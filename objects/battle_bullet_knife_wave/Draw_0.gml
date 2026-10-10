// Collision remains effectively infinite. Restrict the submitted primitive to
// a generous screen-spanning segment so board-surface clipping does not cull
// both distant endpoints and make the whole line disappear.
var half_length=max(room_width,room_height)*2.5;
var x1=x+lengthdir_x(half_length,image_angle+180);
var y1=y+lengthdir_y(half_length,image_angle+180);
var x2=x+lengthdir_x(half_length,image_angle);
var y2=y+lengthdir_y(half_length,image_angle);

if(wave_state>0&&green_guard_blocked){
    // Ray direction is x1 -> x2. Preserve everything before the shield and
    // remove only the section that would continue through the player.
    x2=x+lengthdir_x(green_guard_block_distance,image_angle);
    y2=y+lengthdir_y(green_guard_block_distance,image_angle);
}

if(out==0) surface_set_target(Battle_GetBoardSurface());
draw_set_color(wave_color);
if(wave_state==0){
    if(wave_kind==0){
        Battle_DrawStrip(x,y,image_angle,half_length,max(1,warning_width),wave_color,1);
    }
}else{
    // Visual width is intentionally decoupled from collision. hit_width is
    // fixed at visual_min_width - hit_inset for the entire active phase.
    var active_ratio=clamp(wave_time/max(1,active_time),0,1);
    var draw_width=visual_min_width;
    if(wave_kind==1){
        // One pass only: appear to the narrow hit width, widen once, then
        // immediately collapse and fade. The old cosine pulse repeated several
        // times and restarted after the active timer, making True Knife linger.
        var grow_end=0.22;
        var widen_end=0.48;
        if(active_ratio<grow_end){
            var grow_t=active_ratio/grow_end;
            var grow_ease=0.5-0.5*dcos(180*grow_t);
            draw_width=visual_min_width*grow_ease;
        }else if(active_ratio<widen_end){
            var widen_t=(active_ratio-grow_end)/(widen_end-grow_end);
            var widen_ease=0.5-0.5*dcos(180*widen_t);
            draw_width=lerp(visual_min_width,visual_max_width,widen_ease);
        }else{
            var collapse_t=(active_ratio-widen_end)/(1-widen_end);
            var collapse_ease=0.5-0.5*dcos(180*collapse_t);
            draw_width=lerp(visual_max_width,0,collapse_ease);
            wave_alpha=1-collapse_ease;
        }
    }else{
        var launch_t=clamp(wave_time/max(1,slash_launch_frames),0,1);
        var launch_ease=0.5-0.5*dcos(180*launch_t);
        var pulse_t=max(0,wave_time-slash_launch_frames)/6;
        var pulse_mix=(1-dcos(360*pulse_t))*0.5;
        draw_width=lerp(visual_min_width,visual_max_width,pulse_mix)*launch_ease;
        if(active_time-wave_time<slash_fade_frames){
            var fade_t=clamp((active_time-wave_time)/max(1,slash_fade_frames),0,1);
            wave_alpha*=0.5-0.5*dcos(180*fade_t);
        }
    }
    if(draw_width>0.1){
        // A green guard truncates only the section beyond the shield.  Rebuild
        // the strip from the already-clipped endpoints; drawing again from the
        // original centre would visually ignore green_guard_block_distance.
        var segment_length=point_distance(x1,y1,x2,y2);
        if(segment_length>0.1){
            var segment_x=(x1+x2)*0.5;
            var segment_y=(y1+y2)*0.5;
            var segment_angle=point_direction(x1,y1,x2,y2);
            Battle_DrawStrip(segment_x,segment_y,segment_angle,segment_length*0.5,draw_width,wave_color,wave_alpha);
        }
    }
}
draw_set_alpha(1);
draw_set_color(c_white);
if(out==0) surface_reset_target();
