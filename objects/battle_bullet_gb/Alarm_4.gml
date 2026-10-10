// Preserve the original UTE phase speed: one pulse is about 25 frames at 60
// FPS. A pi/3 increment produced a complete cycle every six frames and looked
// like high-frequency flashing rather than a beam breathing effect.
_beam_breath_offset=sin(_beam_sin)*beam_visual_breath_amplitude;
_beam_scale=max(0,_beam_envelope+_beam_breath_offset);
_beam_sin+=0.25*global.delta_time_factor;
alarm[4]=1 / global.delta_time_factor;
