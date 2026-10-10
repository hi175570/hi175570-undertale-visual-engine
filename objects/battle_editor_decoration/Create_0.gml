data=undefined;
elapsed=0;
source_sprite=-1;
owns_sprite=false;

Setup=function(_data){
    data=_data;
    if(struct_exists(data,"warning_kind")){
        elapsed=0;
        source_sprite=-1;
        owns_sprite=false;
        sprite_index=-1;
        duration=max(1,data.duration);
        layer_mode=BATTLE_EDITOR_LAYER.OUTSIDE;
        depth=DEPTH_BATTLE.WARNING;
        if(data.warning_kind=="box"){x=data.warning_x;y=data.warning_y;}
        return true;
    }
    var track=data.transform;
    elapsed=0;
    var loaded=BattleEditor_LoadAnimationSprite(data.sprite_source,data.animation);
    source_sprite=loaded.sprite;
    owns_sprite=loaded.owns;
    sprite_index=source_sprite;
    image_speed=data.animation.fps/max(1,game_get_speed(gamespeed_fps));
    layer_mode=data.layer_mode;
    depth=layer_mode==BATTLE_EDITOR_LAYER.OUTSIDE?DEPTH_BATTLE.BULLET_OUTSIDE_LOW:DEPTH_BATTLE.BULLET;
    x=track.x;
    y=track.y;
    image_xscale=track.scale_x;
    image_yscale=track.scale_y;
    image_angle=track.angle;
    image_alpha=track.alpha;
    image_blend=data.visual_tint.enabled?data.visual_tint.color:c_white;
    duration=data.duration;
};
