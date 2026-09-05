# PoteCryoStorage.gd
# ANBERNIC RG Rotate 向け 相棒ポテ凍結（コールドスリープ）・保存管理シングルトン (Autoload)
extends Node

signal storage_updated()
signal pote_frozen(slot_index: int, species_name: String)
signal pote_thawed(slot_index: int, species_name: String)

const MAX_SLOTS: int = 4
const STORAGE_FILE_PATH: String = "user://cryo_storage.json"

## スロット配列: 各要素はDictionary (空の場合は空辞書 {})
var slots: Array[Dictionary] = []


func _ready() -> void:
	_init_slots()
	load_storage()
	print("[PoteCryoStorage] 凍結ポッド保管庫 初期化完了。スロット数: %d" % MAX_SLOTS)


func _init_slots() -> void:
	slots.clear()
	for i in range(MAX_SLOTS):
		slots.append({})


## 現在アクティブな相棒ポテを指定スロットに凍結保存
func freeze_current_pote(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		push_error("[PoteCryoStorage] 不正なスロット番号: %d" % slot_index)
		return false

	var state_dict = PoteState.export_state_dict()
	slots[slot_index] = state_dict
	save_storage()

	var sp_name = PoteState.current_species.name if PoteState.current_species else "相棒"
	print("[PoteCryoStorage] スロット %d に %s を凍結保存しました。" % [slot_index + 1, sp_name])
	pote_frozen.emit(slot_index, sp_name)
	storage_updated.emit()
	return true


## 指定スロットの凍結相棒を解凍（現在の相棒と入れ替え）
func thaw_pote(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		push_error("[PoteCryoStorage] 不正なスロット番号: %d" % slot_index)
		return false

	var slot_data = slots[slot_index]
	if slot_data.is_empty():
		push_warning("[PoteCryoStorage] スロット %d は空です。" % slot_index)
		return false

	# 現在の相棒状態を取得し、復元
	PoteState.import_state_dict(slot_data)
	
	# 解凍したスロットを空にする（取り出し）
	slots[slot_index] = {}
	save_storage()

	var sp_name = PoteState.current_species.name if PoteState.current_species else "相棒"
	print("[PoteCryoStorage] スロット %d から %s を解凍・復帰しました。" % [slot_index + 1, sp_name])
	pote_thawed.emit(slot_index, sp_name)
	storage_updated.emit()
	return true


## 指定スロットのデータを消去
func delete_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false
	slots[slot_index] = {}
	save_storage()
	storage_updated.emit()
	return true


## 現在の相棒を凍結後、新タマゴをもらって新規育成を開始
func freeze_and_start_new_egg(slot_index: int, new_name: String = "ポテまる") -> bool:
	if freeze_current_pote(slot_index):
		PoteState.reset_to_new_egg(new_name)
		return true
	return false


## スロットの要約情報を取得
func get_slot_info(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	var data = slots[slot_index]
	if data.is_empty():
		return {"is_empty": true}

	var sp_id = data.get("current_species_id", "")
	var sp_name = "未確認種"
	var stage_name = "UNKNOWN"
	if PoteDatabase:
		var sp = PoteDatabase.get_species(sp_id)
		if sp:
			sp_name = sp.name
			stage_name = PoteEnums.GrowthStage.keys()[sp.stage]

	return {
		"is_empty": false,
		"buddy_name": data.get("buddy_name", "ポテまる"),
		"species_id": sp_id,
		"species_name": sp_name,
		"stage_name": stage_name,
		"total_ticks": data.get("total_alive_ticks", 0),
		"sync": data.get("buddy_sync", 50.0),
		"saved_at": data.get("saved_at", "")
	}


## JSON永続化
func save_storage() -> void:
	var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(slots, "\t")
		file.store_string(json_str)
		file.close()
	else:
		push_error("[PoteCryoStorage] ストレージ保存失敗: %s" % STORAGE_FILE_PATH)


## JSON読み込み
func load_storage() -> void:
	if not FileAccess.file_exists(STORAGE_FILE_PATH):
		return

	var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_str)
		if parse_result is Array:
			slots.clear()
			for i in range(MAX_SLOTS):
				if i < parse_result.size() and parse_result[i] is Dictionary:
					slots.append(parse_result[i])
				else:
					slots.append({})
