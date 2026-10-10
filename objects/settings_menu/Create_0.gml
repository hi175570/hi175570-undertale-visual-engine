choice=0;
option_names=["调试模式","简单模式","特效","高级特效","显示 FPS","神秘选项","窗口缩放","战斗读取存档"];
option_flags=[
    FLAG_SETTINGS_DEBUG,
    FLAG_SETTINGS_EASY,
    FLAG_SETTINGS_EFFECTS,
    FLAG_SETTINGS_ADVANCED_EFFECTS,
    FLAG_SETTINGS_SHOW_FPS,
    FLAG_SETTINGS_MYSTERY,
    "",
    ""
];
scale_option_index=array_length(option_names)-2;
scale_options=Window_ScaleOptions();
save_option_index=array_length(option_names)-1;
save_slots=BattleEditor_ListSaveSlots();
active_save_name=BattleEditor_LoadActiveSlotName();
option_start_y=108;
option_spacing=40;
selector_y=option_start_y;
selector_target_y=option_start_y;

// Visual-effect switches default to on; the other future-facing entries
// default to off until their gameplay behavior is connected.
var zone=Storage_GetSettings().Get("general");
if(is_undefined(zone.Get(FLAG_SETTINGS_EFFECTS,undefined))) zone.Set(FLAG_SETTINGS_EFFECTS,true);
if(is_undefined(zone.Get(FLAG_SETTINGS_ADVANCED_EFFECTS,undefined))) zone.Set(FLAG_SETTINGS_ADVANCED_EFFECTS,true);
if(is_undefined(zone.Get(FLAG_SETTINGS_SHOW_FPS,undefined))) zone.Set(FLAG_SETTINGS_SHOW_FPS,false);
