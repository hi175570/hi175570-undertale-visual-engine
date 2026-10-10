function Battle_End() {
	var room_return=Storage_GetTempGeneral().Get(FLAG_TEMP_BATTLE_ROOM_RETURN);
	if(!room_exists(room_return)){
		show_message($"Room to return doesn't exist: {room_return}!");
		return false;
	}
	
	fader.alpha=1;
	BattleEditor_EffectsReset();
	display_set_gui_size(640,480);
	if(surface_exists(application_surface)) surface_resize(application_surface,640,480);
	room_goto(room_return);
	Fader_Fade(-1,0,20);
	BGM_Resume(0);
	BGM_SetVolume(0,0);
	BGM_SetVolume(0,1,50);
	return true;
}
