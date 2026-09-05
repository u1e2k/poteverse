# PoteLcdDisplay.gd
# 初代デジモン風 レトロモノクロLCD液晶ドットマトリクス表示コンポーネント
class_name PoteLcdDisplay
extends Control

@export var lcd_bg_color: Color = Color(0.61, 0.67, 0.54, 1.0)
@export var lcd_fg_color: Color = Color(0.12, 0.16, 0.12, 1.0)
@export var animation_interval: float = 0.40

enum PoteActionState {
	WALKING,       # 左右パトロール歩行
	WAITING,       # 時々立ち止まり
	APPROACH_FOOD, # ごはんに駆け寄る
	EATING,        # もぐもぐ食べる
	TRAINING,      # サンドバッグ/筋トレ
	BATTLING,      # 実戦スパーリング
	HAPPY          # ゴキゲン
}

var current_species_id: String = "egg_basic"
var current_frame_index: int = 0
var animation_timer: float = 0.0

var action_state: PoteActionState = PoteActionState.WALKING
var state_timer: float = 0.0

var pote_x_offset: float = 0.0
var move_direction: float = 1.0
const WALK_SPEED: float = 48.0
const PATROL_LIMIT_X: float = 185.0

var current_food_type: String = ""
var food_target_x_offset: float = 0.0
var eat_bites_count: int = 0
var battle_won: bool = false

@onready var texture_pote: TextureRect = $LcdViewport/CharacterContainer/TexturePote
@onready var texture_food: TextureRect = $LcdViewport/FoodLayer/TextureFood
@onready var texture_poop: TextureRect = $LcdViewport/PoopLayer/TexturePoop
@onready var texture_happy: TextureRect = $LcdViewport/EmotionLayer/TextureHappy
@onready var character_container: Control = $LcdViewport/CharacterContainer
@onready var food_layer: Control = $LcdViewport/FoodLayer
@onready var emotion_layer: Control = $LcdViewport/EmotionLayer


func _ready() -> void:
	texture_pote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_food.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_poop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_happy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	texture_food.visible = false
	texture_poop.visible = false
	texture_happy.visible = false

	texture_poop.texture = PotePixelArt.create_item_texture("poop", lcd_fg_color)
	texture_happy.texture = PotePixelArt.create_item_texture("happy_note", lcd_fg_color)

	_update_pote_texture()
	_update_pote_scale()


func _process(delta: float) -> void:
	_process_ai_state(delta)
	_process_animation_frames(delta)
	_update_positions()


func _process_ai_state(delta: float) -> void:
	if current_species_id.begins_with("egg_"):
		pote_x_offset = 0.0
		texture_pote.flip_h = false
		return

	match action_state:
		PoteActionState.WALKING:
			pote_x_offset += move_direction * WALK_SPEED * delta
			texture_pote.flip_h = (move_direction < 0)

			if pote_x_offset >= PATROL_LIMIT_X:
				pote_x_offset = PATROL_LIMIT_X
				move_direction = -1.0
				_maybe_pause_walking()
			elif pote_x_offset <= -PATROL_LIMIT_X:
				pote_x_offset = -PATROL_LIMIT_X
				move_direction = 1.0
				_maybe_pause_walking()

		PoteActionState.WAITING:
			state_timer -= delta
			if state_timer <= 0.0:
				action_state = PoteActionState.WALKING
				if randf() > 0.6:
					move_direction *= -1.0

		PoteActionState.APPROACH_FOOD:
			var dir_to_food = signf(food_target_x_offset - pote_x_offset)
			if dir_to_food != 0:
				move_direction = dir_to_food
				texture_pote.flip_h = (move_direction < 0)

			pote_x_offset += move_direction * (WALK_SPEED * 1.6) * delta

			if absf(pote_x_offset - food_target_x_offset) <= 12.0:
				pote_x_offset = food_target_x_offset - (move_direction * 12.0)
				action_state = PoteActionState.EATING
				state_timer = 0.25
				eat_bites_count = 0

		PoteActionState.EATING:
			state_timer -= delta
			if state_timer <= 0.0:
				state_timer = 0.3
				eat_bites_count += 1
				_update_pote_texture()

				if eat_bites_count >= 3:
					texture_food.visible = false
					action_state = PoteActionState.HAPPY
					state_timer = 1.2
					texture_happy.visible = true
					_update_pote_texture()

		PoteActionState.TRAINING:
			state_timer -= delta
			pote_x_offset = sin(Time.get_ticks_msec() * 0.02) * 15.0
			if state_timer <= 0.0:
				texture_food.visible = false
				action_state = PoteActionState.HAPPY
				state_timer = 1.0
				texture_happy.visible = true

		PoteActionState.BATTLING:
			state_timer -= delta
			if state_timer <= 0.0:
				texture_food.visible = false
				if battle_won:
					action_state = PoteActionState.HAPPY
					state_timer = 1.5
					texture_happy.visible = true
				else:
					action_state = PoteActionState.WALKING

		PoteActionState.HAPPY:
			state_timer -= delta
			if state_timer <= 0.0:
				texture_happy.visible = false
				action_state = PoteActionState.WALKING


