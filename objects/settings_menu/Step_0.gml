selector_y=lerp(selector_y,selector_target_y,0.28);
if(abs(selector_y-selector_target_y)<0.1) selector_y=selector_target_y;

if(Input_IsPressed(INPUT.DOWN)){
    choice=(choice+1) mod array_length(option_names);
    selector_target_y=option_start_y+option_spacing*choice;
}else if(Input_IsPressed(INPUT.UP)){
    choice=(choice-1+array_length(option_names)) mod array_length(option_names);
    selector_target_y=option_start_y+option_spacing*choice;
}else if(choice==scale_option_index&&(Input_IsPressed(INPUT.LEFT)||Input_IsPressed(INPUT.RIGHT)||Input_IsPressed(INPUT.CONFIRM))){
    var scale_index=0;
    for(var si=0;si<array_length(scale_options);si++) if(scale_options[si]==global.window_scale){scale_index=si;break;}
    scale_index=(scale_index+(Input_IsPressed(INPUT.LEFT)?-1:1)+array_length(scale_options)) mod array_length(scale_options);
    Window_SetScale(scale_options[scale_index]);
}else if(choice==save_option_index&&(Input_IsPressed(INPUT.LEFT)||Input_IsPressed(INPUT.RIGHT)||Input_IsPressed(INPUT.CONFIRM))){
    save_slots=BattleEditor_ListSaveSlots();
    if(array_length(save_slots)>0){
        var current_index=-1;
        for(var save_index=0;save_index<array_length(save_slots);save_index++) if(save_slots[save_index]==active_save_name){current_index=save_index;break;}
        var save_cycle_delta=Input_IsPressed(INPUT.LEFT)?-1:1;
        current_index=(current_index+save_cycle_delta+array_length(save_slots)) mod array_length(save_slots);
        active_save_name=save_slots[current_index];
        BattleEditor_SelectBattleSlot(active_save_name);
    }
}else if(Input_IsPressed(INPUT.CONFIRM)){
    var settings_storage=Storage_GetSettings();
    var zone=settings_storage.Get("general");
    var flag=option_flags[choice];
    zone.Set(flag,!zone.Get(flag,false));
    if(flag==FLAG_SETTINGS_SHOW_FPS) global.show_fps=zone.Get(flag,false);
    settings_storage.SaveToFile();
}else if(Input_IsPressed(INPUT.CANCEL)){
    room_goto(room_menu);
}
