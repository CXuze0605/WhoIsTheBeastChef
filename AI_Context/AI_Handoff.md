# AI Handoff

## 2026-07-30 v0.0.3 发布交接
- `main` 已推送到 GitHub，发布功能提交为 `cdb6075`，标签与 Release 均为 `v0.0.3`。
- Release 地址：`https://github.com/CXuze0605/WhoIsTheBeastChef/releases/tag/v0.0.3`。
- Windows 包 `WhoIsTheBeastChef-v0.0.3-Windows.zip` 已作为 Release 附件上传；SHA-256 为 `184E22ABD063F51FBAFCDFFBCD5BE19A028CB82881F076FC4AF58F1CD27E5ADE`。
- 后续开发以 `v0.0.3` 为公开基线；文档中早期“公开版本仍为 v0.0.2”仅是历史阶段记录，不代表当前发布状态。
- 本次发布没有把无尽模式设计误写为已实现；无尽模式仍只有设计归档与后续任务说明。

## 下一接手点：无尽试炼尚未实现
- 保留固定三波单机模式，新增独立无尽模式；完整设计见 `Prototype_Endless_Mode_Design.md`。
- DeepSeek Codex 总交接见 `DeepSeek_Codex_Handoff_2026_07_30.md`；首项待执行开发指令见 `DeepSeek_Codex_First_Task_Endless_Mode.md`。
- 在负责人明确授权前先只读状态、检查脏工作区并报告预计修改边界，不要直接重写波次系统。

## 后续功能提醒：烹饪大典
- 已讨论但本轮明确延期，不要在当前任务中擅自实现。
- 未来入口：主菜单与 Esc 暂停菜单；内容包括烹饪路径、使用方式、数值、普通/完美/特殊效果。
- 推荐使用制作后解锁、测试大厅临时全解锁，并直接引用现有料理与战斗配置。

## 2026-07-30 接手点：新美术已经接入
- 新物品素材位于 `GodotProject/Assets/Items/ItemArtBatch2026_07_30/assets/ready/`，共 36 张。
- 新战斗素材位于 `GodotProject/Assets/Combat/DishEffects2026_07_30/`，由 `combat_art_catalog.gd` 统一解析。
- 远程味真族素材位于 `GodotProject/Assets/Characters/Enemies/RangedTasteEnemy01/`；`ranged_enemy_character_animator.gd` 负责八向状态，死亡固定南向。
- 料理效果仍以现有玩法逻辑为权威；新增图片和 Godot 动效只负责呈现，不得据此改写数值或机制。
- 测试大厅目录现为 `20×80`，正式局柜子保持 `10×8`。后续新增 ItemType 时继续使用动态枚举覆盖并检查容量。
- 下一位 AI 优先做普通窗口手感与性能复测、补音效和统一技能视觉语言；不要重建第二套投射物、状态、伤害或动画系统。
- 面向 DeepSeek Codex 的精简交接见 `DeepSeek_Codex_Handoff_2026_07_30.md`。

## 2026-07-30 接手点：缺失料理第2～7组全部完成

缺失料理第2～7组现已全部达到 Prototype 可运行且专项通过的完整组边界；不要继续沿用下方“第6组下一步／第7组未实现”的历史段落。最新实现新增第6组六道辣味料理与第7组四道米饼，并复用 `ExpandedRecipeCatalog`、`PrototypeCombatConfig`、炒锅／汤锅／煎锅、`DishAttackController`、`CombatManager`、自动汤流和测试大厅目录。

- 第6组：辣椒炒饭双环终结、辣味青菜炒牛肉扇形、两种辣味投掷炒饭、可叠共享易伤层的辣牛肉汤、无直接伤害的辣味青菜牛肉汤均已接入。自动汤多实例独立索敌；没有目标时不消耗普通或最后耐久。
- 第7组：煎锅支持白米饭、青菜碎、腌／未腌牛肉丁组合，必须按住压饼后才进入自动双面煎制。四类米饼分别使用回旋、环绕分裂、弹射重砸和逐步分体；盐增加的撞击次数按具体生成对象快照。
- 正式美术和音效没有制作，当前使用现有图标映射或程序占位效果。后续应优先人工验证大量米粒／多汤／多分体并存时的可读性、性能、伤害密度和清理。
- 自动入口：`prototype_missing_recipes_groups_6_7_test.gd`（5/5）。第1～7组专项与 `prototype_0_6b_regression_test.gd`（10/10）均已通过。

## 2026-07-30 接手点：缺失料理停在第5组完整边界

第2～5组已经完成并通过全量回归，不要重做。第5组锅巴牛肉的关键接线：

- `ExpandedRecipeCatalog.CRISPY_RICE_BEEF` 由完整未使用 `UNPLATED_CRISPY_RICE` 与 `UNPLATED_CLEAR_STIR_FRY_BEEF` 通过 `PlatingController` 现有组件组合QTE形成独立待摆盘料理；第二次共享摆盘QTE才消耗干净盘并决定正常／完美。
- `TrapController.deploy_selected_crispy_beef_bomb()` 消耗整份料理并生成 `CrispyBeefBomb`。盘装版本立刻产生脏盘；未摆盘版本不产生。
- `CrispyBeefBomb` 同一类同时承担主炸弹与碎弹，配置集中在 `PrototypeCombatConfig`。炸弹不属于`damageable`，所以无法互相连锁；所有实例属于`run_deployable`，现有正式开局重置会清理。
- 友伤使用 `DamageContext.SourceType.TRAP` 和 `friendly_fire=true`，敌方取完整伤害，玩家／友方取40%或50%；厨房设施没有合法战斗阵营与受伤入口，因此不会受伤。
- 专项 `prototype_missing_recipes_group_5_test.gd` 为4/4；32个测试脚本全量通过，资源扫描、两个Headless入口和diff检查通过。

下一完整组是第6组六道辣味料理。它包含四种主动料理和两种多实例自动汤，必须完整接入配方优先级、易伤共享层、无目标保留最后耐久、真实投射／水流、完美终结与专项测试后才能标记完成。第7组四道米饼仍未实现。

## 2026-07-30 接手点：缺失料理停在第4组完整边界

当前不要重做第2～4组。第4组已经完成青菜牛肉粥、牛肉泡饭和青菜牛肉泡饭：

- 汤锅复用现有白粥／泡饭离散状态；青菜牛肉粥支持牛肉和青菜双向加入，泡饭严格区分一份水与两份水路线。
- 青菜牛肉粥复用玩家真实饮用、烫伤、中断、耐久与脏盘；未腌分支无完美，完美最后一口应用本体增益与持续恢复。
- 两种复合泡饭复用 `RiceEffectZone`；易伤／虚弱按份数配置且不分阵营。区域现在保存生成时的完美最后耐久快照，普通使用不会错误获得完美参数。
- 专项 `prototype_missing_recipes_group_4_test.gd` 为4/4；当前31个测试入口和Godot 4.6.2资源／脚本扫描通过。

下一安全工作从第5组锅巴牛肉开始。必须复用现有组件组合／摆盘、`TrapController`、统一伤害上下文、友方阵营和`run_deployable`清理；主炸弹与小炸弹不可互相触发，不得伤害厨房设施。第6～7组仍未实现。

## 2026-07-30 接手点：缺失料理停在第3组完整边界

当前不要从第2组重做。已完成并通过测试：

- 第2组：青菜盖饭、牛肉盖饭（真实组合QTE、二次摆盘、两类炮台与完美终结）。
- 通用半成品：`GREENS_CRUMBS`，砧板由青菜叶按份数切出。
- 第3组：牛肉焖饭、青菜牛肉焖饭（恰好1份水、完成前双向升级、未腌分支、共享进食点、完美最后一口）。

下一安全工作从第4组开始：青菜牛肉粥、牛肉泡饭、青菜牛肉泡饭。必须继续沿用现有 `SoupPotItem`、粥饮用、`RiceEffectZone`、状态来源与摆盘管线；不要创建平行锅态、区域或治疗系统。

关键测试：

- `prototype_missing_recipes_group_2_test.gd`
- `prototype_missing_recipes_group_3_test.gd`
- 所有30个测试入口在此接手点通过。

注意：工作区包含大量用户/其他AI未提交改动；不得回滚、清理或用旧基线覆盖。第4～7组仍是明确未实现，不得仅补枚举或占位攻击后宣称完成。

## 2026-07-30 缺失料理补全·第一组交接

