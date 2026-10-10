if(editor_visual_override){
    image_blend=editor_visual_color;
}else if(editor_gb_beam_custom&&editor_gb_beam_uses_own_color){
    image_blend=c_white;
}else switch(type)
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
    case 4:
        image_blend = c_yellow;
        break;
    case 5:
        // Max-HP damage uses the same dark green as bones and the GB head.
        image_blend = make_color_rgb(0, 96, 32);
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

// Render only the part of the mathematically infinite ray that can intersect
// the current camera. Drawing a sprite from the GB's actual position eventually
// loses the screen when a long-lived GB has recoiled millions of pixels away.
var _view_x=0,_view_y=0,_view_w=room_width,_view_h=room_height;
if(view_enabled&&view_camera[0]!=-1){
    _view_x=camera_get_view_x(view_camera[0]);
    _view_y=camera_get_view_y(view_camera[0]);
    _view_w=camera_get_view_width(view_camera[0]);
    _view_h=camera_get_view_height(view_camera[0]);
}
var _ray_angle=image_angle+(image_xscale<0?180:0);
var _ray_dx=lengthdir_x(1,_ray_angle),_ray_dy=lengthdir_y(1,_ray_angle);
var _view_cx=_view_x+_view_w*0.5,_view_cy=_view_y+_view_h*0.5;
var _to_view_x=_view_cx-x,_to_view_y=_view_cy-y;
var _along=_to_view_x*_ray_dx+_to_view_y*_ray_dy;
var _normal_x=-_ray_dy,_normal_y=_ray_dx;
var _perpendicular=_to_view_x*_normal_x+_to_view_y*_normal_y;
var _half_diagonal=point_distance(0,0,_view_w*0.5,_view_h*0.5)+128;
var _segment_start=max(0,_along-_half_diagonal);
var _segment_end=max(0,_along+_half_diagonal);
if(green_guard_blocked) _segment_end=min(_segment_end,max(0,green_guard_block_distance));
var _segment_length=max(0,_segment_end-_segment_start);
var _closest_x=_view_cx-_normal_x*_perpendicular;
var _closest_y=_view_cy-_normal_y*_perpendicular;
var _draw_x=_closest_x+_ray_dx*(_segment_start-_along);
var _draw_y=_closest_y+_ray_dy*(_segment_start-_along);
var _draw_xscale=_segment_length/max(1,sprite_width);
var _beam_draw_angle=_ray_angle;
var _beam_draw_xscale=_draw_xscale;
var _beam_draw_yscale=image_yscale;
if(editor_gb_beam_custom){
    var _source_direction=((round(editor_gb_beam_source_direction/90)*90) mod 360+360) mod 360;
    var _vertical_source=_source_direction==90||_source_direction==270;
    var _source_length=_vertical_source?sprite_height:sprite_width;
    var _source_thickness=_vertical_source?sprite_width:sprite_height;
    var _target_thickness=16*abs(image_yscale);
    var _along_scale=_segment_length/max(1,_source_length);
    var _across_scale=_target_thickness/max(1,_source_thickness);
    _beam_draw_xscale=_vertical_source?_across_scale:_along_scale;
    _beam_draw_yscale=_vertical_source?_along_scale:_across_scale;
    _beam_draw_angle=_ray_angle-_source_direction;
}

// Draw a straight semantic core underneath the bundled artwork.  The regular
// sprite remains the detailed overlay, but clipping/scaling can no longer make
// a built-in attack lose its beam completely; user-created beam groups remain
// texture-only so their authored appearance is not replaced.
var _draw_core=editor_gb_guarantee_core&&_segment_length>0&&image_alpha>0;
var _core_color=image_blend;
var _old_alpha=1;
if(_draw_core&&editor_gb_beam_uses_own_color){
    if(type==1) _core_color=make_color_rgb(20,196,255);
    else if(type==2) _core_color=make_color_rgb(248,148,29);
}

if(out == 0){
	depth = DEPTH_BATTLE.BULLET;
	surface_set_target(Battle_GetBoardSurface());{
		if(_draw_core){
			_old_alpha=draw_get_alpha();draw_set_alpha(image_alpha);
			draw_line_width_color(_draw_x,_draw_y,_draw_x+_ray_dx*_segment_length,_draw_y+_ray_dy*_segment_length,max(1,12*abs(image_yscale)),_core_color,_core_color);
			draw_set_alpha(_old_alpha);
		}
		if(_segment_length>0) draw_sprite_ext(sprite_index,image_index,_draw_x,_draw_y,_beam_draw_xscale,_beam_draw_yscale,_beam_draw_angle,image_blend,image_alpha);
	}surface_reset_target();
}
else{
	depth = out==2?DEPTH_BATTLE.BULLET:DEPTH_BATTLE.BEAM;
	if(_draw_core){
		_old_alpha=draw_get_alpha();draw_set_alpha(image_alpha);
		draw_line_width_color(_draw_x,_draw_y,_draw_x+_ray_dx*_segment_length,_draw_y+_ray_dy*_segment_length,max(1,12*abs(image_yscale)),_core_color,_core_color);
		draw_set_alpha(_old_alpha);
	}
	if(_segment_length>0) draw_sprite_ext(sprite_index,image_index,_draw_x,_draw_y,_beam_draw_xscale,_beam_draw_yscale,_beam_draw_angle,image_blend,image_alpha);
}
