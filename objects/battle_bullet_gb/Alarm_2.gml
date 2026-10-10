
var gb_frame_count=max(1,sprite_get_number(sprite_index));
var gb_last_frame=gb_frame_count-1;
// Every authored frame owns one complete interval. The previous (count-1)
// duration switched to the final-frame flicker on the same tick frame 5 was
// reached, so a six-frame resource visibly behaved like five frames.
var gb_open_time=max(1,gb_frame_count*max(1,editor_gb_frame_interval));

if(fake_mode==1){
    image_index=0;
    editor_gb_opening=true;
    editor_gb_open_elapsed=0;
    audio_stop_sound(snd_gb_fake_release);
    BattleEditor_RuntimePlaySound(snd_gb_fake_release,0,false);
    _beam_alpha=0;
    // A fake GB uses the same opened-mouth loop as a firing GB. It simply has
    // no beam and begins its physical drop when the opening finishes.
    alarm[3]=gb_open_time/global.delta_time_factor;
    alarm[6]=gb_open_time/global.delta_time_factor+1;
    exit;
}

if(fake_mode==2){
    BattleEditor_RuntimePlaySound(snd_damage,0,false);
    Camera_Shake(4,4,1,1,1,1);
    image_index=0;
    _beam_alpha=0;
    alarm[6]=1;
    exit;
}

image_index=0;
editor_gb_opening=true;
editor_gb_open_elapsed=0;
// Scratch source first performs a hard expansion, then repeatedly adds and
// subtracts width. Keep that launch envelope and add a smooth sine breath on
// top instead of replacing either part.
_beam_envelope=beam_visual_launch_scale;
_beam_breath_offset=0;
Anim_Create(id,"_beam_envelope",ANIM_TWEEN.SINE,ANIM_EASE.IN_OUT,_beam_envelope,_beam_scale_default-_beam_envelope,3);

if(!variable_global_exists("battle_editor_seek_audio_silent")||!global.battle_editor_seek_audio_silent||global.battle_editor_seek_audio_exact_birth) audio_stop_sound(snd_gb_release);
BattleEditor_RuntimePlaySound(snd_gb_release,0,0);

_inst=instance_create_depth(x,y,0,battle_bullet_gb_beam);
if(sprite_exists(editor_gb_beam_sprite)){
    _inst.sprite_index=editor_gb_beam_sprite;
    _inst.editor_gb_beam_custom=true;
    _inst.editor_gb_beam_source_direction=editor_gb_beam_source_direction;
    _inst.editor_gb_beam_frame_interval=editor_gb_beam_frame_interval;
    _inst.editor_gb_beam_uses_own_color=editor_gb_beam_uses_own_color;
}
_inst.editor_gb_guarantee_core=editor_gb_builtin_style;
if(variable_instance_exists(id,"_battle_editor_runtime_controller")&&instance_exists(_battle_editor_runtime_controller)) BattleEditor_RuntimeTrack(_battle_editor_runtime_controller,_inst);
_inst.green_guard_blockable=green_guard_blockable;
_inst.green_guard_destroy_on_block=false;
var sid=BattleEditor_RuntimePlaySound(snd_gb_release,0,0);
if(sid>=0) audio_sound_pitch(sid,1.2);

Camera_Shake(5,5,1,1,1,1);
gamepad_set_vibration(0,0.5,0.5);
alarm[11] = 10 / global.delta_time_factor; // 修正：除法而不是乘法
alarm[3] = gb_open_time / global.delta_time_factor;
alarm[4] = 3 / global.delta_time_factor;
alarm[5] = time_release_stay / global.delta_time_factor + 1;
// The Scratch GB starts its post-release offset as the mouth opens and the
// beam is emitted. Waiting until the beam lifetime ended made every configured
// offset look late and unlike the authored source behavior.
alarm[7] = 1 / global.delta_time_factor;