- 权威设计与 Prototype 数值见 `Prototype_Missing_Recipes_Group_1.md`。新增 recipe ID 为 `fried_white_rice / clear_stir_fry_beef / greens_soup / beef_soup`，各有未摆盘和盘装类型；不要按显示名称判断，也不要另建第二套持续攻击或品质系统。
- `WokItem/WokStation` 当前保证组合炒饭优先于炒白饭；腌牛肉片第一阶段后保留小炒／清炒分支。`SoupPotItem/WokStation` 当前保证盐水青菜第一节点可提前取出，继续煮才是青菜汤；牛肉丁走牛肉汤，形成前加菜走既有青菜牛肉汤。修改配方顺序时必须保留这些优先级。
- 战斗复用 `DishAttackController + CombatManager`。新增 `ClearBeefComboAttack` 与共享 `HeldSoupStream`；炒白饭复用扩展后的 `RiceBallProjectile` 米粒模式。牛肉汤／米粒／清炒非终结段使用负韧性值明确跳过基础敌人“0 即达阈值”的僵直判定。
- 汤流按住攻击维持，玩家减速使用现有 `CombatStatusController` 持久来源并在停止时按实例 ID 移除。青菜汤同 tick 三流共享去重；牛肉汤只取投影最近目标，文火入味按料理实例保存五层并在断流／换目标／超时清空。
- 新类型已加入 `FreshnessCatalog.DISH_TYPES`，配方 `ingredient_counts` 使用 `FreshnessCatalog.get_actual_units()` 写入真实份数。临期、腐败、浪费和摆盘状态继续走现有统一入口。
- 测试柜继续独立 `20×40`，通过枚举动态覆盖全部类型；合法盘装料理的完美样本必须满足 `PLATED_ + combat + 非怪异 + cap允许 + 无失败标签`，然后刷新战斗配置，不能仅改品质文字。
- 专项 `prototype_missing_recipes_group_1_test.gd` 为 8/8；全量基线现为 28/28。正式图标、技能表现和音效仍未制作；20粒性能、清炒节奏、汤流推力／锁前排和五层反馈需要负责人实机试玩。
- 本轮没有修改公开版本、提交、推送或发布；工作区仍包含大量受保护的既有未提交成果。

## 2026-07-30 新鲜度／腐败／浪费强化交接

- 权威文档为 `Prototype_Freshness_and_Spoilage_Design.md`。入口是主场景唯一 `FreshnessManager` 与集中 `FreshnessCatalog`；不要给各物品或工位另挂独立计时器，也不要新建第二套腐败库存。
- 正式开局统一重置完成后启动时钟，正式准备至波间持续，自由大厅与结算停止；`ItemData.freshness_clock_stamp`配合实例 ID 去重，确保快捷栏、背包、柜子、地面、工位和部署物中的同一实例只老化一次。只有有效加热且阶段实际推进时暂停原料老化。
- `FailureTag.NEAR_EXPIRY` 是永久“临期”失败标签；腌制和成菜只刷新当前腐败周期，不清标签。`ROTTEN_WASTE` 是硬失效类型，不是失败标签；它不可堆叠，并从实例读取原形状遮罩和既有 `storage_rotated`。
- 堆叠必须调用 `ItemData.add_from_stack()`：新鲜／尚鲜可混合，临期只与临期合并，部分接收只计算实际接收份数。GridInventory、QuickInventory与柜子自动堆叠当前会优先腐败度最接近的合法堆。
- 浪费由 `FreshnessManager.settle_waste()`统一结算，`waste_penalty_settled`防重复。垃圾桶、主动丢腐败物与地面自然腐败已接入；系统清理和自由大厅不累计。
- 敌人强化无上限且线性：生命 `1 + waste*0.005`、直接伤害 `1 + waste*0.0025`。WaveManager只给之后新生成的普通／速度／重型／远程快照一次倍率；不要对场上敌人追溯、复利或恢复40点上限。
- 短缺补偿未重写，只在供应扫描中将可腐败资源按新鲜／尚鲜1.0、临期0.5、腐败0计入；原掉落概率、权重和补偿系数保持。
- 专项入口 `prototype_freshness_spoilage_regression_test.gd` 当前 8/8；全量基线为27个既有测试加本专项全部通过。仍需人工三波试玩确认周期、UI可读性、无上限系数压力和大形腐败物占格选择。
- 本轮没有实现冰箱、堆肥、菜园、腐败料理、空瓶、局外经济或联机同步；公开版本未变，工作区仍包含大量受保护的未提交成果。

## 2026-07-30 第一版怪物掉落与调料复用交接

- 权威设计与当前 Prototype 参数见 `Prototype_Loot_and_Reusable_Condiments_Design.md`。继续复用 `PrototypeWaveManager` 的统一掉落入口、真实 `CarryableItem / ItemData`、快捷栏／背包／柜子接收路由和 `RunStats`；不得在四个敌人脚本中复制随机表。
- `PrototypeWaveConfig` 集中保存普通 30%、速度 40%、远程 50% 的基础率与所有池权重。重型在统一结算入口固定生成 `RAW_STEAK`，不再生成 `RAW_BEEF_CHUNK` 或额外 `RICE_BAG`。四种敌人当前 rank 均为 `ordinary`；以后增加阶级时应与 archetype 分离。
- `ItemData.ItemType.SMALL_RICE_BAG` 追加在枚举末尾，避免移动既有整数值。开局 `RICE_BAG` 是 `3×4 / 20`，敌人小米袋当前临时 `2×2 / 2`；V3 `rice_bag_small` 已接入。不要把两者重新合并成同一 20 份实例。
- 油瓶和盐瓶的剩余份数保存在各自 `ItemData` 实例。默认完整容量 6 / 10，怪物掉落容量 2 / 3，且两者不可物品堆叠。工位必须调用玩家统一的 `consume_held_resource_portion()`，成功时只扣一份；不要恢复 `remove_held_item()` 整瓶消耗。
- 动态补偿由 WaveManager 每 0.5 秒在正式 `SPAWNING / WAVE_ACTIVE` 扫描队伍供应。它只选择当前池内一个最紧急资源、提高基础通过率与该条目权重，并在世界生成成功时重置。测试可用 `set_shortage_supply_override_for_test()`；正式逻辑不得以拾取作为重置条件。
- 供应扫描按份数：油含锅中已投入油，盐不把已投入料理算回库存，米含两种袋、独立米、容器／地面／锅中和已制作基础米类料理。当前扫描为本地单玩家容器汇总，但数据入口按队伍共享语义组织，未来多人不能改成每人独立保底。
- 专项入口 `prototype_loot_reuse_regression_test.gd` 为 4/4；当前全量基线 26/26。0.1 历史测试已明确选择腌牛肉片格，适配“油瓶仍留在快捷栏”的真实新语义，未降低断言。
- 尚需人工确认掉率、断供安全线、半瓶碎片感、小米袋对白粥供给和重型固定牛排数量。空瓶、合并、过咸、正式阶级、新鲜度及最终掉落公式均未实现。公开版本未变，禁止据此发布。

## 2026-07-29 远程型味真族三发剩饭攻击交接

- 这是对既有 0.6B `RangedTasteEnemy` 的原位升级，不是新敌人。继续使用 `PrototypeWaveManager.spawn_ranged_enemy_for_test()`、波次 2/3、`EnemyTargetProvider`、`BasicTasteEnemy` 伤害/复味、既有掉落和同场上限 2；不得再创建第二套远程 AI、投射物结算或掉落逻辑。
- 远程自定义状态为 `SEEK / EATING / RETCH_WINDUP / VOLLEY / SHOOT_RECOVERY / SHOVE_WINDUP / SHOVE_RECOVERY`。`STATE_AIM` 只作为旧调试入口的兼容别名。子类覆盖 `_enter_state()`，确保基础 HIT_STUN / LURED 结束时恢复到远程 `SEEK`，并在受击、复味、禁用时统一清除三发队列和预警。
- `PrototypeWaveConfig` 当前 Prototype 值：吞食 0.75 秒、催吐 0.65 秒、锁定比例 0.55、三发、发射间隔 0.22 秒、后摇 0.70 秒、完整攻击周期 4.5 秒、落点间距 26；单团直接伤害 8、落地溅射 4 / 半径 32、速度 360、视觉抛物线 48、轻击退 28。不要散落复制或写成最终平衡。
- 锁定坐标保存在 `locked_landing_positions`。未锁定中心环跟随目标；锁定后三个 `TargetMarker` 显示真实坐标。失瞄在 `_lock_volley_positions()` 内确定真实偏移，再由同一数组驱动预警和弹丸，禁止重新在发射瞬间偏移。
- `RangedFlavorProjectile` 的 Node2D 位置是地面投影；绘制层单独用正弦高度表现饭团抛物线和阴影。射线只检查设施层，碰设施直接消失且不溅射；直接目标和落地溅射均进入玩家统一 `DamageContext / 护盾 / 生命` 管线，`direct_hit_ids` 防止同一团对直接目标重复溅射。第一版只攻击玩家或当前诱饵，不开启怪物友伤。
- 当前仍是程序占位角色：颜色、轻微缩放、状态文字、真实落点和程序饭团。未来可在敌人下增加名为 `RangedEnemyCharacterAnimator`、实现 `update_state(state, velocity, locked_position, hit_flash)` 的视觉节点，替换八方向动画时不需要改 AI、波次、伤害或弹丸规则。
- 角色原型为被流量与表演性进食异化的大胃王主播，主题针对流量压力与身体伤害，不嘲讽胖瘦或饮食障碍患者。正式名称、美术、持续污染、怪物友伤及后续掉落设计均未确认；现有掉落权重没有改。
- 验证基线：0.6B 专项 10/10、全量 25/25、资源扫描、默认主菜单/直接 Gameplay Headless、普通 OpenGL 1280×720 双远程视觉检查均通过。双远程若完全同步，三个落点会重叠得更密；真实波次已有 0.55 秒错峰，仍需负责人完整第三波试玩确认。

