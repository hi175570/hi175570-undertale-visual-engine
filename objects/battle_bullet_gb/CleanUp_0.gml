if(instance_exists(_inst)){
	instance_destroy(_inst);
}
if(editor_gb_owned_sprite&&sprite_exists(sprite_index)) sprite_delete(sprite_index);
if(editor_gb_owned_beam_sprite&&sprite_exists(editor_gb_beam_sprite)) sprite_delete(editor_gb_beam_sprite);
if(!instance_exists(battle_bullet_gb)){
	gamepad_set_vibration(0,0,0);
}
