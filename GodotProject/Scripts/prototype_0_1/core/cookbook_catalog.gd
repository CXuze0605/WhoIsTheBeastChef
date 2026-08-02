class_name CookbookCatalog
extends RefCounted

# 烹饪大典 —— 所有已实现料理的元数据目录
# 数值摘要基于 PrototypeCombatConfig 当前原型配置编写，以实际战斗为准。

# 料理条目数据结构
class DishEntry:
	var recipe_id: StringName        # 唯一标识
	var display_name: String         # 中文名
	var cooking_method: String       # 烹饪方式
	var attack_form: String          # 战斗形态
	var description: String          # 简短描述
	var art_key: StringName          # 美术键
	var can_plate: bool              # 是否可摆盘
	var has_perfect: bool            # 是否有完美终结
	var is_healing: bool             # 是否为回复型
	var ingredients: String          # 烹饪路径（用料与做法）
	var stat_text: String            # 数值摘要（原型配置）
	var lore: String                 # 主题风味文案
	var tips: String                 # 实战提示

	func _init(
		rid: StringName, name: String, method: String, form: String,
		desc: String, key: StringName, plate: bool, perfect: bool, healing: bool,
		ing: String, stat: String, lore_text: String, tip: String
	):
		recipe_id = rid
		display_name = name
		cooking_method = method
		attack_form = form
		description = desc
		art_key = key
		can_plate = plate
		has_perfect = perfect
		is_healing = healing
		ingredients = ing
		stat_text = stat
		lore = lore_text
		tips = tip


# 解锁状态
static var _unlocked: Dictionary = {}          # recipe_id → bool
static var _test_hall_mode: bool = false


