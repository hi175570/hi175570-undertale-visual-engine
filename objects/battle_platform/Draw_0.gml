sprite_index = (sticky ? spr_battle_platform_green: spr_battle_platform_purple);
// Both platform sprites have Nine Slice enabled with one-pixel end caps.
// draw_self -> draw_sprite_ext honours that metadata, so width extends the
// centre strip instead of deforming the caps like an ordinary stretched image.
image_xscale = max(4,width) / sprite_get_width(sprite_index);
event_inherited();

