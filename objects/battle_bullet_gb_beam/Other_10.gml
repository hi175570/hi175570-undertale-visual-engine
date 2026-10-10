var input_moving=Input_IsHeld(INPUT.UP)||Input_IsHeld(INPUT.DOWN)||Input_IsHeld(INPUT.LEFT)||Input_IsHeld(INPUT.RIGHT);
switch (type) {
    case 0:
        if(editor_damage_enabled) Player_HurtColor(type,hp_damage,false);
        else Player_HurtKr();
        break;
    case 1:
        if (input_moving) {
           if(editor_damage_enabled) Player_HurtColor(type,hp_damage,false);
           else Player_HurtKr();
        }
        break;
    case 2:
        if (!input_moving) {
            if(editor_damage_enabled) Player_HurtColor(type,hp_damage,false);
            else Player_HurtKr();
        }
        break;
    case 3:
        Player_Heal(max(0,heal_amount));
        audio_play_sound(snd_item_heal,0,false);
        disposable=1;
        break;
	case 4:
		if(yellow_heavy) Player_HurtColor(4,yellow_hp_damage,false);
		else if(editor_damage_enabled) Player_HurtColor(type,hp_damage,false);
		else Player_HurtKr();
		disposable=1
        break;
    case 5:
        // Green attacks damage the player's max HP only when the general C
        // shield is not active. Blocking one never reduces shield maximum.
        if(!Battle_ShieldAbsorb()) Player_ReduceMaxHp(editor_damage_enabled?max(1,hp_damage):1);
        break;
    case 6:
        Player_HurtColor(6,Player_GetHpMax(),true);
        break;
    case 7:
    case 8:
        if(editor_damage_enabled) Player_HurtColor(type,hp_damage,false);
        else Player_HurtKr();
        break;
}

if (disposable) {
    instance_destroy();
}
