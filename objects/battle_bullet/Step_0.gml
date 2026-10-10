if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;

var soul_collision=place_meeting(x,y,battle_soul);
if(!soul_collision&&variable_instance_exists(id,"bone_style")&&round(real(bone_style))==1) soul_collision=Battle_BoneSpikeTipCollision(id,battle_soul)!=noone;
if (out!=2&&soul_collision) {
    Battle_CallSoulEventBulletCollision();
}

var yellow_collision=instance_place(x,y,battle_soul_yellow_bullet);
if(yellow_collision==noone&&variable_instance_exists(id,"bone_style")&&round(real(bone_style))==1) yellow_collision=Battle_BoneSpikeTipCollision(id,battle_soul_yellow_bullet);
if (out!=2&&yellow_collision!=noone && type == 4 && yellow_shootable) {
    var obj = yellow_collision;
    instance_destroy(obj);
    instance_destroy();
}
if(path_function!=noone){
path_function();
}
