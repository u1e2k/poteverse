# DebugPoteView.gd
# ANBERNIC RG Rotate (720x720) 向け デバッグ＆本格育成メインビュー
extends Control

@onready var label_status: Label = %LabelStatus
@onready var label_speed: Label = %LabelSpeed
@onready var label_tick: Label = %LabelTick
@onready var label_dialogue: Label = %LabelDialogue
@onready var label_pote_name: Label = %LabelPoteName
@onready var label_stage: Label = %LabelStage

@onready var bar_belly: ProgressBar = %BarBelly
@onready var bar_stamina: ProgressBar = %BarStamina
@onready var label_battle_stats: Label = %LabelBattleStats
@onready var label_training_stats: Label = %LabelTrainingStats

@onready var alert_panel: PanelContainer = %AlertPanel
@onready var label_alert: Label = %LabelAlert
@onready var lcd_display: PoteLcdDisplay = %PoteLcdDisplay

@onready var btn_open_cryo: Button = %BtnOpenCryo
@onready var btn_feed_menu: Button = %BtnFeedMenu
@onready var btn_train_menu: Button = %BtnTrainMenu
@onready var btn_toilet: Button = %BtnToilet
@onready var btn_rest: Button = %BtnRest

# サブポップアップ & モーダル
@onready var feed_popup_panel: PanelContainer = %FeedPopupPanel
@onready var btn_meat_action: Button = %BtnMeatAction
@onready var btn_protein_action: Button = %BtnProteinAction
@onready var btn_close_feed: Button = %BtnCloseFeed

@onready var train_popup_panel: PanelContainer = %TrainPopupPanel
@onready var btn_training_action: Button = %BtnTrainingAction
@onready var btn_battle_action: Button = %BtnBattleAction
@onready var btn_close_train: Button = %BtnCloseTrain

@onready var egg_select_modal_panel: PanelContainer = %EggSelectModalPanel
@onready var btn_close_egg_select: Button = %BtnCloseEggSelect
@onready var egg_list_container: VBoxContainer = %EggListContainer

@onready var cryo_modal_panel: PanelContainer = %CryoModalPanel
@onready var btn_close_cryo: Button = %BtnCloseCryo
@onready var slot_list_container: VBoxContainer = %SlotListContainer
@onready var btn_freeze_current: Button = %BtnFreezeCurrent
@onready var btn_freeze_and_egg: Button = %BtnFreezeAndEgg

# 🔧 秘密の開発者デバッグモーダル
@onready var debug_modal_panel: PanelContainer = %DebugModalPanel
@onready var btn_close_debug: Button = %BtnCloseDebug
@onready var label_debug_stats: Label = %LabelDebugStats
@onready var btn_dbg_skip50: Button = %BtnDbgSkip50
@onready var btn_dbg_force_evolve: Button = %BtnDbgForceEvolve
@onready var btn_dbg_full_heal: Button = %BtnDbgFullHeal
@onready var btn_dbg_trigger_toilet: Button = %BtnDbgTriggerToilet
@onready var btn_dbg_add_wins: Button = %BtnDbgAddWins
@onready var btn_dbg_reset_egg: Button = %BtnDbgResetEgg

var alert_timer: float = 0.0
var _pending_freeze_slot_idx: int = -1
var _focus_box_style: StyleBoxFlat

# 隠しコマンド（コナミコマンド: ↑ ↑ ↓ ↓ ← → ← →）
var _secret_input_history: Array[String] = []
const SECRET_KONAMI_SEQUENCE: Array[String] = [
	"ui_up", "ui_up", "ui_down", "ui_down", "ui_left", "ui_right", "ui_left", "ui_right"
]


