event_inherited();
data=undefined;
elapsed=0;
source_sprite=-1;
owns_sprite=false;

Setup=function(_data){
    data=_data;
    var track=data.transform;
    elapsed=0;
    var loaded=BattleEditor_LoadAnimationSprite(data.sprite_source,data.animation,true);
    source_sprite=loaded.sprite;
    owns_sprite=loaded.owns;
    sprite_index=source_sprite;
    mask_index=source_sprite;
    image_speed=data.animation.fps/max(1,game_get_speed(gamespeed_fps));
    out=data.layer_mode;
    type=data.damage_profile.type;
    x=track.x;
    y=track.y;
    image_xscale=track.scale_x;
    image_yscale=track.scale_y;
    image_angle=track.angle;
    image_alpha=track.alpha;
    duration=data.duration;
    editor_visual_override=data.visual_tint.enabled&&!data.visual_tint.follow_damage_profile;
    editor_visual_color=data.visual_tint.color;
    if(data.visual_tint.enabled) image_blend=data.visual_tint.follow_damage_profile?BattleEditor_ColorForType(data.damage_profile.type):editor_visual_color;
};
