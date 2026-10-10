function Battle_EndTurn() {
	if(Battle_GetState()==BATTLE_STATE.IN_TURN){
		Battle_SetTurnNumber(Battle_GetTurnNumber()+1);
	
		/*var LAST=Battle_ConvertMenuChoiceEnemyToEnemySlot(Battle_GetMenuChoiceEnemy());
		var proc=0;
		repeat(3){
			if(proc!=LAST){
				Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.TURN_END,proc);
			}
			proc+=1;
		}*/
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.TURN_END);
	
		if(instance_exists(battle_turn)){
			with(battle_turn){
				event_user(BATTLE_TURN_EVENT.TURN_END);
			}
		}
	
		if(instance_exists(battle_bullet)){
			with(battle_bullet){
				event_user(BATTLE_BULLET_EVENT.TURN_END);
			}
		}

		// Soul modes belong to the monster turn that selected them. Always
		// return to red before the board-reset/menu/dialogue sequence begins,
		// including turns ended early with the editor's Space/Escape shortcut.
		Battle_SetSoul(battle_soul_red);
		// Moving to red keeps the former world position. A timeline/control
		// script may have left that position inside the monster board, so force
		// the replacement soul onto the currently selected player-menu button.
		// This is the authoritative turn-exit path, not an editor-only key path.
		BattleEditor_RestoreSoulToMenuButton();
	
		Battle_GotoNextState();
		return true;
	}else{
		return false;
	}


}
