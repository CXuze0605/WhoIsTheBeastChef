# RangedTasteEnemy01

Source character ID: `89297624-dd7d-4fa9-8623-40ca56a1d022`

## Identity

Modern overeating livestreamer transformed into a ranged Weizhen enemy:
green headset microphone, orange backpack, exposed round belly, dark pants,
sneakers, and a red leftover-rice bucket held in the left hand.

## Directions

`south`, `south-east`, `east`, `north-east`, `north`, `north-west`, `west`,
`south-west`

No direction should be mirrored.

## Contents

- `rotations/<direction>.png`
  - One idle/reference frame per direction.
- `animations/Walking_8dir_v2/<direction>/frame_000.png..frame_008.png`
  - Nine frames per direction.
  - Loop from frame 1 through frame 8 if repeating frame 0 creates a visible
    hitch; frame 0 is the reference pose.
  - Suggested starting playback range: `8–10 FPS`, then tune in game.
- `animations/Retch_Volley_8dir/<direction>/frame_000.png..frame_010.png`
  - Eleven frames per direction.
  - Non-looping.
  - Split the visible phases across eating, retch wind-up, volley and recovery,
    but keep projectile timing controlled by the existing state machine.
- `animations/Death_8dir/<direction>/frame_000.png..frame_006.png`
  - Seven frames per direction.
  - Non-looping; hold the last frame until cleanup.

All source frames use the PixelLab `228x228` transparent canvas. Keep a shared
center/feet anchor per animation instead of trimming frames independently.
