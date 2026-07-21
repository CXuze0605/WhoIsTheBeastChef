# Prototype 0.4：第一代静态美术接入（Pass 1）

> 日期：2026-07-22  
> 性质：Prototype 表现层替换，不是正式美术定稿，不改变玩法规则。

## 目标

把 `D:/静止素材/` 中第一批静态 PNG 识别为现有玩家、设施、锅具、食材和敌人，并以可替换的表现层接入当前 Prototype 0.4。沿用原有碰撞系统、物品实例、烹饪状态、波次与战斗逻辑；只允许为对齐图片校准现有障碍尺寸。

## 素材处理规则

- 原始目录保持不变；项目内使用复制件。
- 项目内统一放在 `GodotProject/Assets/Prototype/Static/`。
- 文件改为清晰英文名，不再使用哈希名或 `Sprite-00xx`。
- 对带纯色底的 PNG，仅从图片边缘做连通区域去底并裁剪透明边界；不修改内部白色、黑色线稿，不重绘内容。
- Aseprite 源文件没有接入运行时；当前只使用 PNG，避免引入第三方导入插件。

## 素材映射

| 项目文件 | 识别对象 | 当前接入状态 |
|---|---|---|
| `player_chef.png` | 玩家厨师 | 已接入玩家场景 |
| `basic_taste_enemy.png` | 基础味真族 | 已接入普通味真族；重型仍使用占位 |
| `ingredient_cabinet.png` | 统一食材柜 | 已接入主场景 |
| `prep_counter.png` | 切菜 / 备菜台 | 已接入切菜板 |
| `marinating_bowl.png` | 腌制容器 | 已接入腌制区 |
| `stove_station_double.png` | 双眼通用灶位 | 已用于当前两个通用灶位 |
| `washing_station.png` | 水池 / 清洗台 | 已接入水池 |
| `clean_plate_stack.png` | 干净盘子堆 | 已接入盘子领取点 |
| `wok.png` | 炒锅 | 已接入物品表现 |
| `frying_pan.png` | 煎锅 | 已接入物品表现 |
| `soup_pot.png` | 汤锅 | 已接入物品表现，并用于锅具架提示 |
| `raw_steak.png` | 生牛排 | 已接入物品表现 |
| `chili_segment.png` | 辣椒段 | 已接入物品表现 |
| `cooking_oil_bottle.png` | 食用油 | 已接入物品表现 |
| `salt_bottle.png` | 盐 | 已接入物品表现 |
| `plated_stir_fry_beef.png` | 小炒黄牛肉 | 已接入待摆盘和盘装小炒的 Prototype 表现 |
| `room_floor_warm.png` | 暖色厨房 / 战斗地板 | 已作为世界空间地板接入，并随地图边界伸缩 |

## 已规范命名但暂未连接

| 项目文件 | 原因 |
|---|---|
| `cold_storage_cabinet.png` | 当前 Prototype 没有独立冷藏柜设施，禁止凭素材新增系统 |
| `stove_station_single.png` | 当前地图配置为两个通用灶位，暂不混用单灶表现 |
| `room_floor_cool.png` | 保留为候选配色；当前场景只使用一套暖色地板，不自行设计区域切换 |

## 当前仍保留占位表现

- 整块生牛肉、生牛肉片、腌牛肉片、腌肉料、芥末、焦炭、脏盘子。
- 战斧牛排、涮牛肉、大骨头及其部分状态变体。
- 重型味真族、普通 / 大型公牛、涮牛肉诱食陷阱、攻击命中特效。
- 墙体细节、导航边界表现、正式 HUD 和大部分状态图标。

## 实现结构

- `Scripts/prototype_0_1/core/prototype_art_catalog.gd`：集中管理 Prototype 图片键与纹理资源。
- `Scripts/prototype_0_1/core/placeholder_visual.gd`：在现有色块、名称和状态标签下增加可选 `Sprite2D`，自动适配原视觉边界。
- `Scripts/prototype_0_1/core/item_catalog.gd`：按 `ItemType` 返回素材键，不用显示名称判断物品。
- `Scripts/prototype_0_1/interaction/interactable.gd`：设施通过导出的 `prototype_art_key` 选择表现。
- `Scripts/prototype_0_1/navigation/kitchen_obstacle.gd`：有素材的设施根据实际图片显示范围校准实体碰撞，保留少量透明边缘缓冲。
- `Scripts/prototype_0_1/navigation/prototype_map_controller.gd`：同步调整世界空间地板到集中配置的地图边界。
- 玩家场景直接加载 `player_chef.png`；基础味真族脚本只为普通类型应用首批敌人图，避免重型敌人被错误套图。

## 运行验证

- Godot 4.6.2 完成资源导入和脚本解析。
- Prototype 0.1、0.2、0.2.1、0.3、0.3.1、0.3.2、0.4 七套自动化测试全部通过。
- 主场景无界面运行通过。
- 2026-07-22 在 Godot 编辑器中实际运行 `main.tscn`：玩家、主要厨房设施和盘子堆显示正常；点击开始营业并进入刷怪后，基础味真族素材显示正常。
- 收到首轮检查反馈后补接暖色地板，改为单次边框与拉伸中央地面；有 PNG 的对象不再绘制旧灰盒色块，设施碰撞与图片显示范围重新对齐。
- 新图片没有创建第二套碰撞系统；现有厨房障碍碰撞只按图片显示范围校准尺寸。交互范围、物品实例和状态保存没有改变。

## 已知问题与下一步

- 当前图片比例来自自动适配原灰盒边界；碰撞已按实际显示范围自动校准，仍需项目负责人人工试玩确认移动手感。
- 一些设施标题与状态文字会叠在图片下沿，这是为了保留 Debug 可读性；正式 UI 阶段需要重新排版。
- 暖色房间底图已作为 Prototype 地板接入；原图为方形，扩大地图中会拉伸中央地砖，正式地图仍应制作匹配目标比例的专用底图。
- 下一批素材优先补齐重型味真族、整块 / 切片 / 腌制牛肉、腌肉料、芥末、焦炭、脏盘子、战斧牛排、涮牛肉、攻击实体和陷阱。
