# 物品美术覆盖报告

## 2026-07-30 新增覆盖
- 新增目录：`GodotProject/Assets/Items/ItemArtBatch2026_07_30/assets/ready/`。
- 新增 36 张料理图标，精确覆盖缺失料理第 2～7 组的未摆盘/摆盘显示。
- 当前测试目录覆盖 114 种 ItemType；合法摆盘料理继续生成真实完美品质样本。
- 战斗表现另见 `GodotProject/Assets/Combat/DishEffects2026_07_30/`；远程敌人动画另见 `GodotProject/Assets/Characters/Enemies/RangedTasteEnemy01/`。
- 负责人已完成普通窗口视觉确认。本批素材可作为当前内部测试版基线，仍允许后续统一调色和精修。

更新时间：2026-07-29  
权威素材基线：`Who_Is_The_Beast_Chef_Item_Art_Pack_2026-07-29_v3.zip`  
权威修正覆盖：`Who_Is_The_Beast_Chef_Item_Art_Correction_2026-07-29_v4.zip`  
工程资源根目录：`GodotProject/Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/` 与 `GodotProject/Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/`

## 结论

- 当前工程共有 68 个 `ItemData.ItemType`。
- V3 提供完整基线，V4 以 8 张 `ready` PNG 定向覆盖普通/完美战斧、小炒黄牛肉、青菜炒牛肉和青菜牛肉汤。
- 当前 68 个 ItemType 均能解析到已确认图片；不再有使用集中式纯色占位图的现行 ItemType。
- 普通与非完美盘装战斧使用 V4 普通图，完美盘装战斧使用 V4 透明 `64×96` 图；仓储仍保持 `2／2／1` 五格遮罩。
- 4 个 ItemType 继续使用包外已有 Prototype 素材：食用油、炒锅、煎锅、汤锅。生牛肉片与涮牛肉最后一片继续使用既有单片动态图。
- V3 的 60 张 `assets/ready/**` 原始 PNG 已全部保存在工程中；没有复制 `sources_48px` 或灰底 `needs_processing` 母图。
- V4 的 8 张 `assets/ready/**` PNG 已全部保存并接入；没有修改玩法、配方、战斗数值或异形占格。

## 当前 ItemType 逐项覆盖

