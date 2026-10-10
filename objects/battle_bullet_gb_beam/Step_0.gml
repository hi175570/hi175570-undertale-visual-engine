if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;
editor_gb_beam_age+=global.delta_time_factor;
if(editor_gb_beam_custom&&sprite_get_number(sprite_index)>1) image_index=floor(editor_gb_beam_age/max(1,editor_gb_beam_frame_interval)) mod sprite_get_number(sprite_index);

// Board-surface content has to draw before battle_board composites that surface.
// Outside beams stay above the soul; below-board beams remain presentation-only.
depth = out == 1 ? DEPTH_BATTLE.BEAM : DEPTH_BATTLE.BULLET;

if (out!=2&&instance_exists(battle_soul) && hurtable && !green_guard_blocked) {
    var beam_dx=dcos(image_angle);
    var beam_dy=-dsin(image_angle);
    var soul_dx=battle_soul.x-x;
    var soul_dy=battle_soul.y-y;
    var beam_along=soul_dx*beam_dx+soul_dy*beam_dy;
    var beam_perp=abs(soul_dx*(-beam_dy)+soul_dy*beam_dx);
    // The GB beam is a ray, not a finite stretched sprite. Its source may move
    // arbitrarily far backwards during a long firing time.
    if(beam_along>=0 && beam_perp<=hit_width*0.5+Battle_SoulHitboxHalfSize()) Battle_CallSoulEventBulletCollision();
}

if (out!=2&&place_meeting(x, y, battle_soul_yellow_bullet) && type == 4 && yellow_shootable) {
    var obj = instance_place(x, y, battle_soul_yellow_bullet);
    instance_destroy(obj);
    instance_destroy();
}
