class_name PoteEnums
extends Object

## 相棒ポテの成長段階
enum GrowthStage {
	EGG,       # タマゴ
	BABY,      # 幼年期（バブポテ）
	CHILD,     # 成長期（ヤングポテ）
	ADULT,     # 成熟期（ダチポテ）
	MASTER     # 究極進化（レジェンドポテ）
}

## オートストップを要求する緊急イベント要因
enum EmergencyReason {
	NONE,
	STARVING,           # 満腹度ゼロ（「おいダチ公、メシくれ！」）
	BATHROOM_CRITICAL,  # 便意限界（「ヤバい、漏れる！！」）
	EXHAUSTION,         # 疲労限界（「もう動けねぇ…」）
	EGG_HATCHING,       # タマゴ孵化の瞬間
	EVOLUTION_READY,    # 進化の兆候・スタンバイ
	WILD_ENCOUNTER,     # 野生ポテの乱入エンカウント
	LIFESPAN_END        # 寿命・世代交代
}

## ポテの現在の気分・アティチュード
enum BuddyMood {
	NORMAL,     # いつものダチ感
	HAPPY,      # ゴキゲン・ハイタッチ
	HUNGRY,     # ハラヘリ
	PANIC,      # 便意・ピンチ
	TIRED,      # バテ気味
	HYPED       # バトル・進化前夜のワクワク
}
