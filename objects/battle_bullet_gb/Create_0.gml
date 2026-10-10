event_inherited();
depth = DEPTH_BATTLE.BEAM;
image_speed = 0;
type = 0;
heal_amount = 10;
x_target = x;
y_target = y;
angle_start = 0;
angle_target = 0;
scale_x = 2;
scale_y = 2;
time_move = round(45 * global.delta_time_factor);
move_tween = ANIM_TWEEN.EXPO;
move_ease = ANIM_EASE.OUT;
time_release_delay = round(35 * global.delta_time_factor);
time_release_stay = 0;
time_beam_end_delay = round(50 * global.delta_time_factor);
_beam_scale_default = 1.8;
// The rendered beam breathes between these two scales. Collision never uses
// the current rendered scale: it stays slightly inside the visual minimum.
// Scratch fast mode supplies the launch and sustained-width ratios. Keep those
// ratios, but preserve UTE's readable 0.25-radian-per-frame breathing cadence;
// treating each Scratch loop iteration as a rendered frame made it pulse over
// four times faster than the engine's established GB effect.
beam_visual_breath_amplitude = _beam_scale_default*0.32;
beam_visual_launch_scale = _beam_scale_default*0.20;
beam_hit_inset = 4;
_beam_scale = 0;
_beam_envelope = 0;
_beam_breath_offset = 0;
_beam_alpha = 1;
_beam_sin = 0;
_beam_closing = false;
_beam_close_complete = false;
_exit_speed = 0;
_fake_drop_vx = 0;
_fake_drop_vy = -3.5;
_fake_drop_gravity = 0.35;
_fake_drop_spin = 4;
fake_mode=0; // 0 real beam, 1 fake release animation, 2 struck and drops directly
editor_gb_force_release=false;
editor_gb_released=false;
editor_gb_opening=false;
editor_gb_open_elapsed=0;
// Custom named GB groups replace only this instance's head sprite. The
// immutable original remains the default and therefore owns no dynamic sprite.
editor_gb_owned_sprite=false;
editor_gb_frame_interval=2;
editor_gb_beam_sprite=-1;
editor_gb_owned_beam_sprite=false;
editor_gb_beam_frame_interval=2;
editor_gb_beam_source_direction=0;
editor_gb_beam_source_offset=20;
editor_gb_beam_uses_own_color=false;
editor_gb_builtin_style=false;
offset_path=[];
offset_path_index=0;
offset_path_time=0;
offset_path_started=false;
offset_direction=0;
offset_speed=0;
offset_acceleration=0;
offset_rotation_speed=0;
offset_curve_speed=0;
out = 1;
_inst = noone;
auto_destroy = 0;
alarm[0] = 1;