func _ready() -> void:
	# AndroidのBackキーでアプリが突然終了しないよう制御
	get_tree().set_auto_accept_quit(false)

	PoteverseTimeManager.tick_advanced.connect(_on_tick_advanced)
	PoteverseTimeManager.fast_forward_state_changed.connect(_on_fast_forward_state_changed)
	PoteverseTimeManager.emergency_stopped.connect(_on_emergency_stopped)

	PoteState.stats_updated.connect(_on_stats_updated)
	PoteState.buddy_dialogue_emitted.connect(_on_buddy_dialogue)
	PoteState.stage_evolved.connect(_on_stage_evolved)
	PoteState.poop_spawned_on_floor.connect(_on_poop_spawned)

	if PoteCryoStorage:
		PoteCryoStorage.storage_updated.connect(_refresh_cryo_slots)

	alert_panel.visible = false
	feed_popup_panel.visible = false
	train_popup_panel.visible = false
	egg_select_modal_panel.visible = false
	cryo_modal_panel.visible = false
	debug_modal_panel.visible = false

	_setup_focus_navigation()
	_update_ui_labels()
	_update_lcd_species()
	_update_battle_ui()
	print("[DebugPoteView] レトロLCDドット液晶UI初期化完了 (十字キー・Aボタン決定・Bボタン戻る対応)")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var handled = _handle_back_request()
		if not handled:
			print("[DebugPoteView] メイン画面でBack要求受信")


func _handle_back_request() -> bool:
	if debug_modal_panel and debug_modal_panel.visible:
		_on_btn_close_debug_pressed()
		return true
	if feed_popup_panel and feed_popup_panel.visible:
		_on_btn_close_feed_pressed()
		return true
	if train_popup_panel and train_popup_panel.visible:
		_on_btn_close_train_pressed()
		return true
	if egg_select_modal_panel and egg_select_modal_panel.visible:
		_on_btn_close_egg_select_pressed()
		return true
	if cryo_modal_panel and cryo_modal_panel.visible:
		_on_btn_close_cryo_pressed()
		return true
	return false


