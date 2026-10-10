draw_set_font(font_mars_needs_cunnilingus);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var hp_max=max(1,Player_GetHpMax());
var hp_natural_max=max(hp_max,Player_GetNaturalHpMax());
var hp=clamp(Player_GetHp(),0,hp_max);
var kr=global.kr ? clamp(Player_GetKr(),0,hp_max-hp) : 0;
var visible_kr=show_kr?kr:0;
var purple_occupancy=clamp(Player_GetPurpleOccupancy(),0,hp_max);
if(heal_tween_active){
    // Sine-out makes the heal immediately readable, then lets the last part
    // settle gently. Yellow growth and purple coverage use one shared amount,
    // so neither colour visually jumps ahead of the other.
    var heal_amount=Anim_GetValue(ANIM_TWEEN.SINE,ANIM_EASE.OUT,clamp(heal_tween_age/max(1,heal_tween_duration),0,1));
    hp=clamp(lerp(heal_tween_start_hp,heal_tween_target_hp,heal_amount),0,hp_max);
    purple_occupancy=clamp(lerp(heal_tween_start_purple,heal_tween_target_purple,heal_amount),0,hp_max);
}
// The physical bar is based on the natural maximum and therefore does not
// shrink when an attack reduces the current maximum. Values above 92 HP are
// proportionally compressed into the same 115-pixel width.
var bar_width=(hp_natural_max<=92) ? hp_natural_max*1.25 : 92*1.25;
var hp_width=bar_width*hp/hp_natural_max;
// Large editor HP totals can make a real KR remainder sub-pixel. Keep at
// least one visible pixel whenever KR exists; the number remains exact.
var kr_width=visible_kr>0?max(1,bar_width*visible_kr/hp_natural_max):0;
var max_hp_loss_width=bar_width*(hp_natural_max-hp_max)/hp_natural_max;
var purple_occupancy_width=purple_occupancy>0?min(hp_width,max(1,bar_width*purple_occupancy/hp_natural_max)):0;
var vitals_x=x+vitals_offset_x;
var vitals_y=y+vitals_offset_y;
var bar_x=vitals_x+245;
var bar_y=vitals_y-1;
var hp_back=make_color_rgb(192,0,0);
var shield_back=make_color_rgb(112,0,0);
var max_hp_loss_color=make_color_rgb(0,96,32);
var kr_color=(kr>0) ? make_color_rgb(255,0,255) : c_white;
// Purple occupancy overlays the right-hand end of current yellow HP and grows
// leftward. KR remains immediately after the HP endpoint and is not displaced.
var purple_occupancy_x=bar_x+hp_width-purple_occupancy_width;
var value_x=bar_x+bar_width+14;

draw_set_color(c_white);
TextTyper_DrawFallback(x+name_offset_x,y+name_offset_y,Player_GetName());
// Keep LV independent from the player name so two-digit levels can move left
// without changing the HP bar position.
TextTyper_DrawFallback(x+126+lv_offset_x,y+lv_offset_y,"LV "+string(Player_GetLv()));
if(show_hp_label) draw_sprite(spr_battle_ui_hp,0,vitals_x+214,vitals_y+4);
if(show_bar){
draw_sprite_ext(spr_pixel,0,bar_x,bar_y,bar_width,20,0,hp_back,1);
draw_sprite_ext(spr_pixel,0,bar_x,bar_y,hp_width,20,0,c_yellow,1);
if(kr_width>0){
    draw_sprite_ext(spr_pixel,0,bar_x+hp_width,bar_y,kr_width,20,0,kr_color,1);
}
// Lost maximum HP grows from the far right toward the left.
if(max_hp_loss_width>0){
    draw_sprite_ext(spr_pixel,0,bar_x+bar_width-max_hp_loss_width,bar_y,max_hp_loss_width,20,0,max_hp_loss_color,1);
}
if(purple_occupancy_width>0){
    draw_sprite_ext(spr_pixel,0,purple_occupancy_x,bar_y,purple_occupancy_width,20,0,make_color_rgb(75,0,130),1);
}
}
// Consumed purple reserve detaches from the bar as one rigid block. Damage is
// already applied; this is visual feedback only and never delays combat logic.
if(purple_drop_active&&purple_drop_alpha>0){
    var old_world=matrix_get(matrix_world);
    var drop_world=matrix_build(purple_drop_x,purple_drop_y,0,0,0,purple_drop_angle,1,1,1);
    matrix_set(matrix_world,matrix_multiply(drop_world,old_world));
    draw_sprite_ext(spr_pixel,0,-purple_drop_width*0.5,-purple_drop_height*0.5,purple_drop_width,purple_drop_height,0,make_color_rgb(75,0,130),purple_drop_alpha);
    matrix_set(matrix_world,old_world);
}
// KR is an independent HUD element and belongs immediately to the right of
// the bar. Keep its sprite visible even while pending KR is zero; only its
// colour changes when a purple remainder exists.
var kr_label_visible=global.kr&&show_kr;
var number_x=value_x;
if(kr_label_visible){
    draw_sprite_ext(spr_battle_ui_kr,0,value_x,vitals_y+4,1,1,0,kr_color,1);
    number_x=value_x+sprite_get_width(spr_battle_ui_kr)+6;
}
if(show_numbers){
    draw_set_color(kr_width>0?kr_color:c_white);
    TextTyper_DrawFallback(number_x,vitals_y,string(round(hp)+visible_kr)+" / "+string(hp_max));
}

if(show_shield&&instance_exists(battle) && battle._shield_enabled){
    var shield_natural_max=max(1,battle._shield_natural_max);
    var shield_ratio=clamp(battle._shield/shield_natural_max,0,1);
    var shield_max_loss_ratio=clamp((shield_natural_max-battle._shield_max)/shield_natural_max,0,1);
    var shield_x=bar_x;
    var shield_y=bar_y+20;
    if(battle._shield_hud_mode==BATTLE_SHIELD_HUD_MODE.SIDE){
        shield_x=vitals_x+495;
        shield_y=bar_y;
    }
    var shield_height=battle._shield_hud_mode==BATTLE_SHIELD_HUD_MODE.SIDE?20:5;
    draw_sprite_ext(spr_pixel,0,shield_x,shield_y,bar_width,shield_height,0,shield_back,1);
    draw_sprite_ext(spr_pixel,0,shield_x,shield_y,bar_width*shield_ratio,shield_height,0,c_lime,1);
    if(shield_max_loss_ratio>0){
        draw_sprite_ext(spr_pixel,0,shield_x+bar_width*(1-shield_max_loss_ratio),shield_y,bar_width*shield_max_loss_ratio,shield_height,0,make_color_rgb(190,190,190),1);
    }
}
