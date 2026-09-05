# PoteDatabase.gd
# 全ポテ種族・4種タマゴ・進化ツリー・属性・セリフ・勝率進化条件管理シングルトン (Autoload)
extends Node

var species_dict: Dictionary = {}

## タマゴ選択肢リスト
const EGG_OPTIONS = [
	{"id": "egg_drak", "name": "🔥 ドラタマ", "desc": "燃える闘志を宿す竜のタマゴ。格闘竜系統へ育つ。"},
	{"id": "egg_byte", "name": "⚡ ビットタマ", "desc": "電脳回路が脈打つデジタルのタマゴ。電脳メカ系統へ育つ。"},
	{"id": "egg_fang", "name": "🐺 ビスタマ", "desc": "野性の咆哮を秘めた獣のタマゴ。疾風狼系統へ育つ。"},
	{"id": "egg_slime", "name": "👑 ヌメタマ", "desc": "ぷにぷに柔らかい謎のタマゴ。宇宙変異系統へ育つ。"}
]


func _enter_tree() -> void:
	_init_species()


func _ready() -> void:
	if species_dict.is_empty():
		_init_species()
	print("[PoteDatabase] 種族データベース登録完了: %d 件" % species_dict.size())


func get_species(species_id: String) -> PoteSpeciesData:
	if species_dict.is_empty():
		_init_species()
	if species_dict.has(species_id):
		return species_dict[species_id]
	return species_dict.get("baby_drak", null)