func _setup_focus_navigation() -> void:
	_focus_box_style = StyleBoxFlat.new()
	_focus_box_style.bg_color = Color(0.20, 0.28, 0.38, 0.95)
	_focus_box_style.border_width_left = 3
	_focus_box_style.border_width_top = 3
	_focus_box_style.border_width_right = 3
	_focus_box_style.border_width_bottom = 3
	_focus_box_style.border_color = Color(0.35, 1.0, 0.65, 1.0) # Bright Matrix Emerald
	_focus_box_style.set_corner_radius_all(6)
	_focus_box_style.shadow_color = Color(0.1, 0.8, 0.4, 0.4)
	_focus_box_style.shadow_size = 4

	var all_static_buttons = [
		btn_open_cryo, btn_feed_menu, btn_train_menu, btn_toilet, btn_rest,
		btn_meat_action, btn_protein_action, btn_close_feed,
		btn_training_action, btn_battle_action, btn_close_train,
		btn_close_egg_select, btn_close_cryo, btn_freeze_current, btn_freeze_and_egg,
		btn_close_debug, btn_dbg_skip50, btn_dbg_force_evolve, btn_dbg_full_heal,
		btn_dbg_trigger_toilet, btn_dbg_add_wins, btn_dbg_reset_egg
	]
	for b in all_static_buttons:
		if b:
			b.add_theme_stylebox_override("focus", _focus_box_style)

	# メイン操作ボタンの十字キー（D-pad）ループ配線
	btn_feed_menu.focus_neighbor_left = btn_rest.get_path()
	btn_feed_menu.focus_neighbor_right = btn_train_menu.get_path()
	btn_feed_menu.focus_neighbor_top = btn_open_cryo.get_path()
	btn_feed_menu.focus_neighbor_bottom = btn_feed_menu.get_path()

	btn_train_menu.focus_neighbor_left = btn_feed_menu.get_path()
	btn_train_menu.focus_neighbor_right = btn_toilet.get_path()
	btn_train_menu.focus_neighbor_top = btn_open_cryo.get_path()
	btn_train_menu.focus_neighbor_bottom = btn_train_menu.get_path()

	btn_toilet.focus_neighbor_left = btn_train_menu.get_path()
	btn_toilet.focus_neighbor_right = btn_rest.get_path()
	btn_toilet.focus_neighbor_top = btn_open_cryo.get_path()
	btn_toilet.focus_neighbor_bottom = btn_toilet.get_path()

	btn_rest.focus_neighbor_left = btn_toilet.get_path()
	btn_rest.focus_neighbor_right = btn_feed_menu.get_path()
	btn_rest.focus_neighbor_top = btn_open_cryo.get_path()
	btn_rest.focus_neighbor_bottom = btn_rest.get_path()

	btn_open_cryo.focus_neighbor_bottom = btn_feed_menu.get_path()
	btn_open_cryo.focus_neighbor_top = btn_feed_menu.get_path()

	# 食事メニューポップアップ配線
	btn_meat_action.focus_neighbor_left = btn_protein_action.get_path()
	btn_meat_action.focus_neighbor_right = btn_protein_action.get_path()
	btn_meat_action.focus_neighbor_bottom = btn_close_feed.get_path()
	btn_protein_action.focus_neighbor_left = btn_meat_action.get_path()
	btn_protein_action.focus_neighbor_right = btn_meat_action.get_path()
	btn_protein_action.focus_neighbor_bottom = btn_close_feed.get_path()
	btn_close_feed.focus_neighbor_top = btn_meat_action.get_path()

	# 鍛錬メニューポップアップ配線
	btn_training_action.focus_neighbor_left = btn_battle_action.get_path()
	btn_training_action.focus_neighbor_right = btn_battle_action.get_path()
	btn_training_action.focus_neighbor_bottom = btn_close_train.get_path()
	btn_battle_action.focus_neighbor_left = btn_training_action.get_path()
	btn_battle_action.focus_neighbor_right = btn_training_action.get_path()
	btn_battle_action.focus_neighbor_bottom = btn_close_train.get_path()
	btn_close_train.focus_neighbor_top = btn_training_action.get_path()

	# 凍結ポッド配線
	btn_close_cryo.focus_neighbor_bottom = btn_freeze_current.get_path()
	btn_freeze_current.focus_neighbor_left = btn_freeze_and_egg.get_path()
	btn_freeze_current.focus_neighbor_right = btn_freeze_and_egg.get_path()
	btn_freeze_current.focus_neighbor_top = btn_close_cryo.get_path()
	btn_freeze_and_egg.focus_neighbor_left = btn_freeze_current.get_path()
	btn_freeze_and_egg.focus_neighbor_right = btn_freeze_current.get_path()
	btn_freeze_and_egg.focus_neighbor_top = btn_close_cryo.get_path()

	# デバッグモーダル配線
	btn_close_debug.focus_neighbor_bottom = btn_dbg_skip50.get_path()
	btn_dbg_skip50.focus_neighbor_top = btn_close_debug.get_path()
	btn_dbg_skip50.focus_neighbor_right = btn_dbg_force_evolve.get_path()
	btn_dbg_skip50.focus_neighbor_bottom = btn_dbg_full_heal.get_path()
	btn_dbg_force_evolve.focus_neighbor_top = btn_close_debug.get_path()
	btn_dbg_force_evolve.focus_neighbor_left = btn_dbg_skip50.get_path()
	btn_dbg_force_evolve.focus_neighbor_bottom = btn_dbg_trigger_toilet.get_path()
	btn_dbg_full_heal.focus_neighbor_top = btn_dbg_skip50.get_path()
	btn_dbg_full_heal.focus_neighbor_right = btn_dbg_trigger_toilet.get_path()
	btn_dbg_full_heal.focus_neighbor_bottom = btn_dbg_add_wins.get_path()
	btn_dbg_trigger_toilet.focus_neighbor_top = btn_dbg_force_evolve.get_path()
	btn_dbg_trigger_toilet.focus_neighbor_left = btn_dbg_full_heal.get_path()
	btn_dbg_trigger_toilet.focus_neighbor_bottom = btn_dbg_reset_egg.get_path()
	btn_dbg_add_wins.focus_neighbor_top = btn_dbg_full_heal.get_path()
	btn_dbg_add_wins.focus_neighbor_right = btn_dbg_reset_egg.get_path()
	btn_dbg_reset_egg.focus_neighbor_top = btn_dbg_trigger_toilet.get_path()
	btn_dbg_reset_egg.focus_neighbor_left = btn_dbg_add_wins.get_path()


func _process(delta: float) -> void:
	if alert_panel.visible:
		alert_timer -= delta
		if alert_timer <= 0.0:
			alert_panel.visible = false

	if PoteverseTimeManager.is_interlocked:
		label_speed.text = "[ INTERLOCK 警告: R2を離してください ]"
		label_speed.modulate = Color.ORANGE
	elif PoteverseTimeManager.is_fast_forwarding:
		label_speed.text = ">> 早送り中 (20倍速 / 0.05s)"
		label_speed.modulate = Color.CYAN
	else:
		label_speed.text = "▶ 通常速度 (1.0s/tick)"
		label_speed.modulate = Color.WHITE


