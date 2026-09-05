# PoteState.gd
# ANBERNIC RG Rotate 向け 相棒ポテ状態・バトル戦績・進化判定管理シングルトン (Autoload)
extends Node

signal stats_updated(belly: float, toilet: float, stamina: float, buddy_sync: float)
signal battle_finished(won: bool, enemy_name: String, message: String)
signal buddy_dialogue_emitted(speaker: String, text: String, mood: PoteEnums.BuddyMood)
signal stage_evolved(previous_species: PoteSpeciesData, new_species: PoteSpeciesData)
signal poop_spawned_on_floor()

## 相棒ポテの基本情報 & 種族データ
@export var buddy_name: String = "ポテまる"
@export var current_species_id: String = "egg_basic"
@export var mood: PoteEnums.BuddyMood = PoteEnums.BuddyMood.NORMAL

var current_species: PoteSpeciesData

## コアパラメータ（0.0 〜 100.0）
@export var belly_fuel: float = 80.0          # 満腹度
@export var toilet_urgency: float = 10.0      # 便意ゲージ（UI非表示）
@export var stamina: float = 90.0             # 体力/タフネス
@export var buddy_sync: float = 60.0          # ダチ度/シンクロ率

## 育成 & バトル履歴
@export var care_mistakes: int = 0
@export var meat_feed_count: int = 0
@export var protein_feed_count: int = 0
@export var sleep_count: int = 0
@export var training_count: int = 0
@export var total_battles: int = 0
@export var wins: int = 0

## 寿命・進化関連パラメータ（Tick単位）
@export var total_alive_ticks: int = 0
@export var current_stage_ticks: int = 0
@export var ticks_to_next_evolution: int = 50

var _has_triggered_starve_stop: bool = false
var _has_triggered_toilet_stop: bool = false
var _has_triggered_exhaust_stop: bool = false
var _is_evolving: bool = false

const BELLY_DECAY_PER_TICK: float = 0.20
const TOILET_INCREASE_PER_TICK: float = 0.25
const STAMINA_DECAY_PER_TICK: float = 0.10


func _ready() -> void:
	if PoteDatabase:
		current_species = PoteDatabase.get_species(current_species_id)
	
	if current_species == null:
		var db = get_node_or_null("/root/PoteDatabase")
		if db:
			current_species = db.get_species(current_species_id)

	if Engine.has_singleton("PoteverseTimeManager") or get_node_or_null("/root/PoteverseTimeManager"):
		var time_mgr = get_node("/root/PoteverseTimeManager")
		time_mgr.tick_advanced.connect(_on_tick_advanced)
		var sp_name = current_species.name if current_species else "相棒"
		print("[PoteState] PoteverseTimeManager 接続完了。相棒: %s (%s)" % [buddy_name, sp_name])

	_emit_stats()


func _on_tick_advanced(current_tick: int, is_fast_mode: bool) -> void:
	total_alive_ticks += 1
	current_stage_ticks += 1

	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		_process_egg_tick()
	else:
		_process_living_tick()

	_check_evolution_progression()
	_evaluate_emergency_conditions()
	_emit_stats()


func _process_living_tick() -> void:
	belly_fuel = maxf(0.0, belly_fuel - BELLY_DECAY_PER_TICK)
	toilet_urgency = minf(100.0, toilet_urgency + TOILET_INCREASE_PER_TICK)
	stamina = maxf(0.0, stamina - STAMINA_DECAY_PER_TICK)

	if toilet_urgency >= 100.0:
		_handle_poop_accident()


func _process_egg_tick() -> void:
	pass


## 【自動進化システム】
func _check_evolution_progression() -> void:
	if current_species == null or current_species.evolution_branches.is_empty():
		return

	if current_stage_ticks >= ticks_to_next_evolution and not _is_evolving:
		_is_evolving = true
		
		var reason = PoteEnums.EmergencyReason.EGG_HATCHING if current_species.stage == PoteEnums.GrowthStage.EGG else PoteEnums.EmergencyReason.EVOLUTION_READY
		var line = "相棒！タマゴが激しく揺れてるぜ！孵化する！" if current_species.stage == PoteEnums.GrowthStage.EGG else "オイ相棒…！体が熱い！進化の時だァァッ！！"
		
		_request_stop(reason, line)
		evolve_to_next_stage()


