if(purple_drop_active){
    var dt=global.delta_time_factor;
    purple_drop_age+=dt;
    purple_drop_x+=purple_drop_vx*dt;
    purple_drop_y+=purple_drop_vy*dt;
    purple_drop_vy+=purple_drop_gravity*dt;
    purple_drop_angle+=purple_drop_spin*dt;
    if(purple_drop_age>54) purple_drop_alpha=max(0,1-(purple_drop_age-54)/24);
    if(purple_drop_alpha<=0||purple_drop_y-purple_drop_height*0.5>500) purple_drop_active=false;
}

if(heal_tween_active){
    // The game state is committed immediately; only the HUD is interpolated.
    // If another gameplay operation changes either endpoint while this visual
    // tween is running, stop displaying stale values at once.
    if(Player_GetHp()!=heal_tween_target_hp||Player_GetPurpleOccupancy()!=heal_tween_target_purple){
        heal_tween_active=false;
    }else{
        heal_tween_age+=global.delta_time_factor;
        if(heal_tween_age>=heal_tween_duration) heal_tween_active=false;
    }
}
