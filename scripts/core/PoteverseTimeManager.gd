# PoteverseTimeManager.gd
# ANBERNIC RG Rotate 向け Poteverse コア時間管理シングルトン (Autoload)
extends Node

## 時間進行および緊急停止関連シグナル
signal tick_advanced(current_tick: int, is_fast_mode: bool)
signal fast_forward_state_changed(is_fast_mode: bool)
signal emergency_stopped(reason: PoteEnums.EmergencyReason, buddy_message: String)
signal alert_sfx_requested(reason: PoteEnums.EmergencyReason)

## 時間進行定数（秒/Tick）
const NORMAL_TICK_INTERVAL: float = 1.0       # 通常時: 1秒 = 1Tick
const FAST_TICK_INTERVAL: float = 0.05        # 早送り時: 0.05秒 = 1Tick (20倍速)
const MAX_CATCHUP_TICKS_PER_FRAME: int = 10   # フレーム落ち時の無限ループ防止上限
const VIBRATION_DURATION_MS: int = 250        # Android端末のキックバック振動時間(ms)

## 内部状態管理
var is_fast_forwarding: bool = false
var is_interlocked: bool = false
var is_time_paused: bool = false

var current_tick_count: int = 0
var tick_accumulator: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[PoteverseTimeManager] 相棒時間エンジン起動完了。初期状態: 通常速度 (1.0s/tick)")


func _process(delta: float) -> void:
	if is_time_paused:
		return

	_handle_fast_forward_input()
	_advance_time(delta)


## R2ボタン（fast_forwardアクション）の入力判定と安全インターロック制御
func _handle_fast_forward_input() -> void:
	var is_r2_pressed: bool = Input.is_action_pressed("fast_forward")

	# 1. インターロックの解除判定
	# オートストップ後、プレイヤーがR2ボタンを一度完全に離した時にインターロックを解除する
	if is_interlocked and not is_r2_pressed:
		is_interlocked = false
		print("[PoteverseTimeManager] インターロック解除: 早送り準備完了")

	# 2. 早送り状態の更新
	var wants_fast_forward: bool = is_r2_pressed and not is_interlocked

	if wants_fast_forward != is_fast_forwarding:
		is_fast_forwarding = wants_fast_forward
		fast_forward_state_changed.emit(is_fast_forwarding)
		
		if is_fast_forwarding:
			print("[PoteverseTimeManager] >> 早送り開始 (20倍速)")
		else:
			print("[PoteverseTimeManager] || 通常速度に復旧")


## Tick駆動型時間進行処理（フレームレート等速・Tick間隔可変）
func _advance_time(delta: float) -> void:
	tick_accumulator += delta
	var target_interval: float = FAST_TICK_INTERVAL if is_fast_forwarding else NORMAL_TICK_INTERVAL

	var ticks_processed_this_frame: int = 0
	while tick_accumulator >= target_interval and ticks_processed_this_frame < MAX_CATCHUP_TICKS_PER_FRAME:
		tick_accumulator -= target_interval
		current_tick_count += 1
		ticks_processed_this_frame += 1

		# 各Tickを全システム（PoteState等）へブロードキャスト
		tick_advanced.emit(current_tick_count, is_fast_forwarding)

		# 途中でオートストップ等により早送りが解除された場合はインターバルが変わるためループ脱出
		if not is_fast_forwarding and target_interval == FAST_TICK_INTERVAL:
			target_interval = NORMAL_TICK_INTERVAL
			break


## 【最重要】オートストップ & 安全インターロック発動
## PoteStateなどのゲーム内モジュールから緊急事態発生時に呼び出される
func trigger_emergency_stop(reason: PoteEnums.EmergencyReason, custom_buddy_message: String = "") -> void:
	if not is_fast_forwarding and is_interlocked:
		# 既に停止＆インターロック中の多重発火を防止
		return

	print("[PoteverseTimeManager] !!! オートストップ発動 [要因: %s] !!!" % [PoteEnums.EmergencyReason.keys()[reason]])

	# 1. 強制的に通常速度へ急停止
	var was_fast: bool = is_fast_forwarding
	is_fast_forwarding = false

	# 2. 安全インターロックを即時投入（R2を離すまで早送り不可）
	is_interlocked = true

	# 蓄積時間をリセットし、急停止直後のTick跳躍を防止
	tick_accumulator = 0.0

	if was_fast:
		fast_forward_state_changed.emit(false)

	# 3. Android端末振動（ハプティクス・キックバック）
	_trigger_hardware_vibration()

	# 4. 警告SE再生リクエスト
	alert_sfx_requested.emit(reason)

	# 5. UIおよび相棒メッセージ連携シグナル
	var message: String = custom_buddy_message
	if message.is_empty():
		message = _get_default_buddy_alert_message(reason)

	emergency_stopped.emit(reason, message)


## Androidハードウェア振動
func _trigger_hardware_vibration() -> void:
	# OSがAndroidまたはバイブレーション対応デバイスの場合にキックバックを実行
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(VIBRATION_DURATION_MS)


## 相棒からのデフォルト警告セリフ
func _get_default_buddy_alert_message(reason: PoteEnums.EmergencyReason) -> String:
	match reason:
		PoteEnums.EmergencyReason.STARVING:
			return "おいダチ公！腹が減りすぎて目が回りそうだ…！メシくれ！"
		PoteEnums.EmergencyReason.BATHROOM_CRITICAL:
			return "ウッ…！ヤバい、マジで限界だ！！トイレに連れてってくれ！"
		PoteEnums.EmergencyReason.EXHAUSTION:
			return "ぜぇ…はぁ…もう一歩も動けねぇ…少し休ませてくれ…"
		PoteEnums.EmergencyReason.EGG_HATCHING:
			return "カパッ…！タマゴにヒビが入ってきたぞ！"
		PoteEnums.EmergencyReason.EVOLUTION_READY:
			return "なんだこの感覚…体が熱い！相棒、何かが来るぞ…！"
		PoteEnums.EmergencyReason.WILD_ENCOUNTER:
			return "オイ、前を見ろ！野生のポテがケンカ売りに来たぜ！"
		PoteEnums.EmergencyReason.LIFESPAN_END:
			return "相棒…お前と過ごした時間は、最高にダチとして楽しかったぜ…"
		_:
			return "相棒、ちょっとストップだ！何か様子が変だぜ！"
