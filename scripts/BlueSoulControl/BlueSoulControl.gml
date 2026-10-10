function BlueSoulControl(dir, impact_speed = 10) {
    Battle_SetSoul(battle_soul_blue);
    battle_soul.impact = 1;
    battle_soul.dir = dir;
    battle_soul.move = impact_speed;
    battle_soul.jump_state = 2;
    battle_soul.on_block = 0;
    battle_soul.on_board = 0;
    battle_soul.on_platform = 0;

    // A gravity throw may drive an enemy pose without coupling the soul code
    // to one specific enemy object. Downward throws use the supplied hand-down
    // frame; other directions stay neutral until matching art is assigned.
    var _gravity_dir=dir;
    with(battle_enemy){
        if(variable_instance_exists(id,"_gravity_pose_timer")){
            // Gravity changes the soul, not the enemy's body pose. Custom
            // projects may still opt into their own direction scripts below.
            _gravity_pose_timer=0;
        }
        BattleEditor_RunEnemyGravityScripts(id,_gravity_dir);
    }
}
