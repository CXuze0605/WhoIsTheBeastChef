# Architecture Map

## 1. 文档定位

本文件记录当前主要模块、依赖方向和已知耦合观察项，供 Chat 与 Codex 快速定位调查入口。它不替代实际代码：运行时行为、最新修改和场景连接仍需按任务核验。当前实现状态以 `Current_Status.md` 为准，当前任务以 `Pending_Tasks.md` 为准。仅当版本或架构发生明显变化时更新，不要求每次小改同步。

## 2. 核心模块地图

| 模块 | 主要入口 | 核心职责 | 主要依赖 | 通信方式 |
|---|---|---|---|---|
| 玩家 | `GodotProject/Scripts/prototype_0_1/player/prototype_player.gd` (`PrototypePlayer`) | 移动、疾跑体力、生命护盾、拾取、库存、交互、食用 | 库存、站点、战斗、统计、新鲜度 | 子节点、节点组、信号、直接调用 |
| 战斗 | `combat_manager.gd`、`dish_attack_controller.gd`、`combat_rules.gd` | 攻击分发、战斗实体、伤害与状态 | 玩家、敌人、`ItemData`、`PrototypeCombatConfig` | `DamageContext`、组查询、实例化、直接调用 |
| 烹饪与配方 | `wok_station.gd`、加工站、`expanded_recipe_catalog.gd`、`plating_controller.gd` | 加工、离散烹饪、配方形成、摆盘品质 | 玩家手持物、厨具、QTE、战斗配置 | NodePath、共享 `ItemData`、直接调用 |
| 物品与库存 | `item_data.gd`、`item_catalog.gd`、`grid_inventory.gd`、`quick_inventory.gd` | 物品状态、堆叠、新鲜度、异形存储、流转 | 物品节点、玩家、柜子、站点 | 共享 Resource、`changed` / `selection_changed` 信号 |
| 烹饪大典 | `cookbook_catalog.gd`、`cookbook_ui.gd` | 料理资料、解锁状态、书本 UI | 配方 ID、物品数据、美术目录、菜单/暂停入口 | 静态目录/状态、UI 回调 |
| 地图与波次 | `Scenes/prototype_0_1/main.tscn`、`prototype_map_controller.gd`、`wave_manager.gd` | 地图边界、十入口、导航、三波流程、掉落与局内重置 | 玩家、导航、站点、统计、新鲜度、战斗、生成点 | NodePath、节点组、信号、场景树实例化 |
| UI | HUD、`ingredient_cabinet_ui.gd`、`plating_qte_ui.gd`、`prototype_tools_overlay.gd` | 显示、拖放、局部模态、暂停与设置入口 | 玩家、库存、摆盘、局内流程 | 玩家信号、NodePath、组查询、少量直接调用 |
| 全局状态 | `Scripts/core/app_session.gd`、`settings_manager.gd`、`audio_manager.gd` | 跨场景启动模式、设置/改键、音乐 | 场景切换、InputMap、AudioServer | `/root/...` Autoload、信号 |

## 3. 推荐内容接入路径

| 内容 | 推荐入口 | 避免的直接依赖 |
|---|---|---|
| 新料理 | `ItemData` / `ItemCatalog` → `ExpandedRecipeCatalog` → 对应站点 → 战斗分发与配置 | 在 UI、测试大厅或掉落逻辑中直接写配方规则 |
| 新食材 | `ItemData`、`ItemCatalog`、存储/新鲜度目录，再接站点与掉落 | 只补图标或柜子库存而不定义数据生命周期 |
| 新敌人 | `BasicTasteEnemy` 子类、`PrototypeWaveConfig`、`WaveManager` 生成分支 | 在玩家、UI 或地图控制器中实现敌人行为 |
| 新怪群 | `PrototypeWaveConfig` 批次数据与 `WaveManager` | 绕过合法入口直接生成敌人 |
| 新餐厅入口 | `WaveSpawnPoint`、`main.tscn`、`PrototypeMapController` | 只添加 Marker；当前控制器还依赖入口名称布局 |
| 新 UI | 独立 UI 脚本，以信号读取或请求玩法动作 | 直接改写另一玩法控制器的内部状态 |
| 新战斗规则 | `DamageContext`、`CombatRules`、`CombatStatusController`、集中配置 | 在单个投射物中另写伤害结算 |
| 新全局状态 | 仅跨场景状态扩展 `AppSession` | 将局内波次、库存或战斗状态放入 Autoload |

## 4. 当前主要耦合风险

以下均为观察项，不代表当前必须重构。

1. **`WaveManager` 的局内总管职责**：除波次外还处理敌人、掉落、短缺补偿、新鲜度结算、测试大厅和新局重置。新增局内系统可能连带影响多个流程。当前策略：先完成 P0 实机验收；后续只在明确痛点下做小范围解耦。
2. **料理功能跨多个 `recipe_id` 分支**：配方、站点、摆盘、攻击分发、战斗对象、配置与大典可能需要同步更新。新增料理容易遗漏接线。当前策略：沿用现有路径和专项验证，不在当前阶段重写为全新数据架构。
3. **`PrototypePlayer` 集中持有多类状态**：输入、移动、生命、体力、库存、交互、食用与被动效果在同一控制器内。修改任一状态系统可能影响玩家生命周期。当前策略：保持整体结构，先以最小改动修复可复现问题。

## 5. 当前保持不动

- `PrototypeCombatConfig` 与 `PrototypeWaveConfig`：当前 Prototype 数值仍在验收，集中配置利于统一调参。
- 大餐厅白盒与 `main.tscn` 当前层级：地图、十入口、导航和拥挤仍在 P0 验收，提前迁移会破坏对照。
- `FreshnessManager` 当前生命周期扫描：先验证局内经济闭环和高密度对象表现，再评估性能或职责调整。
- `PrototypePlayer` 当前整体结构：跨越状态过多，但拆分范围大、回归风险高，当前不以整洁为由改动。

## 6. 第一次小型解耦候选

候选：将背包 UI 的“整颗青菜双击拆分”从 `IngredientCabinetUI` 直接按组查找 `PlatingController`，改为 UI 发出请求信号、摆盘控制器接收处理。

- 当前不立即实施；只有 P0 试玩发现背包、ESC 或 QTE 冲突，或该直接依赖阻碍开发时才启动。
- 最小范围：`ingredient_cabinet_ui.gd`、`plating_controller.gd`，必要时 `main.tscn` 的信号连接；不改变其他库存或摆盘规则。
- 必须保持：整颗青菜双击仍关闭背包并启动可移动 QTE；其他物品双击、自动装备、ESC 优先级与暂停行为不变；保留现有延迟时序。
- 验收：普通窗口验证上述行为，并确认柜子关闭、QTE 启动、取消与恢复流程均无重复触发或输入穿透。

## 7. 重新审计触发条件

仅在以下情况重新进行较完整的模块审计：

- 主场景结构发生明显变化；
- `WaveManager` 或 `PrototypePlayer` 被拆分；
- 料理数据路径被重构；
- 新增大型玩法系统；
- 同类耦合 Bug 连续出现；
- 本文件与实际代码明显不符。
