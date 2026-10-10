if (!follow) {
    Anim_Create(id, "angle", move_tween, move_ease, angle_start, angle_target - angle_start, time_move);
    Anim_Create(id, "x", move_tween, move_ease, x, x_target - x, time_move);
    Anim_Create(id, "y", move_tween, move_ease, y, y_target - y, time_move);
} else {
    Anim_Create(id, "_angle", move_tween, move_ease, angle_start, angle_target - angle_start, time_move);
    Anim_Create(id, "_x", move_tween, move_ease, _x, x_target - _x, time_move);
    Anim_Create(id, "_y", move_tween, move_ease, _y, y_target - _y, time_move);
}
if(!variable_global_exists("battle_editor_seek_audio_silent")||!global.battle_editor_seek_audio_silent||global.battle_editor_seek_audio_exact_birth) audio_stop_sound(snd_gb_charge);
BattleEditor_RuntimePlaySound(snd_gb_charge, 0, 0);
alarm[1] = editor_gb_force_release?1:(time_move + time_release_delay)/global.delta_time_factor + 1;
