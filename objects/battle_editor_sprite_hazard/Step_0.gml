if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

event_inherited();
if(!is_struct(data)) exit;
elapsed+=global.delta_time_factor;
var track=data.transform;
var progress=duration>0?clamp(elapsed/max(1,duration),0,1):0;
if(data.visual_tint.enabled){
    image_blend=data.visual_tint.follow_damage_profile?BattleEditor_ColorForType(type):image_blend;
}else image_blend=c_white;
if(!data.animation.loop&&image_index>=max(0,image_number-1)) image_speed=0;
if(duration>0&&progress>=1) instance_destroy();
