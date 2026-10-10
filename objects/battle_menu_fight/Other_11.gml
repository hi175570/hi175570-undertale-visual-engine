///@desc Damage
var ENEMY_SLOT=Battle_ConvertMenuChoiceEnemyToEnemySlot(Battle_GetMenuChoiceEnemy());
var TARGET=Battle_GetEnemy(ENEMY_SLOT);
// A freshly rebuilt target menu can momentarily leave the choice index stale.
// MISS still belongs to the first live enemy instead of silently disappearing.
if(!instance_exists(TARGET)){
	for(var target_slot=0;target_slot<3;target_slot++){
		var candidate=Battle_GetEnemy(target_slot);
		if(instance_exists(candidate)){TARGET=candidate;break;}
	}
}
// The editor's placeholder enemy deliberately has no combat HP.  It is a
// visual target only, so both an untouched timing bar and a confirmed strike
// resolve to the stock MISS animation.  Real enemies keep the normal rule.
var FORCE_EDITOR_MISS=instance_exists(TARGET)&&TARGET.object_index==battle_enemy_test;
if((Battle_GetMenuFightDamage()<=0||FORCE_EDITOR_MISS) && instance_exists(TARGET)){
	if(FORCE_EDITOR_MISS) Battle_SetMenuFightDamage(0);
	if(variable_instance_exists(TARGET,"_miss_timer")) TARGET._miss_timer=35;
	// Use the engine's original MISS image and its existing pop/fall animation.
	// The target owns only the temporary hide timer; no font-rendered MISS is
	// drawn by the enemy itself.
	// Snapshot the enemy root now. battle_damage keeps xstart/ystart, so the
	// MISS animation will not follow later enemy movement.
	var MISS=instance_create_depth(TARGET.x,TARGET.y,DEPTH_BATTLE.UI_HIGH,battle_damage);
	MISS.damage=0;
	MISS.bar_visible=false;
	MISS.display_time=35;
	MISS.xstart=TARGET.x;
	MISS.ystart=TARGET.y;
	MISS.visible=true;
	// Restart the stock pop/fall lifetime after all MISS fields are assigned.
	MISS.alarm[0]=1;
	Battle_SetMenuFightDamageTime(35);
}
