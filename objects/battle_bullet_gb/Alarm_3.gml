var gb_frame_count=max(1,sprite_get_number(sprite_index));
editor_gb_opening=false;
if(fake_mode!=2){
    // A firing real GB and the animated fake GB both flicker only between the
    // final two opened-mouth frames. The struck/drop variant never schedules
    // this alarm, because it stays closed.
    var gb_loop_start=max(0,gb_frame_count-2);
    var gb_frame=round(image_index);
    image_index=(gb_frame<gb_loop_start||gb_frame>=gb_frame_count-1)?gb_loop_start:gb_frame+1;
    alarm[3]=max(1,editor_gb_frame_interval) / global.delta_time_factor;
}else{
    image_index=0;
    alarm[3]=-1;
}
