depth = DEPTH_BATTLE.BULLET;
angle = 0;
follow = 0;
_y = y;
_x = x;
duration = -1;
auto_destroy = 0;
out = 0;
_vspeed = vspeed;
_hspeed = hspeed;
_speed = speed;
_direction = direction;
type = 0;
heal_amount = 10;
// Editor Visual Tint is independent from Damage Profile.  When enabled, the
// base Draw event must not overwrite image_blend from the damage type.
editor_visual_override = false;
editor_visual_color = c_white;
// Optional artwork-facing correction. Attack angles remain semantic world
// directions; only the sprite is rotated by this offset.
editor_sprite_angle_offset = 0;
// Ordinary engine attacks keep the original KR damage formula. Editor-created
// attacks opt into an explicit damage packet so the visible Damage field is a
// real runtime value instead of dead project data.
editor_damage_enabled = false;
hp_damage = 1;
kr_damage = 0;
disposable = 0;
follow_board = 0;
follow_angle = 0;
follow_x = 0;
follow_y = 0;
follow_target = noone;
center_x = 0;
center_y = 0;
rotate = 0;
_angle = 0;
point_at = 0;
angle_offset = 180;
// Editor-authored pointing is UID based. It deliberately does not reuse the
// legacy point/point_at pair: point was the removed board-edge shortcut and
// point_at only faced the instance's previous movement direction.
editor_aim_enabled = false;
editor_aim_target_uid = -1;
editor_aim_continuous = true;
editor_aim_move_enabled = false;
editor_aim_move_speed = 0;
editor_aim_controller = noone;
editor_aim_applied = false;
editor_aim_angle = 0;
processed = 0;
path_function = noone;
// Optional green-soul guard interaction. Ordinary attacks keep their original
// behaviour unless their creator explicitly enables this flag.
green_guard_blockable = false;
green_guard_destroy_on_block = true;
green_guard_blocked = false;
green_guard_block_distance = 0;
// Yellow is a visual colour; shootability and high-damage behaviour are
// independent so one colour no longer silently means two mechanics.
yellow_shootable = true;
yellow_heavy = false;
yellow_hp_damage = 5;
yellow_kr_damage = 3;
