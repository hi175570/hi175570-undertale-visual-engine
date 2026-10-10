event_inherited();

// Battle Start (User Event 11) normally fills these fields, but an editor
// refresh can create an enemy instance one step before that event is sent.
// Give every instance a complete harmless baseline immediately so Step/Draw
// never depend on event ordering or on a freshly-created save slot.
_miss_timer=0;
_gravity_pose_timer=0;
_gravity_pose_duration=16;
_idle_time=0;
_editor_enemy_cache=[];
_editor_enemy_data=[];
_fallback_enemy_data=[];
_editor_enemy_signature="";
_editor_enemy_overrides={};
_editor_enemy_override_revision=0;
_editor_enemy_loaded_project_revision=-1;
_editor_enemy_loaded_override_revision=-1;
_battle_editor_visual_only=false;
_reload_editor_enemies=undefined;
_set_editor_enemy_part=undefined;
