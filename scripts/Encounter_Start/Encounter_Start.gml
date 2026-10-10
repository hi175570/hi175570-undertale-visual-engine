function Encounter_Start(encounter,anim=true,exclam=true) {
	if(Encounter_IsExists(encounter)){
		if(!instance_exists(char_player)){
			anim=false;
		}
		// The title's normal Start path first plays encounter_anim, so waiting
		// for the later anim=false room transition left that path using stale
		// in-memory editor data. Load once before the transition animation; a
		// direct anim=false call still loads when no transition host exists.
		if(encounter==0&&(anim||!instance_exists(encounter_anim))){
			BattleEditor_LoadSavedProjectForBattle();
			BattleEditor_EffectsReset();
		}
		if(!anim){
			if(Encounter_IsPauseBGM(encounter)){
				BGM_Pause(0);
			}
			Storage_GetTempGeneral().Set(FLAG_TEMP_ENCOUNTER,encounter);
			if(!Player_IsInBattle()){
				Storage_GetTempGeneral().Set(FLAG_TEMP_BATTLE_ROOM_RETURN,room);
				room_persistent=true;
			}
			// The title room is 320x240, while the battle room is 640x480.
			// BattleEditor_Exit deliberately restores the smaller menu surface;
			// restore the full-resolution target before entering battle or the
			// 320x240 surface is enlarged and the whole battle looks pixelated.
			display_set_gui_size(640,480);
			if(surface_exists(application_surface)) surface_resize(application_surface,640,480);
			room_goto(room_battle);
		}else{
			var inst=instance_create_depth(0,0,0,encounter_anim);
			inst._encounter=encounter;
			inst._exclam=exclam;
			inst._quick=Encounter_IsQuick(encounter);
			inst._soul_x=Encounter_GetSoulX(encounter);
			inst._soul_y=Encounter_GetSoulY(encounter);
		}
		return true;
	}else{
		show_debug_message($"Encounter ID {encounter} doesn't exists!");
		return false;
	}


}
