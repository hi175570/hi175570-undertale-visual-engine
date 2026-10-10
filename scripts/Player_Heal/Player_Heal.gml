function Player_Heal(heal) {
	if(heal<0){
		return Player_Hurt(-heal);
	}
	if(heal>0){
		var old_hp=Player_GetHp();
		var old_purple=Player_GetPurpleOccupancy();
		// Healing restores yellow HP normally. Purple occupancy is deliberately
		// harder to cleanse: every two points of healing erase one purple point.
		// Full yellow HP does not prevent the remaining healing power from being
		// used for that separate purple calculation.
		Player_HealPurpleOccupancy(heal);
		var hp=min(Player_GetHpMax(),old_hp+heal);
		Player_SetHp(hp);
		BattleUI_StartHealTween(old_hp,hp,old_purple,Player_GetPurpleOccupancy());
	}
	return true;
}