func _input(event: InputEvent) -> void:
	var any_modal_open: bool = (
		(debug_modal_panel and debug_modal_panel.visible) or
		(feed_popup_panel and feed_popup_panel.visible) or
		(train_popup_panel and train_popup_panel.visible) or
		(egg_select_modal_panel and egg_select_modal_panel.visible) or
		(cryo_modal_panel and cryo_modal_panel.visible)
	)

	# ❌ Bボタン / キャンセル / 戻る判定
	# RG Rotate (Nintendo配列): 物理Bボタン = JOY_BUTTON_A (0)
	# Xbox配列: 物理Bボタン = JOY_BUTTON_B (1)
	# その他: JOY_BUTTON_BACK (4), Escape, Backspace, Android Back (KEY_BACK)
	var is_cancel: bool = false
	if event.is_action_pressed("ui_cancel"):
		is_cancel = true
	elif event is InputEventJoypadButton and event.pressed:
		if any_modal_open:
			# モーダル展開中は、物理Bボタン(0または1)やBackボタン(4)で即座に戻る
			if event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_BACK or event.button_index == 16:
				is_cancel = true
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK or event.keycode == KEY_BACKSPACE:
			is_cancel = true

	if is_cancel and any_modal_open:
		_handle_back_request()
		get_viewport().set_input_as_handled()
		return

	# 🔧 隠しデバッグ起動チェック (F12 / Tab / コナミコマンド: ↑↑↓↓←→←→)
	if event is InputEventKey and event.pressed and (event.keycode == KEY_F12 or event.keycode == KEY_TAB):
		_open_debug_modal()
		get_viewport().set_input_as_handled()
		return

	for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action_pressed(action):
			_record_secret_input(action)
			break


func _record_secret_input(action: String) -> void:
	_secret_input_history.append(action)
	if _secret_input_history.size() > SECRET_KONAMI_SEQUENCE.size():
		_secret_input_history.pop_front()

	if _secret_input_history == SECRET_KONAMI_SEQUENCE:
		_secret_input_history.clear()
		_open_debug_modal()


func _on_tick_advanced(current_tick: int, is_fast: bool) -> void:
	label_tick.text = "Tick: %d" % current_tick
	if debug_modal_panel.visible:
		_update_debug_stats_text()


func _on_fast_forward_state_changed(is_fast: bool) -> void:
	pass


func _on_emergency_stopped(reason: PoteEnums.EmergencyReason, buddy_message: String) -> void:
	alert_panel.visible = true
	alert_timer = 3.0
	label_alert.text = "⚠ EMERGENCY STOP ⚠\n" + PoteEnums.EmergencyReason.keys()[reason]


func _on_stats_updated(belly: float, toilet: float, stamina: float, buddy_sync: float) -> void:
	bar_belly.value = belly
	bar_stamina.value = stamina

	if belly <= 20.0:
		bar_belly.modulate = Color.ORANGE_RED
	else:
		bar_belly.modulate = Color.WHITE

	_update_battle_ui()
	_update_debug_stats_text()


func _on_buddy_dialogue(speaker: String, text: String, mood: PoteEnums.BuddyMood) -> void:
	label_dialogue.text = "「%s」" % text


func _on_stage_evolved(prev_species: PoteSpeciesData, new_species: PoteSpeciesData) -> void:
	_update_ui_labels()
	_update_lcd_species()
	_update_battle_ui()
	if lcd_display:
		lcd_display.trigger_evolve_animation()


func _on_poop_spawned() -> void:
	label_status.text = "💩 床に粗相が発生中！トイレ掃除をしてくれ！"
	if lcd_display:
		lcd_display.set_poop(true)


func _update_lcd_species() -> void:
	if lcd_display and PoteState.current_species:
		lcd_display.set_species(PoteState.current_species.id)


func _update_battle_ui() -> void:
	var total = PoteState.total_battles
	var wins = PoteState.wins
	var wr = PoteState.get_win_rate() * 100.0
	label_battle_stats.text = "⚔️ 実戦: %d戦 %d勝 (勝率 %d%%)" % [total, wins, int(wr)]
	label_training_stats.text = "🏋️ 特訓: %d回" % PoteState.training_count