func _init_species() -> void:
	species_dict.clear()

	# ==========================================================================
	# 0. EGG (4種のタマゴ)
	# ==========================================================================
	species_dict["egg_basic"] = PoteSpeciesData.create(
		"egg_basic", "ポテタマ", PoteEnums.GrowthStage.EGG,
		PoteSpeciesData.AttributeType.BRAWLER,
		"すべての原点となる基本タマゴ。",
		"  ( ● )  \n[ ポテタマ ]",
		"……（中から微かな鼓動が聞こえる）", "……（温かいミルクを吸収した！）", "殻を破って相棒が生まれたぞ！",
		[{"target_id": "baby_drak", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}]
	)
	species_dict["egg_pote"] = species_dict["egg_basic"]

	species_dict["egg_drak"] = PoteSpeciesData.create(
		"egg_drak", "ドラタマ", PoteEnums.GrowthStage.EGG,
		PoteSpeciesData.AttributeType.BRAWLER,
		"燃える闘志を宿す竜のタマゴ。温めると熱を帯びる。",
		"  ( 🔥 )  \n[ ドラタマ ]",
		"……（タマゴが熱く脈打っている！）", "……（熱血エネルギーを吸収した！）", "殻を突き破って竜の幼体が誕生した！",
		[{"target_id": "baby_drak", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}]
	)

	species_dict["egg_byte"] = PoteSpeciesData.create(
		"egg_byte", "ビットタマ", PoteEnums.GrowthStage.EGG,
		PoteSpeciesData.AttributeType.TECH,
		"電脳回路が刻まれたタマゴ。デジタル信号を放つ。",
		"  ( ⚡ )  \n[ ビットタマ ]",
		"……（ピピピ…起動シグナルを受信中）", "……（パケットデータを充電完了！）", "データ同期完了！電脳幼体が実体化した！",
		[{"target_id": "baby_byte", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}]
	)

	species_dict["egg_fang"] = PoteSpeciesData.create(
		"egg_fang", "ビスタマ", PoteEnums.GrowthStage.EGG,
		PoteSpeciesData.AttributeType.BEAST,
		"もふもふの温もりを持つ獣のタマゴ。",
		"  ( 🐾 )  \n[ ビスタマ ]",
		"……（くんくん…かすかに息遣いがする）", "……（美味しい匂いにタマゴが揺れた！）", "元気いっぱいに獣の幼体が飛び出した！",
		[{"target_id": "baby_fang", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}]
	)

	species_dict["egg_slime"] = PoteSpeciesData.create(
		"egg_slime", "ヌメタマ", PoteEnums.GrowthStage.EGG,
		PoteSpeciesData.AttributeType.MUTANT,
		"ぷにぷに弾力のある不思議なタマゴ。",
		"  ( 👑 )  \n[ ヌメタマ ]",
		"……（ぷるぷる…タマゴが揺れている）", "……（なんでも吸い込んでしまった！）", "ぷるんと殻が溶けてヌメ幼体が現れた！",
		[{"target_id": "baby_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}]
	)

	# ==========================================================================
	# 1. BABY (4種の幼年期)
	# ==========================================================================
	species_dict["baby_drak"] = PoteSpeciesData.create(
		"baby_drak", "バブポテ", PoteEnums.GrowthStage.BABY,
		PoteSpeciesData.AttributeType.BRAWLER,
		"格闘竜系統の幼体。元気いっぱい暴れん坊。",
		" (*'ω'*)\n[ バブポテ ]",
		"ばぶっ！相棒、よろしくな！", "もぐもぐ！肉うめぇ！", "うおおっ！？体が大きくなっていく…！",
		[
			{"target_id": "child_drak", "min_sync": 50.0, "min_win_rate": 0.50, "min_battles": 2},
			{"target_id": "child_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)
	species_dict["baby_pote"] = species_dict["baby_drak"]

	species_dict["baby_byte"] = PoteSpeciesData.create(
		"baby_byte", "プチビット", PoteEnums.GrowthStage.BABY,
		PoteSpeciesData.AttributeType.TECH,
		"電脳メカ系統の幼体。ピコピコ電子音を鳴らす。",
		" [•_•]\n[ プチビット ]",
		"ピピ！相棒、システムリンク接続完了！", "エネルギーチャージ中…満腹度UP！", "システムアップデート！成長シグナル検知！",
		[
			{"target_id": "child_byte", "min_sync": 50.0, "min_win_rate": 0.50, "min_battles": 2},
			{"target_id": "child_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["baby_fang"] = PoteSpeciesData.create(
		"baby_fang", "パピポテ", PoteEnums.GrowthStage.BABY,
		PoteSpeciesData.AttributeType.BEAST,

		"疾風狼系統の幼体。尻尾を振って甘えてくる。",
		" ∪･ω･∪\n[ パピポテ ]",
		"くぅ〜ん！相棒、遊ぼうぜ！", "ハフハフ！ごちそうさまだワン！", "野生の力が目覚める…！大きくなるぞ！",
		[
			{"target_id": "child_fang", "min_sync": 50.0, "min_win_rate": 0.50, "min_battles": 2},
			{"target_id": "child_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["baby_slime"] = PoteSpeciesData.create(
		"baby_slime", "プニポテ", PoteEnums.GrowthStage.BABY,
		PoteSpeciesData.AttributeType.MUTANT,
		"宇宙変異系統の幼体。不定形でマイペース。",
		" (〜'ω')〜\n[ プニポテ ]",
		"ぷに〜！相棒、ダラダラいこう〜", "ごくごく…なんでもうまい〜", "ぷるぷる…すごい形になってきた〜！",
		[
			{"target_id": "child_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	# ==========================================================================
	# 2. CHILD (成長期 4種)
	# ==========================================================================
	species_dict["child_drak"] = PoteSpeciesData.create(
		"child_drak", "ドラポテ", PoteEnums.GrowthStage.CHILD,
		PoteSpeciesData.AttributeType.BRAWLER,
		"炎の闘志を秘めた小竜型ポテ。熱いダチ。",
		" ᕙ(🔥ω🔥)ᕗ\n[ ドラポテ ]",
		"オイ相棒！今日も気合入れて特訓だぜ！", "うめぇ！パワーがモリモリ湧いてきたぜ！", "胸の炎が燃え盛る…！進化だ、相棒ォォッ！！",
		[
			{"target_id": "adult_flame", "min_sync": 65.0, "min_win_rate": 0.60, "min_battles": 5},
			{"target_id": "adult_king_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["child_byte"] = PoteSpeciesData.create(
		"child_byte", "ビットポテ", PoteEnums.GrowthStage.CHILD,
		PoteSpeciesData.AttributeType.TECH,
		"回路パターンが刻まれた電脳型ポテ。理論派な相棒。",
		" [■_■]⚡\n[ ビットポテ ]",
		"システムオールグリーン。効率よく行こうぜ、相棒。", "エネルギーチャージ完了。カロリー効率最適化！", "プログラム拡張シグナル検知。新バージョンへアップデート！",
		[
			{"target_id": "adult_cyber", "min_sync": 65.0, "min_win_rate": 0.60, "min_battles": 5},
			{"target_id": "adult_king_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["child_fang"] = PoteSpeciesData.create(
		"child_fang", "ウルポテ", PoteEnums.GrowthStage.CHILD,
		PoteSpeciesData.AttributeType.BEAST,
		"鋭いキバともふもふの毛並みを持つ狼型ポテ。",
		" /ᐠ. ᆺ .ᐟ\\\n[ ウルポテ ]",
		"ワオーン！相棒、一緒に野原を駆け回ろうぜ！", "ガツガツ！肉うめぇ！もっと食いたいぜ！", "野生の血が騒ぐ…！嵐を呼ぶ進化だ！",
		[
			{"target_id": "adult_gale", "min_sync": 65.0, "min_win_rate": 0.60, "min_battles": 5},
			{"target_id": "adult_king_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["child_slime"] = PoteSpeciesData.create(
		"child_slime", "ヌメポテ", PoteEnums.GrowthStage.CHILD,
		PoteSpeciesData.AttributeType.MUTANT,
		"ぬめぬめした軟体型ポテ。どこか憎めない愛嬌者。",
		" ~(˘▾˘~)\n[ ヌメポテ ]",
		"ふぁ〜あ…相棒、今日もダラダラいこうや〜", "ずるずる…うまい！なんでも食うぜ〜", "ぬめぬめパワーMAX! 驚きの変異進化だ〜！",
		[
			{"target_id": "adult_king_slime", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	# ==========================================================================
	# 3. ADULT (成熟期 4種)
	# ==========================================================================
	species_dict["adult_flame"] = PoteSpeciesData.create(
		"adult_flame", "バーンポテ", PoteEnums.GrowthStage.ADULT,
		PoteSpeciesData.AttributeType.BRAWLER,
		"灼熱の業火を纏う立派な格闘竜ポテ。頼れる兄貴分。",
		" (ง🔥Д🔥)ง\n[ バーンポテ ]",
		"背中は任せろ相棒！どんな強敵もブッ倒すぜ！", "ガッツリ食ってパワー全開だ！サンキュー相棒！", "オレの魂が極限突破する…！究極奥義を解き放つ時だ！！",
		[
			{"target_id": "master_wargod", "min_sync": 80.0, "min_win_rate": 0.70, "min_battles": 10},
			{"target_id": "master_cosmic", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["adult_cyber"] = PoteSpeciesData.create(
		"adult_cyber", "ギアポテ", PoteEnums.GrowthStage.ADULT,
		PoteSpeciesData.AttributeType.TECH,
		"重装甲と高出力スラスターを備えた電脳重装甲ポテ。",
		" ⚙️[◣_◢]⚙️\n[ ギアポテ ]",
		"戦闘準備完了。相棒の指示を待つ。", "燃料補給確認。全出力稼働可能。", "オーバークロック限界解除…神話級アーキテクチャへ移行！",
		[
			{"target_id": "master_omega", "min_sync": 80.0, "min_win_rate": 0.70, "min_battles": 10},
			{"target_id": "master_cosmic", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["adult_gale"] = PoteSpeciesData.create(
		"adult_gale", "ガルポテ", PoteEnums.GrowthStage.ADULT,
		PoteSpeciesData.AttributeType.BEAST,

		"銀の風を切り裂いて駆ける疾風の神速狼ポテ。",
		" 🐺彡[◣ω◢]\n[ ガルポテ ]",
		"風が呼んでいる…相棒、オレについてこれるか？", "獲物の味は格別だぜ！血湧き肉躍るな！", "大自然の聖なる咆哮がオレを満たす…究極覚醒だ！",
		[
			{"target_id": "master_fenrir", "min_sync": 80.0, "min_win_rate": 0.70, "min_battles": 10},
			{"target_id": "master_cosmic", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	species_dict["adult_king_slime"] = PoteSpeciesData.create(
		"adult_king_slime", "キングヌメ", PoteEnums.GrowthStage.ADULT,
		PoteSpeciesData.AttributeType.MUTANT,
		"王冠をかぶった巨大なぬめぬめポテ。妙なカリスマがある。",
		" 👑~(˘▾˘~)\n[ キングヌメ ]",
		"余こそがヌメの王…相棒、肩を揉んでくれ〜", "うむ、苦しゅうない！メシのおかわりを所望する〜", "宇宙の深淵から声が聞こえる…全てを超越するぞ〜！",
		[
			{"target_id": "master_cosmic", "min_sync": 0.0, "min_win_rate": 0.0, "min_battles": 0}
		]
	)

	# ==========================================================================
	# 4. MASTER (究極体 4種)
	# ==========================================================================
	species_dict["master_wargod"] = PoteSpeciesData.create(
		"master_wargod", "覇神ウォーポテ", PoteEnums.GrowthStage.MASTER,
		PoteSpeciesData.AttributeType.BRAWLER,
		"伝説の竜闘気を纏う不敗の覇神。相棒との最高の絆の結晶。",
		" 👑ᕙ(🔥口🔥)ᕗ👑\n[ 覇神ウォーポテ ]",
		"相棒…オレたちはここまで強くなった！天下無双だぜッ！！",
		"美味い！これぞ至高の糧だ！",
		"",
		[]
	)

	species_dict["master_omega"] = PoteSpeciesData.create(
		"master_omega", "オメガビットポテ", PoteEnums.GrowthStage.MASTER,
		PoteSpeciesData.AttributeType.TECH,
		"全宇宙の演算データを司る究極の電脳聖騎士ポテ。",
		" ⚔️[Ω_Ω]🛡️\n[ オメガビットポテ ]",
		"全事象の計算完了。相棒と共に永遠の未来を切り拓く。",
		"エネルギー供給確認。完全調和状態。",
		"",
		[]
	)

	species_dict["master_fenrir"] = PoteSpeciesData.create(
		"master_fenrir", "聖狼フェンリルポテ", PoteEnums.GrowthStage.MASTER,
		PoteSpeciesData.AttributeType.BEAST,
		"銀河を駆ける伝説の聖なる白狼ポテ。誇り高き相棒。",
		" 🌕🐺✨\n[ 聖狼フェンリルポテ ]",
		"星々が我らの絆を讃えている…相棒、共に天を翔けよう！",
		"大いなる恵みに感謝を。力が満ち溢れる。",
		"",
		[]
	)

	species_dict["master_cosmic"] = PoteSpeciesData.create(
		"master_cosmic", "コズミックポテ", PoteEnums.GrowthStage.MASTER,
		PoteSpeciesData.AttributeType.MUTANT,
		"時空を超越した宇宙生命体ポテ。もはや何を考えているのか誰にも分からない。",
		" 🌌🌀(◉▾◉)🌀🌌\n[ コズミックポテ ]",
		"フフフ…宇宙の理が見える…相棒、とりあえず寝ようぜ〜",
		"星屑の味がする…うまい〜",
		"",
		[]
	)
