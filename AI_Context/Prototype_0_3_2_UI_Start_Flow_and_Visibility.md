# Prototype 0.3.2：启动流程、HUD、快捷栏与可读性调整

> **0.4 修正说明（2026-07-21）**：本文记录的 `WAITING_TO_START`、全屏等待与“开始游戏后才初始化操作权”是已被试玩反馈纠正的旧实现。当前有效流程为：进入场景立即初始化并自由准备；边缘“开始营业”只触发第一波全局预警且不重置厨房成果；失败或三波完成后重新开始才完整重置。本文的五格栏、生命 HUD、大型公牛参数、相机与局部环形提示仍然有效。

> 实现日期：2026-07-20  
> 场景入口：`res://Scenes/prototype_0_1/main.tscn`  
> 引擎验证：Godot 4.6.2 stable / Compatibility  
> 性质：实际试玩反馈驱动的灰盒可读性调整；容量、视觉和全部数值均不是最终设计

## 一、本轮试玩反馈

1. 玩家生命只在 Debug 文字中出现，战斗时不易读取。
2. 进入场景立即开始准备倒计时，缺少明确的本局初始化与玩家主动开始边界。
3. 三格快捷栏在料理、调味、盘子和锅具同时参与时过于局促。
4. 扩大地图后，完美料理的大型暴怒公牛持续时间、速度和体型缺少存在感。
5. 屏幕固定普通烹饪文字遮挡视线，也削弱了通过观察厨具管理厨房的体验。
6. 相机仍按旧近距离尺度显示，扩大地图的战斗空间没有被充分利用。

## 二、等待开始与本局初始化

`PrototypeWaveManager.Phase` 增加 `WAITING_TO_START`。进入主场景时：

- 准备倒计时保持完整值且不递减；
- 不进入来袭预警，不生成味真族，不推进波次；
- 玩家世界输入被锁定；
- `WokStation.session_active` 为 `false`，自动烹饪不提前运行；
- `StartGameUI` 显示“开始游戏”按钮。

点击“开始游戏”后，现有 WaveManager 统一执行本局初始化：

- 清除基础味真族、普通 / 大型公牛和旧波次统计；
- 恢复玩家 100 / 100 生命、出生位置和空快捷栏；
- 重置统一食材柜为集中配置的有限库存；
- 重置干净盘子、脏盘池和洗净 / 领取统计；
- 清空切菜板与腌制区域；
- 重新建立无油、未粘锅、无内容且关火的炒锅；
- 关闭摆盘 QTE，重置 Debug 假人；
- 开启本局自动烹饪更新并进入 `PREPARATION`。

“开始游戏”与“开始营业”保持不同职责：

- 开始游戏：只在 `WAITING_TO_START` 初始化整局并进入准备阶段。
- 开始营业：只在 `PREPARATION` 记录剩余准备秒数并进入既有全局来袭预警；不重置或返还资源。

开始界面是 Prototype 占位，不是正式主菜单、存档或关卡选择界面。

## 三、玩家血条

主场景新增 `PlayerHUD` CanvasLayer，左上角包含水平 `ProgressBar` 和 `当前 / 最大` 数字。它订阅 `PrototypePlayer.health_changed`，不创建第二套生命数据：

- 敌人或大型公牛造成伤害后立即刷新；
- 受伤时短暂颜色闪烁；
- 开始新游戏时随现有玩家生命重置为满值；
- 局部来袭提示向右避让，不与左上角血条重叠；
- CanvasLayer 保证相机移动和缩放不改变 HUD 尺寸。

## 四、五格快捷栏

`QuickInventory.SLOT_COUNT` 从 3 调为 5：

```text
[1] [2] [3] [4] [5]
```

- UI 和底层数组都读取同一容量常量；
- 滚轮在五格间循环；
- `select_hotbar_1` 至 `select_hotbar_5` 分别绑定数字键 1—5；
- 当前格仍是手持和工位交互来源；
- 每格仍保存完整 `CarryableItem` 实例；
- 料理品质、标签、调味、耐久、盘子数量及炒锅内容不会因切格重建；
- 干净 / 脏盘仍每格最多堆叠 4 个，其他当前物品仍为单件；
- 五格全满时，第六件物品、柜子取料和工位取出继续安全拒绝。

五格是 Prototype 测试容量，不是正式背包总格数；手持位、物品体积和正式网格仍未确定。

## 五、大型暴怒公牛强化

参数集中在 `PrototypeCombatConfig`：

| 参数 | 修改前 | Prototype 0.3.2 | 倍率 / 说明 |
|---|---:|---:|---|
| 持续时间 | 6.0 秒 | 24.0 秒 | 4 倍 |
| 移动速度 | 320 | 800 | 2.5 倍 |
| 命中 / 边界半径 | 50 | 65 | 1.3 倍 |
| 占位视觉 | `152 × 104` | `198 × 135` | 约 1.3 倍 |
| 单目标命中冷却 | 0.45 秒 | 0.45 秒 | 不变 |
| 伤害 / 击退 | 48 / 95 | 48 / 95 | 不变 |

反弹、随机转向预警、友伤、不伤厨房设施和持续时间结束消失均保持不变。高速移动按 `raging_bull_radius × 0.45` 的最大步长拆分，再逐段检测并反射边界，避免较大物理帧越过地图或在角落单帧重复反射。命中仍受单目标冷却限制。