func _evaluate_emergency_conditions() -> void:
	if belly_fuel <= 0.0:
		if not _has_triggered_starve_stop:
			_has_triggered_starve_stop = true
			care_mistakes += 1
			mood = PoteEnums.BuddyMood.HUNGRY
			var line = current_species.dialogue_starve_emergency if current_species else "メシをくれ！"
			_request_stop(PoteEnums.EmergencyReason.STARVING, line)
	else:
		_has_triggered_starve_stop = false

	if toilet_urgency >= 90.0:
		if not _has_triggered_toilet_stop:
			_has_triggered_toilet_stop = true
			mood = PoteEnums.BuddyMood.PANIC
			var line = current_species.dialogue_toilet_emergency if current_species else "トイレ急げ！"
			_request_stop(PoteEnums.EmergencyReason.BATHROOM_CRITICAL, line)
	else:
		_has_triggered_toilet_stop = false

	if stamina <= 0.0:
		if not _has_triggered_exhaust_stop:
			_has_triggered_exhaust_stop = true
			care_mistakes += 1
			mood = PoteEnums.BuddyMood.TIRED
			var line = current_species.dialogue_exhaust_emergency if current_species else "もう動けねぇ…"
			_request_stop(PoteEnums.EmergencyReason.EXHAUSTION, line)
	else:
		_has_triggered_exhaust_stop = false


func _request_stop(reason: PoteEnums.EmergencyReason, buddy_line: String) -> void:
	buddy_dialogue_emitted.emit(buddy_name, buddy_line, mood)
	var time_mgr = get_node_or_null("/root/PoteverseTimeManager")
	if time_mgr:
		time_mgr.trigger_emergency_stop(reason, buddy_line)


func _handle_poop_accident() -> void:
	toilet_urgency = 0.0
	care_mistakes += 1
	buddy_sync = maxf(0.0, buddy_sync - 15.0)
	poop_spawned_on_floor.emit()
	buddy_dialogue_emitted.emit(buddy_name, "うわーーっ！！やっちまった…！すまねぇ相棒、掃除してくれ…", PoteEnums.BuddyMood.PANIC)


# ==============================================================================
# プレイヤー育成 & バトル API
# ==============================================================================

func get_win_rate() -> float:
	if total_battles == 0:
		return 0.0
	return float(wins) / float(total_battles)


## 🍖 肉を与える
func feed_meat(food_power: float = 35.0) -> void:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴはまだ何も食べられないようだ）」", PoteEnums.BuddyMood.NORMAL)
		return

	meat_feed_count += 1
	belly_fuel = minf(100.0, belly_fuel + food_power)
	toilet_urgency = minf(100.0, toilet_urgency + 8.0)
	buddy_sync = minf(100.0, buddy_sync + 2.0)
	mood = PoteEnums.BuddyMood.HAPPY
	
	var line = "肉うめぇーー！！骨の髄まで染み渡るぜ！サンキュー相棒！"
	if current_species and not current_species.dialogue_feed.is_empty():
		line = current_species.dialogue_feed
	buddy_dialogue_emitted.emit(buddy_name, line, mood)
	_emit_stats()


## 💊 プロテインを与える
func feed_protein(stamina_power: float = 30.0) -> void:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴはまだ何も食べられないようだ）」", PoteEnums.BuddyMood.NORMAL)
		return

	protein_feed_count += 1
	stamina = minf(100.0, stamina + stamina_power)
	belly_fuel = minf(100.0, belly_fuel + 10.0)
	buddy_sync = minf(100.0, buddy_sync + 4.0)
	mood = PoteEnums.BuddyMood.HYPED
	
	var line = "プロテイン補給完了！筋肉がキレてるぜ相棒！いくぞォォッ！"
	buddy_dialogue_emitted.emit(buddy_name, line, mood)
	_emit_stats()


## 🏋️ トレーニング（サンドバッグ打ち）
func execute_training() -> void:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴはまだ特訓できない。孵化を待とう）」", PoteEnums.BuddyMood.NORMAL)
		return

	if stamina < 15.0:
		buddy_dialogue_emitted.emit(buddy_name, "ぜぇ…ぜぇ…スタミナ切れだ…休ませてくれ…", PoteEnums.BuddyMood.TIRED)
		return

	training_count += 1
	stamina = maxf(0.0, stamina - 15.0)
	belly_fuel = maxf(0.0, belly_fuel - 8.0)
	buddy_sync = minf(100.0, buddy_sync + 3.0)
	mood = PoteEnums.BuddyMood.HYPED
	buddy_dialogue_emitted.emit(buddy_name, "オラオラァ！いい汗かいたぜ！筋肉が唸ってる！", mood)
	_emit_stats()