static func get_all_dishes() -> Array[DishEntry]:
	var dishes: Array[DishEntry] = []
	dishes.append(DishEntry.new(
		&"stir_fry_beef", "小炒黄牛肉", "炒", "远程冲锋（愤怒公牛）",
		"腌制牛肉片加辣椒段，旺火快炒。按住鼠标左键持续释放穿透敌人的公牛。",
		&"plated_stir_fry_beef", true, true, false,
		"腌制牛肉片 + 辣椒段 → 旺火快炒",
		"公牛冲锋命中 20 伤害 · 速度 500 · 冲锋距离 430",
		"愤怒的公牛冲进人群，把失衡狠狠撞回正轨。",
		"按住左键持续释放公牛；沿直线穿透多个敌人时收益最高。",
	))
	dishes.append(DishEntry.new(
		&"tomahawk_steak", "战斧牛排", "煎", "近战扇形挥砍",
		"生牛排煎至双面金黄。扇形近战攻击，完美耗尽生成可投掷的大骨头。",
		&"tomahawk_steak", true, true, false,
		"生牛排 → 双面煎制（把握两次翻面时机）",
		"挥砍 42 伤害 · 耐久 8 · 射程 112 · 扇形 92° · 强击退",
		"一块厚实的战斧，是最诚实、最过瘾的一餐。",
		"完美煎制后挥砍更强；挥砍间隙较长，注意出手节奏。",
	))
	dishes.append(DishEntry.new(
		&"shabu_beef", "涮牛肉", "煮", "诱食陷阱",
		"生牛肉片在沸汤中涮煮。放置后吸引味真族品尝，造成一次复味伤害。",
		&"shabu_beef_single", false, false, false,
		"生牛肉片 → 沸水涮煮（1.6 秒内捞出最佳）",
		"诱食陷阱 · 命中 26 伤害 · 香味半径 310",
		"一口沸汤，足以让走神的味蕾回头。",
		"放置后吸引周围敌人靠近品尝；涮过头会变柴变差。",
	))
	dishes.append(DishEntry.new(
		&"white_rice", "白米饭", "煮", "远程投掷（饭团）",
		"生米加一份水煮熟。连续投掷饭团攻击，可紧急食用。",
		&"plated_white_rice", true, false, true,
		"生米 + 一份水 → 煮 8 秒",
		"饭团 6.7 伤害 · 耐久 18 · 射程 560 · 攻速 0.3 秒",
		"一碗白米饭，是支撑一天的本味。",
		"攻速快、射程远；危急时可紧急食用回复 5 生命。",
	))
	dishes.append(DishEntry.new(
		&"rice_porridge", "白粥", "煮", "原地饮用（治疗）",
		"生米加两份水慢煮成粥。每次饮用恢复生命，但刚出锅会烫伤。",
		&"plated_rice_porridge", true, false, true,
		"生米 + 两份水 → 慢煮 12 秒",
		"饮用恢复 10 生命（完美 12）· 出锅 10 秒内烫口（4 伤害/2 秒）",
		"烫口的白粥，是惦记你的人端来的温度。",
		"刚出锅别急着喝，先晾一晾；完美出锅恢复最高。",
	))
	dishes.append(DishEntry.new(
		&"crispy_rice", "锅巴", "煮", "装备减伤（盾）",
		"白米饭继续加热形成锅巴。装备后获得减伤，破碎时对周围造成伤害。",
		&"plated_crispy_rice", true, false, false,
		"白米饭 → 继续加热 5 秒成锅巴（4 秒后可能烧焦）",
		"装备减伤 25%（完美 35%）· 耐久 5 · 破碎小范围 20 伤害",
		"焦香的锅巴，是米饭最后的倔强。",
		"完美锅巴减伤最高；被打碎时还能伤到周围敌人。",
	))
	dishes.append(DishEntry.new(
		&"boiled_greens", "盐水青菜", "煮", "近身自动触发（每片一次）",
		"青菜叶在盐水中煮制。放在背包或快捷栏中，敌人靠近时自动触发一次击退与短暂眩晕；每片菜叶提供一次机会。",
		&"boiled_greens", true, false, false,
		"青菜叶 → 盐水煮制",
		"光圈半径 124 · 每 0.8 秒击退 105 · 眩晕 0.18 秒",
		"一碟碧绿，是战场边缘的一点清爽。",
		"放置型控场，耐久按叶片数计算；适合封住敌人来路。",
	))
	dishes.append(DishEntry.new(
		&"stir_fry_greens", "清炒青菜", "炒", "远程（菜叶投掷）",
		"青菜叶猛火快炒。投掷菜叶攻击。",
		&"stir_fry_greens", true, true, false,
		"青菜叶 → 猛火快炒",
		"菜叶 14 伤害 · 穿透 3 · 射程 460 · 耐久 14",
		"猛火锁住叶绿，投出去的是一道春光。",
		"穿透性菜叶适合对付直线排队的敌人。",
	))
	dishes.append(DishEntry.new(
		&"spicy_stir_fry_greens", "辣味清炒青菜", "炒", "远程（易伤投掷）",
		"加辣椒同炒的青菜。附带易伤效果。",
		&"spicy_stir_fry_greens", true, true, false,
		"青菜叶 + 辣椒段 → 同炒",
		"菜叶 14 伤害 · 附带易伤 8%（持续 3 秒）",
		"一点辣意，让原本安静的青菜有了脾气。",
		"先手挂易伤，再切高伤料理收尾。",
	))
	dishes.append(DishEntry.new(
		&"flash_stir_fry_greens", "炝炒青菜", "炒", "远程（命中爆开·呛到）",
		"猛火快炒至微焦的青菜。命中首个目标或到达最大距离时爆开，范围施加呛到失瞄，不造成范围伤害。",
		&"flash_stir_fry_greens", true, true, false,
		"青菜叶 → 猛火快炒至微焦",
		"炝叶 18 伤害 · 速度 760 · 终点爆炸半径 105",
		"炝出锅气的青菜，在终点炸开一束脆响。",
		"穿透后在终点爆炸，适合远程清群。",
	))
	dishes.append(DishEntry.new(
		&"plain_beef_porridge", "普通牛肉粥", "煮", "原地饮用（治疗）",
		"使用未腌牛肉制作，失去完美品质机会，获得略低于生滚牛肉粥的本体攻击增益。",
		&"plain_beef_porridge", true, false, true,
		"白粥 + 未腌牛肉 → 煮制",
		"恢复 8 生命 · 玩家本体伤害增幅 8% · 无完美品质",
		"没有腌制，也能煮出一碗救急的牛肉粥。",
		"作为生滚牛肉粥的低配替代；召唤物和炮台不获得增幅。",
	))
	dishes.append(DishEntry.new(
		&"greens_porridge", "青菜粥", "煮", "原地饮用（治疗）",
		"白粥加入青菜叶。恢复生命。",
		&"greens_porridge", true, true, true,
		"白粥 + 青菜叶 → 短煮 3 秒",
		"饮用恢复 10 生命 · 完美后 5 秒持续回 1/秒",
		"一碗青菜粥，是最温柔的下火方。",
		"完美出锅附带持续恢复，适合战后补给。",
	))
	dishes.append(DishEntry.new(
		&"beef_porridge", "牛肉粥", "煮", "原地饮用（治疗）",
		"白粥加入牛肉丁。恢复生命，完美最后一口获得持续恢复。",
		&"beef_porridge", true, true, true,
		"白粥 + 牛肉丁 → 短煮 3.6 秒",
		"饮用恢复 8 生命 · 直伤加成 10%（完美 20%，持续 8 秒）",
		"牛肉的香气沉进粥底，喝下去才觉得稳了。",
		"开战前喝一口，6 秒内直伤提升；完美持续更久。",
	))
	dishes.append(DishEntry.new(
		&"greens_beef_porridge", "青菜牛肉粥", "煮", "原地饮用（治疗）",
		"白粥同时加入青菜和牛肉。全面恢复。",
		&"greens_beef_porridge", true, true, true,
		"白粥 + 青菜 + 牛肉 → 短煮 3.2 秒",
		"恢复 8 生命 + 直伤加成 8%（完美 15%）· 完美附带持续回血",
		"荤素同粥，是厨房里最周全的一碗。",
		"全面恢复型；完美收益最高，值得等一个完美出锅。",
	))
	dishes.append(DishEntry.new(
		&"beef_greens", "青菜炒牛肉", "炒", "近战扇形",
		"牛肉片和青菜段混炒。扇形近战攻击。",
		&"beef_greens", true, true, false,
		"牛肉片 + 青菜段 → 混炒",
		"扇形中心 36 / 两侧 18 伤害 · 范围 148 · 耐久 16",
		"一荤一素，大火里炒出踏实的一顿。",
		"扇形近战，正面命中伤害最高。",
	))
	dishes.append(DishEntry.new(
		&"beef_greens_rice_bowl", "青菜牛肉盖饭", "组合", "三弹种自动炮台",
		"放置后随机发射饭团、青菜和牛肉三种弹体，分别负责范围、穿透和单点伤害。",
		&"beef_greens_rice_bowl", true, true, false,
		"白饭 + 青菜 + 牛肉 → 盖饭",
		"饭团低伤害范围弹 · 青菜中伤害穿透弹 · 牛肉高伤害单点弹",
		"一碗饭里，三种火力各司其职。",
		"适合提前布置；完美品质提升炮台整体输出。",
	))
	dishes.append(DishEntry.new(
		&"greens_fried_rice", "青菜炒饭", "炒", "远程（米粒散射）",
		"白米饭加青菜炒制。散射米粒攻击。",
		&"greens_fried_rice", true, true, false,
		"白米饭 + 青菜 → 炒制",
		"米粒 15 伤害 · 散射半径 112（完美 182）· 耐久 14",
		"米粒裹着菜香飞出去，像一场小小的春雨。",
		"完美炒饭散射范围更大，清群更稳。",
	))
	dishes.append(DishEntry.new(
		&"beef_fried_rice", "牛肉炒饭", "炒", "远程（米粒散射）",
		"白米饭加牛肉炒制。散射带击退的米粒。",
		&"beef_fried_rice", true, true, false,
		"白米饭 + 牛肉 → 炒制",
		"主米粒 50 伤害 · 吸附半径 48 · 完美 1.28 倍 · 耐久 12",
		"肉香浸透每一粒米，弹出去的都是硬菜。",
		"带击退的米粒可以打断敌人动作。",
	))
	dishes.append(DishEntry.new(
		&"mixed_fried_rice", "混合炒饭", "炒", "远程（米粒散射）",
		"白米饭加牛肉和青菜。散射高伤害米粒。",
		&"mixed_fried_rice", true, true, false,
		"白米饭 + 牛肉 + 青菜 → 炒制",
		"主粒 40 / 溅射 11 · 半径 92（完美 132）· 耐久 14",
		"什么都放一点的炒饭，往往是最好吃的那盘。",
		"高伤害主力输出，完美范围更大。",
	))
	dishes.append(DishEntry.new(
		&"vegetable_rice", "菜饭", "煮", "原地食用（治疗）",
		"米饭与青菜同煮。可食用恢复。",
		&"vegetable_rice", true, true, true,
		"生米 + 青菜 → 同煮 9 秒",
		"每口获得 7 护盾 · 吃完减伤 15%（5 秒）· 耐久 8",
		"菜饭是家的味道，一口护盾一口安心。",
		"可以分段食用，每一口都加护盾。",
	))
	dishes.append(DishEntry.new(
		&"soaked_rice", "泡饭", "煮", "区域（易伤/虚弱）",
		"一份水泡米饭。放置后对范围内敌人施加易伤和虚弱。",
		&"soaked_rice", true, false, false,
		"米饭 + 一份水 → 泡煮 3.2 秒",
		"区域半径 145（完美 205）· 持续 5 秒（完美 7 秒）· 减速 25%/攻速 20%",
		"泡饭温温软软，却能让敌人慢下脚步。",
		"放置型削弱区域，完美范围更大、持续更久。",
	))
	dishes.append(DishEntry.new(
		&"greens_soaked_rice", "青菜泡饭", "煮", "区域（易伤/虚弱）",
		"青菜加泡饭。范围更大。",
		&"greens_soaked_rice", true, false, false,
		"泡饭 + 青菜叶 → 泡煮 2.6 秒",
		"范围内敌人弱点 +3%/叶（上限 15%，完美 20%）",
		"一点青绿沉进泡饭，味道和减益一起散开。",
		"叶片越多弱点越高；配合高伤料理事半功倍。",
	))
	dishes.append(DishEntry.new(
		&"beef_soaked_rice", "牛肉泡饭", "煮", "区域（易伤/虚弱）",
		"牛肉加泡饭。持续伤害并施加易伤。",
		&"beef_soaked_rice", true, false, false,
		"泡饭 + 牛肉 → 同煮",
		"范围内敌人易伤 +3%/份（上限 15%，完美 20%）· 附带持续伤害",
		"牛肉泡饭的热气里，藏着一点不客气的辣手。",
		"牛肉份量越多易伤越高，适合配合爆发。",
	))
	dishes.append(DishEntry.new(
		&"greens_beef_soaked_rice", "青菜牛肉泡饭", "煮", "区域（易伤/虚弱）",
		"青菜牛肉加泡饭。全面范围削弱。",
		&"greens_beef_soaked_rice", true, false, false,
		"泡饭 + 青菜 + 牛肉 → 同煮",
		"易伤 + 弱点双降 · 各自上限 15%（完美 20%）",
		"最周全的一碗泡饭，让一整片敌人都没了脾气。",
		"最全面的范围削弱，团战前放一个。",
	))
	dishes.append(DishEntry.new(
		&"beef_greens_soup", "青菜牛肉汤", "煮", "自动索敌（汤流）",
		"牛肉汤中加入青菜。自动追踪敌人并施加多层易伤。",
		&"beef_greens_soup", true, true, false,
		"牛肉汤 + 青菜 → 煮至入味 3.2 秒",
		"汤流持续伤害 · 范围 360 · 耐久 18 · 完美终结 26（半径 118）",
		"汤会自己找到喝它的人——以复味之名。",
		"自动追踪敌人，持续命中叠伤害；别让汤流空转。",
	))
	dishes.append(DishEntry.new(
		&"mustard_greens", "芥末青菜", "炒", "减益光环（零伤害）",
		"芥末拌青菜。自身无伤害，但降低周围敌人攻速移速并为携带者叠加减益。",
		&"mustard_greens", true, true, false,
		"青菜叶 + 芥末 → 拌匀 1.8 秒",
		"投叶弱点 18% + 减速 30% · 光环半径 120 · 自身无直接伤害",
		"呛鼻的芥末，是战场上最讲礼貌的武器。",
		"光环会波及队友——小心队友打喷嚏时误伤你。",
	))
	dishes.append(DishEntry.new(
		&"fried_white_rice", "炒白饭", "炒", "远程（米粒群）",
		"白米饭回锅炒制。一次释放多粒米攻击。",
		&"fried_white_rice", true, true, false,
		"白米饭 → 回锅炒 1.5 秒",
		"一次 20 粒米 · 单粒 3 伤害 · 射程 280 · 耐久 16",
		"剩饭回锅，粒粒分明，弹出去是一阵米雨。",
		"完美出锅附带敌人减速 8%。",
	))
	dishes.append(DishEntry.new(
		&"clear_stir_fry_beef", "清炒牛肉", "炒", "近战三/六连斩",
		"牛肉片不加辣椒清炒。快速三连近战，完美六连。",
		&"clear_stir_fry_beef", true, true, false,
		"牛肉片（不加辣椒）→ 快炒",
		"单斩 6 伤害 · 三连斩（完美六连）· 耐久 12",
		"不加辣，反而更考验火候与刀功。",
		"完美六连最后一斩范围更大并带眩晕。",
	))
	dishes.append(DishEntry.new(
		&"greens_soup", "青菜汤", "煮", "自动索敌（菜叶汤流）",
		"青菜叶煮汤。多道菜叶汤流自动追踪敌人。",
		&"greens_soup", true, true, false,
		"青菜叶 → 煮汤 2 秒",
		"汤流 2 伤害/0.25 秒 · 范围 280 · 减速 10% · 耐久 5",
		"清汤寡水，却让敌人走得越来越慢。",
		"多道汤流同时命中，减速控场一绝。",
	))
	dishes.append(DishEntry.new(
		&"beef_soup", "牛肉汤", "煮", "自动索敌（牛肉汤流）",
		"牛肉丁煮汤。一道汤流持续对前排敌人造成伤害和文火入味。",
		&"beef_soup", true, true, false,
		"牛肉丁 → 煮汤 2.5 秒",
		"汤流 5 伤害/0.25 秒 · 范围 360 · 耐久 14",
		"文火吊出的牛肉汤，浓得化不开。",
		"持续命中叠“入味”层数（最多 5 层），越烫越疼。",
	))
	dishes.append(DishEntry.new(
		&"greens_rice_bowl", "青菜盖饭", "炒", "炮台（持续投掷）",
		"青菜盖在米饭上。放置后持续投掷菜叶攻击附近敌人。",
		&"greens_rice_bowl", true, true, false,
		"米饭 + 青菜 → 盖饭炒制",
		"炮台投叶 18 伤害 · 范围 410 · 穿透 3 · 耐久 8",
		"一碗盖饭立在那里，就是一尊稳当的炮台。",
		"放在敌群必经之路，让它自己打工。",
	))
	dishes.append(DishEntry.new(
		&"beef_rice_bowl", "牛肉盖饭", "炒", "炮台（持续投掷）",
		"牛肉盖在米饭上。放置后持续投掷肉粒攻击。",
		&"beef_rice_bowl", true, true, false,
		"米饭 + 牛肉 → 盖饭炒制",
		"炮台投肉 42 伤害 · 范围 450 · 耐久 7",
		"肉香四溢的盖饭，连敌人都忍不住多看两眼。",
		"完美终结一击 90 伤害，注意摆放时机。",
	))
	dishes.append(DishEntry.new(
		&"beef_braised_rice", "牛肉焖饭", "煮", "原地进食",
		"牛肉与生米一同焖煮。直接食用获得治疗效果。",
		&"beef_braised_rice", true, true, true,
		"生米 + 牛肉 → 焖煮 9 秒",
		"食用直伤加成 12%（完美 20%）· 持续 7 秒（完美 10 秒）· 耐久 10",
		"一锅焖饭，把牛肉的汁水全收进米里。",
		"开战前吃一口，短时间内直伤提升。",
	))
	dishes.append(DishEntry.new(
		&"greens_beef_braised_rice", "青菜牛肉焖饭", "煮", "原地进食",
		"青菜牛肉焖饭。更全面的治疗效果。",
		&"greens_beef_braised_rice", true, true, true,
		"生米 + 青菜 + 牛肉 → 焖煮",
		"每口护盾 4 · 直伤加成 8%（完美 15% + 减伤 10%）",
		"一锅俱全，吃下去是满格的踏实。",
		"最全面的焖饭；完美出锅还附带减伤。",
	))
	dishes.append(DishEntry.new(
		&"crispy_rice_beef", "锅巴牛肉", "炸", "炸弹（延时爆炸）",
		"锅巴包裹牛肉碎炸制。放置后主炸弹爆炸分裂为碎弹。",
		&"crispy_rice_beef", true, true, false,
		"锅巴 + 牛肉碎 → 炸制",
		"主爆 120（完美 150）· 半径 180 · 分裂 8 块碎弹（各 35 伤害）",
		"咔的一声，是锅巴和牛肉在敌人中间开的会。",
		"会误伤队友（40% 伤害），投掷前看清站位。",
	))
	dishes.append(DishEntry.new(
		&"spicy_fried_rice", "辣椒炒饭", "炒", "远程（灼烧双环）",
		"辣椒与白米饭炒制。释放内外双环造成灼烧。",
		&"spicy_fried_rice", true, true, false,
		"白米饭 + 辣椒 → 炒制",
		"一次 18 粒 · 单粒 2.5 伤害 + 易伤 5%（完美 10%）",
		"双环灼烧，辣味一层层递进。",
		"内外双环覆盖，完美易伤更高，适合群体开胃。",
	))
	dishes.append(DishEntry.new(
		&"spicy_beef_greens", "辣味青菜炒牛肉", "炒", "近战扇形（灼烧）",
		"辣椒、青菜、牛肉同炒。附带灼烧效果的扇形近战。",
		&"spicy_greens_beef", true, true, false,
		"辣椒 + 青菜 + 牛肉 → 同炒",
		"中心 30 / 两侧 15 伤害 · 附带易伤 8%（完美 15%）· 耐久 16",
		"辣、香、绿，一把扇形扇得敌人口舌生津。",
		"扇形近战附易伤，配合后续爆发极佳。",
	))
	dishes.append(DishEntry.new(
		&"spicy_beef_fried_rice", "辣味牛肉炒饭", "炒", "远程（灼烧散射）",
		"辣椒牛肉炒饭。米粒附带灼烧。",
		&"spicy_beef_fried_rice", true, true, false,
		"辣椒 + 牛肉 + 白米饭 → 炒制",
		"主粒 38 伤害 · 易伤 12%（4 秒）· 完美 65 + 易伤 20% · 耐久 14",
		"辣味钻进肉里，再钻进敌人的防线。",
		"完美米粒伤害近乎翻倍还带眩晕。",
	))
	dishes.append(DishEntry.new(
		&"spicy_mixed_fried_rice", "辣味混合炒饭", "炒", "远程（灼烧散射）",
		"辣椒、牛肉、青菜炒饭。完美释放大范围灼烧。",
		&"spicy_mixed_fried_rice", true, true, false,
		"辣椒 + 牛肉 + 青菜 + 白米饭 → 炒制",
		"主粒 30 / 溅射 14 · 半径 105（完美 180）· 易伤 8%（3 秒）",
		"什么都敢放的炒饭，辣得理直气壮。",
		"完美大范围灼烧，是清群王牌。",
	))
	dishes.append(DishEntry.new(
		&"spicy_beef_soup", "辣牛肉汤", "煮", "自动索敌（灼烧汤流）",
		"加辣椒的牛肉汤。持续灼烧并叠加易伤。",
		&"spicy_beef_soup", true, true, false,
		"牛肉汤 + 辣椒 → 煮制",
		"汤流 4 伤害/0.25 秒 · 易伤叠层 2%/层（上限 5 层）",
		"辣汤追着敌人跑，越烫越不肯松口。",
		"持续命中叠易伤，适合长时间磨血。",
	))
	dishes.append(DishEntry.new(
		&"spicy_beef_greens_soup", "辣味青菜牛肉汤", "煮", "自动索敌（易伤汤流）",
		"加辣椒的青菜牛肉汤。纯易伤不造成直接伤害。",
		&"spicy_greens_beef_soup", true, true, false,
		"青菜牛肉汤 + 辣椒 → 煮制",
		"纯易伤汤流 · 易伤 8% + 弱点 10% · 无直接伤害",
		"它不伤人，只是让敌人变得好欺负。",
		"只挂减益不吃伤害，搭配高伤料理使用。",
	))
	dishes.append(DishEntry.new(
		&"pan_fried_rice_cake", "香煎米饼", "煎", "回旋镖（往返伤害）",
		"白米饭压饼煎制。投出后返回，往返均造成伤害。完美额外环绕。",
		&"plain_rice_cake", true, true, false,
		"白米饭压饼 → 煎制（把握翻面时机）",
		"去程 16 / 回程 12 伤害 · 穿透 3 · 耐久 12 · 完美额外环绕 12",
		"煎得两面金黄的米饼，飞出去还会回家。",
		"往返双段伤害；完美多一圈环绕，控场更强。",
	))
	dishes.append(DishEntry.new(
		&"greens_rice_cake", "青菜米饼", "煎", "环绕（多体减速）",
		"青菜米饼煎制。投出后环绕飞行减速多个敌人。",
		&"greens_rice_cake", true, true, false,
		"白米饭 + 青菜压饼 → 煎制",
		"环绕 11 伤害 · 减速 12%（完美 20%）· 耐久 9",
		"碧绿的米饼绕场一周，像在给敌人上课。",
		"环绕同时减速多个敌人，适合拉扯。",
	))
	dishes.append(DishEntry.new(
		&"beef_rice_cake", "牛肉米饼", "煎", "弹射重砸（单体）",
		"牛肉米饼煎制。在敌人间弹射后重砸地面造成范围伤害。",
		&"beef_rice_cake", true, true, false,
		"白米饭 + 牛肉压饼 → 煎制",
		"弹射 26 伤害（最多 4 次）· 重砸范围 · 完美砸 45（半径 105）",
		"结实的牛肉米饼，砸下去连地面都喊疼。",
		"弹射后重砸；完美连击伤害逐次递增。",
	))
	dishes.append(DishEntry.new(
		&"greens_beef_rice_cake", "青菜牛肉米饼", "煎", "分裂（环绕→弹射）",
		"青菜牛肉米饼。分裂为多块小饼分别弹射，最终核心重砸。",
		&"greens_beef_rice_cake", true, true, false,
		"白米饭 + 青菜 + 牛肉压饼 → 煎制",
		"环绕主体 + 分裂 3 块（完美 4 块）· 核心重砸 25（半径 110）",
		"最复杂的一饼，把整桌菜都卷了进去。",
		"先环绕后分裂再重砸；完美最复杂也最赚。",
	))
	return dishes


