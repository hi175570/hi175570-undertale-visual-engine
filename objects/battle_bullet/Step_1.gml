if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

if (!processed) {
    alarm[0] = duration/global.delta_time_factor;
    if (follow) {
        direction = 0;
        speed = 0;
        vspeed = 0;
        hspeed = 0;
        if (follow_board) {
            follow_target = battle_board;
        }
        if (is_struct(follow_target)||instance_exists(follow_target)) {
            center_x = follow_target.x;
            center_y = follow_target.y;
            follow_x = follow_target.x;
            follow_y = follow_target.y;
            if (is_struct(follow_target)||variable_instance_exists(follow_target, "angle")) follow_angle = follow_target.angle;
            else follow_angle = follow_target.image_angle;

        } else {
            center_x = follow_x;
            center_y = follow_y;
        }
        processed = 1;
    }
}
if (follow) {
    _x += _hspeed * global.delta_time_factor;
    _y += _vspeed * global.delta_time_factor;
    if (_speed) {
        x += lengthdir_x(_speed * global.delta_time_factor, _direction);
        y += lengthdir_y(_speed * global.delta_time_factor, _direction);
    }
    if (follow_board && follow_target != battle_board) {
        follow_target = battle_board;
    }
    if (is_struct(follow_target)||instance_exists(follow_target)) {
        follow_x = follow_target.x;
        follow_y = follow_target.y;
        if (is_struct(follow_target)||variable_instance_exists(follow_target, "angle")) follow_angle = follow_target.angle;
        else follow_angle = follow_target.image_angle;
    }

    var pos = RotateAround(center_x, center_y, _x, _y, follow_x, follow_y, follow_angle);
    x = pos[0];
    y = pos[1];

} else {
    _x = x;
    _y = y;
    _vspeed = vspeed;
    _hspeed = hspeed;
    _speed = speed;
    _direction = direction;
}

// Persistent editor pointing resolves a stable UID every frame. A one-shot
// aim resolves only once; optional pursuit uses world-space speed while still
// preserving a followed bone's local coordinates relative to its board.
if(editor_aim_enabled&&instance_exists(editor_aim_controller)){
    var aim_target=BattleEditor_RuntimePointTarget(editor_aim_controller,editor_aim_target_uid);
    if(aim_target[0]&&(editor_aim_continuous||!editor_aim_applied)){
        editor_aim_angle=point_direction(x,y,aim_target[1],aim_target[2]);
        if(follow) _angle=editor_aim_angle-follow_angle;
        else angle=editor_aim_angle;
        editor_aim_applied=true;
    }
    if(editor_aim_applied&&editor_aim_move_enabled&&editor_aim_move_speed!=0){
        // One-shot aim must keep the captured direction and pass the sampled
        // point. Only the explicitly continuous mode recomputes a homing path.
        var move_angle=editor_aim_continuous&&aim_target[0]?point_direction(x,y,aim_target[1],aim_target[2]):editor_aim_angle;
        var move_distance=abs(editor_aim_move_speed)*global.delta_time_factor;
        if(editor_aim_continuous&&editor_aim_move_speed>0&&aim_target[0]) move_distance=min(move_distance,point_distance(x,y,aim_target[1],aim_target[2]));
        if(editor_aim_move_speed<0) move_angle+=180;
        var aim_dx=lengthdir_x(move_distance,move_angle);
        var aim_dy=lengthdir_y(move_distance,move_angle);
        if(follow){
            var local_delta=RotateAround(0,0,aim_dx,aim_dy,0,0,-follow_angle);
            _x+=local_delta[0];
            _y+=local_delta[1];
        }
        x+=aim_dx;
        y+=aim_dy;
    }
}
