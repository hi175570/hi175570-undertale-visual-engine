///@desc Anim
if(Battle_GetMenuFightDamage()>=0){
	var ENEMY=Battle_ConvertMenuChoiceEnemyToEnemySlot(Battle_GetMenuChoiceEnemy());
	var X=Battle_GetEnemyCenterPosX(ENEMY);
	var Y=Battle_GetEnemyCenterPosY(ENEMY);
	// A custom-drawn enemy can have no sprite_index and still has a perfectly
	// valid hit position. The player's attack gets the cut animation only; it
	// must not create an enemy knife-wave bullet.
	instance_create_depth(X,Y,0,battle_menu_fight_anim_knife);
}
