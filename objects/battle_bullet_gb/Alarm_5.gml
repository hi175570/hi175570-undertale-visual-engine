alarm[6]=time_beam_end_delay / global.delta_time_factor + 1;
// Alarm 2 already started the source-compatible recoil when firing began.
// Keep the step alarm alive while Alarm 6 starts the visible narrowing.
alarm[7]=1 / global.delta_time_factor;
