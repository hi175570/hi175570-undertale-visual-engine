event_user(0);

// Room changes may recreate application_surface from the room dimensions.
// Normalize it after the transition; the camera view above handles whether
// the room itself uses 320x240 or 640x480 coordinates.
display_set_gui_size(640,480);
if(surface_exists(application_surface)) surface_resize(application_surface,640,480);

view_enabled=true;
view_camera[0]=_camera;
view_visible[0]=true;
