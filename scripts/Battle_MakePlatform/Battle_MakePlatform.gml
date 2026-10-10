function Battle_MakePlatform(x, y, width, angle, hspeed, vspeed, sticky = 0, bounce = 0, duration = -1, auto_destroy = 1) {
    var a = instance_create_depth(x, y, 0, battle_platform);
    a.sticky = sticky;
    a.width = max(4,width);
    // Set the collision scale immediately; Draw repeats this assignment so a
    // scripted width animation also updates both Nine Slice visual and mask.
    a.image_xscale = a.width / sprite_get_width(sticky ? spr_battle_platform_green : spr_battle_platform_purple);
    a.angle = angle;
    a.hspeed = hspeed * global.delta_time_factor;
    a.vspeed = vspeed * global.delta_time_factor;
    a.bounce = bounce;
    a.auto_destroy = auto_destroy;
    a.duration = duration;
    return a;
}
