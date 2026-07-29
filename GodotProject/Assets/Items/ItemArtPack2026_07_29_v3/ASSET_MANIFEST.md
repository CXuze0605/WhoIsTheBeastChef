# 素材清单 / Asset Manifest

共 67 个文件。eady 可直接进入接入检查；sources_48px 是母版；
eeds_processing 禁止直接导入游戏。

| 文件 | 中文名称 | 预期映射 | 状态 | 占格/用途 | 尺寸 | 备注 |
|---|---|---|---|---|---|---|
| `assets\ready\ingredients\ingredient_marinade_seasoning.png` | 腌肉料 | `ItemData.ItemType.MARINADE` | ready | use catalog | 32x32 | Dark soy-based marinade; replaces original batch candidate 01. |
| `assets\ready\ingredients\ingredient_chili_segments.png` | 辣椒段 | `ItemData.ItemType.CHILI_SEGMENTS` | ready | 1x1 | 32x32 | Original batch candidate 02. |
| `assets\ready\ingredients\ingredient_charcoal.png` | 焦炭 | `ItemData.ItemType.CHARCOAL` | ready | 1x1 | 32x32 | Original batch candidate 03. |
| `assets\ready\ingredients\ingredient_salt_shaker.png` | 盐 | `ItemData.ItemType.SALT` | ready | 1x1 | 32x32 | Original batch candidate 04. |
| `assets\ready\ingredients\ingredient_mustard_sauce.png` | 芥末 | `ItemData.ItemType.MUSTARD` | ready | 1x1 | 32x32 | Original batch candidate 05. |
| `assets\ready\ingredients\ingredient_shabu_beef_slices.png` | 涮牛肉片（成组） | `ItemData.ItemType.SHABU_BEEF / shabu_beef_slices` | ready | 1x1 | 32x32 | Full stack/portion art, not the single final slice. |
| `assets\ready\ingredients\failed_mushy_boiled_beef.png` | 煮烂牛肉 | `ItemData.ItemType.MUSHY_BOILED_BEEF` | ready | 1x1 | 32x32 | Failure dish art. |
| `assets\ready\ingredients\ingredient_uncooked_rice.png` | 生米 | `future item: UNCOOKED_RICE` | ready | 1x1 | 32x32 | Loose uncooked rice portion. |
| `assets\ready\ingredients\ingredient_greens_leaf.png` | 青菜叶 | `future item: GREENS_LEAF` | ready | 1x1 | 32x32 | One separated leaf. |
| `assets\ready\ingredients\ingredient_raw_beef_cubes.png` | 生牛肉块 | `future item: RAW_BEEF_CUBES` | ready | 1x1 | 32x32 | Small diced-beef portion. |
| `assets\ready\ingredients\ingredient_marinated_beef_cubes.png` | 腌牛肉块 | `future item: MARINATED_BEEF_CUBES` | ready | 1x1 | 32x32 | Darker soy-marinated diced beef. |
| `assets\ready\ingredients\ingredient_whole_greens.png` | 整颗青菜 | `future item: WHOLE_GREENS` | ready | use confirmed irregular mask | 32x32 | Breaks into five greens leaves through QTE. |
| `assets\ready\ingredients\resource_rice_bag_large_starting.png` | 开局大米袋 | `future item: RICE_BAG_LARGE_STARTING` | ready | 3x4 | 32x32 | Starting resource package; contains more uncooked rice. |
| `assets\ready\ingredients\resource_rice_bag_small_enemy_drop.png` | 怪物掉落小米袋 | `future item: RICE_BAG_SMALL_DROP` | ready | smaller than 3x4; use design/catalog decision | 32x32 | Enemy drop; contains less uncooked rice. |
| `assets\ready\ingredients\ingredient_raw_beef_chunk_3x3.png` | 整块生牛肉 | `ItemData.ItemType.RAW_BEEF_CHUNK` | prototype_ready | 3x3 | 96x96 | Confirmed temporary version. |
| `assets\ready\ingredients\ingredient_raw_steak_3x1.png` | 生牛排 | `ItemData.ItemType.RAW_STEAK` | prototype_ready | 3x1; rotate to 1x3 with item rotation | 96x32 | Confirmed horizontal version. |
| `assets\ready\ingredients\ingredient_raw_beef_slices_1x1.png` | 生牛肉片（五份一组） | `ItemData.ItemType.RAW_BEEF_SLICES` | ready | 1x1 | 32x32 | Grouped portion art. |
| `assets\ready\ingredients\ingredient_marinated_beef_slices_1x1.png` | 腌牛肉片（五份一组） | `ItemData.ItemType.MARINATED_BEEF_SLICES` | ready | 1x1 | 32x32 | Grouped marinated portion art. |
| `assets\ready\dishes\dish_plain_white_rice_unplated.png` | 白米饭（未装盘） | `future item: WHITE_RICE_UNPLATED` | ready | 1x1 | 32x32 | Temporary metal container. |
| `assets\ready\dishes\dish_plain_white_rice_plated.png` | 白米饭（已装盘） | `future item: WHITE_RICE_PLATED` | ready | 1x1 | 32x32 | Refined blue-and-white porcelain. |
| `assets\ready\dishes\dish_rice_crust_unplated.png` | 锅巴（未装盘） | `future item: RICE_CRUST_UNPLATED` | ready | 1x1 | 32x32 | Temporary metal container. |
| `assets\ready\dishes\dish_rice_crust_plated.png` | 锅巴（已装盘） | `future item: RICE_CRUST_PLATED` | ready | 1x1 | 32x32 | Refined blue-and-white porcelain. |
| `assets\ready\dishes\dish_salt_water_greens_unplated.png` | 盐水青菜（未装盘） | `future item: SALT_WATER_GREENS_UNPLATED` | ready | 1x1 | 32x32 | No chili. |
| `assets\ready\dishes\dish_salt_water_greens_plated.png` | 盐水青菜（已装盘） | `future item: SALT_WATER_GREENS_PLATED` | ready | 1x1 | 32x32 | No chili. |
| `assets\ready\dishes\dish_clear_stir_fried_greens_unplated.png` | 清炒青菜（未装盘） | `future item: CLEAR_STIR_FRIED_GREENS_UNPLATED` | ready | 1x1 | 32x32 | Normal version; no chili. |
| `assets\ready\dishes\dish_clear_stir_fried_greens_plated.png` | 清炒青菜（已装盘） | `future item: CLEAR_STIR_FRIED_GREENS_PLATED` | ready | 1x1 | 32x32 | Normal version; no chili. |
| `assets\ready\dishes\dish_spicy_stir_fried_greens_unplated.png` | 辣味清炒青菜（未装盘） | `future item: SPICY_STIR_FRIED_GREENS_UNPLATED` | ready | 1x1 | 32x32 | Visible chili and restrained red oil. |
| `assets\ready\dishes\dish_spicy_stir_fried_greens_plated.png` | 辣味清炒青菜（已装盘） | `future item: SPICY_STIR_FRIED_GREENS_PLATED` | ready | 1x1 | 32x32 | Visible chili and restrained red oil. |
| `assets\ready\dishes\dish_flash_stir_fried_greens_unplated.png` | 炝炒青菜（未装盘） | `future item: FLASH_STIR_FRIED_GREENS_UNPLATED` | ready | 1x1 | 32x32 | Dry chili, garlic and wok-char. |
| `assets\ready\dishes\dish_flash_stir_fried_greens_plated.png` | 炝炒青菜（已装盘） | `future item: FLASH_STIR_FRIED_GREENS_PLATED` | ready | 1x1 | 32x32 | Dry chili, garlic and wok-char. |
| `assets\ready\dishes\dish_greens_congee_unplated.png` | 青菜粥（未装盘） | `future item: GREENS_CONGEE_UNPLATED` | ready | 1x1 | 32x32 | Accepted practical metal bowl version. |
| `assets\ready\dishes\dish_greens_congee_plated.png` | 青菜粥（已装盘） | `future item: GREENS_CONGEE_PLATED` | ready | 1x1 | 32x32 | Regenerated refined porcelain version. |
| `assets\ready\dishes\dish_beef_congee_unplated.png` | 生滚牛肉粥（未装盘） | `future item: BEEF_CONGEE_UNPLATED` | ready | 1x1 | 32x32 | Marinated beef version. |
| `assets\ready\dishes\dish_beef_congee_plated.png` | 生滚牛肉粥（已装盘） | `future item: BEEF_CONGEE_PLATED` | ready | 1x1 | 32x32 | Marinated beef version. |
| `assets\ready\dishes\dish_unseasoned_beef_congee_unplated.png` | 普通牛肉粥（未腌牛肉，未装盘） | `future item: UNSEASONED_BEEF_CONGEE_UNPLATED` | ready | 1x1 | 32x32 | Cannot reach perfect quality by current design. |
| `assets\ready\dishes\dish_unseasoned_beef_congee_plated.png` | 普通牛肉粥（未腌牛肉，已装盘） | `future item: UNSEASONED_BEEF_CONGEE_PLATED` | ready | 1x1 | 32x32 | Cannot reach perfect quality by current design. |
| `assets\ready\dishes\dish_greens_fried_rice_unplated.png` | 青菜炒饭（未装盘） | `future item: GREENS_FRIED_RICE_UNPLATED` | ready | 1x1 | 32x32 | Low damage design. |
| `assets\ready\dishes\dish_greens_fried_rice_plated.png` | 青菜炒饭（已装盘） | `future item: GREENS_FRIED_RICE_PLATED` | ready | 1x1 | 32x32 | Low damage design. |
| `assets\ready\dishes\dish_beef_fried_rice_unplated.png` | 牛肉炒饭（未装盘） | `future item: BEEF_FRIED_RICE_UNPLATED` | ready | 1x1 | 32x32 | High single-target thrown weapon. |
| `assets\ready\dishes\dish_beef_fried_rice_plated.png` | 牛肉炒饭（已装盘） | `future item: BEEF_FRIED_RICE_PLATED` | ready | 1x1 | 32x32 | High single-target thrown weapon. |
| `assets\ready\dishes\dish_vegetable_rice_unplated.png` | 菜饭（未装盘） | `future item: VEGETABLE_RICE_UNPLATED` | ready | 1x1 | 32x32 | Not fried rice. |
| `assets\ready\dishes\dish_vegetable_rice_plated.png` | 菜饭（已装盘） | `future item: VEGETABLE_RICE_PLATED` | ready | 1x1 | 32x32 | Not fried rice. |
| `assets\ready\dishes\dish_plain_soaked_rice_unplated.png` | 泡饭（未装盘） | `future item: PLAIN_SOAKED_RICE_UNPLATED` | ready | 1x1 | 32x32 | Clear broth must remain readable. |
| `assets\ready\dishes\dish_plain_soaked_rice_plated.png` | 泡饭（已装盘） | `future item: PLAIN_SOAKED_RICE_PLATED` | ready | 1x1 | 32x32 | Clear broth must remain readable. |
| `assets\ready\dishes\dish_greens_soaked_rice_unplated.png` | 菜泡饭（未装盘） | `future item: GREENS_SOAKED_RICE_UNPLATED` | ready | 1x1 | 32x32 | Greens count affects weakness, up to five leaves. |
| `assets\ready\dishes\dish_greens_soaked_rice_plated.png` | 菜泡饭（已装盘） | `future item: GREENS_SOAKED_RICE_PLATED` | ready | 1x1 | 32x32 | Greens count affects weakness, up to five leaves. |
| `assets\ready\dishes\dish_beef_greens_rice_bowl_plated.png` | 青菜牛肉盖饭（已装盘） | `future item: BEEF_GREENS_RICE_BOWL_PLATED` | ready | 1x1 | 32x32 | Turret dish design. |
| `assets\ready\dishes\dish_mustard_greens_unplated_selected_candidate42.png` | 芥末青菜（未装盘选定图） | `future item: MUSTARD_GREENS_UNPLATED` | selected | 1x1 | 32x32 | User explicitly selected original candidate 42; weird dish, no perfect quality. |
| `assets\ready\dishes\dish_mustard_greens_plated_selected_candidate64.png` | 芥末青菜（已装盘选定图） | `future item: MUSTARD_GREENS_PLATED` | selected | 1x1 | 32x32 | User explicitly selected original candidate 64; weird dish, no perfect quality. |
| `assets\ready\dishes\dish_plain_congee_unplated.png` | 白粥（未装盘） | `future item: PLAIN_CONGEE_UNPLATED` | ready | 1x1 | 32x32 | Ordinary temporary container. |
| `assets\ready\dishes\dish_plain_congee_plated.png` | 白粥（已装盘） | `future item: PLAIN_CONGEE_PLATED` | ready | 1x1 | 32x32 | Blue-and-white porcelain final 32px export. |
| `assets\ready\dishes\dish_greens_beef_fried_rice_unplated.png` | 青菜牛肉炒饭（未装盘） | `future item: GREENS_BEEF_FRIED_RICE_UNPLATED` | ready | 1x1 | 32x32 | Normal version must not read as spicy. |
| `assets\ready\dishes\dish_greens_beef_fried_rice_plated.png` | 青菜牛肉炒饭（已装盘） | `future item: GREENS_BEEF_FRIED_RICE_PLATED` | ready | 1x1 | 32x32 | Normal version must not read as spicy. |
| `assets\ready\containers\container_metal_prep_bowl.png` | 临时金属备料盆 | `container master: unplated dishes` | ready | 1x1 | 32x32 | Empty 32px container master. |
| `assets\ready\containers\container_porcelain_deep_bowl.png` | 青花瓷深碗 | `container master: congee/soup/soaked rice` | ready | 1x1 | 32x32 | Empty 32px container master. |
| `assets\ready\containers\container_porcelain_shallow_bowl.png` | 青花瓷浅碗 | `container master: fried rice/rice bowl/stir-fry` | ready | 1x1 | 32x32 | Empty 32px container master. |
| `assets\ready\containers\container_clean_plate.png` | 干净青花瓷盘 | `ItemData.ItemType.CLEAN_PLATE` | ready | 1x1/stack | 32x32 | Use for clean plate inventory art. |
| `assets\ready\containers\container_dirty_plate.png` | 脏青花瓷盘 | `ItemData.ItemType.DIRTY_PLATE` | ready | 1x1/stack | 32x32 | Distinct readable meal residue. |
| `assets\ready\weapons\weapon_tomahawk_steak_normal.png` | 普通战斧牛排 | `ItemData.ItemType.TOMAHAWK_STEAK and non-perfect plated variants` | ready | 2,2,1 mask | 64x96 | Keep the original accepted sprite. |
| `assets\ready\weapons\weapon_big_bone.png` | 大骨头 | `ItemData.ItemType.BIG_BONE` | ready | 1x3 | 32x96 | Keep the previously accepted sprite unchanged. |
| `assets\needs_processing\weapon_tomahawk_steak_perfect_SOURCE_NEEDS_BG_REMOVAL.png` | 完美战斧牛排母图 | `ItemData.ItemType.PLATED_TOMAHAWK_STEAK when quality == PERFECT` | needs_processing | target 2,2,1 mask | 1024x1536 | Do not import directly: remove gray background, crop/recompose, and export final transparent 64x96 pixel sprite first. |
| `assets\sources_48px\source48_plain_congee_plated.png` | 盘装白粥48px母版 | `source only` | source | 48x48 | 48x48 | Keep for future revisions; game-ready 32px export is in ready/dishes. |
| `assets\sources_48px\source48_container_metal_prep_bowl.png` | 金属备料盆48px母版 | `source only` | source | 48x48 | 48x48 | Do not map in catalog when 32px export is used. |
| `assets\sources_48px\source48_container_porcelain_deep_bowl.png` | 青花瓷深碗48px母版 | `source only` | source | 48x48 | 48x48 | Do not map in catalog when 32px export is used. |
| `assets\sources_48px\source48_container_porcelain_shallow_bowl.png` | 青花瓷浅碗48px母版 | `source only` | source | 48x48 | 48x48 | Do not map in catalog when 32px export is used. |
| `assets\sources_48px\source48_container_clean_plate.png` | 干净青花瓷盘48px母版 | `source only` | source | 48x48 | 48x48 | Do not map in catalog when 32px export is used. |
| `assets\sources_48px\source48_container_dirty_plate.png` | 脏青花瓷盘48px母版 | `source only` | source | 48x48 | 48x48 | Do not map in catalog when 32px export is used. |
