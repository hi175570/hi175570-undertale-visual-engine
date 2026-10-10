if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

var dt=global.delta_time_factor;
wave_time+=dt;
hit_cooldown=max(0,hit_cooldown-dt);
// IN_BOARD attacks must render into Battle_GetBoardSurface() before the board
// composites that surface. Giving them the outside BEAM/WARNING depth draws
// too late in the frame, so the surface is cleared next Begin Draw and the
// entire warning/wave becomes invisible. Outside mechanics still sit above
// the soul; BELOW_BOARD remains presentation-only.
depth=out==2?DEPTH_BATTLE.BULLET:(out==0?DEPTH_BATTLE.BULLET:((wave_state==0&&wave_kind==0)?DEPTH_BATTLE.WARNING:DEPTH_BATTLE.BEAM));

if(wave_state==0){
    // Slash warnings may move and rotate. A true knife's pre-cut sprite is
    // deliberately fixed: all motion starts only after the cut has happened.
    if(wave_kind==0){
        if(!warning_sound_played){
            BattleEditor_RuntimePlaySound(warning_sound,0,false);
            warning_sound_played=true;
        }
        pre_direction+=pre_curve_speed*dt;
        x+=lengthdir_x(pre_speed*dt,pre_direction);
        y+=lengthdir_y(pre_speed*dt,pre_direction);
        pre_speed+=pre_acceleration*dt;
        if(pre_rotation_mode==1) image_angle+=pre_rotation_speed*dt;
        else if(pre_rotation_mode==2){
            var pre_rotation_progress=clamp(wave_time/max(1,pre_rotation_time),0,1);
            image_angle=pre_angle_from+(pre_rotation_target-pre_angle_from)*Anim_GetValue(pre_rotation_tween,pre_rotation_ease,pre_rotation_progress);
        }
    }else if(!knife_spawned){
        // The cut sprite and released wave share the authored centre exactly.
        // Clamping only the sprite into the board displaced it from its wave.
        var knife=instance_create_depth(x,y,DEPTH_BATTLE.BEAM,battle_menu_fight_anim_knife,{sound_override:cut_sound});
        if(variable_instance_exists(id,"_battle_editor_runtime_controller")&&instance_exists(_battle_editor_runtime_controller)) BattleEditor_RuntimeTrack(_battle_editor_runtime_controller,knife);
        // The source cut sprite is authored vertically; +90 aligns the visible
        // slash with the editor line and the released wave direction.
        knife.image_angle=image_angle+90;
        // This six-frame cut is only the True Knife's one-shot enlargement.
        // Play it faster than the ordinary menu attack so it hands off to the
        // released wave instead of lingering over the whole attack.
        knife.image_speed=2;
        knife.out=out;
        knife.depth=out==2?DEPTH_BATTLE.BULLET:DEPTH_BATTLE.BEAM;
        knife_spawned=true;
    }

    if(wave_time>=warning_time){
        wave_state=1;
        wave_time=0;
        wave_alpha=1;
        post_angle_from=image_angle;
        fire_started=true;
        BattleEditor_RuntimePlaySound(release_sound,0,false);
        Camera_Shake(wave_kind?4:2,wave_kind?4:2,1,1,1,1);
    }
}else if(wave_state==1){
    post_direction+=post_curve_speed*dt;
    x+=lengthdir_x(post_speed*dt,post_direction);
    y+=lengthdir_y(post_speed*dt,post_direction);
    post_speed+=post_acceleration*dt;
    if(post_rotation_mode==1) image_angle+=post_rotation_speed*dt;
    else if(post_rotation_mode==2){
        var post_rotation_progress=clamp(wave_time/max(1,post_rotation_time),0,1);
        image_angle=post_angle_from+(post_rotation_target-post_angle_from)*Anim_GetValue(post_rotation_tween,post_rotation_ease,post_rotation_progress);
    }

    var active_ratio=clamp(wave_time/max(1,active_time),0,1);
    if(out!=2&&green_guard_blockable&&!green_guard_blocked&&instance_exists(soul_block)){
        var guard_half=wave_length*0.5;
        var guard_x1=x+lengthdir_x(guard_half,image_angle+180);
        var guard_y1=y+lengthdir_y(guard_half,image_angle+180);
        var guard_x2=x+lengthdir_x(guard_half,image_angle);
        var guard_y2=y+lengthdir_y(guard_half,image_angle);
        var guard_hit=collision_line(guard_x1,guard_y1,guard_x2,guard_y2,soul_block,false,true);
        if(instance_exists(guard_hit)){
            var guard_signed_distance=(guard_hit.x-x)*dcos(image_angle)-(guard_hit.y-y)*dsin(image_angle);
            Battle_GreenGuardBlock(id,guard_hit);
            // Unlike a GB, a knife wave is centred and extends both ways, so
            // preserve the signed projection instead of clamping it to zero.
            green_guard_block_distance=guard_signed_distance;
        }
    }
    var collision_phase=(wave_kind==0||active_ratio<true_knife_collision_end);
    if(out!=2&&instance_exists(battle_soul)&&hit_cooldown<=0&&collision_phase&&!green_guard_blocked){
        var half_length=wave_length*0.5;
        var x1=x+lengthdir_x(half_length,image_angle+180);
        var y1=y+lengthdir_y(half_length,image_angle+180);
        var vx=lengthdir_x(wave_length,image_angle);
        var vy=lengthdir_y(wave_length,image_angle);
        var along=clamp(((battle_soul.x-x1)*vx+(battle_soul.y-y1)*vy)/max(1,wave_length*wave_length),0,1);
        var nearest_x=x1+vx*along;
        var nearest_y=y1+vy*along;
        if(point_distance(battle_soul.x,battle_soul.y,nearest_x,nearest_y)<=hit_width*0.5+Battle_SoulHitboxHalfSize()){
            var input_moving=Input_IsHeld(INPUT.UP)||Input_IsHeld(INPUT.DOWN)||Input_IsHeld(INPUT.LEFT)||Input_IsHeld(INPUT.RIGHT);
            var valid_hit=(type!=1||input_moving)&&(type!=2||!input_moving);
            if(valid_hit){
                if(type==3){
                    Player_Heal(max(0,heal_amount));
                    audio_play_sound(snd_item_heal,0,false);
                    instance_destroy();
                }else if(type==5){
                    if(!Battle_ShieldAbsorb()) Player_ReduceMaxHp(max(1,hp_damage));
                }else if(type==6||instant_damage){
                    Player_HurtColor(6,max(Player_GetHpMax(),hp_damage),true);
                }else if(wave_kind==1) Player_HurtOverflowKr(max(1,hp_damage),invincibility_frames);
                else Player_HurtColor(type,hp_damage,false);
                hit_cooldown=18;
            }
        }
    }

    if(wave_time>=active_time){
        // True Knife already narrows and fades during its one active pass.
        // Entering the generic fade state resets wave_time and used to replay
        // its enlargement a second time.
        if(wave_kind==1) instance_destroy();
        else{
            wave_state=2;
            wave_time=0;
        }
    }
}else{
    wave_alpha=1-clamp(wave_time/max(1,fade_time),0,1);
    if(wave_time>=fade_time) instance_destroy();
}
