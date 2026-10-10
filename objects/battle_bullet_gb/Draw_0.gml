image_xscale=scale_x;
image_yscale=scale_y;
if (instance_exists(_inst)) {
    if(alarm[4]>=0) _beam_scale=max(0,_beam_envelope+_beam_breath_offset);
    if(_beam_closing&&_beam_alpha<=0.001){
        _beam_alpha=0;
        _beam_scale=0;
        _beam_envelope=0;
        _beam_close_complete=true;
    }
    _inst.type = type;
    _inst.editor_visual_override=editor_visual_override;
    _inst.editor_visual_color=editor_visual_color;
    _inst.heal_amount=heal_amount;
    _inst.editor_damage_enabled=editor_damage_enabled;
    _inst.hp_damage=hp_damage;
    _inst.kr_damage=kr_damage;
    _inst.out = out;
    _inst.yellow_shootable=yellow_shootable;
    _inst.yellow_heavy=yellow_heavy;
    _inst.yellow_hp_damage=yellow_hp_damage;
    _inst.yellow_kr_damage=yellow_kr_damage;
    var LEN = editor_gb_beam_source_offset * scale_y;
    var X = x + lengthdir_x(LEN, angle);
    var Y = y + lengthdir_y(LEN, angle);
    _inst.x = X;
    _inst.y = Y;
    _inst.image_angle = angle;
	_inst.image_alpha = _beam_alpha;
	// Keep the Runner-tested 999x baseline, then extend it further whenever a
	// moving GB gets far enough away that the baseline could expose its endpoint.
	// Distance to the view centre plus its half diagonal covers the whole camera
	// even when the camera is rotated, so this behaves as an infinite ray without
	// feeding an enormous integer scale to the renderer.
    var _view_x=0,_view_y=0,_view_w=room_width,_view_h=room_height;
    if(view_enabled&&view_camera[0]!=-1){
        _view_x=camera_get_view_x(view_camera[0]);
        _view_y=camera_get_view_y(view_camera[0]);
        _view_w=camera_get_view_width(view_camera[0]);
        _view_h=camera_get_view_height(view_camera[0]);
    }
    var _view_cx=_view_x+_view_w*0.5,_view_cy=_view_y+_view_h*0.5;
    var _required_length=point_distance(X,Y,_view_cx,_view_cy)+point_distance(0,0,_view_w*0.5,_view_h*0.5)+128;
    var _beam_scale_sign=image_xscale<0?-1:1;
    var _beam_length_scale=max(999*abs(image_xscale),_required_length/max(1,_inst.sprite_width));
	_inst.image_xscale = _beam_scale_sign*_beam_length_scale;
    _inst.image_yscale = scale_y * _beam_scale;
    // The visual breathes, but collision uses a fixed width slightly inside
    // the narrowest visible beam.
    var _visual_min_width=16*abs(scale_y)*max(0,_beam_scale_default-beam_visual_breath_amplitude);
    _inst.visual_min_width=_visual_min_width;
    _inst.visual_max_width=16*abs(scale_y)*(_beam_scale_default+beam_visual_breath_amplitude);
    _inst.hit_width=max(2,_visual_min_width-beam_hit_inset);
    _inst.hurtable = out!=2&&(_beam_envelope >= _beam_scale_default*0.95) && (_beam_alpha > 0.8);
}

event_inherited();
