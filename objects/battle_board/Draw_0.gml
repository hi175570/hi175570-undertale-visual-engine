// Build the playable alpha mask first.  ADD frames are unioned, then every
// SUBTRACT frame cuts the result.  Borders are drawn onto their own surface;
// they must never participate in the alpha arithmetic (that was the cause of
// thick wedges, broken joins and disappearing black interiors on stars).
if(_board_render_dirty){
    for (var pass = 0; pass < 2; pass++) {
        for (var i = 0; i < array_length(global.boards_array); i++) {
            var board = global.boards_array[i];
            if (is_struct(board) && !board._destroyed && board.cover == pass) {
                draw_set_alpha(1);
                board.replaceSurfaceAlpha();
                board.drawBorder();
            }
        }
    }
}
draw_set_alpha(1);
surface_set_target(_surface);
draw_surface(_surface_board_cover, 0, 0);
surface_reset_target();
gpu_set_colorwriteenable(0, 0, 0, 1);
gpu_set_blendmode(bm_min);
surface_set_target(_surface);
draw_surface(_surface_mask, 0, 0);
surface_reset_target();
gpu_set_blendmode(bm_normal);
gpu_set_colorwriteenable(1, 1, 1, 1);
draw_surface(_surface, 0, 0);
draw_surface(_surface_board_cover, 0, 0);
