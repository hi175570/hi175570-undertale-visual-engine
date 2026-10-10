alarm[4]=-1;
if(fake_mode==0){
    _beam_closing=true;
    _beam_close_complete=false;
    _beam_breath_offset=0;
    // Closing is visible instead of popping: narrow and fade the beam while
    // the head fades and retreats over the same tail interval.
    var fade_time=10;
    Anim_Create(id,"_beam_envelope",ANIM_TWEEN.SINE,ANIM_EASE.IN_OUT,_beam_envelope,-_beam_envelope,fade_time);
    Anim_Create(id,"_beam_scale",ANIM_TWEEN.SINE,ANIM_EASE.IN_OUT,_beam_scale,-_beam_scale,fade_time);
    Anim_Create(id,"_beam_alpha",ANIM_TWEEN.SINE,ANIM_EASE.IN_OUT,_beam_alpha,-_beam_alpha,fade_time);
    Anim_Create(id,"image_alpha",ANIM_TWEEN.SINE,ANIM_EASE.IN_OUT,image_alpha,-image_alpha,fade_time);
}else{
    _beam_alpha=0;
    _beam_close_complete=true;
}
alarm[7]=1/global.delta_time_factor;
