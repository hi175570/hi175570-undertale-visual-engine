if (point_at == 1) {
    if (x != xprevious || y != yprevious) {
        angle = point_direction(xprevious, yprevious, x, y) + angle_offset;
    }
}
if(follow){
    _angle += rotate;
    angle = _angle + follow_angle;}
else
	angle += rotate;
image_angle = angle + editor_sprite_angle_offset;
if(editor_visual_override){
    image_blend=editor_visual_color;
}else{
    switch(type)
    {
        case 0:
            image_blend = c_white;
            break;
        case 1:
            image_blend = make_color_rgb(20,196,255);
            break;
        case 2:
            image_blend = make_color_rgb(248,148,29);
            break;
        case 3:
            image_blend = make_color_rgb(0, 255, 0);
            break;
        case 5:
            // Dark green means max-HP damage; bright green (type 3) remains healing.
            image_blend = make_color_rgb(0, 96, 32);
            break;
        case 4:
            image_blend = c_yellow;
            break;
        case 6:
            image_blend = c_red;
            break;
        case 7:
            image_blend = make_color_rgb(75,0,130);
            break;
        case 8:
            image_blend = make_color_rgb(20,32,160);
            break;
    }
}

if(out == 0){
	depth = DEPTH_BATTLE.BULLET;
	var editor_custom_clip=BattleEditor_CustomClipBegin(id);
	surface_set_target(Battle_GetBoardSurface());{
		if(variable_instance_exists(id,"bone_style")&&round(real(bone_style))==1) Battle_DrawBoneSpikeAt(x,y,length,angle,point,image_blend,image_alpha);
		else draw_self();
	}surface_reset_target();
	BattleEditor_CustomClipEnd(editor_custom_clip);
}
else{
	depth = out==2?DEPTH_BATTLE.BULLET:DEPTH_BATTLE.BULLET_OUTSIDE_LOW;
	if(variable_instance_exists(id,"bone_style")&&round(real(bone_style))==1) Battle_DrawBoneSpikeAt(x,y,length,angle,point,image_blend,image_alpha);
	else draw_self();
}
