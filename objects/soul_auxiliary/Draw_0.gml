if (Battle_GetState()!=BATTLE_STATE.IN_TURN) exit;
if (!battle_soul_aqua.type) {
	if(!variable_instance_exists(id,"radius")) radius=32;
	surface_set_target(Battle_GetBoardSurface());
	draw_set_color(c_black);
	draw_circle(x,y,radius,false);
	draw_set_color(make_color_rgb(0,120,255));
	var segments=24;
	for(var i=0;i<segments;i++){
		var a1=i*360/segments;
		var a2=(i+1)*360/segments;
		draw_line_width(round(x+lengthdir_x(radius,a1)),round(y+lengthdir_y(radius,a1)),round(x+lengthdir_x(radius,a2)),round(y+lengthdir_y(radius,a2)),3);
	}
	surface_reset_target();
}
