function BGM_Init() {
	var proc=0;
	repeat(6){
		global._bgm_id[proc]=-1;
		global._bgm_audio[proc]=-1;
		global._bgm_loop_start[proc]=-1;
		global._bgm_loop_end[proc]=-1;
		// Optional logical-frame synchronisation uses GameMaker's native
		// track-position API. It remains part of the existing BGM slot instead
		// of creating a second player for survival battles.
		global._bgm_frame_sync[proc]=false;
		global._bgm_frame_clock[proc]=0;
		proc+=1;
	}


}