## 2026-07-29 初始主菜单与正式设置交接

- `project.godot` 当前启动 `Scenes/menu/main_menu.tscn`，并依次自动加载 `AppSession`、`SettingsManager`、`AudioManager`。不要把启动场景改回 Gameplay；直接调试 Gameplay 时仍能按 `UNSPECIFIED` 进入自由大厅。
- 单机与测试大厅不复制场景。主菜单只写入一次性 `AppSessionState.LaunchMode`：单机进入 Gameplay 后调用既有 `WaveManager.start_service_early()` 完成正式重置、有限柜、隐藏假人与准备倒计时；测试大厅保留 FREE_PREPARATION、20×40 无限目录、假人和强制启用的开发工具。Gameplay 读取后立即消费模式，避免影响重载和自动测试。
- `SettingsManager` 保存 `user://settings.cfg`，版本 1，默认 Master/Music/SFX 均 100；缺字段用默认值，损坏文件警告后安全回退。自动测试必须先调用 `set_settings_path_override_for_test()`，不得保存真实用户文件。
- `default_bus_layout.tres` 提供 Master/Music/SFX。`PrototypeAudioManager` 仍是唯一 BGM 管理器和唯一双播放器交叉淡入淡出入口，播放器只把输出路由到 Music；不要在菜单或设置中增加第二套播放器。
- 键位显示统一使用 `InputPrompt`。`SettingsManager.EDITABLE_ACTIONS` 是正式可改清单；F3/F9/测试重置/F8 不在清单内，ESC 也不能被捕获为普通绑定。冲突通过确认弹窗允许重复，不得静默删掉其他动作。
- `IngredientCabinetUI._ensure_backpack_input()` 只在缺少绑定时补默认，并对历史 Tab 语义保持兼容；不得恢复“每次打开都强制清空并写回 Tab/R”的旧逻辑，否则会破坏持久设置。项目默认 `toggle_backpack` 已从误写的 Backspace 修正为 Tab。
- `PrototypeToolsOverlay` 仍是唯一暂停所有权入口，新增 SETTINGS 模态。设置关闭回到暂停菜单；退出本局先走现有 `return_to_lobby()` 清理，再切主菜单并恢复暂停/BGM。ESC/F9、柜子和背包的既有优先级测试仍通过。
- 菜单是 Prototype 原生 UI。联机只是 1—4 人占位说明；分辨率、全屏、语言、手柄重绑与最终菜单美术均未实现。`RunSummaryUI` 结束按钮仍返回自由大厅，是当前明确待办。
- 验证基线：主菜单/设置专项 5/5，全量 25/25，Godot 4.6.2 资源扫描与主菜单 Headless 启动通过；普通 OpenGL 1280×720 已检查菜单和设置滚动布局。测试会故意生成一次损坏 ConfigFile 和试玩记录写入失败日志，用于验证安全回退，脚本最终均 PASS。

## 2026-07-29 Windows 美术试玩包交接

- 当前未发布工作区已导出为 `Builds/WhoIsTheBeastChef-ArtPreview-2026-07-29-Windows.zip`，用于发给美术检查。它不是 v0.0.3 或新的公开 Release，不能据此修改公开版本状态。
- ZIP SHA-256：`F8D8860D2E60EEAB16F8E3881C7C4C60BB7213D82791508B2994A6FE6EBAD6EF`；大小 46,336,923 字节。包内 EXE/PCK 保持同目录，附带中文启动说明与校验清单。
- 普通 Windows 窗口运行 180 帧退出码 0；解压后的 EXE/PCK 与原始导出哈希一致。`Builds/` 继续由 Git 忽略，本次没有提交、推送、上传或发布。

## 2026-07-29 物品美术 V4 修正与 20×40 测试目录交接

- V3 仍是完整物品包基线，V4 是当前权威修正覆盖层。V4 归档位于 `GodotProject/Assets/Items/ItemArtCorrection2026_07_29_v4/`，包含 8 张 ready PNG 与包内说明。
- `PrototypeArtCatalog` 中 V4 接管：普通/完美战斧、小炒黄牛肉未装盘/已装盘、青菜炒牛肉未装盘/已装盘、青菜牛肉汤未装盘/已装盘。不要恢复旧 `plated_stir_fry_beef` 共享键或 V3 错误战斧路径。
- `ItemCatalog.get_art_key_for_data()` 仍是状态与品质选择入口。只有完美盘装战斧选择 V4 完美图；未摆盘和非完美盘装均选择 V4 普通图。战斧 `2／2／1` 仓储遮罩未改变，不能根据纹理透明像素改成矩形。
- 自由大厅测试目录由 `ItemStorageCatalog.LOBBY_TEST_CABINET_SIZE = Vector2i(20, 40)` 独立控制；正式柜继续使用 `FORMAL_CABINET_SIZE = Vector2i(10, 8)`。UI 使用 32px 单元格、640×1280 内容与竖向滚动，标题为 `20×40 测试目录（滚动查看·取走后自动补充）`。
- 自动补充和位置搜索必须继续遍历 `storage.height`，确保第 21—40 行可用。不要把测试目录尺寸写回正式库存配置。
- 验证基线：V4 专项 5/5、V3 兼容 7/7、0.6A 6/6、全量 24/24；资源扫描、Headless 主场景与普通 OpenGL 1280×720 滚动检查均通过。根证书读取失败是隔离测试配置的既有 Windows 环境警告。

## 2026-07-29 物品美术交付包 V3 完整映射交接

- V3 是当前唯一权威物品美术交付，工程归档位于 `GodotProject/Assets/Items/ItemArtPack2026_07_29_v3/`。V1/V2 不得继续作为运行时来源。
- 包内 60 张 `assets/ready/**` PNG 全部已保存；57 个现行 ItemType 使用 V3 映射，实际涉及 56 张包内运行时 PNG。透明处理后的完美战斧是第 57 张 V3 运行时纹理；灰底母图和 `sources_48px` 没有复制进工程。
- 所有物品显示继续集中走 `ItemCatalog.get_art_key_for_data()` 与 `PrototypeArtCatalog.TEXTURES`。快捷栏、CarryableItem、背包、柜子和地面掉落不得另建路径映射。
- 动态规则：生牛肉片和涮牛肉的成组状态使用 V3 图，最后一片继续使用既有单片图；非完美战斧使用普通图，只有完美盘装战斧使用透明 64×96 完美图。
- 67 个现行类型的逐项状态见 `AI_Context/ART_COVERAGE_REPORT.md`。真正缺图仅有：待摆盘/盘装青菜炒牛肉、待摆盘/盘装青菜牛肉汤。食用油、小炒黄牛肉与三种锅具仍有旧图可用。
- V3 ready 中的小米袋和三张空容器母版只保存、不注册。当前 `RICE_BAG` 没有区分大/小袋外观的实例字段；不要为接图擅自修改掉落或资源份数。
- `prototype_item_art_pack_v3_test.gd` 覆盖全部 ItemType、57 个 V3 类型映射、17 组未装盘/盘装区分、三种青菜炒制区分、动态份数图、完美战斧透明轮廓和四类 UI 共用入口。
- 最终验证为 V3 专项 7/7、全量 23/23；Godot 4.6.2 资源扫描/脚本解析及主场景 Headless 180 帧均通过。普通 OpenGL 1280×720 已实际检查测试柜、背包、快捷栏、手持与地面物品。测试沙箱会输出“无法读取 Windows 根证书”的环境警告，不是资源或脚本错误。
- 下方 V2 小节是历史记录，已被本节和 D-109 修正，不可继续用来跳过 V3 ready 素材。

## 2026-07-29 物品美术交付包 v2 接入交接（历史记录）