func _update_ui_labels() -> void:
	var is_egg: bool = false
	if PoteState.current_species:
		var attr_str = PoteSpeciesData.AttributeType.keys()[PoteState.current_species.attribute]
		var stage_str = PoteEnums.GrowthStage.keys()[PoteState.current_species.stage]
		label_pote_name.text = "%s 【%s】" % [PoteState.buddy_name, PoteState.current_species.name]
		label_stage.text = "[%s / %s]" % [stage_str, attr_str]
		label_status.text = "種族解説: %s" % PoteState.current_species.description
		is_egg = (PoteState.current_species.stage == PoteEnums.GrowthStage.EGG)
	else:
		label_pote_name.text = "相棒: %s" % PoteState.buddy_name
		label_stage.text = "段階: BABY"

	if btn_feed_menu:
		btn_feed_menu.disabled = is_egg
	if btn_train_menu:
		btn_train_menu.disabled = is_egg
	if btn_toilet:
		btn_toilet.disabled = is_egg
	if btn_rest:
		btn_rest.disabled = is_egg

	# タマゴでなければメインメニュー先頭にフォーカスを自動セット
	if not is_egg and not feed_popup_panel.visible and not train_popup_panel.visible and not egg_select_modal_panel.visible and not cryo_modal_panel.visible:
		if get_viewport().gui_get_focus_owner() == null or (get_viewport().gui_get_focus_owner() is Button and get_viewport().gui_get_focus_owner().disabled):
			btn_feed_menu.grab_focus()


# ==============================================================================
# 🍖 食事メニュー
# ==============================================================================
func _on_btn_feed_menu_pressed() -> void:
	feed_popup_panel.visible = true
	btn_meat_action.grab_focus()


func _on_btn_close_feed_pressed() -> void:
	feed_popup_panel.visible = false
	btn_feed_menu.grab_focus()


func _on_btn_meat_action_pressed() -> void:
	feed_popup_panel.visible = false
	btn_feed_menu.grab_focus()
	PoteState.feed_meat()
	if lcd_display:
		lcd_display.start_feeding("meat")


func _on_btn_protein_action_pressed() -> void:
	feed_popup_panel.visible = false
	btn_feed_menu.grab_focus()
	PoteState.feed_protein()
	if lcd_display:
		lcd_display.start_feeding("protein")


# ==============================================================================
# 💪 鍛錬メニュー (特訓 & 実戦バトル)
# ==============================================================================
func _on_btn_train_menu_pressed() -> void:
	train_popup_panel.visible = true
	btn_training_action.grab_focus()


func _on_btn_close_train_pressed() -> void:
	train_popup_panel.visible = false
	btn_train_menu.grab_focus()


func _on_btn_training_action_pressed() -> void:
	train_popup_panel.visible = false
	btn_train_menu.grab_focus()
	PoteState.execute_training()
	if lcd_display:
		lcd_display.start_training()


func _on_btn_battle_action_pressed() -> void:
	train_popup_panel.visible = false
	btn_train_menu.grab_focus()
	var res = PoteState.execute_battle()
	if res.get("success", false) and lcd_display:
		lcd_display.start_battle(res.get("won", false))


func _on_btn_toilet_pressed() -> void:
	PoteState.send_to_toilet()
	if lcd_display:
		lcd_display.set_poop(false)


func _on_btn_rest_pressed() -> void:
	PoteState.rest_buddy()


# ==============================================================================
# 🥚 タマゴ選択モーダル
# ==============================================================================
func open_egg_selection() -> void:
	feed_popup_panel.visible = false
	train_popup_panel.visible = false
	for child in egg_list_container.get_children():
		child.queue_free()

	var first_btn: Button = null
	for egg_opt in PoteDatabase.EGG_OPTIONS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.text = "%s\n%s" % [egg_opt.get("name", ""), egg_opt.get("desc", "")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 13)
		if _focus_box_style:
			btn.add_theme_stylebox_override("focus", _focus_box_style)
		var opt_id = egg_opt.get("id", "egg_drak")
		btn.pressed.connect(func(): _on_egg_selected(opt_id))
		egg_list_container.add_child(btn)
		if first_btn == null:
			first_btn = btn

	egg_select_modal_panel.visible = true
	if first_btn:
		first_btn.grab_focus()


func _on_btn_close_egg_select_pressed() -> void:
	egg_select_modal_panel.visible = false
	btn_open_cryo.grab_focus()


