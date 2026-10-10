function Battle_CallSoulEventBulletCollision() {
	if(Battle_IsBulletValid(id)){
		with(battle_soul){
			event_user(BATTLE_SOUL_EVENT.BULLET_COLLISION);
		}
		return true;
	}else{
		return false;
	}


}

/// @desc Half-size of the editor/runtime soul hurtbox.
/// The spr_battle_soul collision mask is a centred 5x5 rectangle. Attacks
/// which perform their own line/ray tests use this value instead of the old
/// hard-coded five-pixel padding, so every damage path has the same forgiving
/// centre hitbox without creating a separate follower instance.
function Battle_SoulHitboxHalfSize() {
	return 2.5;
}
