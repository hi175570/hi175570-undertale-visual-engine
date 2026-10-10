if(Battle_GetState()==BATTLE_STATE.IN_TURN){
    draw_set_color(make_color_rgb(64, 0, 64));
    surface_set_target(Battle_GetBoardSurface());
    for (var i = 0; i < array_length(point); i++) {
        if(variable_struct_exists(point[i],"rail") && point[i].rail){
            var half=point[i].length*0.5;
            draw_line_width(point[i].x+lengthdir_x(half,point[i].angle+180),point[i].y+lengthdir_y(half,point[i].angle+180),point[i].x+lengthdir_x(half,point[i].angle),point[i].y+lengthdir_y(half,point[i].angle),2);
        }else if (point[i].horizontal) {
            draw_line_width(point[i].x - 1000, point[i].y - 1, point[i].x + 1000, point[i].y - 1, 2);
        }
        if (!(variable_struct_exists(point[i],"rail") && point[i].rail) && point[i].vertical) {
            draw_line_width(point[i].x - 1, point[i].y - 1000, point[i].x - 1, point[i].y + 1000, 2);
        }
    }
    surface_reset_target();
}
