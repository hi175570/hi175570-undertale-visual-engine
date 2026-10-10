Time_Step();
Anim_Step();
BGM_Step();

// The visible counter refreshes ten times per second. Drawing the cached text
// remains essentially free and avoids tying its readability to render rate.
if(current_time>=_fps_display_next_ms){
	global.fps_display_text=string_format(fps_real,0,1);
	_fps_display_next_ms=current_time+100;
}

if(_time>=GAME_FPS){
	var z=Storage_GetStaticGeneral();
	var time=z.Get(FLAG_STATIC_TIME,0);
	z.Set(FLAG_STATIC_TIME,time+1);
	_time=0;
}else{
	_time+=global.delta_time_factor;
}

if(Game_GetFrameSkip()>0){
	if(_frame_skip>=Game_GetFrameSkip()){
		draw_enable_drawevent(true);
		_frame_skip=0;
	}else{
		_frame_skip+=1;
		draw_enable_drawevent(false);
	}
}else{
	draw_enable_drawevent(true);
}

if(keyboard_check_pressed(vk_f2)){
	game_restart();
}


if(keyboard_check_pressed(vk_f4)&&!keyboard_check(vk_alt)&&!keyboard_check(vk_control)&&!keyboard_check(vk_shift)){
	window_set_fullscreen(!window_get_fullscreen());
	if(!window_get_fullscreen()) Window_ApplyScale();
}
