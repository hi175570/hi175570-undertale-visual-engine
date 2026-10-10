
image_xscale = (length + 10) / 14;
if (point == 1) {
    sprite_index = bone_style==1?spr_bone_spike_1:spr_bone_1;
    mask_index = spr_bone_1;
} else {
    sprite_index = bone_style==1?spr_bone_spike:spr_bone;
    mask_index = spr_bone;
}
event_inherited();