## ⚔️ 実戦バトル（スパーリング）
func execute_battle() -> Dictionary:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴでバトルに出るのは無茶だ！）」", PoteEnums.BuddyMood.NORMAL)
		return {"success": false, "won": false}

	if stamina < 20.0:
		buddy_dialogue_emitted.emit(buddy_name, "スタミナが足りなくて戦えねぇぜ…！寝るか肉をくれ！", PoteEnums.BuddyMood.TIRED)
		return {"success": false, "won": false}

	total_battles += 1
	stamina = maxf(0.0, stamina - 20.0)
	belly_fuel = maxf(0.0, belly_fuel - 10.0)

	var enemy_names = ["野良ポテ", "シャドウポテ", "ライバルポテ", "暴走メカポテ"]
	var enemy = enemy_names[randi() % enemy_names.size()]

	# 勝率計算: ダチ度、満腹度、トレーニング回数が影響
	var win_chance: float = 0.50
	win_chance += (buddy_sync - 50.0) * 0.004
	win_chance += (belly_fuel - 50.0) * 0.002
	win_chance += minf(0.20, float(training_count) * 0.02)
	win_chance = clampf(win_chance, 0.20, 0.90)

	var won: bool = randf() < win_chance
	var msg: String = ""

	if won:
		wins += 1
		buddy_sync = minf(100.0, buddy_sync + 6.0)
		mood = PoteEnums.BuddyMood.HYPED
		msg = "【勝利！】%s を必殺ブローでノックアウト！オレたちの勝ちだ！" % enemy
	else:
		buddy_sync = maxf(0.0, buddy_sync - 2.0)
		mood = PoteEnums.BuddyMood.TIRED
		msg = "【惜敗…】%s に一撃喰らった…次は絶対勝つぞ相棒！" % enemy

	battle_finished.emit(won, enemy, msg)
	buddy_dialogue_emitted.emit(buddy_name, msg, mood)
	_emit_stats()
	return {"success": true, "won": won, "enemy": enemy, "msg": msg}


## 🚽 トイレ
func send_to_toilet() -> void:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴはトイレに行かないようだ）」", PoteEnums.BuddyMood.NORMAL)
		return

	if toilet_urgency > 20.0:
		toilet_urgency = 0.0
		buddy_sync = minf(100.0, buddy_sync + 5.0)
		mood = PoteEnums.BuddyMood.HAPPY
		var line = current_species.dialogue_toilet_success if current_species else "スッキリしたぜ！"
		buddy_dialogue_emitted.emit(buddy_name, line, mood)
	else:
		buddy_dialogue_emitted.emit(buddy_name, "ん？今はまだ出ねぇぜ！", PoteEnums.BuddyMood.NORMAL)
	_emit_stats()


## 💤 睡眠
func rest_buddy(rest_amount: float = 60.0) -> void:
	if current_species and current_species.stage == PoteEnums.GrowthStage.EGG:
		buddy_dialogue_emitted.emit(buddy_name, "「……（タマゴを毛布で温めて見守った）」", PoteEnums.BuddyMood.NORMAL)
		return

	sleep_count += 1
	stamina = minf(100.0, stamina + rest_amount)
	mood = PoteEnums.BuddyMood.NORMAL
	buddy_dialogue_emitted.emit(buddy_name, "ふぁ〜…ぐっすり寝て全快だぜ！今日もバリバリ行こう！", mood)
	_emit_stats()


## 【勝率・戦績・条件分岐進化ロジック】
func evolve_to_next_stage() -> void:
	if current_species == null or current_species.evolution_branches.is_empty():
		_is_evolving = false
		return

	var prev_species = current_species
	var target_species_id: String = ""
	var win_rate = get_win_rate()

	# タマゴ期 -> 幼年期への孵化
	if prev_species.stage == PoteEnums.GrowthStage.EGG:
		target_species_id = prev_species.evolution_branches[0].get("target_id", "baby_drak")
	else:
		# 条件判定
		for branch in current_species.evolution_branches:
			var min_sync: float = branch.get("min_sync", 0.0)
			var min_wr: float = branch.get("min_win_rate", 0.0)
			var min_bat: int = int(branch.get("min_battles", 0))

			if buddy_sync >= min_sync and win_rate >= min_wr and total_battles >= min_bat:
				target_species_id = branch.get("target_id", "")
				break

	# 条件未達成の場合: 最下位ルート（または進化保留）
	if target_species_id.is_empty():
		# 実戦不足・勝率不足の場合は進化保留（鍛錬継続）
		if total_battles < 2 and prev_species.stage != PoteEnums.GrowthStage.EGG:
			ticks_to_next_evolution += 40 # 鍛錬時間を延長
			_is_evolving = false
			buddy_dialogue_emitted.emit(buddy_name, "（まだ進化の時ではないようだ…もっと実戦と鍛錬が必要だ！）", PoteEnums.BuddyMood.TIRED)
			return
		target_species_id = current_species.evolution_branches[-1].get("target_id", "")

	current_species_id = target_species_id
	current_species = PoteDatabase.get_species(current_species_id)

	match current_species.stage:
		PoteEnums.GrowthStage.EGG: ticks_to_next_evolution = 50
		PoteEnums.GrowthStage.BABY: ticks_to_next_evolution = 60
		PoteEnums.GrowthStage.CHILD: ticks_to_next_evolution = 80
		PoteEnums.GrowthStage.ADULT: ticks_to_next_evolution = 120
		PoteEnums.GrowthStage.MASTER: ticks_to_next_evolution = 999999
		_: ticks_to_next_evolution = 50

	current_stage_ticks = 0
	_is_evolving = false
	mood = PoteEnums.BuddyMood.HYPED
	
	stage_evolved.emit(prev_species, current_species)
	var evolve_line = current_species.dialogue_evolve if current_species else "オレの新形態だぜ！"
	buddy_dialogue_emitted.emit(buddy_name, evolve_line, mood)
	_emit_stats()


