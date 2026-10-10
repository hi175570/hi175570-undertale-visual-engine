global.boards_controller_array = [];
global.boards_array = [];

surface_free(_surface);
surface_free(_surface_board_cover);
surface_free(_surface_board_extra);
surface_free(_surface_mask);
if(surface_exists(_surface_editor_clip_mask)) surface_free(_surface_editor_clip_mask);