func _process_animation_frames(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= animation_interval:
		animation_timer -= animation_interval
		current_frame_index = (current_frame_index + 1) % 2
		_update_pote_texture()


func _update_positions() -> void:
	var screen_center_x = size.x / 2.0
	if character_container:
		character_container.position.x = screen_center_x + pote_x_offset

	if emotion_layer and texture_happy.visible:
		emotion_layer.position.x = screen_center_x + pote_x_offset


func _maybe_pause_walking() -> void:
	if randf() < 0.35:
		action_state = PoteActionState.WAITING
		state_timer = randf_range(0.8, 1.8)


func _update_pote_texture() -> void:
	if texture_pote == null:
		return

	var is_eating = (action_state == PoteActionState.EATING)
	var tex = PotePixelArt.create_texture(current_species_id, current_frame_index, is_eating, lcd_fg_color)
	texture_pote.texture = tex


## 世代ごとのサイズ差別化 (大画面LCD対応)
func _update_pote_scale() -> void:
	if texture_pote == null:
		return

	var target_dim: float = 160.0
	if current_species_id.begins_with("egg_"):
		target_dim = 135.0
	elif current_species_id.begins_with("baby_"):
		target_dim = 125.0
	elif current_species_id.begins_with("child_"):
		target_dim = 165.0
	elif current_species_id.begins_with("adult_"):
		target_dim = 210.0
	elif current_species_id.begins_with("master_"):
		target_dim = 250.0

	texture_pote.scale = Vector2.ONE
	texture_pote.custom_minimum_size = Vector2(target_dim, target_dim)
	texture_pote.offset_left = -target_dim / 2.0
	texture_pote.offset_right = target_dim / 2.0
	texture_pote.offset_top = -target_dim / 2.0 + 15.0
	texture_pote.offset_bottom = target_dim / 2.0 + 15.0



# ==============================================================================
# 公開API
# ==============================================================================
func set_species(species_id: String) -> void:
	current_species_id = species_id
	current_frame_index = 0
	_update_pote_texture()
	_update_pote_scale()


func start_feeding(food_type: String) -> void:
	current_food_type = food_type
	texture_food.texture = PotePixelArt.create_item_texture(food_type, lcd_fg_color)
	texture_food.visible = true

	food_target_x_offset = clampf(pote_x_offset + (move_direction * 70.0), -PATROL_LIMIT_X + 30.0, PATROL_LIMIT_X - 30.0)
	var screen_center_x = size.x / 2.0
	if food_layer:
		food_layer.position.x = screen_center_x + food_target_x_offset

	action_state = PoteActionState.APPROACH_FOOD


func start_training() -> void:
	texture_food.texture = PotePixelArt.create_item_texture("punch", lcd_fg_color)
	texture_food.visible = true
	var screen_center_x = size.x / 2.0
	if food_layer:
		food_layer.position.x = screen_center_x + 55.0
	action_state = PoteActionState.TRAINING
	state_timer = 1.6


func start_battle(won: bool) -> void:
	battle_won = won
	texture_food.texture = PotePixelArt.create_item_texture("blast", lcd_fg_color)
	texture_food.visible = true
	var screen_center_x = size.x / 2.0
	if food_layer:
		food_layer.position.x = screen_center_x + 65.0

	var tween = create_tween()
	# 突進＆体当たり
	tween.tween_property(self, "pote_x_offset", 45.0, 0.25)
	tween.tween_property(self, "pote_x_offset", -30.0, 0.2)
	tween.tween_property(self, "pote_x_offset", 0.0, 0.2)
	
	action_state = PoteActionState.BATTLING
	state_timer = 1.8


func set_poop(visible_state: bool) -> void:
	if texture_poop:
		texture_poop.visible = visible_state


func trigger_evolve_animation() -> void:
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(texture_pote, "modulate:a", 0.1, 0.08)
		tween.tween_property(texture_pote, "modulate:a", 1.0, 0.08)
	tween.tween_callback(func():
		texture_happy.visible = true
		state_timer = 1.5
		action_state = PoteActionState.HAPPY
		_update_pote_scale()
	)
