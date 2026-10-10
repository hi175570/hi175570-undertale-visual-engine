event_inherited();
if (Battle_GetState() == BATTLE_STATE.IN_TURN && moveable) {
    var arbitrary=[];
    for(var rail_i=0;rail_i<array_length(point);rail_i++){
        if(variable_struct_exists(point[rail_i],"rail") && point[rail_i].rail) array_push(arbitrary,point[rail_i]);
    }
    if(array_length(arbitrary)>0){
        var nearest=arbitrary[0];
        var nearest_dist=1000000;
        var nearest_x=x;
        var nearest_y=y;
        for(var ar_i=0;ar_i<array_length(arbitrary);ar_i++){
            var rail=arbitrary[ar_i];
            var ux=dcos(rail.angle);
            var uy=-dsin(rail.angle);
            var along=clamp((x-rail.x)*ux+(y-rail.y)*uy,-rail.length*0.5,rail.length*0.5);
            var px=rail.x+ux*along;
            var py=rail.y+uy*along;
            var pd=point_distance(x,y,px,py);
            if(pd<nearest_dist){nearest=rail;nearest_dist=pd;nearest_x=px;nearest_y=py;}
        }
        x=nearest_x;
        y=nearest_y;
        var input_x=Input_IsHeld(INPUT.RIGHT)-Input_IsHeld(INPUT.LEFT);
        var input_y=Input_IsHeld(INPUT.DOWN)-Input_IsHeld(INPUT.UP);
        var rail_x=dcos(nearest.angle);
        var rail_y=-dsin(nearest.angle);
        // Normal rails read screen-space input and keep the soul upright.
        // World rails rotate the local coordinate system: local LEFT/RIGHT
        // follows the rail even when the whole world is turned.
        var input_along=nearest.rotate_mode ? input_x : input_x*rail_x+input_y*rail_y;
        var rail_speed=Player_GetSpdTotal()*(Input_IsHeld(INPUT.CANCEL)?0.5:1)*global.delta_time_factor;
        var next_along=clamp((x-nearest.x)*rail_x+(y-nearest.y)*rail_y+input_along*rail_speed,-nearest.length*0.5,nearest.length*0.5);
        x=nearest.x+rail_x*next_along;
        y=nearest.y+rail_y*next_along;
        var target_angle=nearest.rotate_mode ? nearest.angle : 0;
        image_angle+=angle_difference(image_angle,target_angle)*min(1,0.22*global.delta_time_factor);

        // Arbitrary rails own their motion while active. The parent Step has
        // already run once at the top of this event, so do not run it twice.
        for(var move_i=array_length(point)-1;move_i>=0;move_i--){
            var move_rail=point[move_i];
            if(!(variable_struct_exists(move_rail,"rail") && move_rail.rail)) continue;
            move_rail.x+=move_rail.hspeed*global.delta_time_factor;
            move_rail.y+=move_rail.vspeed*global.delta_time_factor;
            if(move_rail.duration==0) move_rail.destroyed=1;
            else if(move_rail.duration>0) move_rail.duration-=global.delta_time_factor;
            if(move_rail.auto_destroy && (move_rail.y<0 || move_rail.y>room_height || move_rail.x<0 || move_rail.x>room_width)) move_rail.destroyed=1;
            if(move_rail.destroyed) array_delete(point,move_i,1);
        }
        exit;
    }
    var px = [];
    var py = [];
    var ps = array_length(point);
    for (var i = 0; i < ps; i++) {
        if (point[i].horizontal) {
            array_push(py, point[i]);
        }
        if (point[i].vertical) {
            array_push(px, point[i]);
        }
    }
    array_sort(px,
    function(a, b) {
        return a.x > b.x;
    });
    array_sort(py,
    function(a, b) {
        return a.y > b.y;
    });

    // A newly switched purple soul may arrive between its rails. Snap once to
    // the nearest available horizontal or vertical rail so movement can begin
    // immediately instead of leaving the player stranded.
    if(_needs_track_snap && (array_length(px)>0 || array_length(py)>0)){
        var bestv=-1, besth=-1, bestvd=1000000000, besthd=1000000000;
        for(var snap_i=0;snap_i<array_length(px);snap_i++){
            var candidate_x=abs(x-px[snap_i].x);
            if(candidate_x<bestvd){
                bestvd=candidate_x;
                bestv=snap_i;
            }
        }
        for(var snap_j=0;snap_j<array_length(py);snap_j++){
            var candidate_y=abs(y-py[snap_j].y);
            if(candidate_y<besthd){
                besthd=candidate_y;
                besth=snap_j;
            }
        }
        if(bestv>=0 && (besth<0 || bestvd<=besthd)){
            x=px[bestv].x;
            moving_direction=1;
        }else if(besth>=0){
            y=py[besth].y;
            moving_direction=0;
        }
        _needs_track_snap=false;
    }

    if (cross_step>0) {
        if (is_struct(cross_start) && is_struct(cross_target) && !cross_start.destroyed && !cross_start.destroyed) {
            if (moving_direction) {
                cross_step -= global.delta_time_factor;
                y = lerp(cross_target.y, cross_start.y, (cross_step < 0 ? 0 : cross_step) / 10);
            } else {
                cross_step -= global.delta_time_factor;
                x = lerp(cross_target.x, cross_start.x, (cross_step < 0 ? 0 : cross_step) / 10);
            }
        } else {
            cross_start = noone;
            cross_target = noone;
            cross_step = 0;
        }
    } else {
        x_on = noone;
        y_on = noone;
        for (var i = 0; i < array_length(px); i++) {
            if (x >= px[i].x - 5 && x <= px[i].x + 5) {
                moving_direction = 1;
                x_on = px[i];
                x_index = i;
            }
        }

        for (var i = 0; i < array_length(py); i++) {
            if (y >= py[i].y - 5 && y <= py[i].y + 5) {
                moving_direction = 0;
                y_on = py[i];
                y_index = i;
            }
        }

        var SPD = Player_GetSpdTotal();
        SPD = (Input_IsHeld(INPUT.CANCEL) ? SPD / 2 : SPD);

        // 根据输入移动角色
        if (moveable) {
            if (is_struct(x_on)) {
                repeat(SPD * 10) {
                    if (Input_IsHeld(INPUT.UP)) {
                        if (!position_meeting(x, y - sprite_height / 2, block)) {
                            y -= 0.1 * global.delta_time_factor;
                            x = x_on.x;
                            moving_direction = 1;
                        }
                    }

                    if (Input_IsHeld(INPUT.DOWN)) {
                        if (!position_meeting(x, y + sprite_height / 2, block)) {
                            y += 0.1 * global.delta_time_factor;
                            x = x_on.x;
                            moving_direction = 1;
                        }
                    }
                }
            } else {
                if (Input_IsPressed(INPUT.UP)) {
                    if (y_index > 0) {
                        if (_crossable(x, py[y_index - 1].y - sprite_height / 2)) {
                            moving_direction = 1;
                            cross_step = 10;
                            cross_start = y_on;
                            cross_target = py[y_index - 1];
                        }
                    }
                } else if (Input_IsPressed(INPUT.DOWN)) {
                    if ((y_index + 1) < array_length(py)) if (_crossable(x, py[y_index + 1].y + sprite_height / 2)) {
                        moving_direction = 1;
                        cross_step = 10;
                        cross_start = y_on;
                        cross_target = py[y_index + 1];
                    }
                }
            }
            if (is_struct(y_on)) {
                repeat(SPD * 10) {
                    if (Input_IsHeld(INPUT.LEFT)) {
                        if (!position_meeting(x - sprite_width / 2, y, block)) {
                            x -= 0.1 * global.delta_time_factor;
                            y = y_on.y;
                            if (!cross_step) moving_direction = 0;
                        }
                    }

                    if (Input_IsHeld(INPUT.RIGHT)) {
                        if (!position_meeting(x + sprite_width / 2, y, block)) {
                            x += 0.1 * global.delta_time_factor;
                            y = y_on.y;
                            if (!cross_step) moving_direction = 0;
                        }
                    }
                }
            } else {
                if (Input_IsPressed(INPUT.LEFT)) {
                    if (x_index > 0) if (_crossable(px[x_index - 1].x - sprite_width / 2, y)) {
                        moving_direction = 0;
                        cross_step = 10;
                        cross_start = x_on;
                        cross_target = px[x_index - 1];
                    }
                } else if (Input_IsPressed(INPUT.RIGHT)) {
                    if ((x_index + 1) < array_length(px)) if (_crossable(px[x_index + 1].x + sprite_width / 2, y)) {
                        moving_direction = 0;
                        cross_step = 10;
                        cross_start = x_on;
                        cross_target = px[x_index + 1];
                    }
                }
            }
        }
    }
    for (var i = 0; i < ps; i++) {
        point[i].x += point[i].hspeed * global.delta_time_factor;
        point[i].y += point[i].vspeed * global.delta_time_factor;
        if (point[i].duration == 0) point[i].destroyed = 1;
        else if (point[i].duration > 0) point[i].duration -= 1 * global.delta_time_factor;
        if (point[i].auto_destroy && (point[i].y < 0 || point[i].y > room_height || point[i].x < 0 || point[i].x > room_width)) point[i].destroyed = 1;
        if (point[i].destroyed) {
            delete point[i];
            array_delete(point, i--, 1);
            continue;
        }
    }
}
