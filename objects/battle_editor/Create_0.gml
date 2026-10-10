project = BattleEditor_LoadEditorStartupProject();
editor_ui_drawing=false;
editor_ui_surface=-1;
editor_ui_scale_x=1;editor_ui_scale_y=1;
editor_ui_camera=camera_create_view(0,0,640,480,0,noone,-1,-1,-1,-1);
// The editable main board is the Initialization board itself.  A scene drag,
// vertex edit or inspector change must therefore become the next monster
// turn's default immediately; only the runtime BattleBoard struct is a preview.
main_board_preview=project.initialization.board;
// The active path is derived from the portable save folder beside this build.
project_path = BattleEditor_DefaultProjectPath();
global.battle_editor_project_runtime = project;
global.battle_editor_project_live_from_editor = true;
depth = DEPTH_BATTLE.WARNING - 100;

// Open on New Object. It covers less of the scene than Initialization and is
// the useful visual landing page; authors can still switch to Initialization
// first when preparing a new battle.
tab = 0;
workspace_open = false; // View state only; never stored in a battle/save.
initialization_page = 0;
initialization_scroll = 0;
initialization_scroll_key = "0";
initialization_turn_dropdown = false;
initialization_enemy_page = 0;
battle_music_dropdown_open = false;
battle_music_scroll = 0;
selected_enemy = 0;
enemy_list_scroll = 0;
selected_enemy_part = 0;
selected_enemy_action = 0;
selected_gb_style = -1;
selected_gb_style_frame = 0;
gb_style_sprite_cache = [];
gb_style_beam_sprite_cache = [];
gb_style_editor_page = 0; // 0 body frames, 1 beam, 2 one-shot firing preview
selected_gb_beam_variant = 0;
selected_gb_beam_frame = 0;
gb_style_preview_playing = false;
gb_style_preview_time = 0;
// Independent enemy rig editor. It shares the battle renderer/cache format,
// but owns a centred authoring canvas and never changes world coordinates.
enemy_editor_open = false;
enemy_editor_cache = {sprites:{},parts:{},owned:[]};
enemy_editor_cache_dirty = true;
enemy_editor_selected_part = 0;
enemy_editor_selected_resource = -1;
enemy_editor_resource_scroll = 0;
enemy_editor_part_menu_open = false;
enemy_editor_resource_menu_open = false;
enemy_editor_frame_index = 0;
enemy_editor_preview_playing = false;
enemy_editor_preview_time = 0;
enemy_editor_dragging = false;
enemy_editor_drag_offset_x = 0;
enemy_editor_drag_offset_y = 0;
enemy_editor_drag_start_mouse_x = 0;
enemy_editor_drag_start_mouse_y = 0;
enemy_editor_drag_start_part_x = 0;
enemy_editor_drag_start_part_y = 0;
enemy_editor_pan_x = 207;
enemy_editor_pan_y = 250;
enemy_editor_zoom = 1;
enemy_editor_panning = false;
enemy_editor_pan_button = 0;
enemy_editor_pan_grab_x = 0;
enemy_editor_pan_grab_y = 0;
enemy_editor_rename_resource = -1;
developer_turn_dropdown = false;
developer_turn = project.settings.developer_turn;
tool = 0;
hazard_palette = false;
object_palette = true;
object_palette_category = 0;
object_palette_category_open = false;
create_layer_mode = BATTLE_EDITOR_LAYER.IN_BOARD;
// Layer defaults belong to the chosen preset: ordinary sprite hazards begin
// inside the board, while GB / Slash / True Knife begin outside.  This flag is
// set only when the author deliberately changes "new object layer" during the
// current palette session, so an old choice cannot silently contaminate the
// next object.
create_layer_user_set = false;
wave_inspector_phase = 0;
wave_inspector_section = 0;
board_palette = false;
board_edit_session = false;
selected = -1;
selected_item = -1;
item_scroll = 0;
init_layout_open = false;
init_player_open = false;
hud_settings_open = false;
selected_frame = -2;
selected_animation_frame = -1;
cursor_time = 0;
timeline_dragging = false;
timeline_live_seek_time = -1;
timeline_live_seek_target = 0;
timeline_live_seek_pending = false;
timeline_effective_duration_cache = BattleEditor_EffectiveDuration(project,developer_turn);
timeline_duration_cache = max(60,timeline_effective_duration_cache);
timeline_duration_cache_time = current_time;
timeline_duration_dirty = false;
timeline_live_seek_next_time = 0;
turn_presentation_signature = "";
// Scrubbing is a real replay from the next monster turn's post-dialogue zero.
// It freezes at the requested frame as a UI-visible "half play" snapshot.
timeline_seek_active = false;
timeline_seek_target = 0;
timeline_half_play = false;
timeline_full_play = false;
timeline_reseek_requested = false;
// Every object placed or pasted during one frozen-timeline editing session
// remains directly editable until that session is explicitly exited. This
// transient UID set is never saved into the project.
new_object_preview_uids = [];
scene_objects_visible = project.settings.editor_show_objects;
playing = false;
playhead = 0;
runtime_instances = [];
keep_board_on_stop = true;
preserve_paused_board = false;
fired = [];
dragging = false;
drag_target = false;
drag_mode = "";
drag_offset_x = 0;
drag_offset_y = 0;
context_open = false;
context_x = 0;
context_y = 0;
context_event = -1;
context_frame = -2;
context_submenu = false;
context_anchor_x = 0;
context_anchor_y = 0;
editor_clipboard = undefined;
editor_clipboard_kind = "";
blank_hold = false;
blank_hold_frames = 0;
box_selecting = false;
box_start_x = 0;
box_start_y = 0;
box_end_x = 0;
box_end_y = 0;
multi_events = [];
multi_frames = [];
group_selection_active = false;
group_selection_type = "";
group_selection_control_id = "";
last_scene_click_uid = -1;
last_scene_click_time = -10000;
// Repeated clicks through one overlapping hit stack select front to back and
// wrap. The stack resets only when the next click has no object in common.
scene_click_cycle_uids = [];
group_drag_members = [];
group_drag_primary_x = 0;
group_drag_primary_y = 0;
script_pan_x = 36;
script_pan_y = 58;
script_zoom = 1;
script_drag_mode = "";
script_drag_list = -1;
script_stack_drag = undefined;
script_palette_open = true;
script_palette_progress = 1;
script_palette_category = 0;
script_palette_scroll = 0;
script_layout_revision = 0;
script_layout_cache = {};
script_drag_offset_x = 0;
script_drag_offset_y = 0;
script_selected_list = -1;
script_selected_step = -1;
// Workspace Inspector selection changes are staged: the current detail card
// retracts first, then the newly selected list/step expands.  This is one
// shared transition, not a per-list animation object.
script_inspector_anim_progress = 0;
script_inspector_anim_phase = 0;
script_inspector_pending_list = -1;
script_inspector_pending_step = -1;
script_inspector_last_list = -1;
script_inspector_last_step = -1;
script_step_sound_open = false;
script_step_warning_open = false;
script_dropdown = "";
script_target_scroll = 0;
script_target_popup_left = 300;
script_item_scroll = 0;
script_action_entry_scroll = 0;
script_parameter_scroll = 0;
script_create_scroll = 0;
script_create_choice_scroll = 0;
script_create_choice_path = "";
script_create_choice_kind = "";
script_parameter_choice_scope = "";
script_parameter_choice_index = -1;
script_screen_action_scroll = 0;
script_parameter_key = "";
script_context_open = false;
script_context_x = 0;
script_context_y = 0;
script_context_world_x = 0;
script_context_world_y = 0;
script_context_list = -1;
script_context_step = -1;
script_context_header = false;
script_template_scroll = 0;
script_sound_scroll = 0;
script_enemy_resource_scroll = 0;
script_value_target_scroll = 0;
script_value_property_scroll = 0;
script_formula_variable_scroll = 0;
script_formula_target = "";
script_formula_buffer = "";
script_formula_insert_caret = 0;
formula_field_hit_regions = [];
input_field_hit_regions = [];
// Function-path preview is an editor-only overlay. Cache sampled points and
// rebuild only after authoring input, never once per Draw frame.
script_function_preview_uid = -1;
script_function_preview_dirty = true;
script_function_preview_signature = "";
script_function_preview_data = {valid:true,points:[],parameter_name:"t"};
script_clipboard = [];
script_list_clipboard = undefined;
script_link_drag = false;
script_link_source_list = -1;
script_link_source_step = -1;
script_runtime_states = [];
script_timer_fired = [];
script_vertex_animations = [];
script_patterns = [];
script_monster_turn = 1;
script_vertex_pick = false;
script_vertex_pick_list = -1;
script_vertex_pick_step = -1;
script_variables_open = false;
script_selected_variable = -1;
script_variable_scroll = 0;
right_vertex_drag = false;
drag_vertex_index = -1;
focus_field = "";
focus_last_field = "";
focus_numeric_base = 0;
focus_expression_base = "";
// Single-line fields keep their own edit buffer and caret. keyboard_string is
// only the current OS/IME composition, so the author can insert text in the
// middle instead of being forced to append at the end.
focus_edit_buffer = "";
focus_edit_caret = 0;
focus_keyboard_seen = "";
focus_keyboard_anchor = 0;
focus_formula_validation_signature = "";
focus_formula_validation = {valid:true,error:"",error_pos:0};
input_capture_frames = 0;
deferred_click = false;
deferred_click_x = 0;
deferred_click_y = 0;
text_editor_open = false;
// Windows text input/IME is armed once per editor session. Re-showing the
// virtual input context every Step interrupts IME and Emoji-panel commits.
text_editor_ime_active = false;
// Snapshot of GameMaker's accumulating Windows text input.  Do not clear
// keyboard_string after every character: an IME or the Emoji panel may need
// several Windows messages to commit one Unicode codepoint.
text_editor_keyboard_seen = "";
// Caret position at which the current keyboard_string / IME composition was
// inserted. keyboard_string may rewrite its entire composition ("ni" ->
// "你"), so the editor replaces this range instead of only appending.
text_editor_keyboard_anchor = 0;
text_editor_target = "";
text_editor_buffer = "";
text_editor_hex = "#FF6060FF";
text_editor_focus = "text";
text_editor_help = false;
text_editor_error = "";
text_editor_markup_source = chr(0);
text_editor_preview = noone;
text_editor_preview_frames = 0;
text_editor_preview_mode = false;
text_editor_caret = 0;
text_editor_hex_caret = string_length(text_editor_hex);
text_editor_hex_keyboard_seen = "";
text_editor_hex_keyboard_anchor = text_editor_hex_caret;
color_picker_open = false;
color_picker_target = "color";
color_picker_hue = 0;
color_picker_saturation = 255;
color_picker_value = 255;
color_picker_alpha = 255;
dropdown_anim_key = "";
dropdown_anim_progress = 1;
dropdown_anim_closing = false;
dropdown_anim_snapshot = undefined;
// Full pages use only a restrained fade.  Detailed retract/expand motion is
// reserved for list selection and menus, where it communicates state change.
page_anim_tab = tab;
page_anim_progress = 1;
// The new-object chooser is a side panel and therefore owns a slide clock
// separate from dropdowns.
object_palette_anim_progress = object_palette?1:0;
object_palette_anim_closing = false;
ui_menu_alpha = 1;
font_dropdown_open = false;
font_dropdown_target = "";
font_dropdown_scroll = 0;
damage_dropdown_open = false;
damage_dropdown_event = -1;
gb_spawn_dropdown_open = false;
gb_spawn_dropdown_event = -2;
gb_spawn_dropdown_scroll = 0;
gb_style_dropdown_open = false;
gb_style_dropdown_event = -1;
gb_style_dropdown_scroll = 0;
choice_menu_open = false;
choice_menu_context = "";
choice_menu_kind = "";
choice_menu_event = -1;
choice_menu_phase = 0;
choice_menu_scroll = 0;
// One editor-owned preview channel. It never stops unrelated game audio.
audio_preview_handle = -1;
audio_preview_name = "";
audio_preview_source = "";
// Folder-save browser and its one-level recovery actions.
file_confirm_action = "";
// Save windows are a modal stack. Opening a child keeps its parent in place;
// returning only slides the child away, so the parent never has to perform a
// redundant exit/re-entry animation.
save_dialog_draw_action = "";
save_dialog_pending_action = "";
save_dialog_last_action = "";
save_dialog_anim_progress = 0;
save_dialog_anim_phase = 0; // -1 leaving, 0 stable, 1 entering
save_dialog_stack = [];
save_browser_slots = BattleEditor_ListSaveSlots();
save_browser_backup_flags = BattleEditor_SaveSlotBackupFlags(save_browser_slots);
save_browser_selected = -1;
save_browser_scroll = 0;
save_active_name_cache = BattleEditor_LoadActiveSlotName();
save_name_buffer = save_active_name_cache;
if(save_name_buffer=="") save_name_buffer=BattleEditor_SanitizeSaveName(project.name);
save_name_editing = false;
save_name_caret = string_length(save_name_buffer);
save_name_keyboard_seen = "";
save_name_keyboard_anchor = save_name_caret;
save_pending_name = "";
save_confirm_return = "file_menu";
save_operation_kind = "save";
save_active_backup_ready_cache = save_active_name_cache!=""&&BattleEditor_SaveSlotHasBackup(save_active_name_cache);
save_undo_load_ready_cache = BattleEditor_RuntimeSnapshotExists("undo_load");
runtime_snapshot_pending = false;
runtime_snapshot_state = BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(project));
runtime_snapshot_idle_frames = 0;
runtime_snapshot_patch_count = 0;
// Claim the shared recovery journal before the initial compact write. If a
// second editor opens later, this instance remains usable but can no longer
// overwrite that newer window's project state.
BattleEditor_ClaimRuntimeSnapshotSession();
follow_dropdown_open = false;
follow_dropdown_event = -1;
follow_dropdown_scroll = 0;
aim_dropdown_open = false;
aim_dropdown_event = -1;
aim_dropdown_scroll = 0;
clip_editor_open = false;
clip_editor_event = -1;
clip_editor_scroll = 0;
clip_editor_filter = "";
property_scroll = 0;
property_scroll_key = "";
help_scroll = 0;
help_layout_ready = false;
help_sections_cache = [];
help_section_offsets = [];
help_section_lines = [];
help_content_height_cache = 0;
preview_frames = [];
board_preview_active = false;
last_battle_state = -999;
initial_player_menu_pending = true;
status_text = "空白第一回合：可放置骨头、自定义弹幕、GB、框和装饰。";

if (os_type == os_windows) keyboard_virtual_hide();
keyboard_string = "";
window_set_cursor(cr_none);
if(!instance_exists(game_cursor)) instance_create_depth(0,0,-1000000,game_cursor);
BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(runtime_snapshot_state),"current");
BattleEditor_ApplyInitialization(project);
