editor_gb_released=true;
// The anticipation compresses the head across its artwork width. Scaling Y
// squashed it along the wrong local axis after the source-direction rotation.
Anim_Create(id,"scale_x",0,0,scale_x,-scale_x*0.2,6);
alarm[2] = 7 / global.delta_time_factor; // 直接除法，修正时间缩放