static func get_dish(recipe_id: StringName) -> DishEntry:
	for d in get_all_dishes():
		if d.recipe_id == recipe_id:
			return d
	return null


# 解锁状态管理
static func is_unlocked(recipe_id: StringName) -> bool:
	if _test_hall_mode:
		return true
	return _unlocked.get(recipe_id, false)


static func mark_unlocked(recipe_id: StringName) -> void:
	if recipe_id != StringName():
		_unlocked[recipe_id] = true


static func mark_unlocked_by_data(data: ItemData) -> void:
	mark_unlocked(recipe_id_from_data(data))


static func mark_unlocked_by_type(item_type: int) -> void:
	var key := _item_type_to_recipe(item_type)
	if key != StringName():
		mark_unlocked(key)


static func set_test_hall_mode(enabled: bool) -> void:
	_test_hall_mode = enabled


static func is_test_hall_mode() -> bool:
	return _test_hall_mode


static func reset_all() -> void:
	_unlocked.clear()
	_test_hall_mode = false


static func _item_type_to_recipe(item_type: int) -> StringName:
	# 将 ItemType 映射到 recipe_id
	match item_type:
		ItemData.ItemType.PLATED_STIR_FRY_BEEF, ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			return &"stir_fry_beef"
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			return &"tomahawk_steak"
		ItemData.ItemType.SHABU_BEEF:
			return &"shabu_beef"
		ItemData.ItemType.PLATED_WHITE_RICE, ItemData.ItemType.UNPLATED_WHITE_RICE:
			return &"white_rice"
		ItemData.ItemType.PLATED_RICE_PORRIDGE, ItemData.ItemType.UNPLATED_RICE_PORRIDGE:
			return &"rice_porridge"
		ItemData.ItemType.PLATED_CRISPY_RICE, ItemData.ItemType.UNPLATED_CRISPY_RICE:
			return &"crispy_rice"
		_: return StringName()
	# 扩展菜谱的映射通过 ExpandedRecipeCatalog 的 recipe_id 字段处理


# 获取 ItemData 对应的 recipe_id（由外部在创建料理时调用）
static func recipe_id_from_data(data: ItemData) -> StringName:
	if data == null:
		return StringName()
	if data.recipe_id != StringName():
		return data.recipe_id
	return _item_type_to_recipe(data.item_type)
