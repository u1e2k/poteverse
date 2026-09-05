# PoteSpeciesData.gd
class_name PoteSpeciesData
extends RefCounted

enum AttributeType {
	BRAWLER,   # 熱血・格闘系（オラオラ系・熱いダチ）
	TECH,      # 電脳・メカ系（クール・論理的・ギークな相棒）
	BEAST,     # 野生・ケモノ系（やんちゃ・食いしん坊・俊敏）
	MUTANT     # 異形・脱力系（マイペース・ヌメヌメ・変則）
}

var id: String = "baby_pote"
var name: String = "バブポテ"
var stage: PoteEnums.GrowthStage = PoteEnums.GrowthStage.BABY
var attribute: AttributeType = AttributeType.BRAWLER
var description: String = "すべてのポテの原点。やんちゃで好奇心旺盛な相棒。"

var avatar_art: String = " (*'ω'*)\n[ バブポテ ]"

var dialogue_greeting: String = "ばぶっ！相棒、よろしくな！"
var dialogue_feed: String = "もぐもぐ！うめぇ！"
var dialogue_toilet_emergency: String = "ふぇぇ…！漏れちゃうよ〜！"
var dialogue_toilet_success: String = "すっきり〜！ありがと相棒！"
var dialogue_starve_emergency: String = "ハラペコだよ〜！何かちょうだい！"
var dialogue_exhaust_emergency: String = "くぅ…眠いよぉ…"
var dialogue_evolve: String = "うおおっ！？オレの体が大きくなっていく…！"

var evolution_branches: Array[Dictionary] = []


static func create(
	p_id: String,
	p_name: String,
	p_stage: PoteEnums.GrowthStage,
	p_attr: AttributeType,
	p_desc: String,
	p_art: String,
	p_greet: String,
	p_feed: String,
	p_evolve: String,
	p_branches: Array[Dictionary] = []
) -> PoteSpeciesData:
	var sp = PoteSpeciesData.new()
	sp.id = p_id
	sp.name = p_name
	sp.stage = p_stage
	sp.attribute = p_attr
	sp.description = p_desc
	sp.avatar_art = p_art
	sp.dialogue_greeting = p_greet
	sp.dialogue_feed = p_feed
	sp.dialogue_evolve = p_evolve
	sp.evolution_branches = p_branches
	return sp
