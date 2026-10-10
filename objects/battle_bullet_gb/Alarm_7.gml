var dt=global.delta_time_factor;
if(array_length(offset_path)>0){
    var segment=offset_path[offset_path_index];
    if(!offset_path_started){
        offset_direction=segment.direction;
        offset_speed=segment.speed;
        offset_acceleration=segment.acceleration;
        offset_rotation_speed=segment.rotation_speed;
        offset_path_started=true;
    }
    angle+=offset_rotation_speed*dt;
    var dx=lengthdir_x(offset_speed*dt,offset_direction);
    var dy=lengthdir_y(offset_speed*dt,offset_direction);
    if(!follow){x+=dx;y+=dy;}else{_x+=dx;_y+=dy;}
    offset_speed+=offset_acceleration*dt;
    offset_path_time+=dt;
    if(offset_path_time>=segment.duration && offset_path_index<array_length(offset_path)-1){
        offset_path_index++;
        offset_path_time=0;
        offset_path_started=false;
    }
}else if(fake_mode!=0){
    // Both fake variants recoil upward before gravity takes over.  Mode 1 has
    // already played the release animation; mode 2 has already played the hit
    // sound/shake, but their physical fall is intentionally shared.
    x+=_fake_drop_vx*dt;
    y+=_fake_drop_vy*dt;
    _fake_drop_vy+=_fake_drop_gravity*dt;
    image_angle+=_fake_drop_spin*dt;
}else{
    _exit_speed++;
    if(!follow){
        x-=lengthdir_x(_exit_speed,angle);
        y-=lengthdir_y(_exit_speed,angle);
    }else{
        _x-=lengthdir_x(_exit_speed,angle);
        _y-=lengthdir_y(_exit_speed,angle);
    }
}

// Release/fake-drop cleanup happens only after the complete head has left the
// battle view.  The old alarm loop kept an invisible GB and its beam instance
// alive forever, which accumulated badly in long editor previews.
var cleanup_margin=max(32,max(sprite_width*abs(image_xscale),sprite_height*abs(image_yscale)));
if((x<-cleanup_margin||x>room_width+cleanup_margin||y<-cleanup_margin||y>room_height+cleanup_margin)
&& (fake_mode!=0||image_alpha<=0.05)){
    if(instance_exists(_inst)) instance_destroy(_inst);
    instance_destroy();
    exit;
}
alarm[7] = 1 / global.delta_time_factor; // 修正：除法而不是乘法
