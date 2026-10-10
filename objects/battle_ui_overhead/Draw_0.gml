if(!instance_exists(owner)){
    instance_destroy();
    exit;
}
if(!owner.show_overhead||!instance_exists(battle_soul)) exit;

draw_set_font(font_mars_needs_cunnilingus);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var overhead_max=max(1,Player_GetHpMax());
var overhead_hp_value=clamp(Player_GetHp(),0,overhead_max);
var overhead_kr=global.kr&&owner.show_kr?clamp(Player_GetKr(),0,overhead_max-overhead_hp_value):0;
var overhead_hp=string(overhead_hp_value+overhead_kr);
var overhead_rest=" / "+string(overhead_max);
if(instance_exists(battle)&&battle._shield_enabled) overhead_rest+=" / "+string(round(battle._shield));
var overhead_width=TextTyper_StringWidthFallback(overhead_hp+overhead_rest);
var overhead_x=battle_soul.x-overhead_width*0.5;
var overhead_y=battle_soul.y-30;
draw_set_color(overhead_kr>0?make_color_rgb(255,0,255):c_white);
TextTyper_DrawFallback(overhead_x,overhead_y,overhead_hp);
draw_set_color(c_white);
TextTyper_DrawFallback(overhead_x+TextTyper_StringWidthFallback(overhead_hp),overhead_y,overhead_rest);