func _on_egg_selected(egg_id: String) -> void:
	egg_select_modal_panel.visible = false
	if _pending_freeze_slot_idx >= 0:
		PoteCryoStorage.freeze_and_start_new_egg(_pending_freeze_slot_idx, "ポテまる")
		PoteState.reset_to_new_egg(egg_id, "ポテまる")
		_pending_freeze_slot_idx = -1
	else:
		PoteState.reset_to_new_egg(egg_id, "ポテまる")

	_update_ui_labels()
	_update_lcd_species()
	_update_battle_ui()


# ==============================================================================
# ❄️ 凍結ポッド保管庫
# ==============================================================================
func _on_btn_open_cryo_pressed() -> void:
	_refresh_cryo_slots()
	cryo_modal_panel.visible = true
	btn_freeze_current.grab_focus()


func _on_btn_close_cryo_pressed() -> void:
	cryo_modal_panel.visible = false
	btn_open_cryo.grab_focus()


func _refresh_cryo_slots() -> void:
	if slot_list_container == null or PoteCryoStorage == null:
		return

	for child in slot_list_container.get_children():
		child.queue_free()

	for i in range(PoteCryoStorage.MAX_SLOTS):
		var info = PoteCryoStorage.get_slot_info(i)
		var panel = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
		card_style.set_corner_radius_all(6)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = Color(0.25, 0.35, 0.5, 0.8)
		panel.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var label_slot = Label.new()
		label_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_slot.add_theme_font_size_override("font_size", 13)

		if info.get("is_empty", true):
			label_slot.text = "【ポッド %d】 ❄️ [ 空きスロット ]" % (i + 1)
			label_slot.modulate = Color(0.6, 0.6, 0.6, 1.0)
			hbox.add_child(label_slot)

			var btn_save = Button.new()
			btn_save.text = "💾 凍結保存"
			btn_save.custom_minimum_size = Vector2(85, 32)
			btn_save.add_theme_font_size_override("font_size", 12)
			if _focus_box_style:
				btn_save.add_theme_stylebox_override("focus", _focus_box_style)
			btn_save.pressed.connect(func(): _freeze_into_slot(i))
			hbox.add_child(btn_save)
		else:
			label_slot.text = "【ポッド %d】 %s 【%s】 [%s] (Tick:%d / Sync:%d%%)" % [
				i + 1,
				info.get("buddy_name", "ポテ"),
				info.get("species_name", ""),
				info.get("stage_name", ""),
				info.get("total_ticks", 0),
				int(info.get("sync", 0))
			]
			label_slot.modulate = Color(0.7, 0.95, 1.0, 1.0)
			hbox.add_child(label_slot)

			var btn_thaw = Button.new()
			btn_thaw.text = "🔥 解凍復帰"
			btn_thaw.custom_minimum_size = Vector2(85, 32)
			btn_thaw.add_theme_font_size_override("font_size", 12)
			if _focus_box_style:
				btn_thaw.add_theme_stylebox_override("focus", _focus_box_style)
			btn_thaw.pressed.connect(func(): _thaw_from_slot(i))
			hbox.add_child(btn_thaw)

			var btn_del = Button.new()
			btn_del.text = "🗑 削除"
			btn_del.custom_minimum_size = Vector2(65, 32)
			btn_del.add_theme_font_size_override("font_size", 12)
			if _focus_box_style:
				btn_del.add_theme_stylebox_override("focus", _focus_box_style)
			btn_del.pressed.connect(func(): _delete_from_slot(i))
			hbox.add_child(btn_del)

		margin.add_child(hbox)
		panel.add_child(margin)
		slot_list_container.add_child(panel)


func _freeze_into_slot(slot_idx: int) -> void:
	if PoteCryoStorage.freeze_current_pote(slot_idx):
		_refresh_cryo_slots()


func _thaw_from_slot(slot_idx: int) -> void:
	if PoteCryoStorage.thaw_pote(slot_idx):
		cryo_modal_panel.visible = false
		_update_ui_labels()
		_update_lcd_species()
		_update_battle_ui()


func _delete_from_slot(slot_idx: int) -> void:
	PoteCryoStorage.delete_slot(slot_idx)
	_refresh_cryo_slots()


func _on_btn_freeze_current_pressed() -> void:
	for i in range(PoteCryoStorage.MAX_SLOTS):
		var info = PoteCryoStorage.get_slot_info(i)
		if info.get("is_empty", true):
			_freeze_into_slot(i)
			return
	label_dialogue.text = "「ポッドがいっぱいで凍結できねぇぜ！」"


