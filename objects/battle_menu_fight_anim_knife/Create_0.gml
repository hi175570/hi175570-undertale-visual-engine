depth=DEPTH_BATTLE.UI;
out=1;
image_speed=1;
var _knife_sound=variable_instance_exists(id,"sound_override")?sound_override:snd_slice;
if(_knife_sound>=0) BattleEditor_RuntimePlaySound(_knife_sound,0,false);
