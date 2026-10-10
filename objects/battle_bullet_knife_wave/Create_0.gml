event_inherited();

// 0 = slower slash with warning, 1 = fast true-knife cut then wave.
wave_kind=0;
wave_state=0;
wave_time=0;
warning_time=48;
active_time=72;
fade_time=10;
// Long enough to cross any battle view, but not so enormous that Windows/GPU
// line clipping drops the primitive entirely.
wave_length=max(8192,point_distance(0,0,room_width,room_height)*12);
warning_length=wave_length;
warning_width=1.5;

visual_min_width=10;
visual_max_width=26;
hit_inset=1.5;
hit_width=max(1,visual_min_width-hit_inset);
breath_speed=18;
breath_phase=0;
wave_alpha=1;
wave_color=c_white;
slash_launch_frames=5;
slash_fade_frames=5;
true_knife_collision_end=0.60;

pre_direction=0;
pre_speed=0;
pre_acceleration=0;
pre_rotation_speed=0;
pre_curve_speed=0;
pre_rotation_mode=0;
pre_rotation_target=0;
pre_rotation_time=48;
pre_rotation_tween=ANIM_TWEEN.SINE;
pre_rotation_ease=ANIM_EASE.IN_OUT;
pre_angle_from=image_angle;
post_direction=0;
post_speed=0;
post_acceleration=0;
post_rotation_speed=0;
post_curve_speed=0;
post_rotation_mode=0;
post_rotation_target=0;
post_rotation_time=72;
post_rotation_tween=ANIM_TWEEN.SINE;
post_rotation_ease=ANIM_EASE.IN_OUT;
post_angle_from=image_angle;

hp_damage=1;
kr_damage=0;
invincibility_frames=30;
heal_amount=10;
instant_damage=false;
hit_cooldown=0;
knife_spawned=false;
fire_started=false;
warning_sound_played=false;
warning_sound=snd_slash_warning;
cut_sound=snd_true_knife_cut;
release_sound=snd_knife_wave_release;
// Knife/slash beams are screen-space attacks. The battle board never clips
// them; only the green directional guard may shorten the rendered ray.
out=1;
depth=DEPTH_BATTLE.WARNING;
green_guard_blockable=true;
green_guard_destroy_on_block=false;
auto_destroy=0;
