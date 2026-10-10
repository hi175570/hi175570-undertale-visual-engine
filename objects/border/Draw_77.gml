draw_set_alpha(1);
surface_set_target(application_surface);
draw_surface(global.surface_gui,0,0)
surface_reset_target();
if (_enabled) {
    var SW = (window_get_fullscreen() ? display_get_width() : window_get_width());
    var SH = (window_get_fullscreen() ? display_get_height() : window_get_height());
    var SX = SW / 960;
    var SY = SH / 540;
    var SF = min(SX, SY);
    display_set_gui_maximize(SF, SF, (SW - 960 * SF) / 2 + 160 * SF, (SH - 540 * SF) / 2 + 30 * SF);

    if (sprite_exists(_sprite_previous)) {
        draw_sprite_ext(_sprite_previous, 0, (SW - 960 * SF) / 2, (SH - 540 * SF) / 2, 960 / sprite_get_width(_sprite_previous) * SF, 540 / sprite_get_height(_sprite_previous) * SF, 0, c_white, 1);
    } else {
        draw_sprite_ext(spr_pixel, 0, (SW - 960 * SF) / 2, (SH - 540 * SF) / 2, SW, SH, 0, c_black, 1);
    }

    if (sprite_exists(_sprite)) {
        draw_sprite_ext(_sprite, 0, (SW - 960 * SF) / 2, (SH - 540 * SF) / 2, 960 / sprite_get_width(_sprite) * SF, 540 / sprite_get_height(_sprite) * SF, 0, c_white, _alpha);
    } else {
        draw_sprite_ext(spr_pixel, 0, (SW - 960 * SF) / 2, (SH - 540 * SF) / 2, SW, SH, 0, c_black, _alpha);
    }
    if (blur) {
        var _surface = _kawase.GetSurface();
        surface_set_target(_surface);
        draw_clear_alpha(c_black, 0);
        draw_surface(application_surface, 0, 0);
		draw_surface(global.surface_gui,0,0);
        surface_reset_target();
        _kawase.Blur(4);
        draw_surface_ext(_surface, (SW - 960 * SF) / 2 + SF * 32, (SH - 540 * SF) / 2 - SF * 48, SF * 1.4, SF * 1.4, 0, c_white, 0.5 * _alpha);
        _sprite = spr_border_simple;
    }
    if (round(global.blur_amount)) {
        var _surface = _kawase.GetSurface();
        surface_set_target(_surface);
        draw_clear_alpha(c_black, 0);
        draw_set_alpha(1);
        draw_surface(application_surface, 0, 0);
        surface_reset_target();
        _kawase.Blur(round(global.blur_amount),global.blur_strength);
        draw_set_color(c_white);
        BattleEditor_DrawFinalSurface(_surface, (SW - 960 * SF) / 2 + 160 * SF, (SH - 540 * SF) / 2 + 30 * SF, SF, SF, 0, c_white, 1);
    } else BattleEditor_DrawFinalSurface(application_surface, (SW - 960 * SF) / 2 + 160 * SF, (SH - 540 * SF) / 2 + 30 * SF, SF, SF, 0, c_white, 1);
} else {
    var SW = (window_get_fullscreen() ? display_get_width() : window_get_width());
    var SH = (window_get_fullscreen() ? display_get_height() : window_get_height());
    var SX = SW / 640;
    var SY = SH / 480;
    var SF = min(SX, SY);
    display_set_gui_maximize(SF, SF, (SW - 640 * SF) / 2, (SH - 480 * SF) / 2);
    // Menus use the original 320x240 logical room while battles/editors use
    // 640x480. Scale from the actual application-surface dimensions so a
    // persistent menu does not occupy only the upper-left half after leaving
    // the editor.
    var APP_W=max(1,surface_get_width(application_surface));
    var APP_H=max(1,surface_get_height(application_surface));
    var CONTENT_SX=640/APP_W*SF;
    var CONTENT_SY=480/APP_H*SF;
    if (round(global.blur_amount)) {
        var _surface = _kawase.GetSurface();
        surface_set_target(_surface);
        draw_clear_alpha(c_black, 0);
        draw_set_alpha(1);
        draw_surface_ext(application_surface,0,0,640/APP_W,480/APP_H,0,c_white,1);
        surface_reset_target();
        _kawase.Blur(round(global.blur_amount),global.blur_strength);
        draw_set_color(c_white);
        BattleEditor_DrawFinalSurface(_surface, (SW - 640 * SF) / 2, (SH - 480 * SF) / 2, SF, SF, 0, c_white, 1);
    } else BattleEditor_DrawFinalSurface(application_surface, (SW - 640 * SF) / 2, (SH - 480 * SF) / 2, CONTENT_SX, CONTENT_SY, 0, c_white, 1);
}
surface_set_target(global.surface_gui);
draw_clear_alpha(c_white, 0);
surface_reset_target();

// Editor chrome is a native-resolution overlay, outside ALL game effects.
if(instance_exists(battle_editor)) BattleEditor_DrawUiOverlay(instance_find(battle_editor,0));

// This must be drawn after the application surface is composited; an ordinary
// Draw GUI object is otherwise covered by the border's final blit.
if(os_type==os_windows){
    // Draw GUI End is the native-pixel final backbuffer, not the logical GUI.
    var cursor_x=window_mouse_get_x();
    var cursor_y=window_mouse_get_y();
    draw_sprite_ext(spr_battle_soul,0,cursor_x+3,cursor_y+3,0.55,0.55,225,c_red,1);
}

// Border performs the final application-surface blit, so this is the one
// overlay location that remains visible in ordinary rooms and the editor.
if(variable_global_exists("show_fps")&&global.show_fps){
    var fps_y=instance_exists(battle_editor)?58:4;
    var fps_label="FPS "+global.fps_display_text;
    draw_set_alpha(1);
    draw_set_font(font_menu);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    TextTyper_DrawFallback(6,fps_y+2,fps_label);
    draw_set_color(c_lime);
    TextTyper_DrawFallback(4,fps_y,fps_label);
    draw_set_color(c_white);
}
