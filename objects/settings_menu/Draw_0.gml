draw_set_font(font_menu);
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
draw_set_color(c_white);
TextTyper_DrawFallbackTransformed(display_get_gui_width()/2,62,"设置",2.5,2.5,0);

var zone=Storage_GetSettings().Get("general");
draw_set_halign(fa_left);
for(var i=0;i<array_length(option_names);i++){
    var yy=option_start_y+option_spacing*i;
    var selected=(i==choice);
    draw_set_color(selected ? c_yellow : c_white);
    TextTyper_DrawFallbackTransformed(190,yy,option_names[i],1.65,1.65,0);
    if(i==scale_option_index){
        draw_set_color(c_aqua);
        TextTyper_DrawFallbackTransformed(390,yy,global.window_scale==0?"适应屏幕":string(round(global.window_scale*100))+"%",1.65,1.65,0);
    }else if(i==save_option_index){
        var save_caption=active_save_name!=""?active_save_name:"没有可用存档";
        if(string_length(save_caption)>18) save_caption=string_copy(save_caption,1,18)+"...";
        draw_set_color(active_save_name!=""?c_aqua:c_gray);
        TextTyper_DrawFallbackTransformed(390,yy,save_caption,1.25,1.25,0);
    }else{
        var enabled=zone.Get(option_flags[i],false);
        draw_set_color(enabled ? c_lime : c_gray);
        TextTyper_DrawFallbackTransformed(430,yy,enabled ? "开启" : "关闭",1.65,1.65,0);
    }
}

draw_sprite_ext(spr_battle_soul,0,162,selector_y,1,1,0,c_red,1);
draw_set_halign(fa_center);
draw_set_color(c_gray);
TextTyper_DrawFallbackTransformed(display_get_gui_width()/2,448,"方向键选择　左右或 Z 切换存档 / 设置　X / Shift 返回",1.05,1.05,0);
if(choice==scale_option_index){
    TextTyper_DrawFallbackTransformed(320,422,window_get_fullscreen()?"窗口比例已记住；F4 退出全屏后应用":"保持比例整体放大；超过屏幕时自动适配",1,1,0);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