- 权威归档位于 `GodotProject/Assets/Items/ItemArtPack2026_07_29_v2/`。运行时只允许引用其中 `assets/ready/**`；`review_required` 未复制进工程，也不得因为文件名明确就擅自接入。
- 运行时映射集中在 `ItemCatalog.get_art_key()` / `get_art_key_for_data()` 和 `PrototypeArtCatalog.TEXTURES`。快捷栏、CarryableItem、异形背包与柜子都复用该入口，后续不要为单个 UI 建立第二套路径字典。
- 已接入 18 张纹理：包内 17 张 ready 图，加 1 张由灰底源图处理出的透明完美战斧。小米袋与 3 张通用容器母图只归档未注册；其余 review_required 和 source_48px 没有进入项目。
- 战斧规则：`TOMAHAWK_STEAK` 与非完美 `PLATED_TOMAHAWK_STEAK` 使用 `weapon_tomahawk_steak_normal.png`；只有完美盘装战斧使用 `weapon_tomahawk_steak_perfect.png`。后者为 64×96 透明画布，下方右 32×32 全透明，严禁改回灰底源图。
- 仓储规则：生牛排默认 3×1，旋转后 1×3；普通和盘装战斧都使用 `2／2／1` 五格遮罩；大骨头仍为 1×3。旧 `RAW_BEEF_SLICES` / `SHABU_BEEF` 的单片与成组动态切图保持不变。
- 仍使用旧 Prototype 图的项目不能从本包 `review_required` 自动升级。包括调料候选、牛肉片组、涮牛肉组、生米 / 青菜叶 / 牛肉丁、白饭 / 锅巴和多道扩展料理；必须等负责人明确确认具体候选或新 ready 包。
- 验证基线：`prototype_item_art_pack_v2_test.gd` 5 / 5、0.6A 6 / 6、全量 23 / 23；资源扫描、Headless 主场景 180 帧、普通 OpenGL 实际渲染通过。三张检查截图验证了快捷栏 / 手持、背包和测试柜。

## 2026-07-28 速度型味真族蹲伏飞扑动画交接

- 候选素材位于 `Assets/Characters/Enemies/FastTasteEnemy01/`，固化资源为 `fast_taste_enemy_01_sprite_frames.tres`，视觉状态集中在 `FastEnemyCharacterAnimator`。
- `FastTasteEnemy` 将现有 `STATE_CHARGING` 映射到八方向非循环 `crouch_*`，将 `STATE_DASHING` 与 `STATE_DASH_RECOVERY` 映射到同一八方向非循环 `pounce_*`。这是同一次攻击的“蹲伏蓄力 → 飞扑 → 落地保持”，恢复阶段不得重播飞扑或提前切回待机。
- 原包目录 `feipu` 只作为源文件夹保留，项目内部动画语义统一使用 `pounce_*`。八方向均使用原生帧，不镜像；静止使用 rotations，追赶使用 Running，减速使用较低 FPS 的同套 Running，复味离场使用仅有的 south `defeat_fall`。
- 当前视觉参数：Running 11 FPS、减速 7 FPS、蹲伏 8.333 FPS、飞扑 22.222 FPS、失败 15 FPS；100×100画布、Nearest、整数 `(1,1)`。不得恢复旧的整节点纵向压扁蓄力表现，否则会把原生蹲伏帧拉伸变形。
- 旧 `fast_taste_enemy_walk_sheet.png` 与 ArtCatalog 映射仍保留为隐藏回退。新视觉不得用于修改18冲刺伤害、0.60秒蓄力、0.36秒冲刺、速度、碰撞、导航、锁向、预警或后摇。
- 验证基线：速度型专项4 / 4、普通敌人隔离专项5 / 5、全量22 / 22测试脚本、资源扫描、Headless和普通窗口180帧启动通过。负责人仍需实机确认角色大小、11 FPS追赶节奏、蹲伏与方向线的可读性，以及飞扑落地是否与碰撞后摇匹配。

## 2026-07-28 小炒黄牛肉大型暴怒公牛八方向动画交接

- 完美最后一击大型公牛素材位于 `Assets/Combat/DishAttacks/StirFryRagingBull01/`，固化资源为 `stir_fry_raging_bull_01_sprite_frames.tres`，方向控制集中在 `RagingBullVisualAnimator`。
- `RagingBull` 不再通过 `rotation = direction.angle()` 转动一张东向素材；`_move_and_reflect()` 反弹后和 `_update_random_turn()` 完成预警转向后都会调用同一动画控制器更新八方向。
- 八个活动方向各8帧、10 FPS；另保留 `run_north_variant`。当前 north 使用 `north-b6f811d6`，备用为 `north-0941c069`。两套都不能删除，等待负责人实机选择。
- 148×148画布使用Nearest与整数2倍显示，实际可见主体约160×128。旧标题隐藏，但 `status_label` 必须继续可见，因为它承载“友伤危险”和“转向预警”反馈。
- 视觉控制器只读取当前 `direction`。不得为配合动画修改800速度、24秒持续、65半径、48敌伤、18友伤、反弹子步、随机转向、友伤一次限制或HUD警告。
- 旧 `raging_bull.png` 仍由 ArtCatalog 预载并作为回退保留，运行时在新动画启用后隐藏。普通公牛继续使用独立的 `NormalBullVisualAnimator`。
- 当前验证基线：大型公牛方向专项4 / 4、全量21 / 21测试脚本、资源扫描、Headless和普通窗口启动通过。负责人仍需确认2倍大小、10 FPS重量感和两套north取舍。

## 2026-07-28 小炒黄牛肉普通公牛八方向动画交接

- 普通公牛动画源位于 `Assets/Combat/DishAttacks/StirFryNormalBull01/`，固化资源为 `stir_fry_normal_bull_01_sprite_frames.tres`，方向控制集中在 `NormalBullVisualAnimator`。
- `NormalBull._ready()` 不再执行 `rotation = direction.angle()`；攻击实体始终保持零旋转，由八个 `run_<direction>` 原生动画对应锁定飞行方向。不要重新用东向图片旋转或镜像代替。
- 每个方向 6 帧、12 FPS 循环，显示缩放为整数 2 倍，Nearest。原始画布 84×84，实际可见主体设计约 48×32，游戏内约 96×64。
- 普通公牛仍使用发射时锁定的 `direction` 完成移动和命中，视觉控制器只读取方向。速度、距离、宽度、击退、伤害、穿透、状态、统计和 `DamageContext.PLAYER_DIRECT_RANGED` 均未变化。
- 旧 `normal_bull.png` 仍由 `PrototypeArtCatalog` 预载，但运行时在八方向动画启用后隐藏，作为回退资源保留。大型 `RagingBull` 没有接入该控制器。
- 当前验证基线：普通公牛方向动画专项 4 / 4、全量 20 / 20 测试脚本、资源扫描、Headless 与普通窗口启动通过。下一步只需负责人实机确认 2 倍视觉大小、12 FPS 速度和高速飞行时方向辨识度。

## 2026-07-28 Prototype 候选普通味真族 PixelLab 动画交接

- 普通基础敌人的新动画资源位于 `Assets/Characters/Enemies/BasicTasteEnemy01/basic_taste_enemy_01_sprite_frames.tres`，状态与方向选择集中在 `BasicEnemyCharacterAnimator`。`BasicTasteEnemy` 会排除 `HeavyTasteEnemy`、`FastTasteEnemy` 和 `RangedTasteEnemy` 后才启用该候选美术。
- 动画命名为 `idle_<direction>`、`run_<direction>`、`slow_run_<direction>`、四个 `attack_<cardinal>`、`defeat_fall`，另保留未启用的 `run_south-east_variant`。八方向不使用水平镜像。
- ZIP 没有真正的 Idle 或 Walking：`idle_*` 是 rotations 单帧；减速时使用相同 Running 帧以 5 FPS 播放。不要在后续文档中误写为已拥有待机 / 行走原画。
- FPS 为 Idle 1（静态）、Run 8、Slow Run 5、Lead Jab 8、Defeat 15。15 FPS 是为了在既有 0.48 秒复味离场期间显示完 7 帧，不得为动画另改波次或离场时序。
- `Lead_Jab` 只有东南西北四向，斜向攻击映射到最近的原生 cardinal 方向；`Falling_Back_Death` 只有 south，项目内部称 `defeat_fall`，表示复味离场演出而非世界观死亡。
- PixelLab 的两套 south-east Running 都保留：当前使用 `south-east-c21cebdf`，`south-east-fabc4a3e` 仅作为备用动画。切换前需项目负责人确认，不要随机混用。
- 新 Sprite 在既有视觉原点、`(1,1)` 缩放、Nearest；碰撞、移动、导航、战斗、掉落和统计没有变化。旧静态图与旧走路合图未删除，是快速回退入口。
- 当前验证基线：普通敌人动画专项 5 / 5、0.6A 6 / 6、全量 19 / 19 测试脚本通过；资源扫描、Headless 和普通窗口启动通过。0.5.1 试玩记录故意失败路径仍会输出预期错误。
- 后续仍需负责人实机确认角色大小、脚底锚点、八方向跑动、攻击节奏、复味离场可读性和两套 south-east 取舍。该形象仅为 Prototype 候选，不是最终普通味真族设定。

