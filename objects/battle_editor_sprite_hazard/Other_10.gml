if(!is_struct(data)) exit;
if(!BattleEditor_ClipCollisionAllowed(id,other.x,other.y)) exit;
var profile=data.damage_profile;
var input_moving=Input_IsHeld(INPUT.UP)||Input_IsHeld(INPUT.DOWN)||Input_IsHeld(INPUT.LEFT)||Input_IsHeld(INPUT.RIGHT);
switch(profile.type){
    case 0: Player_HurtColor(profile.type,profile.damage,false); break;
    case 1: if(input_moving) Player_HurtColor(profile.type,profile.damage,false); break;
    case 2: if(!input_moving) Player_HurtColor(profile.type,profile.damage,false); break;
    case 3: Player_Heal(max(0,profile.heal_amount)); audio_play_sound(snd_item_heal,0,false); instance_destroy(); break;
    case 4: Player_HurtColor(profile.type,profile.damage,false); break;
    case 5: if(!Battle_ShieldAbsorb()) Player_ReduceMaxHp(profile.damage); break;
    case 6: Player_HurtColor(6,Player_GetHpMax(),true); break;
    case 7:
    case 8: Player_HurtColor(profile.type,profile.damage,false); break;
}
