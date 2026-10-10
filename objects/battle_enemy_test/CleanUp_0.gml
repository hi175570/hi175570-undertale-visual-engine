if(variable_instance_exists(id,"_editor_enemy_cache")){
    for(var enemy_cache_index=0;enemy_cache_index<array_length(_editor_enemy_cache);enemy_cache_index++){
        var enemy_cache=_editor_enemy_cache[enemy_cache_index];
        for(var owned_sprite_index=0;owned_sprite_index<array_length(enemy_cache.owned);owned_sprite_index++) if(sprite_exists(enemy_cache.owned[owned_sprite_index])) sprite_delete(enemy_cache.owned[owned_sprite_index]);
    }
}