## 2026-07-28 Prototype 候选主角 PixelLab 动画交接

- 玩家场景的 `PlayerArt` 节点名保留，但类型已是 `AnimatedSprite2D`；完整资源位于 `Assets/Characters/Player/ChefWuxia01/chef_wuxia_01_sprite_frames.tres`，由 `PlayerCharacterAnimator` 选择状态和八方向。
- 动画命名为 `idle_<direction>`、`walk_<direction>`、`run_<direction>` 和 `defeat_fall`。FPS 为 4 / 6 / 9 / 8；八方向全部使用 PixelLab 原生帧，`flip_h` 始终关闭。
- 正常移动使用 Running；只有现有 `CombatStatusController` 使移动倍率低于 1 时使用 Walking。不要为配合动画另改玩家速度。
- `facing_direction` 仍是攻击、交互、手持和放置的权威方向；动画控制器只读取它。停止和锁定进入最后方向待机，不会重置 south。
- defeat_fall 目前只有 south 方向，失败时允许视觉切 south，动画不循环且不会改变结算时机。
- 原始 111 张 108×108 PNG、rotations 和 PixelLab metadata 均保留，禁止自动裁边。节点使用 Nearest、`(1,1)` 缩放、位置 `(0,-5)`。
- 旧 `player_chef.png` 与旧 `player_walk_sheet.png` 未删除，是快速回退入口。当前形象仅为 Prototype 候选，不是最终角色设定。
- 后续缺少切菜、洗盘、洗锅、腌制、主动炒制、受击、饮用和料理使用等专用动画；新增动作应继续扩展 `PlayerCharacterAnimator`，不要把状态选择散落回玩家主脚本。
- 验证基线：玩家动画专项 5 / 5；全部 18 个测试脚本通过；最终 SpriteFrames 接线后资源扫描、0.6A 回归、Headless 与普通窗口启动均通过。

## 2026-07-28 米饭、青菜与牛肉扩展交接（里程碑 A—F 代码与自动验收完成）

当前安全接手点：

- 工作区包含未提交的 0.6B、假人 A 自动攻击和本轮 A—F 内容扩展；不得回滚、清理或只保留本轮新增文件。
- 权威设计为 `Prototype_Rice_Greens_Content_Expansion.md`。A—F 均已完成代码接线和自动验证，但尚未完成负责人全套人工试玩，也未提交或发布。
- A 已建立 `DamageContext`、`CombatStatusController`、扩展后的 `ItemData` / `ItemCatalog`、主动炒制和移动摆盘 QTE。新增攻击必须选择明确来源类型，不要退回按节点名判断。
- B 已增加青菜 / 菜叶 / 牛肉丁数据、切丁与双顺序腌制、手持 / 背包拆菜 QTE，以及正式柜子第八类初始物资。
- C / D 已增加七种青菜与粥料理、青菜炒牛肉和三种炒饭；公共叶片投射物、炝烟、扇形与抛投实体集中复用，配方入口集中在 `ExpandedRecipeCatalog`。
- E 已增加菜饭补给点、泡饭与菜泡饭区域；部署与清理由既有 `TrapController` / `CombatManager` 接管。
- F 已增加盖饭三弹随机袋炮台、多份独立青菜牛肉汤流和芥末青菜标记 / 诅咒 / 残盘。自动汤由玩家唯一 `AutoDishEquipmentController` 扫描快捷栏和背包真实实例，不得另建装备栏或限制为一份。
- `WokStation.advance_automatic_cooking()` 的默认主动炒制推进只保留给历史确定性测试；真实 `_process` 明确传 `allow_active_stir_test_step=false`。不得据此误判运行时仍会自动炒熟。
- 移动 QTE 使用 `PrototypePlayer.action_qte_locked`，不要改回 `modal_ui_open`，否则会重新锁死 WASD。摆盘成功才扣盘，取消不需要“退回盘子”。
- 当前开发重点应从“继续堆新料理”转为完整人工验收、手感 / 可读性 / 性能调优和真实流程 Bug 修复；不要在未授权时继续增加菜品。
- 当前验证基线：17 / 17 测试脚本通过，资源扫描 / 脚本解析通过，Headless 主场景 180 帧通过。0.5.1 的试玩记录故意失败路径仍会输出一条预期错误。

## 2026-07-25 最新交接：Prototype 0.6B 代码与自动验收完成

- 权威设计为 `Prototype_0_6B_Shield_Enemies_and_Rice_Design.md`。正式方向、Prototype 临时数值、未确定的正式敌人名称 / 盐改造 / 组合料理 / 怪异料理必须严格分开。
- 玩家伤害只走 `PrototypePlayer.receive_combat_hit()`：当前锅巴减伤 → 护盾 → 生命。波间只调用 `restore_shield_for_wave()`；不得恢复生命。`receive_direct_health_burn()` 仅供滚烫白粥的 Prototype 例外，不能推广为通用伤害入口。
- `FastTasteEnemy` / `RangedTasteEnemy` 均继承既有 `BasicTasteEnemy`，复用导航、防卡、复味离场、统计与掉落。内部中文暂名不是正式名称。目标选择经 `EnemyTargetProvider` 返回 `Node2D`，不要重新把目标写死为唯一玩家。
- 正式柜现在是原六类初始物资加一个实际米袋。米袋 `remaining_portions` 属于物品实例；逐份取米必须先确认快捷栏 / 背包接收成功再扣数量。
- 汤锅 `water_units` 为 0/1/2；历史 `has_water` 兼容属性仍保留。白米饭、白粥、锅巴继续使用同一 `WokStation` 自动加热与离散阶段规则，不得另建米饭计时系统。
- 白米饭攻击由 `DishAttackController` / `RiceBallProjectile` 管理；白粥与通用应急进食在 `PrototypePlayer` 中共用 `secondary_use` 和现有头顶进度条。进食开始预扣耐久，部分治疗不回滚。
- 锅巴不是装备槽：只扫描快捷栏和背包真实实例。优先级为快捷栏左到右，再按背包网格 y/x；减伤不叠加。当前激活物在 HUD、快捷栏和网格中有标记。
- `CombatManager` 统一拥有饭团与锅巴碎生命周期，正式新局 / 返回大厅会清除。重型怪额外米袋只是正式精英缺位时的临时替代，每局最多一个。
- 当前专项 8 / 8、0.1—0.6B 11 套回归、资源解析、Headless 与普通 OpenGL 启动均通过。下一步必须先人工试玩两类敌人的电报 / 碰撞、护盾节奏、米袋取用、汤锅水量、白粥打断和锅巴优先级，再决定数值调整。
- 最新公开版本仍是 `v0.0.2 / Prototype 0.6A`；0.6B 未提交、未推送、未打标签、未发布。继续保护本工作区所有已有修改。

> 最后更新：2026-07-25
> 最近交接来源：GPT Codex（Prototype 0.6B 实现与全量回归）

## 2026-07-25 最新交接：战斧仓储可读性与玩家方向箭头清理

- 战斧牛排素材本身是 `640×640` 透明画布，实际非透明主体边界为 `Rect2(220, 160, 240, 390)`。旧网格 UI 按整张画布适配，使大厅 `1×3` 占格内主体只有约 `9×15px`。现在 `PrototypeArtCatalog.UI_SOURCE_REGIONS` 集中记录该 UI 裁切区域，`InventoryGridView` 和 `IngredientCabinetUI.DragPreviewArtwork` 都使用同一源区域等比绘制，主体约为 `24×39px`；不得通过改变 `1×3` 占格或拉伸图片来再次放大。
- 该裁切只服务背包 / 柜子 / 拖拽预览。世界物品和玩家手持仍使用完整透明画布与既有 `TOMAHAWK_HELD_ART_SCALE = 3.2`，所以本轮没有破坏已调好的战斧手持大小和朝向。
- 玩家场景中的灰盒 `DirectionMarker` 已从 `player.tscn` 删除，`PrototypePlayer` 也不再获取或旋转该节点。`facing_direction`、角色动画左右翻转、纯上下保持朝向、手持锚点与攻击瞄准逻辑全部保留。
- Godot 4.6.2 资源 / 脚本解析通过，0.6A 专项 6 / 6、0.5 美术/UI 回归 9 / 9、主场景 Headless 180 帧通过。没有修改料理规则、仓储数据、移动速度或战斗数值。