## 六、普通烹饪提示与局部环形指示器

已删除屏幕固定的 `CookingStatusUI` 以及炒锅原横向 `ProgressBar`。以下普通烹饪信息不再在屏幕中央 / 固定位置显示：

- 第一阶段完成与等待辣椒；
- 第二阶段成菜；
- 即将焦糊、已经焦糊和焦炭；
- 粘锅事故的远距离固定文字。

`WaveWarningUI` 的味真族来袭、波次完成和玩家失败属于全局流程提示，继续保留。

炒锅工位新增 `CircularCookingIndicator` 世界空间节点，固定在锅具上方并随工位移动。它只显示阶段进度或静态状态，不改变食物数据：

| 状态 | 环形表达 |
|---|---|
| 灶火关闭 | 灰色静态环 + 斜线 |
| 空锅开火 | 橙色静态环 + 火焰占位符号 |
| 第一阶段 | 蓝色阶段进度环 |
| 等待辣椒 | 黄色闪烁静态环 + 等待符号 |
| 第二阶段 | 绿色阶段进度环 |
| 成菜等待取出 | 橙色计时环 + 完成符号 |
| 即将焦糊 | 红色闪烁计时环 + 警告符号 |
| 已焦糊并趋向焦炭 | 紫红色闪烁计时环 |
| 焦炭 | 深灰静态环 |
| 粘锅 | 红色闪烁静态环 + 叉号 |
| 炒锅离开工位 | 隐藏 |

关火、取菜和搬锅仍由既有自动烹饪逻辑清除当前阶段进度；指示器只读取 `HoldProgress` 和 `WokItem.CookStage`，不会生成连续熟度物品。

## 七、相机

运行时 `Camera2D.zoom` 由 `Vector2(1.0, 1.0)` 调为 `Vector2(0.75, 0.75)`，配置位置为 `PrototypeWaveConfig.camera_zoom`。可视宽高约增加三分之一；地图边界仍为左 28、上 28、右 1848、下 1356。`PrototypeMapController` 同时应用缩放和边界：

- 地图四角不露出场外空白；
- 玩家血条、五格栏、开始界面、波次 UI 都是 CanvasLayer，尺寸不变；
- 环形锅具提示属于世界空间，会随相机一起缩放；
- 大型公牛和普通公牛继续读取相同战斗边界。

## 八、主要文件

新增：

- `Scripts/prototype_0_1/ui/player_hud.gd`
- `Scripts/prototype_0_1/ui/start_game_ui.gd`
- `Scripts/prototype_0_1/ui/circular_cooking_indicator.gd`
- `Scripts/prototype_0_1/tests/prototype_0_3_2_smoke_test.gd`
- `AI_Context/Prototype_0_3_2_UI_Start_Flow_and_Visibility.md`

修改：

- `Scenes/prototype_0_1/main.tscn`
- `project.godot`
- `core/quick_inventory.gd`
- `player/prototype_player.gd`
- `wave/prototype_wave_config.gd`
- `wave/wave_manager.gd`
- `navigation/prototype_map_controller.gd`
- `combat/prototype_combat_config.gd`
- `combat/raging_bull.gd`
- `combat/combat_manager.gd`
- `stations/wok_station.gd`、切菜板、腌制、水池与盘子堆重置接口
- `plating/plating_controller.gd`
- 快捷栏与 Debug UI
- 0.1 至 0.3.1 自动化回归脚本

删除：

- `Scripts/prototype_0_1/ui/cooking_status_ui.gd`（屏幕固定普通烹饪提示）

## 九、验证结果

- `prototype_0_1_smoke_test.gd`：PASS
- `prototype_0_2_smoke_test.gd`：PASS
- `prototype_0_2_1_smoke_test.gd`：PASS，10 / 10 组
- `prototype_0_3_smoke_test.gd`：PASS，14 / 14 组
- `prototype_0_3_1_smoke_test.gd`：PASS，12 / 12 组
- `prototype_0_3_2_smoke_test.gd`：PASS，7 / 7 组
- Godot 4.6.2 编辑器扫描：PASS
- 主场景无界面自然启动：PASS
- 1600 × 900（16:9）与 1024 × 768（4:3）无界面启动：PASS，无解析或运行时错误

自动化覆盖等待状态不计时、开始游戏重置、开始营业分离、生命 HUD、五格满栏安全、数值与状态跨格保留、高速公牛边界、局部环形阶段状态、相机缩放，以及既有料理 / 波次系统回归。两种窗口比例均能启动，但实际构图、文字拥挤和手感仍需人工目视试玩。

## 十、Prototype 临时方案与已知问题

- 开始界面、血条、五格栏和环形指示器均使用 Godot 默认字体与程序色块，不是正式 UI / 美术。
- 五格容量不代表正式背包设计。
- 大型公牛 24 秒、800 速度、65 半径和 `198 × 135` 体型不是最终平衡；高速下的混乱程度仍需人工判断。
- 相机 0.75 缩放是当前 1280 × 720 灰盒参数；不同宽高比的构图与边缘提示仍需人工检查。
- 环形提示目前依赖颜色与简单符号，正式无障碍颜色、图标、声音和是否需要非中央远距补充尚未确定。
- “开始游戏”只初始化当前单场景 Prototype；正式主菜单、结算、关卡选择和存档未实现。
- 本轮没有增加任何敌人、料理、食材、奖励或成长系统。
