if(variable_instance_exists(id,"_battle_editor_runtime_frozen")&&_battle_editor_runtime_frozen) exit;
if(duration>=0){
    _solid_lifetime_age+=global.delta_time_factor;
    if(_solid_lifetime_age>=duration){instance_destroy();exit;}
}

if (enable) {
    angle += rotate * global.delta_time_factor;
    anglex += angxs * global.delta_time_factor;  
    angley += angys * global.delta_time_factor;  
    anglez += angzs * global.delta_time_factor;
    anglexw += angxws * global.delta_time_factor;
    angleyw += angyws * global.delta_time_factor;
    anglezw += angzws * global.delta_time_factor;
    update_vert();
    
    for (var i = 0; i < array_length(edge_list); i++) {
        var _prop = edge_list[i];
        
        // 获取 x1, y1, z1
        var vert_index1 = _prop[0]; // 取出索引
        var vert1 = vert_list_draw[vert_index1]; // 获取 vert_list_draw 中的对应顶点
        var x1 = vert1[0];
        var y1 = vert1[1];
        var z1 = vert1[2];

        // 获取 x2, y2, z2
        var vert_index2 = _prop[1]; // 取出索引
        var vert2 = vert_list_draw[vert_index2]; // 获取 vert_list_draw 中的对应顶点
        var x2 = vert2[0];
        var y2 = vert2[1];
        var z2 = vert2[2];

        // 获取 _bone
        var _bone = _prop[2];

        if (instance_exists(_bone) ) {
            var wz1=world_z+z1;
            var wz2=world_z+z2;
            var visible_edge=true;
            var factor1=1;
            var factor2=1;
            if(perspective3d){
                visible_edge=(perspective_distance+wz1>8) && (perspective_distance+wz2>8);
                factor1=perspective_distance/max(8,perspective_distance+wz1);
                factor2=perspective_distance/max(8,perspective_distance+wz2);
            }
            var screen_x1=x+x1*factor1;
            var screen_y1=y+y1*factor1;
            var screen_x2=x+x2*factor2;
            var screen_y2=y+y2*factor2;
            var trim_amount=max(0,edge_trim);
            var edge_length=max(0,point_distance(screen_x1,screen_y1,screen_x2,screen_y2)-trim_amount);

            // Each projected edge remains a real battle bone, so collision,
            // blue/orange rules and the general C shield all work normally.
            _bone.visible=visible_edge && edge_length>0.5;
            _bone.x=(screen_x1+screen_x2)/2;
            _bone.y=(screen_y1+screen_y2)/2;
            // Board-clipped bullets must be drawn before battle_board composites
            // its surface. Giving them the controller's outside depth made them
            // write to the surface after it had already been displayed, and the
            // next Draw Begin immediately cleared that invisible result.
            if(out == 0){
                _bone.depth=DEPTH_BATTLE.BULLET;
            }else{
                _bone.depth=DEPTH_BATTLE.BULLET_OUTSIDE_LOW+((wz1+wz2)/2)*0.02;
            }
            _bone.length=edge_length;
            _bone.angle=point_direction(screen_x1,screen_y1,screen_x2,screen_y2);
            _bone.type = type;   
            _bone.out = out;
            _bone.editor_damage_enabled=editor_damage_enabled;
            _bone.hp_damage=hp_damage;
            _bone.kr_damage=hp_damage;
            _bone.heal_amount=heal_amount;
            _bone.editor_visual_override=editor_visual_override;
            _bone.editor_visual_color=editor_visual_color;
        }  
    }  
}