## 2026-07-23 最新交接：玩家朝向、基础垃圾桶与大厅无限测试柜

- 最新音乐规则由 D-082 覆盖旧的 D-066 阶段映射：`FREE_PREPARATION` 使用大厅曲，点击“开始营业”进入正式 `PREPARATION` 时立即切战斗曲，之后 `GLOBAL_WARNING / LOCAL_WARNING / SPAWNING / WAVE_ACTIVE / INTERMISSION` 全部保持同一首战斗曲。小波之间不得回大厅曲，也不得重新启动战斗流；`AudioManager.play_music()` 的同曲 no-op 继续作为第二层保护。
- 自由大厅柜子现按 D-083 扩为 `20×20`，UI 使用 `32px` 单格的 `640×640` 内容和 `680×336` 可滚动视口；正式开始时同一个 `GridInventory` 在清空后安全缩回 `10×8`。滚动视口外禁止接受拖放，避免物品落到不可见区域。
- 后续实机截图确认异形柜内完整名称与状态文字会被图像遮挡、在 1×1 格内只剩一两个字。当前 `InventoryGridView` 已改为分层信息：小件不再绘制完整格内名称，只有宽度至少约三格的大件显示带省略号的深色名称条；堆叠数量和状态使用独立角标。悬停会在柜子底部 `ItemDetailLabel` 以及 Tooltip 显示完整名称、数量、旋转后的占格、品质、失败标签和主动调味，并用黄色外框标识当前物品。
- `ShabuTrap` 新增子节点 `AromaRangeIndicator`，绘制淡色填充、双层圆环与 12 个边界刻度，锁定敌人后换色。显示半径与 `is_available_for()` 共用 `PrototypeCombatConfig.shabu_aroma_radius`，当前仍为 310；不得为了改视觉另建半径或擅自调整数值。
- 0.6A 专项新增真实悬停完整名称 / `3×3` 占格显示，以及香气圈节点、实际半径、内外边界判定一致性测试。资源扫描、普通 OpenGL 启动、Headless 180 帧和十套全量回归均通过。
- 玩家移动序列的源朝向曾被误判，实机反馈表现为左右相反。当前 `DirectionalWalkAnimator` 的玩家配置已纠正为“源图朝右”：向右移动不翻转，向左移动 `flip_h`，纯上下移动继续保持最近水平朝向。普通 / 重型味真族配置未改变。
- `Kitchen/TrashBin` 位于水池右侧，复用现有 `Interactable` 和玩家 `consume_held_item()`：手持物品按 E 会删除当前选中快捷栏中的整个真实实例 / 堆，并给出销毁反馈。它只是基础空间清理设备；不得擅自加入返还、腐败、厨余强化或垃圾经济。
- 自由大厅的同一食材柜现在调用 `configure_lobby_unlimited_catalog()`，在 `20×20` 实例网格中展示当前全部 22 个 `ItemType`，包含具备正式耐久 / 战斗属性的完成料理。直接取出会生成测试样本；拖走目录样本后通过延迟补充恢复对应类别，避免与三容器原子拖放回滚冲突。
- 点击“开始营业”仍先走 D-068 的完整正式新局重置，并由 `configure_prototype_stock()` 切换到六类有限正式库存；波间不补货，返回自由大厅才恢复无限测试目录。不要把大厅目录带入正式经济。
- 0.6A 专项真实验证了 22 类覆盖、完成料理战斗数据、目录拖取与补回、同一实例进入快捷栏、垃圾桶实际销毁、玩家左右 / 上下朝向和大厅—正式—大厅切换。为保持历史语义，0.1—0.3.2 中六组柜子测试改为先进入正式准备再检查有限库存 / 扣减；断言未被削弱。
- Godot 4.6.2 资源扫描 / 全局脚本解析通过，主场景 Headless 180 帧退出码 0，Prototype 0.1—0.6A 十套全量回归 10 / 10 通过。0.5 阻断测试出现的 Playtest Notes 文件错误是故意失败路径覆盖，测试本身通过。

## 2026-07-23 最新交接：Prototype 0.6A 已完成代码与自动验收

当前代码已形成第一条局内资源循环：有限初始实际物品 → 烹饪战斗 → 普通 / 重型味真族生成实体战利品 → 玩家亲自拾取 → 五格快捷栏满后进入 `6×6` 背包 → 在实时 `10×8` 正式异形食材柜中存取 → 后续继续烹饪；自由大厅另使用同一柜子的 `20×20` 无限测试目录模式。权威设计见 `Prototype_0_6_Loot_Inventory_and_Storage_Design.md`。

### 切换 DeepSeek Codex 前的最新 UI 修复

- 玩家、普通味真族、重型味真族已接入 `4×3`、12 帧移动图。共用 `DirectionalWalkAnimator` 只在水平移动时更新左右朝向，纯上下移动保持最近朝向；玩家由实际输入驱动，两种敌人读取既有速度。快速型序列只在 `Assets/Prototype/Animation/Characters/` 入库，禁止在未完成角色设计前擅自创建新敌人。调整帧率或显示尺寸时只改动画表现，不得联动移动速度、碰撞或寻路。
- DeepSeek Codex 后续接入 `marinade.png` / `mustard.png` 时曾把 `ItemCatalog.get_art_key()` 的盐、腌肉料、芥末、煎锅 `match` 分支少缩进一级，造成全项目连锁解析失败；现已最小修复并保留两张素材。继续修改物品美术映射后必须立即运行 Godot 脚本解析和主场景启动，不能只检查图片文件。
- 首轮人工试玩发现柜内物品无法可靠拖放 / 旋转：原因是 GUI 消费了 `_unhandled_input()` 中的鼠标松开与 R。现在统一由 `IngredientCabinetUI._input()` 接收拖拽完成和旋转，不得移回依赖节点输入顺序的实现。
- 拖拽时显示跟随鼠标的半透明预览，源网格暂时隐藏原物品；悬停背包 / 柜子时按当前异形占格逐格绘制红色落点框，R 后红框立即改变方向。
- “旋转后瓶子仍朝上、只被横向压扁”的根因已修复。`DragPreviewArtwork` 和 `InventoryGridView._draw_item_texture()` 都先保持美术素材原始宽高比，再围绕占格中心真实旋转 90 度；拖拽预览及成功落格后的正式显示必须保持一致。
- `prototype_0_6a_regression_test.gd` 已覆盖真实网格按下、跟随预览、R 图片旋转、红框方向、失败回滚及旋转后成功落格。当前 0.6A 专项 6 / 6、Prototype 0.1—0.6A 十套回归全部通过，普通窗口 0.6A 测试通过。
- 仍需项目负责人人工确认：1280×720 下不同形状物品的图像大小、红框可读性、鼠标跟手感，以及瓶子等方向明显素材在背包和柜子之间往返后的朝向。若仍有视觉问题，优先检查上述两个统一绘制入口，不要改动物品实例或网格原子移动逻辑。

继续开发时必须保持：

- 五格快捷栏仍是唯一直接手持 / 使用层；背包和柜子复用 `GridInventory`，持有同一个 `CarryableItem` 实例。
- 不得重新引入固定数字库存作为柜子权威数据，不得把背包物品直接当作手持物。
- 拆分堆叠或复制加工状态必须使用 `ItemCatalog.duplicate_data()`；不要直接依赖 `ItemData.duplicate(true)`。
- 一块整牛肉第一次切割产出三个独立牛排；旧的单产出测试语义已被替代。
- 正式开局继续执行 D-068 完整重置；波间不清背包、柜子和地面战利品。
- 背包 / 柜子必须接入 D-070 局部模态优先级，打开时世界继续运行。
- 新鲜度、腐败、垃圾加工和冰箱尚未实现；只有“手持物按 E 直接销毁”的基础垃圾桶已授权落地，不得把它误写成完整 0.6B 垃圾系统，也不得把 0.6A 临时参数固化为最终设计。

当前最优先是项目负责人人工试玩 1280×720 背包 / 柜子拖放、R 旋转、混战拾取、三牛排逐块取走、初始资源压力和 35% 掉率。若反馈没有阻断，再单独确认 0.6B 的新鲜度 / 腐败范围。

上述 Prototype 0.6A 源码、资源、测试和文档现已作为发布提交 `03d0be5` 与标签 `v0.0.2` 推送；对应 Windows Release 已公开。任何下一位 AI 仍必须先读取 `git status`，保护发布后的新修改。

> 最后更新：2026-07-25
> 最近交接来源：GPT Codex（战斧仓储显示与玩家方向箭头清理）
> 接手原则：假设下一位 AI 看不到任何聊天记录，只能读取仓库。

