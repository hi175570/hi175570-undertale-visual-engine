// A normal window close or room teardown must persist edits even when the
// author never performed a formal named save. Incremental records cover hard
// crashes during editing; this final compact checkpoint closes the remaining
// gap when teardown happens before the idle journal timer fires.
if(variable_instance_exists(id,"project")&&BattleEditor_RuntimeSnapshotSessionOwned()){
    BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(BattleEditor_ProjectSparseForStorage(project)),"current");
}
BattleEditor_AudioPreviewStop(id);
if(surface_exists(editor_ui_surface)) surface_free(editor_ui_surface);
camera_destroy(editor_ui_camera);
if(variable_global_exists("battle_editor_ui_controller")) global.battle_editor_ui_controller=noone;
BattleEditor_RuntimeStop(id);
BattleEditor_SetInputCapture(false);
BattleEditor_DestroyPreviewFrames(id);
if(variable_instance_exists(id,"enemy_editor_cache")) BattleEditor_FreeEnemyVisualCache(enemy_editor_cache);
if(variable_instance_exists(id,"gb_style_sprite_cache")) BattleEditor_FreeGBStyleSpriteCache(gb_style_sprite_cache);
if(variable_instance_exists(id,"gb_style_beam_sprite_cache")) BattleEditor_FreeGBStyleSpriteCache(gb_style_beam_sprite_cache);
keyboard_string = "";
if (os_type == os_windows) keyboard_virtual_hide();
window_set_cursor(cr_none);
