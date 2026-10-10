if(is_struct(data)&&struct_exists(data,"warning_kind")){
    // Match Undertale's warning language: an opaque red/yellow alternation is
    // readable immediately, unlike the former white line fading almost away.
    // Four frames per phase keeps the telegraph visibly flashing at 60 FPS.
    var warning_color=(floor(elapsed/4) mod 2)==0?c_red:c_yellow;
    var pulse=1;
    draw_set_alpha(1);
    draw_set_color(warning_color);
    if(data.warning_kind=="line"){
        var warning_length=max(room_width,room_height)*2.5;
        var warning_center_x=x+lengthdir_x(warning_length*0.5,data.warning_angle);
        var warning_center_y=y+lengthdir_y(warning_length*0.5,data.warning_angle);
        Battle_DrawStrip(warning_center_x,warning_center_y,data.warning_angle,warning_length*0.5,2,warning_color,pulse);
    }else{
        var half_width=max(2,data.warning_width*0.5),half_height=max(2,data.warning_height*0.5);
        draw_rectangle(x-half_width,y-half_height,x+half_width,y+half_height,true);
        draw_rectangle(x-half_width+2,y-half_height+2,x+half_width-2,y+half_height-2,true);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}else if(layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD){
    var editor_custom_clip=BattleEditor_CustomClipBegin(id);
    surface_set_target(Battle_GetBoardSurface());
    draw_self();
    surface_reset_target();
    BattleEditor_CustomClipEnd(editor_custom_clip);
}else{
    draw_self();
}
