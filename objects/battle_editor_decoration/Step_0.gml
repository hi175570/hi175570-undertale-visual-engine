if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

if(!is_struct(data)) exit;
if(struct_exists(data,"warning_kind")){
    elapsed+=global.delta_time_factor;
    if(data.warning_kind=="line"){
        var warning_target=data.warning_target;
        if(is_struct(warning_target)){
            if((variable_struct_exists(warning_target,"_destroyed")&&warning_target._destroyed)||!variable_struct_exists(warning_target,"x")||!variable_struct_exists(warning_target,"y")){instance_destroy();exit;}
            x=warning_target.x;y=warning_target.y;
        }else{
            if(!instance_exists(warning_target)){instance_destroy();exit;}
            x=warning_target.x;y=warning_target.y;
        }
    }
    if(elapsed>=duration) instance_destroy();
    exit;
}
elapsed+=global.delta_time_factor;
var track=data.transform;
layer_mode=data.layer_mode;
depth=layer_mode==BATTLE_EDITOR_LAYER.OUTSIDE?DEPTH_BATTLE.BULLET_OUTSIDE_LOW:DEPTH_BATTLE.BULLET;
var progress=duration>0?clamp(elapsed/max(1,duration),0,1):0;
if(!data.animation.loop&&image_index>=max(0,image_number-1)) image_speed=0;

if(string_length(data.script_name)>0){
    var hook=asset_get_index(data.script_name);
    if(hook>=0) script_execute(hook,id,data,progress);
}
if(duration>0&&progress>=1) instance_destroy();
