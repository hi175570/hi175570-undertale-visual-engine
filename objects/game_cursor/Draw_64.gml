// The border compositor owns the final native-pixel cursor. Do not leave a
// second logical-GUI cursor underneath it (or inside the game filters).
if(os_type==os_windows&&!instance_exists(border)){
    var cursor_x=device_mouse_x_to_gui(0);
    var cursor_y=device_mouse_y_to_gui(0);
    // The heart's pointed bottom becomes the pointer tip at the upper-left.
    draw_sprite_ext(spr_battle_soul,0,cursor_x+3,cursor_y+3,0.55,0.55,225,c_red,1);
}
