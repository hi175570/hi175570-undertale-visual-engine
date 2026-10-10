time += global.delta_time_factor;

// Both an editor preview and a normally started battle may request revival
// while the game-over typewriter is still printing. Z ends that line, then the
// existing fade and return routing decide whether to restore the editor or
// restart the normal battle; this does not enable editor-only battle shortcuts.
if(!revive_requested&&instance_exists(a)&&Input_IsPressed(INPUT.CONFIRM)){
    revive_requested=true;
    with(a) instance_destroy();
    a=noone;
    time=max(time,300);
}
if (time >= 300 && !instance_exists(a)) {
    image_alpha -= 0.02*global.delta_time_factor;
}
if (time >= 400 && image_alpha <= 0) {
    audio_stop_all();
    BattleEditor_ReturnFromGameOver();
    exit;
}
if(image_alpha<1&&time>=220)image_alpha+=0.01*global.delta_time_factor;
