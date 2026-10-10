///@arg bgm_slot
function BGM_Stop() {
	var SLOT=argument[0];

	if(BGM_IsSlotValid(SLOT)){
		global._bgm_frame_sync[SLOT]=false;
		global._bgm_frame_clock[SLOT]=0;
		if(BGM_IsPlaying(SLOT)){
			audio_stop_sound(BGM_GetID(SLOT));
			return true;
		}else{
			return false;
		}
	}else{
		return false;
	}


}
