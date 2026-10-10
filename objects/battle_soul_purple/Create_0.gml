event_inherited();
image_blend = make_color_rgb(128, 0, 128);
x_on = noone;
y_on = noone;
cross_step = 0;
cross_start = noone;
cross_target = noone;
point = [];
moving_direction = 0;
_needs_track_snap = true;


x_index = 0;
y_index = 0;

_crossable = function(xx, yy) {
    var able = 0;
	var boardcount = array_length(global.boards_array);
    for (var i = 0; i < boardcount; i++) {
        if (global.boards_array[i].cover) able &= !global.boards_array[i].contains(xx, yy);
        else able |= global.boards_array[i].contains(xx, yy);
    }
    return able;
}
function AddPoint(x, y, vertical, horizontal, hspeed = 0, vspeed = 0, duration = -1, auto_destroy = 0) {
    var p = {
        x: x,
        y: y,
        vertical: vertical,
        horizontal: horizontal,
        hspeed: hspeed,
        vspeed: vspeed,
        duration: duration,
        auto_destroy: auto_destroy,
		destroyed: 0
    }
        array_push(point, p);
    return p;
}

/// Adds one arbitrary-angle rail. rotate_mode 0 keeps the soul upright;
/// rotate_mode 1 smoothly aligns it with the rail's screen angle.
function AddRail(x,y,angle,length=220,rotate_mode=0,hspeed=0,vspeed=0,duration=-1,auto_destroy=0){
    var p={x:x,y:y,angle:angle,length:length,rotate_mode:rotate_mode,hspeed:hspeed,vspeed:vspeed,duration:duration,auto_destroy:auto_destroy,destroyed:0,rail:true};
    array_push(point,p);
    _needs_track_snap=true;
    return p;
}
