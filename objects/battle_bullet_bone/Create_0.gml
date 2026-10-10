event_inherited();
length = 20;
type = 0;
out = 0;
rotate = 0;
point = 0;
// 0 = ordinary Bone, 1 = one normal tail plus the extracted spike head.
// It remains the same battle_bullet_bone object and therefore keeps every
// movement, damage, Control ID and follow capability of an ordinary Bone.
bone_style = 0;
if (point == 1) {
    sprite_index = spr_bone_1;
} else {
    sprite_index = spr_bone;
}
