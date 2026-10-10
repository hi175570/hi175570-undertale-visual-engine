if(_menu==0){
	draw_sprite_ext(spr_logo,0,160,55,0.75,0.75,0,c_white,1);
	// room_menu is 320x240 and is displayed at 2x. Half scale keeps the
	// selector the same on-screen size as the 16x16 soul used in battle.
	draw_sprite_ext(spr_battle_soul,0,_selector_x,_selector_y,0.5,0.5,0,c_red,1);
	if(_mode==1){
		// Keep the same compact title layout when a save exists.
	}
}
if(_menu==0){
	draw_set_halign(fa_center);
	draw_set_valign(fa_bottom);
	draw_set_font(font_crypt_of_tomorrow);
	draw_set_color(c_gray);
	TextTyper_DrawFallbackTransformed(320/2,476/2,"UNDERTALE (C) TOBY FOX 2015-"+string(date_get_year(date_current_datetime()))+"\nUNDERTALE ENGINE ULTRA"+ENGINE_VERSION+"  作者 TML&ZNM",1,1,0);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

if(_menu==1){
	draw_set_color(c_white);
	draw_set_font(font_determination_mono);
	TextTyper_DrawFallbackTransformed(280/2,110/2,_naming_name,1,1,0);
}

if(_menu==2||_menu==3){
	draw_set_color(c_white);
	draw_set_font(font_determination_mono);
	TextTyper_DrawFallbackTransformed((_confirm_name_x+_confirm_name_offset_x)/2,(_confirm_name_y+_confirm_name_offset_y)/2,_naming_name,_confirm_name_scale/2,_confirm_name_scale/2,_confirm_name_angle);
}
