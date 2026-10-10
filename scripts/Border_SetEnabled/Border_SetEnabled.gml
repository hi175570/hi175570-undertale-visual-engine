///@arg enabled,blur
function Border_SetEnabled() {
	var ENABLED=argument[0];

	if(ENABLED){
		border._enabled=true;
		border.blur=argument[1]
	}else{
		border._enabled=false;
	
		if(sprite_exists(border._sprite)){
			sprite_flush(border._sprite);
			border._sprite=-1;
		}
		if(sprite_exists(border._sprite_previous)){
			sprite_flush(border._sprite_previous);
			border._sprite_previous=-1;
		}
	}
	
	Window_ApplyScale();
	return true;


}

/// Presentation only: never change camera coordinates or rendering surfaces.
function Window_ScaleOptions() { return [1,1.25,1.5,1.75,2,0]; }

function Window_ScaleSize(requested,base_width,base_height,screen_width,screen_height) {
    var fit=max(0.25,min((screen_width-40)/base_width,(screen_height-80)/base_height));
    var scale=requested<=0?fit:min(requested,fit);
    return {width:round(base_width*scale),height:round(base_height*scale),scale:scale};
}

function Window_ApplyScale() {
    if(!variable_global_exists("window_scale")) global.window_scale=1;
    if(window_get_fullscreen()) return; // F4 retains the windowed preference.
    var wide=instance_exists(border)&&border._enabled;
    var size=Window_ScaleSize(global.window_scale,wide?960:640,wide?540:480,display_get_width(),display_get_height());
    if(window_get_width()!=size.width||window_get_height()!=size.height){
        window_set_size(size.width,size.height);
        window_center();
    }
}

function Window_SetScale(value) {
    var options=Window_ScaleOptions(),valid=false;
    for(var i=0;i<array_length(options);i++) if(value==options[i]) valid=true;
    global.window_scale=valid?value:1;
    var settings=Storage_GetSettings();
    settings.Get("general").Set("window_scale",global.window_scale);
    settings.SaveToFile();
    Window_ApplyScale();
}

/// The same client-pixel rectangle drives editor drawing AND hit testing.
/// GUI camera state is transient during the final surface compositor.
function Window_ContentViewport(width=-1,height=-1,wide=undefined) {
    if(width<0) width=window_get_fullscreen()?display_get_width():window_get_width();
    if(height<0) height=window_get_fullscreen()?display_get_height():window_get_height();
    if(is_undefined(wide)) wide=instance_exists(border)&&border._enabled;
    var base_width=wide?960:640,base_height=wide?540:480;
    var scale=max(0.0001,min(width/base_width,height/base_height));
    var content_width=max(1,round(640*scale)),content_height=max(1,round(480*scale));
    return {window_width:width,window_height:height,scale:scale,
        x:(width-base_width*scale)*0.5+(wide?160*scale:0),
        y:(height-base_height*scale)*0.5+(wide?30*scale:0),
        width:content_width,height:content_height,
        scale_x:content_width/640,scale_y:content_height/480};
}

function Window_ClientToContent(x,y,viewport=undefined) {
    if(is_undefined(viewport)) viewport=Window_ContentViewport();
    // Do not clamp: drags are deliberately allowed beyond the canvas.
    return {x:(x-viewport.x)/viewport.scale_x,y:(y-viewport.y)/viewport.scale_y};
}

function Window_ContentMouse() {
    return Window_ClientToContent(window_mouse_get_x(),window_mouse_get_y());
}
