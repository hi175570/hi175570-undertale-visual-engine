function BGM_Step() {
	var proc=0;
	repeat(6){
		var audio=BGM_GetID(proc);
		if(audio_exists(audio)){
			var start=global._bgm_loop_start[proc];
			var endt=global._bgm_loop_end[proc];
			var sync_active=global._bgm_frame_sync[proc]&&audio_is_playing(audio);
			var custom_loop=start>=0&&endt>=0;
			// Normal non-loop-point playback keeps the original zero-query Step
			// cost. Track position is only needed by one of these two features.
			if(sync_active||custom_loop){
				var pos=audio_sound_get_track_position(audio);
				if(sync_active){
					// Cage of Abyss keeps music on the game's logical Step clock: when
					// rendering cannot sustain the configured game speed, the expected
					// track position advances more slowly too. Only seek when drift is
					// audible enough to matter, avoiding a native audio call every Step.
					var step_scale=variable_global_exists("delta_time_factor")?global.delta_time_factor:1;
					global._bgm_frame_clock[proc]+=step_scale;
					var expected=global._bgm_frame_clock[proc]/GAME_FPS;
					if(start>=0&&endt>start&&expected>=endt) expected=start+((expected-endt) mod (endt-start));
					else{
						var source=BGM_GetAudio(proc);
						var source_length=audio_exists(source)?audio_sound_length(source):0;
						if(source_length>0) expected=expected mod source_length;
					}
					if(abs(pos-expected)>=0.02){
						audio_sound_set_track_position(audio,expected);
						pos=expected;
					}
				}
				if(custom_loop&&pos>=endt){
					audio_sound_set_track_position(audio,start+(pos-endt));
				}
			}
			}
		proc+=1;
	}
	return true;


}

/// @arg bgm_slot
/// @arg enabled
/// Enables native track-position correction against the engine's logical
/// GAME_FPS timeline. The source is still played by the normal BGM slot.
function BGM_SetFrameSync(slot,enabled) {
	if(!BGM_IsSlotValid(slot)) return false;
	global._bgm_frame_sync[slot]=bool(enabled);
	global._bgm_frame_clock[slot]=0;
	if(global._bgm_frame_sync[slot]&&BGM_IsPlaying(slot)) audio_sound_set_track_position(BGM_GetID(slot),0);
	return true;
}
