// Enemy bubbles and targeting use enemy_data.x/y. Idle sway belongs only to
// the shared visual renderer, so it cannot drag combat anchors around.
if(variable_instance_exists(id,"_editor_enemy_data")&&array_length(_editor_enemy_data)>0){
    if(array_length(_editor_enemy_cache)>0){
        var enemy_data=_editor_enemy_data[0];
        BattleEditor_DrawEnemyVisual(enemy_data,_editor_enemy_cache[0],enemy_data.x,enemy_data.y,_idle_time);
    }
}
