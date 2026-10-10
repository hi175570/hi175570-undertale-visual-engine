///@arg state
function Battle_SetState() {
	var STATE=argument[0];

	battle._state=STATE;

	//菜单
	if(STATE==BATTLE_STATE.MENU){
		Battle_SetNextState(BATTLE_STATE.DIALOG);
	
		Battle_SetMenuChoiceEnemy(0,false);
		Battle_SetMenuChoiceAction(0,false);
		Battle_SetMenu(BATTLE_MENU.BUTTON,false);
		// BOARD_RESETTING animates the ordinary wrapper dimensions, but a script
		// may have replaced the real mainboard with an ellipse or polygon. At the
		// player-menu boundary restore the complete authored rectangle and colour,
		// not only x/y/half-extents.
		BattleEditor_ForceRestorePlayerBoard();
	
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.MENU_START);
	}

	//对话
	if(STATE==BATTLE_STATE.DIALOG){
		Battle_SetNextState(BATTLE_STATE.TURN_PREPARATION);
	
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.DIALOG_START);
	}

	//回合准备
	if(STATE==BATTLE_STATE.TURN_PREPARATION){
		Battle_SetNextState(BATTLE_STATE.IN_TURN);
	
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.TURN_PREPARATION_START);
	
		if(instance_exists(battle_turn)){
			with(battle_turn){
				event_user(BATTLE_TURN_EVENT.TURN_PREPARATION_START);
			}
		}
	
		Battle_SetTurnTime(Battle_GetTurnInfo(BATTLE_TURN.TIME,0));
	
		battle_soul.x=battle_board.x+Battle_GetTurnInfo(BATTLE_TURN.SOUL_X,0);
		battle_soul.y=battle_board.y+Battle_GetTurnInfo(BATTLE_TURN.SOUL_Y,0);
	
		var X_OLD=battle_board.x;
		var Y_OLD=battle_board.y;
		var UP_OLD=battle_board.up;
		var DOWN_OLD=battle_board.down;
		var LEFT_OLD=battle_board.left;
		var RIGHT_OLD=battle_board.right;
		var ANGLE_OLD=battle_board.angle;
		var X_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_X,BATTLE_BOARD.X)-X_OLD;
		var Y_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_Y,BATTLE_BOARD.Y)-Y_OLD;
		var UP_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_UP,BATTLE_BOARD.UP)-UP_OLD;
		var DOWN_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_DOWN,BATTLE_BOARD.DOWN)-DOWN_OLD;
		var LEFT_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_LEFT,BATTLE_BOARD.LEFT)-LEFT_OLD;
		var RIGHT_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RIGHT,BATTLE_BOARD.RIGHT)-RIGHT_OLD;
		var ANGLE_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_ANGLE,0)-ANGLE_OLD;
		var MOVE_TWEEN=Battle_GetTurnInfo(BATTLE_TURN.BOARD_MOVE_TWEEN,ANIM_TWEEN.LINEAR);
		var MOVE_EASE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_MOVE_EASE,ANIM_EASE.OUT);
		var MOVE_MODE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_MOVE_MODE,BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED);
		var MOVE_SPEED=Battle_GetTurnInfo(BATTLE_TURN.BOARD_MOVE_SPEED,10);
		var MOVE_DURATION=Battle_GetTurnInfo(BATTLE_TURN.BOARD_MOVE_DURATION,30);
		var SIZE_TWEEN=Battle_GetTurnInfo(BATTLE_TURN.BOARD_SIZE_TWEEN,ANIM_TWEEN.LINEAR);
		var SIZE_EASE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_SIZE_EASE,ANIM_EASE.OUT);
		var SIZE_MODE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_SIZE_MODE,BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED);
		var SIZE_SPEED=Battle_GetTurnInfo(BATTLE_TURN.BOARD_SIZE_SPEED,10);
		var SIZE_DURATION=Battle_GetTurnInfo(BATTLE_TURN.BOARD_SIZE_DURATION,30);
	
		if(MOVE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED){
			Anim_Create(battle_board,"x",MOVE_TWEEN,MOVE_EASE,X_OLD,X_CHANGE,round(abs(X_CHANGE/MOVE_SPEED)));
			Anim_Create(battle_board,"y",MOVE_TWEEN,MOVE_EASE,Y_OLD,Y_CHANGE,round(abs(Y_CHANGE/MOVE_SPEED)));
			Anim_Create(battle_board,"angle",MOVE_TWEEN,MOVE_EASE,ANGLE_OLD,ANGLE_CHANGE,round(abs(ANGLE_CHANGE/MOVE_SPEED)));
		}else{
			Anim_Create(battle_board,"x",MOVE_TWEEN,MOVE_EASE,X_OLD,X_CHANGE,MOVE_DURATION);
			Anim_Create(battle_board,"y",MOVE_TWEEN,MOVE_EASE,Y_OLD,Y_CHANGE,MOVE_DURATION);
			Anim_Create(battle_board,"angle",MOVE_TWEEN,MOVE_EASE,ANGLE_OLD,ANGLE_CHANGE,MOVE_DURATION);
		}
		if(SIZE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED){
			Anim_Create(battle_board,"up",SIZE_TWEEN,SIZE_EASE,UP_OLD,UP_CHANGE,round(abs(UP_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"down",SIZE_TWEEN,SIZE_EASE,DOWN_OLD,DOWN_CHANGE,round(abs(DOWN_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"left",SIZE_TWEEN,SIZE_EASE,LEFT_OLD,LEFT_CHANGE,round(abs(LEFT_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"right",SIZE_TWEEN,SIZE_EASE,RIGHT_OLD,RIGHT_CHANGE,round(abs(RIGHT_CHANGE/SIZE_SPEED)));
		}else{
			Anim_Create(battle_board,"up",SIZE_TWEEN,SIZE_EASE,UP_OLD,UP_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"down",SIZE_TWEEN,SIZE_EASE,DOWN_OLD,DOWN_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"left",SIZE_TWEEN,SIZE_EASE,LEFT_OLD,LEFT_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"right",SIZE_TWEEN,SIZE_EASE,RIGHT_OLD,RIGHT_CHANGE,SIZE_DURATION);
		}
	}

	//回合内
	if(STATE==BATTLE_STATE.IN_TURN){
		Battle_SetNextState(BATTLE_STATE.BOARD_RESETTING);
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.TURN_START);
	
		if(instance_exists(battle_turn)){
			with(battle_turn){
				event_user(BATTLE_TURN_EVENT.TURN_START);
			}
		}
	}

	//面版重置
	if(STATE==BATTLE_STATE.BOARD_RESETTING){
		Battle_SetNextState(BATTLE_STATE.MENU);
		// Quarter-turn rectangles are visually identical after their four local
		// extents are remapped. Normalize first, then animate only the actual
		// position/size difference to the mandatory player-turn rectangle.
		BattleEditor_CanonicalizeRectBoardQuarterTurn();
	
		var X_OLD=battle_board.x;
		var Y_OLD=battle_board.y;
		var UP_OLD=battle_board.up;
		var DOWN_OLD=battle_board.down;
		var LEFT_OLD=battle_board.left;
		var RIGHT_OLD=battle_board.right;
		var ANGLE_OLD=battle_board.angle;
		var X_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_X,BATTLE_BOARD.X)-X_OLD;
		var Y_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_Y,BATTLE_BOARD.Y)-Y_OLD;
		var UP_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_UP,BATTLE_BOARD.UP)-UP_OLD;
		var DOWN_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_DOWN,BATTLE_BOARD.DOWN)-DOWN_OLD;
		var LEFT_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_LEFT,BATTLE_BOARD.LEFT)-LEFT_OLD;
		var RIGHT_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_RIGHT,BATTLE_BOARD.RIGHT)-RIGHT_OLD;
		var ANGLE_CHANGE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_ANGLE,0)-ANGLE_OLD;
		var MOVE_TWEEN=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_MOVE_TWEEN,ANIM_TWEEN.LINEAR);
		var MOVE_EASE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_MOVE_EASE,ANIM_EASE.OUT);
		var MOVE_MODE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_MOVE_MODE,BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED);
		var MOVE_SPEED=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_MOVE_SPEED,10);
		var MOVE_DURATION=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_MOVE_DURATION,30);
		var SIZE_TWEEN=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_SIZE_TWEEN,ANIM_TWEEN.LINEAR);
		var SIZE_EASE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_SIZE_EASE,ANIM_EASE.OUT);
		var SIZE_MODE=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_SIZE_MODE,BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED);
		var SIZE_SPEED=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_SIZE_SPEED,10);
		var SIZE_DURATION=Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_SIZE_DURATION,30);
		// Wrapper x/y/extents already animate during a normal turn exit. A circle
		// or polygon must animate its actual contour as well; otherwise the custom
		// mainboard ignores those fields and snaps only when MENU starts.
		var MOVE_RETURN_FRAMES=MOVE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED
			?max(abs(X_CHANGE),abs(Y_CHANGE),abs(ANGLE_CHANGE))/max(0.001,abs(MOVE_SPEED))
			:MOVE_DURATION;
		var SIZE_RETURN_FRAMES=SIZE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED
			?max(abs(UP_CHANGE),abs(DOWN_CHANGE),abs(LEFT_CHANGE),abs(RIGHT_CHANGE))/max(0.001,abs(SIZE_SPEED))
			:SIZE_DURATION;
		BattleEditor_StartPlayerBoardReturnMorph(
			Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_UP,BATTLE_BOARD.UP),
			Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_DOWN,BATTLE_BOARD.DOWN),
			Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_LEFT,BATTLE_BOARD.LEFT),
			Battle_GetTurnInfo(BATTLE_TURN.BOARD_RESET_RIGHT,BATTLE_BOARD.RIGHT),
			max(1,round(max(MOVE_RETURN_FRAMES,SIZE_RETURN_FRAMES))),SIZE_TWEEN,SIZE_EASE);
	
		if(MOVE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED){
			Anim_Create(battle_board,"x",MOVE_TWEEN,MOVE_EASE,X_OLD,X_CHANGE,round(abs(X_CHANGE/MOVE_SPEED)));
			Anim_Create(battle_board,"y",MOVE_TWEEN,MOVE_EASE,Y_OLD,Y_CHANGE,round(abs(Y_CHANGE/MOVE_SPEED)));
			Anim_Create(battle_board,"angle",MOVE_TWEEN,MOVE_EASE,ANGLE_OLD,ANGLE_CHANGE,round(abs(ANGLE_CHANGE/MOVE_SPEED)));
		}else{
			Anim_Create(battle_board,"x",MOVE_TWEEN,MOVE_EASE,X_OLD,X_CHANGE,MOVE_DURATION);
			Anim_Create(battle_board,"y",MOVE_TWEEN,MOVE_EASE,Y_OLD,Y_CHANGE,MOVE_DURATION);
			Anim_Create(battle_board,"angle",MOVE_TWEEN,MOVE_EASE,ANGLE_OLD,ANGLE_CHANGE,MOVE_DURATION);
		}
		if(SIZE_MODE==BATTLE_TURN_BOARD_TRANSFORM_MODE.SPEED){
			Anim_Create(battle_board,"up",SIZE_TWEEN,SIZE_EASE,UP_OLD,UP_CHANGE,round(abs(UP_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"down",SIZE_TWEEN,SIZE_EASE,DOWN_OLD,DOWN_CHANGE,round(abs(DOWN_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"left",SIZE_TWEEN,SIZE_EASE,LEFT_OLD,LEFT_CHANGE,round(abs(LEFT_CHANGE/SIZE_SPEED)));
			Anim_Create(battle_board,"right",SIZE_TWEEN,SIZE_EASE,RIGHT_OLD,RIGHT_CHANGE,round(abs(RIGHT_CHANGE/SIZE_SPEED)));
		}else{
			Anim_Create(battle_board,"up",SIZE_TWEEN,SIZE_EASE,UP_OLD,UP_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"down",SIZE_TWEEN,SIZE_EASE,DOWN_OLD,DOWN_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"left",SIZE_TWEEN,SIZE_EASE,LEFT_OLD,LEFT_CHANGE,SIZE_DURATION);
			Anim_Create(battle_board,"right",SIZE_TWEEN,SIZE_EASE,RIGHT_OLD,RIGHT_CHANGE,SIZE_DURATION);
		}
	
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.BOARD_RESETTING_START);
	}

	return true;


}
