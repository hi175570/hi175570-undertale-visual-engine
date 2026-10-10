// Invert the actual editor surface rectangle, independent of GUI camera state.
// This also covers letterboxing, border skins and non-integer window scales.
var editor_mouse=Window_ContentMouse();
var mx=editor_mouse.x;
var my=editor_mouse.y;
var click=mouse_check_button_pressed(mb_left);
var right_click=mouse_check_button_pressed(mb_right);
script_palette_progress=clamp(script_palette_progress+(script_palette_open?1:-1)*0.0425*global.delta_time_factor,0,1);
if(gb_style_preview_playing){
    gb_style_preview_time+=global.delta_time_factor;
    // 30 enter + 18 charge + at least one complete opening + 42 beam + 10 close.
    var preview_style=BattleEditor_GBStyleDefinition(project,selected_gb_style>=0&&selected_gb_style<array_length(project.resources.gb_styles)?project.resources.gb_styles[selected_gb_style].uid:-1);
    var preview_frames=max(1,array_length(preview_style.animation.frames));
    var preview_interval=max(1,preview_style.animation.frame_interval);
    // Match the default authored GB timing: 45-frame entrance, 35-frame hold,
    // 6-frame anticipation, full opening, 50-frame beam and visible closing.
    if(gb_style_preview_time>=45+35+6+max(1,(preview_frames-1)*preview_interval)+50+max(10,(preview_frames-1)*preview_interval)){gb_style_preview_playing=false;gb_style_preview_time=0;}
}
if(deferred_click){mx=deferred_click_x;my=deferred_click_y;click=true;deferred_click=false;}
if(audio_preview_handle>=0&&!audio_is_playing(audio_preview_handle)){
    audio_preview_handle=-1;
    audio_preview_name="";
    audio_preview_source="";
}
// Coalesce a burst of editing before comparing/writing the recovery snapshot.
// This keeps add/delete and node-drag release on their own responsive frame.
var snapshot_input_active=click||right_click||mouse_check_button(mb_left)||mouse_check_button(mb_right)||mouse_check_button(mb_middle)
    ||mouse_wheel_up()||mouse_wheel_down()||keyboard_check_pressed(vk_anykey);
if(snapshot_input_active){runtime_snapshot_pending=true;runtime_snapshot_idle_frames=0;}
else if(runtime_snapshot_pending) runtime_snapshot_idle_frames+=1;
if(keyboard_check_pressed(vk_enter)||mouse_check_button_released(mb_left)) script_layout_revision+=1;
if(tab!=2){script_stack_drag=undefined;script_drag_mode="";}
// Inspector fields write their live edit buffer into project data while they
// retain focus. Waiting for focus_field to become empty meant an editor crash
// could discard an entire unsaved typing session even after the author paused.
// The idle coalescing already prevents per-keystroke disk writes, so committed
// project state may be journaled without forcing the field to close first.
var snapshot_can_flush=runtime_snapshot_pending&&runtime_snapshot_idle_frames>=12
    &&!text_editor_open&&!save_name_editing&&file_confirm_action=="";
if(snapshot_can_flush){
    var snapshot_state=BattleEditor_ProjectSparseForStorage(project);
    var snapshot_operations=[];
    BattleEditor_StorageCollectChanges(runtime_snapshot_state,snapshot_state,[],snapshot_operations);
    if(array_length(snapshot_operations)>0){
        var snapshot_ok=false;
        // Bound replay cost and journal growth. Ordinary edits append exact
        // field operations; every 128 successful records become one base.
        if(runtime_snapshot_patch_count>=127){
            snapshot_ok=BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(snapshot_state),"current");
            if(snapshot_ok) runtime_snapshot_patch_count=0;
        }else{
            snapshot_ok=BattleEditor_AppendRuntimeSnapshotChanges(snapshot_operations,"current");
            if(snapshot_ok) runtime_snapshot_patch_count+=1;
        }
        if(snapshot_ok) runtime_snapshot_state=BattleEditor_StorageClone(snapshot_state);
        else status_text="运行态恢复副本写入失败";
    }
    runtime_snapshot_pending=false;runtime_snapshot_idle_frames=0;
}
// Workspace may receive many edits before the author leaves it. Mark the cache
// stale here, but never parse in Step/Draw: leaving Workspace or pressing Run
// rebuilds it once. This also keeps canvas panning and list dragging cheap.
if(click||right_click||mouse_wheel_up()||mouse_wheel_down()||keyboard_check_pressed(vk_anykey)){
    if(tab==2) timeline_duration_dirty=true;
    // A formula may reference initialization or scene-object values edited on
    // another tab. Mark only; the preview still rebuilds once after returning
    // to Workspace rather than evaluating while the author is elsewhere.
    script_function_preview_dirty=true;
}
global.battle_editor_project_runtime=project;
global.battle_editor_project_live_from_editor=true;
if(input_capture_frames>0) input_capture_frames-=1;
BattleEditor_SetInputCapture(focus_field!=""||text_editor_open||input_capture_frames>0);

// Page changes stay deliberately quiet: a short fade is enough for a whole
// screen.  List details and menus carry the stronger spatial transitions.
if(tab!=page_anim_tab){page_anim_tab=tab;page_anim_progress=0;}
else page_anim_progress=min(1,page_anim_progress+0.03*global.delta_time_factor);

// One sliding side-panel clock. Existing code may close the object palette
// directly; Draw keeps the last frame alive and flips this closing flag so the
// panel can leave the screen instead of vanishing.
if(object_palette_anim_closing){
    object_palette_anim_progress=max(0,object_palette_anim_progress-0.0375*global.delta_time_factor);
    if(object_palette_anim_progress<=0){object_palette_anim_progress=0;object_palette_anim_closing=false;object_palette=false;}
}else if(object_palette) object_palette_anim_progress=min(1,object_palette_anim_progress+0.0375*global.delta_time_factor);

// Workspace list/step detail card.  The current item retracts, the pending
// item is committed at the seam, then the new card expands. Repeated clicks
// update the pending target rather than spawning overlapping animations.
if(script_inspector_anim_phase<0){
    script_inspector_anim_progress=max(0,script_inspector_anim_progress-0.045*global.delta_time_factor);
    if(script_inspector_anim_progress<=0){
        script_selected_list=script_inspector_pending_list;
        script_selected_step=script_inspector_pending_step;
        script_inspector_last_list=script_selected_list;
        script_inspector_last_step=script_selected_step;
        script_inspector_anim_progress=0;
        script_inspector_anim_phase=script_selected_list>=0?1:0;
    }
}else if(script_inspector_anim_phase>0){
    script_inspector_anim_progress=min(1,script_inspector_anim_progress+0.045*global.delta_time_factor);
    if(script_inspector_anim_progress>=1) script_inspector_anim_phase=0;
}else if(script_selected_list!=script_inspector_last_list||script_selected_step!=script_inspector_last_step){
    // Selection changes made by non-mouse workflows still receive the entry
    // animation, but are not delayed because the old value has already gone.
    script_inspector_last_list=script_selected_list;
    script_inspector_last_step=script_selected_step;
    script_inspector_anim_progress=script_selected_list>=0?0:1;
    script_inspector_anim_phase=script_selected_list>=0?1:0;
}

// Menus share one short cubic reveal/retract clock. A snapshot preserves the
// outgoing menu after its logical value has already been chosen, so selecting
// an option visibly folds the old menu away before another one unfolds.
if(script_dropdown!=""){
    var stale_dropdown_list_valid=script_selected_list>=0&&script_selected_list<array_length(project.script_lists);
    var stale_dropdown_step_valid=stale_dropdown_list_valid&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps);
    var stale_dropdown_detached=script_dropdown=="formula_help"||script_dropdown=="formula_variable";
    var stale_dropdown_list_only=script_dropdown=="entry_kind"||script_dropdown=="item_entry"||script_dropdown=="action_entry";
    if((stale_dropdown_list_only&&!stale_dropdown_list_valid)||(!stale_dropdown_detached&&!stale_dropdown_list_only&&!stale_dropdown_step_valid)) script_dropdown="";
}
var live_dropdown_key="";
if(script_dropdown!="") live_dropdown_key="script:"+script_dropdown;
else if(font_dropdown_open) live_dropdown_key="font:"+font_dropdown_target;
else if(damage_dropdown_open) live_dropdown_key="damage_type";
else if(gb_spawn_dropdown_open) live_dropdown_key="gb_spawn";
else if(gb_style_dropdown_open) live_dropdown_key="gb_style";
else if(choice_menu_open) live_dropdown_key="choice:"+choice_menu_context;
else if(follow_dropdown_open) live_dropdown_key="follow_frame";
else if(aim_dropdown_open) live_dropdown_key="aim_target";
else if(clip_editor_open) live_dropdown_key="clip_frames";
else if(initialization_turn_dropdown) live_dropdown_key="initialization_turn";
else if(battle_music_dropdown_open) live_dropdown_key="battle_music";
else if(developer_turn_dropdown) live_dropdown_key="developer_turn";
else if(object_palette_category_open) live_dropdown_key="object_palette_category";
if(dropdown_anim_closing){
    dropdown_anim_progress=max(0,dropdown_anim_progress-0.0425*global.delta_time_factor);
    if(dropdown_anim_progress<=0){dropdown_anim_progress=0;dropdown_anim_closing=false;dropdown_anim_key="";dropdown_anim_snapshot=undefined;}
}else if(live_dropdown_key==""){
    if(dropdown_anim_key!=""&&dropdown_anim_progress>0) dropdown_anim_closing=true;
    else{dropdown_anim_key="";dropdown_anim_progress=0;dropdown_anim_snapshot=undefined;}
}else if(dropdown_anim_key!=live_dropdown_key){
    if(dropdown_anim_key!=""&&dropdown_anim_progress>0) dropdown_anim_closing=true;
    else{dropdown_anim_key=live_dropdown_key;dropdown_anim_progress=0;}
}else dropdown_anim_progress=min(1,dropdown_anim_progress+0.0425*global.delta_time_factor);
if(!dropdown_anim_closing&&live_dropdown_key!=""&&live_dropdown_key==dropdown_anim_key){
    dropdown_anim_snapshot={
        script_dropdown:script_dropdown,font_dropdown_open:font_dropdown_open,font_dropdown_target:font_dropdown_target,font_dropdown_scroll:font_dropdown_scroll,
        damage_dropdown_open:damage_dropdown_open,damage_dropdown_event:damage_dropdown_event,
        gb_spawn_dropdown_open:gb_spawn_dropdown_open,gb_spawn_dropdown_event:gb_spawn_dropdown_event,gb_spawn_dropdown_scroll:gb_spawn_dropdown_scroll,
        gb_style_dropdown_open:gb_style_dropdown_open,gb_style_dropdown_event:gb_style_dropdown_event,gb_style_dropdown_scroll:gb_style_dropdown_scroll,
        choice_menu_open:choice_menu_open,choice_menu_context:choice_menu_context,choice_menu_kind:choice_menu_kind,choice_menu_event:choice_menu_event,choice_menu_phase:choice_menu_phase,choice_menu_scroll:choice_menu_scroll,
        follow_dropdown_open:follow_dropdown_open,follow_dropdown_event:follow_dropdown_event,follow_dropdown_scroll:follow_dropdown_scroll,
        aim_dropdown_open:aim_dropdown_open,aim_dropdown_event:aim_dropdown_event,aim_dropdown_scroll:aim_dropdown_scroll,
        clip_editor_open:clip_editor_open,clip_editor_event:clip_editor_event,clip_editor_scroll:clip_editor_scroll,clip_editor_filter:clip_editor_filter,
        initialization_turn_dropdown:initialization_turn_dropdown,battle_music_dropdown_open:battle_music_dropdown_open,battle_music_scroll:battle_music_scroll,
        developer_turn_dropdown:developer_turn_dropdown,object_palette_category_open:object_palette_category_open
    };
}

// Save pages form a real parent/child stack. A child slides over its stationary
// parent; Back/Cancel slides only that child away and reveals the already-drawn
// parent. Input stays locked while the top page is moving.
if(file_confirm_action!=save_dialog_last_action){
    save_dialog_last_action=file_confirm_action;
    save_dialog_pending_action=file_confirm_action;
    var save_stack_count=array_length(save_dialog_stack);
    if(save_stack_count<=0){
        if(save_dialog_pending_action!=""){
            array_push(save_dialog_stack,save_dialog_pending_action);
            save_dialog_draw_action=save_dialog_pending_action;
            save_dialog_anim_progress=0;
            save_dialog_anim_phase=1;
        }
    }else{
        var save_stack_top=save_dialog_stack[save_stack_count-1];
        var save_pending_parent="";
        if(save_dialog_pending_action=="new_save"||save_dialog_pending_action=="load_browser"||save_dialog_pending_action=="undo_save_confirm") save_pending_parent="file_menu";
        else if(save_dialog_pending_action=="load_confirm"||save_dialog_pending_action=="restore_load_confirm") save_pending_parent="load_browser";
        else if(save_dialog_pending_action=="save_confirm") save_pending_parent=save_confirm_return;
        if(save_dialog_pending_action!=""&&save_pending_parent==save_stack_top){
            array_push(save_dialog_stack,save_dialog_pending_action);
            save_dialog_draw_action=save_dialog_pending_action;
            save_dialog_anim_progress=0;
            save_dialog_anim_phase=1;
        }else{
            // Returning to an ancestor or closing the modal retires only the
            // current top page. A non-ancestor transition is installed after
            // that page has left.
            save_dialog_anim_phase=-1;
        }
    }
}
if(save_dialog_anim_phase<0){
    save_dialog_anim_progress=max(0,save_dialog_anim_progress-0.035*global.delta_time_factor);
    if(save_dialog_anim_progress<=0){
        var save_return_index=-1;
        for(var save_stack_index=0;save_stack_index<array_length(save_dialog_stack);save_stack_index++) if(save_dialog_stack[save_stack_index]==save_dialog_pending_action) save_return_index=save_stack_index;
        if(save_dialog_pending_action==""){
            save_dialog_stack=[];
            save_dialog_draw_action="";
            save_dialog_anim_phase=0;
        }else if(save_return_index>=0){
            while(array_length(save_dialog_stack)>save_return_index+1) array_delete(save_dialog_stack,array_length(save_dialog_stack)-1,1);
            save_dialog_draw_action=save_dialog_stack[array_length(save_dialog_stack)-1];
            save_dialog_anim_progress=1;
            save_dialog_anim_phase=0;
        }else{
            if(array_length(save_dialog_stack)>0) array_delete(save_dialog_stack,array_length(save_dialog_stack)-1,1);
            array_push(save_dialog_stack,save_dialog_pending_action);
            save_dialog_draw_action=save_dialog_pending_action;
            save_dialog_anim_progress=0;
            save_dialog_anim_phase=1;
        }
    }
}else if(save_dialog_anim_phase>0){
    save_dialog_anim_progress=min(1,save_dialog_anim_progress+0.035*global.delta_time_factor);
    if(save_dialog_anim_progress>=1) save_dialog_anim_phase=0;
}
var save_dialog_accepts_input=file_confirm_action!=""&&save_dialog_draw_action==file_confirm_action
    &&save_dialog_anim_phase==0&&save_dialog_anim_progress>=1;

var current_state=-1;
if(instance_exists(battle)){
    current_state=Battle_GetState();
    // Entering the editor/game begins at the real player menu. Do this once
    // after the battle object exists so room creation order cannot expose a
    // preparation state as the first playable state.
    if(initial_player_menu_pending){
        initial_player_menu_pending=false;
        if(current_state!=BATTLE_STATE.MENU){
            if(instance_exists(battle_turn)) with(battle_turn) instance_destroy();
            Battle_SetState(BATTLE_STATE.MENU);
            current_state=BATTLE_STATE.MENU;
        }
        // Entering the editor is a real player turn.  Restore the authored
        // player-menu rectangle explicitly instead of inheriting whichever
        // square monster board happened to exist during room creation.
        BattleEditor_RestoreAuthoringBoard(id);
        last_battle_state=BATTLE_STATE.MENU;
    }
    // Menu presentation changes only when its small authored payload or the
    // battle state changes. ProjectNormalize and markup compilation used to
    // run here unconditionally every frame after a project was loaded.
    var upcoming_turn=BattleEditor_ResolveMonsterTurn(project,max(1,Battle_GetTurnNumber()+1));
    var upcoming_turn_data=BattleEditor_GetTurnData(project,upcoming_turn,true);
    var next_turn_presentation_signature=string(upcoming_turn)+"|"+string(current_state)+"|"
        +string(upcoming_turn_data.turn_font)+"|"+string(upcoming_turn_data.turn_voice)+"|"+string(upcoming_turn_data.text);
    if(turn_presentation_signature!=next_turn_presentation_signature){
        BattleEditor_ApplyTurnPresentation(project,upcoming_turn);
        turn_presentation_signature=next_turn_presentation_signature;
    }
    // A real monster turn is hosted by turn_test.  Starting the editor itself
    // here created a second runtime controller: both advanced the same project,
    // duplicated boards, and whichever controller finished first ended the
    // turn.  Manual editor preview is started only by the Play button.
    if(last_battle_state==BATTLE_STATE.IN_TURN&&current_state!=BATTLE_STATE.IN_TURN){
        if(playing) BattleEditor_RuntimeStop(id);
        // Battle_EndTurn performs the ordinary reset. Keep this state-edge
        // fallback for custom scripts which jump out of IN_TURN directly.
        BattleEditor_SetSoulMode(0);
        BattleEditor_RestoreSoulToMenuButton();
    }
    last_battle_state=current_state;
}

// A typewriter preview deliberately hides the complete editor shell so the
// authored text can be judged against the real battle scene.  It is bounded by
// the calculated typing length because text_typer instances are reusable and
// do not normally destroy themselves at the end of a line.
if(text_editor_preview_mode){
    text_editor_preview_frames=max(0,text_editor_preview_frames-global.delta_time_factor);
    if(keyboard_check_pressed(vk_escape)||keyboard_check_pressed(vk_space)||text_editor_preview_frames<=0||!instance_exists(text_editor_preview)){
        if(instance_exists(text_editor_preview)) instance_destroy(text_editor_preview);
        text_editor_preview=noone;
        text_editor_preview_mode=false;
        text_editor_preview_frames=0;
    }else exit;
}

// turn_test is the sole owner of a real monster turn.  The hidden editor must
// not consume Space/Escape or start a second preview controller underneath it.
if(instance_exists(turn_test)&&instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.IN_TURN) exit;

// A direct jump may need many hidden logical ticks, but no intermediate tick
// may reach Draw. Retry only the exceptional case where simulation itself
// stopped making progress before the requested target.
if(timeline_live_seek_pending&&!timeline_dragging&&file_confirm_action==""){
    var pending_seek_target=timeline_live_seek_target;
    if(BattleEditor_RuntimeBeginSeek(id,pending_seek_target,false,false)){
        timeline_live_seek_time=playhead;
        timeline_live_seek_pending=!timeline_seek_complete;
        cursor_time=pending_seek_target;
        status_text=timeline_live_seek_pending
            ?"正在计算 "+BattleEditor_FormatTimelineTime(pending_seek_target)+" 的目标状态"
            :"已定格下一怪物回合 "+BattleEditor_FormatTimelineTime(pending_seek_target)+" 的目标状态";
    }
}

if(file_confirm_action!=""){
    BattleEditor_SetInputCapture(true);
    if(!save_dialog_accepts_input) exit;
    if(file_confirm_action=="file_menu"){
        if(keyboard_check_pressed(vk_escape)){file_confirm_action="";status_text="已取消";exit;}
        if(click){
            var active_slot_name=save_active_name_cache;
            if(BattleEditor_PointInRect(mx,my,178,154,462,188)){
                file_confirm_action="new_save";save_browser_slots=BattleEditor_ListSaveSlots();save_browser_selected=-1;save_browser_scroll=0;
                save_browser_backup_flags=BattleEditor_SaveSlotBackupFlags(save_browser_slots);
                save_name_buffer=BattleEditor_NextSaveSlotName();save_name_editing=true;
                save_name_caret=string_length(save_name_buffer);save_name_keyboard_seen="";save_name_keyboard_anchor=save_name_caret;keyboard_string="";
                if(os_type==os_windows) keyboard_virtual_show(undefined,undefined,undefined,undefined);
            }else if(BattleEditor_PointInRect(mx,my,178,198,462,232)){
                if(active_slot_name=="") status_text="请先新建存档";
                else{save_pending_name=active_slot_name;save_operation_kind="save";save_confirm_return="file_menu";file_confirm_action="save_confirm";}
            }else if(BattleEditor_PointInRect(mx,my,178,242,462,276)){
                save_browser_slots=BattleEditor_ListSaveSlots();save_browser_selected=-1;save_browser_scroll=0;save_name_editing=false;
                save_browser_backup_flags=BattleEditor_SaveSlotBackupFlags(save_browser_slots);save_undo_load_ready_cache=BattleEditor_RuntimeSnapshotExists("undo_load");
                var load_active_name=BattleEditor_LoadActiveSlotName();
                for(var load_active_index=0;load_active_index<array_length(save_browser_slots);load_active_index++) if(save_browser_slots[load_active_index]==load_active_name){save_browser_selected=load_active_index;save_name_buffer=load_active_name;break;}
                file_confirm_action="load_browser";
            }else if(BattleEditor_PointInRect(mx,my,178,286,462,320)){
                if(active_slot_name!=""&&save_active_backup_ready_cache){save_pending_name=active_slot_name;file_confirm_action="undo_save_confirm";}
                else status_text="当前存档还没有可撤销的上一版";
            }else if(BattleEditor_PointInRect(mx,my,178,346,462,380)){file_confirm_action="";status_text="已取消";}
        }
        exit;
    }
    var save_browser_mode=file_confirm_action=="new_save"||file_confirm_action=="load_browser";
    if(save_browser_mode){
        var save_mode=file_confirm_action=="new_save";
        if(save_name_editing){
            if(os_type==os_windows&&!keyboard_virtual_status()) keyboard_virtual_show(undefined,undefined,undefined,undefined);
            var save_name_edit=BattleEditor_SingleLineEditStep(save_name_buffer,save_name_caret,save_name_keyboard_seen,save_name_keyboard_anchor);
            save_name_buffer=save_name_edit.buffer;
            save_name_caret=save_name_edit.caret;
            save_name_keyboard_seen=save_name_edit.keyboard_seen;
            save_name_keyboard_anchor=save_name_edit.keyboard_anchor;
            if(keyboard_check_pressed(vk_enter)){save_name_editing=false;keyboard_string="";if(os_type==os_windows) keyboard_virtual_hide();}
        }
        if(keyboard_check_pressed(vk_escape)){
            if(save_name_editing){save_name_editing=false;keyboard_string="";if(os_type==os_windows) keyboard_virtual_hide();}
            else{file_confirm_action="file_menu";status_text="已返回存档菜单";}
            exit;
        }
        if(BattleEditor_PointInRect(mx,my,120,154,520,334)&&(mouse_wheel_up()||mouse_wheel_down())) save_browser_scroll=clamp(save_browser_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(save_browser_slots)-6));
        if(click){
            if(save_mode&&BattleEditor_PointInRect(mx,my,178,112,520,138)){
                save_name_editing=true;
                save_name_caret=BattleEditor_SingleLineCaretFromPoint(save_name_buffer,save_name_editing?save_name_caret:string_length(save_name_buffer),326,mx,184);
                save_name_keyboard_seen="";save_name_keyboard_anchor=save_name_caret;keyboard_string="";
                if(os_type==os_windows) keyboard_virtual_show(undefined,undefined,undefined,undefined);
                exit;
            }
            if(save_name_editing){save_name_editing=false;save_name_keyboard_seen="";keyboard_string="";if(os_type==os_windows) keyboard_virtual_hide();}
            if(BattleEditor_PointInRect(mx,my,120,154,520,334)){
                var save_row=floor((my-154)/30);
                var save_index=save_browser_scroll+save_row;
                if(save_row>=0&&save_row<6&&save_index<array_length(save_browser_slots)){
                    save_browser_selected=save_index;
                    save_name_buffer=save_browser_slots[save_index];
                }
            }else if(!save_mode&&BattleEditor_PointInRect(mx,my,120,338,270,364)){
                var import_path=get_open_filename("旧攻击项目 JSON|*.json","none");
                if(import_path!=""&&import_path!="none"){
                    if(!BattleEditor_CaptureUndoLoad(project)) status_text="无法建立导入前副本";
                    else{
                        var imported_project=BattleEditor_LoadProject(import_path);
                        if(BattleEditor_AdoptLoadedProject(id,imported_project)){
                            runtime_snapshot_state=BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(project));
                            BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(runtime_snapshot_state),"current");
                            runtime_snapshot_pending=false;runtime_snapshot_patch_count=0;
                            status_text="已导入旧 JSON；请另存为文件夹存档";
                            file_confirm_action="";
                        }else status_text="旧 JSON 导入失败";
                    }
                }
            }else if(BattleEditor_PointInRect(mx,my,120,372,210,400)){
                file_confirm_action="file_menu";status_text="已返回存档菜单";
            }else if(BattleEditor_PointInRect(mx,my,218,372,370,400)){
                if(!save_mode&&save_undo_load_ready_cache) file_confirm_action="restore_load_confirm";
                else if(!save_mode) status_text="目前没有可复原的载入";
            }else if(BattleEditor_PointInRect(mx,my,378,372,520,400)){
                if(save_mode){
                    save_pending_name=BattleEditor_SanitizeSaveName(save_name_buffer);
                    if(save_pending_name=="") status_text="请先输入存档名称";
                    else{save_operation_kind="create";save_confirm_return="new_save";file_confirm_action="save_confirm";}
                }else if(save_browser_selected>=0&&save_browser_selected<array_length(save_browser_slots)){
                    save_pending_name=save_browser_slots[save_browser_selected];file_confirm_action="load_confirm";
                }else status_text="请先选择一个存档";
            }
        }
        exit;
    }
    var confirm_return=file_confirm_action=="save_confirm"?save_confirm_return:(file_confirm_action=="undo_save_confirm"?"file_menu":"load_browser");
    if(keyboard_check_pressed(vk_escape)||click&&BattleEditor_PointInRect(mx,my,226,306,316,332)){
        file_confirm_action=confirm_return;
        status_text="已取消";
    }else if(click&&BattleEditor_PointInRect(mx,my,324,306,414,332)){
        if(file_confirm_action=="save_confirm"){
            var previous_project_name=project.name;
            var project_to_save=project;
            var can_save=true;
            if(save_operation_kind=="create"){
                can_save=BattleEditor_CaptureUndoLoad(project);
                project_to_save=BattleEditor_NewProject();
                project_to_save.name=save_pending_name;
            }else project.name=save_pending_name;
            var save_result=can_save?BattleEditor_SaveSlot(project_to_save,save_pending_name):{ok:false,name:save_pending_name,path:""};
            if(save_result.ok&&(save_operation_kind!="create"||BattleEditor_AdoptLoadedProject(id,project_to_save))){
                save_name_buffer=save_result.name;project_path=save_result.path;
                save_active_name_cache=save_result.name;
                save_browser_slots=BattleEditor_ListSaveSlots();
                save_browser_backup_flags=BattleEditor_SaveSlotBackupFlags(save_browser_slots);
                save_active_backup_ready_cache=BattleEditor_SaveSlotHasBackup(save_result.name);
                if(save_operation_kind=="create") save_undo_load_ready_cache=true;
                runtime_snapshot_state=BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(project));
                BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(runtime_snapshot_state),"current");
                runtime_snapshot_pending=false;runtime_snapshot_patch_count=0;
                status_text=(save_operation_kind=="create"?"已新建空白存档：save / ":"已保存：save / ")+save_result.name;
                file_confirm_action="";
            }else{if(save_operation_kind!="create") project.name=previous_project_name;status_text=can_save?"保存失败："+save_pending_name:"无法建立新建前恢复副本";file_confirm_action=save_confirm_return;}
        }else if(file_confirm_action=="load_confirm"){
            if(!BattleEditor_CaptureUndoLoad(project)){status_text="无法建立载入前副本";file_confirm_action="load_browser";}
            else{
                var loaded_slot=BattleEditor_LoadSlot(save_pending_name);
                if(BattleEditor_AdoptLoadedProject(id,loaded_slot)){
                    save_name_buffer=save_pending_name;save_active_name_cache=save_pending_name;project_path=BattleEditor_DefaultProjectPath();
                    save_active_backup_ready_cache=BattleEditor_SaveSlotHasBackup(save_pending_name);save_undo_load_ready_cache=true;
                    runtime_snapshot_state=BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(project));
                    BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(runtime_snapshot_state),"current");
                    runtime_snapshot_pending=false;runtime_snapshot_patch_count=0;
                    status_text="已载入：save / "+save_pending_name;
                    file_confirm_action="";
                }else{status_text="载入失败："+save_pending_name;file_confirm_action="load_browser";}
            }
        }else if(file_confirm_action=="undo_save_confirm"){
            status_text=BattleEditor_UndoSlotSave(save_pending_name)?"已撤销上次保存；当前编辑内容保持不变":"撤销保存失败";
            save_active_backup_ready_cache=BattleEditor_SaveSlotHasBackup(save_active_name_cache);
            save_browser_backup_flags=BattleEditor_SaveSlotBackupFlags(save_browser_slots);
            file_confirm_action="file_menu";
        }else if(file_confirm_action=="restore_load_confirm"){
            var restored_project=BattleEditor_ConsumeUndoLoad();
            if(BattleEditor_AdoptLoadedProject(id,restored_project)){
                runtime_snapshot_state=BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(project));
                BattleEditor_SaveRuntimeSnapshotSerialized(json_stringify(runtime_snapshot_state),"current");
                save_undo_load_ready_cache=false;
                runtime_snapshot_pending=false;runtime_snapshot_patch_count=0;
                status_text="已复原到载入前的编辑状态";file_confirm_action="";
            }else{status_text="复原载入失败";file_confirm_action="load_browser";}
        }
        save_pending_name="";save_operation_kind="save";
    }
    exit;
}
// A cancelled/completed window remains modal until its visible exit finishes.
if(save_dialog_draw_action!="") exit;

// RuntimeStart owns the scripted monster-board transition while playing. In
// ordinary editor state RestoreAuthoringBoard keeps the live wide player board
// and attaches only authored ADD/SUBTRACT frames, so their clipping and joined
// borders remain visible without forcing the main board back to a square.
if(instance_exists(battle_board)&&current_state==BATTLE_STATE.MENU&&playing&&!preserve_paused_board){
    var runtime_board_missing=!board_preview_active||!is_struct(battle_board.mainboard)||battle_board.mainboard._destroyed;
    if(runtime_board_missing) BattleEditor_SyncBoardPreview(id,false);
}

if(color_picker_open){
    BattleEditor_SetInputCapture(true);
    if(mouse_check_button(mb_left)){
        if(BattleEditor_PointInRect(mx,my,146,118,494,270)){
            color_picker_saturation=clamp((mx-146)/348*255,0,255);
            color_picker_value=clamp((270-my)/152*255,0,255);
        }else if(BattleEditor_PointInRect(mx,my,146,284,494,304)) color_picker_hue=clamp((mx-146)/348*255,0,255);
        else if(BattleEditor_PointInRect(mx,my,146,318,494,338)) color_picker_alpha=clamp((mx-146)/348*255,0,255);
        var picker_live_color=make_color_hsv(color_picker_hue,color_picker_saturation,color_picker_value);
        text_editor_hex=BattleEditor_ColorToHex(picker_live_color,color_picker_alpha);
    }
    if(click&&BattleEditor_PointInRect(mx,my,316,358,400,382)) color_picker_open=false;
    else if(click&&BattleEditor_PointInRect(mx,my,410,358,494,382)){
        var picker_color=make_color_hsv(color_picker_hue,color_picker_saturation,color_picker_value);
        var picker_alpha=color_picker_alpha/255;
        if(color_picker_target=="color"||color_picker_target=="gradient"){
            var picker_before="";
            var picker_after="";
            if(color_picker_target=="gradient"){
                picker_before="<gradient="+text_editor_hex+",#60A0FFFF>";
                picker_after="</gradient>";
            }else{
                picker_before="<color="+text_editor_hex+">";
                picker_after="</color>";
            }
            text_editor_buffer=string_insert(picker_before+picker_after,text_editor_buffer,text_editor_caret+1);
            text_editor_caret+=string_length(picker_before);
            text_editor_focus="text";
        }else if(color_picker_target=="global_board"){
            project.initialization.board_color_default=picker_color;
            // The default colour is live initialization data, not a value
            // deferred until the next monster turn.  Apply it to the main
            // authored board now; extra frames keep their own colours unless
            // the author explicitly presses "应用到全部框".
            project.initialization.board.color_frame=picker_color;
            main_board_preview.color_frame=picker_color;
            BattleEditor_ApplyInitialization(project);
            if(board_edit_session||tab==0) BattleEditor_SyncBoardPreview(id,true);
        }else if(color_picker_target=="frame"&&selected_frame>=-1){
            var picker_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
            picker_frame.color_frame=picker_color;
            BattleEditor_SyncBoardPreview(id,true);
        }else if(color_picker_target=="event_text"&&selected>=0&&selected<array_length(project.events)){
            project.events[selected].text_color=picker_color;
            if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"text_color",wave_inspector_phase,group_selection_type,group_selection_control_id);
        }
        else if(color_picker_target=="event_tint"&&selected>=0&&selected<array_length(project.events)){
            project.events[selected].visual_tint.custom_color=picker_color;
            BattleEditor_SetVisualTintMode(project.events[selected],2);
            if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"visual_color",wave_inspector_phase,group_selection_type,group_selection_control_id);
        }else if(color_picker_target=="script_value"&&script_selected_list>=0&&script_selected_step>=0){
            project.script_lists[script_selected_list].steps[script_selected_step].value=picker_color;
        }else if(color_picker_target=="workspace_create_color"&&script_selected_list>=0&&script_selected_step>=0){
            var picker_create_step=project.script_lists[script_selected_list].steps[script_selected_step];
            BattleEditor_WorkspaceCreateNormalizeTemplate(picker_create_step);
            BattleEditor_WorkspaceTemplateSet(picker_create_step.create_template,script_create_choice_path,picker_color);
            if(script_create_choice_path=="visual_tint.color"){
                BattleEditor_WorkspaceTemplateSet(picker_create_step.create_template,"visual_tint.custom_color",picker_color);
                BattleEditor_SetVisualTintMode(picker_create_step.create_template,2);
            }
        }
        keyboard_string="";
        color_picker_open=false;
    }
    exit;
}

if(text_editor_open){
    BattleEditor_SetInputCapture(true);
    if(os_type==os_windows){
        if(!text_editor_ime_active){
            keyboard_string="";
            text_editor_keyboard_seen="";
            text_editor_keyboard_anchor=text_editor_caret;
            text_editor_ime_active=true;
        }
        // hide/show is asynchronous on Windows. A one-shot show immediately
        // after hide can lose the race and leave the IME disabled for the
        // entire edit session. Trust the runner's real status and retry only
        // while it still reports disabled; once enabled this does not disturb
        // an active composition.
        if(!keyboard_virtual_status()) keyboard_virtual_show(undefined,undefined,undefined,undefined);
    }

    if(text_editor_focus=="text"){
        // Windows' emoji panel does not consistently forward supplementary
        // Unicode characters through GameMaker's keyboard_string.  Clipboard
        // text does preserve full four-byte Unicode, so Ctrl+V is the reliable
        // input route for Emoji as well as long Chinese text. Insert at the
        // real caret instead of appending to the end.
        if(keyboard_check(vk_control)&&keyboard_check_pressed(ord("V"))){
            var pasted_text=clipboard_get_text();
            keyboard_string="";
            text_editor_keyboard_seen="";
            text_editor_keyboard_anchor=text_editor_caret;
            if(string_length(pasted_text)>0){
                text_editor_buffer=string_insert(pasted_text,text_editor_buffer,text_editor_caret+1);
                text_editor_caret=min(string_length(text_editor_buffer),text_editor_caret+string_length(pasted_text));
            }
            text_editor_keyboard_anchor=text_editor_caret;
        }
        // keyboard_string is an accumulating OS/IME composition buffer.  IME
        // commits rewrite it (for example "ni" becomes "你"), so append-only
        // mirroring loses every committed Chinese character. Replace the full
        // previously mirrored composition at its stable caret anchor instead.
        var keyboard_now=TextTyper_NormalizeSupplementaryUnicode(keyboard_string);
        var keyboard_changed=keyboard_now!=text_editor_keyboard_seen;
        if(keyboard_changed){
            var old_input_length=string_length(text_editor_keyboard_seen);
            text_editor_keyboard_anchor=clamp(text_editor_keyboard_anchor,0,string_length(text_editor_buffer));
            if(old_input_length>0){
                text_editor_buffer=string_delete(text_editor_buffer,text_editor_keyboard_anchor+1,old_input_length);
            }
            if(string_length(keyboard_now)>0){
                text_editor_buffer=string_insert(keyboard_now,text_editor_buffer,text_editor_keyboard_anchor+1);
            }
            text_editor_caret=text_editor_keyboard_anchor+string_length(keyboard_now);
            text_editor_keyboard_seen=keyboard_now;
        }
        if(keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right)||keyboard_check_pressed(vk_home)||keyboard_check_pressed(vk_end)){
            keyboard_string="";text_editor_keyboard_seen="";
            if(keyboard_check_pressed(vk_left)) text_editor_caret=max(0,text_editor_caret-1);
            if(keyboard_check_pressed(vk_right)) text_editor_caret=min(string_length(text_editor_buffer),text_editor_caret+1);
            if(keyboard_check_pressed(vk_home)) text_editor_caret=0;
            if(keyboard_check_pressed(vk_end)) text_editor_caret=string_length(text_editor_buffer);
            text_editor_keyboard_anchor=text_editor_caret;
        }
        if(keyboard_check_pressed(vk_backspace)&&!keyboard_changed&&text_editor_caret>0){
            text_editor_buffer=string_delete(text_editor_buffer,text_editor_caret,1);
            text_editor_caret-=1;
            keyboard_string="";text_editor_keyboard_seen="";text_editor_keyboard_anchor=text_editor_caret;
        }
        if(keyboard_check_pressed(vk_delete)&&text_editor_caret<string_length(text_editor_buffer)){
            text_editor_buffer=string_delete(text_editor_buffer,text_editor_caret+1,1);
            keyboard_string="";text_editor_keyboard_seen="";text_editor_keyboard_anchor=text_editor_caret;
        }
        if(keyboard_check_pressed(vk_enter)){
            keyboard_string="";text_editor_keyboard_seen="";
            text_editor_buffer=string_insert(chr(10),text_editor_buffer,text_editor_caret+1);
            text_editor_caret+=1;
            text_editor_keyboard_anchor=text_editor_caret;
        }
    }else if(text_editor_focus=="hex"){
        var hex_edit=BattleEditor_SingleLineEditStep(text_editor_hex,text_editor_hex_caret,text_editor_hex_keyboard_seen,text_editor_hex_keyboard_anchor);
        text_editor_hex=hex_edit.buffer;
        text_editor_hex_caret=hex_edit.caret;
        text_editor_hex_keyboard_seen=hex_edit.keyboard_seen;
        text_editor_hex_keyboard_anchor=hex_edit.keyboard_anchor;
    }

    if(keyboard_check_pressed(vk_escape)||click&&BattleEditor_PointInRect(mx,my,554,56,572,78)){
        text_editor_open=false;text_editor_help=false;text_editor_focus="";keyboard_string="";
        text_editor_ime_active=false;
        if(os_type==os_windows) keyboard_virtual_hide();
        input_capture_frames=3;
        exit;
    }
    if(click&&BattleEditor_PointInRect(mx,my,526,56,552,78)) text_editor_help=!text_editor_help;
    if(text_editor_help){
        if(click&&BattleEditor_PointInRect(mx,my,474,390,562,414)) text_editor_help=false;
        exit;
    }

    if(click&&BattleEditor_PointInRect(mx,my,76,86,564,304)){
        text_editor_focus="text";
        text_editor_caret=BattleEditor_TextCaretFromPoint(string_replace_all(text_editor_buffer,"&","#"),mx,my,84,94,18,468);
        keyboard_string="";
        text_editor_keyboard_seen="";
        text_editor_keyboard_anchor=text_editor_caret;
    }else if(click&&BattleEditor_PointInRect(mx,my,168,366,300,388)){
        text_editor_focus="hex";
        text_editor_hex_caret=BattleEditor_SingleLineCaretFromPoint(text_editor_hex,text_editor_hex_caret,123,mx,172);
        text_editor_hex_keyboard_seen="";text_editor_hex_keyboard_anchor=text_editor_hex_caret;keyboard_string="";
    }else if(click&&BattleEditor_PointInRect(mx,my,76,338,562,360)){
        var insert_before="";
        var insert_after="";
        if(BattleEditor_PointInRect(mx,my,76,338,122,360)) insert_before="<br>";
        else if(BattleEditor_PointInRect(mx,my,124,338,170,360)) insert_before="<page>";
        else if(BattleEditor_PointInRect(mx,my,172,338,218,360)) insert_before="<wait=0.5>";
        else if(BattleEditor_PointInRect(mx,my,220,338,266,360)){
            color_picker_open=true;color_picker_target="color";
            var parsed_picker=BattleEditor_ParseHexColor(text_editor_hex);
            if(!is_undefined(parsed_picker)){
                color_picker_hue=color_get_hue(parsed_picker.color);
                color_picker_saturation=color_get_saturation(parsed_picker.color);
                color_picker_value=color_get_value(parsed_picker.color);
                color_picker_alpha=round(parsed_picker.alpha*255);
            }
        }
        else if(BattleEditor_PointInRect(mx,my,268,338,314,360)){
            color_picker_open=true;color_picker_target="gradient";
            var parsed_gradient_picker=BattleEditor_ParseHexColor(text_editor_hex);
            if(!is_undefined(parsed_gradient_picker)){
                color_picker_hue=color_get_hue(parsed_gradient_picker.color);
                color_picker_saturation=color_get_saturation(parsed_gradient_picker.color);
                color_picker_value=color_get_value(parsed_gradient_picker.color);
                color_picker_alpha=round(parsed_gradient_picker.alpha*255);
            }
        }
        else if(BattleEditor_PointInRect(mx,my,316,338,362,360)){insert_before="<shake>";insert_after="</shake>";}
        else if(BattleEditor_PointInRect(mx,my,364,338,410,360)){insert_before="<glitch>";insert_after="</glitch>";}
        else if(BattleEditor_PointInRect(mx,my,412,338,458,360)){insert_before="<float>";insert_after="</float>";}
        else if(BattleEditor_PointInRect(mx,my,460,338,506,360)){insert_before="<rotate=15>";insert_after="</rotate>";}
        else if(BattleEditor_PointInRect(mx,my,508,338,562,360)){insert_before="<cycle>";insert_after="</cycle>";}
        if(!color_picker_open){
            text_editor_buffer=string_insert(insert_before+insert_after,text_editor_buffer,text_editor_caret+1);
            text_editor_caret+=string_length(insert_before);
        }
    }
    if(click&&BattleEditor_PointInRect(mx,my,76,338,562,360)){
        text_editor_focus="text";keyboard_string="";text_editor_keyboard_seen="";text_editor_keyboard_anchor=text_editor_caret;
    }

    // Markup validation is content-driven. The old code recompiled the same
    // text every Step while this window was open, including completely idle
    // frames, which is especially wasteful on mobile targets.
    if(text_editor_markup_source!=text_editor_buffer){
        var markup_result=TextTyper_CompileMarkup(text_editor_buffer);
        text_editor_error=markup_result.error;
        if(text_editor_error!=""){
            var error_location=TextTyper_MarkupErrorLocation(text_editor_buffer,markup_result.error_index);
            text_editor_error+="（第 "+string(error_location.line)+" 行，第 "+string(error_location.column)+" 列）";
        }
        text_editor_markup_source=text_editor_buffer;
    }
    if(click&&BattleEditor_PointInRect(mx,my,392,394,474,416)){
        text_editor_open=false;text_editor_help=false;text_editor_focus="";keyboard_string="";
        text_editor_ime_active=false;
        if(os_type==os_windows) keyboard_virtual_hide();
        input_capture_frames=3;
    }else if(click&&BattleEditor_PointInRect(mx,my,480,394,562,416)){
        if(text_editor_error==""){
            var edited_turn_data=BattleEditor_GetTurnData(project,developer_turn,true);
            if(text_editor_target=="turn") edited_turn_data.text=text_editor_buffer;
            else if(text_editor_target=="dialogue") edited_turn_data.dialogue=text_editor_buffer;
            else if(text_editor_target=="enemy_action_text"&&selected_enemy>=0&&selected_enemy<array_length(project.initialization.enemies)){
                var text_action_enemy=project.initialization.enemies[selected_enemy];
                if(selected_enemy_action>=0&&selected_enemy_action<array_length(text_action_enemy.actions)) text_action_enemy.actions[selected_enemy_action].text=text_editor_buffer;
            }
            else if(text_editor_target=="script_enemy_speech"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) project.script_lists[script_selected_list].steps[script_selected_step].text_value=text_editor_buffer;
            else if(text_editor_target=="item"&&selected_item>=0&&selected_item<array_length(project.initialization.items)){
                project.initialization.items[selected_item].eat_text=text_editor_buffer;
                BattleEditor_ApplyInitialization(project);
            }
            else if(text_editor_target=="mercy_spare_response") project.initialization.mercy_spare_response=text_editor_buffer;
            else if(text_editor_target=="mercy_flee_success") project.initialization.mercy_flee_success_text=text_editor_buffer;
            else if(text_editor_target=="mercy_flee_fail") project.initialization.mercy_flee_fail_text=text_editor_buffer;
            else if(text_editor_target=="typewriter"&&selected>=0&&selected<array_length(project.events)&&project.events[selected].kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
                project.events[selected].text=text_editor_buffer;
                timeline_duration_dirty=true;
            }
            text_editor_open=false;text_editor_help=false;text_editor_focus="";keyboard_string="";
            text_editor_ime_active=false;
            if(os_type==os_windows) keyboard_virtual_hide();
            input_capture_frames=3;status_text="文本已更新";
        }
    }
    exit;
}

// A scrubbed frame is a UI-visible half-play state. Space/Escape explicitly
// leaves it and restores the real player-turn starting state.
if(timeline_half_play){
    global.delta_time_factor=0;
    if(keyboard_check_pressed(vk_space)||keyboard_check_pressed(vk_escape)){
        BattleEditor_RuntimeStop(id);
        preserve_paused_board=false;
        board_edit_session=false;
        cursor_time=0;
        BattleEditor_RestoreAuthoringBoard(id);
        status_text="已退出时间轴重放并恢复玩家回合";
        exit;
    }
}

if(playing){
    // Full editor preview hides the controls but is not an actual monster
    // turn. Space holds the current frame; its natural end is held as well.
    BattleEditor_RuntimeStep(id);
    if(!playing&&timeline_half_play){
        board_edit_session=true;
        status_text="预览结束，已定格 "+BattleEditor_FormatTimelineTime(cursor_time)+"；空格恢复，或继续放置细节";
    }else if(keyboard_check_pressed(vk_space)){
        BattleEditor_RuntimeFreezeAtCursor(id,playhead);
        board_edit_session=true;
        status_text="已拖住 "+BattleEditor_FormatTimelineTime(cursor_time)+"；空格恢复，或继续放置细节";
    }else if(keyboard_check_pressed(vk_escape)){
        BattleEditor_RuntimeStop(id);
        preserve_paused_board=false;
        board_edit_session=false;
        cursor_time=0;
        BattleEditor_RestoreAuthoringBoard(id);
    }
    exit;
}

// Space starts a full replay only from the player-turn editor. Text fields and
// open menus retain Space as ordinary input/interaction.
if(!timeline_half_play&&tab==0&&focus_field==""&&!text_editor_open&&!object_palette&&!hazard_palette&&!board_palette&&!choice_menu_open&&!context_open&&keyboard_check_pressed(vk_space)){
    BattleEditor_RuntimeStart(id);
    // RuntimeStart first clears the previous preview, including this flag.
    timeline_full_play=true;
    status_text="正在播放下一怪物回合；空格拖住，Esc 恢复";
    exit;
}

// Keep the exact last runtime frame visible after pausing.  The first actual
// editor click deliberately returns to authored initialization data so scene
// dragging/property editing never mutates a transient runtime board.
if(preserve_paused_board&&(click||right_click)){
    preserve_paused_board=false;
    if(instance_exists(battle_board)&&(board_edit_session||tab==0)) BattleEditor_SyncBoardPreview(id,true);
}

if(font_dropdown_open){
    var font_count=TextTyper_FontCount();
    if(mouse_wheel_up()) font_dropdown_scroll=max(0,font_dropdown_scroll-1);
    if(mouse_wheel_down()) font_dropdown_scroll=min(max(0,font_count-10),font_dropdown_scroll+1);
    if(click){
        var font_visible=min(10,font_count-font_dropdown_scroll);
        if(BattleEditor_PointInRect(mx,my,286,118,570,118+font_visible*24)){
            var chosen_font=font_dropdown_scroll+floor((my-118)/24);
            if(chosen_font>=0&&chosen_font<font_count){
                var font_turn_data=BattleEditor_GetTurnData(project,developer_turn,true);
                if(font_dropdown_target=="turn") font_turn_data.turn_font=chosen_font;
                else if(font_dropdown_target=="dialogue") font_turn_data.dialogue_font=chosen_font;
                else if(font_dropdown_target=="script_enemy_speech"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)){
                    project.script_lists[script_selected_list].steps[script_selected_step].dialogue_font=chosen_font;
                }
                else if(font_dropdown_target=="typewriter"&&selected>=0&&selected<array_length(project.events)&&project.events[selected].kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
                    project.events[selected].font_id=chosen_font;
                    if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"font_id",wave_inspector_phase,group_selection_type,group_selection_control_id);
                }
                status_text="字体："+TextTyper_FontName(chosen_font);
            }
        }
        font_dropdown_open=false;font_dropdown_target="";
    }
    exit;
}

if(damage_dropdown_open){
    // Damage/colour rules are a real menu, not a click-to-cycle mystery value.
    // The same menu is shared by every hazard inspector.
    if(click){
        if(BattleEditor_PointInRect(mx,my,438,120,632,336)){
            var chosen_damage_type=clamp(floor((my-120)/24),0,8);
            if(damage_dropdown_event>=0&&damage_dropdown_event<array_length(project.events)){
                var damage_event=project.events[damage_dropdown_event];
                var old_damage_type=damage_event.damage_profile.type;
                var old_default_damage=BattleEditor_DefaultDamageForType(old_damage_type);
                var used_old_default=damage_event.damage_profile.damage==old_default_damage;
                BattleEditor_ApplyDamageTypeToEvent(damage_event,chosen_damage_type);
                // A freshly-created/default attack adopts the exact AllScript
                // value for its new colour. An explicitly edited damage value
                // is preserved when the author only changes the rule colour.
                if(chosen_damage_type==3) {
                    if(damage_event.damage_profile.heal_amount<=0) damage_event.damage_profile.heal_amount=BattleEditor_DefaultDamageForType(3);
                } else if(used_old_default) damage_event.damage_profile.damage=BattleEditor_DefaultDamageForType(chosen_damage_type);
                if(group_selection_active&&damage_dropdown_event==selected) BattleEditor_SyncEventGroupField(project,selected,"damage_type",wave_inspector_phase,group_selection_type,group_selection_control_id);
                status_text="颜色规则："+BattleEditor_DamageTypeName(chosen_damage_type);
            }
        }
        damage_dropdown_open=false;
        damage_dropdown_event=-1;
    }
    exit;
}

if(gb_spawn_dropdown_open){
    var gb_spawn_first=gb_spawn_dropdown_event==-1?1:0;
    var gb_spawn_count=19-gb_spawn_first;
    if(mouse_wheel_up()) gb_spawn_dropdown_scroll=max(0,gb_spawn_dropdown_scroll-1);
    if(mouse_wheel_down()) gb_spawn_dropdown_scroll=min(max(0,gb_spawn_count-10),gb_spawn_dropdown_scroll+1);
    if(click){
        var gb_spawn_visible=min(10,gb_spawn_count-gb_spawn_dropdown_scroll);
        if(BattleEditor_PointInRect(mx,my,350,102,632,102+gb_spawn_visible*24)){
            var gb_spawn_value=gb_spawn_first+gb_spawn_dropdown_scroll+floor((my-102)/24);
            if(gb_spawn_dropdown_event==-1) project.initialization.gb_spawn_default.preset=gb_spawn_value;
            else if(gb_spawn_dropdown_event>=0&&gb_spawn_dropdown_event<array_length(project.events)){
                project.events[gb_spawn_dropdown_event].spawn_preset=gb_spawn_value;
                if(group_selection_active&&gb_spawn_dropdown_event==selected) BattleEditor_SyncEventGroupField(project,selected,"spawn_preset",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            status_text="GB 出生位置："+BattleEditor_GBSpawnPresetName(gb_spawn_value);
        }
        gb_spawn_dropdown_open=false;
        gb_spawn_dropdown_event=-2;
    }
    exit;
}

if(gb_style_dropdown_open){
    var gb_style_choice_count=1+array_length(project.resources.gb_styles);
    if(mouse_wheel_up()) gb_style_dropdown_scroll=max(0,gb_style_dropdown_scroll-1);
    if(mouse_wheel_down()) gb_style_dropdown_scroll=min(max(0,gb_style_choice_count-10),gb_style_dropdown_scroll+1);
    if(click){
        var gb_style_choice_visible=min(10,gb_style_choice_count-gb_style_dropdown_scroll);
        if(BattleEditor_PointInRect(mx,my,350,102,632,102+gb_style_choice_visible*24)&&gb_style_dropdown_event>=0&&gb_style_dropdown_event<array_length(project.events)){
            var gb_style_choice_index=gb_style_dropdown_scroll+floor((my-102)/24);
            project.events[gb_style_dropdown_event].gb_style_uid=BattleEditor_WorkspaceCreateChoiceValue("gb_style",gb_style_choice_index,project);
            if(group_selection_active&&gb_style_dropdown_event==selected) BattleEditor_SyncEventGroupField(project,selected,"gb_style_uid",wave_inspector_phase,group_selection_type,group_selection_control_id);
            status_text="GB 贴图组："+BattleEditor_GBStyleCaption(project,project.events[gb_style_dropdown_event].gb_style_uid);
        }
        gb_style_dropdown_open=false;gb_style_dropdown_event=-1;
    }
    exit;
}

if(choice_menu_open){
    var editor_choice_count=BattleEditor_EditorChoiceCount(choice_menu_kind);
    if(mouse_wheel_up()) choice_menu_scroll=max(0,choice_menu_scroll-1);
    if(mouse_wheel_down()) choice_menu_scroll=min(max(0,editor_choice_count-10),choice_menu_scroll+1);
    if(click){
        var editor_choice_visible=min(10,editor_choice_count-choice_menu_scroll);
        if(BattleEditor_PointInRect(mx,my,420,102,632,102+editor_choice_visible*24)){
            var editor_choice_value=choice_menu_scroll+floor((my-102)/24);
            if(choice_menu_context=="create_layer"){
                create_layer_mode=editor_choice_value;
                create_layer_user_set=true;
            }
            else if(choice_menu_context=="event_layer"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].layer_mode=editor_choice_value;
                project.events[choice_menu_event].clipped=editor_choice_value==BATTLE_EDITOR_LAYER.IN_BOARD;
                if(project.events[choice_menu_event].kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD) project.events[choice_menu_event].layer_user_set=true;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"layer_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="visual_color_mode"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                BattleEditor_SetVisualTintMode(project.events[choice_menu_event],editor_choice_value);
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"visual_color_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="visual_color_preset"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                BattleEditor_SetVisualTintPreset(project.events[choice_menu_event],editor_choice_value);
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"visual_color_preset",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="bone_style"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].bone_style=clamp(editor_choice_value,0,1);
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"bone_style",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="bone_aim_behavior"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                var aim_choice_event=project.events[choice_menu_event];
                aim_choice_event.aim_enabled=editor_choice_value!=0;
                aim_choice_event.aim_move_enabled=editor_choice_value==2;
                if(group_selection_active&&choice_menu_event==selected){
                    BattleEditor_SyncEventGroupField(project,selected,"aim_enabled",wave_inspector_phase,group_selection_type,group_selection_control_id);
                    BattleEditor_SyncEventGroupField(project,selected,"aim_move_enabled",wave_inspector_phase,group_selection_type,group_selection_control_id);
                }
            }else if(choice_menu_context=="bone_aim_update"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].aim_continuous=editor_choice_value==1;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"aim_continuous",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="gb_fake"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].fake_mode=editor_choice_value;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"fake_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="gb_tween"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].transform.tween=editor_choice_value;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"track_tween",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(choice_menu_context=="gb_offset_direction"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].offset_direction_mode=editor_choice_value;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"gb_offset_direction_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(choice_menu_context=="solid_shape"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                BattleEditor_SetSolidBoneField(project.events[choice_menu_event],"shape_3d",editor_choice_value);
            }
            else if(string_pos("wave_",choice_menu_context)==1&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                var choice_wave=project.events[choice_menu_event];
                var choice_motion=choice_menu_phase==0?choice_wave.pre_motion:choice_wave.post_motion;
                if(choice_menu_context=="wave_rotation") choice_motion.rotation_mode=editor_choice_value;
                else if(choice_menu_context=="wave_tween") choice_motion.tween=editor_choice_value;
                else choice_motion.ease=editor_choice_value;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,choice_menu_context=="wave_rotation"?"wave_rotation_mode":choice_menu_context,wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(choice_menu_context=="shield_mode"){
                project.initialization.shield_hud_mode=editor_choice_value;
                BattleEditor_ApplyInitialization(project);
            }else if(choice_menu_context=="dialogue_template") BattleEditor_GetTurnData(project,developer_turn,true).dialogue_template=editor_choice_value;
            else if(choice_menu_context=="turn_voice") BattleEditor_GetTurnData(project,developer_turn,true).turn_voice=BattleEditor_VoiceChoiceToId(editor_choice_value);
            else if(choice_menu_context=="dialogue_voice") BattleEditor_GetTurnData(project,developer_turn,true).dialogue_voice=BattleEditor_VoiceChoiceToId(editor_choice_value);
            else if(choice_menu_context=="script_enemy_voice"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) project.script_lists[script_selected_list].steps[script_selected_step].dialogue_voice=BattleEditor_VoiceChoiceToId(editor_choice_value);
            else if(choice_menu_context=="script_enemy_template"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) project.script_lists[script_selected_list].steps[script_selected_step].dialogue_template=editor_choice_value;
            else if(choice_menu_context=="script_enemy_mode"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) project.script_lists[script_selected_list].steps[script_selected_step].dialogue_mode=editor_choice_value;
            else if(choice_menu_context=="item_voice"&&selected_item>=0&&selected_item<array_length(project.initialization.items)){
                project.initialization.items[selected_item].voice_id=BattleEditor_VoiceChoiceToId(editor_choice_value);
                BattleEditor_ApplyInitialization(project);
            }
            else if(choice_menu_context=="item_after_use"&&selected_item>=0&&selected_item<array_length(project.initialization.items)){
                project.initialization.items[selected_item].after_use_mode=editor_choice_value;
                status_text="物品使用后："+BattleEditor_ItemAfterUseModeName(editor_choice_value);
            }
            else if(choice_menu_context=="typewriter_voice"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].voice_id=BattleEditor_VoiceChoiceToId(editor_choice_value);
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"typewriter_voice",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(choice_menu_context=="platform_type"&&choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
                project.events[choice_menu_event].sticky=editor_choice_value==1;
                if(group_selection_active&&choice_menu_event==selected) BattleEditor_SyncEventGroupField(project,selected,"platform_sticky",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(choice_menu_context=="enemy_part") selected_enemy_part=editor_choice_value;
        }
        choice_menu_open=false;choice_menu_context="";choice_menu_kind="";
    }
    exit;
}

if(follow_dropdown_open){
    var follow_options=BattleEditor_FollowFrameOptions(project);
    var follow_visible=min(8,max(0,array_length(follow_options)-follow_dropdown_scroll));
    if(mouse_wheel_up()) follow_dropdown_scroll=max(0,follow_dropdown_scroll-1);
    if(mouse_wheel_down()) follow_dropdown_scroll=min(max(0,array_length(follow_options)-8),follow_dropdown_scroll+1);
    if(click){
        if(BattleEditor_PointInRect(mx,my,438,120,632,120+follow_visible*24)){
            var follow_index=follow_dropdown_scroll+floor((my-120)/24);
            if(follow_index>=0&&follow_index<array_length(follow_options)&&follow_dropdown_event>=0&&follow_dropdown_event<array_length(project.events)){
                var follow_event=project.events[follow_dropdown_event];
                if(group_selection_active&&follow_dropdown_event==selected) BattleEditor_SetGroupBoneFollow(project,selected,true,follow_options[follow_index].uid,main_board_preview,group_selection_type,group_selection_control_id);
                else BattleEditor_BoneSetFollow(follow_event,true,project,main_board_preview,follow_options[follow_index].uid);
                status_text="跟随："+BattleEditor_FollowFrameCaption(project,follow_event.follow_target_uid);
            }
        }
        follow_dropdown_open=false;
        follow_dropdown_event=-1;
    }
    exit;
}

if(aim_dropdown_open){
    var aim_self_uid=-1;
    if(aim_dropdown_event>=0&&aim_dropdown_event<array_length(project.events)) aim_self_uid=project.events[aim_dropdown_event].uid;
    var aim_options=BattleEditor_AimTargetOptions(project,aim_self_uid);
    var aim_visible=min(9,max(0,array_length(aim_options)-aim_dropdown_scroll));
    if(mouse_wheel_up()) aim_dropdown_scroll=max(0,aim_dropdown_scroll-1);
    if(mouse_wheel_down()) aim_dropdown_scroll=min(max(0,array_length(aim_options)-9),aim_dropdown_scroll+1);
    if(click){
        if(BattleEditor_PointInRect(mx,my,350,102,632,102+aim_visible*24)){
            var aim_index=aim_dropdown_scroll+floor((my-102)/24);
            if(aim_index>=0&&aim_index<array_length(aim_options)&&aim_dropdown_event>=0&&aim_dropdown_event<array_length(project.events)){
                project.events[aim_dropdown_event].aim_target_uid=aim_options[aim_index].uid;
                if(group_selection_active&&aim_dropdown_event==selected) BattleEditor_SyncEventGroupField(project,selected,"aim_target_uid",wave_inspector_phase,group_selection_type,group_selection_control_id);
                status_text="指向："+aim_options[aim_index].name;
            }
        }
        aim_dropdown_open=false;
        aim_dropdown_event=-1;
    }
    exit;
}

// Formula fields register their exact Draw rectangles. Right-clicking one
// opens the variable browser and remembers the real caret, so selection inserts
// in the middle of an expression instead of appending a mysterious "+name".
if(right_click&&tab==2&&workspace_open&&is_array(formula_field_hit_regions)){
    for(var formula_hit_index=array_length(formula_field_hit_regions)-1;formula_hit_index>=0;formula_hit_index--){
        var formula_hit=formula_field_hit_regions[formula_hit_index];
        if(!BattleEditor_PointInRect(mx,my,formula_hit.x1,formula_hit.y1,formula_hit.x2,formula_hit.y2)) continue;
        if(script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)){
            var formula_context_step=project.script_lists[script_selected_list].steps[script_selected_step];
            var formula_same_focus=focus_field==formula_hit.field;
            script_formula_target=formula_hit.field;
            script_formula_buffer=formula_same_focus?focus_edit_buffer:BattleEditor_GetStepFormulaField(formula_context_step,formula_hit.field);
            script_formula_insert_caret=formula_same_focus?focus_edit_caret:string_length(script_formula_buffer);
            script_formula_variable_scroll=0;
            script_dropdown="formula_variable";
            focus_field="";focus_last_field="";keyboard_string="";focus_keyboard_seen="";
            input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();
            exit;
        }
    }
}

if(focus_field=="") focus_last_field="";
if(focus_field!=""){
    BattleEditor_SetInputCapture(true);
    // Do not recreate the Windows IME context every Step. This used to cancel
    // composition whenever the field's selected font lacked the typed glyph.
    // Re-enable only when the runner says a previous hide actually won.
    if(os_type==os_windows&&!keyboard_virtual_status()) keyboard_virtual_show(undefined,undefined,undefined,undefined);
    // Remember the committed value which was present when this field received
    // focus. A leading +, * or / is a calculator-style relative edit: a field
    // showing 300 may be replaced with "+10" and commits as 310. A leading
    // minus remains an ordinary negative coordinate; subtraction can still be
    // written explicitly as "300-10" without making -40 impossible to enter.
    if(focus_last_field!=focus_field){
        focus_last_field=focus_field;
        focus_expression_base=string(keyboard_string);
        var focus_base_result=BattleEditor_EvaluateNumberExpression(keyboard_string);
        focus_numeric_base=focus_base_result.valid?focus_base_result.value:0;
        focus_edit_buffer=string(keyboard_string);
        focus_edit_caret=string_length(focus_edit_buffer);
        focus_keyboard_seen="";
        focus_keyboard_anchor=focus_edit_caret;
        keyboard_string="";
        focus_formula_validation_signature="";
        if(BattleEditor_IsFormulaField(focus_field)) script_formula_target=focus_field;
    }
    // A single-line field is a real text editor while it has focus. Accept all
    // input here; field-specific parsing and validation happens only when the
    // author submits or clicks elsewhere.
    var focus_edit=BattleEditor_SingleLineEditStep(focus_edit_buffer,focus_edit_caret,focus_keyboard_seen,focus_keyboard_anchor);
    focus_edit_buffer=focus_edit.buffer;
    focus_edit_caret=focus_edit.caret;
    focus_keyboard_seen=focus_edit.keyboard_seen;
    focus_keyboard_anchor=focus_edit.keyboard_anchor;
    // A second click in the active field positions the caret instead of
    // submitting the value. Search from the topmost drawn field backwards so
    // overlapping/scrolling panels use the rectangle the author can see.
    if(click&&is_array(input_field_hit_regions)){
        for(var active_hit_index=array_length(input_field_hit_regions)-1;active_hit_index>=0;active_hit_index--){
            var active_hit=input_field_hit_regions[active_hit_index];
            if(active_hit.field==focus_field&&BattleEditor_PointInRect(mx,my,active_hit.x1,active_hit.y1,active_hit.x2,active_hit.y2)){
                focus_edit_caret=BattleEditor_SingleLineCaretFromPoint(focus_edit_buffer,focus_edit_caret,active_hit.x2-active_hit.x1-9,mx,active_hit.x1+4);
                keyboard_string="";focus_keyboard_seen="";focus_keyboard_anchor=focus_edit_caret;
                input_capture_frames=3;
                exit;
            }
        }
    }
    if(BattleEditor_IsFormulaField(focus_field)){
        var live_formula_signature=focus_field+"|"+focus_edit_buffer;
        if(live_formula_signature!=focus_formula_validation_signature){
            focus_formula_validation_signature=live_formula_signature;
            if(string_length(string_trim(focus_edit_buffer))<=0) focus_formula_validation={valid:true,error:"",error_pos:0};
            else{
                var live_formula_step=script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
                focus_formula_validation=BattleEditor_EvaluateNumberExpression(focus_edit_buffer,BattleEditor_ExpressionVariablesForFormula(project,live_formula_step,focus_field));
                if(!focus_formula_validation.valid) status_text="公式错误（位置 "+string(focus_formula_validation.error_pos)+"）："+focus_formula_validation.error;
            }
        }
    }
    var submit_by_enter=keyboard_check_pressed(vk_enter);
    var submit_field=submit_by_enter||click;
    var object_time_seek_pending=false;
    var object_time_seek_target=0;
    var object_time_seek_name="对象";
    var cancel_field=keyboard_check_pressed(vk_escape);
    if(cancel_field){
        focus_field="";
        focus_edit_buffer="";focus_keyboard_seen="";
        keyboard_string="";
        input_capture_frames=3;
        if(os_type==os_windows) keyboard_virtual_hide();
        exit;
    }

    // All fields edit a temporary string.  Numeric expressions are evaluated
    // only on Enter or an explicit click away; the model is never rewritten
    // to zero while the author is halfway through "15+10" or has erased the
    // field to type a replacement.
    var is_text_field=focus_field=="turn_text"||focus_field=="character_dialogue"
        ||focus_field=="item_name"||focus_field=="item_text"
        ||focus_field=="script_list_name"||focus_field=="script_builtin_name"||focus_field=="script_builtin_args"
        ||focus_field=="script_action_path_variable"
        ||focus_field=="script_action_control_id"||focus_field=="script_copy_control_id"||string_pos("script_action_param_",focus_field)==1||string_pos("script_screen_param_",focus_field)==1
        ||focus_field=="script_variable_name"||focus_field=="script_read_variable_name"||focus_field=="script_expression"
        ||focus_field=="script_condition_left"||focus_field=="script_condition_right"||focus_field=="script_repeat_count"||focus_field=="script_repeat_interval"
        ||focus_field=="script_value"||focus_field=="script_position_x"||focus_field=="script_position_y"||focus_field=="script_position_angle"
        ||string_pos("script_create_text_",focus_field)==1||focus_field=="script_create_frame"
        ||string_pos("script_physics_",focus_field)==1||string_pos("script_create_",focus_field)==1
        ||focus_field=="enemy_name"||focus_field=="enemy_action_name"||focus_field=="enemy_resource_name"||focus_field=="enemy_sway_x"||focus_field=="enemy_torso_y"||focus_field=="enemy_head_y"
        ||focus_field=="gb_style_name"||focus_field=="gb_style_frame"||focus_field=="gb_style_beam_frame"
        ||focus_field=="enemy_gravity_up"||focus_field=="enemy_gravity_down"||focus_field=="enemy_gravity_left"||focus_field=="enemy_gravity_right"
        ||focus_field=="object_name"||focus_field=="object_control_id"||focus_field=="object_sprite"||focus_field=="object_script"
        ||focus_field=="animation_frame"||focus_field=="typewriter_color"||focus_field=="player_name"
        ||focus_field=="mercy_spare_label"||focus_field=="mercy_flee_label"
        ||focus_field=="frame_name"||focus_field=="frame_control_id"||focus_field=="global_variable_name"||focus_field=="clip_filter";
    var is_runtime_expression_field=BattleEditor_IsFormulaField(focus_field);
    var is_timeline_time_field=focus_field=="object_time"||focus_field=="solid_field_2";
    var submitted_timeline_frames=undefined;
    var allows_blank_number=focus_field=="script_position_x"||focus_field=="script_position_y"||focus_field=="script_position_angle";
    // Clicking away from an empty numeric/formula field cancels that edit and
    // replays the click next Step. This applies to lists and every UI panel,
    // not only the Workspace grid.
    if(click&&!is_text_field&&!is_runtime_expression_field&&!allows_blank_number&&string_length(string_trim(focus_edit_buffer))<=0){
        deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
        focus_field="";focus_edit_buffer="";focus_keyboard_seen="";keyboard_string="";
        input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();exit;
    }
    if(submit_field) keyboard_string=focus_edit_buffer;
    if(is_timeline_time_field){
        if(!submit_field) exit;
        var timeline_time_result=BattleEditor_ParseTimelineTime(keyboard_string,0);
        if(!timeline_time_result.valid){
            if(click){deferred_click=true;deferred_click_x=mx;deferred_click_y=my;focus_field="";focus_edit_buffer="";focus_keyboard_seen="";keyboard_string="";input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();exit;}
            keyboard_string="";focus_keyboard_seen="";focus_keyboard_anchor=focus_edit_caret;
            status_text="时间格式无效；请使用 分:秒.十分之一 或帧数";exit;
        }
        submitted_timeline_frames=timeline_time_result.value;
        keyboard_string=BattleEditor_FormatTimelineTime(timeline_time_result.value);
    }else if(is_runtime_expression_field){
        if(!submit_field) exit;
        var runtime_expression=string(keyboard_string);
        if(string_length(string_trim(runtime_expression))<=0){
            // Empty and whitespace-only formulas are intentional authoring
            // values. Keep them verbatim; each runtime parameter already owns
            // its explicit fallback/default behavior.
            keyboard_string=focus_edit_buffer;
        }else{
            var runtime_expression_first=string_char_at(string_trim(runtime_expression),1);
            // Keep formulas/variables as formulas for runtime evaluation. The
            // calculator-style +/* prefix applies to the previous expression,
            // rather than collapsing it to a number or treating +10 as plain 10.
            if(runtime_expression_first=="+"||runtime_expression_first=="*"||runtime_expression_first=="/"){
                var runtime_expression_base=string_trim(focus_expression_base);
                if(runtime_expression_base=="") runtime_expression_base="0";
                runtime_expression="("+runtime_expression_base+")"+runtime_expression;
            }
            var formula_scope_step=script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
            var runtime_expression_result=BattleEditor_EvaluateNumberExpression(runtime_expression,BattleEditor_ExpressionVariablesForFormula(project,formula_scope_step,focus_field));
            if(!runtime_expression_result.valid){
                status_text="公式错误（位置 "+string(runtime_expression_result.error_pos)+"）："+runtime_expression_result.error;
                if(click){deferred_click=true;deferred_click_x=mx;deferred_click_y=my;focus_field="";focus_edit_buffer="";focus_keyboard_seen="";keyboard_string="";input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();exit;}
                keyboard_string="";focus_keyboard_seen="";focus_keyboard_anchor=focus_edit_caret;
                exit;
            }
            keyboard_string=runtime_expression;
        }
    }else if(!is_text_field){
        keyboard_string=BattleEditor_FilterNumberText(keyboard_string);
        if(!submit_field) exit;
        if(string_length(string_trim(keyboard_string))<=0){
            if(!allows_blank_number){
                if(click){deferred_click=true;deferred_click_x=mx;deferred_click_y=my;focus_field="";focus_edit_buffer="";focus_keyboard_seen="";keyboard_string="";input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();exit;}
                status_text="数值暂时为空；输入完成后按 Enter";exit;
            }
        }else{
            var expression_source=keyboard_string;
            var expression_first=string_char_at(string_trim(expression_source),1);
            if(expression_first=="+"||expression_first=="*"||expression_first=="/") expression_source="("+string(focus_numeric_base)+")"+expression_source;
            var expression_result=BattleEditor_EvaluateNumberExpression(expression_source);
            if(!expression_result.valid){
                if(click){deferred_click=true;deferred_click_x=mx;deferred_click_y=my;focus_field="";focus_edit_buffer="";focus_keyboard_seen="";keyboard_string="";input_capture_frames=3;if(os_type==os_windows) keyboard_virtual_hide();exit;}
                status_text="公式还没有写完整";exit;
            }
            keyboard_string=string(expression_result.value);
        }
    }else if(!submit_field) exit;
    var init=project.initialization;
    if(focus_field=="developer_turn"){
        BattleEditor_SetAuthoringTurn(id,BattleEditor_ReadNumberText(keyboard_string,1));
        status_text="正在编辑第 "+string(developer_turn)+" 回合";
    }
    else if(focus_field=="turn_text") init.turn_text=string_copy(keyboard_string,1,512);
    else if(focus_field=="character_dialogue") init.character_dialogue=string_copy(keyboard_string,1,1024);
    else if((focus_field=="global_variable_name"||focus_field=="global_variable_value")&&script_selected_variable>=0&&script_selected_variable<array_length(project.variables)){
        var edited_global_variable=project.variables[script_selected_variable];
        if(focus_field=="global_variable_name") edited_global_variable.name=string_copy(keyboard_string,1,64);
        else edited_global_variable.value=BattleEditor_ReadNumberText(keyboard_string,edited_global_variable.value);
    }
    else if(focus_field=="player_name"){
        init.player_name=string_copy(keyboard_string,1,64);
        BattleEditor_ApplyInitialization(project);
    }
    else if(focus_field=="mercy_spare_label"||focus_field=="mercy_flee_label"){
        if(focus_field=="mercy_spare_label") init.mercy_spare_label=string_copy(keyboard_string,1,128);
        else init.mercy_flee_label=string_copy(keyboard_string,1,128);
        BattleEditor_ApplyInitialization(project);
    }
    else if(focus_field=="dialogue_offset_x"||focus_field=="dialogue_offset_y"){
        var dialogue_turn_data=BattleEditor_GetTurnData(project,developer_turn,true);
        var dialogue_offset_value=BattleEditor_ReadNumberText(keyboard_string,0);
        if(focus_field=="dialogue_offset_x") dialogue_turn_data.dialogue_offset_x=dialogue_offset_value;
        else dialogue_turn_data.dialogue_offset_y=dialogue_offset_value;
    }
    else if(string_pos("player_",focus_field)==1&&string_pos("player_board_",focus_field)!=1){
        var player_number=BattleEditor_FilterNumberText(keyboard_string);
        keyboard_string=player_number;
        var player_value=BattleEditor_ReadNumberText(player_number,0);
        if(focus_field=="player_lv") init.lv=max(1,round(player_value));
        else if(focus_field=="player_hp") init.hp=clamp(player_value,0,init.max_hp);
        else if(focus_field=="player_max_hp"){init.max_hp=clamp(player_value,1,init.natural_max_hp);init.hp=min(init.hp,init.max_hp);}
        else if(focus_field=="player_natural_max_hp"){init.natural_max_hp=max(1,player_value);init.max_hp=min(init.max_hp,init.natural_max_hp);init.hp=min(init.hp,init.max_hp);}
        else if(focus_field=="player_atk") init.atk=player_value;
        else if(focus_field=="player_def") init.def=player_value;
        else if(focus_field=="player_shield") init.shield=clamp(player_value,0,init.shield_max);
        else if(focus_field=="player_shield_max"){init.shield_max=clamp(player_value,0,init.shield_natural_max);init.shield=min(init.shield,init.shield_max);}
        else if(focus_field=="player_shield_natural_max"){init.shield_natural_max=max(0,player_value);init.shield_max=min(init.shield_max,init.shield_natural_max);init.shield=min(init.shield,init.shield_max);}
        BattleEditor_ApplyInitialization(project);
    }
    else if(string_pos("player_board_",focus_field)==1){
        var player_board_value=BattleEditor_ReadNumberText(keyboard_string,0);
        var player_board=init.player_board;
        if(focus_field=="player_board_x") player_board.x=player_board_value;
        else if(focus_field=="player_board_y") player_board.y=player_board_value;
        else if(focus_field=="player_board_up") player_board.up=max(0,player_board_value);
        else if(focus_field=="player_board_down") player_board.down=max(0,player_board_value);
        else if(focus_field=="player_board_left") player_board.left=max(0,player_board_value);
        else if(focus_field=="player_board_right") player_board.right=max(0,player_board_value);
        else if(focus_field=="player_board_angle") player_board.angle=player_board_value;
        if(instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.MENU) BattleEditor_RestoreAuthoringBoard(id);
    }
    else if(string_pos("init_board_",focus_field)==1){
        var init_board_value=BattleEditor_ReadNumberText(keyboard_string,0);
        var init_board=init.board;
        if(focus_field=="init_board_x") init_board.x=init_board_value;
        else if(focus_field=="init_board_y") init_board.y=init_board_value;
        else if(focus_field=="init_board_up") init_board.up=max(0,init_board_value);
        else if(focus_field=="init_board_down") init_board.down=max(0,init_board_value);
        else if(focus_field=="init_board_left") init_board.left=max(0,init_board_value);
        else if(focus_field=="init_board_right") init_board.right=max(0,init_board_value);
        else if(focus_field=="init_board_angle") init_board.angle=init_board_value;
        main_board_preview=init.board;
        board_edit_session=true;
        BattleEditor_SyncBoardPreview(id,true);
    }
    else if(string_pos("layout_",focus_field)==1){
        var layout_number=BattleEditor_FilterNumberText(keyboard_string);
        keyboard_string=layout_number;
        var layout_value=BattleEditor_ReadNumberText(layout_number,0);
        if(focus_field=="layout_enemy_x") init.enemy_x=layout_value;
        else if(focus_field=="layout_enemy_y") init.enemy_y=layout_value;
        else if(focus_field=="layout_hud_x") init.hud_x=layout_value;
        else if(focus_field=="layout_hud_y") init.hud_y=layout_value;
        else if(focus_field=="layout_turn_text_x") init.turn_text_x=layout_value;
        else if(focus_field=="layout_turn_text_y") init.turn_text_y=layout_value;
        BattleEditor_ApplyLayout(init);
    }
    else if(string_pos("global_board_color_",focus_field)==1){
        var global_color_text=string_digits(keyboard_string);
        keyboard_string=global_color_text;
        var global_color_value=clamp(real(global_color_text==""?"0":global_color_text),0,255);
        var global_red=color_get_red(init.board_color_default);
        var global_green=color_get_green(init.board_color_default);
        var global_blue=color_get_blue(init.board_color_default);
        if(focus_field=="global_board_color_r") global_red=global_color_value;
        else if(focus_field=="global_board_color_g") global_green=global_color_value;
        else global_blue=global_color_value;
        init.board_color_default=make_color_rgb(global_red,global_green,global_blue);
        init.board.color_frame=init.board_color_default;
        main_board_preview.color_frame=init.board_color_default;
        BattleEditor_ApplyInitialization(project);
        if(board_edit_session||tab==0) BattleEditor_SyncBoardPreview(id,true);
    }
    else if(string_pos("global_gb_",focus_field)==1){
        var global_number=BattleEditor_FilterNumberText(keyboard_string);
        keyboard_string=global_number;
        if(focus_field=="global_gb_x") init.gb_spawn_default.x=BattleEditor_ReadNumberText(global_number,init.gb_spawn_default.x);
        else if(focus_field=="global_gb_y") init.gb_spawn_default.y=BattleEditor_ReadNumberText(global_number,init.gb_spawn_default.y);
        else if(focus_field=="global_gb_angle") init.gb_spawn_default.angle=BattleEditor_ReadNumberText(global_number,init.gb_spawn_default.angle);
        else if(focus_field=="global_gb_distance") init.gb_spawn_default.distance=max(1,BattleEditor_ReadNumberText(global_number,init.gb_spawn_default.distance));
    }
    else if(string_pos("gb_style_",focus_field)==1&&selected_gb_style>=0&&selected_gb_style<array_length(project.resources.gb_styles)){
        var edited_gb_style=project.resources.gb_styles[selected_gb_style];
        if(focus_field=="gb_style_name") edited_gb_style.name=BattleEditor_UniqueGBStyleName(project,string_copy(keyboard_string,1,64),edited_gb_style.uid);
        else if(focus_field=="gb_style_frame"){
            var edited_gb_path=string_copy(keyboard_string,1,1024);
            if(file_exists(edited_gb_path)) edited_gb_style.animation.frames[selected_gb_style_frame]=BattleEditor_StageResource(edited_gb_path);
            else status_text="帧图片不存在；保留原来的帧";
        }else if(focus_field=="gb_style_beam_frame"){
            var edited_beam_path=string_copy(keyboard_string,1,1024);
            if(file_exists(edited_beam_path)) edited_gb_style.beam.variants[selected_gb_beam_variant].animation.frames[selected_gb_beam_frame]=BattleEditor_StageResource(edited_beam_path);
            else status_text="光束图片不存在；保留原来的帧";
        }else if(focus_field=="gb_style_interval") edited_gb_style.animation.frame_interval=max(1,round(BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.animation.frame_interval)));
        else if(focus_field=="gb_style_origin_x") edited_gb_style.origin_x=BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.origin_x);
        else if(focus_field=="gb_style_origin_y") edited_gb_style.origin_y=BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.origin_y);
        else if(focus_field=="gb_style_beam_interval") edited_gb_style.beam.variants[selected_gb_beam_variant].animation.frame_interval=max(1,round(BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.variants[selected_gb_beam_variant].animation.frame_interval)));
        else if(focus_field=="gb_style_beam_offset") edited_gb_style.beam.source_offset=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.source_offset));
        else if(focus_field=="gb_style_beam_scale") edited_gb_style.beam.base_scale=max(0.01,BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.base_scale));
        else if(focus_field=="gb_style_beam_launch") edited_gb_style.beam.launch_ratio=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.launch_ratio));
        else if(focus_field=="gb_style_beam_breath") edited_gb_style.beam.breath_ratio=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.breath_ratio));
        else if(focus_field=="gb_style_beam_hit_inset") edited_gb_style.beam.hit_inset=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_gb_style.beam.hit_inset));
    }
    else if(string_pos("enemy_",focus_field)==1&&selected_enemy>=0&&selected_enemy<array_length(init.enemies)){
        var edit_enemy=init.enemies[selected_enemy];
        var edit_enemy_keys=BattleEditor_EnemyPartKeys();
        var edit_enemy_part=variable_struct_get(edit_enemy.parts,edit_enemy_keys[clamp(selected_enemy_part,0,array_length(edit_enemy_keys)-1)]);
        if(focus_field=="enemy_action_name"&&selected_enemy_action>=0&&selected_enemy_action<array_length(edit_enemy.actions)) edit_enemy.actions[selected_enemy_action].name=string_copy(keyboard_string,1,64);
        else if(focus_field=="enemy_name") edit_enemy.name=string_copy(keyboard_string,1,64);
        else if(focus_field=="enemy_resource_name"){
            var edit_enemy_resource=BattleEditor_FindEnemyTextureResource(project,edit_enemy_part.asset_uid);
            if(!is_undefined(edit_enemy_resource)) edit_enemy_resource.name=string_copy(keyboard_string,1,64);
        }
        else if(focus_field=="enemy_control_id") edit_enemy.control_id=string_copy(keyboard_string,1,64);
        else if(focus_field=="enemy_sway_x") edit_enemy.sway_x=string_copy(keyboard_string,1,256);
        else if(focus_field=="enemy_torso_y") edit_enemy.torso_y=string_copy(keyboard_string,1,256);
        else if(focus_field=="enemy_head_y") edit_enemy.head_y=string_copy(keyboard_string,1,256);
        else if(focus_field=="enemy_gravity_up") edit_enemy.animation_scripts.gravity_up=string_copy(keyboard_string,1,128);
        else if(focus_field=="enemy_gravity_down") edit_enemy.animation_scripts.gravity_down=string_copy(keyboard_string,1,128);
        else if(focus_field=="enemy_gravity_left") edit_enemy.animation_scripts.gravity_left=string_copy(keyboard_string,1,128);
        else if(focus_field=="enemy_gravity_right") edit_enemy.animation_scripts.gravity_right=string_copy(keyboard_string,1,128);
        else{
            var edit_enemy_number=BattleEditor_ReadNumberText(keyboard_string,0);
            if(focus_field=="enemy_x") edit_enemy.x=edit_enemy_number;
            else if(focus_field=="enemy_y") edit_enemy.y=edit_enemy_number;
            else if(focus_field=="enemy_scale_x") edit_enemy.scale_x=max(0.01,edit_enemy_number);
            else if(focus_field=="enemy_scale_y") edit_enemy.scale_y=max(0.01,edit_enemy_number);
            else if(focus_field=="enemy_part_x") edit_enemy_part.offset_x=edit_enemy_number;
            else if(focus_field=="enemy_part_y") edit_enemy_part.offset_y=edit_enemy_number;
            else if(focus_field=="enemy_origin_x") edit_enemy_part.origin_x=edit_enemy_number;
            else if(focus_field=="enemy_origin_y") edit_enemy_part.origin_y=edit_enemy_number;
            else if(focus_field=="enemy_animation_fps"){
                var edit_animation_resource=BattleEditor_FindEnemyTextureResource(project,edit_enemy_part.asset_uid);
                if(!is_undefined(edit_animation_resource)) edit_animation_resource.animation.fps=max(0.001,edit_enemy_number);
            }
        }
        enemy_editor_cache_dirty=true;
        if(selected_enemy==0){init.enemy_x=edit_enemy.x;init.enemy_y=edit_enemy.y;}
        if(focus_field=="enemy_action_name") BattleEditor_ApplyInitialization(project); else BattleEditor_ApplyLayout(init);
    }
    else if(string_pos("item_",focus_field)==1&&selected_item>=0&&selected_item<array_length(init.items)){
        var edit_item=init.items[selected_item];
        switch(focus_field){
            case "item_name": edit_item.name=string_copy(keyboard_string,1,64); break;
            case "item_heal":
                var filtered=string_digits(keyboard_string);
                keyboard_string=filtered;
                edit_item.heal=max(0,real(filtered==""?"0":filtered));
                break;
            case "item_text": edit_item.eat_text=string_copy(keyboard_string,1,512); break;
        }
        BattleEditor_ApplyInitialization(project);
    }else if(string_pos("script_",focus_field)==1&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)){
        var input_list=project.script_lists[script_selected_list];
        if(focus_field=="script_list_name") input_list.name=string_copy(keyboard_string,1,64);
        else if(focus_field=="script_entry_value"){
            if(input_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN||input_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE){
                var entry_number=BattleEditor_FilterNumberText(keyboard_string);
                keyboard_string=entry_number;
                input_list.entry_value=BattleEditor_ReadNumberText(entry_number,0);
            }else input_list.entry_value=string_copy(keyboard_string,1,64);
        }else if(script_selected_step>=0&&script_selected_step<array_length(input_list.steps)){
            var input_step=input_list.steps[script_selected_step];
            if(BattleEditor_IsFormulaField(focus_field)) BattleEditor_SetStepFormulaField(input_step,focus_field,string_copy(keyboard_string,1,256));
            else if(focus_field=="script_action_path_variable"){
                var next_path_variable=string_trim(string_copy(keyboard_string,1,64));
                if(!BattleEditor_FunctionPathVariableNameValid(next_path_variable)){
                    status_text="局部自变量名称无效；不能使用 pi、e 或 progress";
                    exit;
                }
                input_step.action_path_variable=next_path_variable;
            }
            else if(focus_field=="script_text_value") input_step.text_value=string_copy(keyboard_string,1,128);
            else if(focus_field=="script_position_x"){
                var position_x_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=position_x_text;
                input_step.position_x=position_x_text;
            }else if(focus_field=="script_position_y"){
                var position_y_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=position_y_text;
                input_step.position_y=position_y_text;
            }else if(focus_field=="script_position_angle"){
                var position_angle_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=position_angle_text;
                input_step.position_angle=position_angle_text;
            }else if(focus_field=="script_orbit_center_x"){
                var orbit_x_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=orbit_x_text;
                input_step.orbit_center_x=orbit_x_text;
            }else if(focus_field=="script_orbit_center_y"){
                var orbit_y_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=orbit_y_text;
                input_step.orbit_center_y=orbit_y_text;
            }else if(focus_field=="script_physics_direction") input_step.physics_direction=keyboard_string;
            else if(focus_field=="script_physics_speed") input_step.physics_speed=keyboard_string;
            else if(focus_field=="script_physics_acceleration") input_step.physics_acceleration=keyboard_string;
            else if(focus_field=="script_physics_curve_speed") input_step.physics_curve_speed=keyboard_string;
            else if(focus_field=="script_physics_rotation_speed") input_step.physics_rotation_speed=keyboard_string;
            else if(focus_field=="script_aim_move_speed") input_step.aim_move_speed=keyboard_string;
            else if(focus_field=="script_vertex_x"){
                var vertex_x_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=vertex_x_text;
                input_step.vertex_target_x=BattleEditor_ReadNumberText(vertex_x_text,0);
            }else if(focus_field=="script_vertex_y"){
                var vertex_y_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=vertex_y_text;
                input_step.vertex_target_y=BattleEditor_ReadNumberText(vertex_y_text,0);
            }else if(focus_field=="script_duration"){
                var duration_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=duration_text;
                input_step.duration=max(0,BattleEditor_ReadNumberText(duration_text,0));
            }else if(focus_field=="script_wait_extra_duration"){
                var wait_extra_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=wait_extra_text;
                input_step.wait_extra_duration=max(0,BattleEditor_ReadNumberText(wait_extra_text,0));
            }else if(focus_field=="script_warning_duration"){
                var warning_duration_text=BattleEditor_FilterNumberText(keyboard_string);keyboard_string=warning_duration_text;
                input_step.warning_duration=max(1,round(BattleEditor_ReadNumberText(warning_duration_text,30)));
            }else if(focus_field=="script_tween"){
                var tween_text=string_digits(keyboard_string);keyboard_string=tween_text;
                input_step.tween=real(tween_text==""?"0":tween_text);
            }else if(focus_field=="script_ease"){
                var ease_text=string_digits(keyboard_string);keyboard_string=ease_text;
                input_step.ease=real(ease_text==""?"0":ease_text);
            }else if(focus_field=="script_builtin_name") input_step.script_name=string_copy(keyboard_string,1,128);
            else if(focus_field=="script_builtin_args") input_step.script_arguments=string_copy(keyboard_string,1,256);
            else if(string_pos("script_action_param_",focus_field)==1){
                var action_parameter_index=real(string_delete(focus_field,1,string_length("script_action_param_")));
                input_step.action_arguments=BattleEditor_ActionArgumentsSet(input_step.action_arguments,action_parameter_index,string_copy(keyboard_string,1,256),BattleEditor_BuiltinActionDefaults(input_step.action_name));
            }
            else if(focus_field=="script_action_control_id"){input_step.action_control_id=string_copy(keyboard_string,1,64);input_step.action_control_id_auto=false;}
            else if(focus_field=="script_create_control_id"){input_step.create_control_id=string_copy(keyboard_string,1,64);input_step.create_control_id_auto=false;}
            else if(focus_field=="script_copy_control_id"){
                input_step.copy_control_id=string_copy(keyboard_string,1,64);
                if(string_length(string_trim(input_step.copy_control_id))<=0){input_step.copy_control_id=BattleEditor_NextCopiedControlId(project,input_step.target);input_step.copy_control_id_auto=true;}
                else input_step.copy_control_id_auto=false;
            }
            else if(string_pos("script_create_text_",focus_field)==1){
                BattleEditor_WorkspaceCreateNormalizeTemplate(input_step);
                BattleEditor_WorkspaceTemplateSet(input_step.create_template,string_delete(focus_field,1,string_length("script_create_text_")),string_copy(keyboard_string,1,1024));
            }else if(focus_field=="script_create_frame"){
                var input_create_template=BattleEditor_WorkspaceCreateNormalizeTemplate(input_step);
                var input_create_frames=input_create_template.animation.frames;
                if(array_length(input_create_frames)<=0){array_push(input_create_frames,string_copy(keyboard_string,1,1024));input_step.create_animation_frame_index=0;}
                else input_create_frames[clamp(round(real(input_step.create_animation_frame_index)),0,array_length(input_create_frames)-1)]=string_copy(keyboard_string,1,1024);
            }
            else if(string_pos("script_screen_param_",focus_field)==1){
                var screen_parameter_index=real(string_delete(focus_field,1,string_length("script_screen_param_")));
                input_step.screen_arguments=BattleEditor_ActionArgumentsSet(input_step.screen_arguments,screen_parameter_index,string_copy(keyboard_string,1,256),BattleEditor_ScreenActionDefaults(input_step.screen_action));
            }
            else if(focus_field=="script_variable_name") input_step.variable_name=string_copy(keyboard_string,1,64);
            else if(focus_field=="script_read_variable_name"){
                var next_read_name=string_copy(keyboard_string,1,64);
                if(next_read_name!=input_step.read_variable_name) input_step.read_overwrite_confirmed=false;
                input_step.read_variable_name=next_read_name;
            }
            else if(focus_field=="script_expression") input_step.expression=string_copy(keyboard_string,1,256);
            else if(focus_field=="script_condition_left") input_step.condition_left=string_copy(keyboard_string,1,256);
            else if(focus_field=="script_condition_right") input_step.condition_right=string_copy(keyboard_string,1,256);
            else if(focus_field=="script_skip_count") input_step.skip_count=max(0,round(BattleEditor_ReadNumberText(keyboard_string,1)));
            else if(focus_field=="script_repeat_count") input_step.repeat_count=string_copy(keyboard_string,1,256);
            else if(focus_field=="script_repeat_length") input_step.repeat_length=max(0,round(BattleEditor_ReadNumberText(keyboard_string,1)));
            else if(focus_field=="script_repeat_interval") input_step.repeat_interval=string_copy(keyboard_string,1,256);
        }
    }else if(focus_field=="clip_filter"){
        clip_editor_filter=string_copy(keyboard_string,1,64);
    }else if(selected>=0&&selected<array_length(project.events)){
        var edited_object=project.events[selected];
        if(focus_field=="object_name") edited_object.name=string_copy(keyboard_string,1,64);
        else if(focus_field=="object_control_id") edited_object.control_id=string_copy(keyboard_string,1,64);
        else if(focus_field=="object_sprite") edited_object.sprite_source=string_copy(keyboard_string,1,512);
        else if(focus_field=="object_script"&&edited_object.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION) edited_object.script_name=string_copy(keyboard_string,1,128);
        else if(focus_field=="object_heal_amount"&&struct_exists(edited_object,"damage_profile")) edited_object.damage_profile.heal_amount=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_object.damage_profile.heal_amount));
        else if(focus_field=="object_damage"&&struct_exists(edited_object,"damage_profile")) edited_object.damage_profile.damage=max(0,BattleEditor_ReadNumberText(keyboard_string,edited_object.damage_profile.damage));
        else if(focus_field=="bone_aim_speed"&&edited_object.preset=="bone") edited_object.aim_move_speed=BattleEditor_ReadNumberText(BattleEditor_FilterNumberText(keyboard_string),edited_object.aim_move_speed);
        else if(focus_field=="animation_fps"){
            var fps_text=string_digits(keyboard_string);
            keyboard_string=fps_text;
            edited_object.animation.fps=max(0,real(fps_text==""?"0":fps_text));
        }else if(focus_field=="animation_frame"&&struct_exists(edited_object,"animation")){
            var frame_files=edited_object.animation.frames;
            if(selected_animation_frame>=0&&selected_animation_frame<array_length(frame_files)) frame_files[selected_animation_frame]=string_copy(keyboard_string,1,512);
            edited_object.animation.frames=frame_files;
        }else if(edited_object.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER&&string_pos("typewriter_",focus_field)==1){
            if(focus_field=="typewriter_color") edited_object.text_color=string_copy(keyboard_string,1,32);
            else{
                var typer_number=BattleEditor_FilterNumberText(keyboard_string);
                keyboard_string=typer_number;
                if(focus_field=="typewriter_speed") edited_object.speed=max(0,BattleEditor_ReadNumberText(typer_number,edited_object.speed));
                else if(focus_field=="typewriter_depth") edited_object.text_depth=BattleEditor_ReadNumberText(typer_number,edited_object.text_depth);
            }
        }else if((edited_object.preset=="bone_3d"||edited_object.preset=="bone_4d")&&string_pos("solid_field_",focus_field)==1){
            var solid_field_index=real(string_copy(focus_field,13,string_length(focus_field)-12));
            var solid_keys=BattleEditor_SolidBoneFieldKeys(edited_object.preset);
            if(solid_field_index>=0&&solid_field_index<array_length(solid_keys)){
                var solid_key=solid_keys[solid_field_index];
                var solid_value=solid_key=="time"
                    ?submitted_timeline_frames
                    :BattleEditor_ReadNumberText(BattleEditor_FilterNumberText(keyboard_string),BattleEditor_SolidBoneFieldValue(edited_object,solid_key));
                BattleEditor_SetSolidBoneField(edited_object,solid_key,solid_value);
            }
        }else if(edited_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(edited_object.preset=="slash"||edited_object.preset=="true_knife")&&(string_pos("wave_",focus_field)==1||focus_field=="true_knife_invincibility")){
            var wave_number=BattleEditor_FilterNumberText(keyboard_string);
            keyboard_string=wave_number;
            var wave_value=BattleEditor_ReadNumberText(wave_number,0);
            var edited_wave_motion=wave_inspector_phase==0?edited_object.pre_motion:edited_object.post_motion;
            if(focus_field=="true_knife_invincibility"&&edited_object.preset=="true_knife") edited_object.invincibility_frames=max(0,round(wave_value));
            else if(focus_field=="wave_warning_time"&&edited_object.preset!="true_knife") edited_object.warning_time=max(1,wave_value);
            else if(focus_field=="wave_active_time"&&edited_object.preset!="true_knife") edited_object.active_time=max(1,wave_value);
            else if(focus_field=="wave_min_width"&&edited_object.preset!="true_knife"){
                edited_object.visual_min_width=max(1,wave_value);
                edited_object.visual_max_width=edited_object.visual_min_width*2.6;
                edited_object.warning_width=max(1,edited_object.visual_min_width*0.3);
            }
            else if(focus_field=="wave_max_width"&&edited_object.preset!="true_knife"){edited_object.visual_max_width=max(edited_object.visual_min_width,wave_value);edited_object.warning_width=max(1,edited_object.visual_min_width*0.3);}
            else if(focus_field=="wave_motion_direction") edited_wave_motion.direction=wave_value;
            else if(focus_field=="wave_motion_speed") edited_wave_motion.speed=wave_value;
            else if(focus_field=="wave_motion_acceleration") edited_wave_motion.acceleration=wave_value;
            else if(focus_field=="wave_motion_curve") edited_wave_motion.curve_speed=wave_value;
            else if(focus_field=="wave_rotation_speed") edited_wave_motion.rotation_speed=wave_value;
            else if(focus_field=="wave_rotation_target") edited_wave_motion.target_angle=wave_value;
            else if(focus_field=="wave_rotation_time") edited_wave_motion.rotation_time=max(1,wave_value);
        }else if(edited_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&edited_object.preset=="gb"&&string_pos("gb_",focus_field)==1){
            var gb_number=BattleEditor_FilterNumberText(keyboard_string);
            keyboard_string=gb_number;
            if(focus_field=="gb_spawn_x") edited_object.spawn_x=BattleEditor_ReadNumberText(gb_number,edited_object.spawn_x);
            else if(focus_field=="gb_spawn_y") edited_object.spawn_y=BattleEditor_ReadNumberText(gb_number,edited_object.spawn_y);
            else if(focus_field=="gb_spawn_angle") edited_object.angle_start=BattleEditor_ReadNumberText(gb_number,edited_object.angle_start);
            else if(focus_field=="gb_spawn_distance") edited_object.spawn_distance=max(1,BattleEditor_ReadNumberText(gb_number,edited_object.spawn_distance));
            else if(focus_field=="gb_target_angle") edited_object.angle_target=BattleEditor_ReadNumberText(gb_number,edited_object.angle_target);
            else if(focus_field=="gb_target_x") edited_object.target_x=BattleEditor_ReadNumberText(gb_number,edited_object.target_x);
            else if(focus_field=="gb_target_y") edited_object.target_y=BattleEditor_ReadNumberText(gb_number,edited_object.target_y);
            else if(focus_field=="gb_scale"){
                edited_object.transform.scale_x=max(0.05,BattleEditor_ReadNumberText(gb_number,edited_object.transform.scale_x));
                edited_object.transform.scale_y=edited_object.transform.scale_x;
            }
            else if(focus_field=="gb_move_time") edited_object.move_time=max(0,BattleEditor_ReadNumberText(gb_number,edited_object.move_time));
            else if(focus_field=="gb_charge_time") edited_object.charge_time=max(0,BattleEditor_ReadNumberText(gb_number,edited_object.charge_time));
            else if(focus_field=="gb_beam_time") edited_object.beam_time=max(1,BattleEditor_ReadNumberText(gb_number,edited_object.beam_time));
            else if(focus_field=="gb_offset_direction") edited_object.offset_direction=BattleEditor_ReadNumberText(gb_number,edited_object.offset_direction);
            else if(focus_field=="gb_offset_speed") edited_object.offset_speed=BattleEditor_ReadNumberText(gb_number,edited_object.offset_speed);
            else if(focus_field=="gb_offset_acceleration") edited_object.offset_acceleration=BattleEditor_ReadNumberText(gb_number,edited_object.offset_acceleration);
            else if(focus_field=="gb_offset_rotation") edited_object.offset_rotation_speed=BattleEditor_ReadNumberText(gb_number,edited_object.offset_rotation_speed);
        }else if(string_pos("track_",focus_field)==1||string_pos("bone_",focus_field)==1||string_pos("platform_",focus_field)==1||focus_field=="object_duration"||focus_field=="object_time"){
            var object_number=focus_field=="object_time"?keyboard_string:BattleEditor_FilterNumberText(keyboard_string);
            keyboard_string=object_number;
            var object_value=focus_field=="object_time"?submitted_timeline_frames:BattleEditor_ReadNumberText(object_number,0);
            if(focus_field=="track_x") edited_object.transform.x=object_value;
            else if(focus_field=="track_y") edited_object.transform.y=object_value;
            else if(focus_field=="track_angle") edited_object.transform.angle=object_value;
            else if(focus_field=="track_scale_x") edited_object.transform.scale_x=max(0.01,object_value);
            else if(focus_field=="track_scale_y") edited_object.transform.scale_y=max(0.01,object_value);
            else if(focus_field=="track_alpha") edited_object.transform.alpha=clamp(object_value,0,1);
            else if(focus_field=="bone_length") edited_object.length=max(1,object_value);
            else if(focus_field=="bone_hspeed") edited_object.hspeed=object_value;
            else if(focus_field=="bone_vspeed") edited_object.vspeed=object_value;
            else if(focus_field=="bone_rotate") edited_object.rotate=object_value;
            else if(focus_field=="bone_point") edited_object.point=object_value;
            else if(focus_field=="bone_point_at") edited_object.point_at=object_value;
            else if(focus_field=="platform_width") edited_object.width=max(4,object_value);
            else if(focus_field=="platform_hspeed") edited_object.hspeed=object_value;
            else if(focus_field=="platform_vspeed") edited_object.vspeed=object_value;
            else if(focus_field=="object_duration") edited_object.duration=object_value<0?-1:max(1,object_value);
            else if(focus_field=="object_time"){
                edited_object.time=max(0,object_value);
                cursor_time=edited_object.time;
                // Enter means "take me to this object's authored birth frame".
                // Clicking away still commits the value without unexpectedly
                // changing editor mode.
                if(submit_by_enter){
                    object_time_seek_pending=true;
                    object_time_seek_target=edited_object.time;
                    object_time_seek_name=edited_object.name;
                }
            }
        }
    }else if(selected_frame>=-1&&(focus_field=="frame_name"||focus_field=="frame_control_id")){
        var identity_frame=selected_frame==-1?init.board:init.frames[selected_frame];
        if(focus_field=="frame_name") identity_frame.name=string_copy(keyboard_string,1,64);
        else identity_frame.control_id=string_copy(keyboard_string,1,64);
    }else if(selected_frame>=-1&&string_pos("frame_color_",focus_field)==1){
        var color_frame=selected_frame==-1?init.board:init.frames[selected_frame];
        var frame_color_text=string_digits(keyboard_string);
        keyboard_string=frame_color_text;
        var frame_color_value=clamp(real(frame_color_text==""?"0":frame_color_text),0,255);
        var frame_red=color_get_red(color_frame.color_frame);
        var frame_green=color_get_green(color_frame.color_frame);
        var frame_blue=color_get_blue(color_frame.color_frame);
        if(focus_field=="frame_color_r") frame_red=frame_color_value;
        else if(focus_field=="frame_color_g") frame_green=frame_color_value;
        else frame_blue=frame_color_value;
        color_frame.color_frame=make_color_rgb(frame_red,frame_green,frame_blue);
        BattleEditor_SyncBoardPreview(id,false);
    }else if(selected_frame>=-1&&string_pos("frame_",focus_field)==1){
        var edit_frame=selected_frame==-1?init.board:init.frames[selected_frame];
        var frame_number=BattleEditor_FilterNumberText(keyboard_string);
        keyboard_string=frame_number;
        var frame_value=BattleEditor_ReadNumberText(frame_number,0);
        if(focus_field=="frame_x") edit_frame.x=frame_value;
        else if(focus_field=="frame_y") edit_frame.y=frame_value;
        else if(focus_field=="frame_up") edit_frame.up=max(1,frame_value);
        else if(focus_field=="frame_down") edit_frame.down=max(1,frame_value);
        else if(focus_field=="frame_left") edit_frame.left=max(1,frame_value);
        else if(focus_field=="frame_right") edit_frame.right=max(1,frame_value);
        else if(focus_field=="frame_angle") edit_frame.angle=frame_value;
        else if(focus_field=="frame_rotate") edit_frame.rotate=frame_value;
        else if(focus_field=="frame_depth") edit_frame.board_depth=frame_value;
        else if(focus_field=="frame_radius_x") edit_frame.radius_x=max(1,frame_value);
        else if(focus_field=="frame_radius_y") edit_frame.radius_y=max(1,frame_value);
        else if(focus_field=="frame_triangle_size") edit_frame.triangle_size=max(1,frame_value);
    }
    var finish_input=keyboard_check_pressed(vk_enter);
    if(finish_input||click){
        var submitted_group_field=focus_field;
        if(group_selection_active&&selected>=0&&selected<array_length(project.events)){
            BattleEditor_SyncEventGroupField(project,selected,submitted_group_field,wave_inspector_phase,group_selection_type,group_selection_control_id);
            if(submitted_group_field=="object_control_id") group_selection_control_id=string(project.events[selected].control_id);
        }
        if(submitted_group_field=="object_control_id"&&selected>=0&&selected<array_length(project.events)){
            var control_finish_object=project.events[selected];
            var control_finish_type=BattleEditor_DataTargetType(control_finish_object);
            if(!struct_exists(control_finish_object,"control_uid")) control_finish_object.control_uid=BattleEditor_AllocateUid(project);
            // Editing one member of a selected multi-member group means split;
            // editing the group selection means rename the complete identity.
            if(!group_selection_active&&string(focus_expression_base)!=string(control_finish_object.control_id)&&BattleEditor_ControlGroupMemberCount(project,control_finish_object.control_uid,control_finish_type)>1) control_finish_object.control_uid=BattleEditor_AllocateUid(project);
            control_finish_object.control_uid=BattleEditor_ReconcileControlGroupLabel(project,control_finish_object.control_uid,control_finish_type,string(control_finish_object.control_id));
            if(group_selection_active) group_selection_control_id=string(control_finish_object.control_id);
        }
        if(focus_field=="object_name"&&selected>=0){
            var finish_object=project.events[selected];
            var requested_object_name=finish_object.name;
            finish_object.name=BattleEditor_MakeUniqueName(project,finish_object.name,finish_object.uid);
            if(finish_object.name!=requested_object_name) status_text="名称已存在，已改为 "+finish_object.name;
        }else if(focus_field=="frame_name"&&selected_frame>=-1){
            var finish_frame=selected_frame==-1?init.board:init.frames[selected_frame];
            var requested_frame_name=finish_frame.name;
            finish_frame.name=BattleEditor_MakeUniqueName(project,finish_frame.name,finish_frame.uid);
            if(finish_frame.name!=requested_frame_name) status_text="名称已存在，已改为 "+finish_frame.name;
        }else if(focus_field=="enemy_name"&&selected_enemy>=0&&selected_enemy<array_length(init.enemies)){
            var finish_enemy=init.enemies[selected_enemy];
            var previous_enemy_name=focus_expression_base;
            var requested_enemy_name=finish_enemy.name;
            finish_enemy.name=BattleEditor_MakeUniqueName(project,finish_enemy.name,finish_enemy.uid);
            if(finish_enemy.name!=requested_enemy_name) status_text="名称已存在，已改为 "+finish_enemy.name;
            BattleEditor_RenameEnemyResourceDirectory(project,finish_enemy.uid,previous_enemy_name,finish_enemy.name);
            enemy_editor_cache_dirty=true;
            BattleEditor_ApplyInitialization(project);
        }
        input_capture_frames=3;
        focus_last_field="";
        focus_expression_base="";
        focus_field="";
        focus_edit_buffer="";
        focus_keyboard_seen="";
        keyboard_string="";
        if(os_type==os_windows) keyboard_virtual_hide();
        // The model has received the field value. Do not parse here: many
        // commits may form one authoring batch. Run/seek refreshes once on
        // demand, immediately before the duration is actually needed.
        timeline_duration_dirty=true;
        if(object_time_seek_pending){
            // The event time was just edited, so the frozen state belongs to
            // the old schedule and cannot be continued incrementally.
            if(BattleEditor_RuntimeBeginSeek(id,object_time_seek_target,false,true)){
                board_edit_session=true;
                status_text="已将 "+object_time_seek_name+" 移到 "+BattleEditor_FormatTimelineTime(object_time_seek_target)+" 并定格该时刻";
            }
        }
    }
    if(finish_input||!click) exit;
}

if(enemy_editor_open){
    BattleEditor_SetInputCapture(focus_field!="");
    var visual_enemies=project.initialization.enemies;
    if(array_length(visual_enemies)<=0){
        if(click&&BattleEditor_PointInRect(mx,my,548,6,634,30)) enemy_editor_open=false;
        exit;
    }
    selected_enemy=clamp(selected_enemy,0,array_length(visual_enemies)-1);
    var visual_enemy=visual_enemies[selected_enemy];
    var visual_keys=BattleEditor_EnemyPartKeys();
    enemy_editor_selected_part=clamp(enemy_editor_selected_part,0,array_length(visual_keys)-1);
    var visual_key=visual_keys[enemy_editor_selected_part];
    var visual_part=variable_struct_get(visual_enemy.parts,visual_key);
    if(enemy_editor_cache_dirty){
        if(!variable_global_exists("battle_editor_enemy_visual_revision")) global.battle_editor_enemy_visual_revision=0;
        global.battle_editor_enemy_visual_revision+=1;
        BattleEditor_FreeEnemyVisualCache(enemy_editor_cache);
        enemy_editor_cache=BattleEditor_LoadEnemyVisualCache(project,visual_enemy);
        enemy_editor_cache_dirty=false;
    }
    if(enemy_editor_preview_playing) enemy_editor_preview_time+=global.delta_time_factor;
    var enemy_canvas_hover=BattleEditor_PointInRect(mx,my,6,36,408,470);
    if(enemy_canvas_hover&&keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var enemy_old_zoom=enemy_editor_zoom;
        var enemy_world_under_mouse_x=(mx-enemy_editor_pan_x)/enemy_old_zoom;
        var enemy_world_under_mouse_y=(my-enemy_editor_pan_y)/enemy_old_zoom;
        enemy_editor_zoom=clamp(enemy_editor_zoom*(mouse_wheel_up()?1.12:1/1.12),0.1,8);
        enemy_editor_pan_x=mx-enemy_world_under_mouse_x*enemy_editor_zoom;
        enemy_editor_pan_y=my-enemy_world_under_mouse_y*enemy_editor_zoom;
    }
    if(enemy_canvas_hover&&mouse_check_button_pressed(mb_middle)){
        enemy_editor_panning=true;enemy_editor_pan_button=1;
        enemy_editor_pan_grab_x=mx-enemy_editor_pan_x;enemy_editor_pan_grab_y=my-enemy_editor_pan_y;
    }
    if(enemy_editor_panning){
        var enemy_pan_held=enemy_editor_pan_button==1?mouse_check_button(mb_middle):mouse_check_button(mb_left);
        if(enemy_pan_held){enemy_editor_pan_x=mx-enemy_editor_pan_grab_x;enemy_editor_pan_y=my-enemy_editor_pan_grab_y;}
        else enemy_editor_panning=false;
    }
    if(enemy_editor_dragging){
        if(mouse_check_button(mb_left)){
            // Edit the neutral local offset by mouse delta.  The animated
            // preview pose may move underneath the pointer, but it must never
            // be written back into the authored part position.
            visual_part.offset_x=enemy_editor_drag_start_part_x+(mx-enemy_editor_drag_start_mouse_x)/enemy_editor_zoom;
            visual_part.offset_y=enemy_editor_drag_start_part_y+(my-enemy_editor_drag_start_mouse_y)/enemy_editor_zoom;
            runtime_snapshot_pending=true;runtime_snapshot_idle_frames=0;
        }else enemy_editor_dragging=false;
    }
    var visual_options=BattleEditor_EnemyTextureOptions(project,visual_enemy.uid,visual_key);
    if(enemy_editor_resource_menu_open&&(mouse_wheel_up()||mouse_wheel_down())){
        enemy_editor_resource_scroll=clamp(enemy_editor_resource_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(visual_options)-9));
    }
    if(click){
        if(BattleEditor_PointInRect(mx,my,548,6,634,30)){
            enemy_editor_open=false;enemy_editor_part_menu_open=false;enemy_editor_resource_menu_open=false;
            BattleEditor_FreeEnemyVisualCache(enemy_editor_cache);enemy_editor_cache={sprites:{},parts:{},owned:[]};enemy_editor_cache_dirty=true;
            status_text="敌人可视化编辑已保存到当前项目";exit;
        }
        if(BattleEditor_PointInRect(mx,my,322,6,406,30)){enemy_editor_preview_playing=!enemy_editor_preview_playing;if(enemy_editor_preview_playing) enemy_editor_preview_time=0;exit;}
        if(enemy_editor_part_menu_open){
            if(BattleEditor_PointInRect(mx,my,424,90,626,90+array_length(visual_keys)*24)){
                enemy_editor_selected_part=clamp(floor((my-90)/24),0,array_length(visual_keys)-1);
                selected_enemy_part=enemy_editor_selected_part;enemy_editor_part_menu_open=false;enemy_editor_resource_menu_open=false;enemy_editor_frame_index=0;exit;
            }
            enemy_editor_part_menu_open=false;deferred_click=true;deferred_click_x=mx;deferred_click_y=my;exit;
        }
        if(enemy_editor_resource_menu_open){
            var visible_resource_count=min(9,max(0,array_length(visual_options)-enemy_editor_resource_scroll));
            if(BattleEditor_PointInRect(mx,my,424,142,626,142+visible_resource_count*24)){
                var picked_resource=visual_options[enemy_editor_resource_scroll+floor((my-142)/24)];
                visual_part.asset_uid=picked_resource.uid;visual_part.source=picked_resource.path;visual_part.animation=picked_resource.animation;
                enemy_editor_selected_resource=picked_resource.uid;enemy_editor_resource_menu_open=false;enemy_editor_frame_index=0;enemy_editor_cache_dirty=true;exit;
            }
            enemy_editor_resource_menu_open=false;deferred_click=true;deferred_click_x=mx;deferred_click_y=my;exit;
        }
        if(BattleEditor_PointInRect(mx,my,424,64,626,88)){enemy_editor_part_menu_open=true;enemy_editor_resource_menu_open=false;exit;}
        if(BattleEditor_PointInRect(mx,my,424,116,626,140)){enemy_editor_resource_menu_open=true;enemy_editor_part_menu_open=false;enemy_editor_resource_scroll=0;exit;}
        if(BattleEditor_PointInRect(mx,my,424,146,522,170)){
            var static_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择敌人部件贴图");
            if(static_path!=""){
                var static_resource=BattleEditor_StageEnemyResource(project,visual_enemy.uid,static_path,visual_key,filename_name(static_path));
                if(!is_undefined(static_resource)){visual_part.asset_uid=static_resource.uid;visual_part.source=static_resource.path;visual_part.animation=static_resource.animation;enemy_editor_cache_dirty=true;status_text="已导入到 "+visual_enemy.name+" 的资源目录";}
            }
            exit;
        }
        if(BattleEditor_PointInRect(mx,my,528,146,626,170)){
            var animation_number=array_length(BattleEditor_EnemyTextureOptions(project,visual_enemy.uid))+1;
            var new_animation=BattleEditor_NewEnemyTextureResource(project,visual_enemy.uid,"动画 "+string(animation_number),"",visual_key,BattleEditor_NewAnimation());
            visual_part.asset_uid=new_animation.uid;visual_part.source="";visual_part.animation=new_animation.animation;enemy_editor_frame_index=0;enemy_editor_cache_dirty=true;status_text="已新建动画；请逐帧导入";exit;
        }
        var visual_resource=BattleEditor_FindEnemyTextureResource(project,visual_part.asset_uid);
        if(!is_undefined(visual_resource)){
            if(BattleEditor_PointInRect(mx,my,424,198,626,222)){focus_field="enemy_resource_name";keyboard_string=visual_resource.name;exit;}
            if(BattleEditor_PointInRect(mx,my,520,228,626,252)){
                var frame_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择下一帧");
                if(frame_path!=""&&BattleEditor_StageEnemyAnimationFrame(project,visual_resource.uid,frame_path)!=""){
                    visual_part.source=visual_resource.path;visual_part.animation=visual_resource.animation;enemy_editor_frame_index=array_length(visual_resource.animation.frames)-1;enemy_editor_cache_dirty=true;status_text="已加入第 "+string(enemy_editor_frame_index+1)+" 帧";
                }
                exit;
            }
            var frame_count=array_length(visual_resource.animation.frames);
            if(frame_count>0&&BattleEditor_PointInRect(mx,my,424,258,462,282)){enemy_editor_frame_index=(enemy_editor_frame_index-1+frame_count) mod frame_count;enemy_editor_preview_time=enemy_editor_frame_index*GAME_FPS/max(0.001,visual_resource.animation.fps);exit;}
            if(frame_count>0&&BattleEditor_PointInRect(mx,my,466,258,504,282)){enemy_editor_frame_index=(enemy_editor_frame_index+1) mod frame_count;enemy_editor_preview_time=enemy_editor_frame_index*GAME_FPS/max(0.001,visual_resource.animation.fps);exit;}
            if(frame_count>0&&BattleEditor_PointInRect(mx,my,510,258,626,282)){array_delete(visual_resource.animation.frames,clamp(enemy_editor_frame_index,0,frame_count-1),1);enemy_editor_frame_index=clamp(enemy_editor_frame_index,0,max(0,array_length(visual_resource.animation.frames)-1));enemy_editor_cache_dirty=true;exit;}
            if(BattleEditor_PointInRect(mx,my,478,310,548,334)){focus_field="enemy_animation_fps";keyboard_string=string(visual_resource.animation.fps);exit;}
            if(BattleEditor_PointInRect(mx,my,554,310,626,334)){visual_resource.animation.loop=!visual_resource.animation.loop;visual_part.animation=visual_resource.animation;enemy_editor_cache_dirty=true;exit;}
        }
        if(BattleEditor_PointInRect(mx,my,424,360,522,382)){focus_field="enemy_part_x";keyboard_string=string(visual_part.offset_x);exit;}
        if(BattleEditor_PointInRect(mx,my,528,360,626,382)){focus_field="enemy_part_y";keyboard_string=string(visual_part.offset_y);exit;}
        if(BattleEditor_PointInRect(mx,my,424,406,522,428)){focus_field="enemy_origin_x";keyboard_string=string(visual_part.origin_x);exit;}
        if(BattleEditor_PointInRect(mx,my,528,406,626,428)){focus_field="enemy_origin_y";keyboard_string=string(visual_part.origin_y);exit;}
        if(BattleEditor_PointInRect(mx,my,424,452,522,474)){focus_field="enemy_scale_x";keyboard_string=string(visual_enemy.scale_x);exit;}
        if(BattleEditor_PointInRect(mx,my,528,452,626,474)){focus_field="enemy_scale_y";keyboard_string=string(visual_enemy.scale_y);exit;}
        if(BattleEditor_PointInRect(mx,my,6,36,408,470)){
            var enemy_part_hit=false;
            for(var hit_index=array_length(visual_keys)-1;hit_index>=0;hit_index--){
                var hit_key=visual_keys[hit_index];var hit_sprite=variable_struct_get(enemy_editor_cache.sprites,hit_key);
                if(!sprite_exists(hit_sprite)) continue;
                var hit_pose=BattleEditor_EnemyPartPose(visual_enemy,hit_key,enemy_editor_pan_x,enemy_editor_pan_y,enemy_editor_preview_time,enemy_editor_zoom);
                if(BattleEditor_SpriteHit(hit_sprite,hit_pose[0],hit_pose[1],visual_enemy.scale_x*enemy_editor_zoom,visual_enemy.scale_y*enemy_editor_zoom,0,mx,my,12,3)){
                    enemy_editor_selected_part=hit_index;selected_enemy_part=hit_index;visual_key=hit_key;visual_part=variable_struct_get(visual_enemy.parts,hit_key);
                    enemy_editor_dragging=true;
                    enemy_editor_drag_start_mouse_x=mx;enemy_editor_drag_start_mouse_y=my;
                    enemy_editor_drag_start_part_x=visual_part.offset_x;enemy_editor_drag_start_part_y=visual_part.offset_y;
                    enemy_part_hit=true;break;
                }
            }
            if(!enemy_part_hit){
                enemy_editor_panning=true;enemy_editor_pan_button=0;
                enemy_editor_pan_grab_x=mx-enemy_editor_pan_x;enemy_editor_pan_grab_y=my-enemy_editor_pan_y;
            }
            exit;
        }
    }
    exit;
}

if(clip_editor_open){
    BattleEditor_SetInputCapture(true);
    if(clip_editor_event<0||clip_editor_event>=array_length(project.events)){
        clip_editor_open=false;
        exit;
    }
    var clip_object=project.events[clip_editor_event];
    var clip_options=BattleEditor_FilterClipFrames(project,clip_editor_filter);
    var clip_visible=min(9,max(0,array_length(clip_options)-clip_editor_scroll));
    if(mouse_wheel_up()) clip_editor_scroll=max(0,clip_editor_scroll-1);
    if(mouse_wheel_down()) clip_editor_scroll=min(max(0,array_length(clip_options)-9),clip_editor_scroll+1);
    if(click&&BattleEditor_PointInRect(mx,my,502,72,526,94)){
        clip_editor_open=false;
        if(focus_field=="clip_filter"){focus_field="";keyboard_string="";}
        exit;
    }
    if(click&&BattleEditor_PointInRect(mx,my,120,82,270,104)) clip_object.clip_mode="all";
    else if(click&&BattleEditor_PointInRect(mx,my,276,82,432,104)) clip_object.clip_mode="selected";
    else if(click&&BattleEditor_PointInRect(mx,my,120,112,432,136)){focus_field="clip_filter";keyboard_string=clip_editor_filter;exit;}
    else if(click&&BattleEditor_PointInRect(mx,my,120,142,214,164)){
        clip_object.clip_frame_uids=[];
        var every_clip_frame=BattleEditor_FollowFrameOptions(project);
        for(var all_clip_index=0;all_clip_index<array_length(every_clip_frame);all_clip_index++) array_push(clip_object.clip_frame_uids,every_clip_frame[all_clip_index].uid);
        clip_object.clip_mode="selected";
    }else if(click&&BattleEditor_PointInRect(mx,my,220,142,314,164)){
        clip_object.clip_frame_uids=[];
        clip_object.clip_mode="selected";
    }else if(click&&BattleEditor_PointInRect(mx,my,320,142,526,164)) clip_object.clipped_collision=!clip_object.clipped_collision;
    else if(click&&BattleEditor_PointInRect(mx,my,120,172,526,172+clip_visible*24)){
        var clip_row=clip_editor_scroll+floor((my-172)/24);
        if(clip_row>=0&&clip_row<array_length(clip_options)){
            var clicked_clip_frame=clip_options[clip_row];
            var group_click=mx>=452;
            if(group_click){
                var all_frames=BattleEditor_FollowFrameOptions(project);
                var group_all_selected=true;
                for(var group_scan=0;group_scan<array_length(all_frames);group_scan++) if(all_frames[group_scan].control_id==clicked_clip_frame.control_id&&!BattleEditor_UidArrayContains(clip_object.clip_frame_uids,all_frames[group_scan].uid)){group_all_selected=false;break;}
                for(var group_apply=0;group_apply<array_length(all_frames);group_apply++) if(all_frames[group_apply].control_id==clicked_clip_frame.control_id){
                    var group_uid=all_frames[group_apply].uid;
                    var group_uid_index=-1;
                    for(var group_find=0;group_find<array_length(clip_object.clip_frame_uids);group_find++) if(clip_object.clip_frame_uids[group_find]==group_uid){group_uid_index=group_find;break;}
                    if(group_all_selected&&group_uid_index>=0) array_delete(clip_object.clip_frame_uids,group_uid_index,1);
                    else if(!group_all_selected&&group_uid_index<0) array_push(clip_object.clip_frame_uids,group_uid);
                }
            }else{
                var clip_uid_index=-1;
                for(var clip_find=0;clip_find<array_length(clip_object.clip_frame_uids);clip_find++) if(clip_object.clip_frame_uids[clip_find]==clicked_clip_frame.uid){clip_uid_index=clip_find;break;}
                if(clip_uid_index>=0) array_delete(clip_object.clip_frame_uids,clip_uid_index,1);
                else array_push(clip_object.clip_frame_uids,clicked_clip_frame.uid);
            }
            clip_object.clip_mode="selected";
        }
    }
    exit;
}

// Layout is a modal initialization panel. It prevents clicks from leaking
// through to the battle scene while still using the normal Chinese text input
// path and blinking editor fields.
if(tab==1&&hud_settings_open){
    var hud_init=project.initialization;
    if(click&&BattleEditor_PointInRect(mx,my,474,76,506,98)) hud_settings_open=false;
    else if(click&&BattleEditor_PointInRect(mx,my,138,112,310,136)) hud_init.hud_show_hp_label=!hud_init.hud_show_hp_label;
    else if(click&&BattleEditor_PointInRect(mx,my,330,112,502,136)) hud_init.hud_show_bar=!hud_init.hud_show_bar;
    else if(click&&BattleEditor_PointInRect(mx,my,138,148,310,172)) hud_init.hud_show_kr=!hud_init.hud_show_kr;
    else if(click&&BattleEditor_PointInRect(mx,my,330,148,502,172)) hud_init.hud_show_numbers=!hud_init.hud_show_numbers;
    else if(click&&BattleEditor_PointInRect(mx,my,138,184,502,208)) hud_init.hud_show_overhead=!hud_init.hud_show_overhead;
    else if(click&&BattleEditor_PointInRect(mx,my,138,220,310,244)) hud_init.shield_enabled=!hud_init.shield_enabled;
    else if(click&&BattleEditor_PointInRect(mx,my,330,220,502,244)){choice_menu_open=true;choice_menu_context="shield_mode";choice_menu_kind="shield_mode";choice_menu_scroll=0;}
    else if(click&&BattleEditor_PointInRect(mx,my,138,260,502,284)){
        hud_init.board.shape="rect";hud_init.board.x=320;hud_init.board.y=240;hud_init.board.left=320;hud_init.board.right=320;hud_init.board.up=240;hud_init.board.down=240;
        BattleEditor_SyncBoardPreview(id,true);status_text="主框已设为 640 x 480 全屏";
    }
    BattleEditor_ApplyInitialization(project);
    exit;
}

if(tab==1&&init_player_open){
    var player_init=project.initialization;
    if(click&&BattleEditor_PointInRect(mx,my,492,82,524,104)) init_player_open=false;
    else if(click&&BattleEditor_PointInRect(mx,my,210,124,304,148)){focus_field="player_lv";keyboard_string=string(player_init.lv);}
    else if(click&&BattleEditor_PointInRect(mx,my,326,124,420,148)){focus_field="player_atk";keyboard_string=string(player_init.atk);}
    else if(click&&BattleEditor_PointInRect(mx,my,430,124,524,148)){focus_field="player_def";keyboard_string=string(player_init.def);}
    else if(click&&BattleEditor_PointInRect(mx,my,210,176,350,200)){focus_field="player_hp";keyboard_string=string(player_init.hp);}
    else if(click&&BattleEditor_PointInRect(mx,my,370,176,524,200)){focus_field="player_max_hp";keyboard_string=string(player_init.max_hp);}
    else if(click&&BattleEditor_PointInRect(mx,my,210,228,350,252)){focus_field="player_shield";keyboard_string=string(player_init.shield);}
    else if(click&&BattleEditor_PointInRect(mx,my,370,228,524,252)){focus_field="player_shield_max";keyboard_string=string(player_init.shield_max);}
    else if(click&&BattleEditor_PointInRect(mx,my,300,280,524,304)){focus_field="player_shield_natural_max";keyboard_string=string(player_init.shield_natural_max);}
    exit;
}

if(tab==1&&init_layout_open){
    if(click&&BattleEditor_PointInRect(mx,my,478,100,510,122)) init_layout_open=false;
    else if(click&&BattleEditor_PointInRect(mx,my,230,154,350,178)){focus_field="layout_enemy_x";keyboard_string=string(project.initialization.enemy_x);}
    else if(click&&BattleEditor_PointInRect(mx,my,360,154,480,178)){focus_field="layout_enemy_y";keyboard_string=string(project.initialization.enemy_y);}
    else if(click&&BattleEditor_PointInRect(mx,my,230,224,350,248)){focus_field="layout_hud_x";keyboard_string=string(project.initialization.hud_x);}
    else if(click&&BattleEditor_PointInRect(mx,my,360,224,480,248)){focus_field="layout_hud_y";keyboard_string=string(project.initialization.hud_y);}
    else if(click&&BattleEditor_PointInRect(mx,my,230,282,350,306)){focus_field="layout_turn_text_x";keyboard_string=string(project.initialization.turn_text_x);}
    else if(click&&BattleEditor_PointInRect(mx,my,360,282,480,306)){focus_field="layout_turn_text_y";keyboard_string=string(project.initialization.turn_text_y);}
    else if(click&&BattleEditor_PointInRect(mx,my,230,328,300,352)){focus_field="global_board_color_r";keyboard_string=string(color_get_red(project.initialization.board_color_default));}
    else if(click&&BattleEditor_PointInRect(mx,my,306,328,376,352)){focus_field="global_board_color_g";keyboard_string=string(color_get_green(project.initialization.board_color_default));}
    else if(click&&BattleEditor_PointInRect(mx,my,382,328,452,352)){focus_field="global_board_color_b";keyboard_string=string(color_get_blue(project.initialization.board_color_default));}
    else if(click&&BattleEditor_PointInRect(mx,my,458,328,514,352)){
        project.initialization.board.color_frame=project.initialization.board_color_default;
        for(var apply_color_index=0;apply_color_index<array_length(project.initialization.frames);apply_color_index++) project.initialization.frames[apply_color_index].color_frame=project.initialization.board_color_default;
        BattleEditor_SyncBoardPreview(id,false);
        status_text="已将全局框颜色应用到全部框";
    }
    exit;
}

// Right mouse is reserved for contextual editing. Existing board vertices drag
// directly; every other right-click opens the appropriate context menu.
if(right_vertex_drag){
    if(mouse_check_button(mb_right)&&context_frame>=-1){
        var vertex_frame=context_frame==-1?main_board_preview:project.initialization.frames[context_frame];
        BattleEditor_FrameSetVertexWorld(vertex_frame,drag_vertex_index,mx,my);
        // Auxiliary handles update only their matching live board. The first
        // rect-to-polygon conversion (and main-board edits) deliberately use
        // the full path once; all following pointer frames stay incremental.
        if(context_frame<0||!BattleEditor_SyncSingleAuxiliaryBoardPreview(id,context_frame)) BattleEditor_SyncBoardPreview(id,false);
    }else{
        right_vertex_drag=false;
        drag_vertex_index=-1;
    }
}

if(keyboard_check_pressed(vk_escape)&&BattleEditor_WorkspaceEscape(id)) exit;

if(script_variables_open){
    var global_variable_count=array_length(project.variables);
    if(mouse_wheel_up()) script_variable_scroll=max(0,script_variable_scroll-1);
    if(mouse_wheel_down()) script_variable_scroll=min(max(0,global_variable_count-9),script_variable_scroll+1);
    if(click&&BattleEditor_PointInRect(mx,my,480,4,528,28)){script_variables_open=false;exit;}
    if(click&&BattleEditor_PointInRect(mx,my,444,390,532,414)){script_variables_open=false;exit;}
    if(click&&BattleEditor_PointInRect(mx,my,420,72,474,96)){
        var variable_number=array_length(project.variables)+1;
        var variable_name="变量_"+string(variable_number);
        var variable_name_used=true;
        while(variable_name_used){
            variable_name_used=false;
            for(var variable_name_index=0;variable_name_index<array_length(project.variables);variable_name_index++) if(project.variables[variable_name_index].name==variable_name){variable_name_used=true;variable_number+=1;variable_name="变量_"+string(variable_number);break;}
        }
        array_push(project.variables,{name:variable_name,value:0});script_selected_variable=array_length(project.variables)-1;script_variable_scroll=max(0,array_length(project.variables)-9);status_text="已新增数字变量";
    }else if(click&&BattleEditor_PointInRect(mx,my,478,72,532,96)&&script_selected_variable>=0){
        array_delete(project.variables,script_selected_variable,1);script_selected_variable=min(script_selected_variable,array_length(project.variables)-1);script_variable_scroll=min(script_variable_scroll,max(0,array_length(project.variables)-9));status_text="已删除数字变量";
    }else if(click){
        for(var global_variable_row=0;global_variable_row<9;global_variable_row++){
            var global_variable_index=script_variable_scroll+global_variable_row;
            if(global_variable_index<array_length(project.variables)&&BattleEditor_PointInRect(mx,my,98,154+global_variable_row*28,350,178+global_variable_row*28)){script_selected_variable=global_variable_index;break;}
        }
        if(script_selected_variable>=0&&script_selected_variable<array_length(project.variables)){
            var picked_global_variable=project.variables[script_selected_variable];
            if(BattleEditor_PointInRect(mx,my,366,172,532,196)){focus_field="global_variable_name";keyboard_string=picked_global_variable.name;}
            else if(BattleEditor_PointInRect(mx,my,366,226,532,250)){focus_field="global_variable_value";keyboard_string=string(picked_global_variable.value);}
        }
    }
    exit;
}

if(right_click&&tab==0&&mx<(object_palette||hazard_palette||board_palette?390:468)&&my>58){
    context_open=false;context_submenu=false;context_event=-1;context_frame=-2;
    context_anchor_x=mx;context_anchor_y=my;
    // Visible vertices win first, with extra frames above the main frame.
    for(var vertex_frame_index=array_length(project.initialization.frames)-1;vertex_frame_index>=-1;vertex_frame_index--){
        var vertex_candidate=vertex_frame_index==-1?main_board_preview:project.initialization.frames[vertex_frame_index];
        var hit_vertex=BattleEditor_FrameVertexHit(vertex_candidate,mx,my,10);
        if(hit_vertex>=0){
            selected=-1;selected_frame=vertex_frame_index;context_frame=vertex_frame_index;
            drag_vertex_index=hit_vertex;right_vertex_drag=true;board_edit_session=true;
            if(vertex_frame_index==-1&&!timeline_half_play) BattleEditor_RuntimeBeginSeek(id,0);
            BattleEditor_FrameEnsurePolygon(vertex_candidate);
            break;
        }
    }
    if(!right_vertex_drag){
        for(var context_event_index=array_length(project.events)-1;context_event_index>=0;context_event_index--){
            if(!BattleEditor_EventBelongsToTurn(project.events[context_event_index],developer_turn)) continue;
            if(!scene_objects_visible&&context_event_index!=selected&&!BattleEditor_UidArrayContains(new_object_preview_uids,project.events[context_event_index].uid)) continue;
            if(BattleEditor_EventHit(project.events[context_event_index],mx,my,project,main_board_preview,id)){context_event=context_event_index;break;}
        }
        if(context_event>=0){selected=context_event;selected_frame=-2;object_palette=false;hazard_palette=false;board_palette=false;}
        else{
            for(var context_frame_index=array_length(project.initialization.frames)-1;context_frame_index>=0;context_frame_index--){
                if(BattleEditor_FrameHit(project.initialization.frames[context_frame_index],mx,my)){context_frame=context_frame_index;break;}
            }
            if(context_frame==-2&&BattleEditor_FrameHit(main_board_preview,mx,my)) context_frame=-1;
            if(context_frame>=-1){
                selected=-1;selected_frame=context_frame;board_edit_session=true;object_palette=false;hazard_palette=false;board_palette=false;
                if(context_frame==-1&&!timeline_half_play) BattleEditor_RuntimeBeginSeek(id,0);
            }
        }
        context_x=clamp(mx,4,342);context_y=clamp(my,58,244);context_open=true;
    }
}

if(context_open&&click){
    var menu_row=floor((my-context_y)/22);
    var in_menu=BattleEditor_PointInRect(mx,my,context_x,context_y,context_x+112,context_y+132);
    var in_submenu=context_submenu&&BattleEditor_PointInRect(mx,my,context_x+114,context_y+88,context_x+242,context_y+176);
    var handled_context=false;
    if(in_submenu){
        var shape_row=floor((my-(context_y+88))/22);
        if(context_frame>=-1){
            var shape_frame=context_frame==-1?main_board_preview:project.initialization.frames[context_frame];
            if(shape_row==0) BattleEditor_FrameSetPreset(shape_frame,"square");
            else if(shape_row==1) BattleEditor_FrameSetPreset(shape_frame,"rect");
            else if(shape_row==2) BattleEditor_FrameSetPreset(shape_frame,"circle");
            else if(shape_row==3) BattleEditor_FrameSetPreset(shape_frame,"triangle");
            BattleEditor_SyncBoardPreview(id,true);
            status_text="战斗框已强制转换形状";
        }
        context_open=false;context_submenu=false;handled_context=true;
    }else if(in_menu){
        if(menu_row==0&&(context_event>=0||context_frame>=-1)){
            if(context_event>=0){editor_clipboard=json_parse(json_stringify(project.events[context_event]));editor_clipboard_kind="event";}
            else{editor_clipboard=json_parse(json_stringify(context_frame==-1?main_board_preview:project.initialization.frames[context_frame]));editor_clipboard_kind="frame";}
            status_text="已复制";context_open=false;handled_context=true;
        }else if(menu_row==1&&(context_event>=0||context_frame>=0)){
            if(context_event>=0){
                editor_clipboard=json_parse(json_stringify(project.events[context_event]));editor_clipboard_kind="event";
                array_delete(project.events,context_event,1);selected=-1;
                timeline_duration_dirty=true;
            }else{
                editor_clipboard=json_parse(json_stringify(project.initialization.frames[context_frame]));editor_clipboard_kind="frame";
                array_delete(project.initialization.frames,context_frame,1);selected_frame=-2;BattleEditor_SyncBoardPreview(id,true);
            }
            status_text="已剪下";context_open=false;handled_context=true;
        }else if(menu_row==2&&!is_undefined(editor_clipboard)){
            var pasted=json_parse(json_stringify(editor_clipboard));
            if(editor_clipboard_kind=="event"){
                if(pasted.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&pasted.preset=="gb"){pasted.target_x=context_anchor_x;pasted.target_y=context_anchor_y;}
                else{pasted.transform.x=context_anchor_x;pasted.transform.y=context_anchor_y;}
                if(struct_exists(pasted,"uid")) struct_remove(pasted,"uid");
                // A pasted object is an independent authored group until the
                // user explicitly gives it another group's Control ID.
                if(struct_exists(pasted,"control_uid")) struct_remove(pasted,"control_uid");
                pasted.turn=developer_turn;
                pasted.name=BattleEditor_MakeUniqueName(project,pasted.name);
                BattleEditor_AssignIdentity(project,pasted,pasted.name,pasted.control_id);
                array_push(project.events,pasted);selected=array_length(project.events)-1;selected_frame=-2;
                timeline_duration_dirty=true;
                if(timeline_half_play){
                    if(!BattleEditor_UidArrayContains(new_object_preview_uids,pasted.uid)) array_push(new_object_preview_uids,pasted.uid);
                    timeline_reseek_requested=true;
                }
            }else{
                if(pasted.kind==BATTLE_EDITOR_BOARD_KIND.MAIN){pasted.kind=BATTLE_EDITOR_BOARD_KIND.ADD;pasted.cover=false;pasted.name="加框";pasted.board_depth=10;}
                if(struct_exists(pasted,"uid")) struct_remove(pasted,"uid");
                pasted.name=BattleEditor_MakeUniqueName(project,pasted.name);
                BattleEditor_AssignIdentity(project,pasted,pasted.name,pasted.control_id);
                pasted.x=context_anchor_x;pasted.y=context_anchor_y;
                array_push(project.initialization.frames,pasted);selected_frame=array_length(project.initialization.frames)-1;selected=-1;board_edit_session=true;BattleEditor_SyncBoardPreview(id,true);
            }
            status_text="已贴上";context_open=false;handled_context=true;
        }else if(menu_row==3&&(context_event>=0||context_frame>=0)){
            if(context_event>=0){array_delete(project.events,context_event,1);selected=-1;timeline_duration_dirty=true;}
            else{array_delete(project.initialization.frames,context_frame,1);selected_frame=-2;BattleEditor_SyncBoardPreview(id,true);}
            status_text="已删除";context_open=false;handled_context=true;
        }else if(menu_row==4&&context_frame>=-1){
            var add_vertex_frame=context_frame==-1?main_board_preview:project.initialization.frames[context_frame];
            drag_vertex_index=BattleEditor_FrameAddVertexWorld(add_vertex_frame,context_anchor_x,context_anchor_y);
            BattleEditor_SyncBoardPreview(id,true);status_text="已新增顶点";context_open=false;handled_context=true;
        }else if(menu_row==5&&context_frame>=-1){context_submenu=!context_submenu;handled_context=true;}
    }
    if(!handled_context&&!in_submenu){context_open=false;context_submenu=false;}
    if(handled_context) exit;
}

// Each top-level editor category is a single mutually-exclusive entry.
var toolbar_click=click&&!(tab==2&&workspace_open);
if(toolbar_click&&BattleEditor_PointInRect(mx,my,4,4,68,28)){tab=1;tool=0;object_palette=false;hazard_palette=false;board_palette=false;}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,71,4,159,28)){
    tab=0;tool=0;object_palette=!object_palette;hazard_palette=false;board_palette=false;selected_frame=-2;
    object_palette_anim_closing=!object_palette;
    object_palette_category_open=false;
    create_layer_mode=BATTLE_EDITOR_LAYER.IN_BOARD;
    create_layer_user_set=false;
    status_text="请选择要新增的对象类型";
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,162,4,210,28)){
    BattleEditor_WorkspaceSetOpen(id,true);tool=0;object_palette=false;hazard_palette=false;board_palette=false;
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,213,4,261,28)){
    object_palette=false;hazard_palette=false;board_palette=false;
    BattleEditor_RuntimeStart(id);
    timeline_full_play=true;
    status_text="正在播放下一怪物回合；空格拖住，Esc 恢复";
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,264,4,363,28)){
    file_confirm_action="file_menu";focus_field="";save_name_editing=false;
    save_browser_slots=BattleEditor_ListSaveSlots();save_browser_selected=-1;save_browser_scroll=0;
    save_browser_backup_flags=BattleEditor_SaveSlotBackupFlags(save_browser_slots);save_undo_load_ready_cache=BattleEditor_RuntimeSnapshotExists("undo_load");
    var save_active_name=BattleEditor_LoadActiveSlotName();
    save_active_name_cache=save_active_name;
    save_active_backup_ready_cache=save_active_name!=""&&BattleEditor_SaveSlotHasBackup(save_active_name);
    save_name_buffer=save_active_name!=""?save_active_name:BattleEditor_SanitizeSaveName(project.name);
    for(var save_active_index=0;save_active_index<array_length(save_browser_slots);save_active_index++) if(save_browser_slots[save_active_index]==save_name_buffer){save_browser_selected=save_active_index;break;}
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,366,4,414,28)){
    BattleEditor_Exit(id);
    room_goto(Storage_GetTempGeneral().Get(FLAG_TEMP_BATTLE_ROOM_RETURN));
    exit;
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,417,4,477,28)){
    tab=3;tool=0;object_palette=false;hazard_palette=false;board_palette=false;
    developer_turn=project.settings.developer_turn;
    status_text="开发者工具：回合切换只在下一次怪物回合生效";
}
else if(toolbar_click&&BattleEditor_PointInRect(mx,my,584,4,632,28)){
    tab=4;tool=0;object_palette=false;hazard_palette=false;board_palette=false;
    script_variables_open=false;help_scroll=0;
    status_text="编辑器教学：点击目录跳转，右下角回到目录";
}
else if(tab==0&&object_palette&&click&&BattleEditor_PointInRect(mx,my,390,124,632,148)) object_palette_category_open=!object_palette_category_open;
else if(tab==0&&object_palette&&object_palette_category_open&&click&&BattleEditor_PointInRect(mx,my,390,150,632,282)){
    var palette_category_row=floor((my-150)/22);
    if(palette_category_row>=0&&palette_category_row<6){object_palette_category=palette_category_row;object_palette_category_open=false;status_text="新对象 / "+BattleEditor_ObjectPaletteCategoryName(object_palette_category);}
}
else if(tab==0&&object_palette&&object_palette_category_open&&click){
    // A category dropdown owns only its trigger and option rows. Clicking any
    // other editor surface dismisses it, like leaving an ordinary input field.
    object_palette_category_open=false;
    deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
    exit;
}
else if(tab==0&&object_palette&&!object_palette_category_open&&click&&my>32&&mx<382){
    // Clicking back into the scene cancels the chooser. Keep the click for the
    // canvas after the panel has begun sliding away, rather than leaving a
    // permanent slab over the authoring view.
    object_palette=false;
    object_palette_anim_closing=true;
    deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
    exit;
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,158,506,182)){
    tool=1;object_palette=false;status_text="弹幕 / 骨头：点击战斗区域放置";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,158,632,182)){
    tool=3;object_palette=false;status_text="弹幕 / GB：点击战斗区域放置目标点";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,186,506,210)){
    tool=8;object_palette=false;status_text="真刀：点击战斗区域放置砍击位置";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,186,632,210)){
    tool=9;object_palette=false;status_text="斩击：点击战斗区域放置";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,214,506,238)){tool=10;object_palette=false;status_text="友谊颗粒：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,214,632,238)){tool=11;object_palette=false;status_text="火球：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,242,506,266)){tool=12;object_palette=false;status_text="长矛：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,242,632,266)){tool=13;object_palette=false;status_text="三叉戟：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,270,506,294)){tool=14;object_palette=false;status_text="刀子：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,270,632,294)){tool=16;object_palette=false;status_text="3D 骨：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,298,506,322)){tool=17;object_palette=false;status_text="4D 骨：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,512,298,632,322)){tool=18;object_palette=false;status_text="骨刺：点击战斗区域放置";}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==0&&click&&BattleEditor_PointInRect(mx,my,390,334,632,358)){
    choice_menu_open=true;choice_menu_context="create_layer";choice_menu_kind="layer";choice_menu_scroll=0;
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==1&&click&&BattleEditor_PointInRect(mx,my,390,158,632,182)){
    object_palette=false;tool=2;selected_frame=-2;status_text="自定义弹幕：点击战斗区域放置";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==2&&click&&BattleEditor_PointInRect(mx,my,390,158,632,182)){
    object_palette=false;tool=6;selected_frame=-2;status_text="装饰：点击战斗区域放置";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==3&&click&&BattleEditor_PointInRect(mx,my,390,158,632,182)){
    tool=0;object_palette=false;board_edit_session=true;selected=-1;selected_frame=-1;
    if(BattleEditor_RuntimeBeginSeek(id,0)) status_text="已显示怪物回合主框，并定格在 0:00";
    else status_text="无法显示怪物回合主框";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==3&&click&&BattleEditor_PointInRect(mx,my,390,186,632,210)){
    tool=4;object_palette=false;board_edit_session=true;status_text="点击战斗区域新增加框";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==3&&click&&BattleEditor_PointInRect(mx,my,390,214,632,238)){
    tool=5;object_palette=false;board_edit_session=true;status_text="点击战斗区域新增减框";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==4&&click&&BattleEditor_PointInRect(mx,my,390,158,632,182)){
    object_palette=false;tool=7;selected_frame=-2;status_text="打字机：点击战斗区域设置文字起始点";
}
else if(tab==0&&object_palette&&!object_palette_category_open&&object_palette_category==5&&click&&BattleEditor_PointInRect(mx,my,390,158,632,182)){
    object_palette=false;tool=15;selected_frame=-2;status_text="蓝魂平台：点击战斗区域放置";
}
else if(tab==0){
    if(click&&!object_palette&&!hazard_palette&&!board_palette&&selected<0&&selected_frame<-1&&BattleEditor_PointInRect(mx,my,478,110,632,134)){
        scene_objects_visible=!scene_objects_visible;
        project.settings.editor_show_objects=scene_objects_visible;
        status_text=scene_objects_visible?"已显示当前回合对象":"已隐藏当前回合对象；正在编辑的对象仍会显示";
        exit;
    }
    if(script_vertex_pick&&click&&mx<(object_palette||hazard_palette||board_palette?390:468)&&my>58&&my<392){
        var picked_vertex=false;
        for(var vertex_pick_frame_index=array_length(project.initialization.frames)-1;vertex_pick_frame_index>=-1;vertex_pick_frame_index--){
            var vertex_pick_frame=vertex_pick_frame_index==-1?main_board_preview:project.initialization.frames[vertex_pick_frame_index];
            var picked_vertex_index=BattleEditor_FrameVertexHit(vertex_pick_frame,mx,my,12);
            if(picked_vertex_index>=0){
                BattleEditor_FrameEnsurePolygon(vertex_pick_frame,project);
                BattleEditor_FrameEnsureVertexUids(project,vertex_pick_frame);
                var vertex_pick_step=project.script_lists[script_vertex_pick_list].steps[script_vertex_pick_step];
                vertex_pick_step.target_mode="control_id";
                vertex_pick_step.target=vertex_pick_frame.control_id;
                vertex_pick_step.target_type="board";
                var picked_vertex_uid=vertex_pick_frame.vertex_uids[picked_vertex_index];
                var already_selected=false;
                for(var selected_vertex_index=0;selected_vertex_index<array_length(vertex_pick_step.vertex_uids);selected_vertex_index++) if(vertex_pick_step.vertex_uids[selected_vertex_index]==picked_vertex_uid){already_selected=true;break;}
                if(!already_selected) array_push(vertex_pick_step.vertex_uids,picked_vertex_uid);
                BattleEditor_SyncBoardPreview(id,true);
                picked_vertex=true;
                if(!keyboard_check(vk_shift)){
                    script_vertex_pick=false;tab=2;script_selected_list=script_vertex_pick_list;script_selected_step=script_vertex_pick_step;
                    status_text="顶点已按隐藏 UID 绑定到控制脚本";
                }else status_text="已加入顶点；继续按住 Shift 点选，松开后可回脚本页";
                break;
            }
        }
        if(!picked_vertex) status_text="这里没有可选顶点";
        exit;
    }
    var timeline_can_scrub=current_state<0||current_state==BATTLE_STATE.MENU;
    if(timeline_can_scrub&&((click&&BattleEditor_PointInRect(mx,my,20,34,454,54))||(timeline_dragging&&mouse_check_button(mb_left)))){
        // The first scrub after any authoring batch is an explicit demand for
        // an exact scale. Refresh once before mapping the mouse to a frame;
        // subsequent drag samples reuse the same cache.
        if(click&&timeline_duration_dirty) BattleEditor_RefreshDurationCache(id);
        timeline_dragging=true;
        var timeline_duration=timeline_duration_cache;
        var live_cursor_time=clamp((mx-20)/434*timeline_duration,0,timeline_duration);
        cursor_time=live_cursor_time;
        timeline_live_seek_target=live_cursor_time;
        object_palette=false;hazard_palette=false;board_palette=false;
        // Re-evaluate while the thumb moves, not only after release. Repeating
        // the same pixel/time is skipped so a stationary mouse does no work.
        // Human mouse input can deliver far more samples than the scene can
        // visibly present. Recalculate at about 30 Hz while the thumb itself
        // follows every frame, but every recalculation is an atomic target
        // frame rather than an exposed fast-forward.
        var live_seek_due=click||current_time>=timeline_live_seek_next_time;
        if(live_seek_due&&(timeline_live_seek_pending||abs(timeline_live_seek_time-live_cursor_time)>0.0001)){
            if(BattleEditor_RuntimeBeginSeek(id,live_cursor_time,false,false)){
                timeline_live_seek_time=playhead;
                timeline_live_seek_pending=!timeline_seek_complete;
                cursor_time=live_cursor_time;
                timeline_live_seek_next_time=current_time+33;
                status_text=timeline_live_seek_pending
                    ?"正在计算 "+BattleEditor_FormatTimelineTime(cursor_time)+" 的目标状态"
                    :"已实时定格 "+BattleEditor_FormatTimelineTime(cursor_time)+"；新对象将在这里开始";
            }
        }
    }
    else if(click&&mx<(object_palette||hazard_palette||board_palette?390:468)&&my>58&&my<392&&tool>0){
        if(tool==1||tool==2||tool==3||tool==6||tool==7||(tool>=8&&tool<=18)){
            var created_object;
            if(tool==1) created_object=BattleEditor_NewBone(mx,my,cursor_time);
            else if(tool==2) created_object=BattleEditor_NewCustomSpriteHazard(mx,my,cursor_time);
            else if(tool==3) created_object=BattleEditor_NewGB(mx,my,cursor_time);
            else if(tool==8) created_object=BattleEditor_NewWaveHazard(mx,my,"true_knife",cursor_time);
            else if(tool==9) created_object=BattleEditor_NewWaveHazard(mx,my,"slash",cursor_time);
            else if(tool==10) created_object=BattleEditor_NewBuiltinSpriteHazard(mx,my,"friendship_pellet",cursor_time);
            else if(tool==11) created_object=BattleEditor_NewBuiltinSpriteHazard(mx,my,"fireball",cursor_time);
            else if(tool==12) created_object=BattleEditor_NewBuiltinSpriteHazard(mx,my,"spear",cursor_time);
            else if(tool==13) created_object=BattleEditor_NewBuiltinSpriteHazard(mx,my,"trident",cursor_time);
            else if(tool==14) created_object=BattleEditor_NewBuiltinSpriteHazard(mx,my,"knife",cursor_time);
            else if(tool==15) created_object=BattleEditor_NewPlatform(mx,my,cursor_time);
            else if(tool==16) created_object=BattleEditor_NewSolidBone(mx,my,"bone_3d",cursor_time);
            else if(tool==17) created_object=BattleEditor_NewSolidBone(mx,my,"bone_4d",cursor_time);
            else if(tool==18) created_object=BattleEditor_NewBone(mx,my,cursor_time,1);
            else if(tool==6) created_object=BattleEditor_NewDecoration(mx,my,cursor_time);
            else created_object=BattleEditor_NewTypewriter(mx,my,cursor_time);
            // Presets own their useful defaults.  An explicit palette choice
            // may override every object family, including the three mechanic
            // hazards; otherwise GB / Slash / True Knife remain OUTSIDE and
            // ordinary sprite hazards remain IN_BOARD.
            if(create_layer_user_set){
                created_object.layer_mode=create_layer_mode;
                created_object.clipped=create_layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD;
                if(created_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD) created_object.layer_user_set=true;
            }
            created_object.clip_mode="all";
            created_object.clip_frame_uids=[];
            created_object.clipped_collision=true;
            created_object.turn=developer_turn;
            created_object.name=BattleEditor_MakeUniqueName(project,created_object.name);
            BattleEditor_AssignIdentity(project,created_object,created_object.name,BattleEditor_NextControlId(project,created_object.preset));
            array_push(project.events,created_object);
            timeline_duration_dirty=true;
            selected=array_length(project.events)-1;
            if(timeline_half_play&&!BattleEditor_UidArrayContains(new_object_preview_uids,created_object.uid)) array_push(new_object_preview_uids,created_object.uid);
            selected_frame=-2;
            selected_animation_frame=-1;
            // A frozen real replay must be rebuilt so an object placed at the
            // cursor appears in that same runtime-derived frame.
            if(timeline_half_play) timeline_reseek_requested=true;
            status_text=created_object.name+" 已创建";
        }else{
            var created_frame=BattleEditor_NewFrame(mx,my,tool==5);
            created_frame.color_frame=project.initialization.board_color_default;
            created_frame.name=BattleEditor_MakeUniqueName(project,created_frame.name);
            BattleEditor_AssignIdentity(project,created_frame,created_frame.name,BattleEditor_NextControlId(project,created_frame.cover?"subtract_board":"add_board"));
            array_push(project.initialization.frames,created_frame);
            selected_frame=array_length(project.initialization.frames)-1;
            selected=-1;
            board_edit_session=true;
            BattleEditor_SyncBoardPreview(id,true);
            status_text=tool==5?"减框已创建":"加框已创建";
        }
        tool=0;
        create_layer_user_set=false;
        dragging=true;
        drag_offset_x=0;
        drag_offset_y=0;
    }
    else if(click&&mx<(object_palette||hazard_palette||board_palette?390:468)&&my>58){
        var clicked_event=-1;
        var previous_selected_frame=selected_frame;
        selected_frame=-2;
        selected_animation_frame=-1;
        hazard_palette=false;
        board_palette=false;
        object_palette=false;
        var clicked_event_stack=[];
        var clicked_uid_stack=[];
        for(var i=array_length(project.events)-1;i>=0;i--){
            if(!BattleEditor_EventBelongsToTurn(project.events[i],developer_turn)) continue;
            var is_new_object_preview=struct_exists(project.events[i],"uid")&&BattleEditor_UidArrayContains(new_object_preview_uids,project.events[i].uid);
            if(!scene_objects_visible&&i!=selected&&!is_new_object_preview) continue;
            if((!timeline_half_play||is_new_object_preview||BattleEditor_EventVisibleAtTime(project.events[i],cursor_time))&&BattleEditor_EventHit(project.events[i],mx,my,project,main_board_preview,id)){
                array_push(clicked_event_stack,i);
                array_push(clicked_uid_stack,project.events[i].uid);
            }
        }
        if(array_length(clicked_event_stack)>0){
            var same_click_stack=false;
            for(var stack_uid_index=0;stack_uid_index<array_length(clicked_uid_stack)&&!same_click_stack;stack_uid_index++){
                for(var previous_uid_index=0;previous_uid_index<array_length(scene_click_cycle_uids);previous_uid_index++) if(clicked_uid_stack[stack_uid_index]==scene_click_cycle_uids[previous_uid_index]){same_click_stack=true;break;}
            }
            var clicked_stack_index=0;
            if(same_click_stack&&selected>=0&&selected<array_length(project.events)){
                var previous_selected_uid=project.events[selected].uid;
                for(var cycle_index=0;cycle_index<array_length(clicked_uid_stack);cycle_index++) if(clicked_uid_stack[cycle_index]==previous_selected_uid){clicked_stack_index=(cycle_index+1) mod array_length(clicked_event_stack);break;}
            }
            clicked_event=clicked_event_stack[clicked_stack_index];
            scene_click_cycle_uids=clicked_uid_stack;
        }else{
            scene_click_cycle_uids=[];
        }
        selected=clicked_event;
        if(selected>=0){
            var click_uid=project.events[selected].uid;
            var group_double_click=last_scene_click_uid==click_uid&&(current_time-last_scene_click_time)<=350;
            last_scene_click_uid=click_uid;
            last_scene_click_time=current_time;
            if(group_double_click&&string(project.events[selected].control_id)!=""){
                group_selection_active=true;
                group_selection_type=BattleEditor_DataTargetType(project.events[selected]);
                group_selection_control_id=string(project.events[selected].control_id);
                status_text="已选中同一控制组的 "+string(BattleEditor_EventGroupCount(project,group_selection_type,group_selection_control_id,project.events[selected].control_uid,developer_turn))+" 个";
            }else{
                group_selection_active=false;
                group_selection_type="";
                group_selection_control_id="";
            }
        }else{
            group_selection_active=false;
            group_selection_type="";
            group_selection_control_id="";
            last_scene_click_uid=-1;
        }
        if(selected<0){
            var frames=project.initialization.frames;
            for(var i=array_length(frames)-1;i>=0;i--){
                if(BattleEditor_FrameHit(frames[i],mx,my)){selected_frame=i;break;}
            }
            // The unique main board is selected explicitly from its palette.
            // Once selected, it can be grabbed in the scene like any frame;
            // otherwise its large interior must not steal ordinary clicks.
            if(selected_frame==-2&&previous_selected_frame==-1&&BattleEditor_FrameHit(main_board_preview,mx,my)) selected_frame=-1;
        }
        dragging=selected>=0||selected_frame>=-1;
        if(selected>=0){
            cursor_time=project.events[selected].time;
            var drag_object=project.events[selected];
            if(drag_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&drag_object.preset=="gb"){
                drag_mode="target";
                drag_offset_x=mx-drag_object.target_x;
                drag_offset_y=my-drag_object.target_y;
            }else{
                drag_mode="object";
                if(drag_object.preset=="bone"&&drag_object.follow){
                    var followed_drag_world=BattleEditor_BoneWorldTransform(drag_object,project,main_board_preview);
                    drag_offset_x=mx-followed_drag_world.x;
                    drag_offset_y=my-followed_drag_world.y;
                }else{
                    drag_offset_x=mx-drag_object.transform.x;
                    drag_offset_y=my-drag_object.transform.y;
                }
            }
            group_drag_members=[];
            if(group_selection_active){
                for(var group_drag_index=0;group_drag_index<array_length(project.events);group_drag_index++){
                    var group_drag_object=project.events[group_drag_index];
                    if(!BattleEditor_IsSameEventGroup(drag_object,group_drag_object)) continue;
                    var group_origin_x=group_drag_object.transform.x;
                    var group_origin_y=group_drag_object.transform.y;
                    var group_is_gb=group_drag_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&group_drag_object.preset=="gb";
                    if(group_is_gb){group_origin_x=group_drag_object.target_x;group_origin_y=group_drag_object.target_y;}
                    else if(group_drag_object.preset=="bone"&&group_drag_object.follow){
                        var group_bone_world=BattleEditor_BoneWorldTransform(group_drag_object,project,main_board_preview);
                        group_origin_x=group_bone_world.x;group_origin_y=group_bone_world.y;
                    }
                    array_push(group_drag_members,{index:group_drag_index,x:group_origin_x,y:group_origin_y,is_gb:group_is_gb});
                    if(group_drag_index==selected){group_drag_primary_x=group_origin_x;group_drag_primary_y=group_origin_y;}
                }
            }
        }else if(selected_frame>=-1){
            drag_mode="frame";
            var picked_drag_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
            drag_offset_x=mx-picked_drag_frame.x;
            drag_offset_y=my-picked_drag_frame.y;
        }
    }

    if(mouse_check_button(mb_left)&&dragging){
        if(selected>=0){
            var moved_object=project.events[selected];
            var moved_track=moved_object.transform;
            if(group_selection_active&&array_length(group_drag_members)>0){
                var group_desired_x=mx-drag_offset_x;
                var group_desired_y=my-drag_offset_y;
                var group_delta_x=group_desired_x-group_drag_primary_x;
                var group_delta_y=group_desired_y-group_drag_primary_y;
                for(var group_move_index=0;group_move_index<array_length(group_drag_members);group_move_index++){
                    var group_member=group_drag_members[group_move_index];
                    if(group_member.index<0||group_member.index>=array_length(project.events)) continue;
                    var group_move_object=project.events[group_member.index];
                    var group_world_x=group_member.x+group_delta_x;
                    var group_world_y=group_member.y+group_delta_y;
                    if(group_member.is_gb){group_move_object.target_x=group_world_x;group_move_object.target_y=group_world_y;}
                    else if(group_move_object.preset=="bone"&&group_move_object.follow){
                        var group_follow_frame=BattleEditor_FollowFrameData(project,group_move_object.follow_target_uid,main_board_preview);
                        var group_local=RotateAround(0,0,group_world_x-group_follow_frame.x,group_world_y-group_follow_frame.y,0,0,-group_follow_frame.angle);
                        group_move_object.transform.x=group_local[0];group_move_object.transform.y=group_local[1];
                    }else{group_move_object.transform.x=group_world_x;group_move_object.transform.y=group_world_y;}
                }
            }else if(moved_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&moved_object.preset=="gb"){
                moved_object.target_x=mx-drag_offset_x;
                moved_object.target_y=my-drag_offset_y;
            }else{
                var moved_world_x=mx-drag_offset_x;
                var moved_world_y=my-drag_offset_y;
                if(moved_object.preset=="bone"&&moved_object.follow){
                    var moved_follow_frame=BattleEditor_FollowFrameData(project,moved_object.follow_target_uid,main_board_preview);
                    var moved_local=RotateAround(0,0,moved_world_x-moved_follow_frame.x,moved_world_y-moved_follow_frame.y,0,0,-moved_follow_frame.angle);
                    moved_track.x=moved_local[0];
                    moved_track.y=moved_local[1];
                }else{
                    moved_track.x=moved_world_x;
                    moved_track.y=moved_world_y;
                }
            }
        }else if(selected_frame>=-1){
            var moved_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
            // Authored scene objects are allowed outside the visible 640x480
            // canvas. Off-screen starts/ends are a normal attack-building
            // technique, so frame dragging follows the same unrestricted
            // world-coordinate rule already used by hazards and groups.
            moved_frame.x=mx-drag_offset_x;
            moved_frame.y=my-drag_offset_y;
            // Frame data already follows the pointer every step.  Keep the
            // compositor's live board struct in lockstep as well, so the
            // filled/clipped shape and connected border move with its handles
            // instead of snapping only after mouse release.
            BattleEditor_SyncBoardPreview(id,false);
        }
    }
    if(mouse_check_button_released(mb_left)){
        dragging=false;
        if(timeline_dragging){
            timeline_dragging=false;
            timeline_reseek_requested=false;
            var release_duration=timeline_duration_cache;
            var release_cursor_time=clamp((mx-20)/434*release_duration,0,release_duration);
            timeline_live_seek_target=release_cursor_time;
            if(timeline_live_seek_pending||abs(timeline_live_seek_time-release_cursor_time)>0.0001){
                cursor_time=release_cursor_time;
                if(BattleEditor_RuntimeBeginSeek(id,cursor_time,false,false)){
                    timeline_live_seek_time=playhead;
                    timeline_live_seek_pending=!timeline_seek_complete;
                    cursor_time=release_cursor_time;
                }
            }
            status_text=timeline_live_seek_pending
                ?"正在计算 "+BattleEditor_FormatTimelineTime(cursor_time)+" 的目标状态"
                :"已定格下一怪物回合 "+BattleEditor_FormatTimelineTime(cursor_time)+" 的目标状态";
            exit;
        }
        if(timeline_reseek_requested){
            timeline_reseek_requested=false;
            if(BattleEditor_RuntimeBeginSeek(id,cursor_time,true)) status_text="已重建 "+BattleEditor_FormatTimelineTime(cursor_time)+" 的新增细节";
            exit;
        }
    }

    var amount=keyboard_check(vk_shift)?10:(keyboard_check(vk_control)?5:1);
    var property_original_my=my;
    // Object properties are a scrollable inspector. Switching selection always
    // returns to the top, while the scene itself keeps its wheel controls.
    var property_key_data=selected>=0?project.events[selected]:(selected_frame>=-1?(selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame]):undefined);
    var property_current_key=is_undefined(property_key_data)?"":((selected>=0?"event:":"frame:")+(struct_exists(property_key_data,"uid")?string(property_key_data.uid):string(selected)+":"+string(selected_frame)));
    if(property_current_key!=property_scroll_key){property_scroll_key=property_current_key;property_scroll=0;}
    if(mx>=468&&my>=106&&my<=438&&(selected>=0||selected_frame>=-1)){
        if(mouse_wheel_up()) property_scroll=max(0,property_scroll-28);
        if(mouse_wheel_down()) property_scroll=min(900,property_scroll+28);
        my+=property_scroll;
    }
    if(selected>=0){
        var selected_object=project.events[selected];
        var selected_track=selected_object.transform;
        var is_bone=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&selected_object.preset=="bone";
        var is_gb=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&selected_object.preset=="gb";
        var is_typewriter=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER;
        var is_wave=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(selected_object.preset=="slash"||selected_object.preset=="true_knife");
        var is_solid=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(selected_object.preset=="bone_3d"||selected_object.preset=="bone_4d");
        var is_platform=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&selected_object.preset=="platform";
        var is_builtin_sprite=selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&selected_object.preset!="bone"&&selected_object.preset!="custom_sprite";
        var has_animation=struct_exists(selected_object,"animation");
        // The wheel belongs to the current selection, not to a tiny sprite hit
        // target. Keep the right property panel scrollable, but anywhere in
        // the scene/timeline area rotates the selected object or whole group.
        if(mx<468&&(mouse_wheel_up()||mouse_wheel_down())){
            var wheel_angle_delta=mouse_wheel_up()?amount:-amount;
            var wheel_rotated=BattleEditor_RotateEventSelection(project,selected,wheel_angle_delta,main_board_preview,
                group_selection_active?group_selection_type:"",group_selection_active?group_selection_control_id:"");
            status_text=(group_selection_active?"已整体旋转 "+string(wheel_rotated)+" 个对象：":"已旋转：")+string(wheel_angle_delta)+"°";
        }
        if(click&&BattleEditor_PointInRect(mx,my,518,130,632,152)){
            choice_menu_open=true;choice_menu_context="event_layer";choice_menu_kind="layer";choice_menu_event=selected;choice_menu_scroll=0;
        }else if(!is_typewriter&&!is_platform&&click&&BattleEditor_PointInRect(mx,my,538,158,632,180)){
            var toggle_visual_mode=clamp(round(real(selected_object.visual_tint.mode)),0,2);
            if(toggle_visual_mode==2) BattleEditor_SetVisualTintMode(selected_object,1);
            else{
                selected_object.visual_tint.custom_color=selected_object.visual_tint.color;
                BattleEditor_SetVisualTintMode(selected_object,2);
            }
            if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"visual_color_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
        }else if(!is_typewriter&&!is_platform&&click&&BattleEditor_PointInRect(mx,my,538,186,632,208)){
            var selected_visual_mode=clamp(round(real(selected_object.visual_tint.mode)),0,2);
            if(selected_visual_mode!=2){choice_menu_open=true;choice_menu_context="visual_color_preset";choice_menu_kind="visual_color_preset";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(selected_visual_mode==2) BattleEditor_OpenColorPicker(id,"event_tint",selected_object.visual_tint.custom_color,1);
        }else if(!is_typewriter&&!is_platform&&struct_exists(selected_object,"damage_profile")&&click&&BattleEditor_PointInRect(mx,my,478,214,632,236)){
            BattleEditor_SetDamageChangeVisual(selected_object,!selected_object.damage_profile.change_visual);
            if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"damage_change_visual",wave_inspector_phase,group_selection_type,group_selection_control_id);
        }
        if(click&&BattleEditor_PointInRect(mx,my,514,64,632,82)){focus_field="object_name";keyboard_string=selected_object.name;}
        else if(click&&BattleEditor_PointInRect(mx,my,510,86,570,104)){focus_field="object_control_id";keyboard_string=selected_object.control_id;}
        // Draw shifts the property body down to make room for the dedicated
        // layer row. Reuse all existing hit rectangles in body-local space.
        var selected_property_header_offset=(is_typewriter||is_platform)?28:(struct_exists(selected_object,"damage_profile")?112:84);
        my-=selected_property_header_offset;
        if(is_typewriter){
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="track_scale_x";keyboard_string=string(selected_track.scale_x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="track_scale_y";keyboard_string=string(selected_track.scale_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="track_alpha";keyboard_string=string(selected_track.alpha);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="typewriter_speed";keyboard_string=string(selected_object.speed);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,300,552,320)){font_dropdown_open=true;font_dropdown_target="typewriter";font_dropdown_scroll=clamp(selected_object.font_id-4,0,max(0,TextTyper_FontCount()-10));}
            else if(click&&BattleEditor_PointInRect(mx,my,558,300,632,320)){focus_field="typewriter_depth";keyboard_string=string(selected_object.text_depth);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,338,552,358)){
                var current_typer_color=is_real(selected_object.text_color)?selected_object.text_color:GetColorFromString(selected_object.text_color);
                BattleEditor_OpenColorPicker(id,"event_text",current_typer_color,1);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,558,338,632,358)){
                text_editor_open=true;text_editor_target="typewriter";text_editor_buffer=selected_object.text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;color_picker_open=false;keyboard_string="";
            }else if(click&&BattleEditor_PointInRect(mx,my,478,364,552,386)){
                if(instance_exists(text_editor_preview)) instance_destroy(text_editor_preview);
                text_editor_preview=BattleEditor_SpawnEvent(selected_object,project.initialization);
                text_editor_preview_frames=max(30,BattleEditor_EventEndTime(selected_object)-selected_object.time);
                text_editor_preview_mode=instance_exists(text_editor_preview);
                status_text="已播放一次真实打字过程";
            }else if(click&&BattleEditor_PointInRect(mx,my,558,364,632,386)){
                selected_object.page_requires_confirm=!selected_object.page_requires_confirm;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"typewriter_confirm",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }else if(click&&BattleEditor_PointInRect(mx,my,478,390,598,412)){
                choice_menu_open=true;choice_menu_context="typewriter_voice";choice_menu_kind="voice";choice_menu_event=selected;choice_menu_scroll=0;
            }else if(click&&BattleEditor_PointInRect(mx,my,604,390,632,412)) BattleEditor_AudioPreviewToggleVoice(id,selected_object.voice_id,"typewriter_"+string(selected_object.uid));
        }else if(is_solid){
            var solid_keys=BattleEditor_SolidBoneFieldKeys(selected_object.preset);
            for(var solid_field_index=0;solid_field_index<array_length(solid_keys);solid_field_index++){
                var solid_field_y=132+solid_field_index*42;
                if(!click||!BattleEditor_PointInRect(mx,my,478,solid_field_y+16,632,solid_field_y+38)) continue;
                var solid_key=solid_keys[solid_field_index];
                if(solid_key=="shape_3d"){
                    choice_menu_open=true;choice_menu_context="solid_shape";choice_menu_kind="solid_shape";choice_menu_event=selected;choice_menu_scroll=0;
                }else if(solid_key=="damage_type"){
                    damage_dropdown_open=true;damage_dropdown_event=selected;
                }else{
                    focus_field="solid_field_"+string(solid_field_index);
                    keyboard_string=solid_key=="time"?BattleEditor_FormatTimelineTime(BattleEditor_SolidBoneFieldValue(selected_object,solid_key)):string(BattleEditor_SolidBoneFieldValue(selected_object,solid_key));
                }
                break;
            }
        }else if(is_platform){
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="platform_width";keyboard_string=string(selected_object.width);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="object_duration";keyboard_string=string(selected_object.duration);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="platform_hspeed";keyboard_string=string(selected_object.hspeed);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="platform_vspeed";keyboard_string=string(selected_object.vspeed);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,300,632,322)){choice_menu_open=true;choice_menu_context="platform_type";choice_menu_kind="platform_type";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(click&&BattleEditor_PointInRect(mx,my,478,328,632,350)){
                selected_object.bounce=!selected_object.bounce;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"platform_bounce",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
        }else if(is_bone){
            if(keyboard_check_pressed(vk_left)) selected_track.angle-=amount;
            if(keyboard_check_pressed(vk_right)) selected_track.angle+=amount;
            if(keyboard_check_pressed(vk_up)) selected_object.length+=amount;
            if(keyboard_check_pressed(vk_down)) selected_object.length=max(4,selected_object.length-amount);
            if(click&&BattleEditor_PointInRect(mx,my,478,148,632,168)){choice_menu_open=true;choice_menu_context="bone_style";choice_menu_kind="bone_style";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="bone_rotate";keyboard_string=string(selected_object.rotate);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="bone_length";keyboard_string=string(selected_object.length);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="object_duration";keyboard_string=string(selected_object.duration);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,300,552,320)){focus_field="bone_hspeed";keyboard_string=string(selected_object.hspeed);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,300,632,320)){focus_field="bone_vspeed";keyboard_string=string(selected_object.vspeed);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,338,552,358)){damage_dropdown_open=true;damage_dropdown_event=selected;}
            else if(click&&BattleEditor_PointInRect(mx,my,558,338,632,358)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,364,552,386)){
                selected_object.green_guard_blockable=!selected_object.green_guard_blockable;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"green_guard_blockable",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,558,364,632,386)){
                selected_object.green_guard_destroy_on_block=!selected_object.green_guard_destroy_on_block;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"green_guard_destroy_on_block",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,478,392,552,416)){
                var enable_group_follow=!selected_object.follow;
                if(group_selection_active) BattleEditor_SetGroupBoneFollow(project,selected,enable_group_follow,selected_object.follow_target_uid,main_board_preview,group_selection_type,group_selection_control_id);
                else BattleEditor_BoneSetFollow(selected_object,enable_group_follow,project,main_board_preview);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,558,392,632,416)){
                follow_dropdown_open=true;
                follow_dropdown_event=selected;
                follow_dropdown_scroll=0;
            }
            else if(selected_object.damage_profile.type==3&&click&&BattleEditor_PointInRect(mx,my,478,436,632,456)){focus_field="object_heal_amount";keyboard_string=string(selected_object.damage_profile.heal_amount);}
            else if(selected_object.damage_profile.type!=3&&click&&BattleEditor_PointInRect(mx,my,478,436,632,456)){focus_field="object_damage";keyboard_string=string(selected_object.damage_profile.damage);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,474,632,498)){choice_menu_open=true;choice_menu_context="bone_aim_behavior";choice_menu_kind="bone_aim_behavior";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(click&&BattleEditor_PointInRect(mx,my,478,516,632,540)){
                aim_dropdown_open=true;aim_dropdown_event=selected;aim_dropdown_scroll=0;
            }
            else if(click&&BattleEditor_PointInRect(mx,my,478,558,552,582)){choice_menu_open=true;choice_menu_context="bone_aim_update";choice_menu_kind="aim_update";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(selected_object.aim_enabled&&selected_object.aim_move_enabled&&click&&BattleEditor_PointInRect(mx,my,558,558,632,582)){focus_field="bone_aim_speed";keyboard_string=string(selected_object.aim_move_speed);}
        }else if(is_gb){
            if(keyboard_check_pressed(vk_left)) selected_object.angle_target-=amount;
            if(keyboard_check_pressed(vk_right)) selected_object.angle_target+=amount;
            if(keyboard_check_pressed(vk_up)){selected_track.scale_x+=0.1;selected_track.scale_y+=0.1;}
            if(keyboard_check_pressed(vk_down)){selected_track.scale_x=max(0.2,selected_track.scale_x-0.1);selected_track.scale_y=max(0.2,selected_track.scale_y-0.1);}
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="gb_target_x";keyboard_string=string(selected_object.target_x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="gb_target_y";keyboard_string=string(selected_object.target_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,632,206)){gb_spawn_dropdown_open=true;gb_spawn_dropdown_event=selected;gb_spawn_dropdown_scroll=clamp(selected_object.spawn_preset-4,0,9);}
            else if(selected_object.spawn_preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM&&click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="gb_spawn_x";keyboard_string=string(selected_object.spawn_x);}
            else if(selected_object.spawn_preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM&&click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="gb_spawn_y";keyboard_string=string(selected_object.spawn_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="gb_spawn_angle";keyboard_string=string(selected_object.angle_start);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="gb_target_angle";keyboard_string=string(selected_object.angle_target);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,300,552,320)){focus_field="track_scale_x";keyboard_string=string(selected_track.scale_x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,300,632,320)){focus_field="track_scale_y";keyboard_string=string(selected_track.scale_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,338,526,358)){focus_field="gb_move_time";keyboard_string=string(selected_object.move_time);}
            else if(click&&BattleEditor_PointInRect(mx,my,531,338,579,358)){focus_field="gb_charge_time";keyboard_string=string(selected_object.charge_time);}
            else if(click&&BattleEditor_PointInRect(mx,my,584,338,632,358)){focus_field="gb_beam_time";keyboard_string=string(selected_object.beam_time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,380,552,402)){choice_menu_open=true;choice_menu_context="gb_fake";choice_menu_kind="gb_fake";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(click&&BattleEditor_PointInRect(mx,my,558,380,632,402)){damage_dropdown_open=true;damage_dropdown_event=selected;}
            else if(click&&BattleEditor_PointInRect(mx,my,478,422,552,444)){choice_menu_open=true;choice_menu_context="gb_tween";choice_menu_kind="tween";choice_menu_event=selected;choice_menu_scroll=clamp(selected_track.tween-4,0,1);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,422,632,444)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(selected_object.damage_profile.type==3&&click&&BattleEditor_PointInRect(mx,my,478,464,632,486)){focus_field="object_heal_amount";keyboard_string=string(selected_object.damage_profile.heal_amount);}
            else if(selected_object.damage_profile.type!=3&&click&&BattleEditor_PointInRect(mx,my,478,464,632,486)){focus_field="object_damage";keyboard_string=string(selected_object.damage_profile.damage);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,492,632,514)){
                selected_object.offset_enabled=!selected_object.offset_enabled;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"gb_offset_enabled",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,478,536,632,558)){choice_menu_open=true;choice_menu_context="gb_offset_direction";choice_menu_kind="gb_offset_direction";choice_menu_event=selected;choice_menu_scroll=0;}
            else if(round(real(selected_object.offset_direction_mode))==0&&click&&BattleEditor_PointInRect(mx,my,478,578,552,598)){focus_field="gb_offset_speed";keyboard_string=string(selected_object.offset_speed);}
            else if(round(real(selected_object.offset_direction_mode))==0&&click&&BattleEditor_PointInRect(mx,my,558,578,632,598)){focus_field="gb_offset_acceleration";keyboard_string=string(selected_object.offset_acceleration);}
            else if(round(real(selected_object.offset_direction_mode))==0&&click&&BattleEditor_PointInRect(mx,my,478,616,632,636)){focus_field="gb_offset_rotation";keyboard_string=string(selected_object.offset_rotation_speed);}
            else if(round(real(selected_object.offset_direction_mode))!=0&&click&&BattleEditor_PointInRect(mx,my,478,578,552,598)){focus_field="gb_offset_direction";keyboard_string=string(selected_object.offset_direction);}
            else if(round(real(selected_object.offset_direction_mode))!=0&&click&&BattleEditor_PointInRect(mx,my,558,578,632,598)){focus_field="gb_offset_speed";keyboard_string=string(selected_object.offset_speed);}
            else if(round(real(selected_object.offset_direction_mode))!=0&&click&&BattleEditor_PointInRect(mx,my,478,616,632,636)){focus_field="gb_offset_acceleration";keyboard_string=string(selected_object.offset_acceleration);}
            else if(round(real(selected_object.offset_direction_mode))!=0&&click&&BattleEditor_PointInRect(mx,my,478,654,632,674)){focus_field="gb_offset_rotation";keyboard_string=string(selected_object.offset_rotation_speed);}
            else if(array_length(project.resources.gb_styles)>0&&click&&BattleEditor_PointInRect(mx,my,478,748,632,772)){
                gb_style_dropdown_open=true;gb_style_dropdown_event=selected;
                gb_style_dropdown_scroll=max(0,BattleEditor_WorkspaceCreateChoiceIndex("gb_style",selected_object.gb_style_uid,project)-4);
            }
        }else if(is_wave){
            var selected_true_knife=selected_object.preset=="true_knife";
            if(selected_true_knife) wave_inspector_phase=1;
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){damage_dropdown_open=true;damage_dropdown_event=selected;}
            else if(!selected_true_knife&&selected_object.damage_profile.type==3&&click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="object_heal_amount";keyboard_string=string(selected_object.damage_profile.heal_amount);}
            else if(selected_object.damage_profile.type!=3&&click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="object_damage";keyboard_string=string(selected_object.damage_profile.damage);}
            else if(selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,478,266,632,286)){focus_field="true_knife_invincibility";keyboard_string=string(selected_object.invincibility_frames);}
            else if(!selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="wave_warning_time";keyboard_string=string(selected_object.warning_time);}
            else if(!selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="wave_active_time";keyboard_string=string(selected_object.active_time);}
            else if(!selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,478,300,632,320)){focus_field="wave_min_width";keyboard_string=string(selected_object.visual_min_width);}
            else if(!selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,478,324,552,344)) wave_inspector_phase=0;
            else if(!selected_true_knife&&click&&BattleEditor_PointInRect(mx,my,558,324,632,344)) wave_inspector_phase=1;
            else{
                var selected_wave_motion=wave_inspector_phase==0?selected_object.pre_motion:selected_object.post_motion;
                var selected_wave_section_y=selected_true_knife?336:344;
                if(click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y,552,selected_wave_section_y+20)) wave_inspector_section=0;
                else if(click&&BattleEditor_PointInRect(mx,my,558,selected_wave_section_y,632,selected_wave_section_y+20)) wave_inspector_section=1;
                else if(wave_inspector_section==0){
                    if(click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y+34,552,selected_wave_section_y+52)){focus_field="wave_motion_direction";keyboard_string=string(selected_wave_motion.direction);}
                    else if(click&&BattleEditor_PointInRect(mx,my,558,selected_wave_section_y+34,632,selected_wave_section_y+52)){focus_field="wave_motion_speed";keyboard_string=string(selected_wave_motion.speed);}
                    else if(click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y+66,552,selected_wave_section_y+84)){focus_field="wave_motion_acceleration";keyboard_string=string(selected_wave_motion.acceleration);}
                    else if(click&&BattleEditor_PointInRect(mx,my,558,selected_wave_section_y+66,632,selected_wave_section_y+84)){focus_field="wave_motion_curve";keyboard_string=string(selected_wave_motion.curve_speed);}
                }else{
                    var mode_right=selected_wave_motion.rotation_mode==2?548:632;
                    if(click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y+23,mode_right,selected_wave_section_y+43)){choice_menu_open=true;choice_menu_context="wave_rotation";choice_menu_kind="wave_rotation";choice_menu_event=selected;choice_menu_phase=wave_inspector_phase;choice_menu_scroll=0;}
                    else if(selected_wave_motion.rotation_mode==2&&click&&BattleEditor_PointInRect(mx,my,550,selected_wave_section_y+23,596,selected_wave_section_y+43)){choice_menu_open=true;choice_menu_context="wave_tween";choice_menu_kind="tween";choice_menu_event=selected;choice_menu_phase=wave_inspector_phase;choice_menu_scroll=clamp(selected_wave_motion.tween-4,0,1);}
                    else if(selected_wave_motion.rotation_mode==2&&click&&BattleEditor_PointInRect(mx,my,598,selected_wave_section_y+23,632,selected_wave_section_y+43)){choice_menu_open=true;choice_menu_context="wave_ease";choice_menu_kind="ease";choice_menu_event=selected;choice_menu_phase=wave_inspector_phase;choice_menu_scroll=0;}
                    else if(selected_wave_motion.rotation_mode==1&&click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y+59,632,selected_wave_section_y+81)){focus_field="wave_rotation_speed";keyboard_string=string(selected_wave_motion.rotation_speed);}
                    else if(selected_wave_motion.rotation_mode==2&&click&&BattleEditor_PointInRect(mx,my,478,selected_wave_section_y+59,552,selected_wave_section_y+81)){focus_field="wave_rotation_target";keyboard_string=string(selected_wave_motion.target_angle);}
                    else if(selected_wave_motion.rotation_mode==2&&click&&BattleEditor_PointInRect(mx,my,558,selected_wave_section_y+59,632,selected_wave_section_y+81)){focus_field="wave_rotation_time";keyboard_string=string(selected_wave_motion.rotation_time);}
                }
            }
        }else if(is_builtin_sprite){
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="track_scale_x";keyboard_string=string(selected_track.scale_x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="track_scale_y";keyboard_string=string(selected_track.scale_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,632,284)){damage_dropdown_open=true;damage_dropdown_event=selected;}
            else if(selected_object.damage_profile.type==3&&click&&BattleEditor_PointInRect(mx,my,478,304,552,326)){focus_field="object_heal_amount";keyboard_string=string(selected_object.damage_profile.heal_amount);}
            else if(selected_object.damage_profile.type!=3&&click&&BattleEditor_PointInRect(mx,my,478,304,552,326)){focus_field="object_damage";keyboard_string=string(selected_object.damage_profile.damage);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,304,632,326)){focus_field="object_duration";keyboard_string=string(selected_object.duration);}
        }else{
            if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="track_x";keyboard_string=string(selected_track.x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="track_y";keyboard_string=string(selected_track.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="track_angle";keyboard_string=string(selected_track.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="track_alpha";keyboard_string=string(selected_track.alpha);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="track_scale_x";keyboard_string=string(selected_track.scale_x);}
            else if(click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="track_scale_y";keyboard_string=string(selected_track.scale_y);}
            else if(click&&BattleEditor_PointInRect(mx,my,570,262,632,282)){
                var selected_sprite_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择贴图");
                if(string_length(selected_sprite_path)>0) selected_object.sprite_source=BattleEditor_StageResource(selected_sprite_path);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,478,262,566,282)){focus_field="object_sprite";keyboard_string=selected_object.sprite_source;}
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,570,300,632,320)){
                var selected_frame_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择动画帧");
                if(string_length(selected_frame_path)>0){
                    selected_frame_path=BattleEditor_StageResource(selected_frame_path);
                    var selected_frame_files=selected_object.animation.frames;
                    if(array_length(selected_frame_files)<=0){array_push(selected_frame_files,selected_frame_path);selected_animation_frame=0;}
                    else{selected_animation_frame=clamp(selected_animation_frame,0,array_length(selected_frame_files)-1);selected_frame_files[selected_animation_frame]=selected_frame_path;}
                    selected_object.animation.frames=selected_frame_files;
                }
            }
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,478,300,566,320)){
                var editable_frames=selected_object.animation.frames;
                if(array_length(editable_frames)<=0){array_push(editable_frames,"");selected_object.animation.frames=editable_frames;selected_animation_frame=0;}
                selected_animation_frame=clamp(selected_animation_frame,0,array_length(editable_frames)-1);
                focus_field="animation_frame";
                keyboard_string=editable_frames[selected_animation_frame];
            }
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,508,324,536,346)){
                var added_frames=selected_object.animation.frames;
                array_push(added_frames,"");
                selected_object.animation.frames=added_frames;
                selected_animation_frame=array_length(added_frames)-1;
                focus_field="animation_frame";
                keyboard_string="";
            }
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,478,324,506,346)&&selected_animation_frame>=0){
                var removed_frames=selected_object.animation.frames;
                if(selected_animation_frame<array_length(removed_frames)) array_delete(removed_frames,selected_animation_frame,1);
                selected_object.animation.frames=removed_frames;
                selected_animation_frame=min(selected_animation_frame,array_length(removed_frames)-1);
            }
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,538,324,566,346)) selected_animation_frame=max(0,selected_animation_frame-1);
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,568,324,596,346)) selected_animation_frame=min(array_length(selected_object.animation.frames)-1,selected_animation_frame+1);
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,598,324,632,346)){
                selected_object.animation.loop=!selected_object.animation.loop;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"animation_loop",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(has_animation&&click&&BattleEditor_PointInRect(mx,my,478,366,530,386)){focus_field="animation_fps";keyboard_string=string(selected_object.animation.fps);}
            else if(click&&BattleEditor_PointInRect(mx,my,534,366,632,386)){focus_field="object_duration";keyboard_string=string(selected_object.duration);}
            else if(click&&BattleEditor_PointInRect(mx,my,478,406,selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION?632:552,426)){focus_field="object_time";keyboard_string=BattleEditor_FormatTimelineTime(selected_object.time);}
            else if(selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&click&&BattleEditor_PointInRect(mx,my,558,406,632,426)){damage_dropdown_open=true;damage_dropdown_event=selected;}
            else if(selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&selected_object.damage_profile.type==3&&click&&BattleEditor_PointInRect(mx,my,478,448,632,468)){focus_field="object_heal_amount";keyboard_string=string(selected_object.damage_profile.heal_amount);}
            else if(selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&selected_object.damage_profile.type!=3&&click&&BattleEditor_PointInRect(mx,my,478,448,632,468)){focus_field="object_damage";keyboard_string=string(selected_object.damage_profile.damage);}
        }
        if(selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&struct_exists(selected_object,"layer_mode")&&selected_object.layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD){
            var selected_clip_y=is_bone?600:(is_typewriter?434:(is_builtin_sprite?358:((selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION)?486:444)));
            if(click&&BattleEditor_PointInRect(mx,my,478,selected_clip_y+20,552,selected_clip_y+42)){
                selected_object.clip_mode=selected_object.clip_mode=="all"?"selected":"all";
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"clip_mode",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
            else if(click&&BattleEditor_PointInRect(mx,my,558,selected_clip_y+20,632,selected_clip_y+42)){
                clip_editor_open=true;clip_editor_event=selected;clip_editor_scroll=0;clip_editor_filter="";
            }
            else if(click&&BattleEditor_PointInRect(mx,my,478,selected_clip_y+48,632,selected_clip_y+72)){
                selected_object.clipped_collision=!selected_object.clipped_collision;
                if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"clipped_collision",wave_inspector_phase,group_selection_type,group_selection_control_id);
            }
        }
        if(keyboard_check_pressed(vk_pageup)){selected_object.time=max(0,selected_object.time+5);cursor_time=selected_object.time;}
        if(keyboard_check_pressed(vk_pagedown)){selected_object.time=max(0,selected_object.time-5);cursor_time=selected_object.time;}
        if(keyboard_check_pressed(ord("T"))&&selected_object.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&!is_platform){damage_dropdown_open=true;damage_dropdown_event=selected;}
        if(keyboard_check_pressed(ord("C"))&&struct_exists(selected_object,"layer_mode")){
            selected_object.layer_mode=BattleEditor_CycleLayer(selected_object.layer_mode,1);
            selected_object.clipped=selected_object.layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD;
            if(selected_object.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD) selected_object.layer_user_set=true;
        }
        if(keyboard_check_pressed(ord("L"))&&has_animation){
            selected_object.animation.loop=!selected_object.animation.loop;
            if(group_selection_active) BattleEditor_SyncEventGroupField(project,selected,"animation_loop",wave_inspector_phase,group_selection_type,group_selection_control_id);
        }
        if(keyboard_check_pressed(vk_delete)){array_delete(project.events,selected,1);selected=-1;selected_animation_frame=-1;timeline_duration_dirty=true;}
    }else if(selected_frame>=-1){
        var edited_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
        if(click&&BattleEditor_PointInRect(mx,my,514,64,632,82)){focus_field="frame_name";keyboard_string=edited_frame.name;}
        else if(click&&BattleEditor_PointInRect(mx,my,510,86,570,104)){focus_field="frame_control_id";keyboard_string=edited_frame.control_id;}
        if(click&&BattleEditor_PointInRect(mx,my,478,148,552,168)){focus_field="frame_x";keyboard_string=string(edited_frame.x);}
        else if(click&&BattleEditor_PointInRect(mx,my,558,148,632,168)){focus_field="frame_y";keyboard_string=string(edited_frame.y);}
        else if(edited_frame.shape=="circle"&&click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="frame_radius_x";keyboard_string=string(edited_frame.radius_x);}
        else if(edited_frame.shape=="circle"&&click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="frame_radius_y";keyboard_string=string(edited_frame.radius_y);}
        else if(edited_frame.shape=="triangle"&&click&&BattleEditor_PointInRect(mx,my,478,186,632,206)){focus_field="frame_triangle_size";keyboard_string=string(edited_frame.triangle_size);}
        else if(edited_frame.shape=="rect"&&click&&BattleEditor_PointInRect(mx,my,478,186,552,206)){focus_field="frame_up";keyboard_string=string(edited_frame.up);}
        else if(edited_frame.shape=="rect"&&click&&BattleEditor_PointInRect(mx,my,558,186,632,206)){focus_field="frame_down";keyboard_string=string(edited_frame.down);}
        else if(edited_frame.shape=="rect"&&click&&BattleEditor_PointInRect(mx,my,478,224,552,244)){focus_field="frame_left";keyboard_string=string(edited_frame.left);}
        else if(edited_frame.shape=="rect"&&click&&BattleEditor_PointInRect(mx,my,558,224,632,244)){focus_field="frame_right";keyboard_string=string(edited_frame.right);}
        else if(click&&BattleEditor_PointInRect(mx,my,478,262,552,282)){focus_field="frame_angle";keyboard_string=string(edited_frame.angle);}
        else if(click&&BattleEditor_PointInRect(mx,my,558,262,632,282)){focus_field="frame_rotate";keyboard_string=string(edited_frame.rotate);}
        else if(click&&BattleEditor_PointInRect(mx,my,478,300,552,320)){focus_field="frame_depth";keyboard_string=string(edited_frame.board_depth);}
        else if(click&&BattleEditor_PointInRect(mx,my,478,338,624,358)) BattleEditor_OpenColorPicker(id,"frame",edited_frame.color_frame,1);
        if(keyboard_check_pressed(vk_left)) edited_frame.left=max(10,edited_frame.left-amount);
        if(keyboard_check_pressed(vk_right)) edited_frame.right+=amount;
        if(keyboard_check_pressed(vk_up)) edited_frame.up+=amount;
        if(keyboard_check_pressed(vk_down)) edited_frame.down=max(10,edited_frame.down-amount);
        if(keyboard_check_pressed(ord("Q"))) edited_frame.angle-=amount;
        if(keyboard_check_pressed(ord("E"))) edited_frame.angle+=amount;
        if(mx<468&&mouse_wheel_up()){edited_frame.angle+=amount;status_text="已旋转战斗框：+"+string(amount)+"°";}
        if(mx<468&&mouse_wheel_down()){edited_frame.angle-=amount;status_text="已旋转战斗框：-"+string(amount)+"°";}
        if(selected_frame>=0&&keyboard_check_pressed(vk_delete)){
            array_delete(project.initialization.frames,selected_frame,1);
            selected_frame=-2;
            BattleEditor_SyncBoardPreview(id,true);
        }
    }
    my=property_original_my;
}else if(tab==1){
    var init=project.initialization;
    var editor_turn_data=BattleEditor_GetTurnData(project,developer_turn,true);
    // Nested initialization pages keep unrelated settings off-screen.  A
    // click on a page tab always closes the local turn selector.
    if(click&&BattleEditor_PointInRect(mx,my,20,42,144,66)){initialization_page=0;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
    if(click&&BattleEditor_PointInRect(mx,my,148,42,294,66)){initialization_page=1;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
    if(click&&BattleEditor_PointInRect(mx,my,298,42,444,66)){initialization_page=2;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
    if(click&&BattleEditor_PointInRect(mx,my,448,42,624,66)){initialization_page=3;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}

    // Sticky second-level navigation is tested before translating the body
    // coordinate.  It therefore remains reliable at every scroll position.
    if(initialization_page==1&&click){
        if(BattleEditor_PointInRect(mx,my,20,72,136,98)){initialization_enemy_page=0;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
        if(BattleEditor_PointInRect(mx,my,140,72,256,98)){initialization_enemy_page=1;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
        if(BattleEditor_PointInRect(mx,my,260,72,376,98)){initialization_enemy_page=2;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
        if(BattleEditor_PointInRect(mx,my,380,72,496,98)){initialization_enemy_page=3;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
        if(BattleEditor_PointInRect(mx,my,500,72,624,98)){initialization_enemy_page=4;initialization_scroll=0;initialization_turn_dropdown=false;battle_music_dropdown_open=false;exit;}
    }

    var initialization_original_my=my;
    var initialization_current_key=string(initialization_page)+":"+string(initialization_enemy_page);
    if(initialization_current_key!=initialization_scroll_key){initialization_scroll_key=initialization_current_key;initialization_scroll=0;}
    // The item list is drawn inside the translated initialization canvas.
    // Hit-test it in content coordinates before the outer page consumes the
    // wheel; testing raw GUI Y only worked for the two pixels visible at the
    // list's unscrolled position and made both nested scroll areas move.
    var initialization_body_top=initialization_page==1?102:68;
    var initialization_body_offset=initialization_page==1?36:0;
    var initialization_content_my=my+initialization_scroll-initialization_body_offset;
    var over_item_list=initialization_page==0&&my>=initialization_body_top&&my<=450&&BattleEditor_PointInRect(mx,initialization_content_my,22,516,246,705);
    var over_enemy_list=initialization_page==1&&(initialization_enemy_page==1||initialization_enemy_page==2)&&my>=initialization_body_top&&my<=450&&BattleEditor_PointInRect(mx,initialization_content_my,22,100,190,404);
    if(my>=initialization_body_top&&my<=450&&!over_item_list&&!over_enemy_list){
        var initialization_scroll_max=initialization_page==0?420:320;
        if(mouse_wheel_up()) initialization_scroll=max(0,initialization_scroll-32);
        if(mouse_wheel_down()) initialization_scroll=min(initialization_scroll_max,initialization_scroll+32);
    }
    if(my>=initialization_body_top&&my<=450) my=initialization_content_my;
    else if(initialization_page==1&&my>=68&&my<initialization_body_top) my=-10000;

    if(initialization_page==1&&initialization_turn_dropdown){
        var initialization_known_turns=BattleEditor_GetKnownTurns(project);
        var initialization_turn_rows=min(10,array_length(initialization_known_turns));
        if(click&&BattleEditor_PointInRect(mx,my,148,100,330,100+initialization_turn_rows*22)){
            var initialization_turn_row=clamp(floor((my-100)/22),0,initialization_turn_rows-1);
            BattleEditor_SetAuthoringTurn(id,initialization_known_turns[initialization_turn_row]);
            initialization_turn_dropdown=false;
            exit;
        }
        if(click&&!BattleEditor_PointInRect(mx,my,148,74,330,100+initialization_turn_rows*22)){
            initialization_turn_dropdown=false;
            deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
            exit;
        }
    }

    if(initialization_page==1&&initialization_enemy_page==4&&battle_music_dropdown_open){
        var battle_music_step_options=BattleEditor_MusicOptions(project);
        var battle_music_step_total=array_length(battle_music_step_options)+1;
        battle_music_scroll=clamp(battle_music_scroll,0,max(0,battle_music_step_total-10));
        var battle_music_step_visible=min(10,battle_music_step_total-battle_music_scroll);
        if(BattleEditor_PointInRect(mx,my,22,134,508,134+battle_music_step_visible*24)&&(mouse_wheel_up()||mouse_wheel_down())){
            battle_music_scroll=clamp(battle_music_scroll+(mouse_wheel_down()?1:-1),0,max(0,battle_music_step_total-10));
            exit;
        }
        if(click&&BattleEditor_PointInRect(mx,my,22,134,508,134+battle_music_step_visible*24)){
            var battle_music_step_row=clamp(floor((my-134)/24),0,battle_music_step_visible-1);
            var battle_music_step_index=battle_music_scroll+battle_music_step_row;
            init.battle_music=battle_music_step_index==0?"":battle_music_step_options[battle_music_step_index-1];
            battle_music_dropdown_open=false;
            BattleEditor_AudioPreviewStop(id);
            status_text=init.battle_music==""?"战斗音乐已设为无":"战斗音乐已选择："+BattleEditor_SoundOptionCaption(init.battle_music,project);
            exit;
        }
        if(click&&!BattleEditor_PointInRect(mx,my,22,104,508,134+battle_music_step_visible*24)){
            battle_music_dropdown_open=false;
            deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
            exit;
        }
    }

    if(initialization_page==0){
        if(click&&BattleEditor_PointInRect(mx,my,120,102,624,126)){focus_field="player_name";keyboard_string=init.player_name;}
        else if(click&&BattleEditor_PointInRect(mx,my,22,156,202,180)){focus_field="player_lv";keyboard_string=string(init.lv);}
        else if(click&&BattleEditor_PointInRect(mx,my,212,156,392,180)){focus_field="player_atk";keyboard_string=string(init.atk);}
        else if(click&&BattleEditor_PointInRect(mx,my,402,156,624,180)){focus_field="player_def";keyboard_string=string(init.def);}
        else if(click&&BattleEditor_PointInRect(mx,my,22,210,202,234)){focus_field="player_hp";keyboard_string=string(init.hp);}
        else if(click&&BattleEditor_PointInRect(mx,my,212,210,392,234)){focus_field="player_max_hp";keyboard_string=string(init.max_hp);}
        else if(click&&BattleEditor_PointInRect(mx,my,402,210,624,234)){focus_field="player_natural_max_hp";keyboard_string=string(init.natural_max_hp);}
        else if(click&&BattleEditor_PointInRect(mx,my,22,264,202,288)){focus_field="player_shield";keyboard_string=string(init.shield);}
        else if(click&&BattleEditor_PointInRect(mx,my,212,264,392,288)){focus_field="player_shield_max";keyboard_string=string(init.shield_max);}
        else if(click&&BattleEditor_PointInRect(mx,my,402,264,624,288)){focus_field="player_shield_natural_max";keyboard_string=string(init.shield_natural_max);}
        else if(click&&BattleEditor_PointInRect(mx,my,22,328,318,352)){init.shield_enabled=!init.shield_enabled;BattleEditor_ApplyInitialization(project);}
        else if(click&&BattleEditor_PointInRect(mx,my,326,328,624,352)){choice_menu_open=true;choice_menu_context="shield_mode";choice_menu_kind="shield_mode";choice_menu_scroll=0;}
        else if(click&&BattleEditor_PointInRect(mx,my,22,358,318,382)){init.hud_show_hp_label=!init.hud_show_hp_label;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,326,358,624,382)){init.hud_show_bar=!init.hud_show_bar;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,22,388,318,412)){init.hud_show_kr=!init.hud_show_kr;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,326,388,624,412)){init.hud_show_numbers=!init.hud_show_numbers;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,22,418,318,442)){init.hud_show_shield=!init.hud_show_shield;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,326,418,624,442)){init.hud_show_overhead=!init.hud_show_overhead;BattleEditor_ApplyLayout(init);}
        else if(click&&BattleEditor_PointInRect(mx,my,90,484,166,508)){
            if(array_length(init.items)<ITEM_INVENTORY_CAPACITY){
                var player_new_item=BattleEditor_NewItem();player_new_item.uid=BattleEditor_AllocateUid(project);
                array_push(init.items,player_new_item);selected_item=array_length(init.items)-1;item_scroll=max(0,array_length(init.items)-7);BattleEditor_ApplyInitialization(project);
            }else status_text="物品栏已达到 114 个上限";
        }else if(click&&BattleEditor_PointInRect(mx,my,170,484,246,508)&&selected_item>=0){
            array_delete(init.items,selected_item,1);selected_item=min(selected_item,array_length(init.items)-1);BattleEditor_ApplyInitialization(project);
        }else if(mouse_wheel_up()&&BattleEditor_PointInRect(mx,my,22,516,246,705)) item_scroll=max(0,item_scroll-1);
        else if(mouse_wheel_down()&&BattleEditor_PointInRect(mx,my,22,516,246,705)) item_scroll=min(max(0,array_length(init.items)-7),item_scroll+1);
        else if(click){
            for(var player_item_row=0;player_item_row<7;player_item_row++){
                var player_item_index=item_scroll+player_item_row;
                if(player_item_index<array_length(init.items)&&BattleEditor_PointInRect(mx,my,22,516+player_item_row*27,246,540+player_item_row*27)) selected_item=player_item_index;
            }
            if(selected_item>=0&&selected_item<array_length(init.items)){
                var player_chosen_item=init.items[selected_item];
                if(BattleEditor_PointInRect(mx,my,360,516,624,540)){focus_field="item_name";keyboard_string=player_chosen_item.name;}
                else if(BattleEditor_PointInRect(mx,my,360,546,624,570)){focus_field="item_heal";keyboard_string=string(player_chosen_item.heal);}
                else if(BattleEditor_PointInRect(mx,my,360,576,590,600)){
                    choice_menu_open=true;choice_menu_context="item_voice";choice_menu_kind="voice";choice_menu_scroll=0;
                }else if(BattleEditor_PointInRect(mx,my,596,576,624,600)) BattleEditor_AudioPreviewToggleVoice(id,player_chosen_item.voice_id,"item_"+string(player_chosen_item.uid));
                else if(BattleEditor_PointInRect(mx,my,266,628,624,674)||BattleEditor_PointInRect(mx,my,516,678,624,702)){
                    text_editor_open=true;text_editor_target="item";text_editor_buffer=player_chosen_item.eat_text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;color_picker_open=false;keyboard_string="";
                }else if(BattleEditor_PointInRect(mx,my,384,714,624,740)){
                    choice_menu_open=true;choice_menu_context="item_after_use";choice_menu_kind="item_after_use";choice_menu_scroll=0;
                }
            }
        }
        if(click&&BattleEditor_PointInRect(mx,my,22,758,198,784)){
            var default_player_init=BattleEditor_NewProject().initialization;
            init.player_name=default_player_init.player_name;init.lv=default_player_init.lv;init.atk=default_player_init.atk;init.def=default_player_init.def;
            init.hp=default_player_init.hp;init.max_hp=default_player_init.max_hp;init.natural_max_hp=default_player_init.natural_max_hp;
            init.shield=default_player_init.shield;init.shield_max=default_player_init.shield_max;init.shield_natural_max=default_player_init.shield_natural_max;
            BattleEditor_ApplyInitialization(project);status_text="玩家数值已恢复默认";
        }else if(click&&BattleEditor_PointInRect(mx,my,204,758,404,784)){
            var default_hud_init=BattleEditor_NewProject().initialization;
            init.hud_x=default_hud_init.hud_x;init.hud_y=default_hud_init.hud_y;init.hud_show_hp_label=default_hud_init.hud_show_hp_label;init.hud_show_bar=default_hud_init.hud_show_bar;
            init.hud_show_kr=default_hud_init.hud_show_kr;init.hud_show_numbers=default_hud_init.hud_show_numbers;init.hud_show_shield=default_hud_init.hud_show_shield;init.hud_show_overhead=default_hud_init.hud_show_overhead;
            init.shield_enabled=default_hud_init.shield_enabled;init.shield_hud_mode=default_hud_init.shield_hud_mode;BattleEditor_ApplyLayout(init);status_text="HUD 已恢复默认";
        }else if(click&&BattleEditor_PointInRect(mx,my,410,758,624,784)){
            init.items=json_parse(json_stringify(BattleEditor_DefaultItems()));selected_item=-1;item_scroll=0;BattleEditor_ApplyInitialization(project);status_text="物品栏已恢复默认";
        }
    }else if(initialization_page==1){
        if(initialization_enemy_page==0){
        if(click&&BattleEditor_PointInRect(mx,my,148,74,330,98)){initialization_turn_dropdown=!initialization_turn_dropdown;exit;}
        else if(click&&BattleEditor_PointInRect(mx,my,336,74,432,98)){
            var add_turns=BattleEditor_GetKnownTurns(project);BattleEditor_SetAuthoringTurn(id,add_turns[array_length(add_turns)-1]+1);status_text="已新增第 "+string(developer_turn)+" 回合";
        }
        else if(click&&BattleEditor_PointInRect(mx,my,438,74,624,98)){
            editor_turn_data.text="* 第 "+string(developer_turn)+" 回合";editor_turn_data.dialogue="";editor_turn_data.turn_font=0;editor_turn_data.dialogue_font=2;editor_turn_data.turn_voice=1;editor_turn_data.dialogue_voice=2;editor_turn_data.dialogue_template=0;editor_turn_data.dialogue_offset_x=92;editor_turn_data.dialogue_offset_y=-34;status_text="本回合文本与气泡已恢复默认";
        }
        else if(click&&BattleEditor_PointInRect(mx,my,210,108,330,132)){text_editor_open=true;text_editor_target="turn";text_editor_buffer=editor_turn_data.text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;keyboard_string="";}
        else if(click&&BattleEditor_PointInRect(mx,my,336,108,456,132)){font_dropdown_open=true;font_dropdown_target="turn";font_dropdown_scroll=clamp(editor_turn_data.turn_font-4,0,max(0,TextTyper_FontCount()-10));}
        else if(click&&BattleEditor_PointInRect(mx,my,460,108,592,132)){choice_menu_open=true;choice_menu_context="turn_voice";choice_menu_kind="voice";choice_menu_scroll=0;}
        else if(click&&BattleEditor_PointInRect(mx,my,596,108,624,132)) BattleEditor_AudioPreviewToggleVoice(id,editor_turn_data.turn_voice,"turn_voice");
        else if(click&&BattleEditor_PointInRect(mx,my,210,142,330,166)){text_editor_open=true;text_editor_target="dialogue";text_editor_buffer=editor_turn_data.dialogue;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;keyboard_string="";}
        else if(click&&BattleEditor_PointInRect(mx,my,336,142,456,166)){font_dropdown_open=true;font_dropdown_target="dialogue";font_dropdown_scroll=clamp(editor_turn_data.dialogue_font-4,0,max(0,TextTyper_FontCount()-10));}
        else if(click&&BattleEditor_PointInRect(mx,my,460,142,592,166)){choice_menu_open=true;choice_menu_context="dialogue_voice";choice_menu_kind="voice";choice_menu_scroll=0;}
        else if(click&&BattleEditor_PointInRect(mx,my,596,142,624,166)) BattleEditor_AudioPreviewToggleVoice(id,editor_turn_data.dialogue_voice,"dialogue_voice");
        else if(click&&BattleEditor_PointInRect(mx,my,112,176,330,200)){choice_menu_open=true;choice_menu_context="dialogue_template";choice_menu_kind="dialogue_template";choice_menu_scroll=0;}
        else if(click&&BattleEditor_PointInRect(mx,my,464,176,540,200)){focus_field="dialogue_offset_x";keyboard_string=string(editor_turn_data.dialogue_offset_x);}
        else if(click&&BattleEditor_PointInRect(mx,my,546,176,624,200)){focus_field="dialogue_offset_y";keyboard_string=string(editor_turn_data.dialogue_offset_y);}
        }else if(initialization_enemy_page==1){
            var enemy_count=array_length(init.enemies);selected_enemy=clamp(selected_enemy,0,max(0,enemy_count-1));
            var enemy_visible_rows=8;
            enemy_list_scroll=clamp(enemy_list_scroll,0,max(0,enemy_count-enemy_visible_rows));
            if(mouse_wheel_up()&&BattleEditor_PointInRect(mx,my,22,134,190,374)){enemy_list_scroll=max(0,enemy_list_scroll-1);exit;}
            if(mouse_wheel_down()&&BattleEditor_PointInRect(mx,my,22,134,190,374)){enemy_list_scroll=min(max(0,enemy_count-enemy_visible_rows),enemy_list_scroll+1);exit;}
            if(click&&BattleEditor_PointInRect(mx,my,86,72,136,96)){
                if(enemy_count<BATTLE_EDITOR_ENEMY_LIMIT){
                    var new_enemy_position=enemy_count>0?BattleEditor_DuplicateEnemyPosition(project,init.enemies[selected_enemy]):[320,166];
                    array_push(init.enemies,BattleEditor_NewEnemy(project,new_enemy_position[0],new_enemy_position[1],false));selected_enemy=array_length(init.enemies)-1;enemy_list_scroll=max(0,array_length(init.enemies)-enemy_visible_rows);status_text="已新增敌人";BattleEditor_ApplyInitialization(project);
                }else status_text="敌人已达到 15 个上限";
            }else if(click&&BattleEditor_PointInRect(mx,my,140,72,190,96)&&enemy_count>0){
                var duplicated_enemy=BattleEditor_DuplicateEnemy(project,selected_enemy);
                if(!is_undefined(duplicated_enemy)){
                    selected_enemy=array_length(init.enemies)-1;enemy_list_scroll=max(0,array_length(init.enemies)-enemy_visible_rows);selected_enemy_action=0;
                    BattleEditor_ApplyInitialization(project);status_text="已复制敌人："+duplicated_enemy.name;
                }else status_text="敌人已达到 15 个上限";
            }else if(click&&BattleEditor_PointInRect(mx,my,22,104,82,128)&&enemy_count>1){
                array_delete(init.enemies,selected_enemy,1);selected_enemy=clamp(selected_enemy,0,array_length(init.enemies)-1);BattleEditor_ApplyInitialization(project);
            }else if(click&&BattleEditor_PointInRect(mx,my,86,104,190,128)&&enemy_count>0){
                var reset_enemy=BattleEditor_ResetEnemyToDefault(project,selected_enemy);
                if(!is_undefined(reset_enemy)){BattleEditor_ApplyInitialization(project);status_text="当前敌人已恢复默认";}
            }else if(click){
                for(var enemy_row=0;enemy_row<enemy_visible_rows;enemy_row++){
                    var enemy_index=enemy_list_scroll+enemy_row;
                    if(enemy_index<array_length(init.enemies)&&BattleEditor_PointInRect(mx,my,22,134+enemy_row*30,190,160+enemy_row*30)) selected_enemy=enemy_index;
                }
                if(array_length(init.enemies)>0){
                    var enemy_data=init.enemies[selected_enemy];var enemy_part_keys=BattleEditor_EnemyPartKeys();var enemy_part_key=enemy_part_keys[selected_enemy_part];var enemy_part=variable_struct_get(enemy_data.parts,enemy_part_key);
                    if(BattleEditor_PointInRect(mx,my,330,72,472,96)){focus_field="enemy_name";keyboard_string=enemy_data.name;}
                    else if(BattleEditor_PointInRect(mx,my,478,72,624,96)){focus_field="enemy_control_id";keyboard_string=enemy_data.control_id;}
                    else if(BattleEditor_PointInRect(mx,my,340,104,474,128)){focus_field="enemy_x";keyboard_string=string(enemy_data.x);}
                    else if(BattleEditor_PointInRect(mx,my,480,104,624,128)){focus_field="enemy_y";keyboard_string=string(enemy_data.y);}
                    else if(BattleEditor_PointInRect(mx,my,340,136,474,160)){focus_field="enemy_scale_x";keyboard_string=string(enemy_data.scale_x);}
                    else if(BattleEditor_PointInRect(mx,my,480,136,624,160)){focus_field="enemy_scale_y";keyboard_string=string(enemy_data.scale_y);}
                    else if(BattleEditor_PointInRect(mx,my,340,168,624,192)){focus_field="enemy_sway_x";keyboard_string=enemy_data.sway_x;}
                    else if(BattleEditor_PointInRect(mx,my,340,200,624,224)){focus_field="enemy_torso_y";keyboard_string=enemy_data.torso_y;}
                    else if(BattleEditor_PointInRect(mx,my,340,232,624,256)){focus_field="enemy_head_y";keyboard_string=enemy_data.head_y;}
                    else if(BattleEditor_PointInRect(mx,my,340,264,474,288)){choice_menu_open=true;choice_menu_context="enemy_part";choice_menu_kind="enemy_part";choice_menu_scroll=0;}
                    else if(BattleEditor_PointInRect(mx,my,480,264,624,288)){
                        enemy_editor_open=true;enemy_editor_selected_part=selected_enemy_part;enemy_editor_preview_time=0;enemy_editor_preview_playing=false;
                        enemy_editor_pan_x=207;enemy_editor_pan_y=250;enemy_editor_zoom=1;enemy_editor_panning=false;
                        enemy_editor_part_menu_open=false;enemy_editor_resource_menu_open=false;enemy_editor_cache_dirty=true;
                        status_text="敌人可视化编辑：拖动画布部件，或在右侧精确输入";exit;
                    }
                    else if(BattleEditor_PointInRect(mx,my,340,328,474,352)){focus_field="enemy_part_x";keyboard_string=string(enemy_part.offset_x);}
                    else if(BattleEditor_PointInRect(mx,my,480,328,624,352)){focus_field="enemy_part_y";keyboard_string=string(enemy_part.offset_y);}
                    else if(BattleEditor_PointInRect(mx,my,382,360,500,384)){focus_field="enemy_gravity_up";keyboard_string=enemy_data.animation_scripts.gravity_up;}
                    else if(BattleEditor_PointInRect(mx,my,506,360,624,384)){focus_field="enemy_gravity_down";keyboard_string=enemy_data.animation_scripts.gravity_down;}
                    else if(BattleEditor_PointInRect(mx,my,382,392,500,416)){focus_field="enemy_gravity_left";keyboard_string=enemy_data.animation_scripts.gravity_left;}
                    else if(BattleEditor_PointInRect(mx,my,506,392,624,416)){focus_field="enemy_gravity_right";keyboard_string=enemy_data.animation_scripts.gravity_right;}
                }
            }
        }else if(initialization_enemy_page==2){
            var enemy_count=array_length(init.enemies);selected_enemy=clamp(selected_enemy,0,max(0,enemy_count-1));
            var action_enemy_visible_rows=9;
            enemy_list_scroll=clamp(enemy_list_scroll,0,max(0,enemy_count-action_enemy_visible_rows));
            if(mouse_wheel_up()&&BattleEditor_PointInRect(mx,my,22,104,190,374)){enemy_list_scroll=max(0,enemy_list_scroll-1);exit;}
            if(mouse_wheel_down()&&BattleEditor_PointInRect(mx,my,22,104,190,374)){enemy_list_scroll=min(max(0,enemy_count-action_enemy_visible_rows),enemy_list_scroll+1);exit;}
            if(click){
                for(var action_enemy_row=0;action_enemy_row<action_enemy_visible_rows;action_enemy_row++){
                    var action_enemy_index=enemy_list_scroll+action_enemy_row;
                    if(action_enemy_index<enemy_count&&BattleEditor_PointInRect(mx,my,22,104+action_enemy_row*30,190,130+action_enemy_row*30)){selected_enemy=action_enemy_index;selected_enemy_action=0;}
                }
                if(enemy_count>0){
                    var action_enemy=init.enemies[selected_enemy];
                    selected_enemy_action=clamp(selected_enemy_action,0,max(0,array_length(action_enemy.actions)-1));
                    if(BattleEditor_PointInRect(mx,my,330,72,408,96)){
                        if(array_length(action_enemy.actions)<6){array_push(action_enemy.actions,BattleEditor_NewEnemyAction(project,"行动 "+string(array_length(action_enemy.actions)+1),""));selected_enemy_action=array_length(action_enemy.actions)-1;BattleEditor_ApplyInitialization(project);status_text="已新增行动项目";}
                        else status_text="UTE 行动菜单每个敌人最多 6 项";
                    }else if(BattleEditor_PointInRect(mx,my,414,72,492,96)&&array_length(action_enemy.actions)>0){
                        var removed_action_uid=action_enemy.actions[selected_enemy_action].uid;
                        array_delete(action_enemy.actions,selected_enemy_action,1);selected_enemy_action=clamp(selected_enemy_action,0,max(0,array_length(action_enemy.actions)-1));
                        // Keep the Workspace list visible but make the missing
                        // trigger explicit instead of silently rebinding it.
                        BattleEditor_ApplyInitialization(project);status_text="已删除行动项目；引用 UID "+string(removed_action_uid)+" 的列表会显示未选择";
                    }else{
                        for(var enemy_action_row=0;enemy_action_row<min(6,array_length(action_enemy.actions));enemy_action_row++) if(BattleEditor_PointInRect(mx,my,208,104+enemy_action_row*30,624,130+enemy_action_row*30)) selected_enemy_action=enemy_action_row;
                        if(array_length(action_enemy.actions)>0){
                            var selected_action=action_enemy.actions[selected_enemy_action];
                            if(BattleEditor_PointInRect(mx,my,310,286,624,310)){focus_field="enemy_action_name";keyboard_string=selected_action.name;}
                            else if(BattleEditor_PointInRect(mx,my,506,394,624,418)){text_editor_open=true;text_editor_target="enemy_action_text";text_editor_buffer=selected_action.text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;keyboard_string="";}
                        }
                    }
                }
            }
        }else if(initialization_enemy_page==3){
            var gb_styles=project.resources.gb_styles;
            selected_gb_style=clamp(selected_gb_style,-1,max(-1,array_length(gb_styles)-1));
            if(click&&BattleEditor_PointInRect(mx,my,22,466,298,490)){gb_spawn_dropdown_open=true;gb_spawn_dropdown_event=-1;gb_spawn_dropdown_scroll=clamp(init.gb_spawn_default.preset-5,0,8);}
            else if(init.gb_spawn_default.preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM&&click&&BattleEditor_PointInRect(mx,my,310,466,412,490)){focus_field="global_gb_x";keyboard_string=string(init.gb_spawn_default.x);}
            else if(init.gb_spawn_default.preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM&&click&&BattleEditor_PointInRect(mx,my,420,466,522,490)){focus_field="global_gb_y";keyboard_string=string(init.gb_spawn_default.y);}
            else if(click&&BattleEditor_PointInRect(mx,my,530,466,624,490)){focus_field="global_gb_angle";keyboard_string=string(init.gb_spawn_default.angle);}
            else if(click&&BattleEditor_PointInRect(mx,my,448,540,624,566)){init.gb_spawn_default=json_parse(json_stringify(BattleEditor_NewProject().initialization.gb_spawn_default));status_text="GB 默认出生位置已恢复";}
            else if(click&&BattleEditor_PointInRect(mx,my,112,72,164,96)){
                var new_gb_style=BattleEditor_NewGBStyle(project,BattleEditor_UniqueGBStyleName(project,"自定义 GB"));
                array_push(gb_styles,new_gb_style);selected_gb_style=array_length(gb_styles)-1;selected_gb_style_frame=0;
                selected_gb_beam_variant=0;selected_gb_beam_frame=0;gb_style_editor_page=0;gb_style_preview_playing=false;gb_style_preview_time=0;
                status_text="已新建 GB 贴图组：6 帧细节本体与 3 组光束素材";
            }else if(click&&BattleEditor_PointInRect(mx,my,168,72,220,96)&&selected_gb_style>=0){
                var removed_gb_uid=gb_styles[selected_gb_style].uid;
                BattleEditor_RemoveGBStyleReferences(project,removed_gb_uid);
                array_delete(gb_styles,selected_gb_style,1);selected_gb_style=clamp(selected_gb_style,-1,array_length(gb_styles)-1);selected_gb_style_frame=0;
                selected_gb_beam_variant=0;selected_gb_beam_frame=0;gb_style_preview_playing=false;gb_style_preview_time=0;
                status_text="已删除 GB 贴图组；原引用已回退到原版 GB";
            }else if(click&&BattleEditor_PointInRect(mx,my,22,104,220,130)){
                selected_gb_style=-1;selected_gb_style_frame=0;selected_gb_beam_variant=0;selected_gb_beam_frame=0;gb_style_preview_playing=false;gb_style_preview_time=0;
            }else if(click){
                for(var gb_style_row=0;gb_style_row<min(8,array_length(gb_styles));gb_style_row++) if(BattleEditor_PointInRect(mx,my,22,134+gb_style_row*30,220,160+gb_style_row*30)){selected_gb_style=gb_style_row;selected_gb_style_frame=0;selected_gb_beam_variant=0;selected_gb_beam_frame=0;gb_style_preview_playing=false;gb_style_preview_time=0;exit;}
                if(BattleEditor_PointInRect(mx,my,238,106,360,132)){gb_style_editor_page=0;gb_style_preview_playing=false;gb_style_preview_time=0;}
                else if(BattleEditor_PointInRect(mx,my,370,106,492,132)){gb_style_editor_page=1;gb_style_preview_playing=false;gb_style_preview_time=0;}
                else if(BattleEditor_PointInRect(mx,my,502,106,624,132)){gb_style_editor_page=2;gb_style_preview_playing=false;gb_style_preview_time=0;}
                else if(gb_style_editor_page==2&&BattleEditor_PointInRect(mx,my,238,144,624,172)){gb_style_preview_playing=true;gb_style_preview_time=0;status_text="GB 发射预览：飞入、开口、光束、收束";}
                else if(selected_gb_style<0&&gb_style_editor_page==0){
                    var builtin_gb_frame_count=array_length(BattleEditor_BuiltinGBStyle().animation.frames);
                    if(BattleEditor_PointInRect(mx,my,238,196,428,220)) selected_gb_style_frame=(selected_gb_style_frame-1+builtin_gb_frame_count) mod builtin_gb_frame_count;
                    else if(BattleEditor_PointInRect(mx,my,434,196,624,220)) selected_gb_style_frame=(selected_gb_style_frame+1) mod builtin_gb_frame_count;
                }else if(selected_gb_style>=0&&selected_gb_style<array_length(gb_styles)){
                    var gb_style=gb_styles[selected_gb_style];
                    if(BattleEditor_PointInRect(mx,my,300,72,624,96)){focus_field="gb_style_name";keyboard_string=gb_style.name;}
                    else if(gb_style_editor_page==0){
                        var gb_frames=gb_style.animation.frames;var gb_frame_count=array_length(gb_frames);
                        selected_gb_style_frame=clamp(selected_gb_style_frame,0,max(0,gb_frame_count-1));
                        if(BattleEditor_PointInRect(mx,my,238,164,540,188)){focus_field="gb_style_frame";keyboard_string=gb_frames[selected_gb_style_frame];}
                        else if(BattleEditor_PointInRect(mx,my,546,164,624,188)){
                            var gb_replace_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","替换当前 GB 本体帧");
                            if(gb_replace_path!="") gb_frames[selected_gb_style_frame]=BattleEditor_StageResource(gb_replace_path);
                        }else if(BattleEditor_PointInRect(mx,my,238,196,330,220)) selected_gb_style_frame=(selected_gb_style_frame-1+gb_frame_count) mod gb_frame_count;
                        else if(BattleEditor_PointInRect(mx,my,336,196,428,220)) selected_gb_style_frame=(selected_gb_style_frame+1) mod gb_frame_count;
                        else if(BattleEditor_PointInRect(mx,my,434,196,526,220)){
                            var gb_add_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","添加 GB 本体动画帧");
                            if(gb_add_path!=""){array_insert(gb_frames,selected_gb_style_frame+1,BattleEditor_StageResource(gb_add_path));selected_gb_style_frame+=1;}
                        }else if(BattleEditor_PointInRect(mx,my,532,196,624,220)&&gb_frame_count>1){array_delete(gb_frames,selected_gb_style_frame,1);selected_gb_style_frame=clamp(selected_gb_style_frame,0,array_length(gb_frames)-1);}
                        else if(BattleEditor_PointInRect(mx,my,238,228,428,252)&&selected_gb_style_frame>0){var gb_swap_before=gb_frames[selected_gb_style_frame-1];gb_frames[selected_gb_style_frame-1]=gb_frames[selected_gb_style_frame];gb_frames[selected_gb_style_frame]=gb_swap_before;selected_gb_style_frame-=1;}
                        else if(BattleEditor_PointInRect(mx,my,434,228,624,252)&&selected_gb_style_frame<gb_frame_count-1){var gb_swap_after=gb_frames[selected_gb_style_frame+1];gb_frames[selected_gb_style_frame+1]=gb_frames[selected_gb_style_frame];gb_frames[selected_gb_style_frame]=gb_swap_after;selected_gb_style_frame+=1;}
                        else if(BattleEditor_PointInRect(mx,my,338,260,420,284)){focus_field="gb_style_interval";keyboard_string=string(gb_style.animation.frame_interval);}
                        else if(BattleEditor_PointInRect(mx,my,520,260,568,284)){focus_field="gb_style_origin_x";keyboard_string=string(gb_style.origin_x);}
                        else if(BattleEditor_PointInRect(mx,my,574,260,624,284)){focus_field="gb_style_origin_y";keyboard_string=string(gb_style.origin_y);}
                        else for(var head_direction_button=0;head_direction_button<4;head_direction_button++) if(BattleEditor_PointInRect(mx,my,338+head_direction_button*72,292,404+head_direction_button*72,316)){var head_directions=[0,270,180,90];gb_style.source_direction=head_directions[head_direction_button];break;}
                    }else if(gb_style_editor_page==1){
                        for(var gb_variant_button=0;gb_variant_button<3;gb_variant_button++) if(BattleEditor_PointInRect(mx,my,238+gb_variant_button*130,144,358+gb_variant_button*130,168)){selected_gb_beam_variant=gb_variant_button;selected_gb_beam_frame=0;exit;}
                        var gb_beam_animation=gb_style.beam.variants[selected_gb_beam_variant].animation;var gb_beam_frames=gb_beam_animation.frames;var gb_beam_frame_count=array_length(gb_beam_frames);
                        selected_gb_beam_frame=clamp(selected_gb_beam_frame,0,max(0,gb_beam_frame_count-1));
                        if(BattleEditor_PointInRect(mx,my,238,200,540,224)){focus_field="gb_style_beam_frame";keyboard_string=gb_beam_frames[selected_gb_beam_frame];}
                        else if(BattleEditor_PointInRect(mx,my,546,200,624,224)){
                            var beam_replace_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","替换当前 GB 光束帧");
                            if(beam_replace_path!="") gb_beam_frames[selected_gb_beam_frame]=BattleEditor_StageResource(beam_replace_path);
                        }else if(BattleEditor_PointInRect(mx,my,238,232,330,256)) selected_gb_beam_frame=(selected_gb_beam_frame-1+gb_beam_frame_count) mod gb_beam_frame_count;
                        else if(BattleEditor_PointInRect(mx,my,336,232,428,256)) selected_gb_beam_frame=(selected_gb_beam_frame+1) mod gb_beam_frame_count;
                        else if(BattleEditor_PointInRect(mx,my,434,232,526,256)){
                            var beam_add_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","添加 GB 光束动画帧");
                            if(beam_add_path!=""){array_insert(gb_beam_frames,selected_gb_beam_frame+1,BattleEditor_StageResource(beam_add_path));selected_gb_beam_frame+=1;}
                        }else if(BattleEditor_PointInRect(mx,my,532,232,624,256)&&gb_beam_frame_count>1){array_delete(gb_beam_frames,selected_gb_beam_frame,1);selected_gb_beam_frame=clamp(selected_gb_beam_frame,0,array_length(gb_beam_frames)-1);}
                        else if(BattleEditor_PointInRect(mx,my,318,264,390,288)){focus_field="gb_style_beam_interval";keyboard_string=string(gb_beam_animation.frame_interval);}
                        else if(BattleEditor_PointInRect(mx,my,520,264,624,288)){focus_field="gb_style_beam_offset";keyboard_string=string(gb_style.beam.source_offset);}
                        else if(BattleEditor_PointInRect(mx,my,424,328,520,352)){focus_field="gb_style_beam_scale";keyboard_string=string(gb_style.beam.base_scale);}
                        else if(BattleEditor_PointInRect(mx,my,526,328,624,352)){focus_field="gb_style_beam_launch";keyboard_string=string(gb_style.beam.launch_ratio);}
                        else if(BattleEditor_PointInRect(mx,my,424,360,520,384)){focus_field="gb_style_beam_breath";keyboard_string=string(gb_style.beam.breath_ratio);}
                        else if(BattleEditor_PointInRect(mx,my,526,360,624,384)){focus_field="gb_style_beam_hit_inset";keyboard_string=string(gb_style.beam.hit_inset);}
                        else for(var beam_direction_button=0;beam_direction_button<4;beam_direction_button++) if(BattleEditor_PointInRect(mx,my,338+beam_direction_button*72,296,404+beam_direction_button*72,320)){var beam_directions=[0,270,180,90];gb_style.beam.source_direction=beam_directions[beam_direction_button];break;}
                    }
                }
            }
        }else{
            if(click&&BattleEditor_PointInRect(mx,my,22,104,508,132)){
                battle_music_dropdown_open=!battle_music_dropdown_open;
                if(battle_music_dropdown_open){
                    var battle_music_current_options=BattleEditor_MusicOptions(project);
                    battle_music_scroll=0;
                    for(var battle_music_current_index=0;battle_music_current_index<array_length(battle_music_current_options);battle_music_current_index++) if(string_lower(battle_music_current_options[battle_music_current_index])==string_lower(init.battle_music)){battle_music_scroll=max(0,battle_music_current_index+1-4);break;}
                }
                exit;
            }else if(click&&BattleEditor_PointInRect(mx,my,516,104,544,132)){
                BattleEditor_AudioPreviewToggleNamed(id,init.battle_music,"battle_music");
            }else if(click&&BattleEditor_PointInRect(mx,my,550,104,624,132)){
                var battle_music_import_path=get_open_filename("音频文件|*.wav;*.ogg;*.mp3;*.flac;*.wma;*.aac;*.m4a","导入战斗音乐");
                if(battle_music_import_path!=""){
                    var battle_music_staged_path=BattleEditor_RegisterImportedAudio(project,battle_music_import_path);
                    if(battle_music_staged_path!=""){init.battle_music=battle_music_staged_path;status_text="已导入并选择战斗音乐："+filename_name(battle_music_import_path);}
                    else status_text="战斗音乐导入失败";
                }
            }else if(click&&BattleEditor_PointInRect(mx,my,22,188,318,216)){
                init.battle_music_frame_sync=false;status_text="战斗音乐：正常播放";
            }else if(click&&BattleEditor_PointInRect(mx,my,326,188,624,216)){
                init.battle_music_frame_sync=true;status_text="战斗音乐：低 FPS 时跟随逻辑帧校正";
            }
        }
    }else if(initialization_page==2){
        var player_board_settings=init.player_board;var monster_board_settings=init.board;
        if(click&&BattleEditor_PointInRect(mx,my,188,102,314,126)){focus_field="layout_hud_x";keyboard_string=string(init.hud_x);}
        else if(click&&BattleEditor_PointInRect(mx,my,322,102,448,126)){focus_field="layout_hud_y";keyboard_string=string(init.hud_y);}
        else if(click&&BattleEditor_PointInRect(mx,my,188,134,314,158)){focus_field="layout_enemy_x";keyboard_string=string(init.enemy_x);}
        else if(click&&BattleEditor_PointInRect(mx,my,322,134,448,158)){focus_field="layout_enemy_y";keyboard_string=string(init.enemy_y);}
        else if(click&&BattleEditor_PointInRect(mx,my,188,166,314,190)){focus_field="layout_turn_text_x";keyboard_string=string(init.turn_text_x);}
        else if(click&&BattleEditor_PointInRect(mx,my,322,166,448,190)){focus_field="layout_turn_text_y";keyboard_string=string(init.turn_text_y);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,242,236,266)){focus_field="player_board_x";keyboard_string=string(player_board_settings.x);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,242,346,266)){focus_field="player_board_y";keyboard_string=string(player_board_settings.y);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,272,236,296)){focus_field="player_board_up";keyboard_string=string(player_board_settings.up);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,272,346,296)){focus_field="player_board_down";keyboard_string=string(player_board_settings.down);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,302,236,326)){focus_field="player_board_left";keyboard_string=string(player_board_settings.left);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,302,346,326)){focus_field="player_board_right";keyboard_string=string(player_board_settings.right);}
        else if(click&&BattleEditor_PointInRect(mx,my,420,302,524,326)){focus_field="player_board_angle";keyboard_string=string(player_board_settings.angle);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,380,236,404)){focus_field="init_board_x";keyboard_string=string(monster_board_settings.x);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,380,346,404)){focus_field="init_board_y";keyboard_string=string(monster_board_settings.y);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,410,236,434)){focus_field="init_board_up";keyboard_string=string(monster_board_settings.up);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,410,346,434)){focus_field="init_board_down";keyboard_string=string(monster_board_settings.down);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,440,236,464)){focus_field="init_board_left";keyboard_string=string(monster_board_settings.left);}
        else if(click&&BattleEditor_PointInRect(mx,my,242,440,346,464)){focus_field="init_board_right";keyboard_string=string(monster_board_settings.right);}
        else if(click&&BattleEditor_PointInRect(mx,my,420,440,524,464)){focus_field="init_board_angle";keyboard_string=string(monster_board_settings.angle);}
        else if(click&&BattleEditor_PointInRect(mx,my,132,518,386,542)) BattleEditor_OpenColorPicker(id,"global_board",init.board_color_default,1);
        else if(click&&BattleEditor_PointInRect(mx,my,398,518,624,542)){
            init.board.color_frame=init.board_color_default;main_board_preview.color_frame=init.board_color_default;for(var global_frame_index=0;global_frame_index<array_length(init.frames);global_frame_index++) init.frames[global_frame_index].color_frame=init.board_color_default;BattleEditor_SyncBoardPreview(id,true);
        }
        else if(click&&BattleEditor_PointInRect(mx,my,22,566,318,594)){
            main_board_preview=init.board;
            if(instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.MENU){board_edit_session=false;BattleEditor_RestoreAuthoringBoard(id);}
            else{board_edit_session=true;BattleEditor_SyncBoardPreview(id,true);}
            status_text="已强制恢复初始化";
        }
        else if(click&&BattleEditor_PointInRect(mx,my,326,566,624,594)){
            var default_board_init=BattleEditor_NewProject().initialization;
            init.hud_x=default_board_init.hud_x;init.hud_y=default_board_init.hud_y;init.enemy_x=default_board_init.enemy_x;init.enemy_y=default_board_init.enemy_y;init.turn_text_x=default_board_init.turn_text_x;init.turn_text_y=default_board_init.turn_text_y;
            init.player_board=json_parse(json_stringify(default_board_init.player_board));init.board=json_parse(json_stringify(default_board_init.board));init.board_color_default=default_board_init.board_color_default;
            main_board_preview=init.board;board_edit_session=true;BattleEditor_ApplyLayout(init);BattleEditor_SyncBoardPreview(id,true);status_text="画面锚点与战斗框已恢复默认";
        }
    }else{
        if(click&&BattleEditor_PointInRect(mx,my,474,104,624,130)){initialization_page=1;initialization_enemy_page=1;initialization_scroll=0;status_text="FIGHT 目标来自前三个可攻击敌人";exit;}
        else if(click&&BattleEditor_PointInRect(mx,my,474,136,624,162)){initialization_page=1;initialization_enemy_page=2;initialization_scroll=0;status_text="在这里编辑每个敌人的 ACT 行动项目";exit;}
        else if(click&&BattleEditor_PointInRect(mx,my,474,168,624,194)){initialization_page=0;initialization_scroll=320;status_text="ITEM 选项来自物品栏";exit;}
        else if(click&&BattleEditor_PointInRect(mx,my,166,246,624,272)){focus_field="mercy_spare_label";keyboard_string=init.mercy_spare_label;}
        else if(click&&(BattleEditor_PointInRect(mx,my,22,306,624,352)||BattleEditor_PointInRect(mx,my,506,356,624,382))){text_editor_open=true;text_editor_target="mercy_spare_response";text_editor_buffer=init.mercy_spare_response;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;color_picker_open=false;keyboard_string="";}
        else if(click&&BattleEditor_PointInRect(mx,my,22,398,624,426)){init.mercy_flee_enabled=!init.mercy_flee_enabled;BattleEditor_ApplyInitialization(project);status_text=init.mercy_flee_enabled?"逃跑选项已显示":"逃跑选项已隐藏";}
        else if(click&&BattleEditor_PointInRect(mx,my,166,452,624,478)){focus_field="mercy_flee_label";keyboard_string=init.mercy_flee_label;}
        else if(click&&(BattleEditor_PointInRect(mx,my,22,512,624,558)||BattleEditor_PointInRect(mx,my,506,562,624,588))){text_editor_open=true;text_editor_target="mercy_flee_success";text_editor_buffer=init.mercy_flee_success_text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;color_picker_open=false;keyboard_string="";}
        else if(click&&(BattleEditor_PointInRect(mx,my,22,640,624,686)||BattleEditor_PointInRect(mx,my,506,690,624,716))){text_editor_open=true;text_editor_target="mercy_flee_fail";text_editor_buffer=init.mercy_flee_fail_text;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;color_picker_open=false;keyboard_string="";}
        else if(click&&BattleEditor_PointInRect(mx,my,22,730,624,758)){
            var mercy_defaults=BattleEditor_NewProject().initialization;
            init.mercy_spare_label=mercy_defaults.mercy_spare_label;init.mercy_spare_response=mercy_defaults.mercy_spare_response;
            init.mercy_flee_enabled=mercy_defaults.mercy_flee_enabled;init.mercy_flee_label=mercy_defaults.mercy_flee_label;
            init.mercy_flee_success_text=mercy_defaults.mercy_flee_success_text;init.mercy_flee_fail_text=mercy_defaults.mercy_flee_fail_text;
            BattleEditor_ApplyInitialization(project);status_text="仁慈菜单已恢复默认";
        }
    }
    my=initialization_original_my;
}else if(tab==2){
    if(!workspace_open) exit;
    var workspace_left_down=mouse_check_button(mb_left);
    var workspace_left_released=mouse_check_button_released(mb_left);
    var workspace_world_x=(mx-script_pan_x)/script_zoom;
    var workspace_world_y=(my-script_pan_y)/script_zoom;

    // Active drags own pointer input, including while crossing the Inspector.
    // No persistent coordinates, arrays or journal entries change in preview.
    if(!is_undefined(script_stack_drag)){
        var drag=script_stack_drag;
        if(keyboard_check_pressed(vk_escape)||right_click){script_stack_drag=undefined;script_drag_mode="";status_text="已取消拖动";exit;}
        if(point_distance(mx,my,drag.press_x,drag.press_y)>=4) drag.active=true;
        drag.x=workspace_world_x-drag.offset_x;drag.y=workspace_world_y-drag.offset_y;
        drag.snap=BattleEditor_WorkspaceSnap(project,drag,drag.x,drag.y,script_zoom);
        if(workspace_left_released){
            var drop_on_palette=script_palette_open&&BattleEditor_PointInRect(mx,my,8,36,176,448);
            var drop_on_inspector=script_selected_list>=0&&BattleEditor_PointInRect(mx,my,420,36,640,450);
            if(drag.active&&my>=32&&my<452&&!drop_on_palette&&!drop_on_inspector){
                var committed_uid=BattleEditor_WorkspaceCommitDrop(project,drag,drag.x,drag.y,developer_turn);
                if(committed_uid>=0){
                    script_selected_list=-1;script_selected_step=-1;script_inspector_pending_list=-1;script_inspector_pending_step=-1;
                    for(var selected_i=0;selected_i<array_length(project.script_lists);selected_i++) if(project.script_lists[selected_i].uid==committed_uid){script_selected_list=selected_i;break;}
                    if(script_selected_list>=0&&drag.mode!="head"&&drag.mode!="list") script_selected_step=drag.snap.list_uid<0?0:drag.snap.index;
                    // An earlier click may still be retracting the old card.
                    // Commit its new target too, so that seam cannot restore stale indices.
                    script_inspector_pending_list=script_selected_list;
                    script_inspector_pending_step=script_selected_step;
                    BattleEditor_WorkspaceChanged(id);
                    status_text=BattleEditor_WorkspaceHasHeader(project.script_lists[script_selected_list])?"积木已拼接 / 移动":"已保留游离积木；接上事件头后才执行";
                }
            }
            script_stack_drag=undefined;script_drag_mode="";
        }
        exit;
    }
    if(BattleEditor_WorkspaceNewPaletteInput(id,mx,my,click,mouse_wheel_down()-mouse_wheel_up())){
        if(workspace_left_released){script_link_drag=false;script_drag_mode="";}
        exit;
    }

    var script_parameter_step=script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
    var next_script_parameter_key=is_undefined(script_parameter_step)?"":string(script_parameter_step.uid)+":"+script_parameter_step.kind+":"+(struct_exists(script_parameter_step,"property")?script_parameter_step.property:"")+":"+(struct_exists(script_parameter_step,"action_name")?script_parameter_step.action_name:"")+":"+(struct_exists(script_parameter_step,"screen_action")?script_parameter_step.screen_action:"");
    if(next_script_parameter_key!=script_parameter_key){script_parameter_key=next_script_parameter_key;script_parameter_scroll=0;script_create_scroll=0;script_formula_target="";script_value_property_scroll=0;script_step_sound_open=false;script_step_warning_open=false;}
    if(!is_undefined(script_parameter_step)&&(script_parameter_step.kind=="builtin_action"||script_parameter_step.kind=="screen_control")&&script_dropdown==""&&!keyboard_check(vk_control)&&mx>=420&&mx<=638&&my>=264&&my<=432&&(mouse_wheel_up()||mouse_wheel_down())){
        var parameter_total_rows=0;
        var parameter_visible_rows=4;
        if(script_parameter_step.kind=="builtin_action"){
            if(script_parameter_step.action_name=="bone_orbit"){parameter_total_rows=11;parameter_visible_rows=6;}
            else if(script_parameter_step.action_name=="bone_wall"){parameter_total_rows=19;parameter_visible_rows=6;}
            else if(script_parameter_step.action_name=="bone_function_path") parameter_total_rows=(round(real(script_parameter_step.action_path_mode))==1?2:3)+array_length(BattleEditor_ActionParameterLabels("builtin",script_parameter_step.action_name));
            else parameter_total_rows=1+(BattleEditor_BuiltinActionUsesTemplate(script_parameter_step.action_name)?1:0)+array_length(BattleEditor_ActionParameterLabels("builtin",script_parameter_step.action_name));
        }else{
            parameter_total_rows=array_length(BattleEditor_ActionParameterLabels("screen",script_parameter_step.screen_action))+(script_parameter_step.screen_action=="camera_set"?2:0);
        }
        script_parameter_scroll=clamp(script_parameter_scroll+(mouse_wheel_down()?1:-1),0,max(0,parameter_total_rows-parameter_visible_rows));
    }
    if(!is_undefined(script_parameter_step)&&script_parameter_step.kind=="create_object"&&script_parameter_step.create_preset!="board_add"&&script_parameter_step.create_preset!="board_subtract"&&script_dropdown==""&&!keyboard_check(vk_control)&&BattleEditor_PointInRect(mx,my,420,284,638,450)&&(mouse_wheel_up()||mouse_wheel_down())){
        var create_scroll_fields=BattleEditor_WorkspaceCreateFields(script_parameter_step.create_preset);
        var create_scroll_max=max(0,BattleEditor_WorkspaceCreateFieldsHeight(create_scroll_fields)-164);
        script_create_scroll=clamp(script_create_scroll+(mouse_wheel_down()?42:-42),0,create_scroll_max);
    }

    if(script_dropdown=="create_clip_frames"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_create_choice_scroll=clamp(script_create_choice_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_FollowFrameOptions(project))-8));
    }else if(script_dropdown=="create_template_choice"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_create_choice_scroll=clamp(script_create_choice_scroll+(mouse_wheel_down()?1:-1),0,max(0,BattleEditor_WorkspaceCreateChoiceCount(script_create_choice_kind,project)-8));
    }else if(script_dropdown=="target"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var scroll_step=script_selected_list>=0&&script_selected_step>=0?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
        var target_option_count=is_undefined(scroll_step)?0:array_length(BattleEditor_ControlSourceOptions(project,scroll_step));
        script_target_scroll=clamp(script_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,target_option_count-8));
    }else if(script_dropdown=="aim_target_value"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_target_scroll=clamp(script_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_AimTargetOptions(project,-1))-8));
    }else if(script_dropdown=="control_follow_frame"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_target_scroll=clamp(script_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_FollowFrameOptions(project))-8));
    }else if(script_dropdown=="action_template"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var template_scroll_step=script_selected_list>=0&&script_selected_step>=0?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
        var template_scroll_is_path=!is_undefined(template_scroll_step)&&template_scroll_step.kind=="builtin_action"&&template_scroll_step.action_name=="bone_function_path"&&round(real(template_scroll_step.action_path_mode))==0;
        var template_scroll_count=template_scroll_is_path?array_length(BattleEditor_FunctionPathCloneOptions(project)):array_length(BattleEditor_ActionTemplateOptions(project));
        script_template_scroll=clamp(script_template_scroll+(mouse_wheel_down()?1:-1),0,max(0,template_scroll_count-8));
    }else if(script_dropdown=="function_path_target"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_target_scroll=clamp(script_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_FunctionPathTargetOptions(project))-8));
    }else if(script_dropdown=="board_shape_target"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_target_scroll=clamp(script_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_ControlTargetOptions(project,"board"))-8));
    }else if(script_dropdown=="screen_action"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_screen_action_scroll=clamp(script_screen_action_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_ScreenActionOptions())-8));
    }else if(script_dropdown=="sound_name"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_sound_scroll=clamp(script_sound_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_SoundOptions(project))-8));
    }else if(script_dropdown=="enemy_resource"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var appearance_scroll_step=script_selected_list>=0&&script_selected_step>=0?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
        if(!is_undefined(appearance_scroll_step)) script_enemy_resource_scroll=clamp(script_enemy_resource_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_EnemyTextureOptions(project,appearance_scroll_step.enemy_uid,appearance_scroll_step.enemy_part_key))-5));
    }else if(script_dropdown=="value_target"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_value_target_scroll=clamp(script_value_target_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_ValueTargetOptions(project))-8));
    }else if(script_dropdown=="value_property"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var value_scroll_step=script_selected_list>=0&&script_selected_step>=0?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
        if(!is_undefined(value_scroll_step)) script_value_property_scroll=clamp(script_value_property_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_ValueProperties(value_scroll_step.read_target_key,value_scroll_step.read_target_type))-8));
    }else if(script_dropdown=="formula_variable"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        script_formula_variable_scroll=clamp(script_formula_variable_scroll+(mouse_wheel_down()?1:-1),0,max(0,array_length(BattleEditor_FormulaVariableOptions(project,script_parameter_step,script_formula_target))-8));
    }else if(keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var old_zoom=script_zoom;
        script_zoom=clamp(script_zoom*(mouse_wheel_up()?1.12:1/1.12),0.45,2.2);
        script_pan_x=mx-workspace_world_x*script_zoom;
        script_pan_y=my-workspace_world_y*script_zoom;
        status_text="Workspace 缩放 "+string(round(script_zoom*100))+"%";
    }
    if(script_dropdown=="item_entry"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var item_option_count=array_length(project.initialization.items);
        if(mouse_wheel_up()) script_item_scroll=max(0,script_item_scroll-1);
        if(mouse_wheel_down()) script_item_scroll=min(max(0,item_option_count-8),script_item_scroll+1);
    }else if(script_dropdown=="action_entry"&&!keyboard_check(vk_control)&&(mouse_wheel_up()||mouse_wheel_down())){
        var action_option_count=array_length(BattleEditor_ActionTriggerOptions(project));
        if(mouse_wheel_up()) script_action_entry_scroll=max(0,script_action_entry_scroll-1);
        if(mouse_wheel_down()) script_action_entry_scroll=min(max(0,action_option_count-8),script_action_entry_scroll+1);
    }

    if(BattleEditor_WorkspaceContextInput(id,mx,my,click,right_click)) exit;

    // The inspector owns the whole right strip. Consume its clicks before the
    // workspace hit test so clicking a field never deselects the script item
    // behind it.
    var script_inspector_consumed=false;
    if(click&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)){
        var inspector_list=project.script_lists[script_selected_list];
        var inspector_step=script_selected_step>=0&&script_selected_step<array_length(inspector_list.steps)?inspector_list.steps[script_selected_step]:undefined;
        var inspector_can_warning=!is_undefined(inspector_step)&&inspector_step.kind=="control_object"&&(inspector_step.property=="position"||inspector_step.property=="orbit"||inspector_step.property=="physics"||inspector_step.property=="aim_motion");
        if(script_dropdown!=""){
            if(script_dropdown=="entry_kind"){
                var entry_row=floor((my-150)/22);
                if(BattleEditor_PointInRect(mx,my,430,150,628,304)&&entry_row>=0&&entry_row<7){
                    inspector_list.entry_kind=entry_row;
                    if(entry_row==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN) inspector_list.entry_value=developer_turn;
                    else if(entry_row==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE){inspector_list.entry_value=60;inspector_list.turn=developer_turn;}
                    else if(entry_row==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED) inspector_list.entry_value=array_length(project.initialization.items)>0?project.initialization.items[0].uid:-1;
                    else if(entry_row==BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION){var action_options=BattleEditor_ActionTriggerOptions(project);inspector_list.entry_value=array_length(action_options)>0?action_options[0].uid:-1;}
                    else inspector_list.entry_value="";
                    script_dropdown="";
                }
            }else if(script_dropdown=="item_entry"){
                var item_options=project.initialization.items;
                var item_visible=min(8,max(1,array_length(item_options)-script_item_scroll));
                var item_row=floor((my-174)/22);
                var item_index=script_item_scroll+item_row;
                if(BattleEditor_PointInRect(mx,my,430,174,628,174+item_visible*22)&&item_row>=0&&item_row<item_visible&&item_index<array_length(item_options)){
                    inspector_list.entry_value=item_options[item_index].uid;
                    script_dropdown="";
                }
            }else if(script_dropdown=="action_entry"){
                var action_options=BattleEditor_ActionTriggerOptions(project);
                var action_visible=min(8,max(1,array_length(action_options)-script_action_entry_scroll));
                var action_row=floor((my-174)/22);
                var action_index=script_action_entry_scroll+action_row;
                if(BattleEditor_PointInRect(mx,my,430,174,628,174+action_visible*22)&&action_row>=0&&action_row<action_visible&&action_index<array_length(action_options)){
                    inspector_list.entry_value=action_options[action_index].uid;
                    script_dropdown="";
                }
            }else if(script_dropdown=="kind"&&!is_undefined(inspector_step)){
                var kind_row=floor((my-200)/22);
                if(BattleEditor_PointInRect(mx,my,500,200,638,464)&&kind_row>=0&&kind_row<12){
                    var kind_values=["control_object","create_object","builtin_action","screen_control","play_sound","enemy_appearance","set_variable","get_value","condition","wait","repeat","start_list"];
                    inspector_step.kind=kind_values[kind_row];
                    if(inspector_step.kind=="create_object"&&inspector_step.create_control_id_auto&&string_length(string(inspector_step.create_control_id))<=0) inspector_step.create_control_id=BattleEditor_NextControlId(project,inspector_step.create_preset);
                    if(inspector_step.kind=="builtin_action"&&inspector_step.action_control_id_auto&&string_length(string(inspector_step.action_control_id))<=0) inspector_step.action_control_id=BattleEditor_NextControlId(project,inspector_step.action_name);
                    if(inspector_step.kind=="enemy_appearance"&&array_length(project.initialization.enemies)>0){
                        inspector_step.enemy_uid=project.initialization.enemies[0].uid;
                        var initial_enemy_resources=BattleEditor_EnemyTextureOptions(project,inspector_step.enemy_uid,inspector_step.enemy_part_key);
                        inspector_step.enemy_resource_uid=array_length(initial_enemy_resources)>0?initial_enemy_resources[0].uid:-1;
                    }
                    script_step_sound_open=false;script_step_warning_open=false;script_dropdown="";
                }
            }else if(script_dropdown=="create_category"&&!is_undefined(inspector_step)){
                var create_category_row=floor((my-226)/22);
                if(BattleEditor_PointInRect(mx,my,510,226,638,358)&&create_category_row>=0&&create_category_row<6){
                    inspector_step.create_category=create_category_row;
                    var category_options=BattleEditor_WorkspaceCreateOptions(create_category_row);
                    BattleEditor_WorkspaceCreateApplyPresetDefaults(inspector_step,category_options[0].id);
                    if(inspector_step.create_control_id_auto){inspector_step.create_control_id="";inspector_step.create_control_id=BattleEditor_NextControlId(project,inspector_step.create_preset);}
                    script_create_scroll=0;
                    script_dropdown="";
                }
            }else if(script_dropdown=="create_preset"&&!is_undefined(inspector_step)){
                var create_options=BattleEditor_WorkspaceCreateOptions(inspector_step.create_category);
                var create_col=floor((mx-420)/109),create_row=floor((my-254)/22);
                var create_index=create_col*6+create_row;
                if(create_col>=0&&create_col<2&&create_row>=0&&create_row<6&&create_index<array_length(create_options)){
                    BattleEditor_WorkspaceCreateApplyPresetDefaults(inspector_step,create_options[create_index].id);
                    if(inspector_step.create_control_id_auto){inspector_step.create_control_id="";inspector_step.create_control_id=BattleEditor_NextControlId(project,inspector_step.create_preset);}
                    script_create_scroll=0;
                    script_dropdown="";
                }
            }else if(script_dropdown=="create_template_choice"&&!is_undefined(inspector_step)){
                var create_choice_count=BattleEditor_WorkspaceCreateChoiceCount(script_create_choice_kind,project);
                var create_choice_visible=min(8,max(1,create_choice_count-script_create_choice_scroll));
                var create_choice_row=floor((my-264)/22);
                var create_choice_index=script_create_choice_scroll+create_choice_row;
                if(BattleEditor_PointInRect(mx,my,420,264,638,264+create_choice_visible*22)&&create_choice_row>=0&&create_choice_row<create_choice_visible&&create_choice_index<create_choice_count){
                    var create_choice_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
                    var create_choice_selected_value=BattleEditor_WorkspaceCreateChoiceValue(script_create_choice_kind,create_choice_index,project);
                    if(script_create_choice_kind=="lifetime_mode"&&create_choice_index==1){
                        var previous_lifetime=real(BattleEditor_WorkspaceTemplateGet(create_choice_template,script_create_choice_path));
                        create_choice_selected_value=previous_lifetime>=0?previous_lifetime:60;
                    }
                    if(script_create_choice_kind=="bone_aim_behavior"){
                        BattleEditor_WorkspaceTemplateSet(create_choice_template,"aim_enabled",create_choice_index!=0);
                        BattleEditor_WorkspaceTemplateSet(create_choice_template,"aim_move_enabled",create_choice_index==2);
                    }else if(script_create_choice_kind=="aim_update") BattleEditor_WorkspaceTemplateSet(create_choice_template,"aim_continuous",create_choice_index==1);
                    else BattleEditor_WorkspaceTemplateSet(create_choice_template,script_create_choice_path,create_choice_selected_value);
                    if(script_create_choice_kind=="visual_color_mode") BattleEditor_SetVisualTintMode(create_choice_template,create_choice_selected_value);
                    else if(script_create_choice_kind=="visual_color_preset") BattleEditor_SetVisualTintPreset(create_choice_template,create_choice_selected_value);
                    else if(script_create_choice_kind=="damage") BattleEditor_ApplyDamageTypeToEvent(create_choice_template,create_choice_selected_value);
                    script_dropdown="";
                }
            }else if(script_dropdown=="create_clip_frames"&&!is_undefined(inspector_step)){
                var create_clip_options=BattleEditor_FollowFrameOptions(project);
                var create_clip_visible=min(8,max(1,array_length(create_clip_options)-script_create_choice_scroll));
                var create_clip_row=floor((my-264)/22);
                var create_clip_index=script_create_choice_scroll+create_clip_row;
                if(BattleEditor_PointInRect(mx,my,420,264,638,264+create_clip_visible*22)&&create_clip_row>=0&&create_clip_row<create_clip_visible&&create_clip_index<array_length(create_clip_options)){
                    var create_clip_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
                    var create_clip_uid=create_clip_options[create_clip_index].uid;
                    var create_clip_found=-1;
                    for(var create_clip_find=0;create_clip_find<array_length(create_clip_template.clip_frame_uids);create_clip_find++) if(create_clip_template.clip_frame_uids[create_clip_find]==create_clip_uid){create_clip_found=create_clip_find;break;}
                    if(create_clip_found>=0) array_delete(create_clip_template.clip_frame_uids,create_clip_found,1);else array_push(create_clip_template.clip_frame_uids,create_clip_uid);
                    create_clip_template.clip_mode="selected";
                }
            }else if(script_dropdown=="create_board_shape"&&!is_undefined(inspector_step)){
                var create_shape_row=floor((my-394)/22);
                if(BattleEditor_PointInRect(mx,my,500,394,638,482)&&create_shape_row>=0&&create_shape_row<4){
                    inspector_step.create_board_shape=create_shape_row;
                    script_dropdown="";
                }
            }else if(script_dropdown=="create_damage"&&!is_undefined(inspector_step)){
                var create_damage_col=floor((mx-410)/112),create_damage_row=floor((my-368)/22);
                var create_damage_index=create_damage_col*5+create_damage_row;
                if(create_damage_col>=0&&create_damage_col<2&&create_damage_row>=0&&create_damage_row<5&&create_damage_index<9){inspector_step.create_damage_type=create_damage_index;script_dropdown="";}
            }else if(script_dropdown=="create_layer"&&!is_undefined(inspector_step)){
                var create_layer_row=floor((my-394)/22);
                if(BattleEditor_PointInRect(mx,my,500,394,628,460)&&create_layer_row>=0&&create_layer_row<3){inspector_step.create_layer_mode=create_layer_row;script_dropdown="";}
            }else if(script_dropdown=="wait_mode"&&!is_undefined(inspector_step)){
                var wait_mode_row=floor((my-260)/22);
                if(BattleEditor_PointInRect(mx,my,430,260,628,304)&&wait_mode_row>=0&&wait_mode_row<2){inspector_step.wait_mode=wait_mode_row;script_dropdown="";}
            }else if(script_dropdown=="builtin_action"&&!is_undefined(inspector_step)){
                var action_options=BattleEditor_BuiltinActionOptions();
                var action_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,420,258,638,258+array_length(action_options)*22)&&action_row>=0&&action_row<array_length(action_options)){
                    inspector_step.action_name=action_options[action_row].id;
                    inspector_step.action_arguments=action_options[action_row].defaults;
                    if(inspector_step.action_name=="bone_function_path"){
                        inspector_step.action_path_variable="t";
                        inspector_step.action_path_mode=0;
                        inspector_step.action_path_target_type="bone";
                        inspector_step.action_path_legacy_default=false;
                        var initial_path_mode_clones=BattleEditor_FunctionPathCloneOptions(project);
                        inspector_step.action_source_uid=array_length(initial_path_mode_clones)>0?initial_path_mode_clones[0].uid:-1;
                    }
                    inspector_step.action_follow=false;
                    inspector_step.action_keep_objects=false;
                    inspector_step.action_exit_tween=inspector_step.tween;
                    inspector_step.action_exit_ease=inspector_step.ease;
                    if(!BattleEditor_BuiltinActionUsesTemplate(inspector_step.action_name)) inspector_step.action_source_uid=-1;
                    if(inspector_step.action_name=="bone_wall") inspector_step.action_direction=1;
                    if(inspector_step.action_name=="board_shape") inspector_step.action_control_id="main_board";
                    else if(inspector_step.action_control_id_auto){inspector_step.action_control_id="";inspector_step.action_control_id=BattleEditor_NextControlId(project,inspector_step.action_name);}
                    script_parameter_scroll=0;
                    script_dropdown="";
                }
            }else if(script_dropdown=="builtin_wall_direction"&&!is_undefined(inspector_step)){
                var wall_direction_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,500,258,628,412)&&wall_direction_row>=0&&wall_direction_row<7){inspector_step.action_direction=wall_direction_row+1;script_dropdown="";}
            }else if(script_dropdown=="builtin_wall_color"&&!is_undefined(inspector_step)){
                var wall_color_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,500,258,628,456)&&wall_color_row>=0&&wall_color_row<9){inspector_step.action_arguments=BattleEditor_ActionArgumentsSet(inspector_step.action_arguments,8,wall_color_row,BattleEditor_BuiltinActionDefaults("bone_wall"));script_dropdown="";}
            }else if(script_dropdown=="builtin_wall_layer"&&!is_undefined(inspector_step)){
                var wall_layer_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,500,258,628,324)&&wall_layer_row>=0&&wall_layer_row<3){inspector_step.action_arguments=BattleEditor_ActionArgumentsSet(inspector_step.action_arguments,9,wall_layer_row,BattleEditor_BuiltinActionDefaults("bone_wall"));script_dropdown="";}
            }else if(script_dropdown=="action_template"&&!is_undefined(inspector_step)){
                var action_template_is_path=inspector_step.kind=="builtin_action"&&inspector_step.action_name=="bone_function_path"&&round(real(inspector_step.action_path_mode))==0;
                var action_template_options=action_template_is_path?BattleEditor_FunctionPathCloneOptions(project):BattleEditor_ActionTemplateOptions(project);
                var action_template_visible=min(8,max(1,array_length(action_template_options)-script_template_scroll));
                var action_template_row=floor((my-258)/22);
                var action_template_index=script_template_scroll+action_template_row;
                if(BattleEditor_PointInRect(mx,my,410,258,638,258+action_template_visible*22)&&action_template_row>=0&&action_template_row<action_template_visible&&action_template_index<array_length(action_template_options)){
                    inspector_step.action_source_uid=action_template_options[action_template_index].uid;
                    if(action_template_is_path) inspector_step.action_path_legacy_default=false;
                    script_dropdown="";
                }
            }else if(script_dropdown=="function_path_mode"&&!is_undefined(inspector_step)){
                var path_mode_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,420,258,638,302)&&path_mode_row>=0&&path_mode_row<2){
                    inspector_step.action_path_mode=path_mode_row;
                    script_parameter_scroll=0;
                    if(path_mode_row==0){
                        inspector_step.action_path_legacy_default=false;
                        var initial_path_clones=BattleEditor_FunctionPathCloneOptions(project);
                        inspector_step.action_source_uid=array_length(initial_path_clones)>0?initial_path_clones[0].uid:-1;
                    }else{
                        var initial_path_targets=BattleEditor_FunctionPathTargetOptions(project);
                        if(array_length(initial_path_targets)>0){
                            inspector_step.action_control_id=initial_path_targets[0].control_id;
                            inspector_step.action_path_target_type=initial_path_targets[0].target_type;
                        }
                    }
                    script_dropdown="";
                }
            }else if(script_dropdown=="function_path_target"&&!is_undefined(inspector_step)){
                var path_target_options=BattleEditor_FunctionPathTargetOptions(project);
                var path_target_visible=min(8,max(1,array_length(path_target_options)-script_target_scroll));
                var path_target_row=floor((my-258)/22),path_target_index=script_target_scroll+path_target_row;
                if(BattleEditor_PointInRect(mx,my,410,258,638,258+path_target_visible*22)&&path_target_row>=0&&path_target_row<path_target_visible&&path_target_index<array_length(path_target_options)){
                    inspector_step.action_control_id=path_target_options[path_target_index].control_id;
                    inspector_step.action_path_target_type=path_target_options[path_target_index].target_type;
                    script_dropdown="";
                }
            }else if(script_dropdown=="board_shape_target"&&!is_undefined(inspector_step)){
                var board_target_options=BattleEditor_ControlTargetOptions(project,"board");
                var board_target_visible=min(8,max(1,array_length(board_target_options)-script_target_scroll));
                var board_target_row=floor((my-258)/22);
                var board_target_index=script_target_scroll+board_target_row;
                if(BattleEditor_PointInRect(mx,my,410,258,638,258+board_target_visible*22)&&board_target_row>=0&&board_target_row<board_target_visible&&board_target_index<array_length(board_target_options)){
                    inspector_step.action_control_id=board_target_options[board_target_index].control_id;
                    script_dropdown="";
                }
            }else if(script_dropdown=="screen_action"&&!is_undefined(inspector_step)){
                var screen_options=BattleEditor_ScreenActionOptions();
                var screen_row=floor((my-258)/22);
                var screen_action_visible=min(8,array_length(screen_options)-script_screen_action_scroll);
                var screen_option_index=script_screen_action_scroll+screen_row;
                if(BattleEditor_PointInRect(mx,my,420,258,638,258+screen_action_visible*22)&&screen_row>=0&&screen_row<screen_action_visible&&screen_option_index<array_length(screen_options)){
                    inspector_step.screen_action=screen_options[screen_option_index].id;
                    inspector_step.screen_arguments=screen_options[screen_option_index].defaults;
                    script_parameter_scroll=0;
                    script_dropdown="";
                }
            }else if(script_dropdown=="sound_name"&&!is_undefined(inspector_step)){
                var sound_options=BattleEditor_SoundOptions(project);
                var sound_visible=min(8,max(1,array_length(sound_options)-script_sound_scroll));
                var sound_row=floor((my-260)/22);
                var sound_index=script_sound_scroll+sound_row;
                if(BattleEditor_PointInRect(mx,my,410,260,638,260+sound_visible*22)&&sound_row>=0&&sound_row<sound_visible&&sound_index<array_length(sound_options)){
                    inspector_step.sound_name=sound_options[sound_index];script_dropdown="";
                }else if(BattleEditor_PointInRect(mx,my,410,260+sound_visible*22,638,286+sound_visible*22)){
                    var imported_audio_path=get_open_filename("音频文件|*.wav;*.ogg;*.mp3;*.flac;*.wma;*.aac;*.m4a","导入音频");
                    if(string_length(imported_audio_path)>0){
                        var staged_audio_path=BattleEditor_RegisterImportedAudio(project,imported_audio_path);
                        if(staged_audio_path!=""){inspector_step.sound_name=staged_audio_path;status_text="已导入音频："+filename_name(staged_audio_path);}
                        else status_text="音频导入失败";
                    }
                    script_dropdown="";
                }
            }else if(script_dropdown=="sound_timing"&&!is_undefined(inspector_step)){
                var sound_timing_row=floor((my-318)/22);
                if(BattleEditor_PointInRect(mx,my,430,318,628,362)&&sound_timing_row>=0&&sound_timing_row<2){inspector_step.sound_timing=sound_timing_row;script_dropdown="";}
            }else if(script_dropdown=="enemy_target"&&!is_undefined(inspector_step)){
                var appearance_enemy_options=project.initialization.enemies;
                var appearance_enemy_visible=min(8,max(1,array_length(appearance_enemy_options)));
                var appearance_enemy_row=floor((my-260)/22);
                if(BattleEditor_PointInRect(mx,my,410,260,638,260+appearance_enemy_visible*22)&&appearance_enemy_row>=0&&appearance_enemy_row<array_length(appearance_enemy_options)){
                    inspector_step.enemy_uid=appearance_enemy_options[appearance_enemy_row].uid;
                    var changed_enemy_resources=BattleEditor_EnemyTextureOptions(project,inspector_step.enemy_uid,inspector_step.enemy_part_key);
                    inspector_step.enemy_resource_uid=array_length(changed_enemy_resources)>0?changed_enemy_resources[0].uid:-1;
                    script_enemy_resource_scroll=0;script_dropdown="";
                }
            }else if(script_dropdown=="enemy_part_key"&&!is_undefined(inspector_step)){
                var appearance_part_options=BattleEditor_EnemyPartKeys();
                var appearance_part_row=floor((my-296)/22);
                if(BattleEditor_PointInRect(mx,my,500,296,638,296+array_length(appearance_part_options)*22)&&appearance_part_row>=0&&appearance_part_row<array_length(appearance_part_options)){
                    inspector_step.enemy_part_key=appearance_part_options[appearance_part_row];script_enemy_resource_scroll=0;script_dropdown="";
                }
            }else if(script_dropdown=="enemy_resource"&&!is_undefined(inspector_step)){
                var appearance_resource_options=BattleEditor_EnemyTextureOptions(project,inspector_step.enemy_uid,inspector_step.enemy_part_key);
                var appearance_resource_visible=min(5,max(1,array_length(appearance_resource_options)-script_enemy_resource_scroll));
                var appearance_resource_row=floor((my-352)/22),appearance_resource_index=script_enemy_resource_scroll+appearance_resource_row;
                if(BattleEditor_PointInRect(mx,my,410,352,638,352+appearance_resource_visible*22)&&appearance_resource_row>=0&&appearance_resource_row<appearance_resource_visible&&appearance_resource_index<array_length(appearance_resource_options)){
                    inspector_step.enemy_resource_uid=appearance_resource_options[appearance_resource_index].uid;script_dropdown="";
                }
            }else if(script_dropdown=="value_target"&&!is_undefined(inspector_step)){
                var value_targets=BattleEditor_ValueTargetOptions(project);
                var value_target_visible=min(8,max(1,array_length(value_targets)-script_value_target_scroll));
                var value_target_row=floor((my-260)/22);
                var value_target_index=script_value_target_scroll+value_target_row;
                if(BattleEditor_PointInRect(mx,my,410,260,638,260+value_target_visible*22)&&value_target_row>=0&&value_target_row<value_target_visible&&value_target_index<array_length(value_targets)){
                    var chosen_value_target=value_targets[value_target_index];
                    inspector_step.read_target_key=chosen_value_target.key;inspector_step.read_target_uid=chosen_value_target.uid;inspector_step.read_target_type=chosen_value_target.target_type;
                    var readable_properties=BattleEditor_ValueProperties(inspector_step.read_target_key,inspector_step.read_target_type);
                    inspector_step.read_property=readable_properties[0];script_value_property_scroll=0;script_dropdown="";
                }
            }else if(script_dropdown=="value_property"&&!is_undefined(inspector_step)){
                var value_properties=BattleEditor_ValueProperties(inspector_step.read_target_key,inspector_step.read_target_type);
                var value_property_visible=min(8,max(1,array_length(value_properties)-script_value_property_scroll));
                var value_property_row=floor((my-296)/22);
                var value_property_index=script_value_property_scroll+value_property_row;
                if(BattleEditor_PointInRect(mx,my,430,296,638,296+value_property_visible*22)&&value_property_row>=0&&value_property_row<value_property_visible&&value_property_index<array_length(value_properties)){
                    inspector_step.read_property=value_properties[value_property_index];script_dropdown="";
                }
            }else if(script_dropdown=="formula_variable"&&!is_undefined(inspector_step)){
                var formula_options=BattleEditor_FormulaVariableOptions(project,inspector_step,script_formula_target);
                var formula_visible=min(8,max(1,array_length(formula_options)-script_formula_variable_scroll));
                var formula_row=floor((my-32)/22);
                var formula_index=script_formula_variable_scroll+formula_row;
                if(BattleEditor_PointInRect(mx,my,370,32,638,32+formula_visible*22)&&formula_row>=0&&formula_row<formula_visible&&formula_index<array_length(formula_options)){
                    var formula_token=formula_options[formula_index].token;
                    script_formula_insert_caret=clamp(script_formula_insert_caret,0,string_length(script_formula_buffer));
                    script_formula_buffer=string_insert(formula_token,script_formula_buffer,script_formula_insert_caret+1);
                    script_formula_insert_caret+=string_length(formula_token);
                    BattleEditor_SetStepFormulaField(inspector_step,script_formula_target,script_formula_buffer);
                    focus_field=script_formula_target;focus_last_field=script_formula_target;
                    focus_expression_base=script_formula_buffer;focus_edit_buffer=script_formula_buffer;focus_edit_caret=script_formula_insert_caret;
                    focus_keyboard_anchor=focus_edit_caret;focus_keyboard_seen="";keyboard_string="";focus_formula_validation_signature="";
                    script_dropdown="";
                }
            }else if(script_dropdown=="parameter_choice"&&!is_undefined(inspector_step)){
                var parameter_action=script_parameter_choice_scope=="screen"?inspector_step.screen_action:inspector_step.action_name;
                var parameter_kind=BattleEditor_ActionParameterKind(script_parameter_choice_scope,parameter_action,script_parameter_choice_index);
                var parameter_choice_count=BattleEditor_ActionParameterChoiceCount(parameter_kind);
                var parameter_choice_row=floor((my-258)/22);
                if(BattleEditor_PointInRect(mx,my,430,258,628,258+parameter_choice_count*22)&&parameter_choice_row>=0&&parameter_choice_row<parameter_choice_count){
                    if(script_parameter_choice_scope=="screen") inspector_step.screen_arguments=BattleEditor_ActionArgumentsSet(inspector_step.screen_arguments,script_parameter_choice_index,parameter_choice_row,BattleEditor_ScreenActionDefaults(inspector_step.screen_action));
                    else inspector_step.action_arguments=BattleEditor_ActionArgumentsSet(inspector_step.action_arguments,script_parameter_choice_index,parameter_choice_row,BattleEditor_BuiltinActionDefaults(inspector_step.action_name));
                    script_dropdown="";
                }
            }else if(script_dropdown=="target_category"&&!is_undefined(inspector_step)){
                var category_values=BattleEditor_ControlCategories();
                var category_row=floor((my-226)/22);
                if(BattleEditor_PointInRect(mx,my,510,226,638,226+array_length(category_values)*22)&&category_row>=0&&category_row<array_length(category_values)){
                    var next_category=category_values[category_row];
                    if(inspector_step.target_category!=next_category){
                        inspector_step.target_category=next_category;
                        inspector_step.target="";
                        inspector_step.target_type="";
                        inspector_step.target_group_uid=-1;
                        inspector_step.target_group_kind="";
                        inspector_step.property="position";
                        inspector_step.property_category="transform";
                    }
                    script_target_scroll=0;
                    script_dropdown="";
                }
            }else if(script_dropdown=="target"&&!is_undefined(inspector_step)){
                var target_options=BattleEditor_ControlSourceOptions(project,inspector_step);
                var target_visible=min(8,max(1,array_length(target_options)-script_target_scroll));
                var target_row=floor((my-252)/22);
                var target_index=script_target_scroll+target_row;
                var target_popup_left=variable_instance_exists(id,"script_target_popup_left")?script_target_popup_left:300;
                if(BattleEditor_PointInRect(mx,my,target_popup_left,252,638,252+target_visible*22)&&target_row>=0&&target_row<target_visible&&target_index<array_length(target_options)){
                    var chosen_target=target_options[target_index];
                    inspector_step.target_mode="control_id";
                    inspector_step.target=chosen_target.control_id;
                    inspector_step.target_type=chosen_target.target_type;
                    inspector_step.target_group_uid=struct_exists(chosen_target,"group_uid")?chosen_target.group_uid:-1;
                    inspector_step.target_group_kind=struct_exists(chosen_target,"group_kind")?string(chosen_target.group_kind):"";
                    inspector_step.follow_value_initialized=false;
                    if(round(real(inspector_step.control_source_mode))==1&&inspector_step.copy_control_id_auto){
                        inspector_step.copy_control_id="";
                        inspector_step.copy_control_id=BattleEditor_NextCopiedControlId(project,chosen_target.control_id);
                    }
                    inspector_step.property_category="transform";
                    var allowed_properties=BattleEditor_ControlPropertiesForStep(inspector_step);
                    var property_allowed=false;
                    for(var allowed_index=0;allowed_index<array_length(allowed_properties);allowed_index++) if(allowed_properties[allowed_index]==inspector_step.property){property_allowed=true;break;}
                    if(!property_allowed) inspector_step.property=allowed_properties[0];
                    inspector_step.property_category=BattleEditor_ControlPropertyCategory(inspector_step.property,inspector_step.target_type);
                    if(inspector_step.target_type=="board") BattleEditor_ApplyBoardControlDefaults(project,inspector_step);
                    BattleEditor_ControlFollowApplySourceDefault(project,inspector_step);
                    script_dropdown="";
                }
            }else if(script_dropdown=="property_category"&&!is_undefined(inspector_step)){
                var property_categories=BattleEditor_ControlPropertyCategoriesForStep(inspector_step);
                var property_category_row=floor((my-278)/22);
                if(BattleEditor_PointInRect(mx,my,420,278,638,278+array_length(property_categories)*22)&&property_category_row>=0&&property_category_row<array_length(property_categories)){
                    inspector_step.property_category=property_categories[property_category_row];
                    var category_properties=BattleEditor_ControlPropertiesForStep(inspector_step,inspector_step.property_category);
                    if(array_length(category_properties)>0){
                        inspector_step.property=category_properties[0];
                        if(inspector_step.target_type=="board") BattleEditor_ApplyBoardControlDefaults(project,inspector_step);
                        BattleEditor_ControlFollowApplySourceDefault(project,inspector_step);
                    }
                    script_dropdown="";
                }
            }else if(script_dropdown=="property"&&!is_undefined(inspector_step)){
                var property_col=floor((mx-420)/109);
                var property_row=floor((my-278)/22);
                var property_index=property_col*8+property_row;
                var property_values=BattleEditor_ControlPropertiesForStep(inspector_step,inspector_step.property_category);
                if(property_col>=0&&property_col<2&&property_row>=0&&property_row<8&&property_index<array_length(property_values)){
                    inspector_step.property=property_values[property_index];
                    if(inspector_step.target_type=="board") BattleEditor_ApplyBoardControlDefaults(project,inspector_step);
                    BattleEditor_ControlFollowApplySourceDefault(project,inspector_step);
                    script_dropdown="";
                }
            }else if(script_dropdown=="control_follow_frame"&&!is_undefined(inspector_step)){
                var control_follow_options=BattleEditor_FollowFrameOptions(project);
                var control_follow_visible=min(8,max(1,array_length(control_follow_options)-script_target_scroll));
                var control_follow_row=floor((my-338)/22);
                var control_follow_index=script_target_scroll+control_follow_row;
                if(BattleEditor_PointInRect(mx,my,410,338,628,338+control_follow_visible*22)&&control_follow_row>=0&&control_follow_row<control_follow_visible&&control_follow_index<array_length(control_follow_options)){
                    inspector_step.follow_target_uid=control_follow_options[control_follow_index].uid;
                    inspector_step.follow_value_initialized=true;
                    script_dropdown="";
                }
            }else if(script_dropdown=="coordinate_mode"&&!is_undefined(inspector_step)){
                var coordinate_popup_y=inspector_step.property=="control_vertex"?394:306;
                var coordinate_row=floor((my-coordinate_popup_y)/22);
                if(BattleEditor_PointInRect(mx,my,430,coordinate_popup_y,628,coordinate_popup_y+44)&&coordinate_row>=0&&coordinate_row<2){
                    inspector_step.coordinate_mode=coordinate_row==0?"absolute":"relative";
                    if(inspector_step.target_type=="board"&&inspector_step.property=="position"){
                        if(coordinate_row==0) BattleEditor_ApplyBoardControlDefaults(project,inspector_step);
                        else{
                            inspector_step.position_x="";inspector_step.position_y="";inspector_step.position_angle="";
                            inspector_step.board_transform_width="";inspector_step.board_transform_height="";
                        }
                    }
                    script_dropdown="";
                }
            }else if((script_dropdown=="tween"||script_dropdown=="action_exit_tween")&&!is_undefined(inspector_step)){
                var tween_col=floor((mx-420)/104);
                var tween_row=floor((my-220)/20);
                var tween_index=tween_col*7+tween_row;
                if(tween_col>=0&&tween_col<2&&tween_row>=0&&tween_row<7&&tween_index<11){
                    if(script_dropdown=="action_exit_tween") inspector_step.action_exit_tween=tween_index; else inspector_step.tween=tween_index;
                    script_dropdown="";
                }
            }else if((script_dropdown=="ease"||script_dropdown=="action_exit_ease")&&!is_undefined(inspector_step)){
                var ease_row=floor((my-220)/22);
                if(BattleEditor_PointInRect(mx,my,532,220,628,286)&&ease_row>=0&&ease_row<3){
                    if(script_dropdown=="action_exit_ease") inspector_step.action_exit_ease=ease_row; else inspector_step.ease=ease_row;
                    script_dropdown="";
                }
            }else if(script_dropdown=="variable_operation"&&!is_undefined(inspector_step)){
                var operation_row=floor((my-294)/22);
                if(BattleEditor_PointInRect(mx,my,510,294,628,404)&&operation_row>=0&&operation_row<5){inspector_step.variable_operation=["set","add","subtract","multiply","divide"][operation_row];script_dropdown="";}
            }else if(script_dropdown=="condition_operator"&&!is_undefined(inspector_step)){
                var condition_row=floor((my-266)/22);
                if(BattleEditor_PointInRect(mx,my,510,266,628,398)&&condition_row>=0&&condition_row<6){inspector_step.condition_operator=["==","!=",">",">=","<","<="][condition_row];script_dropdown="";}
            }else if(script_dropdown=="choice_value"&&!is_undefined(inspector_step)){
                var choice_count=BattleEditor_ControlChoiceCount(inspector_step.property);
                if(inspector_step.property=="mask_color"){
                    var choice_column=floor((mx-346)/94),choice_row=floor((my-306)/22),choice_index=choice_column*6+choice_row;
                    if(BattleEditor_PointInRect(mx,my,346,306,628,438)&&choice_column>=0&&choice_column<3&&choice_row>=0&&choice_row<6&&choice_index<choice_count){inspector_step.value=choice_index;script_dropdown="";}
                }else{
                    var choice_row=floor((my-306)/22);
                    if(BattleEditor_PointInRect(mx,my,510,306,628,306+choice_count*22)&&choice_row>=0&&choice_row<choice_count){inspector_step.value=choice_row;script_dropdown="";}
                }
            }else if(script_dropdown=="length_anchor"&&!is_undefined(inspector_step)){
                var length_anchor_row=floor((my-334)/22);
                if(BattleEditor_PointInRect(mx,my,430,334,628,400)&&length_anchor_row>=0&&length_anchor_row<3){inspector_step.length_anchor=length_anchor_row;script_dropdown="";}
            }else if(script_dropdown=="soul_blue_direction"&&!is_undefined(inspector_step)){
                var soul_direction_row=floor((my-336)/22);
                if(BattleEditor_PointInRect(mx,my,510,336,628,424)&&soul_direction_row>=0&&soul_direction_row<4){
                    if(inspector_step.property=="soul_mode") inspector_step.soul_blue_direction=soul_direction_row;
                    else inspector_step.value=soul_direction_row;
                    script_dropdown="";
                }
            }else if(script_dropdown=="aim_target_value"&&!is_undefined(inspector_step)){
                var aim_value_options=BattleEditor_AimTargetOptions(project,-1);
                var aim_value_visible=min(8,max(1,array_length(aim_value_options)-script_target_scroll));
                var aim_value_row=floor((my-306)/22);
                var aim_value_index=script_target_scroll+aim_value_row;
                if(BattleEditor_PointInRect(mx,my,410,306,628,306+aim_value_visible*22)&&aim_value_row>=0&&aim_value_row<aim_value_visible&&aim_value_index<array_length(aim_value_options)){
                    if(inspector_step.property=="aim_motion") inspector_step.aim_target_uid=aim_value_options[aim_value_index].uid;
                    else inspector_step.value=aim_value_options[aim_value_index].uid;
                    script_dropdown="";
                }
            }else if(script_dropdown=="aim_motion_mode"&&!is_undefined(inspector_step)){
                var aim_motion_mode_row=floor((my-362)/22);
                if(BattleEditor_PointInRect(mx,my,430,362,628,406)&&aim_motion_mode_row>=0&&aim_motion_mode_row<2){
                    inspector_step.aim_continuous=aim_motion_mode_row==1;
                    script_dropdown="";
                }
            }else if(script_dropdown=="aim_behavior"&&!is_undefined(inspector_step)){
                var aim_behavior_row=floor((my-334)/22);
                if(BattleEditor_PointInRect(mx,my,430,334,628,400)&&aim_behavior_row>=0&&aim_behavior_row<3){
                    inspector_step.aim_behavior=aim_behavior_row;
                    inspector_step.aim_face_target=aim_behavior_row!=2;
                    script_dropdown="";
                }
            }
            script_inspector_consumed=true;
            // Any click which did not choose an option dismisses the dropdown.
            // Previously the broad inspector rectangle kept it focused even
            // when the author clicked visibly empty space inside the panel.
            if(script_dropdown!=""){
                script_dropdown="";
                // Workspace/canvas clicks should still perform their normal
                // action after dismissing an inspector dropdown.
                if(!BattleEditor_PointInRect(mx,my,420,36,638,450)){
                    deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
                }
            }
        }else if(BattleEditor_PointInRect(mx,my,420,36,638,450)){
            script_inspector_consumed=true;
            if(BattleEditor_PointInRect(mx,my,430,84,628,106)){focus_field="script_list_name";keyboard_string=inspector_list.name;}
            else if(BattleEditor_WorkspaceHasHeader(inspector_list)&&BattleEditor_PointInRect(mx,my,430,126,628,148)) script_dropdown="entry_kind";
            else if(inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED&&BattleEditor_PointInRect(mx,my,498,150,628,172)){script_dropdown="item_entry";script_item_scroll=0;}
            else if(inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION&&BattleEditor_PointInRect(mx,my,498,150,628,172)){script_dropdown="action_entry";script_action_entry_scroll=0;}
            else if((inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN||inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE)&&BattleEditor_PointInRect(mx,my,518,150,628,172)){focus_field="script_entry_value";keyboard_string=string(inspector_list.entry_value);}
            else if(!is_undefined(inspector_step)&&((inspector_can_warning&&BattleEditor_PointInRect(mx,my,534,176,628,198))||(!inspector_can_warning&&BattleEditor_PointInRect(mx,my,510,176,628,198)))) script_dropdown="kind";
            else if(inspector_can_warning&&BattleEditor_PointInRect(mx,my,480,176,530,198)){
                script_step_warning_open=!script_step_warning_open;
                script_step_sound_open=false;
                script_dropdown="";
            }
            else if(!is_undefined(inspector_step)&&inspector_step.kind!="play_sound"&&BattleEditor_PointInRect(mx,my,430,176,inspector_can_warning?476:504,198)){
                script_step_sound_open=!script_step_sound_open;
                script_step_warning_open=false;
                script_dropdown="";
            }
            else if(!is_undefined(inspector_step)&&script_step_sound_open&&inspector_step.kind!="play_sound"){
                if(BattleEditor_PointInRect(mx,my,430,234,594,258)){script_dropdown="sound_name";script_sound_scroll=0;}
                else if(BattleEditor_PointInRect(mx,my,600,234,628,258)) BattleEditor_AudioPreviewToggleNamed(id,inspector_step.sound_name,"workspace_"+string(inspector_step.uid));
                else if(BattleEditor_PointInRect(mx,my,430,292,628,316)) script_dropdown="sound_timing";
                else if(BattleEditor_PointInRect(mx,my,430,330,628,354)) inspector_step.step_sound_enabled=!inspector_step.step_sound_enabled;
            }
            else if(inspector_can_warning&&script_step_warning_open){
                if(BattleEditor_PointInRect(mx,my,430,234,628,258)) inspector_step.warning_enabled=!inspector_step.warning_enabled;
                else if(BattleEditor_PointInRect(mx,my,530,270,628,294)){focus_field="script_warning_duration";keyboard_string=string(inspector_step.warning_duration);}
                else if(BattleEditor_PointInRect(mx,my,530,306,628,330)) inspector_step.warning_angle_mode=round(real(inspector_step.warning_angle_mode))==0?1:0;
                else if(round(real(inspector_step.warning_angle_mode))==1&&BattleEditor_PointInRect(mx,my,530,342,628,366)){focus_field="script_warning_angle";keyboard_string=string(inspector_step.warning_angle);}
            }
            else if(!is_undefined(inspector_step)&&inspector_step.kind=="create_object"){
                var create_is_board=inspector_step.create_preset=="board_add"||inspector_step.create_preset=="board_subtract";
                if(BattleEditor_PointInRect(mx,my,510,202,628,224)) script_dropdown="create_category";
                else if(BattleEditor_PointInRect(mx,my,510,230,628,252)) script_dropdown="create_preset";
                else if(BattleEditor_PointInRect(mx,my,510,258,628,280)){focus_field="script_create_control_id";keyboard_string=string(inspector_step.create_control_id);}
                else if(BattleEditor_PointInRect(mx,my,474,286,548,308)){focus_field="script_create_x";keyboard_string=string(inspector_step.create_x);}
                else if(BattleEditor_PointInRect(mx,my,554,286,628,308)){focus_field="script_create_y";keyboard_string=string(inspector_step.create_y);}
                else if(create_is_board&&BattleEditor_PointInRect(mx,my,510,314,566,336)){focus_field="script_create_angle";keyboard_string=string(inspector_step.create_angle);}
                else if(create_is_board&&BattleEditor_PointInRect(mx,my,572,314,628,336)){focus_field="script_create_board_rotate";keyboard_string=string(inspector_step.create_board_rotate);}
                else if(create_is_board&&BattleEditor_PointInRect(mx,my,510,342,566,364)){focus_field="script_create_lifetime";keyboard_string=string(inspector_step.create_lifetime);}
                else if(create_is_board&&BattleEditor_PointInRect(mx,my,572,342,628,364)){focus_field="script_create_board_depth";keyboard_string=string(inspector_step.create_board_depth);}
                else if(create_is_board&&BattleEditor_PointInRect(mx,my,510,370,628,392)) script_dropdown="create_board_shape";
                else if(create_is_board&&inspector_step.create_board_shape==0&&BattleEditor_PointInRect(mx,my,474,398,548,420)){focus_field="script_create_board_up";keyboard_string=string(inspector_step.create_board_up);}
                else if(create_is_board&&inspector_step.create_board_shape==0&&BattleEditor_PointInRect(mx,my,554,398,628,420)){focus_field="script_create_board_down";keyboard_string=string(inspector_step.create_board_down);}
                else if(create_is_board&&inspector_step.create_board_shape==0&&BattleEditor_PointInRect(mx,my,474,426,548,448)){focus_field="script_create_board_left";keyboard_string=string(inspector_step.create_board_left);}
                else if(create_is_board&&inspector_step.create_board_shape==0&&BattleEditor_PointInRect(mx,my,554,426,628,448)){focus_field="script_create_board_right";keyboard_string=string(inspector_step.create_board_right);}
                else if(create_is_board&&inspector_step.create_board_shape==1&&BattleEditor_PointInRect(mx,my,510,398,566,420)){focus_field="script_create_board_radius_x";keyboard_string=string(inspector_step.create_board_radius_x);}
                else if(create_is_board&&inspector_step.create_board_shape==1&&BattleEditor_PointInRect(mx,my,572,398,628,420)){focus_field="script_create_board_radius_y";keyboard_string=string(inspector_step.create_board_radius_y);}
                else if(create_is_board&&inspector_step.create_board_shape==2&&BattleEditor_PointInRect(mx,my,540,398,628,420)){focus_field="script_create_board_triangle_size";keyboard_string=string(inspector_step.create_board_triangle_size);}
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,510,398,566,420)){focus_field="script_create_board_vertex_x";keyboard_string=BattleEditor_GetStepFormulaField(inspector_step,"script_create_board_vertex_x");}
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,572,398,628,420)){focus_field="script_create_board_vertex_y";keyboard_string=BattleEditor_GetStepFormulaField(inspector_step,"script_create_board_vertex_y");}
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,430,426,474,448)) inspector_step.point_index=(inspector_step.point_index-1+array_length(inspector_step.points)) mod array_length(inspector_step.points);
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,478,426,522,448)) inspector_step.point_index=(inspector_step.point_index+1) mod array_length(inspector_step.points);
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,526,426,574,448)){
                    array_insert(inspector_step.points,inspector_step.point_index+1,["0","0"]);inspector_step.point_index+=1;
                }
                else if(create_is_board&&inspector_step.create_board_shape==3&&BattleEditor_PointInRect(mx,my,578,426,628,448)&&array_length(inspector_step.points)>3){
                    array_delete(inspector_step.points,inspector_step.point_index,1);inspector_step.point_index=min(inspector_step.point_index,array_length(inspector_step.points)-1);
                }
                else if(!create_is_board&&BattleEditor_PointInRect(mx,my,420,284,638,450)){
                    var click_create_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
                    var click_create_fields=BattleEditor_WorkspaceCreateFields(inspector_step.create_preset);
                    var click_create_y=286-script_create_scroll;
                    for(var click_create_index=0;click_create_index<array_length(click_create_fields);click_create_index++){
                        var click_create_field=click_create_fields[click_create_index];
                        var click_create_height=BattleEditor_WorkspaceCreateFieldHeight(click_create_field);
                        var click_create_value_right=click_create_field.kind=="frames"?542:630;
                        if(BattleEditor_PointInRect(mx,my,430,click_create_y+16,click_create_value_right,click_create_y+38)){
                            if(click_create_field.kind=="clip_frames"){
                                script_create_choice_scroll=0;script_dropdown="create_clip_frames";
                            }else if(click_create_field.kind=="choice"){
                                var click_create_choice_value=BattleEditor_WorkspaceTemplateGet(click_create_template,click_create_field.path);
                                if(click_create_field.choice=="bone_aim_behavior") click_create_choice_value=!BattleEditor_WorkspaceTemplateGet(click_create_template,"aim_enabled")?0:(BattleEditor_WorkspaceTemplateGet(click_create_template,"aim_move_enabled")?2:1);
                                if(click_create_field.choice=="voice"&&mx>=600) BattleEditor_AudioPreviewToggleVoice(id,click_create_choice_value,"workspace_create_"+string(inspector_step.uid)+"_voice");
                                else{script_create_choice_path=click_create_field.path;script_create_choice_kind=click_create_field.choice;script_create_choice_scroll=max(0,BattleEditor_WorkspaceCreateChoiceIndex(click_create_field.choice,click_create_choice_value,project)-3);script_create_choice_scroll=min(script_create_choice_scroll,max(0,BattleEditor_WorkspaceCreateChoiceCount(click_create_field.choice,project)-8));script_dropdown="create_template_choice";}
                            }else if(click_create_field.kind=="visual_template_toggle"){
                                var click_template_mode=clamp(round(real(BattleEditor_WorkspaceTemplateGet(click_create_template,"visual_tint.mode"))),0,2);
                                if(click_template_mode==2) BattleEditor_SetVisualTintMode(click_create_template,1);
                                else{
                                    BattleEditor_WorkspaceTemplateSet(click_create_template,"visual_tint.custom_color",BattleEditor_WorkspaceTemplateGet(click_create_template,"visual_tint.color"));
                                    BattleEditor_SetVisualTintMode(click_create_template,2);
                                }
                            }else if(click_create_field.kind=="lifetime"){
                                var click_lifetime_value=BattleEditor_WorkspaceTemplateGet(click_create_template,click_create_field.path);
                                if(mx<544){
                                    script_create_choice_path=click_create_field.path;script_create_choice_kind="lifetime_mode";script_create_choice_scroll=0;script_dropdown="create_template_choice";
                                }else if(real(click_lifetime_value)>=0){
                                    focus_field="script_create_formula_"+click_create_field.path;keyboard_string=string(click_lifetime_value);
                                }
                            }else if(click_create_field.kind=="bool"){
                                var next_create_bool=real(BattleEditor_WorkspaceTemplateGet(click_create_template,click_create_field.path))==0;
                                if(click_create_field.path=="damage_profile.change_visual") BattleEditor_SetDamageChangeVisual(click_create_template,next_create_bool);
                                else BattleEditor_WorkspaceTemplateSet(click_create_template,click_create_field.path,next_create_bool);
                            }else if(click_create_field.kind=="color"){
                                var click_visual_mode=click_create_field.path=="visual_tint.color"?clamp(round(real(BattleEditor_WorkspaceTemplateGet(click_create_template,"visual_tint.mode"))),0,2):2;
                                if(click_create_field.path=="visual_tint.color"&&click_visual_mode!=2){
                                    script_create_choice_path="visual_tint.preset_type";script_create_choice_kind="visual_color_preset";
                                    var click_visual_preset=BattleEditor_WorkspaceTemplateGet(click_create_template,"visual_tint.preset_type");
                                    script_create_choice_scroll=max(0,BattleEditor_WorkspaceCreateChoiceIndex("visual_color_preset",click_visual_preset,project)-3);
                                    script_create_choice_scroll=min(script_create_choice_scroll,max(0,BattleEditor_WorkspaceCreateChoiceCount("visual_color_preset",project)-8));
                                    script_dropdown="create_template_choice";
                                }else if(click_create_field.path!="visual_tint.color"||click_visual_mode==2){
                                    script_create_choice_path=click_create_field.path;
                                    var click_create_color_source=BattleEditor_WorkspaceTemplateGet(click_create_template,click_create_field.path);
                                    var click_create_color=is_real(click_create_color_source)?click_create_color_source:GetColorFromString(click_create_color_source);
                                    BattleEditor_OpenColorPicker(id,"workspace_create_color",click_create_color,1);
                                }
                            }else if(click_create_field.kind=="frames"){
                                var click_create_frames=click_create_template.animation.frames;
                                if(array_length(click_create_frames)<=0){array_push(click_create_frames,"");inspector_step.create_animation_frame_index=0;}
                                focus_field="script_create_frame";keyboard_string=click_create_frames[clamp(round(real(inspector_step.create_animation_frame_index)),0,array_length(click_create_frames)-1)];
                            }else if(click_create_field.kind=="path"&&mx>=548){
                                var click_create_image_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择贴图");
                                if(string_length(click_create_image_path)>0) BattleEditor_WorkspaceTemplateSet(click_create_template,click_create_field.path,BattleEditor_StageResource(click_create_image_path));
                            }else{
                                focus_field=((click_create_field.kind=="text"||click_create_field.kind=="path")?"script_create_text_":"script_create_formula_")+click_create_field.path;
                                keyboard_string=string(BattleEditor_WorkspaceTemplateGet(click_create_template,click_create_field.path));
                            }
                            break;
                        }else if(click_create_field.kind=="frames"&&BattleEditor_PointInRect(mx,my,548,click_create_y+16,628,click_create_y+38)){
                            var click_create_frame_path=get_open_filename("PNG/JPG 图片|*.png;*.jpg;*.jpeg;*.webp","选择动画帧");
                            if(string_length(click_create_frame_path)>0){
                                click_create_frame_path=BattleEditor_StageResource(click_create_frame_path);
                                var click_create_path_frames=click_create_template.animation.frames;
                                if(array_length(click_create_path_frames)<=0){array_push(click_create_path_frames,click_create_frame_path);inspector_step.create_animation_frame_index=0;}
                                else click_create_path_frames[clamp(round(real(inspector_step.create_animation_frame_index)),0,array_length(click_create_path_frames)-1)]=click_create_frame_path;
                            }
                            break;
                        }else if(click_create_field.kind=="frames"&&BattleEditor_PointInRect(mx,my,430,click_create_y+42,594,click_create_y+62)){
                            var click_frames=click_create_template.animation.frames;
                            var click_frame_count=array_length(click_frames);
                            if(mx<470&&click_frame_count>0) inspector_step.create_animation_frame_index=(inspector_step.create_animation_frame_index-1+click_frame_count) mod click_frame_count;
                            else if(mx<512&&click_frame_count>0) inspector_step.create_animation_frame_index=(inspector_step.create_animation_frame_index+1) mod click_frame_count;
                            else if(mx<554){array_insert(click_frames,min(click_frame_count,inspector_step.create_animation_frame_index+1),"");inspector_step.create_animation_frame_index=min(click_frame_count,inspector_step.create_animation_frame_index+1);}
                            else if(click_frame_count>0){array_delete(click_frames,inspector_step.create_animation_frame_index,1);inspector_step.create_animation_frame_index=clamp(inspector_step.create_animation_frame_index,0,max(0,array_length(click_frames)-1));}
                            break;
                        }
                        click_create_y+=click_create_height;
                    }
                }
            }
            else if(!is_undefined(inspector_step)&&inspector_step.kind=="control_object"){
                if(BattleEditor_PointInRect(mx,my,430,202,526,224)||BattleEditor_PointInRect(mx,my,532,202,628,224)){
                    var requested_source_mode=BattleEditor_PointInRect(mx,my,532,202,628,224)?1:0;
                    if(round(real(inspector_step.control_source_mode))!=requested_source_mode){
                        inspector_step.control_source_mode=requested_source_mode;
                        inspector_step.target="";inspector_step.target_type="";inspector_step.target_group_uid=-1;inspector_step.target_group_kind="";
                        inspector_step.property="position";inspector_step.property_category="transform";
                        inspector_step.follow_value_initialized=false;
                        if(requested_source_mode==1){
                            if(inspector_step.copy_control_id_auto||string_length(string(inspector_step.copy_control_id))<=0){inspector_step.copy_control_id="";inspector_step.copy_control_id_auto=true;}
                            status_text="复制后控制：只列出可实例化的场景对象来源";
                        }else status_text="直接控制：只列出真实 Control ID 与运行时控制节点";
                    }
                    script_dropdown="";
                }
                else if(BattleEditor_PointInRect(mx,my,430,228,round(real(inspector_step.control_source_mode))==1?482:494,250)) script_dropdown="target_category";
                else if(BattleEditor_PointInRect(mx,my,round(real(inspector_step.control_source_mode))==1?486:498,228,round(real(inspector_step.control_source_mode))==1?554:628,250)){
                    script_dropdown="target";script_target_scroll=0;
                    var popup_copy_mode=round(real(inspector_step.control_source_mode))==1;
                    var popup_options=BattleEditor_ControlSourceOptions(project,inspector_step);
                    script_target_popup_left=BattleEditor_ControlSourcePopupLeft(popup_options,popup_copy_mode);
                }
                else if(round(real(inspector_step.control_source_mode))==1&&BattleEditor_PointInRect(mx,my,568,228,628,250)){focus_field="script_copy_control_id";keyboard_string=string(inspector_step.copy_control_id);}
                else if(BattleEditor_PointInRect(mx,my,474,254,530,276)) script_dropdown="property_category";
                else if(BattleEditor_PointInRect(mx,my,534,254,628,276)) script_dropdown="property";
                else if(inspector_step.property=="control_vertex"&&BattleEditor_PointInRect(mx,my,430,282,628,304)){
                    script_vertex_pick=true;script_vertex_pick_list=script_selected_list;script_vertex_pick_step=script_selected_step;
                    tab=0;tool=0;object_palette=false;hazard_palette=false;board_palette=false;board_edit_session=true;
                    status_text="点击一个框顶点；按住 Shift 可连续加入多个顶点";
                }else if(inspector_step.property=="control_vertex"&&BattleEditor_PointInRect(mx,my,450,342,524,364)){focus_field="script_vertex_x";keyboard_string=string(inspector_step.vertex_target_x);}
                else if(inspector_step.property=="control_vertex"&&BattleEditor_PointInRect(mx,my,552,342,628,364)){focus_field="script_vertex_y";keyboard_string=string(inspector_step.vertex_target_y);}
                else if(inspector_step.property=="control_vertex"&&BattleEditor_PointInRect(mx,my,430,370,628,392)) script_dropdown="coordinate_mode";
                else if(inspector_step.property=="position"&&BattleEditor_PointInRect(mx,my,430,282,628,304)) script_dropdown="coordinate_mode";
                else if(inspector_step.property=="position"&&BattleEditor_PointInRect(mx,my,430,328,526,350)){focus_field="script_position_x";keyboard_string=string(inspector_step.position_x);}
                else if(inspector_step.property=="position"&&BattleEditor_PointInRect(mx,my,532,328,628,350)){focus_field="script_position_y";keyboard_string=string(inspector_step.position_y);}
                else if(inspector_step.property=="position"&&inspector_step.target_type=="board"&&BattleEditor_PointInRect(mx,my,430,372,492,394)){focus_field="script_position_angle";keyboard_string=string(inspector_step.position_angle);}
                else if(inspector_step.property=="position"&&inspector_step.target_type=="board"&&BattleEditor_PointInRect(mx,my,498,372,558,394)){focus_field="script_board_transform_width";keyboard_string=string(inspector_step.board_transform_width);}
                else if(inspector_step.property=="position"&&inspector_step.target_type=="board"&&BattleEditor_PointInRect(mx,my,568,372,628,394)){focus_field="script_board_transform_height";keyboard_string=string(inspector_step.board_transform_height);}
                else if(inspector_step.property=="position"&&inspector_step.target_type!="board"&&BattleEditor_PointInRect(mx,my,430,372,628,394)){focus_field="script_position_angle";keyboard_string=string(inspector_step.position_angle);}
                else if(inspector_step.property=="orbit"&&BattleEditor_PointInRect(mx,my,510,282,628,304)){focus_field="script_value";keyboard_string=string(inspector_step.value);}
                else if(inspector_step.property=="orbit"&&BattleEditor_PointInRect(mx,my,430,310,628,332)) inspector_step.orbit_use_group_center=!inspector_step.orbit_use_group_center;
                else if(inspector_step.property=="orbit"&&!inspector_step.orbit_use_group_center&&BattleEditor_PointInRect(mx,my,430,338,526,360)){focus_field="script_orbit_center_x";keyboard_string=string(inspector_step.orbit_center_x);}
                else if(inspector_step.property=="orbit"&&!inspector_step.orbit_use_group_center&&BattleEditor_PointInRect(mx,my,532,338,628,360)){focus_field="script_orbit_center_y";keyboard_string=string(inspector_step.orbit_center_y);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,282,628,304)){focus_field="script_physics_direction";keyboard_string=string(inspector_step.physics_direction);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,310,628,332)){focus_field="script_physics_speed";keyboard_string=string(inspector_step.physics_speed);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,338,628,360)){focus_field="script_physics_acceleration";keyboard_string=string(inspector_step.physics_acceleration);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,366,628,388)){focus_field="script_physics_curve_speed";keyboard_string=string(inspector_step.physics_curve_speed);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,394,628,416)){focus_field="script_physics_rotation_speed";keyboard_string=string(inspector_step.physics_rotation_speed);}
                else if(inspector_step.property=="physics"&&BattleEditor_PointInRect(mx,my,510,422,628,444)){focus_field="script_duration";keyboard_string=string(inspector_step.duration);}
                else if(inspector_step.property=="aim_motion"&&BattleEditor_PointInRect(mx,my,510,282,628,304)){script_dropdown="aim_target_value";script_target_scroll=0;}
                else if(inspector_step.property=="aim_motion"&&BattleEditor_PointInRect(mx,my,510,310,628,332)) script_dropdown="aim_behavior";
                else if(inspector_step.property=="aim_motion"&&BattleEditor_PointInRect(mx,my,510,338,628,360)) script_dropdown="aim_motion_mode";
                else if(inspector_step.property=="aim_motion"&&inspector_step.aim_behavior!=0&&BattleEditor_PointInRect(mx,my,510,366,628,388)){focus_field="script_aim_move_speed";keyboard_string=string(inspector_step.aim_move_speed);}
                else if(inspector_step.property=="aim_motion"&&BattleEditor_PointInRect(mx,my,510,394,628,416)){focus_field="script_duration";keyboard_string=string(inspector_step.duration);}
                else if(inspector_step.property=="shape"&&BattleEditor_PointInRect(mx,my,510,282,628,304)) script_dropdown="choice_value";
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==0&&BattleEditor_PointInRect(mx,my,430,328,526,350)){focus_field="script_board_shape_width";keyboard_string=string(inspector_step.board_shape_width);}
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==0&&BattleEditor_PointInRect(mx,my,532,328,628,350)){focus_field="script_board_shape_height";keyboard_string=string(inspector_step.board_shape_height);}
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==1&&BattleEditor_PointInRect(mx,my,430,328,526,350)){focus_field="script_board_shape_radius_x";keyboard_string=string(inspector_step.board_shape_radius_x);}
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==1&&BattleEditor_PointInRect(mx,my,532,328,628,350)){focus_field="script_board_shape_radius_y";keyboard_string=string(inspector_step.board_shape_radius_y);}
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==2&&BattleEditor_PointInRect(mx,my,430,328,526,350)){focus_field="script_board_shape_triangle_width";keyboard_string=string(inspector_step.board_shape_triangle_width);}
                else if(inspector_step.property=="shape"&&clamp(round(real(inspector_step.value)),0,3)==2&&BattleEditor_PointInRect(mx,my,532,328,628,350)){focus_field="script_board_shape_triangle_height";keyboard_string=string(inspector_step.board_shape_triangle_height);}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,510,282,628,304)){
                    text_editor_open=true;text_editor_target="script_enemy_speech";text_editor_buffer=inspector_step.text_value;text_editor_caret=string_length(text_editor_buffer);text_editor_focus="text";text_editor_help=false;keyboard_string="";
                }
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,510,312,556,336)){font_dropdown_open=true;font_dropdown_target="script_enemy_speech";font_dropdown_scroll=clamp(round(real(inspector_step.dialogue_font))-4,0,max(0,TextTyper_FontCount()-10));}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,560,312,600,336)){choice_menu_open=true;choice_menu_context="script_enemy_voice";choice_menu_kind="voice";choice_menu_scroll=0;}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,604,312,628,336)) BattleEditor_AudioPreviewToggleVoice(id,inspector_step.dialogue_voice,"script_enemy_voice_"+string(inspector_step.uid));
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,510,344,628,368)){choice_menu_open=true;choice_menu_context="script_enemy_template";choice_menu_kind="dialogue_template";choice_menu_scroll=0;}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,510,376,566,400)){focus_field="script_dialogue_offset_x";keyboard_string=string(inspector_step.dialogue_offset_x);}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,572,376,628,400)){focus_field="script_dialogue_offset_y";keyboard_string=string(inspector_step.dialogue_offset_y);}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,510,404,628,428)){choice_menu_open=true;choice_menu_context="script_enemy_mode";choice_menu_kind="dialogue_mode";choice_menu_scroll=0;}
                else if(inspector_step.property=="speak"&&BattleEditor_PointInRect(mx,my,430,434,628,458)) inspector_step.dialogue_block_battle=!inspector_step.dialogue_block_battle;
                else if(inspector_step.property=="gb_hold"&&BattleEditor_PointInRect(mx,my,430,318,628,342)) inspector_step.gb_move_sound=!inspector_step.gb_move_sound;
                else if(inspector_step.property=="damage_type"&&BattleEditor_PointInRect(mx,my,430,312,628,334)) inspector_step.damage_change_visual=!inspector_step.damage_change_visual;
                else if(inspector_step.property=="follow"&&real(inspector_step.value)!=0&&BattleEditor_PointInRect(mx,my,510,312,628,336)){script_dropdown="control_follow_frame";script_target_scroll=0;}
                else if(inspector_step.target_type=="bone"&&inspector_step.property=="length"&&BattleEditor_PointInRect(mx,my,510,310,628,332)) script_dropdown="length_anchor";
                else if(inspector_step.property!="control_vertex"&&inspector_step.property!="position"&&inspector_step.property!="shape"&&inspector_step.property!="speak"&&inspector_step.property!="gb_hold"&&inspector_step.property!="gb_release"&&inspector_step.property!="aim_motion"&&BattleEditor_PointInRect(mx,my,510,282,628,304)){
                    if(inspector_step.property=="player_name"){focus_field="script_text_value";keyboard_string=inspector_step.text_value;}
                    else if(inspector_step.property=="aim_target_uid"){script_dropdown="aim_target_value";script_target_scroll=0;}
                    else if(inspector_step.property=="color"||inspector_step.property=="visual_color"||inspector_step.property=="color_frame") BattleEditor_OpenColorPicker(id,"script_value",inspector_step.value,1);
                    else if(BattleEditor_IsBooleanControlProperty(inspector_step.property)){
                        inspector_step.value=real(inspector_step.value)==0?1:0;
                        if(inspector_step.property=="follow") inspector_step.follow_value_initialized=true;
                    }
                    else if(BattleEditor_IsChoiceControlProperty(inspector_step.property)) script_dropdown="choice_value";
                    else{focus_field="script_value";keyboard_string=string(inspector_step.value);}
                }
                else{
                    var soul_system_control=inspector_step.target_type=="soul"&&(inspector_step.property=="soul_mode"||inspector_step.property=="blue_direction");
                    if(soul_system_control){
                        var soul_mode_selected=inspector_step.property=="soul_mode"?clamp(round(real(inspector_step.value)),0,6):1;
                        if(soul_mode_selected==1&&BattleEditor_PointInRect(mx,my,510,312,628,336)) script_dropdown="soul_blue_direction";
                        else if(soul_mode_selected==1&&BattleEditor_PointInRect(mx,my,430,342,628,366)) inspector_step.blue_gravity_throw=!inspector_step.blue_gravity_throw;
                    }else if(inspector_step.property!="physics"&&inspector_step.property!="aim_motion"&&BattleEditor_ControlStepUsesDuration(inspector_step)){
                        var inspector_bone_length=inspector_step.target_type=="bone"&&inspector_step.property=="length";
                        var inspector_timing_y=inspector_step.property=="control_vertex"?398:(inspector_step.property=="position"?400:(inspector_step.property=="orbit"?394:(inspector_step.property=="shape"?360:(inspector_bone_length?360:312))));
                        if(BattleEditor_PointInRect(mx,my,510,inspector_timing_y,628,inspector_timing_y+22)){focus_field="script_duration";keyboard_string=string(inspector_step.duration);}
                        else if(BattleEditor_PointInRect(mx,my,430,inspector_timing_y+28,528,inspector_timing_y+50)) script_dropdown="tween";
                        else if(BattleEditor_PointInRect(mx,my,532,inspector_timing_y+28,628,inspector_timing_y+50)) script_dropdown="ease";
                    }
                }
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="wait"){
                if(BattleEditor_PointInRect(mx,my,430,234,628,258)) script_dropdown="wait_mode";
                else if(round(real(inspector_step.wait_mode))==0&&BattleEditor_PointInRect(mx,my,430,296,628,320)){focus_field="script_duration";keyboard_string=string(inspector_step.duration);}
                else if(round(real(inspector_step.wait_mode))==1&&BattleEditor_PointInRect(mx,my,430,296,628,320)){focus_field="script_wait_extra_duration";keyboard_string=string(inspector_step.wait_extra_duration);}
            }
            else if(!is_undefined(inspector_step)&&inspector_step.kind=="builtin_action"){
                var builtin_follow_available=BattleEditor_BuiltinActionCanFollow(inspector_step.action_name);
                if(inspector_step.action_name=="bone_function_path"&&BattleEditor_PointInRect(mx,my,566,234,628,256)){
                    script_function_preview_uid=script_function_preview_uid==inspector_step.uid?-1:inspector_step.uid;
                    script_function_preview_dirty=true;
                    status_text=script_function_preview_uid==inspector_step.uid?"已显示函数轨迹预览；修改公式后会自动刷新":"已关闭函数轨迹预览";
                }
                else if(builtin_follow_available&&BattleEditor_PointInRect(mx,my,inspector_step.action_name=="bone_function_path"?504:546,234,inspector_step.action_name=="bone_function_path"?562:628,256)){
                    inspector_step.action_follow=!inspector_step.action_follow;
                    status_text=inspector_step.action_follow?"这组内建对象会跟随主战斗框":"这组内建对象使用独立世界坐标";
                }
                else if(BattleEditor_PointInRect(mx,my,430,234,inspector_step.action_name=="bone_function_path"?500:(builtin_follow_available?542:628),256)) script_dropdown="builtin_action";
                else if(BattleEditor_BuiltinActionHasDamageColor(inspector_step.action_name)&&BattleEditor_PointInRect(mx,my,430,430,628,450)) inspector_step.action_damage_change_visual=!inspector_step.action_damage_change_visual;
                else if(inspector_step.action_name=="board_shape"&&BattleEditor_PointInRect(mx,my,430,264,628,424)){
                    var board_shape_row=floor((my-264)/32);
                    if(board_shape_row==0){script_dropdown="board_shape_target";script_target_scroll=0;}
                    else if(board_shape_row==1){script_parameter_choice_scope="builtin";script_parameter_choice_index=0;script_dropdown="parameter_choice";}
                    else if(board_shape_row==2){focus_field="script_action_param_1";keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,1,BattleEditor_BuiltinActionDefaults("board_shape"));}
                    else if(board_shape_row==3) script_dropdown="tween";
                    else if(board_shape_row==4) script_dropdown="ease";
                }
                else if(inspector_step.action_name=="bone_orbit"&&BattleEditor_PointInRect(mx,my,430,264,628,432)){
                    var orbit_row=script_parameter_scroll+floor((my-264)/28);
                    if(orbit_row==0){focus_field="script_action_control_id";keyboard_string=inspector_step.action_control_id;}
                    else if(orbit_row==1){script_dropdown="action_template";script_template_scroll=0;}
                    else if(orbit_row==2||orbit_row==3){
                        var orbit_pair_start=orbit_row==2?0:2;
                        var orbit_pair_index=mx<548?orbit_pair_start:orbit_pair_start+1;
                        focus_field="script_action_param_"+string(orbit_pair_index);keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_index,BattleEditor_BuiltinActionDefaults("bone_orbit"));
                    }else if(orbit_row==4||orbit_row==5){
                        var orbit_pair_start=orbit_row==4?4:6;
                        var orbit_pair_index=mx<522?orbit_pair_start:orbit_pair_start+1;
                        focus_field="script_action_param_"+string(orbit_pair_index);keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_index,BattleEditor_BuiltinActionDefaults("bone_orbit"));
                    }else if(orbit_row==6){focus_field="script_action_param_8";keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,8,BattleEditor_BuiltinActionDefaults("bone_orbit"));}
                    else if(orbit_row==7){script_parameter_choice_scope="builtin";script_parameter_choice_index=mx<526?12:13;script_dropdown="parameter_choice";}
                    else if(orbit_row==8||orbit_row==10){
                        var orbit_entry=orbit_row==8;
                        if(mx<512){var orbit_time_index=orbit_entry?9:11;focus_field="script_action_param_"+string(orbit_time_index);keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_time_index,BattleEditor_BuiltinActionDefaults("bone_orbit"));}
                        else if(mx<572) script_dropdown=orbit_entry?"tween":"action_exit_tween";
                        else script_dropdown=orbit_entry?"ease":"action_exit_ease";
                    }else if(orbit_row==9){focus_field="script_action_param_10";keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,10,BattleEditor_BuiltinActionDefaults("bone_orbit"));}
                }
                else if(inspector_step.action_name=="bone_wall"&&BattleEditor_PointInRect(mx,my,430,264,628,432)){
                    var wall_parameter_row=script_parameter_scroll+floor((my-264)/28);
                    if(wall_parameter_row==0){focus_field="script_action_control_id";keyboard_string=inspector_step.action_control_id;}
                    else if(wall_parameter_row==1) script_dropdown="builtin_wall_direction";
                    else if(wall_parameter_row==2){script_dropdown="action_template";script_template_scroll=0;}
                    else if(wall_parameter_row==13) script_dropdown="tween";
                    else if(wall_parameter_row==14) script_dropdown="ease";
                    else if(wall_parameter_row==15) script_dropdown="action_exit_tween";
                    else if(wall_parameter_row==16) script_dropdown="action_exit_ease";
                    else if(wall_parameter_row==17) inspector_step.warning_enabled=!inspector_step.warning_enabled;
                    else if(wall_parameter_row==18){focus_field="script_warning_duration";keyboard_string=string(inspector_step.warning_duration);}
                    else if(wall_parameter_row>=3&&wall_parameter_row<=12){
                        var wall_parameter_index=wall_parameter_row-3;
                        if(wall_parameter_index==8) script_dropdown="builtin_wall_color";
                        else if(wall_parameter_index==9) script_dropdown="builtin_wall_layer";
                        else{
                            focus_field="script_action_param_"+string(wall_parameter_index);
                            keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,wall_parameter_index,BattleEditor_BuiltinActionDefaults("bone_wall"));
                        }
                    }
                }
                else if(BattleEditor_PointInRect(mx,my,430,264,628,432)){
                    var action_labels=BattleEditor_ActionParameterLabels("builtin",inspector_step.action_name);
                    var action_is_path=inspector_step.action_name=="bone_function_path";
                    var action_path_existing=action_is_path&&round(real(inspector_step.action_path_mode))==1;
                    var action_has_template=BattleEditor_BuiltinActionUsesTemplate(inspector_step.action_name)&&!action_path_existing;
                    var action_prefix_rows=action_is_path?(action_path_existing?2:3):(1+(action_has_template?1:0));
                    var action_row=script_parameter_scroll+floor((my-264)/42);
                    if(action_is_path&&action_row==0) script_dropdown="function_path_mode";
                    else if(action_is_path&&action_row==1){
                        if(action_path_existing){script_dropdown="function_path_target";script_target_scroll=0;}
                        else{focus_field="script_action_control_id";keyboard_string=inspector_step.action_control_id;}
                    }
                    else if(action_is_path&&!action_path_existing&&action_row==2){script_dropdown="action_template";script_template_scroll=0;}
                    else if(!action_is_path&&action_row==0){focus_field="script_action_control_id";keyboard_string=inspector_step.action_control_id;}
                    else if(!action_is_path&&action_has_template&&action_row==1){script_dropdown="action_template";script_template_scroll=0;}
                    else{
                        var action_parameter_index=action_row-action_prefix_rows;
                        if(action_parameter_index<array_length(action_labels)){
                            var action_parameter_kind=BattleEditor_ActionParameterKind("builtin",inspector_step.action_name,action_parameter_index);
                            if(action_parameter_kind=="identifier"){
                                focus_field="script_action_path_variable";
                                keyboard_string=inspector_step.action_path_variable;
                            }else if(action_parameter_kind=="expression"){
                                focus_field="script_action_param_"+string(action_parameter_index);
                                keyboard_string=BattleEditor_ActionArgumentText(inspector_step.action_arguments,action_parameter_index,BattleEditor_BuiltinActionDefaults(inspector_step.action_name));
                            }else{
                                script_parameter_choice_scope="builtin";script_parameter_choice_index=action_parameter_index;script_dropdown="parameter_choice";
                            }
                        }
                    }
                }
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="screen_control"){
                if(BattleEditor_PointInRect(mx,my,430,234,628,256)){script_dropdown="screen_action";script_screen_action_scroll=0;}
                else if(BattleEditor_PointInRect(mx,my,430,264,628,432)){
                    var screen_labels=BattleEditor_ActionParameterLabels("screen",inspector_step.screen_action);
                    var screen_row=script_parameter_scroll+floor((my-264)/42);
                    if(screen_row<array_length(screen_labels)){
                        var screen_parameter_kind=BattleEditor_ActionParameterKind("screen",inspector_step.screen_action,screen_row);
                        var screen_parameter_value=BattleEditor_ActionArgumentText(inspector_step.screen_arguments,screen_row,BattleEditor_ScreenActionDefaults(inspector_step.screen_action));
                        if(screen_parameter_kind=="boolean") inspector_step.screen_arguments=BattleEditor_ActionArgumentsSet(inspector_step.screen_arguments,screen_row,BattleEditor_ReadNumberText(screen_parameter_value,0)==0?1:0,BattleEditor_ScreenActionDefaults(inspector_step.screen_action));
                        else{focus_field="script_screen_param_"+string(screen_row);keyboard_string=screen_parameter_value;}
                    }else if(inspector_step.screen_action=="camera_set"&&screen_row==array_length(screen_labels)) script_dropdown="tween";
                    else if(inspector_step.screen_action=="camera_set"&&screen_row==array_length(screen_labels)+1) script_dropdown="ease";
                }
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="play_sound"){
                if(BattleEditor_PointInRect(mx,my,430,234,594,258)){script_dropdown="sound_name";script_sound_scroll=0;}
                else if(BattleEditor_PointInRect(mx,my,600,234,628,258)) BattleEditor_AudioPreviewToggleNamed(id,inspector_step.sound_name,"workspace_"+string(inspector_step.uid));
                else if(BattleEditor_PointInRect(mx,my,430,292,628,316)) script_dropdown="sound_timing";
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="enemy_appearance"){
                if(BattleEditor_PointInRect(mx,my,430,234,628,258)) script_dropdown="enemy_target";
                else if(BattleEditor_PointInRect(mx,my,510,270,628,294)) script_dropdown="enemy_part_key";
                else if(BattleEditor_PointInRect(mx,my,430,326,628,350)){script_enemy_resource_scroll=0;script_dropdown="enemy_resource";}
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="get_value"){
                if(BattleEditor_PointInRect(mx,my,430,234,628,258)){script_dropdown="value_target";script_value_target_scroll=0;}
                else if(BattleEditor_PointInRect(mx,my,510,270,628,294)){script_dropdown="value_property";script_value_property_scroll=0;}
                else if(BattleEditor_PointInRect(mx,my,510,306,628,330)){focus_field="script_read_variable_name";keyboard_string=inspector_step.read_variable_name;}
                else if((!BattleEditor_IsVariableIdentifier(inspector_step.read_variable_name)||BattleEditor_IsReservedVariableName(inspector_step.read_variable_name))&&BattleEditor_PointInRect(mx,my,430,382,628,406)){focus_field="script_read_variable_name";keyboard_string=inspector_step.read_variable_name;status_text="请输入有效且非系统保留的新变量名";}
                else if(BattleEditor_VariableNameConflict(project,inspector_step.read_variable_name,inspector_step.uid)&&!inspector_step.read_overwrite_confirmed&&BattleEditor_PointInRect(mx,my,430,382,526,406)){
                    inspector_step.read_overwrite_confirmed=true;status_text="已允许覆盖同名变量；原值会在执行到此项时丢失";
                }else if(BattleEditor_VariableNameConflict(project,inspector_step.read_variable_name,inspector_step.uid)&&!inspector_step.read_overwrite_confirmed&&BattleEditor_PointInRect(mx,my,532,382,628,406)){
                    focus_field="script_read_variable_name";keyboard_string=inspector_step.read_variable_name;status_text="请输入新的变量名";
                }else if(inspector_step.read_overwrite_confirmed&&BattleEditor_PointInRect(mx,my,430,382,628,406)) inspector_step.read_overwrite_confirmed=false;
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="set_variable"){
                if(BattleEditor_PointInRect(mx,my,430,234,628,256)){focus_field="script_variable_name";keyboard_string=inspector_step.variable_name;}
                else if(BattleEditor_PointInRect(mx,my,510,270,628,292)) script_dropdown="variable_operation";
                else if(BattleEditor_PointInRect(mx,my,430,322,628,344)){focus_field="script_expression";keyboard_string=inspector_step.expression;}
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="condition"){
                if(BattleEditor_PointInRect(mx,my,510,212,628,234)){focus_field="script_condition_left";keyboard_string=inspector_step.condition_left;}
                else if(BattleEditor_PointInRect(mx,my,510,242,628,264)) script_dropdown="condition_operator";
                else if(BattleEditor_PointInRect(mx,my,510,272,628,294)){focus_field="script_condition_right";keyboard_string=inspector_step.condition_right;}
                else if(BattleEditor_PointInRect(mx,my,550,302,628,324)){focus_field="script_skip_count";keyboard_string=string(inspector_step.skip_count);}
            }else if(!is_undefined(inspector_step)&&inspector_step.kind=="repeat"){
                if(BattleEditor_PointInRect(mx,my,540,212,628,234)){focus_field="script_repeat_count";keyboard_string=inspector_step.repeat_count;}
                else if(BattleEditor_PointInRect(mx,my,550,242,628,264)){focus_field="script_repeat_length";keyboard_string=string(inspector_step.repeat_length);}
                else if(BattleEditor_PointInRect(mx,my,550,272,628,294)){focus_field="script_repeat_interval";keyboard_string=string(inspector_step.repeat_interval);}
            }
        }
    }
    if(script_inspector_consumed) exit;

    if(click&&!script_context_open&&my>=32){
        var started_link=false;
        for(var li=array_length(project.script_lists)-1;li>=0&&!started_link;li--){
            var list_data=project.script_lists[li];
            var px=script_pan_x+(list_data.world_x+238)*script_zoom;
            for(var si=0;si<array_length(list_data.steps);si++){
                var py=script_pan_y+(list_data.world_y+BattleEditor_WorkspaceHeaderHeight(list_data)+si*48+24)*script_zoom;
                if(list_data.steps[si].kind=="start_list"&&point_distance(mx,my,px,py)<=max(8,10*script_zoom)){
                    script_link_drag=true;script_link_source_list=li;script_link_source_step=si;started_link=true;break;
                }
            }
        }
        if(!started_link){
            var hit=BattleEditor_WorkspaceHit(id,mx,my);
            BattleEditor_RequestScriptSelection(id,hit.list_index,hit.step_index);
            if(hit.list_index>=0){
                var picked=project.script_lists[hit.list_index];
                var px=script_pan_x+picked.world_x*script_zoom,py=script_pan_y+picked.world_y*script_zoom;
                if(hit.header&&BattleEditor_PointInRect(mx,my,px+190*script_zoom,py+4*script_zoom,px+232*script_zoom,py+30*script_zoom)){
                    BattleEditor_RuntimeStartList(id,picked.uid);
                    if(project.settings.auto_switch_to_objects_on_run){tab=0;tool=0;object_palette=false;hazard_palette=false;board_palette=false;}
                    status_text="正在运行列表："+picked.name;exit;
                }
                if(hit.header||hit.step_index>=0){
                    var first=max(0,hit.step_index);
                    BattleEditor_WorkspaceBeginDrag(id,hit.header?"list":"tail",picked.uid,first,"",-1,mx,my,
                        workspace_world_x-picked.world_x,
                        workspace_world_y-picked.world_y-(hit.header?0:BattleEditor_WorkspaceHeaderHeight(picked)+first*48));
                }
            }else{
                script_drag_mode="canvas";script_drag_offset_x=mx-script_pan_x;script_drag_offset_y=my-script_pan_y;
            }
        }
    }
    if(workspace_left_down&&script_drag_mode=="canvas"){
        script_pan_x=mx-script_drag_offset_x;script_pan_y=my-script_drag_offset_y;
    }
    if(workspace_left_released){
        if(script_link_drag&&script_link_source_list>=0&&script_link_source_step>=0){
            var linked=false;
            for(var li=array_length(project.script_lists)-1;li>=0;li--){
                var target=project.script_lists[li];
                if(!BattleEditor_WorkspaceHasHeader(target)) continue;
                var px=script_pan_x+target.world_x*script_zoom,py=script_pan_y+(target.world_y+17)*script_zoom;
                if(point_distance(mx,my,px,py)<=max(10,12*script_zoom)){
                    project.script_lists[script_link_source_list].steps[script_link_source_step].target_list_uid=target.uid;
                    BattleEditor_WorkspaceChanged(id);status_text="列表连接完成："+target.name;linked=true;break;
                }
            }
            if(!linked) status_text="未连接：请拖到事件头左侧端口；游离积木不能执行";
        }
        script_link_drag=false;script_link_source_list=-1;script_link_source_step=-1;script_drag_mode="";
    }
}else if(tab==3){
    if(developer_turn_dropdown){
        if(click){
            var dropdown_turns=BattleEditor_GetKnownTurns(project);
            var dropdown_row=floor((my-216)/24);
            var developer_turn_chosen=BattleEditor_PointInRect(mx,my,336,216,546,216+array_length(dropdown_turns)*24)&&dropdown_row>=0&&dropdown_row<array_length(dropdown_turns);
            if(developer_turn_chosen){
                BattleEditor_SetAuthoringTurn(id,dropdown_turns[dropdown_row]);
                status_text="正在编辑第 "+string(developer_turn)+" 回合";
            }
            developer_turn_dropdown=false;
            if(!developer_turn_chosen&&!BattleEditor_PointInRect(mx,my,336,186,546,212)){
                deferred_click=true;deferred_click_x=mx;deferred_click_y=my;
            }
        }
        exit;
    }
    if(click&&BattleEditor_PointInRect(mx,my,94,146,546,172)){
        project.settings.developer_force_turn=!project.settings.developer_force_turn;
        status_text=project.settings.developer_force_turn?"下一次怪物回合将强制使用第 "+string(project.settings.developer_turn)+" 回合":"已恢复正常回合顺序";
    }else if(click&&BattleEditor_PointInRect(mx,my,194,186,330,212)){
        focus_field="developer_turn";keyboard_string=string(project.settings.developer_turn);
    }else if(click&&BattleEditor_PointInRect(mx,my,336,186,546,212)){
        developer_turn_dropdown=true;
    }else if(click&&BattleEditor_PointInRect(mx,my,94,238,546,266)){
        project.settings.developer_force_default_board=!project.settings.developer_force_default_board;
        status_text=project.settings.developer_force_default_board?"怪物回合测试将使用 130 x 130 预设方框":"怪物回合恢复项目主框";
    }else if(click&&BattleEditor_PointInRect(mx,my,94,274,546,302)){
        project.settings.auto_switch_to_objects_on_run=!project.settings.auto_switch_to_objects_on_run;
        status_text=project.settings.auto_switch_to_objects_on_run?"运行列表后切到对象页":"运行列表后留在脚本页";
    }else if(click) developer_turn_dropdown=false;
}else if(tab==4){
    var help_max_scroll=max(0,(help_layout_ready?help_content_height_cache:BattleEditor_HelpContentHeight())-390);
    if(mouse_wheel_up()) help_scroll=max(0,help_scroll-54);
    if(mouse_wheel_down()) help_scroll=min(help_max_scroll,help_scroll+54);
    if(click&&BattleEditor_PointInRect(mx,my,520,450,628,472)){
        help_scroll=0;
        status_text="已回到教学目录";
    }else if(click){
        var help_sections=help_layout_ready?help_sections_cache:BattleEditor_HelpSections();
        var help_content_y=my+help_scroll;
        for(var help_index=0;help_index<array_length(help_sections);help_index++){
            if(BattleEditor_PointInRect(mx,help_content_y,22,94+help_index*22,318,114+help_index*22)){
                var help_target_offset=help_layout_ready?help_section_offsets[help_index]:BattleEditor_HelpSectionOffset(help_index);
                help_scroll=clamp(help_target_offset-50,0,help_max_scroll);
                status_text="教学："+help_sections[help_index].title;
                break;
            }
        }
    }
    exit;
}

if(focus_field!=""){
    BattleEditor_SetInputCapture(true);
}
if(keyboard_check_pressed(vk_escape)){
    BattleEditor_RuntimeStop(id);
    BattleEditor_RestoreAuthoringBoard(id);
    board_edit_session=false;
    status_text="已返回玩家回合";
}else if(keyboard_check_pressed(vk_space)){
    BattleEditor_RuntimeStart(id);
    // An empty timeline is still a valid board/physics preview.  It has no
    // calculable end time, so remain in playback until Space/Escape is pressed
    // again instead of starting and pausing in the very same Step event.
    if(timeline_effective_duration_cache<=0) status_text="空回合正在播放；空格或 Esc 暂停";
}
