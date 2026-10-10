var STATE = Battle_GetState();
var MENU = Battle_GetMenu();
if (STATE == BATTLE_STATE.IN_TURN || STATE == BATTLE_STATE.TURN_PREPARATION || (STATE == BATTLE_STATE.MENU && MENU != BATTLE_MENU.FIGHT_AIM && MENU != BATTLE_MENU.FIGHT_ANIM && MENU != BATTLE_MENU.FIGHT_DAMAGE)) {
    draw_self();
}
if (STATE == BATTLE_STATE.IN_TURN) {
    draw_sprite_ext(sprite_index, 0, x, y, 1.6, 1.6, image_angle, image_blend, init_alpha);
	draw_sprite_ext(spr_soul_light, image_index, x, y, light_size * 0.08, light_size * 0.08, image_angle, image_blend, !global.classic_ui);
	draw_sprite_ext(spr_soul_guangbiao, index, x, y, light_size, light_size, 0, c_white, !global.classic_ui)
	if(true_knife_hit_fx>0){
		var knife_fx_progress=1-true_knife_hit_fx/14;
		var knife_fx_alpha=1-knife_fx_progress;
		var knife_fx_radius=12+knife_fx_progress*34;
		draw_set_alpha(knife_fx_alpha);
		draw_set_color(c_white);
		draw_line_width(x+lengthdir_x(knife_fx_radius,true_knife_hit_angle+180),y+lengthdir_y(knife_fx_radius,true_knife_hit_angle+180),x+lengthdir_x(knife_fx_radius,true_knife_hit_angle),y+lengthdir_y(knife_fx_radius,true_knife_hit_angle),3);
		draw_set_color(c_red);
		draw_circle(x,y,knife_fx_radius,false);
		draw_set_alpha(1);
		draw_set_color(c_white);
	}
}
