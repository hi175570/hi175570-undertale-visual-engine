function Battle_MakeGB(x, y, x_target, y_target, angle_start, angle_target, scale_x, scale_y, type, pause=35, duration=50, time_move=45, green_guard_blockable=false, fake_mode=0, move_tween=ANIM_TWEEN.EXPO, move_ease=ANIM_EASE.OUT, layer_mode=1) {
    var bb = instance_create_depth(x, y, DEPTH_BATTLE.BULLET_OUTSIDE_HIGH, battle_bullet_gb);    
    bb.x_target = x_target;
    bb.y_target = y_target;
    bb.angle_start = angle_start;
    bb.angle_target = angle_target;
    bb.scale_x = scale_x;
    bb.scale_y = scale_y;
    bb.type = type;
    bb.time_release_delay = pause;
    bb.time_beam_end_delay = duration;
    bb.time_move = time_move;
    bb.green_guard_blockable=green_guard_blockable;
    bb.green_guard_destroy_on_block=false;
    bb.fake_mode=fake_mode;
    bb.move_tween=move_tween;
    bb.move_ease=move_ease;
    bb.out=layer_mode;
    return bb;
}

function Battle_SetAttackLayer(inst,layer_mode) {
    if(!instance_exists(inst)) return noone;
    inst.out=clamp(layer_mode,0,2);
    if(variable_instance_exists(inst,"_inst")&&instance_exists(inst._inst)) inst._inst.out=inst.out;
    return inst;
}

/// One post-release motion segment. Direction and body rotation are independent.
/// A negative speed naturally starts opposite the requested direction; a
/// positive acceleration can slow it, stop it, then reverse it.
/// curve_speed is retained only so old external calls still compile. The
/// original Scratch GB never bends direction continuously, so it is ignored.
function Battle_GBOffsetSegment(duration,direction,speed,acceleration=0,rotation_speed=0,curve_speed=0) {
    return {duration:max(1,duration),direction:direction,speed:speed,acceleration:acceleration,rotation_speed:rotation_speed,curve_speed:0};
}

function Battle_GBSetOffset(gb,direction,speed=0,acceleration=1,rotation_speed=0,curve_speed=0) {
    if(!instance_exists(gb)) return gb;
    gb.offset_path=[Battle_GBOffsetSegment(999999,direction,speed,acceleration,rotation_speed,curve_speed)];
    gb.offset_path_index=0;
    gb.offset_path_time=0;
    gb.offset_path_started=false;
    return gb;
}

/// Multi-stage counterpart. Each array item is made with Battle_GBOffsetSegment.
function Battle_GBSetOffsetPath(gb,segments) {
    if(!instance_exists(gb)) return gb;
    gb.offset_path=segments;
    gb.offset_path_index=0;
    gb.offset_path_time=0;
    gb.offset_path_started=false;
    return gb;
}