func _on_btn_freeze_and_egg_pressed() -> void:
	for i in range(PoteCryoStorage.MAX_SLOTS):
		var info = PoteCryoStorage.get_slot_info(i)
		if info.get("is_empty", true):
			_pending_freeze_slot_idx = i
			cryo_modal_panel.visible = false
			open_egg_selection()
			return
	label_dialogue.text = "「ポッドがいっぱいで新タマゴを受け取れねぇぜ！」"


# ==============================================================================
# 🔧 秘密の開発者デバッグモーダル & チート機能
# ==============================================================================
func _open_debug_modal() -> void:
	feed_popup_panel.visible = false
	train_popup_panel.visible = false
	egg_select_modal_panel.visible = false
	cryo_modal_panel.visible = false

	_update_debug_stats_text()
	debug_modal_panel.visible = true
	btn_dbg_skip50.grab_focus()


func _on_btn_close_debug_pressed() -> void:
	debug_modal_panel.visible = false
	btn_feed_menu.grab_focus()


func _update_debug_stats_text() -> void:
	if not debug_modal_panel or not debug_modal_panel.visible:
		return

	var sp_id = PoteState.current_species.id if PoteState.current_species else "none"
	var sp_name = PoteState.current_species.name if PoteState.current_species else "???"
	var stage_name = PoteEnums.GrowthStage.keys()[PoteState.current_species.stage] if PoteState.current_species else "EGG"
	var attr_name = PoteSpeciesData.AttributeType.keys()[PoteState.current_species.attribute] if PoteState.current_species else "NONE"
	var win_rate = PoteState.get_win_rate() * 100.0

	var txt = ""
	txt += "【相棒】 %s (%s) [%s / %s]\n" % [PoteState.buddy_name, sp_name, stage_name, attr_name]
	txt += "🍖 満腹度 (Belly): %.1f / 100.0\n" % PoteState.belly_fuel
	txt += "⚡ スタミナ (Stamina): %.1f / 100.0\n" % PoteState.stamina
	txt += "🚽 便意 (Toilet - 隠し): %.1f / 100.0\n" % PoteState.toilet_urgency
	txt += "🤝 ダチ度 (Sync - 隠し): %.1f / 100.0\n" % PoteState.buddy_sync
	txt += "⏳ 世代経過Tick: %d / 進化目標: %d Tick (総Tick: %d)\n" % [PoteState.current_stage_ticks, PoteState.ticks_to_next_evolution, PoteState.total_alive_ticks]
	txt += "💩 粗相・ケアミス: %d 回\n" % PoteState.care_mistakes
	txt += "⚔️ 実戦戦績: %d 戦 %d 勝 (勝率: %.1f%%)\n" % [PoteState.total_battles, PoteState.wins, win_rate]
	txt += "🏋️ 特訓: %d 回 / 💤 睡眠: %d 回 / 🍖 給餌: %d 回 / 💊 プロテイン: %d 回" % [
		PoteState.training_count, PoteState.sleep_count, PoteState.meat_feed_count, PoteState.protein_feed_count
	]
	label_debug_stats.text = txt


func _on_btn_dbg_skip50_pressed() -> void:
	for i in range(50):
		PoteverseTimeManager.advance_tick()
	_update_debug_stats_text()
	_update_battle_ui()
	_update_ui_labels()
	_update_lcd_species()


func _on_btn_dbg_force_evolve_pressed() -> void:
	PoteState.evolve_to_next_stage()
	_update_debug_stats_text()
	_update_battle_ui()
	_update_ui_labels()
	_update_lcd_species()


func _on_btn_dbg_full_heal_pressed() -> void:
	PoteState.belly_fuel = 100.0
	PoteState.stamina = 100.0
	PoteState.buddy_sync = 100.0
	PoteState.toilet_urgency = 0.0
	PoteState._emit_stats()
	_update_debug_stats_text()


func _on_btn_dbg_trigger_toilet_pressed() -> void:
	PoteState.toilet_urgency = 95.0
	PoteState._emit_stats()
	_update_debug_stats_text()


func _on_btn_dbg_add_wins_pressed() -> void:
	PoteState.total_battles += 3
	PoteState.wins += 3
	PoteState._emit_stats()
	_update_debug_stats_text()
	_update_battle_ui()


func _on_btn_dbg_reset_egg_pressed() -> void:
	debug_modal_panel.visible = false
	open_egg_selection()
