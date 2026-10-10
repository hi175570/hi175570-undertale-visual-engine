/// @desc Battle Start - initialize the reusable mechanism test encounter.
_test_phase=0;
_miss_timer=0;
_gravity_pose_timer=0;
_gravity_pose_duration=16;
_idle_time=0;
// Match the supplied 640x480 reference layout.  Its visible Sans bounds are
// 104x139; the supplied layered rig's union is 212x324.
_character_scale_x=104/212;
_character_scale_y=139/324;
// The supplied cutouts share a source origin at (480,360). Their neutral
// visible union is (376,332)-(588,656), centred at (482,494). Keep x/y as the
// visible centre of the complete rig, and offset the source canvases once.
_rig_draw_offset_x=(480-482)*_character_scale_x;
_rig_draw_offset_y=(360-494)*_character_scale_y;
_dust_body_sprite=asset_get_index("spr_enemy_dust_body");
if(_dust_body_sprite<0) _dust_body_sprite=asset_get_index("spr_enemy_bigrock_body");
_dust_legs_sprite=asset_get_index("spr_enemy_dust_legs");
_dust_head_sprite=asset_get_index("spr_enemy_dust_head");
if(_dust_head_sprite<0) _dust_head_sprite=asset_get_index("spr_enemy_bigrock_head");
_dust_face_sprite=asset_get_index("spr_enemy_dust_face_eyes");
_editor_enemy_cache=[];
_editor_enemy_data=[];
_editor_enemy_overrides={};
_editor_enemy_override_revision=0;
_editor_enemy_loaded_project_revision=-1;
_editor_enemy_loaded_override_revision=-1;
// A normal Encounter does not have battle_editor_project_runtime. Give it the
// same complete default rig instead of leaving the enemy instance invisible.
var fallback_enemy_project=BattleEditor_ProjectNormalize(BattleEditor_NewProject());
_fallback_enemy_data=fallback_enemy_project.initialization.enemies;
_editor_enemy_signature="";
_set_editor_enemy_part=function(enemy_uid,part_key,resource){
    if(is_undefined(resource)||!is_struct(resource)) return false;
    var override=json_parse(json_stringify(resource));
    override.runtime_start=_idle_time;
    variable_struct_set(_editor_enemy_overrides,string(enemy_uid)+"|"+part_key,override);
    _editor_enemy_override_revision+=1;
    _reload_editor_enemies(true);
    return true;
};
_reload_editor_enemies=function(force=false){
    var runtime_project=variable_global_exists("battle_editor_project_runtime")
        ?global.battle_editor_project_runtime
        :fallback_enemy_project;
    var enemy_data_list=runtime_project.initialization.enemies;
    if(array_length(enemy_data_list)<=0){
        if(array_length(_editor_enemy_data)>0) _editor_enemy_data=[];
        return;
    }
    // Every live enemy owns only its own six-part rig. Loading all authored
    // enemies into every instance scales as N squared (15 enemies became 225
    // complete rigs) and made the editor needlessly expensive.
    var enemy_index=clamp(_enemy_slot,0,array_length(enemy_data_list)-1);
    var enemy_data=enemy_data_list[enemy_index];
    var project_revision=variable_global_exists("battle_editor_enemy_visual_revision")?global.battle_editor_enemy_visual_revision:0;
    var same_enemy_data=array_length(_editor_enemy_data)>0&&_editor_enemy_data[0]==enemy_data;
    if(!force&&same_enemy_data&&project_revision==_editor_enemy_loaded_project_revision&&_editor_enemy_override_revision==_editor_enemy_loaded_override_revision) return;
    _editor_enemy_data=[enemy_data];
    for(var old_enemy_index=0;old_enemy_index<array_length(_editor_enemy_cache);old_enemy_index++){
        var old_cache=_editor_enemy_cache[old_enemy_index];
        if(!is_struct(old_cache)||!struct_exists(old_cache,"owned")) continue;
        for(var old_sprite_index=0;old_sprite_index<array_length(old_cache.owned);old_sprite_index++) if(sprite_exists(old_cache.owned[old_sprite_index])) sprite_delete(old_cache.owned[old_sprite_index]);
    }
    _editor_enemy_cache=[];
    var part_keys=BattleEditor_EnemyPartKeys();
    var sprites={};var parts={};var owned=[];
    for(var part_index=0;part_index<array_length(part_keys);part_index++){
        var part_key=part_keys[part_index];
        var part=BattleEditor_EnemyPartResolved(runtime_project,enemy_data,part_key);
        var override_key=string(enemy_data.uid)+"|"+part_key;
        if(variable_struct_exists(_editor_enemy_overrides,override_key)){
            var override=variable_struct_get(_editor_enemy_overrides,override_key);
            var runtime_part=json_parse(json_stringify(part));
            runtime_part.source=override.path;runtime_part.animation=override.animation;
            runtime_part.runtime_start=override.runtime_start;
            part=runtime_part;
        }
        if(!struct_exists(part,"runtime_start")) part.runtime_start=0;
        var loaded=BattleEditor_LoadEnemyPartSprite(part);
        if(loaded.owns&&sprite_exists(loaded.sprite)) array_push(owned,loaded.sprite);
        variable_struct_set(sprites,part_key,sprite_exists(loaded.sprite)?loaded.sprite:-1);
        variable_struct_set(parts,part_key,part);
    }
    _editor_enemy_cache=[{sprites:sprites,parts:parts,owned:owned}];
    _editor_enemy_loaded_project_revision=project_revision;
    _editor_enemy_loaded_override_revision=_editor_enemy_override_revision;
};
_reload_editor_enemies(true);
if(variable_global_exists("battle_editor_project_runtime")){
    var editor_layout=global.battle_editor_project_runtime.initialization;
    var editor_enemy_index=clamp(_enemy_slot,0,max(0,array_length(editor_layout.enemies)-1));
    var editor_enemy_data=editor_layout.enemies[editor_enemy_index];
    x=editor_enemy_data.x;
    y=editor_enemy_data.y;
}else{
    x=320;
    y=166;
}
// Extra enemies 4..15 are visual/script-controlled actors only. They must not
// rewrite the stock three-slot target menu or restart battle state while the
// editor synchronizes them.
if(variable_instance_exists(id,"_battle_editor_visual_only")&&_battle_editor_visual_only) exit;
_round_menu_texts=["* 第一回合"];
if(variable_global_exists("battle_editor_project_runtime")) BattleEditor_ApplyInitialization(global.battle_editor_project_runtime);
else{
    Player_SetNaturalHpMax(114514);
    Player_SetHpMax(114514);
    Player_SetHp(114514);
    Player_SetKr(0);
    Battle_ShieldConfigure(100,30,BATTLE_SHIELD_HUD_MODE.BELOW_HP,true,15,0);
    // Standalone test-room fallback only. An editor project owns its actual
    // item list; never overwrite freshly-applied Initialization data with the
    // old hard-coded test inventory.
    Battle_EnableSurvivalItems([],true);
    var test_items=Item_GetInventoryItems();
    test_items.Clear();
    test_items.Add(ITEM_TEST_CANDY);
    test_items.Add(ITEM_TEST_CANDY);
    test_items.Add(ITEM_TEST_NOODLES);
    test_items.Add(ITEM_TEST_NOODLES);
    test_items.Add(ITEM_TEST_STEAK);
    test_items.Add(ITEM_TEST_STEAK);
    test_items.Add(ITEM_TEST_PIE);
    test_items.Add(ITEM_TEST_PIE);
}
// The test enemy uses the supplied cutout material. The neutral pose is held
// still; gravity control briefly selects a directional gesture.
var encounter_enemy_name="大石头";
if(variable_global_exists("battle_editor_project_runtime")&&array_length(global.battle_editor_project_runtime.initialization.enemies)>0){
    var encounter_enemy_index=clamp(_enemy_slot,0,array_length(global.battle_editor_project_runtime.initialization.enemies)-1);
    encounter_enemy_name=global.battle_editor_project_runtime.initialization.enemies[encounter_enemy_index].name;
}
Battle_SetEnemyName(_enemy_slot,encounter_enemy_name);
Battle_SetEnemyCenterPos(_enemy_slot,x,y);
if(variable_global_exists("battle_editor_project_runtime")){
    var start_editor_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
    var start_enemy_index=clamp(_enemy_slot,0,array_length(start_editor_project.initialization.enemies)-1);
    var start_actions=start_editor_project.initialization.enemies[start_enemy_index].actions;
    Battle_SetEnemyActionNumber(_enemy_slot,min(6,array_length(start_actions)));
    for(var start_action_index=0;start_action_index<6;start_action_index++) Battle_SetEnemyActionName(_enemy_slot,start_action_index,start_action_index<array_length(start_actions)?start_actions[start_action_index].name:"");
    BattleEditor_ApplyTurnPresentation(start_editor_project,BattleEditor_ResolveMonsterTurn(start_editor_project,max(1,Battle_GetTurnNumber()+1)));
}else{
    Battle_SetEnemyActionNumber(_enemy_slot,3);
    Battle_SetEnemyActionName(_enemy_slot,0,"查看");
    Battle_SetEnemyActionName(_enemy_slot,1,"测试");
    Battle_SetEnemyActionName(_enemy_slot,2,"下一回合");
    Battle_SetMenuDialog(_round_menu_texts[0]);
}
// Begin at the normal player menu. Finishing any player action starts the
// next test attack; after that attack the menu is shown again.
Battle_SetNextState(BATTLE_STATE.MENU);
