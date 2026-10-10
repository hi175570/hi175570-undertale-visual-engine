function Battle_EndMenu() {
	if(Battle_GetState()==BATTLE_STATE.MENU){
		Battle_SetMenu(-1,false);
	
		var BUTTON=Battle_GetMenuChoiceButton();
		var MERCY=Battle_GetMenuChoiceMercy();
	
		//使用物品
		if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.ITEM){
			var index=Battle_GetMenuChoiceItem();
			var items=Item_GetInventoryItems();
			var itemId=items.Get(index);
			battle._menu_item_used_last=itemId;
			items.InvokeItemUse(index);
		}
	
		if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.FIGHT){
			if(instance_exists(battle_menu_fight)){
				with(battle_menu_fight){
					event_user(BATTLE_MENU_FIGHT_EVENT.END);
				}
			}
		}
	
		//计算逃跑
		if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.MERCY && MERCY==BATTLE_MENU_CHOICE_MERCY.FLEE){
			if(Battle_IsMenuMercyFleeEnabled()){
				// The editor exposes whether FLEE exists, not a hidden success roll.
				// Once the player selects an enabled FLEE entry it always succeeds.
				Battle_SetFleeable(true);
			}else{
				Battle_SetFleeable(false);
			}
		}
	
		//调用事件
		Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.MENU_END);

		// MERCY keeps the original enemy event as the authority for whether an
		// enemy is actually spared. This optional text is only the authored game
		// response; it does not create a second spare/flee ruleset.
		if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.MERCY && MERCY==BATTLE_MENU_CHOICE_MERCY.SPARE){
			var spare_response=string(BattleEditor_RuntimeMercyValue("mercy_spare_response",""));
			if(string_length(string_trim(spare_response))>0){
				Dialog_Add(TextTyper_CompileMarkup(spare_response).text);
				Dialog_Start();
			}
		}
	
		if(Battle_GetEnemyNumber()>0){
			//逃跑
			if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.MERCY && MERCY==BATTLE_MENU_CHOICE_MERCY.FLEE && Battle_IsFleeable()){
				Battle_SetState(BATTLE_STATE.RESULT);
				Battle_SetNextState(BATTLE_STATE.RESULT);
				instance_create_depth(0,0,0,battle_result_flee);
			
				var EXP=Battle_GetRewardExp();
				var GOLD=Battle_GetRewardGold();
				var custom_flee_success=string(BattleEditor_RuntimeMercyValue("mercy_flee_success_text",""));
				var text="";
				if(string_length(string_trim(custom_flee_success))>0){
					text=TextTyper_CompileMarkup(custom_flee_success).text;
				}else if(GOLD==0&&EXP==0){
					var rand=irandom(20);
					var fled_text="* 成功逃跑了……";
					if(rand<2){
						fled_text="* 我先走一步。";
					}else if(rand==2){
						fled_text="* 我还有更重要的事要做。";
					}else if(rand==3){
						fled_text="* 别拖我的后腿。";
					}else{
						fled_text="* 成功逃跑了……";
					}
					text+=fled_text;
				}else{
					text+="{define `EXP` "+string(EXP)+"}"+"{define `GOLD` "+string(GOLD)+"}";
					text+="* 逃跑时带走了 {insert EXP} 点 EXP&  和 {insert GOLD} G。";
				}
				if(GOLD!=0||EXP!=0){
					Player_SetExp(Player_GetExp()+Battle_GetRewardExp());
					Player_SetGold(Player_GetGold()+Battle_GetRewardGold());
					if(Player_UpdateLv()){
						
						audio_play_sound(snd_level_up,0,false);
					}
				}
				Battle_SetDialog(text,true);
			}else{
				if(BUTTON==BATTLE_MENU_CHOICE_BUTTON.MERCY && MERCY==BATTLE_MENU_CHOICE_MERCY.FLEE){
					var custom_flee_fail=string(BattleEditor_RuntimeMercyValue("mercy_flee_fail_text",""));
					if(string_length(string_trim(custom_flee_fail))>0){
						Dialog_Add(TextTyper_CompileMarkup(custom_flee_fail).text);
						Dialog_Start();
					}
				}
				Battle_GotoNextState();
			}
		}
		return true;
	}else{
		return false;
	}


}