## 当前开发阶段

当前开发版本为 **Prototype 0.6A：异形背包、真实仓储、牛肉多份加工与实体战利品闭环**。Prototype 0.5 的营业准备、统计结算、暂停、开发试玩记录及 0.5.1 阻断修复仍是必须保持的历史基础。

本轮在 0.4 核心玩法不变的前提下修复暂停 / F9 状态、真实记录输入和保存、ESC 局部模态优先级、正式开局状态污染、持续交互反馈和战斧触发 / 命中可靠性，并补充“未摆盘小炒可直接战斗”的正式规则。下一步是项目负责人人工完成一次成功和一次失败流程并验证实际手感；新料理、新敌人和成长内容继续暂停。

`v0.0.2` 已于 2026-07-24 公开发布。本地版本、CHANGELOG、README 与 Prototype 0.6A Windows 发布包均已验证；在 BGM 连贯性与大厅 `20×20` 柜修正后重新生成的 ZIP 大小为 `45,447,902` 字节，SHA-256 为 `F2F5B638DC9678845EA3077DCA109215C90EECF09222C10DC4DFA0BC7B990952`，原始与解压构建 120 帧自检均通过。发布提交 / 标签为 `03d0be5`，Release 地址为 `https://github.com/CXuze0605/WhoIsTheBeastChef/releases/tag/v0.0.2`；远端资产状态和摘要已核验一致。

## 当前项目状态

- Godot：4.6.2 stable，Compatibility，1280 × 720，主场景 `res://Scenes/prototype_0_1/main.tscn`。
- 场景载入后进入可操作的 `FREE_PREPARATION` 独立练习大厅；点击“开始营业”先复用完整新局重置清除大厅成果，再进入 32 秒 `PREPARATION`，倒计时结束后才开始第一波预警与生成。正式准备内新制作的内容不会再次清除。
- 正式准备开始时测试假人隐藏、停用碰撞并移出伤害 / 瞄准组；结算返回大厅后恢复。
- F3 可隐藏 / 恢复右侧开发辅助 UI，默认仍为开发模式。
- ESC 先交给当前局部模态（素材柜、摆盘），无局部界面时才打开全局暂停并冻结场景树与当前 BGM；可继续或二次确认后复用完整大厅重置入口退出本局。
- F9 仅在 Godot 编辑器运行环境中打开试玩记录面板。可从游戏或暂停菜单进入，关闭时精确返回来源状态；三个真实可编辑输入框追加到仓库根目录 `AI_Context/Playtest_Notes.md`，保存失败也始终可退出，正式导出不响应。
- 五格快捷栏保存真实物品实例；盘子按既有规则堆叠。
- 五格快捷栏、素材柜库存和柜内物品栏均为图片主显示；普通公牛使用独立牛头图，巨大整牛只用于完美料理。缺少正式素材的物品使用颜色图标兜底。
- 两个通用灶位，炒锅、煎锅、汤锅三口可搬运锅具。
- 已有三种代表性料理战斗形式：小炒远程公牛、战斧近战、涮牛肉诱食陷阱。
- 完成炒制的未摆盘小炒已是完整普通战斗成品：可直接释放普通公牛，首次使用后永久失去摆盘资格，未摆盘耗尽不产生脏盘；只有未使用且满耐久版本可继续摆盘并争取完美。
- 玩家头顶有读取既有 `HoldProgress` 的小型持续交互条；战斧有 0.16 秒点击缓冲、0.13 秒命中窗口和碰撞半径扇形判定，正式战斗数值未改。
- 已有普通与重型两种近战味真族和三波连续测试。
- 味真族使用 32 像素静态 `AStarGrid2D`；重型净空、软拥堵、玩家周围追击槽和无进展脱困已加固，敌人之间不再硬碰撞。
- 已有基础本局统计与成功 / 失败统一结算，点击“结束本局”返回重置后的自由大厅。
- 已有统一 Autoload `AudioManager`：自由大厅播放大厅曲，正式烹饪准备开始即进入战斗曲，并跨所有小波、预警和波间连续保持；成败结算分别播放成功 / 失败曲，四首循环，默认 0.8 秒交叉淡化。
- 大型暴怒公牛保留友伤；玩家 / 友方每头最多受击一次，独立友伤为 18，并有 HUD 接近预警。
- 新增 0.5 阻断专项 6 / 6 组；0.1 至 0.5 八套历史自动化测试全部通过，0.5 当前为 9 / 9 组；最近一次资源扫描 / 脚本解析、主场景 Headless 180 帧和普通窗口 180 帧启动均通过。
- v0.0.1 Windows 包已由 Godot 4.6.2 正式模板导出，并通过隐藏启动检查；构建产物位于被 Git 忽略的 `Builds/`。
- 完整源码已发布到 `https://github.com/CXuze0605/WhoIsTheBeastChef`，提交 `921d549` 对应标签 `v0.0.1`；Windows 包位于 `https://github.com/CXuze0605/WhoIsTheBeastChef/releases/tag/v0.0.1`。仓库当前不添加许可证。

## 已完成内容

- 牛肉两次切割、腌制、小炒黄牛肉、盐 / 芥末、焦糊 / 焦炭与粘锅清洗。
- 主动摆盘 QTE、四档品质、盘子堆叠、脏盘池和连续洗盘。
- 普通 / 大型暴怒公牛、毒伤、玩家生命和阵营伤害。
- 自由准备、双层来袭预警、分批刷怪、波间准备、三波完成和完整新局重置。
- 战斧牛排翻面、近战、装盘资格、完美大骨头和芥末喷嚏。
- 生牛肉片五份、汤锅涮煮、涮肉陷阱、重型韧性。
- 攻击形式与烹饪方式数据标签；当前没有实际抗性。
- 自由大厅、32 秒营业准备、F3 玩家模式、测试假人生命周期与返回大厅。
- 场景级料理 / 伤害 / 击败 / 友伤 / 队友击倒统计及统一成败结算。
- 统一 BGM 管理器、双播放器淡化、四首阶段音乐与音量扩展接口。
- ESC 暂停 / 恢复、退出本局二次确认、既有大厅清理复用及编辑器 F9 Markdown 试玩记录。

## 最近一次修改

最近一次功能修改是 Prototype 0.5 真实试玩阻断修复：`PrototypeToolsOverlay` 以可恢复来源状态协调暂停菜单与 F9 记录，局部模态 ESC 优先级集中到同一入口；记录面板覆盖真实 Unicode 输入、按钮、仓库根目录追加和失败可退出。开始营业改为先走完整新局重置再进入 32 秒正式准备，修正 D-063 保留大厅成果的旧部分。玩家头顶条只读取既有 HoldProgress；未摆盘小炒成菜即获得普通战斗数值并遵循使用后禁摆盘 / 无盘耗尽规则；战斧增加短输入缓冲、短时复检和碰撞半径扇形判定。新增阻断专项 6 / 6，八套历史回归、资源扫描和两种主场景启动均通过。详见 D-068 至 D-071。

最近一次 UI / 美术修改是普通公牛牛头确认与库存图片化：使用项目负责人本次附件重新覆盖 `normal_bull.png`，普通攻击与巨大整牛资源继续严格分离；`QuickInventoryUI` 和 `IngredientCabinetUI` 通过现有物品美术键显示最近邻图片，保留格号、数量、选中状态和文字兜底。腌肉料、芥末等缺图项暂用物品颜色块，不擅自新增美术。八套回归和主场景 120 帧通过。

最近一次表现层修改是第二批静态美术接入：玩家、普通 / 巨大公牛攻击、干净盘子堆、大块生牛肉、生牛排、牛肉片单片 / 成组、涮牛肉单片 / 成组和两类测试假人均已有透明 PNG。`ItemCatalog.get_art_key_for_data()` 根据剩余份数 / 堆叠数切换单片与成组图，放置的涮牛肉陷阱固定显示单片图；玩法和数值未改。0.5 为 9 / 9，八套回归和主场景 120 帧通过。素材仍是静态单帧，需人工确认比例、文字叠放、朝向与动态可读性。

最近一次功能修改是味真族导航防卡：保持 `AStarGrid2D` 技术路线，把导航净空从 15 对齐到重型碰撞半径 23（当前代理 24），敌人只与世界 / 玩家硬碰撞，单位间用受移速限制且经过禁行格过滤的软分离；同一玩家周围分配追击槽，并在 0.75 秒无路径进展后重算与短侧向脱困。攻击、速度、伤害和状态机未改。当前仍只有单个强类型 `PrototypePlayer` 目标，未来多玩家 / 权重需要独立目标选择接口。0.5 为 8 / 8，八套回归和主场景 120 帧通过。

