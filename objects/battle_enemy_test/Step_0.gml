// Self-heal instances loaded from an older room/save where the new editor
// fields did not exist yet. Create initializes normal instances; these guards
// keep hot reload and legacy instances safe as well.
if(!variable_instance_exists(id,"_miss_timer")) _miss_timer=0;
if(!variable_instance_exists(id,"_gravity_pose_timer")) _gravity_pose_timer=0;
if(!variable_instance_exists(id,"_idle_time")) _idle_time=0;
if(!variable_instance_exists(id,"_editor_enemy_cache")) _editor_enemy_cache=[];
if(!variable_instance_exists(id,"_reload_editor_enemies")) _reload_editor_enemies=undefined;

if(_miss_timer>0) _miss_timer=max(0,_miss_timer-global.delta_time_factor);
if(_gravity_pose_timer>0) _gravity_pose_timer=max(0,_gravity_pose_timer-global.delta_time_factor);
_idle_time+=global.delta_time_factor;
if(is_callable(_reload_editor_enemies)) _reload_editor_enemies(false);
