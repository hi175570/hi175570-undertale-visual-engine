//生成实例
instance_create_depth(0,0,0,battle_fader);
instance_create_depth(0,0,0,battle_board);
instance_create_depth(0,0,0,battle_ui);
instance_create_depth(32,432,0,battle_button_fight);
instance_create_depth(185,432,0,battle_button_act);
instance_create_depth(345,432,0,battle_button_item);
instance_create_depth(500,432,0,battle_button_mercy);
Battle_SetSoul(battle_soul_red);

var BGM=Encounter_GetBGM(_encounter);
var BGM_FRAME_SYNC=false;
// Encounter 0 is backed by the editor save. Empty means a deliberate "none",
// while both bundled snd... assets and imported streams use the normal BGM
// slot and its volume/stop/fade behaviour.
if(_encounter==0&&variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)){
	var editor_music_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
	var editor_music_name=string(editor_music_project.initialization.battle_music);
	BGM=string_length(string_trim(editor_music_name))>0?BattleEditor_ResolveSoundAsset(editor_music_name):-1;
	BGM_FRAME_SYNC=editor_music_project.initialization.battle_music_frame_sync;
}
if(audio_exists(BGM)){
	BGM_Play(5,BGM);
	BGM_SetFrameSync(5,BGM_FRAME_SYNC);
}else{
	BGM_SetFrameSync(5,false);
}

//初始化敌人
var proc=0;
repeat(3){
	Battle_SetEnemy(_enemy_object[proc],proc);
	proc+=1;
}

Battle_SetNextState(BATTLE_STATE.MENU);

//调用事件
Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.BATTLE_START);

Battle_GotoNextState();
