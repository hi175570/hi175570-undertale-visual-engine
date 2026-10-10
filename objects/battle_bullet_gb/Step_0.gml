if(editor_gb_opening){
    var gb_open_frame_count=max(1,sprite_get_number(sprite_index));
    var gb_open_interval=max(1,editor_gb_frame_interval);
    image_index=min(gb_open_frame_count-1,floor(editor_gb_open_elapsed/gb_open_interval));
    editor_gb_open_elapsed+=global.delta_time_factor;
}

if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

if (place_meeting(x, y, battle_soul_yellow_bullet) && type == 4 && yellow_shootable) {
    var obj = instance_place(x, y, battle_soul_yellow_bullet);
    instance_destroy(obj);
    instance_destroy();
}
// Do not delete a retreating head until its rotated bounding box is fully
// outside the room. Centre-position checks visibly popped large GBs early.
if ((bbox_right < 0 || bbox_left > room_width || bbox_bottom < 0 || bbox_top > room_height) && _beam_alpha<=0) {
    instance_destroy();
    if (instance_exists(_inst)) instance_destroy(_inst);
}