前一版 Prototype 0.5 暂停与开发试玩记录工具建立了最高层 `PrototypeToolsOverlay`、`SceneTree.paused`、BGM 暂停和 `return_to_lobby()` 清理复用。其当时“ESC 优先于素材柜、暂停菜单中忽略 F9”的输入细节已经被最新 D-070 / D-071 修正；不得恢复旧行为。F9 仍只在编辑器特征下可用，并追加仓库根目录 `AI_Context/Playtest_Notes.md`。

前一轮功能修改是 Prototype 0.5 基础 BGM 接入：四首 MP3 位于 `GodotProject/Audio/bgm/`，`PrototypeAudioManager` 以 Autoload 形式集中管理；`prototype_main.gd` 只根据现有波次阶段请求曲目，不修改状态机。Headless 模式不启动不可听见的解码播放，只验证曲目选择、循环资源与淡化接口。

前一轮功能修改是 Prototype 0.5 第一阶段：新增 `RunStats`、准备倒计时和结算 UI，调整首波开始状态机、测试假人生命周期、开发 UI 显隐以及大型暴怒公牛友伤链。0.5 当时新增 4 组验收，0.1—0.4 历史回归同步适配并全部通过；主场景自然运行通过。详细执行记录见 `AI_Work_Log.md`，正式规则见 `Decision_Log.md` 的 D-063 至 D-065。

最近一次项目收尾是 v0.0.1 公开发布和线程归档：源码、标签与 Windows Release 已公开；随后更新 AI_Context 记录实际远程状态。本地 `HEAD` 为 `4967faa docs: record v0.0.1 release`，因 GitHub 连接超时尚未推送，且本次归档修改了 `Current_Status.md`、`AI_Work_Log.md`、`Pending_Tasks.md` 和本文件。新线程不得把这些内容当作可丢弃的临时改动。

Prototype 0.5 没有改变 0.4 的料理、锅具、敌人和三波规则；这些底层玩法的完整说明仍见 `Prototype_0_4_Beef_Branches_and_Multiwave.md`。

最近一次游戏表现修改是首批静态 PNG 接入：素材从 `D:/静止素材/` 复制到 `GodotProject/Assets/Prototype/Static/` 并改为明确英文名，通过 `PrototypeArtCatalog`、`PlaceholderVisual`、物品映射和场景属性替换玩家、基础味真族、主要厨房设施及部分物品的程序占位表现。原始素材目录未修改；玩法规则和数值未改变，现有厨房障碍碰撞尺寸已按图片显示范围校准。详细记录见 `Prototype_0_4_Static_Art_Pass_1.md`。

同日完成 `v0.0.1` 公开发布：重写根目录 `README.md`，新增 `CHANGELOG.md`、`.gitattributes` 和可版本管理的 Windows 导出预设，并在 `project.godot` 中写入版本号。使用 Godot 4.6.2 正式模板导出的 `.exe + .pck` 已启动成功，七套回归测试全部通过，Windows ZIP SHA-256 为 `B0B362BB1BEB9250DDE4A73D1D7381955E01F2E9F9D48C9529C1A6F83146305D`。源码提交 `921d549`、`main`、标签 `v0.0.1` 和 GitHub Release 均已公开；GitHub API 验证 ZIP 状态为 `uploaded` 且摘要一致。

2026-07-22，DeepSeek Codex 完成一次全量只读接手审计：阅读全部 20 份 `AI_Context` 文档和 55+ 个脚本，输出中文标注的游戏数值清单，但没有修改任何项目文件。该记录属于 0.5 开发前历史；当前待办已更新为 Prototype 0.5 全流程人工试玩。

注意：该中文数值清单尚未确认存在仓库文件路径，因此不能依赖聊天记录把它视为已持久化资料；如需长期使用，应另行把原始清单写入项目文档。

## 当前不要修改的内容

- 不要恢复 0.3.2 的阻塞式 `WAITING_TO_START` 流程，也不要绕过 0.5 的正式营业准备倒计时。
- 不要创建第二套物品栏、波次管理器、品质系统、毒伤系统或玩家生命系统。
- 不要把通用灶位重新写死为只能放炒锅。
- 不要按显示名称判断料理、锅具、攻击形式或敌人抗性。
- 不要把失败标签与 `salted` / `mustard` 主动调味混为同一列表。
- 不要删除或覆盖其他 AI / 用户的未提交文件。
- 不要实现正式抗性、奖励、波间补给、第三敌人、Boss、联机或新食材，除非项目负责人明确授权。
- 不要重打、移动或删除已经公开的 `v0.0.1` 标签和 Release，也不要替换发布资产，除非项目负责人明确要求。
- 不要在 Prototype 0.5 人工试玩前启动新料理、新敌人、新成长或大型架构重构。
- 不要擅自 Git 提交。

## 当前重点关注问题

1. 0.5 完整流程和真实手感尚未由项目负责人人工确认。
2. 两灶三锅、翻面、陷阱和三波可能增加认知负担，需要判断是否“忙乱但可读”。
3. 重型韧性应可感知，但不能被误解为隐藏料理抗性。
4. 第一批静态 PNG 与暖色地图地板已接入；旧灰盒色块在有图片时隐藏，设施碰撞按实际图片显示范围校准。普通与重型味真族均已有独立图片；部分物品 / 料理、攻击实体、陷阱、地图细节和正式 UI 仍是程序占位表现。
5. 已有包含全部 Prototype 与 AI Context 的公开 Git 基线；本地还存在 1 个未推送文档提交和本次归档修改，后续必须先检查 `git status`，不得覆盖其他 AI / 用户的工作。
6. “击倒队友”接口已建立，但正式单人流程没有真实队友，当前主要由测试假人验证，正常结算通常为 0。
7. 四首 BGM 的状态映射与循环已自动验证，但循环接缝、相对响度和淡化手感仍需完整流程人工听检。
8. 暂停冻结、确认退出和 F9 文件写入已自动验证；暂停界面视觉、柜子 / QTE 场景按键感和中文输入法仍需编辑器人工确认。
9. 重型导航净空、软拥堵和无进展脱困已自动验证；混合波在设施附近的视觉重叠与转弯自然度仍需人工确认。当前目标字段仍绑定单个玩家，不能视为已经支持多人目标权重。

## 下一步推荐工作

推荐下一步：项目负责人在编辑器中完成一次成功和一次失败的 Prototype 0.5 全流程，核验 32 秒准备、ESC 暂停 / 确认退出、F3 玩家模式、F9 实际保存一条试玩记录、结算统计、测试假人退出 / 恢复、大型公牛友伤及大厅 / 战斗 / 成败音乐切换；同时听检循环接缝、相对响度和淡化。试玩结论出来前不扩展新玩法。旧 v0.0.1 Release 的外部下载验证仍未完成，但它不包含本轮 0.5 修改。

如果委托 AI 修复：先复现，说明修改目标，保持范围最小，运行相关测试与八套全量回归，然后更新 `Current_Status.md`、`AI_Work_Log.md`、`Pending_Tasks.md` 和本文件；涉及设计变化时再更新 `Decision_Log.md`。

## 注意事项

- 权威优先级：`Design_Pillars.md` → `Decision_Log.md` → `Current_Status.md` → `Pending_Tasks.md` → 最近 `AI_Work_Log.md` → 本交接文档。
- `Stage1_Midterm_Summary.md` 和旧 Prototype 文档保留历史设计 / 实现，顶部的增量或修正说明优先于历史正文。
- `Development_Roadmap.md` 是里程碑计划，不等同于当前授权；当前授权只看用户请求和 `Pending_Tasks.md`。
- 聊天中没有写入仓库的重要信息不视为正式保存。

## 2026-07-27 交接增量：假人 A 自动攻击测试工具

- `Kitchen/EnemyDummyA` 通过 `DebugCombatTarget` 的导出参数启用开发自动攻击能力；默认开关为关。
- F3 右侧开发 UI 底部的 `EnemyDummyAAutoAttackToggle` 是唯一玩家入口。不要再创建另一套假人攻击控制器。
- 攻击目标依据 `damageable`、`get_combat_faction()` 和 `receive_combat_hit()` 筛选玩家 / 友方阵营，因此未来召唤物只要遵循既有伤害接口即可自动参与测试。
- 当前 Prototype 参数：范围 220、间隔 1 秒、伤害 8、击退 34；均为开发测试值，不是正式敌人平衡。
- 正式营业生命周期通过 `set_lobby_active(false)` 自动关闭开关，保证测试假人不会污染正式本局。
- 专项验证已加入 `prototype_0_6b_regression_test.gd`，该测试现为 9 / 9 组；2026-07-27 全量 11 / 11 个历史测试脚本通过。
