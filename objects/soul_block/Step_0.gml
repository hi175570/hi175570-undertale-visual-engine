x=battle_soul.x;
y=battle_soul.y;

// Green-soul guard is a separate, free four-direction mechanic. Direction
// input changes its target immediately, while the visible shield performs a
// short smooth turn. It never uses the general-purpose C shield meter.
if(battle_soul.moveable){
    if(Input_IsHeld(INPUT.UP)){
        guard_target_angle=90;
    }else if(Input_IsHeld(INPUT.DOWN)){
        guard_target_angle=-90;
    }else if(Input_IsHeld(INPUT.LEFT)){
        guard_target_angle=180;
    }else if(Input_IsHeld(INPUT.RIGHT)){
        guard_target_angle=0;
    }
}

var guard_turn=angle_difference(guard_target_angle,image_angle);
if(abs(guard_turn)<0.5){
    image_angle=guard_target_angle;
}else{
    image_angle+=guard_turn*min(1,0.3*global.delta_time_factor);
}

var STATE=Battle_GetState();
if(STATE==BATTLE_STATE.TURN_PREPARATION || STATE==BATTLE_STATE.IN_TURN){
    visible=true;
}else{
    visible=false;
    image_angle=90;
    guard_target_angle=90;
}