| 当前 ItemType | 中文名称 | 使用 PNG / 美术来源 | 状态 |
|---|---|---|---|
| `RAW_BEEF_CHUNK` | 整块生牛肉 | `ingredients/ingredient_raw_beef_chunk_3x3.png` | 已接入 V3 |
| `RAW_STEAK` | 生牛排 | `ingredients/ingredient_raw_steak_3x1.png` | 已接入 V3 |
| `RAW_BEEF_SLICES` | 生牛肉片组 | `ingredients/ingredient_raw_beef_slices_1x1.png`；最后一片保留 `Assets/Prototype/Static/raw_beef_slice_single.png` | 已接入 V3，保留动态单片切换 |
| `MARINATED_BEEF_SLICES` | 腌牛肉片组 | `ingredients/ingredient_marinated_beef_slices_1x1.png` | 已接入 V3 |
| `MARINADE` | 腌肉料 | `ingredients/ingredient_marinade_seasoning.png` | 已接入 V3 |
| `CHILI_SEGMENTS` | 辣椒段 | `ingredients/ingredient_chili_segments.png` | 已接入 V3 |
| `COOKING_OIL` | 食用油 | `Assets/Prototype/Static/cooking_oil_bottle.png` | V3 无替代图，沿用已有有效素材 |
| `UNPLATED_STIR_FRY_BEEF` | 待摆盘小炒黄牛肉 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_stir_fry_beef_unplated.png` | 已接入 V4 |
| `CHARCOAL` | 焦炭 | `ingredients/ingredient_charcoal.png` | 已接入 V3 |
| `WOK` | 炒锅 | `Assets/Prototype/Static/wok.png` | V3 无替代图，沿用已有有效素材 |
| `CLEAN_PLATE` | 干净盘子 | `containers/container_clean_plate.png` | 已接入 V3 |
| `DIRTY_PLATE` | 脏盘子 | `containers/container_dirty_plate.png` | 已接入 V3 |
| `PLATED_STIR_FRY_BEEF` | 已摆盘小炒黄牛肉 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_stir_fry_beef_plated.png` | 已接入 V4 |
| `SALT` | 盐 | `ingredients/ingredient_salt_shaker.png` | 已接入 V3 |
| `MUSTARD` | 芥末 | `ingredients/ingredient_mustard_sauce.png` | 已接入 V3 |
| `PAN` | 煎锅 | `Assets/Prototype/Static/frying_pan.png` | V3 无替代图，沿用已有有效素材 |
| `SOUP_POT` | 汤锅 | `Assets/Prototype/Static/soup_pot.png` | V3 无替代图，沿用已有有效素材 |
| `TOMAHAWK_STEAK` | 未摆盘战斧牛排 | `ItemArtCorrection2026_07_29_v4/assets/ready/weapon_tomahawk_steak_normal.png` | 已接入 V4 |
| `PLATED_TOMAHAWK_STEAK` | 盘装战斧牛排 | 非完美：V4 `weapon_tomahawk_steak_normal.png`；完美：V4 `weapon_tomahawk_steak_perfect.png` | 已接入 V4 + 品质动态切换 |
| `BIG_BONE` | 大骨头 | `weapons/weapon_big_bone.png` | 已接入 V3 |
| `SHABU_BEEF` | 涮牛肉 | 成组：`ingredients/ingredient_shabu_beef_slices.png`；最后一片：`Assets/Prototype/Static/shabu_beef_single.png` | 已接入 V3，保留动态单片切换 |
| `MUSHY_BOILED_BEEF` | 煮烂牛肉 | `ingredients/failed_mushy_boiled_beef.png` | 已接入 V3 |
| `RICE_BAG` | 米袋 | `ingredients/resource_rice_bag_large_starting.png` | 已接入 V3 |
| `SMALL_RICE_BAG` | 敌人掉落小米袋 | `ingredients/resource_rice_bag_small_enemy_drop.png` | 已接入 V3；独立 2 份实例 |
| `RAW_RICE` | 生米 | `ingredients/ingredient_uncooked_rice.png` | 已接入 V3 |
| `UNPLATED_WHITE_RICE` | 待摆盘白米饭 | `dishes/dish_plain_white_rice_unplated.png` | 已接入 V3 |
| `PLATED_WHITE_RICE` | 盘装白米饭 | `dishes/dish_plain_white_rice_plated.png` | 已接入 V3 |
| `UNPLATED_RICE_PORRIDGE` | 待摆盘白粥 | `dishes/dish_plain_congee_unplated.png` | 已接入 V3 |
| `PLATED_RICE_PORRIDGE` | 盘装白粥 | `dishes/dish_plain_congee_plated.png` | 已接入 V3 |
| `UNPLATED_CRISPY_RICE` | 待摆盘锅巴 | `dishes/dish_rice_crust_unplated.png` | 已接入 V3 |
| `PLATED_CRISPY_RICE` | 盘装锅巴 | `dishes/dish_rice_crust_plated.png` | 已接入 V3 |
| `WHOLE_GREENS` | 整颗青菜 | `ingredients/ingredient_whole_greens.png` | 已接入 V3 |
| `GREENS_LEAF` | 青菜叶 | `ingredients/ingredient_greens_leaf.png` | 已接入 V3 |
| `RAW_BEEF_DICE` | 生牛肉丁组 | `ingredients/ingredient_raw_beef_cubes.png` | 已接入 V3 |
| `MARINATED_BEEF_DICE` | 腌牛肉丁组 | `ingredients/ingredient_marinated_beef_cubes.png` | 已接入 V3 |
| `UNPLATED_BOILED_GREENS` | 待摆盘盐水青菜 | `dishes/dish_salt_water_greens_unplated.png` | 已接入 V3 |
| `PLATED_BOILED_GREENS` | 盘装盐水青菜 | `dishes/dish_salt_water_greens_plated.png` | 已接入 V3 |
| `UNPLATED_STIR_FRY_GREENS` | 待摆盘清炒青菜 | `dishes/dish_clear_stir_fried_greens_unplated.png` | 已接入 V3 |
| `PLATED_STIR_FRY_GREENS` | 盘装清炒青菜 | `dishes/dish_clear_stir_fried_greens_plated.png` | 已接入 V3 |
| `UNPLATED_SPICY_STIR_FRY_GREENS` | 待摆盘辣味清炒青菜 | `dishes/dish_spicy_stir_fried_greens_unplated.png` | 已接入 V3 |
| `PLATED_SPICY_STIR_FRY_GREENS` | 盘装辣味清炒青菜 | `dishes/dish_spicy_stir_fried_greens_plated.png` | 已接入 V3 |
| `UNPLATED_FLASH_STIR_FRY_GREENS` | 待摆盘炝炒青菜 | `dishes/dish_flash_stir_fried_greens_unplated.png` | 已接入 V3 |
| `PLATED_FLASH_STIR_FRY_GREENS` | 盘装炝炒青菜 | `dishes/dish_flash_stir_fried_greens_plated.png` | 已接入 V3 |
| `UNPLATED_GREENS_PORRIDGE` | 待摆盘青菜粥 | `dishes/dish_greens_congee_unplated.png` | 已接入 V3 |
| `PLATED_GREENS_PORRIDGE` | 盘装青菜粥 | `dishes/dish_greens_congee_plated.png` | 已接入 V3 |
| `UNPLATED_BEEF_PORRIDGE` | 待摆盘生滚牛肉粥 | `dishes/dish_beef_congee_unplated.png` | 已接入 V3 |
| `PLATED_BEEF_PORRIDGE` | 盘装生滚牛肉粥 | `dishes/dish_beef_congee_plated.png` | 已接入 V3 |
| `UNPLATED_PLAIN_BEEF_PORRIDGE` | 待摆盘普通牛肉粥 | `dishes/dish_unseasoned_beef_congee_unplated.png` | 已接入 V3 |
| `PLATED_PLAIN_BEEF_PORRIDGE` | 盘装普通牛肉粥 | `dishes/dish_unseasoned_beef_congee_plated.png` | 已接入 V3 |
| `UNPLATED_BEEF_GREENS` | 待摆盘青菜炒牛肉 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_stir_fry_unplated.png` | 已接入 V4 |
| `PLATED_BEEF_GREENS` | 盘装青菜炒牛肉 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_stir_fry_plated.png` | 已接入 V4 |
| `UNPLATED_GREENS_FRIED_RICE` | 待摆盘青菜炒饭 | `dishes/dish_greens_fried_rice_unplated.png` | 已接入 V3 |
| `PLATED_GREENS_FRIED_RICE` | 盘装青菜炒饭 | `dishes/dish_greens_fried_rice_plated.png` | 已接入 V3 |
| `UNPLATED_BEEF_FRIED_RICE` | 待摆盘牛肉炒饭 | `dishes/dish_beef_fried_rice_unplated.png` | 已接入 V3 |
| `PLATED_BEEF_FRIED_RICE` | 盘装牛肉炒饭 | `dishes/dish_beef_fried_rice_plated.png` | 已接入 V3 |
| `UNPLATED_MIXED_FRIED_RICE` | 待摆盘青菜牛肉炒饭 | `dishes/dish_greens_beef_fried_rice_unplated.png` | 已接入 V3 |
| `PLATED_MIXED_FRIED_RICE` | 盘装青菜牛肉炒饭 | `dishes/dish_greens_beef_fried_rice_plated.png` | 已接入 V3 |
| `UNPLATED_VEGETABLE_RICE` | 待摆盘菜饭 | `dishes/dish_vegetable_rice_unplated.png` | 已接入 V3 |
| `PLATED_VEGETABLE_RICE` | 盘装菜饭 | `dishes/dish_vegetable_rice_plated.png` | 已接入 V3 |
| `UNPLATED_SOAKED_RICE` | 待摆盘泡饭 | `dishes/dish_plain_soaked_rice_unplated.png` | 已接入 V3 |
| `PLATED_SOAKED_RICE` | 盘装泡饭 | `dishes/dish_plain_soaked_rice_plated.png` | 已接入 V3 |
| `UNPLATED_GREENS_SOAKED_RICE` | 待摆盘菜泡饭 | `dishes/dish_greens_soaked_rice_unplated.png` | 已接入 V3 |
| `PLATED_GREENS_SOAKED_RICE` | 盘装菜泡饭 | `dishes/dish_greens_soaked_rice_plated.png` | 已接入 V3 |
| `PLATED_BEEF_GREENS_RICE_BOWL` | 青菜牛肉盖饭炮台 | `dishes/dish_beef_greens_rice_bowl_plated.png` | 已接入 V3 |
| `UNPLATED_BEEF_GREENS_SOUP` | 待摆盘青菜牛肉汤 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_soup_unplated.png` | 已接入 V4 |
| `PLATED_BEEF_GREENS_SOUP` | 盘装青菜牛肉汤 | `ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_soup_plated.png` | 已接入 V4 |
| `UNPLATED_MUSTARD_GREENS` | 芥末青菜 | `dishes/dish_mustard_greens_unplated_selected_candidate42.png` | 已接入 V3 候选 42 |
| `PLATED_MUSTARD_GREENS` | 盘装芥末青菜 | `dishes/dish_mustard_greens_plated_selected_candidate64.png` | 已接入 V3 候选 64 |

## 已保存但当前不注册为 ItemType

| V3 ready PNG | 原因 |
|---|---|
| `containers/container_metal_prep_bowl.png` | 容器母版，不是独立 ItemType。 |
| `containers/container_porcelain_deep_bowl.png` | 容器母版，不是独立 ItemType。 |
| `containers/container_porcelain_shallow_bowl.png` | 容器母版，不是独立 ItemType。 |

## 真正缺图清单

当前 68 个 ItemType 均已有可用映射，不再存在集中式纯色占位缺图。

下列项目仍沿用 V3 包外的既有 Prototype 素材，后续可按美术计划重绘：

- 食用油。
- 炒锅、煎锅、汤锅。
- 生牛肉片与涮牛肉最后一片仍使用既有单片图。

## 导入与显示规则

- 所有 V3 基线与 V4 修正 PNG 均由 `PrototypeArtCatalog` 集中注册，再由 `ItemCatalog.get_art_key_for_data()` 按物品实例状态选择。
- 世界掉落/手持 `CarryableItem`、五格快捷栏、异形背包与食材柜共同使用上述入口。
- 未摆盘与盘装料理分别映射；清炒、辣味清炒、炝炒分别映射。
- 完美战斧只在 `PLATED_TOMAHAWK_STEAK && quality == PERFECT` 时选择 V4 完美图；普通与非完美盘装战斧使用 V4 普通图。
- 像素纹理采用无损导入、关闭 mipmaps；世界物品、快捷栏、拖拽预览和背包/柜子网格均显式使用 Nearest。
- 禁止恢复 V1/V2、V3 错误战斧、旧小炒共享图、`sources_48px`、灰底 `needs_processing` 母图或未选中候选图。

## 验证记录

- V3 专项测试：7/7 组通过。
- V4 修正专项：5/5 组通过；0.6A 测试柜/库存回归：6/6 组通过。
- Prototype 全量回归：24/24 个测试脚本通过。
- Godot 4.6.2：资源扫描/脚本解析通过；主场景 Headless 180 帧自然启动通过。
- 普通 OpenGL 1280×720：已滚动检查 20×40 测试柜顶部、中部和第 40 行底部，并检查 V4 战斧、小炒黄牛肉、青菜炒牛肉和青菜牛肉汤；没有发现旧图、串图或纯色占位。