func _emit_stats() -> void:
	stats_updated.emit(belly_fuel, toilet_urgency, stamina, buddy_sync)


# ==============================================================================
# ❄️ 凍結（コールドスリープ）＆新タマゴ生成 API
# ==============================================================================
func export_state_dict() -> Dictionary:
	return {
		"buddy_name": buddy_name,
		"current_species_id": current_species_id,
		"belly_fuel": belly_fuel,
		"toilet_urgency": toilet_urgency,
		"stamina": stamina,
		"buddy_sync": buddy_sync,
		"care_mistakes": care_mistakes,
		"meat_feed_count": meat_feed_count,
		"protein_feed_count": protein_feed_count,
		"sleep_count": sleep_count,
		"training_count": training_count,
		"total_battles": total_battles,
		"wins": wins,
		"total_alive_ticks": total_alive_ticks,
		"current_stage_ticks": current_stage_ticks,
		"ticks_to_next_evolution": ticks_to_next_evolution,
		"saved_at": Time.get_datetime_string_from_system()
	}


func import_state_dict(data: Dictionary) -> void:
	buddy_name = data.get("buddy_name", "ポテまる")
	current_species_id = data.get("current_species_id", "egg_basic")
	belly_fuel = float(data.get("belly_fuel", 80.0))
	toilet_urgency = float(data.get("toilet_urgency", 10.0))
	stamina = float(data.get("stamina", 90.0))
	buddy_sync = float(data.get("buddy_sync", 60.0))
	care_mistakes = int(data.get("care_mistakes", 0))
	meat_feed_count = int(data.get("meat_feed_count", 0))
	protein_feed_count = int(data.get("protein_feed_count", 0))
	sleep_count = int(data.get("sleep_count", 0))
	training_count = int(data.get("training_count", 0))
	total_battles = int(data.get("total_battles", 0))
	wins = int(data.get("wins", 0))
	total_alive_ticks = int(data.get("total_alive_ticks", 0))
	current_stage_ticks = int(data.get("current_stage_ticks", 0))
	ticks_to_next_evolution = int(data.get("ticks_to_next_evolution", 50))

	if PoteDatabase:
		current_species = PoteDatabase.get_species(current_species_id)

	mood = PoteEnums.BuddyMood.HAPPY
	stage_evolved.emit(null, current_species)
	buddy_dialogue_emitted.emit(buddy_name, "ふぁぁ…！コールドスリープから目覚めたぜ相棒！またよろしくな！", mood)
	_emit_stats()


func reset_to_new_egg(egg_species_id: String = "egg_drak", new_name: String = "ポテまる") -> void:
	buddy_name = new_name
	current_species_id = egg_species_id
	if PoteDatabase:
		current_species = PoteDatabase.get_species(current_species_id)
	
	belly_fuel = 100.0
	toilet_urgency = 0.0
	stamina = 100.0
	buddy_sync = 50.0
	
	care_mistakes = 0
	meat_feed_count = 0
	protein_feed_count = 0
	sleep_count = 0
	training_count = 0
	total_battles = 0
	wins = 0
	
	total_alive_ticks = 0
	current_stage_ticks = 0
	ticks_to_next_evolution = 50
	_is_evolving = false
	mood = PoteEnums.BuddyMood.NORMAL

	stage_evolved.emit(null, current_species)
	buddy_dialogue_emitted.emit(buddy_name, "（温かいタマゴが静かに脈打っている…）", mood)
	_emit_stats()
