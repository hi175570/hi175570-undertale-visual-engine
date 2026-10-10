draw_set_font(font_menu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// During a real turn, turn_test owns the runtime.  During a one-shot typer
// preview only the actual battle and typer should be visible.
if(text_editor_preview_mode) exit;
if(instance_exists(turn_test)&&instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.IN_TURN) exit;
// Full playback represents the hidden monster turn. Timeline seeking is the
// separate UI-visible half-play mode, so its progress and frozen frame remain
// editable.
if(playing&&!timeline_seek_active) exit;

// Normal Draw contributes only game-visible authoring content to post effects.
// The compositor invokes this same event once more for the editor-only pass.
if(!editor_ui_drawing){
    if(tab==0&&!enemy_editor_open) BattleEditor_DrawAuthoringContent(id,false);
    exit;
}
var editor_mouse=Window_ContentMouse();

// A menu's click handler commits its value immediately, but the visual menu
// retracts afterward. Temporarily restore the outgoing menu snapshot for this
// Draw only; its real logical state is restored before the toolbar is drawn.
var dropdown_draw_restore=undefined;
if(!enemy_editor_open&&dropdown_anim_key!=""&&dropdown_anim_progress>0&&is_struct(dropdown_anim_snapshot)){
    var draw_live_dropdown_key="";
    if(script_dropdown!="") draw_live_dropdown_key="script:"+script_dropdown;
    else if(font_dropdown_open) draw_live_dropdown_key="font:"+font_dropdown_target;
    else if(damage_dropdown_open) draw_live_dropdown_key="damage_type";
    else if(gb_spawn_dropdown_open) draw_live_dropdown_key="gb_spawn";
    else if(gb_style_dropdown_open) draw_live_dropdown_key="gb_style";
    else if(choice_menu_open) draw_live_dropdown_key="choice:"+choice_menu_context;
    else if(follow_dropdown_open) draw_live_dropdown_key="follow_frame";
    else if(aim_dropdown_open) draw_live_dropdown_key="aim_target";
    else if(clip_editor_open) draw_live_dropdown_key="clip_frames";
    else if(initialization_turn_dropdown) draw_live_dropdown_key="initialization_turn";
    else if(battle_music_dropdown_open) draw_live_dropdown_key="battle_music";
    else if(developer_turn_dropdown) draw_live_dropdown_key="developer_turn";
    else if(object_palette_category_open) draw_live_dropdown_key="object_palette_category";
    if(draw_live_dropdown_key!=dropdown_anim_key){
        dropdown_anim_closing=true;
        dropdown_draw_restore={
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
        script_dropdown=dropdown_anim_snapshot.script_dropdown;
        font_dropdown_open=dropdown_anim_snapshot.font_dropdown_open;font_dropdown_target=dropdown_anim_snapshot.font_dropdown_target;font_dropdown_scroll=dropdown_anim_snapshot.font_dropdown_scroll;
        damage_dropdown_open=dropdown_anim_snapshot.damage_dropdown_open;damage_dropdown_event=dropdown_anim_snapshot.damage_dropdown_event;
        gb_spawn_dropdown_open=dropdown_anim_snapshot.gb_spawn_dropdown_open;gb_spawn_dropdown_event=dropdown_anim_snapshot.gb_spawn_dropdown_event;gb_spawn_dropdown_scroll=dropdown_anim_snapshot.gb_spawn_dropdown_scroll;
        gb_style_dropdown_open=dropdown_anim_snapshot.gb_style_dropdown_open;gb_style_dropdown_event=dropdown_anim_snapshot.gb_style_dropdown_event;gb_style_dropdown_scroll=dropdown_anim_snapshot.gb_style_dropdown_scroll;
        choice_menu_open=dropdown_anim_snapshot.choice_menu_open;choice_menu_context=dropdown_anim_snapshot.choice_menu_context;choice_menu_kind=dropdown_anim_snapshot.choice_menu_kind;choice_menu_event=dropdown_anim_snapshot.choice_menu_event;choice_menu_phase=dropdown_anim_snapshot.choice_menu_phase;choice_menu_scroll=dropdown_anim_snapshot.choice_menu_scroll;
        follow_dropdown_open=dropdown_anim_snapshot.follow_dropdown_open;follow_dropdown_event=dropdown_anim_snapshot.follow_dropdown_event;follow_dropdown_scroll=dropdown_anim_snapshot.follow_dropdown_scroll;
        aim_dropdown_open=dropdown_anim_snapshot.aim_dropdown_open;aim_dropdown_event=dropdown_anim_snapshot.aim_dropdown_event;aim_dropdown_scroll=dropdown_anim_snapshot.aim_dropdown_scroll;
        clip_editor_open=dropdown_anim_snapshot.clip_editor_open;clip_editor_event=dropdown_anim_snapshot.clip_editor_event;clip_editor_scroll=dropdown_anim_snapshot.clip_editor_scroll;clip_editor_filter=dropdown_anim_snapshot.clip_editor_filter;
        initialization_turn_dropdown=dropdown_anim_snapshot.initialization_turn_dropdown;battle_music_dropdown_open=dropdown_anim_snapshot.battle_music_dropdown_open;battle_music_scroll=dropdown_anim_snapshot.battle_music_scroll;
        developer_turn_dropdown=dropdown_anim_snapshot.developer_turn_dropdown;object_palette_category_open=dropdown_anim_snapshot.object_palette_category_open;
    }
}

function _editor_button(x1,y1,x2,y2,label,active=false){
    var workspace_style=tab==2&&workspace_open&&x1>=420&&y1>=36;
    draw_set_alpha(0.92*ui_menu_alpha);
    draw_set_color(workspace_style?(active?make_color_rgb(43,66,86):make_color_rgb(25,35,48)):(active?make_color_rgb(74,64,10):make_color_rgb(18,18,18)));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,false);else draw_rectangle(x1,y1,x2,y2,false);
    draw_set_alpha(ui_menu_alpha);
    draw_set_color(workspace_style?(active?make_color_rgb(141,196,237):make_color_rgb(62,82,105)):(active?c_yellow:c_white));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,true);else draw_rectangle(x1,y1,x2,y2,true);
    if(workspace_style) draw_set_color(c_white);
    var button_text=string(label);
    var button_has_dropdown=string_pos("▼",button_text)>0;
    button_text=string_replace_all(button_text,"▼","");
    var button_available=max(0,x2-x1-7-(button_has_dropdown?18:0));
    button_text=TextTyper_EllipsisFallback(button_text,button_available);
    TextTyper_DrawFallback(x1+3,y1+3,button_text);
    if(button_has_dropdown) draw_sprite_ext(spr_editor_ui_dropdown,0,x2-10,(y1+y2)*0.5,0.65,0.65,0,active?c_yellow:c_white,ui_menu_alpha);
}

function _editor_icon_button(x1,y1,x2,y2,sprite_id,active=false){
    var workspace_style=tab==2&&workspace_open&&x1>=420&&y1>=36;
    draw_set_alpha(0.92*ui_menu_alpha);
    draw_set_color(workspace_style?make_color_rgb(25,35,48):(active?make_color_rgb(74,64,10):make_color_rgb(18,18,18)));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,false);else draw_rectangle(x1,y1,x2,y2,false);
    draw_set_alpha(ui_menu_alpha);draw_set_color(workspace_style?make_color_rgb(101,146,182):(active?c_yellow:c_white));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,true);else draw_rectangle(x1,y1,x2,y2,true);
    draw_sprite_ext(sprite_id,0,(x1+x2)*0.5,(y1+y2)*0.5,0.72,0.72,0,active?c_yellow:c_white,ui_menu_alpha);
}

function _editor_menu_frame(x1,y1,x2,y2){
    draw_set_alpha(ui_menu_alpha);draw_set_color(make_color_rgb(21,31,44));
    draw_roundrect_ext(x1,y1,x2,y2,6,6,false);
    draw_set_color(make_color_rgb(93,124,155));draw_roundrect_ext(x1,y1,x2,y2,6,6,true);
    draw_set_color(c_white);
}

// Every value-selecting dropdown uses the same persistent selection marker.
// A filled row alone was too easy to miss among coloured menu entries, so the
// current value also receives an explicit one-pixel yellow frame.
function _editor_dropdown_selection(x1,y1,x2,y2,selected){
    if(!selected) return;
    if(tab==2&&workspace_open){
        draw_set_color(make_color_rgb(43,62,82));draw_roundrect_ext(x1,y1,x2,y2,4,4,false);
        draw_set_color(make_color_rgb(145,196,236));draw_roundrect_ext(x1,y1,x2,y2,4,4,true);
        return;
    }
    draw_set_color(make_color_rgb(74,64,10));
    draw_rectangle(x1,y1,x2,y2,false);
    draw_set_color(c_yellow);
    draw_rectangle(x1,y1,x2,y2,true);
}

function _editor_audio_preview_button(x1,y1,x2,y2,preview_key){
    var preview_playing=audio_preview_handle>=0&&audio_is_playing(audio_preview_handle)&&audio_preview_source==preview_key;
    _editor_icon_button(x1,y1,x2,y2,preview_playing?spr_editor_ui_stop:spr_editor_ui_play,preview_playing);
    var preview_hint=preview_playing?"停止":"播放";
    // The next inspector row starts ten pixels below the icon button. Keep the
    // hint inside that gap so it remains a caption rather than overlapping the
    // next control.
    var preview_hint_scale=0.52;
    var preview_hint_width=TextTyper_StringWidthFallback(preview_hint)*preview_hint_scale;
    draw_set_color(c_ltgray);
    TextTyper_DrawFallbackTransformed((x1+x2-preview_hint_width)*0.5,y2+1,preview_hint,preview_hint_scale,preview_hint_scale,0);
}

function _editor_field(x1,y1,x2,y2,value,field_id){
    var hex_editor_active=field_id=="text_editor_hex"&&text_editor_open&&text_editor_focus=="hex";
    var active=focus_field==field_id||hex_editor_active;
    var formula_field=BattleEditor_IsFormulaField(field_id);
    if(formula_field) array_push(formula_field_hit_regions,{field:field_id,x1:x1,y1:y1,x2:x2,y2:y2});
    array_push(input_field_hit_regions,{field:field_id,x1:x1,y1:y1,x2:x2,y2:y2});
    draw_set_alpha(ui_menu_alpha);
    var workspace_style=tab==2&&workspace_open&&x1>=420&&y1>=36;
    draw_set_color(workspace_style?make_color_rgb(14,22,32):make_color_rgb(8,8,8));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,false);else draw_rectangle(x1,y1,x2,y2,false);
    var formula_invalid=active&&formula_field&&string_length(string_trim(focus_edit_buffer))>0&&!focus_formula_validation.valid;
    draw_set_color(formula_invalid?c_red:(workspace_style?(active?make_color_rgb(141,196,237):make_color_rgb(62,82,105)):(active?c_yellow:c_white)));
    if(workspace_style) draw_roundrect_ext(x1,y1,x2,y2,5,5,true);else draw_rectangle(x1,y1,x2,y2,true);
    if(workspace_style) draw_set_color(c_white);
    // While focused, show the uncommitted edit buffer verbatim.  This permits
    // an empty field and expressions such as 300+10 without rewriting the
    // underlying number on every key press.
    var field_source=hex_editor_active?string(text_editor_hex):(focus_field==field_id?string(focus_edit_buffer):string(value));
    var field_caret=hex_editor_active?text_editor_hex_caret:(focus_field==field_id?focus_edit_caret:string_length(field_source));
    var field_layout=BattleEditor_SingleLineLayout(field_source,field_caret,x2-x1-9);
    var visible_text=field_layout.text;
    var visible_start=field_layout.start;
    var visible_caret=field_layout.caret;
    TextTyper_DrawFallback(x1+4,y1+3,visible_text);
    if(active&&((current_time div 450) mod 2)==0){
        var caret_char_count=clamp(visible_caret-visible_start+1,0,string_length(visible_text));
        var caret_prefix=caret_char_count>0?string_copy(visible_text,1,caret_char_count):"";
        var caret_x=min(x2-3,x1+4+TextTyper_StringWidthFallback(caret_prefix));
        draw_line(caret_x,y1+3,caret_x,y2-3);
    }
}

function _editor_color_button(x1,y1,x2,y2,color,label=""){
    draw_set_alpha(0.96*ui_menu_alpha);draw_set_color(make_color_rgb(14,14,16));draw_rectangle(x1,y1,x2,y2,false);
    draw_set_alpha(ui_menu_alpha);draw_set_color(c_white);draw_rectangle(x1,y1,x2,y2,true);
    draw_set_color(color);draw_rectangle(x1+3,y1+3,min(x1+21,x2-3),y2-3,false);
    if(x2-x1>=48){
        draw_set_color(c_white);
        var color_label=label==""?BattleEditor_ColorToHex(color,255):label;
        TextTyper_DrawFallback(x1+25,y1+3,color_label);
    }
}

function _editor_ellipsis(text_value,available_width){
    return TextTyper_EllipsisFallback(text_value,available_width);
}

// Initialization uses the same visual grammar on every page: a yellow section
// title followed by a quiet divider.  This makes groups readable without
// inventing more nested pages or changing any stored data.
function _editor_section(y,label){
    draw_set_color(c_yellow);
    TextTyper_DrawFallback(22,y,label);
    draw_set_color(make_color_rgb(72,72,76));
    draw_line(min(610,34+TextTyper_StringWidthFallback(label)),y+10,624,y+10);
}

function _editor_bezier(x1,y1,x2,y2,line_color,line_width=2){
    var bend=max(28,abs(x2-x1)*0.42);
    var c1x=x1+bend,c1y=y1;
    var c2x=x2-bend,c2y=y2;
    var last_x=x1,last_y=y1;
    draw_set_color(line_color);
    for(var segment=1;segment<=20;segment++){
        var t=segment/20;
        var omt=1-t;
        var px=omt*omt*omt*x1+3*omt*omt*t*c1x+3*omt*t*t*c2x+t*t*t*x2;
        var py=omt*omt*omt*y1+3*omt*omt*t*c1y+3*omt*t*t*c2y+t*t*t*y2;
        draw_line_width(last_x,last_y,px,py,line_width);
        last_x=px;last_y=py;
    }
}

function _editor_toolbar(){
    if(tab==2&&workspace_open) return;
    _editor_button(4,4,68,28,"初始化",tab==1);
    // Selection opens an inspector, not the creation menu. Keeping this button
    // highlighted after selecting an object made the closed palette look stuck.
    _editor_button(71,4,159,28,"新对象",object_palette||hazard_palette||board_palette||tool>=1&&tool<=17);
    _editor_button(162,4,210,28,"脚本",tab==2);
    _editor_button(213,4,261,28,"播放",playing);
    _editor_button(264,4,363,28,"存档",file_confirm_action!="");
    _editor_button(366,4,414,28,"退出",false);
    _editor_button(417,4,477,28,"开发者",tab==3);
    _editor_button(584,4,632,28,"?",tab==4);
}

// Rebuilt from the formula fields actually drawn this frame. Step uses these
// exact rectangles so a right-click menu never opens from unrelated blank UI.
formula_field_hit_regions=[];
input_field_hit_regions=[];

if(enemy_editor_open){
    draw_set_alpha(1);draw_set_color(make_color_rgb(9,10,13));draw_rectangle(0,0,640,480,false);
    draw_set_color(make_color_rgb(24,26,32));draw_rectangle(6,36,408,470,false);draw_set_color(c_gray);draw_rectangle(6,36,408,470,true);
    var enemy_canvas_old_scissor=gpu_get_scissor();
    BattleEditor_UiScissor(6,36,402,434);
    var enemy_grid_step=max(8,24*enemy_editor_zoom);
    var enemy_grid_start_x=6+(((enemy_editor_pan_x-6) mod enemy_grid_step)+enemy_grid_step) mod enemy_grid_step;
    var enemy_grid_start_y=36+(((enemy_editor_pan_y-36) mod enemy_grid_step)+enemy_grid_step) mod enemy_grid_step;
    for(var grid_x=enemy_grid_start_x;grid_x<408;grid_x+=enemy_grid_step){draw_set_color(make_color_rgb(30,32,38));draw_line(grid_x,36,grid_x,470);}
    for(var grid_y=enemy_grid_start_y;grid_y<470;grid_y+=enemy_grid_step){draw_set_color(make_color_rgb(30,32,38));draw_line(6,grid_y,408,grid_y);}
    var visual_enemy_count=array_length(project.initialization.enemies);
    if(visual_enemy_count>0){
        selected_enemy=clamp(selected_enemy,0,visual_enemy_count-1);
        var visual_enemy=project.initialization.enemies[selected_enemy];
        var visual_part_keys=BattleEditor_EnemyPartKeys();
        enemy_editor_selected_part=clamp(enemy_editor_selected_part,0,array_length(visual_part_keys)-1);
        var visual_part_key=visual_part_keys[enemy_editor_selected_part];
        var visual_part=variable_struct_get(visual_enemy.parts,visual_part_key);
        draw_set_color(make_color_rgb(48,54,65));draw_line(enemy_editor_pan_x,enemy_editor_pan_y-17,enemy_editor_pan_x,enemy_editor_pan_y+17);draw_line(enemy_editor_pan_x-17,enemy_editor_pan_y,enemy_editor_pan_x+17,enemy_editor_pan_y);
        BattleEditor_DrawEnemyVisual(visual_enemy,enemy_editor_cache,enemy_editor_pan_x,enemy_editor_pan_y,enemy_editor_preview_time,visual_part_key,enemy_editor_zoom);
        BattleEditor_UiScissor(enemy_canvas_old_scissor);
        draw_set_color(c_ltgray);TextTyper_DrawFallback(12,42,"拖部件；拖空白/中键平移；Ctrl+滚轮缩放 "+string(round(enemy_editor_zoom*100))+"%");
        draw_set_color(c_white);TextTyper_DrawFallback(12,8,"敌人可视化编辑 / "+visual_enemy.name);
        _editor_button(322,6,406,30,enemy_editor_preview_playing?"暂停预览":"播放预览",enemy_editor_preview_playing);
        _editor_button(548,6,634,30,"完成",false);

        draw_set_color(make_color_rgb(18,19,24));draw_rectangle(416,36,634,470,false);draw_set_color(c_gray);draw_rectangle(416,36,634,470,true);
        draw_set_color(c_gray);TextTyper_DrawFallback(424,46,"部件");
        _editor_button(424,64,626,88,BattleEditor_EnemyPartName(visual_part_key)+" ▼",enemy_editor_part_menu_open);
        draw_set_color(c_gray);TextTyper_DrawFallback(424,98,"角色资源（只显示当前角色目录）");
        _editor_button(424,116,626,140,BattleEditor_EnemyResourceCaption(project,visual_part.asset_uid)+" ▼",enemy_editor_resource_menu_open);
        _editor_button(424,146,522,170,"导入静态图",false);_editor_button(528,146,626,170,"新建动画",false);

        var visual_resource=BattleEditor_FindEnemyTextureResource(project,visual_part.asset_uid);
        if(!is_undefined(visual_resource)){
            draw_set_color(c_gray);TextTyper_DrawFallback(424,180,"资源名称");_editor_field(424,198,626,222,visual_resource.name,"enemy_resource_name");
            var visual_frame_count=array_length(visual_resource.animation.frames);
            draw_set_color(c_gray);TextTyper_DrawFallback(424,232,"动画帧："+string(visual_frame_count));
            _editor_button(520,228,626,252,"导入下一帧",false);
            if(visual_frame_count>0){
                enemy_editor_frame_index=clamp(enemy_editor_frame_index,0,visual_frame_count-1);
                _editor_button(424,258,462,282,"<",false);_editor_button(466,258,504,282,">",false);_editor_button(510,258,626,282,"删除当前帧",false);
                draw_set_color(c_ltgray);TextTyper_DrawFallback(424,288,string(enemy_editor_frame_index+1)+" / "+string(visual_frame_count)+"  "+filename_name(visual_resource.animation.frames[enemy_editor_frame_index]));
            }
            draw_set_color(c_gray);TextTyper_DrawFallback(424,314,"FPS");_editor_field(478,310,548,334,visual_resource.animation.fps,"enemy_animation_fps");
            _editor_button(554,310,626,334,visual_resource.animation.loop?"[X] 循环":"[ ] 循环",visual_resource.animation.loop);
        }
        draw_set_color(c_gray);TextTyper_DrawFallback(424,342,"局部 X / Y");_editor_field(424,360,522,382,visual_part.offset_x,"enemy_part_x");_editor_field(528,360,626,382,visual_part.offset_y,"enemy_part_y");
        TextTyper_DrawFallback(424,388,"资源原点 X / Y");_editor_field(424,406,522,428,visual_part.origin_x,"enemy_origin_x");_editor_field(528,406,626,428,visual_part.origin_y,"enemy_origin_y");
        TextTyper_DrawFallback(424,434,"整体缩放 X / Y");_editor_field(424,452,522,474,visual_enemy.scale_x,"enemy_scale_x");_editor_field(528,452,626,474,visual_enemy.scale_y,"enemy_scale_y");

        if(enemy_editor_part_menu_open){
            draw_set_color(make_color_rgb(8,8,8));draw_rectangle(424,90,626,90+array_length(visual_part_keys)*24,false);
            for(var part_menu_index=0;part_menu_index<array_length(visual_part_keys);part_menu_index++){
                var part_menu_y=90+part_menu_index*24;
                _editor_dropdown_selection(424,part_menu_y,626,part_menu_y+23,part_menu_index==enemy_editor_selected_part);
                draw_set_color(part_menu_index==enemy_editor_selected_part?c_yellow:c_white);TextTyper_DrawFallback(430,part_menu_y+3,BattleEditor_EnemyPartName(visual_part_keys[part_menu_index]));
            }
        }else if(enemy_editor_resource_menu_open){
            var resource_options=BattleEditor_EnemyTextureOptions(project,visual_enemy.uid,visual_part_key);
            var visible_resources=min(9,max(0,array_length(resource_options)-enemy_editor_resource_scroll));
            draw_set_color(make_color_rgb(8,8,8));draw_rectangle(424,142,626,142+visible_resources*24,false);
            for(var resource_row=0;resource_row<visible_resources;resource_row++){
                var resource_option=resource_options[enemy_editor_resource_scroll+resource_row];var resource_y=142+resource_row*24;
                _editor_dropdown_selection(424,resource_y,626,resource_y+23,resource_option.uid==visual_part.asset_uid);
                draw_set_color(resource_option.uid==visual_part.asset_uid?c_yellow:c_white);TextTyper_DrawFallback(430,resource_y+3,_editor_ellipsis(resource_option.name,188));
            }
        }
    }else{
        BattleEditor_UiScissor(enemy_canvas_old_scissor);
        draw_set_color(c_white);TextTyper_DrawFallback(24,72,"没有可编辑的敌人。");_editor_button(548,6,634,30,"完成",false);
    }
    exit;
}

if(tab==0){
    // Effective duration walks every authored event and every Workspace list.
    // Computing it again for each timeline tick made this page O(N^2) and
    // became visibly slow as the project accumulated objects. One snapshot is
    // sufficient for the complete Draw event.
    // Draw is a pure cache consumer. Duration is rebuilt only when Run/seek
    // actually needs an exact schedule (plus initial create/load).
    if(!variable_instance_exists(id,"timeline_duration_cache")) BattleEditor_RefreshDurationCache(id);
    var timeline_duration=timeline_duration_cache;
    draw_set_alpha(0.98);
    draw_set_color(make_color_rgb(18,18,18));
    draw_rectangle(18,33,456,55,false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(20,35,454,53,true);
    for(var i=0;i<array_length(project.events);i++){
        if(!BattleEditor_EventBelongsToTurn(project.events[i],developer_turn)) continue;
        var tx=20+clamp(project.events[i].time/timeline_duration,0,1)*434;
        var timeline_group_selected=group_selection_active&&selected>=0&&BattleEditor_IsSameEventGroup(project.events[selected],project.events[i]);
        draw_set_color(i==selected?c_yellow:(timeline_group_selected?c_aqua:c_white));
        draw_line(tx,37,tx,51);
    }
    var timeline_x=20+clamp((playing?playhead:cursor_time)/timeline_duration,0,1)*434;
    draw_set_color(c_red);
    draw_line(timeline_x,32,timeline_x,56);

    // Keep the clock beside the scrubber instead of making the author convert
    // raw logical frames.  The left value is the current cursor/playhead and
    // the right value is the complete authored duration.
    var timeline_state=playing?(timeline_seek_active?"定格":"播放"):(timeline_half_play?"定格":"编辑");
    var timeline_clock=timeline_state+"  "+BattleEditor_FormatTimelineTime(playing?playhead:cursor_time)+" / "+(timeline_duration_dirty?"待更新":BattleEditor_FormatTimelineTime(timeline_duration));
    draw_set_alpha(0.98);
    draw_set_color(make_color_rgb(18,18,18));
    draw_rectangle(464,33,638,55,false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    TextTyper_DrawFallback(468,36,timeline_clock);

    BattleEditor_DrawAuthoringContent(id,true);

    var draw_object_palette=object_palette;
    if(!draw_object_palette&&object_palette_anim_progress>0){
        object_palette_anim_closing=true;
        draw_object_palette=true;
    }
    if(!draw_object_palette){
        draw_set_alpha(0.98);
        draw_set_color(make_color_rgb(12,12,12));
        draw_rectangle(470,60,638,454,false);
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
    if(!draw_object_palette&&selected>=0){
        var header_object=project.events[selected];
        TextTyper_DrawFallback(478,66,"名称");
        _editor_field(514,64,632,82,header_object.name,"object_name");
        TextTyper_DrawFallback(478,88,"ID");
        _editor_field(510,86,570,104,header_object.control_id,"object_control_id");
        draw_set_color(make_color_rgb(80,180,255));
        var header_count=group_selection_active
            ?BattleEditor_EventGroupCount(project,group_selection_type,group_selection_control_id,header_object.control_uid,developer_turn)
            :BattleEditor_EventGroupCount(project,BattleEditor_DataTargetType(header_object),header_object.control_id,header_object.control_uid,developer_turn);
        TextTyper_DrawFallback(576,89,"共"+string(header_count));
    }else if(!draw_object_palette&&selected_frame>=-1){
        var header_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
        TextTyper_DrawFallback(478,66,"名称");
        _editor_field(514,64,632,82,header_frame.name,"frame_name");
        TextTyper_DrawFallback(478,88,"ID");
        _editor_field(510,86,570,104,header_frame.control_id,"frame_control_id");
        draw_set_color(make_color_rgb(80,180,255));
        TextTyper_DrawFallback(576,89,"共"+string(BattleEditor_ControlIdCount(project,header_frame.control_id)));
    }else if(!draw_object_palette){
        TextTyper_DrawFallback(478,66,"第 "+string(developer_turn)+" 回合 / "+(timeline_duration_dirty?"自动 / 待更新":(timeline_effective_duration_cache>0?"自动 "+string(round(timeline_effective_duration_cache/60*100)/100)+"s":"自动 / 未定")));
        TextTyper_DrawFallback(478,88,"对象: "+string(BattleEditor_EventCountForTurn(project,developer_turn)));
        _editor_button(478,110,632,134,scene_objects_visible?"隐藏当前回合对象":"显示当前回合对象",false);
    }
    if(draw_object_palette){
        // A genuine side panel: its backing plate is wider than every child
        // button, and the whole unit slides together instead of exposing
        // controls beyond the old narrow Inspector background.
        var palette_old_world=matrix_get(matrix_world);
        var palette_reveal=1-power(1-clamp(object_palette_anim_progress,0,1),3);
        var palette_offset=(1-palette_reveal)*258;
        matrix_set(matrix_world,matrix_build(palette_offset,0,0,0,0,0,1,1,1));
        ui_menu_alpha=1;
        draw_set_alpha(ui_menu_alpha);
        draw_set_color(make_color_rgb(12,12,12));draw_rectangle(382,60,638,454,false);
        draw_set_color(c_white);draw_rectangle(382,60,638,454,true);
        draw_set_color(c_yellow);
        TextTyper_DrawFallback(390,112,"新对象");
        _editor_button(390,124,632,148,"分类："+BattleEditor_ObjectPaletteCategoryName(object_palette_category)+"  ▼",object_palette_category_open);
        if(object_palette_category==0){
            _editor_button(390,158,506,182,"骨头",false);_editor_button(512,158,632,182,"GB",false);
            _editor_button(390,186,506,210,"真刀",false);_editor_button(512,186,632,210,"斩击",false);
            _editor_button(390,214,506,238,"友谊颗粒",false);_editor_button(512,214,632,238,"火球",false);
            _editor_button(390,242,506,266,"长矛",false);_editor_button(512,242,632,266,"三叉戟",false);
            _editor_button(390,270,506,294,"刀子",false);_editor_button(512,270,632,294,"3D 骨",false);
            _editor_button(390,298,506,322,"4D 骨",false);_editor_button(512,298,632,322,"骨刺",false);
            var create_layer_caption=create_layer_user_set?BattleEditor_LayerName(create_layer_mode):"自动";
            _editor_button(390,334,632,358,"层级："+create_layer_caption+" ▼",choice_menu_open&&choice_menu_context=="create_layer");
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,366,"自动按对象类型选择绘制层级。",18,238);
        }else if(object_palette_category==1){
            _editor_button(390,158,632,182,"放置自定义弹幕",false);
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,194,"放置后可选择内建贴图或文件帧，并编辑动画与伤害。",18,238);
        }else if(object_palette_category==2){
            _editor_button(390,158,632,182,"放置装饰",false);
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,194,"装饰不造成伤害，可编辑贴图、动画、变换与层级。",18,238);
        }else if(object_palette_category==3){
            _editor_button(390,158,632,182,"选择主框",false);
            _editor_button(390,186,632,210,"新增加框",false);
            _editor_button(390,214,632,238,"新增减框",false);
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,250,"主框唯一；加框、减框可重复。",18,238);
        }else if(object_palette_category==4){
            _editor_button(390,158,632,182,"放置打字机",false);
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,194,"点击战斗区域设置文字起始点。",18,238);
        }else{
            _editor_button(390,158,632,182,"放置蓝魂平台",false);
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(390,194,"点击战斗区域放置可调宽度的平台。",18,238);
        }
        if(object_palette_category_open){
            var palette_category_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
            var palette_category_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,150,640,max(1,ceil((480-150)*palette_category_reveal)));
            draw_set_alpha(palette_category_reveal);
            draw_set_color(make_color_rgb(8,8,10));draw_rectangle(390,150,632,282,false);
            draw_set_color(c_white);draw_rectangle(390,150,632,282,true);
            for(var palette_category_row=0;palette_category_row<6;palette_category_row++){
                var palette_category_y=150+palette_category_row*22;
                _editor_dropdown_selection(391,palette_category_y+1,631,palette_category_y+21,object_palette_category==palette_category_row);
                draw_set_color(object_palette_category==palette_category_row?c_yellow:c_white);
                TextTyper_DrawFallback(396,palette_category_y+3,BattleEditor_ObjectPaletteCategoryName(palette_category_row));
            }
            BattleEditor_UiScissor(palette_category_old_scissor);draw_set_alpha(1);
        }
        ui_menu_alpha=1;draw_set_alpha(1);
        matrix_set(matrix_world,palette_old_world);
    }else if(selected>=0){
        var property_old_world=matrix_get(matrix_world);
        var property_old_scissor=gpu_get_scissor();
        BattleEditor_UiScissor(468,106,172,332);
        matrix_set(matrix_world,matrix_build(0,-property_scroll,0,0,0,0,1,1,1));
        var picked=project.events[selected];
        var picked_track=picked.transform;
        var picked_bone=picked.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&picked.preset=="bone";
        var picked_gb=picked.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&picked.preset=="gb";
        var picked_typewriter=picked.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER;
        var picked_wave=picked.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(picked.preset=="slash"||picked.preset=="true_knife");
        var picked_solid=picked.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(picked.preset=="bone_3d"||picked.preset=="bone_4d");
        var picked_platform=picked.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&picked.preset=="platform";
        var picked_builtin_sprite=picked.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&picked.preset!="bone"&&picked.preset!="custom_sprite";
        var picked_clip_y=444;
        draw_set_color(c_yellow);
        TextTyper_DrawFallback(478,112,picked_typewriter?"打字机":(picked_platform?"蓝魂平台":(picked_bone?"内建攻击 / "+BattleEditor_BoneStyleName(picked.bone_style):(picked_gb?"内建攻击 / GB":((picked_wave||picked_solid)?"内建攻击 / "+BattleEditor_BuiltinHazardName(picked.preset):(picked.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION?"装饰":(picked.preset=="custom_sprite"?"自定义弹幕":"内建攻击 / "+BattleEditor_BuiltinHazardName(picked.preset))))))));
        draw_set_color(c_ltgray);TextTyper_DrawFallback(478,134,"层级");
        _editor_button(518,130,632,152,BattleEditor_LayerName(picked.layer_mode)+" ▼",choice_menu_open&&choice_menu_context=="event_layer"&&choice_menu_event==selected);
        var picked_has_damage=struct_exists(picked,"damage_profile");
        var picked_property_header_offset=(picked_typewriter||picked_platform)?28:(picked_has_damage?112:84);
        if(!picked_typewriter&&!picked_platform){
            var picked_visual_mode=clamp(round(real(picked.visual_tint.mode)),0,2);
            var picked_fixed_template=picked_visual_mode!=2;
            draw_set_color(c_ltgray);TextTyper_DrawFallback(478,162,"显示颜色");
            _editor_button(538,158,632,180,picked_fixed_template?"[X] 固定模板":"[ ] 自由颜色",picked_fixed_template);
            draw_set_color(c_ltgray);TextTyper_DrawFallback(478,190,picked_fixed_template?"颜色模板":"调色板");
            if(picked_fixed_template){
                var picked_template_type=picked_visual_mode==0&&picked_has_damage?picked.damage_profile.type:picked.visual_tint.preset_type;
                _editor_color_button(538,186,632,208,BattleEditor_ColorForType(picked_template_type),_editor_ellipsis(BattleEditor_VisualColorPresetName(picked_template_type),64)+" ▼");
            }else _editor_color_button(538,186,632,208,picked.visual_tint.custom_color,"自由选择");
            if(picked_has_damage) _editor_button(478,214,632,236,picked.damage_profile.change_visual?"[X] 同时修改显示颜色":"[ ] 只修改伤害判定",picked.damage_profile.change_visual);
        }
        // The title owns its own row. Shift every existing property row as a
        // unit so no layer/color button can overlap the object title.
        matrix_set(matrix_world,matrix_build(0,picked_property_header_offset-property_scroll,0,0,0,0,1,1,1));
        if(picked_solid){
            var solid_keys=BattleEditor_SolidBoneFieldKeys(picked.preset);
            var solid_labels=BattleEditor_SolidBoneFieldLabels(picked.preset);
            for(var solid_field_index=0;solid_field_index<array_length(solid_keys);solid_field_index++){
                var solid_field_y=132+solid_field_index*42;
                var solid_field_key=solid_keys[solid_field_index];
                draw_set_color(c_white);TextTyper_DrawFallback(478,solid_field_y,solid_labels[solid_field_index]);
                if(solid_field_key=="shape_3d") _editor_button(478,solid_field_y+16,632,solid_field_y+38,BattleEditor_SolidBoneShapeName(picked.shape_3d)+" ▼",choice_menu_open&&choice_menu_context=="solid_shape"&&choice_menu_event==selected);
                else if(solid_field_key=="damage_type") _editor_button(478,solid_field_y+16,632,solid_field_y+38,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
                else _editor_field(478,solid_field_y+16,632,solid_field_y+38,solid_field_key=="time"?BattleEditor_FormatTimelineTime(BattleEditor_SolidBoneFieldValue(picked,solid_field_key)):BattleEditor_SolidBoneFieldValue(picked,solid_field_key),"solid_field_"+string(solid_field_index));
            }
        }else if(picked_typewriter){
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"文字起始 X / Y");
            _editor_field(478,148,552,168,picked_track.x,"track_x");
            _editor_field(558,148,632,168,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"角度 / 出生时间");
            _editor_field(478,186,552,206,picked_track.angle,"track_angle");
            _editor_field(558,186,632,206,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"横向缩放 / 纵向缩放");
            _editor_field(478,224,552,244,picked_track.scale_x,"track_scale_x");
            _editor_field(558,224,632,244,picked_track.scale_y,"track_scale_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"透明度 / 打字速度");
            _editor_field(478,262,552,282,picked_track.alpha,"track_alpha");
            _editor_field(558,262,632,282,picked.speed,"typewriter_speed");
            draw_set_color(c_white);TextTyper_DrawFallback(478,284,"字体 / 绘制深度");
            _editor_button(478,300,552,320,string_copy(TextTyper_FontName(picked.font_id),1,9)+"  ▼",font_dropdown_open&&font_dropdown_target=="typewriter");
            _editor_field(558,300,632,320,picked.text_depth,"typewriter_depth");
            draw_set_color(c_white);TextTyper_DrawFallback(478,322,"基础颜色");
            var typer_base_color=is_real(picked.text_color)?picked.text_color:GetColorFromString(picked.text_color);
            _editor_color_button(478,338,552,358,typer_base_color,"选择");
            _editor_button(558,338,632,358,"编辑文本",false);
        _editor_button(478,364,552,386,"预览一次",false);
        _editor_button(558,364,632,386,picked.page_requires_confirm?"翻页按 Z":"自动翻页",picked.page_requires_confirm);
        _editor_button(478,390,598,412,"打字音效："+BattleEditor_VoiceName(picked.voice_id)+" ▼",choice_menu_open&&choice_menu_context=="typewriter_voice"&&choice_menu_event==selected);
            _editor_audio_preview_button(604,390,632,412,"typewriter_"+string(picked.uid));
            picked_clip_y=434;
        }else if(picked_platform){
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"中心 X / Y");
            _editor_field(478,148,552,168,picked_track.x,"track_x");
            _editor_field(558,148,632,168,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"角度 / 出生时间");
            _editor_field(478,186,552,206,picked_track.angle,"track_angle");
            _editor_field(558,186,632,206,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"宽度 / 生命周期");
            _editor_field(478,224,552,244,picked.width,"platform_width");
            _editor_field(558,224,632,244,BattleEditor_LifetimeCaption(picked.duration),"object_duration");
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"水平速度 / 垂直速度");
            _editor_field(478,262,552,282,picked.hspeed,"platform_hspeed");
            _editor_field(558,262,632,282,picked.vspeed,"platform_vspeed");
            draw_set_color(c_white);TextTyper_DrawFallback(478,284,"平台类型");
            _editor_button(478,300,632,322,picked.sticky?"绿色（带着玩家） ▼":"紫色（不带玩家） ▼",choice_menu_open&&choice_menu_context=="platform_type"&&choice_menu_event==selected);
            _editor_button(478,328,632,350,picked.bounce?"[X] 碰到战斗框时反弹":"[ ] 碰到战斗框时反弹",picked.bounce);
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(478,358,"两种平台都能站立；只有绿色平台会带着玩家一起移动。",17,150);
        }else if(picked_bone){
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"骨头类型");
            _editor_button(478,148,632,168,BattleEditor_BoneStyleName(picked.bone_style)+" ▼",choice_menu_open&&choice_menu_context=="bone_style"&&choice_menu_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,picked.follow?"相对所选框 X / Y":"初始 X / Y");
            _editor_field(478,186,552,206,picked_track.x,"track_x");
            _editor_field(558,186,632,206,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"初始角度 / 自转速度");
            _editor_field(478,224,552,244,picked_track.angle,"track_angle");
            _editor_field(558,224,632,244,picked.rotate,"bone_rotate");
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"长度 / 生命周期");
            _editor_field(478,262,552,282,picked.length,"bone_length");
            _editor_field(558,262,632,282,BattleEditor_LifetimeCaption(picked.duration),"object_duration");
            draw_set_color(c_white);TextTyper_DrawFallback(478,284,"水平速度 / 垂直速度");
            _editor_field(478,300,552,320,picked.hspeed,"bone_hspeed");
            _editor_field(558,300,632,320,picked.vspeed,"bone_vspeed");
            draw_set_color(c_white);TextTyper_DrawFallback(478,322,"伤害规则 / 出生时间");
            _editor_button(478,338,552,358,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
            _editor_field(558,338,632,358,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            _editor_button(478,364,552,386,picked.green_guard_blockable?"护盾可挡":"护盾不可挡",picked.green_guard_blockable);
            _editor_button(558,364,632,386,picked.green_guard_destroy_on_block?"格挡后销毁":"格挡后保留",picked.green_guard_destroy_on_block);
            _editor_button(478,392,552,416,picked.follow?"跟随：开":"跟随：关",picked.follow);
            _editor_button(558,392,632,416,string_copy(BattleEditor_FollowFrameCaption(project,picked.follow_target_uid),1,8)+" ▼",follow_dropdown_open&&follow_dropdown_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,420,BattleEditor_DamageValueName(picked.damage_profile.type));
            var bone_damage_value=picked.damage_profile.type==3?picked.damage_profile.heal_amount:picked.damage_profile.damage;
            _editor_field(478,436,632,456,bone_damage_value,picked.damage_profile.type==3?"object_heal_amount":"object_damage");
            var bone_aim_behavior=!picked.aim_enabled?0:(picked.aim_move_enabled?2:1);
            draw_set_color(c_white);TextTyper_DrawFallback(478,458,"朝向目标的行为");
            _editor_button(478,474,632,498,BattleEditor_BoneAimBehaviorName(bone_aim_behavior)+" ▼",choice_menu_open&&choice_menu_context=="bone_aim_behavior"&&choice_menu_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,500,"指向对象");
            _editor_button(478,516,632,540,string_copy(BattleEditor_AimTargetCaption(project,picked.aim_target_uid),1,18)+" ▼",aim_dropdown_open&&aim_dropdown_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,542,bone_aim_behavior==0?"方向更新（启用后生效）":"更新方式 / 移动速度");
            _editor_button(478,558,552,582,BattleEditor_EditorChoiceCaption("aim_update",picked.aim_continuous)+" ▼",choice_menu_open&&choice_menu_context=="bone_aim_update"&&choice_menu_event==selected);
            if(bone_aim_behavior==2) _editor_field(558,558,632,582,picked.aim_move_speed,"bone_aim_speed");
            else{draw_set_color(make_color_rgb(35,35,35));draw_rectangle(558,558,632,582,false);}
            picked_clip_y=600;
        }else if(picked_gb){
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"原生瞄准目标 X / Y");
            _editor_field(478,148,552,168,picked.target_x,"gb_target_x");
            _editor_field(558,148,632,168,picked.target_y,"gb_target_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"出生预设");
            _editor_button(478,186,632,206,BattleEditor_GBSpawnPresetName(picked.spawn_preset)+" ▼",gb_spawn_dropdown_open&&gb_spawn_dropdown_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"出生 X / Y");
            if(picked.spawn_preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM){
                _editor_field(478,224,552,244,picked.spawn_x,"gb_spawn_x");
                _editor_field(558,224,632,244,picked.spawn_y,"gb_spawn_y");
            }else{
                var resolved_spawn=BattleEditor_ResolveGBSpawn(picked,project.initialization);
                draw_set_color(make_color_rgb(35,35,35));draw_rectangle(478,224,552,244,false);draw_rectangle(558,224,632,244,false);
                draw_set_color(c_gray);draw_rectangle(478,224,552,244,true);draw_rectangle(558,224,632,244,true);
                TextTyper_DrawFallback(482,227,string(round(resolved_spawn[0])));TextTyper_DrawFallback(562,227,string(round(resolved_spawn[1])));
            }
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"起始角 / 目标角");
            _editor_field(478,262,552,282,picked.angle_start,"gb_spawn_angle");
            _editor_field(558,262,632,282,picked.angle_target,"gb_target_angle");
            draw_set_color(c_white);TextTyper_DrawFallback(478,284,"横向缩放 / 纵向缩放");
            _editor_field(478,300,552,320,picked_track.scale_x,"track_scale_x");
            _editor_field(558,300,632,320,picked_track.scale_y,"track_scale_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,322,"移动 / 等待 / 光束");
            _editor_field(478,338,526,358,picked.move_time,"gb_move_time");
            _editor_field(531,338,579,358,picked.charge_time,"gb_charge_time");
            _editor_field(584,338,632,358,picked.beam_time,"gb_beam_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,364,"假炮 / 伤害规则");
            var gb_fake_names=["真实 GB","假 GB 动画","假 GB 掉落"];
            _editor_button(478,380,552,402,gb_fake_names[clamp(round(picked.fake_mode),0,2)]+" ▼",choice_menu_open&&choice_menu_context=="gb_fake"&&choice_menu_event==selected);
            _editor_button(558,380,632,402,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,406,"移动曲线 / 出生时间");
            _editor_button(478,422,552,444,BattleEditor_TweenName(picked_track.tween)+" ▼",choice_menu_open&&choice_menu_context=="gb_tween"&&choice_menu_event==selected);
            _editor_field(558,422,632,444,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,448,BattleEditor_DamageValueName(picked.damage_profile.type));
            var gb_damage_value=picked.damage_profile.type==3?picked.damage_profile.heal_amount:picked.damage_profile.damage;
            _editor_field(478,464,632,486,gb_damage_value,picked.damage_profile.type==3?"object_heal_amount":"object_damage");
            _editor_button(478,492,632,514,picked.offset_enabled?"[X] 发射开始后使用 GB 偏移":"[ ] 使用原生后退",picked.offset_enabled);
            draw_set_color(c_white);TextTyper_DrawFallback(478,520,"退出方向模式");
            _editor_button(478,536,632,558,BattleEditor_EditorChoiceCaption("gb_offset_direction",picked.offset_direction_mode)+" ▼",choice_menu_open&&choice_menu_context=="gb_offset_direction"&&choice_menu_event==selected);
            draw_set_color(c_white);
            if(round(real(picked.offset_direction_mode))==0){
                TextTyper_DrawFallback(478,562,"初始速度 / 每帧速度变化");
                _editor_field(478,578,552,598,"初速 "+string(picked.offset_speed),"gb_offset_speed");
                _editor_field(558,578,632,598,"变化 "+string(picked.offset_acceleration),"gb_offset_acceleration");
            }else{
                TextTyper_DrawFallback(478,562,"退出方向 / 初始速度");
                _editor_field(478,578,552,598,"方向 "+string(picked.offset_direction),"gb_offset_direction");
                _editor_field(558,578,632,598,"初速 "+string(picked.offset_speed),"gb_offset_speed");
                TextTyper_DrawFallback(478,600,"每帧速度变化");
                _editor_field(478,616,632,636,"变化 "+string(picked.offset_acceleration),"gb_offset_acceleration");
            }
            var gb_rotation_label_y=round(real(picked.offset_direction_mode))==0?600:638;
            var gb_rotation_field_y=gb_rotation_label_y+16;
            TextTyper_DrawFallback(478,gb_rotation_label_y,"GB 本体旋转速度");
            _editor_field(478,gb_rotation_field_y,632,gb_rotation_field_y+20,"自转 "+string(picked.offset_rotation_speed),"gb_offset_rotation");
            var gb_help_y=gb_rotation_field_y+28;
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(478,gb_help_y,"方向固定；速度每帧累加变化值。自动方向就是当前 GB 朝向的正后方。",17,150);
            if(array_length(project.resources.gb_styles)>0){
                draw_set_color(c_white);TextTyper_DrawFallback(478,730,"GB 贴图组");
                _editor_button(478,748,632,772,BattleEditor_GBStyleCaption(project,picked.gb_style_uid)+" ▼",gb_style_dropdown_open&&gb_style_dropdown_event==selected);
            }
        }else if(picked_wave){
            var is_true_knife=picked.preset=="true_knife";
            if(is_true_knife) wave_inspector_phase=1;
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"起点 X / Y");
            _editor_field(478,148,552,168,picked_track.x,"track_x");
            _editor_field(558,148,632,168,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"角度 / 出生时间");
            _editor_field(478,186,552,206,picked_track.angle,"track_angle");
            _editor_field(558,186,632,206,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,is_true_knife?"颜色规则 / 单次伤害":"伤害类型 / "+BattleEditor_DamageValueName(picked.damage_profile.type));
            if(is_true_knife){
                _editor_button(478,224,552,244,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
                _editor_field(558,224,632,244,picked.damage_profile.damage,"object_damage");
            }else if(picked.damage_profile.type==3){
                _editor_button(478,224,552,244,"亮绿色 ▼",damage_dropdown_open&&damage_dropdown_event==selected);
                _editor_field(558,224,632,244,picked.damage_profile.heal_amount,"object_heal_amount");
            }else{
                _editor_button(478,224,552,244,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
                _editor_field(558,224,632,244,picked.damage_profile.damage,"object_damage");
            }
            if(!is_true_knife){
                draw_set_color(c_white);TextTyper_DrawFallback(478,246,"警告帧 / 攻击帧");
                _editor_field(478,262,552,282,picked.warning_time,"wave_warning_time");
                _editor_field(558,262,632,282,picked.active_time,"wave_active_time");
                draw_set_color(c_white);TextTyper_DrawFallback(478,284,"宽度");
                _editor_field(478,300,632,320,picked.visual_min_width,"wave_min_width");
                _editor_button(478,324,552,344,"攻击前",wave_inspector_phase==0);
                _editor_button(558,324,632,344,"攻击后",wave_inspector_phase==1);
            }else{
                draw_set_color(c_white);TextTyper_DrawFallback(478,250,"受击无敌时间（帧）");
                _editor_field(478,266,632,286,picked.invincibility_frames,"true_knife_invincibility");
                draw_set_color(c_gray);TextTyper_DrawFallbackExt(478,290,"一次扣 "+string(picked.damage_profile.damage)+"；专属闪光与震屏。",18,150);
                _editor_button(478,312,632,334,"刀波出现后",true);
            }
            var wave_motion=wave_inspector_phase==0?picked.pre_motion:picked.post_motion;
            var wave_section_y=is_true_knife?336:344;
            _editor_button(478,wave_section_y,552,wave_section_y+20,"移动",wave_inspector_section==0);
            _editor_button(558,wave_section_y,632,wave_section_y+20,"旋转",wave_inspector_section==1);
            if(wave_inspector_section==0){
                draw_set_color(c_white);TextTyper_DrawFallback(478,wave_section_y+22,"方向 / 初速");
                _editor_field(478,wave_section_y+34,552,wave_section_y+52,wave_motion.direction,"wave_motion_direction");
                _editor_field(558,wave_section_y+34,632,wave_section_y+52,wave_motion.speed,"wave_motion_speed");
                draw_set_color(c_white);TextTyper_DrawFallback(478,wave_section_y+54,"加速度 / 弯曲角速");
                _editor_field(478,wave_section_y+66,552,wave_section_y+84,wave_motion.acceleration,"wave_motion_acceleration");
                _editor_field(558,wave_section_y+66,632,wave_section_y+84,wave_motion.curve_speed,"wave_motion_curve");
            }else{
                _editor_button(478,wave_section_y+23,wave_motion.rotation_mode==2?548:632,wave_section_y+43,BattleEditor_WaveRotationModeName(wave_motion.rotation_mode)+" ▼",choice_menu_open&&choice_menu_context=="wave_rotation"&&choice_menu_event==selected);
                if(wave_motion.rotation_mode==2){
                    _editor_button(550,wave_section_y+23,596,wave_section_y+43,string_copy(BattleEditor_TweenName(wave_motion.tween),1,2)+"▼",choice_menu_open&&choice_menu_context=="wave_tween"&&choice_menu_event==selected);
                    _editor_button(598,wave_section_y+23,632,wave_section_y+43,string_copy(BattleEditor_EaseName(wave_motion.ease),1,1)+"▼",choice_menu_open&&choice_menu_context=="wave_ease"&&choice_menu_event==selected);
                }
                if(wave_motion.rotation_mode==1){
                    draw_set_color(c_white);TextTyper_DrawFallback(478,wave_section_y+45,"每帧旋转速度");
                    _editor_field(478,wave_section_y+59,632,wave_section_y+81,wave_motion.rotation_speed,"wave_rotation_speed");
                }else if(wave_motion.rotation_mode==2){
                    draw_set_color(c_white);TextTyper_DrawFallback(478,wave_section_y+45,"目标角 / 用时");
                    _editor_field(478,wave_section_y+59,552,wave_section_y+81,wave_motion.target_angle,"wave_rotation_target");
                    _editor_field(558,wave_section_y+59,632,wave_section_y+81,wave_motion.rotation_time,"wave_rotation_time");
                }
            }
        }else if(picked_builtin_sprite){
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"初始 X / Y");
            _editor_field(478,148,552,168,picked_track.x,"track_x");
            _editor_field(558,148,632,168,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"角度 / 出生时间");
            _editor_field(478,186,552,206,picked_track.angle,"track_angle");
            _editor_field(558,186,632,206,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"横向缩放 / 纵向缩放");
            _editor_field(478,224,552,244,picked_track.scale_x,"track_scale_x");
            _editor_field(558,224,632,244,picked_track.scale_y,"track_scale_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"伤害规则");
            _editor_button(478,262,632,284,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
            draw_set_color(c_white);TextTyper_DrawFallback(478,288,BattleEditor_DamageValueName(picked.damage_profile.type)+" / 生命周期");
            _editor_field(478,304,552,326,picked.damage_profile.type==3?picked.damage_profile.heal_amount:picked.damage_profile.damage,picked.damage_profile.type==3?"object_heal_amount":"object_damage");
            _editor_field(558,304,632,326,BattleEditor_LifetimeCaption(picked.duration),"object_duration");
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(478,334,"贴图："+string_copy(picked.sprite_source,1,18),18,150);
            picked_clip_y=358;
        }else{
            draw_set_color(c_white);TextTyper_DrawFallback(478,132,"初始 X / Y");
            _editor_field(478,148,552,168,picked_track.x,"track_x");
            _editor_field(558,148,632,168,picked_track.y,"track_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"角度 / 透明度");
            _editor_field(478,186,552,206,picked_track.angle,"track_angle");
            _editor_field(558,186,632,206,picked_track.alpha,"track_alpha");
            draw_set_color(c_white);TextTyper_DrawFallback(478,208,"横向缩放 / 纵向缩放");
            _editor_field(478,224,552,244,picked_track.scale_x,"track_scale_x");
            _editor_field(558,224,632,244,picked_track.scale_y,"track_scale_y");
            draw_set_color(c_white);TextTyper_DrawFallback(478,246,"Sprite 资源 / 横向精灵条");
            _editor_field(478,262,566,282,picked.sprite_source,"object_sprite");
            _editor_button(570,262,632,282,"选择",false);
            var frame_count=array_length(picked.animation.frames);
            var frame_label=selected_animation_frame>=0&&selected_animation_frame<frame_count?picked.animation.frames[selected_animation_frame]:"点击后编辑第 1 帧";
            draw_set_color(c_white);TextTyper_DrawFallback(478,284,"动画帧 "+string(max(0,selected_animation_frame+1))+" / "+string(frame_count));
            _editor_field(478,300,566,320,frame_label,"animation_frame");
            _editor_button(570,300,632,320,"选择",false);
            _editor_button(478,324,506,346,"-",false);
            _editor_button(508,324,536,346,"+",false);
            _editor_button(538,324,566,346,"◀",false);
            _editor_button(568,324,596,346,">",false);
            _editor_button(598,324,632,346,picked.animation.loop?"循":"停",picked.animation.loop);
            draw_set_color(c_white);TextTyper_DrawFallback(478,350,"FPS / 生命周期");
            _editor_field(478,366,530,386,picked.animation.fps,"animation_fps");
            _editor_field(534,366,632,386,BattleEditor_LifetimeCaption(picked.duration),"object_duration");
            draw_set_color(c_white);TextTyper_DrawFallback(478,390,picked.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION?"出生时间":"出生时间 / 伤害规则");
            _editor_field(478,406,picked.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION?632:552,426,BattleEditor_FormatTimelineTime(picked.time),"object_time");
            if(picked.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION){
                _editor_button(558,406,632,426,BattleEditor_DamageTypeName(picked.damage_profile.type)+" ▼",damage_dropdown_open&&damage_dropdown_event==selected);
                var custom_damage_value=picked.damage_profile.type==3?picked.damage_profile.heal_amount:picked.damage_profile.damage;
                draw_set_color(c_white);TextTyper_DrawFallback(478,432,BattleEditor_DamageValueName(picked.damage_profile.type));
                _editor_field(478,448,632,468,custom_damage_value,picked.damage_profile.type==3?"object_heal_amount":"object_damage");
                picked_clip_y=486;
            }
        }
        if(picked.kind!=BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&struct_exists(picked,"layer_mode")&&picked.layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD){
            draw_set_color(c_white);TextTyper_DrawFallback(478,picked_clip_y,"裁剪");
            _editor_button(478,picked_clip_y+20,552,picked_clip_y+42,picked.clip_mode=="all"?"全部框":"自定义",picked.clip_mode=="selected");
            var clip_count=is_array(picked.clip_frame_uids)?array_length(picked.clip_frame_uids):0;
            _editor_button(558,picked_clip_y+20,632,picked_clip_y+42,"选择 "+string(clip_count)+" 个",clip_editor_open&&clip_editor_event==selected);
            _editor_button(478,picked_clip_y+48,632,picked_clip_y+72,picked.clipped_collision?"[X] 被裁剪部分无碰撞":"[ ] 裁剪只影响画面",picked.clipped_collision);
        }
        matrix_set(matrix_world,property_old_world);
        BattleEditor_UiScissor(property_old_scissor);
    }else if(selected_frame>=-1){
        var frame_property_old_world=matrix_get(matrix_world);
        var frame_property_old_scissor=gpu_get_scissor();
        BattleEditor_UiScissor(468,106,172,332);
        matrix_set(matrix_world,matrix_build(0,-property_scroll,0,0,0,0,1,1,1));
        var picked_frame=selected_frame==-1?main_board_preview:project.initialization.frames[selected_frame];
        draw_set_color(c_yellow);
        TextTyper_DrawFallback(478,116,selected_frame==-1?"战斗框 / 主框":(picked_frame.cover?"战斗框 / 减框":"战斗框 / 加框"));
        draw_set_color(c_white);
        TextTyper_DrawFallback(478,132,"中心 X / Y");
        _editor_field(478,148,552,168,"X "+string(picked_frame.x),"frame_x");
        _editor_field(558,148,632,168,"Y "+string(picked_frame.y),"frame_y");
        if(picked_frame.shape=="circle"){
            TextTyper_DrawFallback(478,170,"椭圆半径 X / Y");
            _editor_field(478,186,552,206,"半径X "+string(picked_frame.radius_x),"frame_radius_x");
            _editor_field(558,186,632,206,"半径Y "+string(picked_frame.radius_y),"frame_radius_y");
            draw_set_color(c_gray);TextTyper_DrawFallback(478,216,"两个半径相同就是圆形");
        }else if(picked_frame.shape=="rect"){
            TextTyper_DrawFallback(478,170,"上 / 下");
            _editor_field(478,186,552,206,"上 "+string(picked_frame.up),"frame_up");
            _editor_field(558,186,632,206,"下 "+string(picked_frame.down),"frame_down");
            TextTyper_DrawFallback(478,208,"左 / 右");
            _editor_field(478,224,552,244,"左 "+string(picked_frame.left),"frame_left");
            _editor_field(558,224,632,244,"右 "+string(picked_frame.right),"frame_right");
        }else if(picked_frame.shape=="triangle"){
            draw_set_color(c_white);TextTyper_DrawFallback(478,170,"正三角形尺寸");
            _editor_field(478,186,632,206,picked_frame.triangle_size,"frame_triangle_size");
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(478,212,"拖动顶点后转为多边形。",18,150);
        }else{
            draw_set_color(c_white);TextTyper_DrawFallback(478,174,"多边形顶点 "+string(array_length(picked_frame.vertices)));
            draw_set_color(c_gray);TextTyper_DrawFallbackExt(478,194,"右拖顶点；右键空处加顶点。",18,150);
        }
        TextTyper_DrawFallback(478,246,"角度 / 每帧旋转");
        _editor_field(478,262,552,282,"角度 "+string(picked_frame.angle),"frame_angle");
        _editor_field(558,262,632,282,"旋转 "+string(picked_frame.rotate),"frame_rotate");
        TextTyper_DrawFallback(478,284,"绘制深度");
        _editor_field(478,300,552,320,"层级 "+string(picked_frame.board_depth),"frame_depth");
        draw_set_color(c_white);TextTyper_DrawFallback(478,320,"边框颜色");
        _editor_color_button(478,338,624,358,picked_frame.color_frame,BattleEditor_ColorToHex(picked_frame.color_frame,255));
        draw_set_color(c_gray);TextTyper_DrawFallback(478,362,"框内左拖；右拖顶点；Del 删除额外框");
        matrix_set(matrix_world,frame_property_old_world);
        BattleEditor_UiScissor(frame_property_old_scissor);
    }else{
        draw_set_color(c_gray);
        TextTyper_DrawFallbackExt(478,124,"骨头贴图固定；自定义可选贴图。装饰无伤害。",18,150);
    }
    draw_set_color(c_ltgray);
    // Status/hint text is constrained to the scene column. It may wrap, but it
    // can never run underneath the inspector or outside the 640x480 GUI.
    TextTyper_DrawFallbackExt(8,374,string_copy(status_text,1,240),18,452);
}else if(tab==1){
    // Initialization is a real modal editor surface.  A nearly opaque backing
    // keeps the live battle HUD from visually running through labels/buttons.
    draw_set_alpha(0.94);
    draw_set_color(c_black);
    draw_rectangle(0,32,640,480,false);
    draw_set_alpha(1);
    draw_set_color(c_white);draw_rectangle(12,36,632,454,true);
    var init=project.initialization;
    var editor_turn_data=BattleEditor_GetTurnData(project,developer_turn,true);
    _editor_button(20,42,144,66,"玩家与物品",initialization_page==0);
    _editor_button(148,42,294,66,"回合与敌人",initialization_page==1);
    _editor_button(298,42,444,66,"画面与战斗框",initialization_page==2);
    _editor_button(448,42,624,66,"四按钮菜单",initialization_page==3);
    // The second-level navigation belongs directly under its parent page and
    // remains visible while the long editor body scrolls.
    if(initialization_page==1){
        _editor_button(20,72,136,98,"回合文本",initialization_enemy_page==0);
        _editor_button(140,72,256,98,"敌人角色",initialization_enemy_page==1);
        _editor_button(260,72,376,98,"ACT 行动",initialization_enemy_page==2);
        _editor_button(380,72,496,98,"GB 设置",initialization_enemy_page==3);
        _editor_button(500,72,624,98,"战斗音乐",initialization_enemy_page==4);
    }
    var initialization_old_world=matrix_get(matrix_world);
    var initialization_old_scissor=gpu_get_scissor();
    var initialization_body_top=initialization_page==1?102:68;
    var initialization_body_offset=initialization_page==1?36:0;
    BattleEditor_UiScissor(12,initialization_body_top,620,450-initialization_body_top);
    matrix_set(matrix_world,matrix_build(0,initialization_body_offset-initialization_scroll,0,0,0,0,1,1,1));

    if(initialization_page==0){
        _editor_section(76,"玩家基本数值");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,106,"玩家名称");_editor_field(120,102,624,126,init.player_name,"player_name");
        TextTyper_DrawFallback(22,138,"LV");TextTyper_DrawFallback(212,138,"ATK");TextTyper_DrawFallback(402,138,"DEF");
        _editor_field(22,156,202,180,init.lv,"player_lv");_editor_field(212,156,392,180,init.atk,"player_atk");_editor_field(402,156,624,180,init.def,"player_def");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,192,"当前 HP");TextTyper_DrawFallback(212,192,"HP 上限");TextTyper_DrawFallback(402,192,"完整 HP 上限");
        _editor_field(22,210,202,234,init.hp,"player_hp");_editor_field(212,210,392,234,init.max_hp,"player_max_hp");_editor_field(402,210,624,234,init.natural_max_hp,"player_natural_max_hp");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,246,"当前护盾");TextTyper_DrawFallback(212,246,"护盾上限");TextTyper_DrawFallback(402,246,"完整护盾上限");
        _editor_field(22,264,202,288,init.shield,"player_shield");_editor_field(212,264,392,288,init.shield_max,"player_shield_max");_editor_field(402,264,624,288,init.shield_natural_max,"player_shield_natural_max");
        _editor_section(302,"HUD 显示与护盾");
        _editor_button(22,328,318,352,init.shield_enabled?"[X] 启用护盾":"[ ] 启用护盾",init.shield_enabled);
        _editor_button(326,328,624,352,(init.shield_hud_mode==BATTLE_SHIELD_HUD_MODE.SIDE?"护盾位置：血条右侧":"护盾位置：血条下方")+" ▼",choice_menu_open&&choice_menu_context=="shield_mode");
        _editor_button(22,358,318,382,init.hud_show_hp_label?"[X] 显示 HP 图标":"[ ] 显示 HP 图标",init.hud_show_hp_label);
        _editor_button(326,358,624,382,init.hud_show_bar?"[X] 显示血条":"[ ] 显示血条",init.hud_show_bar);
        _editor_button(22,388,318,412,init.hud_show_kr?"[X] 显示 KR":"[ ] 显示 KR",init.hud_show_kr);
        _editor_button(326,388,624,412,init.hud_show_numbers?"[X] 显示数值":"[ ] 显示数值",init.hud_show_numbers);
        _editor_button(22,418,318,442,init.hud_show_shield?"[X] 显示护盾":"[ ] 显示护盾",init.hud_show_shield);
        _editor_button(326,418,624,442,init.hud_show_overhead?"[X] 显示头顶数值":"[ ] 显示头顶数值",init.hud_show_overhead);
        _editor_section(460,"物品栏");_editor_button(90,484,166,508,"添加",false);_editor_button(170,484,246,508,"删除",false);
        for(var row=0;row<7;row++){
            var item_index=item_scroll+row;if(item_index>=array_length(init.items)) break;
            _editor_button(22,516+row*27,246,540+row*27,string(item_index+1)+". "+init.items[item_index].name,item_index==selected_item);
        }
        if(selected_item>=0&&selected_item<array_length(init.items)){
            var item=init.items[selected_item];
            draw_set_color(c_gray);TextTyper_DrawFallback(266,520,"物品名称");_editor_field(360,516,624,540,item.name,"item_name");
            TextTyper_DrawFallback(266,550,"恢复量");_editor_field(360,546,624,570,item.heal,"item_heal");
            TextTyper_DrawFallback(266,580,"打字音效");_editor_button(360,576,590,600,BattleEditor_VoiceName(item.voice_id)+" ▼",choice_menu_open&&choice_menu_context=="item_voice");_editor_audio_preview_button(596,576,624,600,"item_"+string(item.uid));
            TextTyper_DrawFallback(266,610,"食用文本");
            draw_set_color(make_color_rgb(8,8,8));draw_rectangle(266,628,624,674,false);draw_set_color(c_white);draw_rectangle(266,628,624,674,true);
            TextTyper_DrawFallbackExt(272,632,TextTyper_MarkupPlain(item.eat_text),18,340);_editor_button(516,678,624,702,"编辑文本",false);
            draw_set_color(c_gray);TextTyper_DrawFallback(266,718,"使用后脚本");
            _editor_button(384,714,624,740,_editor_ellipsis(BattleEditor_ItemAfterUseModeName(item.after_use_mode),216)+" ▼",choice_menu_open&&choice_menu_context=="item_after_use");
        }
        _editor_button(22,758,198,784,"恢复玩家数值",false);_editor_button(204,758,404,784,"恢复 HUD",false);_editor_button(410,758,624,784,"恢复默认物品",false);
    }else if(initialization_page==1){
        if(initialization_enemy_page==0){
        draw_set_color(c_gray);TextTyper_DrawFallback(22,78,"编辑怪物回合");
        _editor_button(148,74,330,98,"第 "+string(developer_turn)+" 回合  ▼",initialization_turn_dropdown);
        _editor_button(336,74,432,98,"新增回合",false);
        _editor_button(438,74,624,98,"本回合恢复默认",false);
        draw_set_color(c_gray);TextTyper_DrawFallback(22,112,"回合文本（战斗框字体）");_editor_button(210,108,330,132,"编辑文本",false);_editor_button(336,108,456,132,string_copy(TextTyper_FontName(editor_turn_data.turn_font),1,18)+"  ▼",font_dropdown_open&&font_dropdown_target=="turn");
        _editor_button(460,108,592,132,BattleEditor_VoiceName(editor_turn_data.turn_voice)+" ▼",choice_menu_open&&choice_menu_context=="turn_voice");_editor_audio_preview_button(596,108,624,132,"turn_voice");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,146,"敌人台词（角色气泡字体）");_editor_button(210,142,330,166,"编辑文本",false);_editor_button(336,142,456,166,string_copy(TextTyper_FontName(editor_turn_data.dialogue_font),1,18)+"  ▼",font_dropdown_open&&font_dropdown_target=="dialogue");
        _editor_button(460,142,592,166,BattleEditor_VoiceName(editor_turn_data.dialogue_voice)+" ▼",choice_menu_open&&choice_menu_context=="dialogue_voice");_editor_audio_preview_button(596,142,624,166,"dialogue_voice");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,180,"气泡样式");_editor_button(112,176,330,200,BattleEditor_DialogueTemplateName(editor_turn_data.dialogue_template)+"  ▼",choice_menu_open&&choice_menu_context=="dialogue_template");
        TextTyper_DrawFallback(342,180,"相对敌人 X / Y");_editor_field(464,176,540,200,editor_turn_data.dialogue_offset_x,"dialogue_offset_x");_editor_field(546,176,624,200,editor_turn_data.dialogue_offset_y,"dialogue_offset_y");
        draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(22,216,"气泡位置以当前敌人 Root 为锚点；整体布局统一在“画面与战斗框”中设置。",18,580);
        }else if(initialization_enemy_page==1){
            var enemy_count=array_length(init.enemies);
            selected_enemy=clamp(selected_enemy,0,max(0,enemy_count-1));
            var enemy_visible_rows=8;
            enemy_list_scroll=clamp(enemy_list_scroll,0,max(0,enemy_count-enemy_visible_rows));
            if(selected_enemy<enemy_list_scroll) enemy_list_scroll=selected_enemy;
            if(selected_enemy>=enemy_list_scroll+enemy_visible_rows) enemy_list_scroll=selected_enemy-enemy_visible_rows+1;
            draw_set_color(c_yellow);TextTyper_DrawFallback(22,76,"敌人列表");_editor_button(86,72,136,96,"新增",false);_editor_button(140,72,190,96,"复制",false);
            _editor_button(22,104,82,128,"删除",false);_editor_button(86,104,190,128,"恢复默认",false);
            for(var enemy_row=0;enemy_row<enemy_visible_rows;enemy_row++){
                var enemy_index=enemy_list_scroll+enemy_row;
                if(enemy_index<enemy_count) _editor_button(22,134+enemy_row*30,190,160+enemy_row*30,string(enemy_index+1)+". "+init.enemies[enemy_index].name,enemy_index==selected_enemy);
            }
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(22,378,"最多 15 个；原版 FIGHT/ACT 无滚动，只有前 3 个可精确选择。其余仍会显示并接受脚本控制。",14,168);
            if(enemy_count>0){
                var enemy_data=init.enemies[selected_enemy];
                draw_set_color(c_gray);TextTyper_DrawFallback(208,76,"名称 / 控制 ID");_editor_field(330,72,472,96,enemy_data.name,"enemy_name");_editor_field(478,72,624,96,enemy_data.control_id,"enemy_control_id");
                TextTyper_DrawFallback(208,108,"逻辑位置 X / Y");_editor_field(340,104,474,128,enemy_data.x,"enemy_x");_editor_field(480,104,624,128,enemy_data.y,"enemy_y");
                TextTyper_DrawFallback(208,140,"缩放 X / Y");_editor_field(340,136,474,160,enemy_data.scale_x,"enemy_scale_x");_editor_field(480,136,624,160,enemy_data.scale_y,"enemy_scale_y");
                TextTyper_DrawFallback(208,172,"横向摆动公式");_editor_field(340,168,624,192,enemy_data.sway_x,"enemy_sway_x");
                TextTyper_DrawFallback(208,204,"身体 Y 公式");_editor_field(340,200,624,224,enemy_data.torso_y,"enemy_torso_y");
                TextTyper_DrawFallback(208,236,"头部 Y 公式");_editor_field(340,232,624,256,enemy_data.head_y,"enemy_head_y");
                var enemy_part_keys=BattleEditor_EnemyPartKeys();selected_enemy_part=clamp(selected_enemy_part,0,array_length(enemy_part_keys)-1);
                var enemy_part_key=enemy_part_keys[selected_enemy_part];var enemy_part=variable_struct_get(enemy_data.parts,enemy_part_key);
                TextTyper_DrawFallback(208,268,"身体部件");_editor_button(340,264,474,288,BattleEditor_EnemyPartName(enemy_part_key)+" ▼",choice_menu_open&&choice_menu_context=="enemy_part");_editor_button(480,264,624,288,"可视化编辑",false);
                TextTyper_DrawFallback(208,300,"贴图");draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(270,296,string_copy(enemy_part.source,1,50),18,354);
                draw_set_color(c_gray);TextTyper_DrawFallback(208,332,"局部偏移 X / Y");_editor_field(340,328,474,352,enemy_part.offset_x,"enemy_part_x");_editor_field(480,328,624,352,enemy_part.offset_y,"enemy_part_y");
                TextTyper_DrawFallback(208,364,"重力动画脚本 上 / 下");_editor_field(382,360,500,384,enemy_data.animation_scripts.gravity_up,"enemy_gravity_up");_editor_field(506,360,624,384,enemy_data.animation_scripts.gravity_down,"enemy_gravity_down");
                TextTyper_DrawFallback(208,396,"重力动画脚本 左 / 右");_editor_field(382,392,500,416,enemy_data.animation_scripts.gravity_left,"enemy_gravity_left");_editor_field(506,392,624,416,enemy_data.animation_scripts.gravity_right,"enemy_gravity_right");
            }
        }else if(initialization_enemy_page==2){
            var enemy_count=array_length(init.enemies);
            selected_enemy=clamp(selected_enemy,0,max(0,enemy_count-1));
            var action_enemy_visible_rows=9;
            enemy_list_scroll=clamp(enemy_list_scroll,0,max(0,enemy_count-action_enemy_visible_rows));
            if(selected_enemy<enemy_list_scroll) enemy_list_scroll=selected_enemy;
            if(selected_enemy>=enemy_list_scroll+action_enemy_visible_rows) enemy_list_scroll=selected_enemy-action_enemy_visible_rows+1;
            draw_set_color(c_yellow);TextTyper_DrawFallback(22,76,"敌人列表");
            for(var action_enemy_row=0;action_enemy_row<action_enemy_visible_rows;action_enemy_row++){
                var action_enemy_index=enemy_list_scroll+action_enemy_row;
                if(action_enemy_index<enemy_count) _editor_button(22,104+action_enemy_row*30,190,130+action_enemy_row*30,string(action_enemy_index+1)+". "+init.enemies[action_enemy_index].name,action_enemy_index==selected_enemy);
            }
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(22,378,"第 4～15 个敌人可编辑行动数据，但不会出现在原版 FIGHT/ACT 目标列表。",14,168);
            if(enemy_count>0){
                var action_enemy=init.enemies[selected_enemy];
                selected_enemy_action=clamp(selected_enemy_action,0,max(0,array_length(action_enemy.actions)-1));
                draw_set_color(c_yellow);TextTyper_DrawFallback(208,76,"行动选项");
                _editor_button(330,72,408,96,"新增",false);_editor_button(414,72,492,96,"删除",false);
                draw_set_color(c_ltgray);TextTyper_DrawFallback(502,76,string(array_length(action_enemy.actions))+" / 6");
                for(var enemy_action_row=0;enemy_action_row<min(6,array_length(action_enemy.actions));enemy_action_row++) _editor_button(208,104+enemy_action_row*30,624,130+enemy_action_row*30,string(enemy_action_row+1)+". "+action_enemy.actions[enemy_action_row].name,enemy_action_row==selected_enemy_action);
                if(array_length(action_enemy.actions)>0){
                    var enemy_action=action_enemy.actions[selected_enemy_action];
                    draw_set_color(c_gray);TextTyper_DrawFallback(208,290,"选项名称");_editor_field(310,286,624,310,enemy_action.name,"enemy_action_name");
                    TextTyper_DrawFallback(208,324,"选择后的文本");
                    draw_set_color(make_color_rgb(8,8,8));draw_rectangle(208,344,624,390,false);draw_set_color(c_white);draw_rectangle(208,344,624,390,true);
                    TextTyper_DrawFallbackExt(214,348,TextTyper_MarkupPlain(enemy_action.text),18,396);
                    _editor_button(506,394,624,418,"编辑文本",false);
                }else{
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(208,286,"这个敌人目前没有行动项目。点击“新增”后可编辑名称、文本，并在 Workspace 建立对应的行动项目列表。",18,396);
                }
            }
        }else if(initialization_enemy_page==3){
            var gb_styles=project.resources.gb_styles;
            selected_gb_style=clamp(selected_gb_style,-1,max(-1,array_length(gb_styles)-1));
            draw_set_color(c_yellow);TextTyper_DrawFallback(22,76,"GB 贴图组");
            _editor_button(112,72,164,96,"新建",false);_editor_button(168,72,220,96,"删除",false);
            _editor_button(22,104,220,130,"内置默认 GB（只读）",selected_gb_style==-1);
            for(var gb_style_row=0;gb_style_row<min(8,array_length(gb_styles));gb_style_row++) _editor_button(22,134+gb_style_row*30,220,160+gb_style_row*30,string(gb_style_row+1)+". "+gb_styles[gb_style_row].name,gb_style_row==selected_gb_style);

            var gb_style=selected_gb_style>=0?gb_styles[selected_gb_style]:undefined;
            if(is_undefined(gb_style)){
                draw_set_color(c_yellow);TextTyper_DrawFallback(238,76,"原版 UTE GB");
                draw_set_color(c_ltgray);TextTyper_DrawFallback(238,98,"4 帧本体 / 原版光束 / 只读");
            }else{
                draw_set_color(c_gray);TextTyper_DrawFallback(238,76,"名称");_editor_field(300,72,624,96,gb_style.name,"gb_style_name");
            }
            _editor_button(238,106,360,132,"本体帧",gb_style_editor_page==0);
            _editor_button(370,106,492,132,"光束",gb_style_editor_page==1);
            _editor_button(502,106,624,132,"发射预览",gb_style_editor_page==2);

            if(gb_style_editor_page==0){
                var gb_style_definition=is_undefined(gb_style)?BattleEditor_BuiltinGBStyle():gb_style;
                var gb_style_preview=BattleEditor_GBStylePreviewSprite(id,project,gb_style_definition.uid);
                var gb_style_frames=gb_style_definition.animation.frames;
                var gb_style_frame_count=array_length(gb_style_frames);
                selected_gb_style_frame=clamp(selected_gb_style_frame,0,max(0,gb_style_frame_count-1));
                draw_set_color(c_gray);TextTyper_DrawFallback(238,144,"本体动画帧 "+string(selected_gb_style_frame+1)+" / "+string(gb_style_frame_count));
                if(!is_undefined(gb_style)){
                    _editor_field(238,164,540,188,gb_style_frames[selected_gb_style_frame],"gb_style_frame");_editor_button(546,164,624,188,"选择",false);
                    _editor_button(238,196,330,220,"上一帧",false);_editor_button(336,196,428,220,"下一帧",false);_editor_button(434,196,526,220,"添加",false);_editor_button(532,196,624,220,"删除",false);
                    _editor_button(238,228,428,252,"向前移动",false);_editor_button(434,228,624,252,"向后移动",false);
                    draw_set_color(c_gray);TextTyper_DrawFallback(238,264,"每帧间隔");_editor_field(338,260,420,284,gb_style.animation.frame_interval,"gb_style_interval");
                    TextTyper_DrawFallback(434,264,"原点 X / Y");_editor_field(520,260,568,284,gb_style.origin_x,"gb_style_origin_x");_editor_field(574,260,624,284,gb_style.origin_y,"gb_style_origin_y");
                    TextTyper_DrawFallback(238,296,"素材朝向");
                    var head_directions=[0,270,180,90];var head_direction_names=["右","下","左","上"];
                    for(var head_direction_button=0;head_direction_button<4;head_direction_button++) _editor_button(338+head_direction_button*72,292,404+head_direction_button*72,316,head_direction_names[head_direction_button],gb_style.source_direction==head_directions[head_direction_button]);
                }else{
                    _editor_button(238,196,428,220,"上一帧",false);_editor_button(434,196,624,220,"下一帧",false);
                }
                if(sprite_exists(gb_style_preview)){
                    var gb_body_preview_scale=min(2.5,min(250/max(1,sprite_get_width(gb_style_preview)),82/max(1,sprite_get_height(gb_style_preview))));
                    var gb_body_preview_angle=-gb_style_definition.source_direction;
                    draw_sprite_ext(gb_style_preview,selected_gb_style_frame,430,370,gb_body_preview_scale,gb_body_preview_scale,gb_body_preview_angle,c_white,1);
                }
                draw_set_color(c_ltgray);TextTyper_DrawFallback(238,402,"真实与假动画在最后两帧闪；假掉落不张嘴");
            }else if(gb_style_editor_page==1){
                if(is_undefined(gb_style)){
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(238,148,"原版 UTE 光束使用 16×16 横向素材，由运行时绘制为无限射线并独立计算视觉宽度与判定宽度。",18,374);
                    draw_sprite_ext(spr_gb_beam,0,300,270,16,2,0,c_white,1);
                }else{
                    var gb_beam_variant_names=["基础/其他","橙色","蓝色"];
                    for(var gb_variant_button=0;gb_variant_button<3;gb_variant_button++) _editor_button(238+gb_variant_button*130,144,358+gb_variant_button*130,168,gb_beam_variant_names[gb_variant_button],selected_gb_beam_variant==gb_variant_button);
                    var gb_beam_animation=gb_style.beam.variants[selected_gb_beam_variant].animation;
                    var gb_beam_frames=gb_beam_animation.frames;
                    selected_gb_beam_frame=clamp(selected_gb_beam_frame,0,max(0,array_length(gb_beam_frames)-1));
                    TextTyper_DrawFallback(238,180,"光束帧 "+string(selected_gb_beam_frame+1)+" / "+string(array_length(gb_beam_frames)));
                    _editor_field(238,200,540,224,gb_beam_frames[selected_gb_beam_frame],"gb_style_beam_frame");_editor_button(546,200,624,224,"选择",false);
                    _editor_button(238,232,330,256,"上一帧",false);_editor_button(336,232,428,256,"下一帧",false);_editor_button(434,232,526,256,"添加",false);_editor_button(532,232,624,256,"删除",false);
                    draw_set_color(c_gray);TextTyper_DrawFallback(238,268,"帧间隔");_editor_field(318,264,390,288,gb_beam_animation.frame_interval,"gb_style_beam_interval");TextTyper_DrawFallback(404,268,"发射点距离");_editor_field(520,264,624,288,gb_style.beam.source_offset,"gb_style_beam_offset");
                    TextTyper_DrawFallback(238,300,"素材朝向");
                    var beam_directions=[0,270,180,90];var beam_direction_names=["右","下","左","上"];
                    for(var beam_direction_button=0;beam_direction_button<4;beam_direction_button++) _editor_button(338+beam_direction_button*72,296,404+beam_direction_button*72,320,beam_direction_names[beam_direction_button],gb_style.beam.source_direction==beam_directions[beam_direction_button]);
                    TextTyper_DrawFallback(238,332,"基础宽度 / 初始比例");_editor_field(424,328,520,352,gb_style.beam.base_scale,"gb_style_beam_scale");_editor_field(526,328,624,352,gb_style.beam.launch_ratio,"gb_style_beam_launch");
                    TextTyper_DrawFallback(238,364,"呼吸幅度 / 判定内缩");_editor_field(424,360,520,384,gb_style.beam.breath_ratio,"gb_style_beam_breath");_editor_field(526,360,624,384,gb_style.beam.hit_inset,"gb_style_beam_hit_inset");
                    draw_set_color(c_ltgray);TextTyper_DrawFallback(238,394,"三组都支持任意帧数；基础组供其他颜色着色");
                }
            }else{
                _editor_button(238,144,624,172,gb_style_preview_playing?"正在播放一次完整发射…":"播放一次完整发射",gb_style_preview_playing);
                draw_set_color(make_color_rgb(4,4,6));draw_rectangle(238,180,624,410,false);draw_set_color(c_gray);draw_rectangle(238,180,624,410,true);
                var preview_style=is_undefined(gb_style)?BattleEditor_BuiltinGBStyle():gb_style;
                var preview_head=BattleEditor_GBStylePreviewSprite(id,project,preview_style.uid);
                var preview_beam=BattleEditor_GBStylePreviewBeamSprite(id,project,preview_style.uid,0);
                var preview_head_count=max(1,sprite_get_number(preview_head));
                var preview_head_interval=max(1,preview_style.animation.frame_interval);
                var preview_head_direction=preview_style.source_direction;
                var preview_beam_direction=preview_style.beam.source_direction;
                var preview_t=gb_style_preview_playing?gb_style_preview_time:0;
                var preview_enter=45,preview_charge=35,preview_anticipation=6;
                var preview_open=max(1,(preview_head_count-1)*preview_head_interval),preview_active=50;
                var preview_close=max(10,(preview_head_count-1)*preview_head_interval);
                var preview_release_start=preview_enter+preview_charge+preview_anticipation;
                var preview_close_start=preview_release_start+preview_open+preview_active;
                // Render a real 640 x 480 battle viewport inside the panel.
                // The entrance uses exactly the initialization GB spawn preset,
                // rather than a decorative hard-coded nudge inside this box.
                var preview_view_scale=min((624-238)/640,(410-180)/480);
                var preview_view_x=(238+624-preview_view_scale*640)*0.5;
                var preview_view_y=(180+410-preview_view_scale*480)*0.5;
                var preview_target_x=430,preview_target_y=240;
                var preview_spawn_event={spawn_preset:BATTLE_EDITOR_GB_SPAWN.INHERIT,spawn_x:320,spawn_y:-560,angle_start:project.initialization.gb_spawn_default.angle,target_x:preview_target_x,target_y:preview_target_y};
                var preview_spawn=BattleEditor_ResolveGBSpawn(preview_spawn_event,project.initialization);
                var preview_enter_p=clamp(preview_t/preview_enter,0,1);
                var preview_enter_ease=1-power(1-preview_enter_p,3);
                var preview_world_x=lerp(preview_spawn[0],preview_target_x,preview_enter_ease);
                var preview_world_y=lerp(preview_spawn[1],preview_target_y,preview_enter_ease);
                var preview_semantic_angle=lerp(preview_spawn[2],0,preview_enter_ease);
                var preview_x=preview_view_x+preview_world_x*preview_view_scale;
                var preview_y=preview_view_y+preview_world_y*preview_view_scale;
                var preview_head_frame=0;
                if(preview_t>=preview_release_start){
                    var preview_release_age=preview_t-preview_release_start;
                    if(preview_release_age<preview_open) preview_head_frame=min(preview_head_count-1,floor(preview_release_age/preview_head_interval));
                    else if(preview_t<preview_close_start){
                        var preview_loop_start=max(0,preview_head_count-2);
                        preview_head_frame=preview_loop_start+(floor((preview_release_age-preview_open)/preview_head_interval) mod max(1,preview_head_count-preview_loop_start));
                    }
                    else preview_head_frame=max(0,preview_head_count-1-floor((preview_t-preview_close_start)/preview_head_interval));
                }
                var preview_alpha=preview_t>=preview_close_start?1-clamp((preview_t-preview_close_start)/preview_close,0,1):1;
                var preview_head_y_scale=2;
                if(preview_t>=preview_enter+preview_charge&&preview_t<preview_release_start) preview_head_y_scale=2*(1-0.2*clamp((preview_t-preview_enter-preview_charge)/preview_anticipation,0,1));
                var preview_old_scissor=gpu_get_scissor();
                BattleEditor_UiScissor(238,180,386,230);
                if(gb_style_preview_playing&&preview_t>=preview_release_start){
                    var preview_beam_age=preview_t-preview_release_start;
                    var preview_beam_scale=preview_style.beam.base_scale;
                    var preview_launch_ratio=preview_style.beam.launch_ratio;
                    var preview_breath_ratio=preview_style.beam.breath_ratio;
                    var preview_width_scale=preview_beam_scale*(preview_launch_ratio+(1-preview_launch_ratio)*clamp(preview_beam_age/3,0,1));
                    preview_width_scale+=sin(preview_beam_age*pi/3)*preview_beam_scale*preview_breath_ratio;
                    if(preview_t>=preview_close_start) preview_width_scale*=preview_alpha;
                    var preview_beam_world_x=preview_world_x+lengthdir_x(preview_style.beam.source_offset*2,preview_semantic_angle);
                    var preview_beam_world_y=preview_world_y+lengthdir_y(preview_style.beam.source_offset*2,preview_semantic_angle);
                    var preview_beam_x=preview_view_x+preview_beam_world_x*preview_view_scale;
                    var preview_beam_y=preview_view_y+preview_beam_world_y*preview_view_scale;
                    // The preview beam is a ray in any direction. Measuring
                    // only to the right edge made rotated previews too short
                    // and visually unlike the straight runtime beam.
                    var preview_beam_length=point_distance(0,0,640,480)*2*preview_view_scale;
                    var preview_beam_frame=floor(preview_beam_age/max(1,preview_style.beam.variants[0].animation.frame_interval)) mod max(1,sprite_get_number(preview_beam));
                    var preview_beam_vertical=preview_beam_direction==90||preview_beam_direction==270;
                    var preview_beam_along=preview_beam_length/max(1,preview_beam_vertical?sprite_get_height(preview_beam):sprite_get_width(preview_beam));
                    var preview_beam_across=16*2*preview_view_scale*max(0,preview_width_scale)/max(1,preview_beam_vertical?sprite_get_width(preview_beam):sprite_get_height(preview_beam));
                    draw_sprite_ext(preview_beam,preview_beam_frame,preview_beam_x,preview_beam_y,preview_beam_vertical?preview_beam_across:preview_beam_along,preview_beam_vertical?preview_beam_along:preview_beam_across,preview_semantic_angle-preview_beam_direction,c_white,preview_alpha);
                }
                var preview_head_scale=2*preview_view_scale;
                draw_sprite_ext(preview_head,preview_head_frame,preview_x,preview_y,preview_head_scale,preview_head_y_scale*preview_view_scale,preview_semantic_angle-preview_head_direction,c_white,preview_alpha);
                BattleEditor_UiScissor(preview_old_scissor);
                if(!gb_style_preview_playing){draw_set_color(c_ltgray);TextTyper_DrawFallback(260,384,"按初始化出生规则：飞入 → 开口 → 光束 → 收束");}
            }
            _editor_section(438,"GB 默认出生位置");
            _editor_button(22,466,298,490,BattleEditor_GBSpawnPresetName(init.gb_spawn_default.preset)+" ▼",gb_spawn_dropdown_open&&gb_spawn_dropdown_event==-1);
            draw_set_color(c_gray);TextTyper_DrawFallback(310,446,"解析/自定 X");TextTyper_DrawFallback(420,446,"Y");TextTyper_DrawFallback(530,446,"起始角");
            if(init.gb_spawn_default.preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM){_editor_field(310,466,412,490,init.gb_spawn_default.x,"global_gb_x");_editor_field(420,466,522,490,init.gb_spawn_default.y,"global_gb_y");}
            else{draw_set_color(make_color_rgb(35,35,35));draw_rectangle(310,466,412,490,false);draw_rectangle(420,466,522,490,false);draw_set_color(c_gray);draw_rectangle(310,466,412,490,true);draw_rectangle(420,466,522,490,true);TextTyper_DrawFallback(316,470,"由预设计算");TextTyper_DrawFallback(426,470,"由预设计算");}
            _editor_field(530,466,624,490,init.gb_spawn_default.angle,"global_gb_angle");
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(22,500,"全局规则不能为“无”；单个 GB 的“无”表示继承这里。屏幕外预设固定使用屏幕直径 800。",18,600);
            _editor_button(448,540,624,566,"恢复出生默认",false);
        }else{
            var battle_music_caption=string_length(string_trim(init.battle_music))>0?BattleEditor_SoundOptionCaption(init.battle_music,project):"无（不播放）";
            draw_set_color(c_yellow);TextTyper_DrawFallback(22,78,"正式战斗音乐");
            _editor_button(22,104,508,132,_editor_ellipsis(battle_music_caption,450)+" ▼",battle_music_dropdown_open);
            _editor_audio_preview_button(516,104,544,132,"battle_music");
            _editor_button(550,104,624,132,"导入",false);

            draw_set_color(c_yellow);TextTyper_DrawFallback(22,164,"播放同步方式");
            _editor_button(22,188,318,216,"正常播放",!init.battle_music_frame_sync);
            _editor_button(326,188,624,216,"低 FPS 音频校正",init.battle_music_frame_sync);
            draw_set_color(c_ltgray);
            TextTyper_DrawFallbackExt(22,238,"正常播放：音乐按真实时间前进。低 FPS 音频校正：音乐位置跟随游戏逻辑帧；游戏变慢时音乐也会同步变慢，音高不变。",18,602);
            TextTyper_DrawFallbackExt(22,316,"两种方式都使用现有 BGM 槽位、音量、停止与淡入淡出逻辑。不限回合制或生存战；任何战斗都可以选择。",18,602);
            draw_set_color(c_gray);
            TextTyper_DrawFallback(22,382,string_length(string_trim(init.battle_music))>0?"当前资源已保存到项目":"当前不播放战斗音乐");
        }
        if(battle_music_dropdown_open&&initialization_enemy_page==4){
            var battle_music_options=BattleEditor_MusicOptions(project);
            var battle_music_total=array_length(battle_music_options)+1;
            battle_music_scroll=clamp(battle_music_scroll,0,max(0,battle_music_total-10));
            var battle_music_visible=min(10,battle_music_total-battle_music_scroll);
            var battle_music_bottom=134+battle_music_visible*24;
            var battle_music_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
            draw_set_alpha(0.99*battle_music_reveal);draw_set_color(make_color_rgb(8,8,10));draw_rectangle(22,134,508,battle_music_bottom,false);
            draw_set_alpha(battle_music_reveal);draw_set_color(c_white);draw_rectangle(22,134,508,battle_music_bottom,true);
            for(var battle_music_row=0;battle_music_row<battle_music_visible;battle_music_row++){
                var battle_music_option_index=battle_music_scroll+battle_music_row;
                var battle_music_option=battle_music_option_index==0?"":battle_music_options[battle_music_option_index-1];
                var battle_music_selected=string_lower(string(battle_music_option))==string_lower(string(init.battle_music));
                var battle_music_row_y=135+battle_music_row*24;
                _editor_dropdown_selection(23,battle_music_row_y,507,battle_music_row_y+22,battle_music_selected);
                draw_set_color(battle_music_selected?c_yellow:c_white);
                var battle_music_option_caption=battle_music_option_index==0?"无（不播放战斗音乐）":BattleEditor_SoundOptionCaption(battle_music_option,project);
                TextTyper_DrawFallback(28,battle_music_row_y+2,_editor_ellipsis(battle_music_option_caption,468));
            }
            draw_set_alpha(1);
        }
    }else if(initialization_page==2){
        var pb=init.player_board;var mb=init.board;
        _editor_section(76,"界面锚点");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,106,"HUD 原点 X / Y");_editor_field(188,102,314,126,init.hud_x,"layout_hud_x");_editor_field(322,102,448,126,init.hud_y,"layout_hud_y");
        TextTyper_DrawFallback(22,138,"敌人整体中心 X / Y");_editor_field(188,134,314,158,init.enemy_x,"layout_enemy_x");_editor_field(322,134,448,158,init.enemy_y,"layout_enemy_y");
        TextTyper_DrawFallback(22,170,"回合文本起点 X / Y");_editor_field(188,166,314,190,init.turn_text_x,"layout_turn_text_x");_editor_field(322,166,448,190,init.turn_text_y,"layout_turn_text_y");
        draw_set_color(c_ltgray);TextTyper_DrawFallback(466,106,"所有位置集中在这里");

        _editor_section(216,"玩家回合框");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,246,"中心 X / Y");_editor_field(132,242,236,266,"X "+string(pb.x),"player_board_x");_editor_field(242,242,346,266,"Y "+string(pb.y),"player_board_y");
        TextTyper_DrawFallback(22,276,"上 / 下");_editor_field(132,272,236,296,"上 "+string(pb.up),"player_board_up");_editor_field(242,272,346,296,"下 "+string(pb.down),"player_board_down");
        TextTyper_DrawFallback(22,306,"左 / 右");_editor_field(132,302,236,326,"左 "+string(pb.left),"player_board_left");_editor_field(242,302,346,326,"右 "+string(pb.right),"player_board_right");TextTyper_DrawFallback(366,306,"角度");_editor_field(420,302,524,326,"角度 "+string(pb.angle),"player_board_angle");

        _editor_section(354,"怪物回合主框默认");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,384,"中心 X / Y");_editor_field(132,380,236,404,"X "+string(mb.x),"init_board_x");_editor_field(242,380,346,404,"Y "+string(mb.y),"init_board_y");
        TextTyper_DrawFallback(22,414,"上 / 下");_editor_field(132,410,236,434,"上 "+string(mb.up),"init_board_up");_editor_field(242,410,346,434,"下 "+string(mb.down),"init_board_down");
        TextTyper_DrawFallback(22,444,"左 / 右");_editor_field(132,440,236,464,"左 "+string(mb.left),"init_board_left");_editor_field(242,440,346,464,"右 "+string(mb.right),"init_board_right");TextTyper_DrawFallback(366,444,"角度");_editor_field(420,440,524,464,"角度 "+string(mb.angle),"init_board_angle");

        _editor_section(492,"全局框外观");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,522,"边框颜色");_editor_color_button(132,518,386,542,init.board_color_default,BattleEditor_ColorToHex(init.board_color_default,255));_editor_button(398,518,624,542,"应用到全部框",false);
        _editor_button(22,566,318,594,"强制恢复当前初始化",false);
        _editor_button(326,566,624,594,"恢复画面与战斗框默认值",false);
    }else{
        _editor_section(76,"四个主按钮的数据来源");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,110,"FIGHT：敌人列表决定可攻击目标");_editor_button(474,104,624,130,"编辑敌人",false);
        TextTyper_DrawFallback(22,142,"ACT：每个敌人拥有自己的行动项目");_editor_button(474,136,624,162,"编辑 ACT",false);
        TextTyper_DrawFallback(22,174,"ITEM：物品栏决定可使用项目");_editor_button(474,168,624,194,"编辑物品",false);

        _editor_section(220,"MERCY / 仁慈菜单");
        draw_set_color(c_gray);TextTyper_DrawFallback(22,252,"饶恕显示文字");_editor_field(166,246,624,272,init.mercy_spare_label,"mercy_spare_label");
        TextTyper_DrawFallback(22,286,"按下饶恕后的回应");
        draw_set_color(make_color_rgb(8,8,8));draw_rectangle(22,306,624,352,false);draw_set_color(c_white);draw_rectangle(22,306,624,352,true);
        TextTyper_DrawFallbackExt(28,310,string_length(string_trim(init.mercy_spare_response))>0?TextTyper_MarkupPlain(init.mercy_spare_response):"（空白：只执行敌人原有的饶恕事件）",18,580);
        _editor_button(506,356,624,382,"编辑回应",false);

        _editor_button(22,398,624,426,init.mercy_flee_enabled?"[X] 在仁慈菜单显示逃跑":"[ ] 隐藏逃跑选项",init.mercy_flee_enabled);
        draw_set_color(c_gray);TextTyper_DrawFallback(22,458,"逃跑显示文字");_editor_field(166,452,624,478,init.mercy_flee_label,"mercy_flee_label");
        TextTyper_DrawFallback(22,492,"逃跑成功回应");
        draw_set_color(make_color_rgb(8,8,8));draw_rectangle(22,512,624,558,false);draw_set_color(c_white);draw_rectangle(22,512,624,558,true);
        TextTyper_DrawFallbackExt(28,516,string_length(string_trim(init.mercy_flee_success_text))>0?TextTyper_MarkupPlain(init.mercy_flee_success_text):"（空白：使用原版随机文本 / 奖励文本）",18,580);
        _editor_button(506,562,624,588,"编辑成功回应",false);
        draw_set_color(c_gray);TextTyper_DrawFallback(22,620,"逃跑失败回应");
        draw_set_color(make_color_rgb(8,8,8));draw_rectangle(22,640,624,686,false);draw_set_color(c_white);draw_rectangle(22,640,624,686,true);
        TextTyper_DrawFallbackExt(28,644,string_length(string_trim(init.mercy_flee_fail_text))>0?TextTyper_MarkupPlain(init.mercy_flee_fail_text):"（空白：保持原版无额外文本）",18,580);
        _editor_button(506,690,624,716,"编辑失败回应",false);
        _editor_button(22,730,624,758,"恢复仁慈菜单默认值",false);
    }
    if(initialization_turn_dropdown&&initialization_page==1){
        var known_turns=BattleEditor_GetKnownTurns(project);var turn_rows=min(10,array_length(known_turns));
        var init_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
        draw_set_alpha(0.99*init_dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));draw_rectangle(148,100,330,100+turn_rows*22,false);draw_set_alpha(init_dropdown_reveal);draw_set_color(c_white);draw_rectangle(148,100,330,100+turn_rows*22,true);
        for(var turn_row=0;turn_row<turn_rows;turn_row++){
            var turn_selected=known_turns[turn_row]==developer_turn;
            _editor_dropdown_selection(149,101+turn_row*22,329,121+turn_row*22,turn_selected);
            draw_set_color(turn_selected?c_yellow:c_white);
            TextTyper_DrawFallback(154,103+turn_row*22,"第 "+string(known_turns[turn_row])+" 回合");
        }
        draw_set_alpha(1);
    }
    matrix_set(matrix_world,initialization_old_world);
    BattleEditor_UiScissor(initialization_old_scissor);
    if(initialization_scroll>0){draw_set_color(c_gray);TextTyper_DrawFallback(606,initialization_page==1?104:70,"▲");}
}else if(tab==2&&workspace_open){
    draw_set_alpha(0.94);
    draw_set_color(make_color_rgb(7,9,13));
    draw_rectangle(0,0,640,480,false);
    draw_set_alpha(1);

    var grid_size=32*script_zoom;
    if(grid_size>=12){
        draw_set_color(make_color_rgb(24,29,38));
        var grid_x=script_pan_x mod grid_size;
        var grid_y=script_pan_y mod grid_size;
        for(var gx=grid_x;gx<640;gx+=grid_size) draw_line(gx,0,gx,480);
        for(var gy=grid_y;gy<480;gy+=grid_size) draw_line(0,gy,640,gy);
    }

    // Function-path preview uses battle-screen coordinates directly. It is
    // drawn over the grid but under nodes/Inspector, so authors can tune the
    // formula without leaving Workspace or confusing it with a runtime object.
    if(script_function_preview_uid>=0){
        var function_preview_step=undefined;
        for(var preview_list_index=0;preview_list_index<array_length(project.script_lists)&&is_undefined(function_preview_step);preview_list_index++){
            var preview_steps=project.script_lists[preview_list_index].steps;
            for(var preview_step_index=0;preview_step_index<array_length(preview_steps);preview_step_index++){
                var preview_candidate=preview_steps[preview_step_index];
                if(preview_candidate.uid==script_function_preview_uid&&preview_candidate.kind=="builtin_action"&&preview_candidate.action_name=="bone_function_path"){
                    function_preview_step=preview_candidate;
                    break;
                }
            }
        }
        if(is_undefined(function_preview_step)){
            script_function_preview_uid=-1;
            script_function_preview_data={valid:true,points:[],parameter_name:"t"};
        }else{
            var function_preview_signature=string(function_preview_step.action_arguments)+"|"+string(function_preview_step.action_path_variable);
            if(script_function_preview_dirty||script_function_preview_signature!=function_preview_signature){
                script_function_preview_data=BattleEditor_FunctionPathPreviewData(project,function_preview_step,96);
                script_function_preview_signature=function_preview_signature;
                script_function_preview_dirty=false;
            }
            var function_preview_points=script_function_preview_data.points;
            if(array_length(function_preview_points)>=2){
                draw_set_alpha(0.2);
                draw_set_color(script_function_preview_data.valid?make_color_rgb(50,210,255):c_red);
                for(var preview_segment=1;preview_segment<array_length(function_preview_points);preview_segment++) draw_line_width(function_preview_points[preview_segment-1][0],function_preview_points[preview_segment-1][1],function_preview_points[preview_segment][0],function_preview_points[preview_segment][1],6);
                draw_set_alpha(0.95);
                for(var preview_segment=1;preview_segment<array_length(function_preview_points);preview_segment++){
                    var preview_mix=preview_segment/(array_length(function_preview_points)-1);
                    draw_set_color(script_function_preview_data.valid?merge_color(make_color_rgb(30,225,255),make_color_rgb(235,80,255),preview_mix):c_red);
                    draw_line_width(function_preview_points[preview_segment-1][0],function_preview_points[preview_segment-1][1],function_preview_points[preview_segment][0],function_preview_points[preview_segment][1],2);
                }
                draw_set_color(c_lime);draw_circle(function_preview_points[0][0],function_preview_points[0][1],5,false);
                var function_preview_last=array_length(function_preview_points)-1;
                draw_set_color(make_color_rgb(255,90,220));draw_circle(function_preview_points[function_preview_last][0],function_preview_points[function_preview_last][1],5,false);
                draw_set_alpha(1);
            }
            if(!script_function_preview_data.valid){draw_set_color(c_red);TextTyper_DrawFallback(8,36,"轨迹公式无效：无效部分按 0 预览");}
        }
    }

    // Direct list references are drawn as wires. Names are presentation only;
    // the edge is held by target_list_uid.
    // Resolve UIDs once per frame instead of scanning every list for every
    // edge. Large workspaces therefore stay O(lists + steps), not O(edges ×
    // lists). The map is draw-local and cannot become stale after an edit.
    var wire_target_lookup={};
    for(var wire_lookup_index=0;wire_lookup_index<array_length(project.script_lists);wire_lookup_index++){
        var wire_lookup_list=project.script_lists[wire_lookup_index];
        wire_target_lookup[$ "u_"+string(wire_lookup_list.uid)]=wire_lookup_list;
    }
    for(var wire_list_index=0;wire_list_index<array_length(project.script_lists);wire_list_index++){
        var wire_list=project.script_lists[wire_list_index];
        // Hiding the original dragged stack must not hide its logical edges.
        var wire_visible=array_length(wire_list.steps);
        for(var wire_step_index=0;wire_step_index<wire_visible;wire_step_index++){
            var wire_step=wire_list.steps[wire_step_index];
            if(wire_step.kind=="start_list"&&struct_exists(wire_step,"target_list_uid")&&wire_step.target_list_uid>=0){
                var wire_target_key="u_"+string(wire_step.target_list_uid);
                if(struct_exists(wire_target_lookup,wire_target_key)){
                    var wire_target=wire_target_lookup[$ wire_target_key];
                    if(!BattleEditor_WorkspaceHasHeader(wire_target)) continue;
                    var wire_from=BattleEditor_WorkspacePortPosition(id,wire_list,wire_step_index);
                    var wire_to=BattleEditor_WorkspacePortPosition(id,wire_target);
                    var wire_x1=wire_from.x,wire_y1=wire_from.y,wire_x2=wire_to.x,wire_y2=wire_to.y;
                    var wire_offscreen=(wire_x1<0&&wire_x2<0)||(wire_x1>640&&wire_x2>640)||(wire_y1<32&&wire_y2<32)||(wire_y1>480&&wire_y2>480);
                    if(!wire_offscreen) _editor_bezier(wire_x1,wire_y1,wire_x2,wire_y2,make_color_rgb(115,190,255),max(1,2*script_zoom));
                }
            }
        }
    }

    for(var draw_list_index=0;draw_list_index<array_length(project.script_lists);draw_list_index++){
        var draw_list=project.script_lists[draw_list_index];
        var draw_visible_count=BattleEditor_WorkspaceVisibleCount(draw_list,script_stack_drag);
        if(draw_visible_count<0) continue;
        var list_x=script_pan_x+draw_list.world_x*script_zoom;
        var list_y=script_pan_y+draw_list.world_y*script_zoom;
        var list_w=238*script_zoom;
        var header_h=BattleEditor_WorkspaceHeaderHeight(draw_list)*script_zoom;
        var list_h=header_h+max(1,draw_visible_count)*48*script_zoom;
        if(list_x>640||list_x+list_w<0||list_y>480||list_y+list_h<32) continue;
        var selected_list=draw_list_index==script_selected_list;
        draw_set_color(make_color_rgb(25,33,46));
        draw_roundrect_ext(list_x,list_y,list_x+list_w,list_y+list_h,7*script_zoom,7*script_zoom,false);
        if(header_h>0){
            // Header and body share one silhouette, with no bottom header border.
            draw_set_color(c_white);
            TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,list_y+4*script_zoom,_editor_ellipsis(draw_list.name,178),script_zoom*0.85,script_zoom*0.85,0);
            draw_set_color(make_color_rgb(183,200,220));
            TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,list_y+20*script_zoom,BattleEditor_ScriptEntryName(draw_list.entry_kind,draw_list.entry_value,project),script_zoom*0.65,script_zoom*0.65,0);
            BattleEditor_WorkspaceDrawRunButton(list_x,list_y,script_zoom);
            draw_set_color(make_color_rgb(130,190,255));draw_circle(list_x,list_y+header_h*0.5,max(3,4*script_zoom),false);
        }
        if(draw_visible_count<=0){
            draw_set_color(c_ltgray);
            TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,list_y+header_h+13*script_zoom,"把积木拖到这里",script_zoom*0.78,script_zoom*0.78,0);
        }
        var stack_scissor=gpu_get_scissor();
        BattleEditor_UiScissor(max(0,list_x),max(32,list_y),max(1,min(640,list_x+list_w)-max(0,list_x)),max(1,min(450,list_y+list_h)-max(32,list_y)));
        for(var draw_step_index=0;draw_step_index<draw_visible_count;draw_step_index++){
            var draw_step=draw_list.steps[draw_step_index];
            var step_y=list_y+header_h+draw_step_index*48*script_zoom;
            // A tall list may contain hundreds of steps. Keep its data and hit
            // geometry intact, but do not submit rectangles/text wholly beyond
            // the clipped Workspace viewport.
            if(step_y>480||step_y+48*script_zoom<32) continue;
            var step_selected=draw_list_index==script_selected_list&&draw_step_index==script_selected_step;
            draw_set_color(BattleEditor_ScriptStepFillColor(draw_step.kind,step_selected));
            var fill_top=draw_step_index==0&&header_h==0?step_y+4*script_zoom:step_y;
            var fill_bottom=draw_step_index==draw_visible_count-1?step_y+44*script_zoom:step_y+48*script_zoom;
            draw_rectangle(list_x+2*script_zoom,fill_top,list_x+list_w-2*script_zoom,fill_bottom,false);
            if(step_selected){
                draw_set_color(BattleEditor_ScriptStepBorderColor(draw_step.kind,true));
                draw_line_width(list_x+3*script_zoom,step_y+8*script_zoom,list_x+3*script_zoom,step_y+40*script_zoom,2*script_zoom);
            }
            // Text is independent of selection outlines and loop enclosures.
            draw_set_color(struct_exists(draw_step,"enabled")&&!draw_step.enabled?c_gray:c_white);
            var step_title=BattleEditor_ScriptStepName(draw_step.kind);
            TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+5*script_zoom,step_title,script_zoom*0.9,script_zoom*0.9,0);
            if(draw_step.kind=="start_list"){
                TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,"目标: 拖动右侧端口连接列表头",script_zoom*0.72,script_zoom*0.72,0);
                draw_set_color(make_color_rgb(115,190,255));draw_circle(list_x+list_w,step_y+24*script_zoom,max(3,4*script_zoom),false);
            }else if(draw_step.kind=="wait"){
                var draw_wait_mode=struct_exists(draw_step,"wait_mode")?round(real(draw_step.wait_mode)):0;
                var draw_wait_extra=struct_exists(draw_step,"wait_extra_duration")?max(0,real(draw_step.wait_extra_duration)):0;
                var draw_wait_text=draw_wait_mode==1?("等上一个步骤执行完"+(draw_wait_extra>0?" + "+string(draw_wait_extra)+" 帧":"")):("时长: "+string(round(draw_step.duration/60*100)/100)+" 秒");
                TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,draw_wait_text,script_zoom*0.72,script_zoom*0.72,0);
            }
            else if(draw_step.kind=="control_object"){
                var control_step_copy=struct_exists(draw_step,"control_source_mode")&&round(real(draw_step.control_source_mode))==1;
                var control_step_group=struct_exists(draw_step,"target_group_kind")?string(draw_step.target_group_kind):"";
                var control_step_target=control_step_group!=""?BattleEditor_ControlGroupName(control_step_group):(BattleEditor_TargetTypeName(draw_step.target_type)+"对象组");
                control_step_target+=(control_step_copy?"：复制 ":"：直接 ")+string(draw_step.target);
                if(control_step_copy) control_step_target+=" > "+string(draw_step.copy_control_id);
                TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,control_step_target+" · "+BattleEditor_ControlPropertyName(draw_step.property,draw_step.target_type),script_zoom*0.72,script_zoom*0.72,0);
            }
            else if(draw_step.kind=="create_object") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,BattleEditor_WorkspaceCreatePresetName(draw_step.create_preset)+" / "+string(draw_step.create_control_id),script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="set_variable") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,draw_step.variable_name+" = "+draw_step.expression,script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="condition") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,draw_step.condition_left+" "+draw_step.condition_operator+" "+draw_step.condition_right,script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="repeat"){
                var draw_repeat_interval=struct_exists(draw_step,"repeat_interval")?string(draw_step.repeat_interval):"0";
                TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,"重复 "+string(draw_step.repeat_count)+" 次 / 后 "+string(draw_step.repeat_length)+" 项 / 间隔 "+draw_repeat_interval+" 帧",script_zoom*0.72,script_zoom*0.72,0);
            }
            else if(draw_step.kind=="builtin_action") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,BattleEditor_BuiltinActionName(draw_step.action_name),script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="screen_control") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,BattleEditor_ScreenActionName(draw_step.screen_action),script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="play_sound") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,BattleEditor_SoundOptionCaption(draw_step.sound_name,project)+" · "+BattleEditor_SoundTimingName(draw_step.sound_timing),script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="enemy_appearance"){
                var appearance_enemy=BattleEditor_FindEnemyByUid(project,draw_step.enemy_uid);
                TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,(is_undefined(appearance_enemy)?"未选择敌人":appearance_enemy.name)+" / "+BattleEditor_EnemyPartName(draw_step.enemy_part_key)+" / "+BattleEditor_EnemyResourceCaption(project,draw_step.enemy_resource_uid),script_zoom*0.72,script_zoom*0.72,0);
            }
            else if(draw_step.kind=="get_value") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,draw_step.read_variable_name+" ← "+BattleEditor_ValuePropertyName(draw_step.read_property),script_zoom*0.72,script_zoom*0.72,0);
            else if(draw_step.kind=="run_script") TextTyper_DrawFallbackTransformed(list_x+8*script_zoom,step_y+24*script_zoom,"旧任意脚本已禁用",script_zoom*0.72,script_zoom*0.72,0);
        }
        BattleEditor_UiScissor(stack_scissor);
        BattleEditor_WorkspaceDrawOutline(id,draw_list,list_x,list_y,list_w,list_h,header_h,script_zoom,selected_list,draw_visible_count);
    }
    if(script_link_drag&&script_link_source_list>=0&&script_link_source_step>=0){
        var link_source=project.script_lists[script_link_source_list];
        var live_port=BattleEditor_WorkspacePortPosition(id,link_source,script_link_source_step);
        _editor_bezier(live_port.x,live_port.y,editor_mouse.x,editor_mouse.y,make_color_rgb(115,190,255),2);
    }

    if(script_selected_list>=0&&script_selected_list<array_length(project.script_lists)){
        var inspector_transition_old_world=matrix_get(matrix_world);
        var inspector_transition_reveal=1-power(1-clamp(script_inspector_anim_progress,0,1),3);
        var inspector_transition_offset=(1-inspector_transition_reveal)*230;
        matrix_set(matrix_world,matrix_build(inspector_transition_offset,0,0,0,0,0,1,1,1));
        var inspector_list=project.script_lists[script_selected_list];
        draw_set_alpha(0.98);draw_set_color(make_color_rgb(17,24,34));draw_roundrect_ext(420,36,638,450,9,9,false);
        draw_set_alpha(1);draw_set_color(make_color_rgb(72,94,118));draw_roundrect_ext(420,36,638,450,9,9,true);
        draw_set_color(make_color_rgb(151,194,229));TextTyper_DrawFallback(430,44,script_selected_step>=0?"项目属性":"列表属性");
        draw_set_color(c_gray);TextTyper_DrawFallback(430,68,"列表名称");
        _editor_field(430,84,628,106,inspector_list.name,"script_list_name");
        draw_set_color(c_gray);TextTyper_DrawFallback(430,110,"触发条件");
        if(BattleEditor_WorkspaceHasHeader(inspector_list)) _editor_button(430,126,628,148,_editor_ellipsis(BattleEditor_ScriptEntryName(inspector_list.entry_kind,inspector_list.entry_value,project),174)+"  ▼",script_dropdown=="entry_kind");
        else {draw_set_color(c_ltgray);TextTyper_DrawFallback(430,130,"游离积木：拖事件头接到上方");}
        if(inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN||inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE){
            draw_set_color(c_gray);TextTyper_DrawFallback(430,152,"触发数值");
            _editor_field(518,150,628,172,inspector_list.entry_value,"script_entry_value");
        }else if(inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED){
            draw_set_color(c_gray);TextTyper_DrawFallback(430,152,"触发物品");
            _editor_button(498,150,628,172,string_copy(BattleEditor_ItemTriggerCaption(project,inspector_list.entry_value),1,15)+"  ▼",script_dropdown=="item_entry");
        }else if(inspector_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION){
            draw_set_color(c_gray);TextTyper_DrawFallback(430,152,"触发行动");
            _editor_button(498,150,628,172,_editor_ellipsis(BattleEditor_ActionTriggerCaption(project,inspector_list.entry_value),104)+"  ▼",script_dropdown=="action_entry");
        }
        if(script_selected_step>=0&&script_selected_step<array_length(inspector_list.steps)){
            var inspector_step=inspector_list.steps[script_selected_step];
            var inspector_kind_name=BattleEditor_ScriptStepName(inspector_step.kind);
            var inspector_can_warning=inspector_step.kind=="control_object"&&(inspector_step.property=="position"||inspector_step.property=="orbit"||inspector_step.property=="physics"||inspector_step.property=="aim_motion");
            if(inspector_step.kind=="play_sound"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,178,"项目类型");
                _editor_button(510,176,628,198,inspector_kind_name+"  ▼",script_dropdown=="kind");
            }else if(inspector_can_warning){
                _editor_button(430,176,476,198,inspector_step.step_sound_enabled?"音效√":"音效",script_step_sound_open);
                _editor_button(480,176,530,198,inspector_step.warning_enabled?"警告√":"警告",script_step_warning_open);
                _editor_button(534,176,628,198,inspector_kind_name+" ▼",script_dropdown=="kind");
            }else{
                _editor_button(430,176,504,198,inspector_step.step_sound_enabled?"音效 开":"音效",script_step_sound_open);
                _editor_button(510,176,628,198,inspector_kind_name+"  ▼",script_dropdown=="kind");
            }
            if(script_step_sound_open&&inspector_step.kind!="play_sound"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"此项目执行音效");
                _editor_button(430,234,594,258,_editor_ellipsis(BattleEditor_SoundOptionCaption(inspector_step.sound_name,project),142)+"  ▼",script_dropdown=="sound_name");_editor_audio_preview_button(600,234,628,258,"workspace_"+string(inspector_step.uid));
                TextTyper_DrawFallback(430,274,"播放时机");
                _editor_button(430,292,628,316,BattleEditor_SoundTimingName(inspector_step.sound_timing)+"  ▼",script_dropdown=="sound_timing");
                _editor_button(430,330,628,354,inspector_step.step_sound_enabled?"[X] 启用这个项目的音效":"[ ] 启用这个项目的音效",inspector_step.step_sound_enabled);
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,366,"直接附着在这个项目上，不需要再拖入“播放音效”。关闭时保留选择但不会播放。",18,194);
            }else if(script_step_warning_open&&inspector_can_warning){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"移动前警告线");
                _editor_button(430,234,628,258,inspector_step.warning_enabled?"[X] 启用警告线":"[ ] 启用警告线",inspector_step.warning_enabled);
                TextTyper_DrawFallback(430,274,"警告帧数");_editor_field(530,270,628,294,inspector_step.warning_duration,"script_warning_duration");
                var warning_auto_direction_name=inspector_step.property=="aim_motion"?"瞄准目标":"贴图方向";
                TextTyper_DrawFallback(430,310,"朝向来源");_editor_button(530,306,628,330,round(real(inspector_step.warning_angle_mode))==0?warning_auto_direction_name:"自定义角度",false);
                if(round(real(inspector_step.warning_angle_mode))==1){TextTyper_DrawFallback(430,346,"警告线角度");_editor_field(530,342,628,366,inspector_step.warning_angle,"script_warning_angle");}
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,382,"这是本次移动的前置预告；任何可移动对象都能使用。结束后才开始移动。",18,194);
            }else if(inspector_step.kind=="create_object"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,204,"创建分类");
                _editor_button(510,202,628,224,BattleEditor_ObjectPaletteCategoryName(inspector_step.create_category)+" ▼",script_dropdown=="create_category");
                TextTyper_DrawFallback(430,232,"对象");
                _editor_button(510,230,628,252,BattleEditor_WorkspaceCreatePresetName(inspector_step.create_preset)+" ▼",script_dropdown=="create_preset");
                TextTyper_DrawFallback(430,260,"Control ID");_editor_field(510,258,628,280,inspector_step.create_control_id,"script_create_control_id");
                var create_is_board=inspector_step.create_preset=="board_add"||inspector_step.create_preset=="board_subtract";
                var create_has_damage=!create_is_board&&inspector_step.create_preset!="decoration"&&inspector_step.create_preset!="typewriter"&&inspector_step.create_preset!="platform";
                if(create_is_board){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,288,"中心 X / Y");
                    _editor_field(474,286,548,308,inspector_step.create_x,"script_create_x");
                    _editor_field(554,286,628,308,inspector_step.create_y,"script_create_y");
                    TextTyper_DrawFallback(430,316,"角度 / 每帧旋转");
                    _editor_field(510,314,566,336,inspector_step.create_angle,"script_create_angle");
                    _editor_field(572,314,628,336,inspector_step.create_board_rotate,"script_create_board_rotate");
                    TextTyper_DrawFallback(430,344,"生命周期 / 绘制深度");
                    _editor_field(510,342,566,364,BattleEditor_LifetimeCaption(inspector_step.create_lifetime),"script_create_lifetime");
                    _editor_field(572,342,628,364,inspector_step.create_board_depth,"script_create_board_depth");
                    TextTyper_DrawFallback(430,372,"形状");
                    _editor_button(510,370,628,392,BattleEditor_ControlChoiceCaption("shape",inspector_step.create_board_shape)+" ▼",script_dropdown=="create_board_shape");
                    if(inspector_step.create_board_shape==0){
                        TextTyper_DrawFallback(430,400,"上 / 下");
                        _editor_field(474,398,548,420,inspector_step.create_board_up,"script_create_board_up");
                        _editor_field(554,398,628,420,inspector_step.create_board_down,"script_create_board_down");
                        TextTyper_DrawFallback(430,428,"左 / 右");
                        _editor_field(474,426,548,448,inspector_step.create_board_left,"script_create_board_left");
                        _editor_field(554,426,628,448,inspector_step.create_board_right,"script_create_board_right");
                    }else if(inspector_step.create_board_shape==1){
                        TextTyper_DrawFallback(430,400,"椭圆半径 X / Y");
                        _editor_field(510,398,566,420,inspector_step.create_board_radius_x,"script_create_board_radius_x");
                        _editor_field(572,398,628,420,inspector_step.create_board_radius_y,"script_create_board_radius_y");
                    }else if(inspector_step.create_board_shape==2){
                        TextTyper_DrawFallback(430,400,"正三角形尺寸");
                        _editor_field(540,398,628,420,inspector_step.create_board_triangle_size,"script_create_board_triangle_size");
                    }else{
                        inspector_step.point_index=clamp(round(real(inspector_step.point_index)),0,max(0,array_length(inspector_step.points)-1));
                        var create_vertex=inspector_step.points[inspector_step.point_index];
                        TextTyper_DrawFallback(430,400,"顶点 "+string(inspector_step.point_index+1)+" / "+string(array_length(inspector_step.points)));
                        _editor_field(510,398,566,420,create_vertex[0],"script_create_board_vertex_x");
                        _editor_field(572,398,628,420,create_vertex[1],"script_create_board_vertex_y");
                        _editor_button(430,426,474,448,"上个",false);_editor_button(478,426,522,448,"下个",false);
                        _editor_button(526,426,574,448,"新增",false);_editor_button(578,426,628,448,"删除",false);
                    }
                }else{
                    var create_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
                    var create_fields=BattleEditor_WorkspaceCreateFields(inspector_step.create_preset);
                    var create_old_scissor=gpu_get_scissor();
                    BattleEditor_UiScissor(420,284,218,166);
                    var create_cursor_y=286-script_create_scroll;
                    for(var create_field_index=0;create_field_index<array_length(create_fields);create_field_index++){
                        var create_field=create_fields[create_field_index];
                        var create_field_height=BattleEditor_WorkspaceCreateFieldHeight(create_field);
                        if(create_cursor_y+create_field_height>=284&&create_cursor_y<=450){
                            var create_field_label=create_field.label;
                            if(create_field.path=="visual_tint.color"){
                                var create_label_mode=clamp(round(real(BattleEditor_WorkspaceTemplateGet(create_template,"visual_tint.mode"))),0,2);
                                create_field_label=create_label_mode==2?"自由调色板":"颜色模板";
                            }
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,create_cursor_y,create_field_label);
                            if(create_field.kind=="frames"){
                                var create_frames=BattleEditor_WorkspaceTemplateGet(create_template,create_field.path);
                                var create_frame_count=array_length(create_frames);
                                inspector_step.create_animation_frame_index=clamp(round(real(inspector_step.create_animation_frame_index)),0,max(0,create_frame_count-1));
                                var create_frame_value=create_frame_count>0?create_frames[inspector_step.create_animation_frame_index]:"";
                                _editor_field(430,create_cursor_y+16,542,create_cursor_y+38,create_frame_value,"script_create_frame");
                                _editor_button(548,create_cursor_y+16,628,create_cursor_y+38,"选择",false);
                                _editor_button(430,create_cursor_y+42,468,create_cursor_y+62,"<",false);_editor_button(472,create_cursor_y+42,510,create_cursor_y+62,">",false);
                                _editor_button(514,create_cursor_y+42,552,create_cursor_y+62,"+",false);_editor_button(556,create_cursor_y+42,594,create_cursor_y+62,"-",false);
                                draw_set_color(c_ltgray);TextTyper_DrawFallback(600,create_cursor_y+44,create_frame_count<=0?"0":string(inspector_step.create_animation_frame_index+1)+"/"+string(create_frame_count));
                            }else{
                                var create_field_value=BattleEditor_WorkspaceTemplateGet(create_template,create_field.path);
                                if(create_field.kind=="clip_frames") _editor_button(430,create_cursor_y+16,628,create_cursor_y+38,"选择 "+string(array_length(create_field_value))+" 个框",script_dropdown=="create_clip_frames");
                                else if(create_field.kind=="choice"){
                                    if(create_field.choice=="bone_aim_behavior") create_field_value=!BattleEditor_WorkspaceTemplateGet(create_template,"aim_enabled")?0:(BattleEditor_WorkspaceTemplateGet(create_template,"aim_move_enabled")?2:1);
                                    var create_choice_right=create_field.choice=="voice"?594:628;
                                    _editor_button(430,create_cursor_y+16,create_choice_right,create_cursor_y+38,_editor_ellipsis(BattleEditor_WorkspaceCreateChoiceCaption(create_field.choice,create_field_value,project),create_field.choice=="voice"?140:174)+" ▼",script_dropdown=="create_template_choice"&&script_create_choice_path==create_field.path);
                                    if(create_field.choice=="voice") _editor_audio_preview_button(600,create_cursor_y+16,628,create_cursor_y+38,"workspace_create_"+string(inspector_step.uid)+"_voice");
                                }
                                else if(create_field.kind=="visual_template_toggle"){
                                    var create_uses_fixed_template=clamp(round(real(create_field_value)),0,2)!=2;
                                    _editor_button(430,create_cursor_y+16,628,create_cursor_y+38,create_uses_fixed_template?"[X] 使用固定颜色模板":"[ ] 使用自由颜色",create_uses_fixed_template);
                                }
                                else if(create_field.kind=="lifetime"){
                                    var create_lifetime_finite=real(create_field_value)>=0;
                                    _editor_button(430,create_cursor_y+16,542,create_cursor_y+38,create_lifetime_finite?"指定存活帧数 ▼":"本回合一直存在 ▼",script_dropdown=="create_template_choice"&&script_create_choice_path==create_field.path);
                                    if(create_lifetime_finite) _editor_field(548,create_cursor_y+16,628,create_cursor_y+38,create_field_value,"script_create_formula_"+create_field.path);
                                    else{draw_set_color(make_color_rgb(35,35,35));draw_rectangle(548,create_cursor_y+16,628,create_cursor_y+38,false);}
                                }
                                else if(create_field.kind=="bool") _editor_button(430,create_cursor_y+16,628,create_cursor_y+38,real(create_field_value)!=0?"[X] 开":"[ ] 关",real(create_field_value)!=0);
                                else if(create_field.kind=="color"){
                                    var create_draw_color=is_real(create_field_value)?create_field_value:GetColorFromString(create_field_value);
                                    var create_visual_mode=create_field.path=="visual_tint.color"?clamp(round(real(BattleEditor_WorkspaceTemplateGet(create_template,"visual_tint.mode"))),0,2):2;
                                    if(create_field.path=="visual_tint.color"&&create_visual_mode!=2){
                                        var create_visual_preset=create_visual_mode==0
                                            ?clamp(round(real(BattleEditor_WorkspaceTemplateGet(create_template,"damage_profile.type"))),0,8)
                                            :clamp(round(real(BattleEditor_WorkspaceTemplateGet(create_template,"visual_tint.preset_type"))),0,8);
                                        _editor_color_button(430,create_cursor_y+16,628,create_cursor_y+38,BattleEditor_ColorForType(create_visual_preset),BattleEditor_VisualColorPresetName(create_visual_preset)+" ▼");
                                    }else _editor_color_button(430,create_cursor_y+16,628,create_cursor_y+38,create_draw_color,BattleEditor_ColorToHex(create_draw_color,255));
                                }else if(create_field.kind=="path"){
                                    _editor_field(430,create_cursor_y+16,542,create_cursor_y+38,string(create_field_value),"script_create_text_"+create_field.path);
                                    _editor_button(548,create_cursor_y+16,628,create_cursor_y+38,"选择",false);
                                }
                                else _editor_field(430,create_cursor_y+16,628,create_cursor_y+38,create_field_value,(create_field.kind=="text"?"script_create_text_":"script_create_formula_")+create_field.path);
                            }
                        }
                        create_cursor_y+=create_field_height;
                    }
                    BattleEditor_UiScissor(create_old_scissor);
                }
            }else if(inspector_step.kind=="control_object"){
                var copy_control_mode=round(real(inspector_step.control_source_mode))==1;
                _editor_button(430,202,526,224,"控制原件",!copy_control_mode);
                _editor_button(532,202,628,224,"复制后控制",copy_control_mode);
                var target_group_kind=struct_exists(inspector_step,"target_group_kind")?string(inspector_step.target_group_kind):"";
                var target_caption=copy_control_mode?"选择复制来源":"选择控制目标";
                if(string_length(inspector_step.target)>0){
                    if(target_group_kind!="") target_caption=BattleEditor_ControlGroupName(target_group_kind)+" · "+inspector_step.target;
                    else target_caption=inspector_step.target+" · "+BattleEditor_TargetTypeName(inspector_step.target_type);
                }
                if(copy_control_mode){
                    _editor_button(430,228,482,250,_editor_ellipsis(BattleEditor_ControlCategoryName(inspector_step.target_category),36)+" ▼",script_dropdown=="target_category");
                    _editor_button(486,228,554,250,_editor_ellipsis(target_caption,50)+" ▼",script_dropdown=="target");
                    draw_set_color(c_gray);TextTyper_DrawFallback(557,232,">");
                    _editor_field(568,228,628,250,inspector_step.copy_control_id,"script_copy_control_id");
                }else{
                    _editor_button(430,228,494,250,_editor_ellipsis(BattleEditor_ControlCategoryName(inspector_step.target_category),48)+" ▼",script_dropdown=="target_category");
                    _editor_button(498,228,628,250,_editor_ellipsis(target_caption,112)+" ▼",script_dropdown=="target");
                }
                draw_set_color(c_gray);TextTyper_DrawFallback(430,256,"参数");
                _editor_button(474,254,530,276,BattleEditor_ControlPropertyCategoryName(inspector_step.property_category)+" ▼",script_dropdown=="property_category");
                _editor_button(534,254,628,276,string_copy(BattleEditor_ControlPropertyName(inspector_step.property,inspector_step.target_type),1,7)+" ▼",script_dropdown=="property");
                if(inspector_step.property=="control_vertex"){
                    _editor_button(430,282,628,304,"到战斗画面点选顶点",false);
                    draw_set_color(c_ltgray);TextTyper_DrawFallback(430,308,"已选 "+string(array_length(inspector_step.vertex_uids))+" 个顶点");
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,326,inspector_step.coordinate_mode=="relative"?"位移 X":"目标 X");TextTyper_DrawFallback(532,326,inspector_step.coordinate_mode=="relative"?"位移 Y":"目标 Y");
                    _editor_field(450,342,524,364,inspector_step.vertex_target_x,"script_vertex_x");
                    _editor_field(552,342,628,364,inspector_step.vertex_target_y,"script_vertex_y");
                    _editor_button(430,370,628,392,"坐标模式："+(inspector_step.coordinate_mode=="relative"?"相对位移":"绝对位置"),script_dropdown=="coordinate_mode");
                }else if(inspector_step.property=="position"){
                    var position_is_board=inspector_step.target_type=="board";
                    _editor_button(430,282,628,304,(position_is_board?"变换模式：":"移动模式：")+(inspector_step.coordinate_mode=="relative"?(position_is_board?"相对变化":"相对位移"):(position_is_board?"目标状态":"目标位置")),script_dropdown=="coordinate_mode");
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,312,"X（空=不改）");TextTyper_DrawFallback(532,312,"Y（空=不改）");
                    _editor_field(430,328,526,350,inspector_step.position_x,"script_position_x");
                    _editor_field(532,328,628,350,inspector_step.position_y,"script_position_y");
                    if(position_is_board){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,356,"角度");TextTyper_DrawFallback(498,356,"宽度");TextTyper_DrawFallback(568,356,"高度");
                        _editor_field(430,372,492,394,inspector_step.position_angle,"script_position_angle");
                        _editor_field(498,372,558,394,inspector_step.board_transform_width,"script_board_transform_width");
                        _editor_field(568,372,628,394,inspector_step.board_transform_height,"script_board_transform_height");
                    }else{
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,356,inspector_step.coordinate_mode=="relative"?"角度位移（留空不控制）":"目标角度（留空不控制）");
                        _editor_field(430,372,628,394,inspector_step.position_angle,"script_position_angle");
                    }
                }else if(inspector_step.property=="orbit"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"总旋转角度");
                    _editor_field(510,282,628,304,inspector_step.value,"script_value");
                    _editor_button(430,310,628,332,inspector_step.orbit_use_group_center?"中心：对象组中心":"中心：自定义坐标",inspector_step.orbit_use_group_center);
                    if(!inspector_step.orbit_use_group_center){
                        _editor_field(430,338,526,360,inspector_step.orbit_center_x,"script_orbit_center_x");
                        _editor_field(532,338,628,360,inspector_step.orbit_center_y,"script_orbit_center_y");
                    }
                }else if(inspector_step.property=="physics"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"移动方向");_editor_field(510,282,628,304,inspector_step.physics_direction,"script_physics_direction");
                    TextTyper_DrawFallback(430,312,"初始速度");_editor_field(510,310,628,332,inspector_step.physics_speed,"script_physics_speed");
                    TextTyper_DrawFallback(430,340,"加速度");_editor_field(510,338,628,360,inspector_step.physics_acceleration,"script_physics_acceleration");
                    TextTyper_DrawFallback(430,368,"弯曲角速");_editor_field(510,366,628,388,inspector_step.physics_curve_speed,"script_physics_curve_speed");
                    TextTyper_DrawFallback(430,396,"自转角速");_editor_field(510,394,628,416,inspector_step.physics_rotation_speed,"script_physics_rotation_speed");
                    TextTyper_DrawFallback(430,424,"时长(帧)");_editor_field(510,422,628,444,inspector_step.duration,"script_duration");
                }else if(inspector_step.property=="aim_motion"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"瞄准目标");
                    _editor_button(510,282,628,304,_editor_ellipsis(BattleEditor_AimTargetCaption(project,inspector_step.aim_target_uid),104)+" ▼",script_dropdown=="aim_target_value");
                    TextTyper_DrawFallback(430,312,"行为");
                    _editor_button(510,310,628,332,BattleEditor_AimBehaviorName(inspector_step.aim_behavior)+" ▼",script_dropdown=="aim_behavior");
                    TextTyper_DrawFallback(430,340,"方向更新");
                    _editor_button(510,338,628,360,(inspector_step.aim_continuous?"持续追踪目标":"执行时锁定一次")+" ▼",script_dropdown=="aim_motion_mode");
                    if(inspector_step.aim_behavior!=0){TextTyper_DrawFallback(430,368,"移动速度");_editor_field(510,366,628,388,inspector_step.aim_move_speed,"script_aim_move_speed");}
                    else{draw_set_color(c_ltgray);TextTyper_DrawFallback(430,370,"仅改变朝向，不移动位置");}
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,396,"移动时长(帧)");_editor_field(530,394,628,416,inspector_step.duration,"script_duration");
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,422,inspector_step.aim_continuous?"每帧重算目标方向；这是追踪弹。":"执行时只取一次方向，之后沿直线越过原目标点。",18,194);
                }else if(inspector_step.property=="shape"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"目标形状");
                    _editor_button(510,282,628,304,BattleEditor_ControlChoiceCaption("shape",inspector_step.value)+" ▼",script_dropdown=="choice_value");
                    var controlled_board_shape=clamp(round(real(inspector_step.value)),0,3);
                    if(controlled_board_shape==0){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,312,"宽 / 高");
                        _editor_field(430,328,526,350,inspector_step.board_shape_width,"script_board_shape_width");
                        _editor_field(532,328,628,350,inspector_step.board_shape_height,"script_board_shape_height");
                    }else if(controlled_board_shape==1){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,312,"半径 X / Y");
                        _editor_field(430,328,526,350,inspector_step.board_shape_radius_x,"script_board_shape_radius_x");
                        _editor_field(532,328,628,350,inspector_step.board_shape_radius_y,"script_board_shape_radius_y");
                    }else if(controlled_board_shape==2){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,312,"底宽 / 高");
                        _editor_field(430,328,526,350,inspector_step.board_shape_triangle_width,"script_board_shape_triangle_width");
                        _editor_field(532,328,628,350,inspector_step.board_shape_triangle_height,"script_board_shape_triangle_height");
                    }else{
                        draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,316,"多边形保留当前顶点；需要细调时使用“控制顶点”。",18,194);
                    }
                }else if(inspector_step.property=="speak"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"台词");_editor_button(510,282,628,304,"编辑文本",false);
                    TextTyper_DrawFallback(430,316,"字体 / 音色");
                    _editor_button(510,312,556,336,string(round(real(inspector_step.dialogue_font)))+" ▼",font_dropdown_open&&font_dropdown_target=="script_enemy_speech");
                    _editor_button(560,312,600,336,BattleEditor_VoiceName(inspector_step.dialogue_voice)+" ▼",choice_menu_open&&choice_menu_context=="script_enemy_voice");
                    _editor_audio_preview_button(604,312,628,336,"script_enemy_voice_"+string(inspector_step.uid));
                    TextTyper_DrawFallback(430,348,"气泡");_editor_button(510,344,628,368,_editor_ellipsis(BattleEditor_DialogueTemplateName(inspector_step.dialogue_template),104)+" ▼",choice_menu_open&&choice_menu_context=="script_enemy_template");
                    TextTyper_DrawFallback(430,380,"偏移 X / Y");_editor_field(510,376,566,400,inspector_step.dialogue_offset_x,"script_dialogue_offset_x");_editor_field(572,376,628,400,inspector_step.dialogue_offset_y,"script_dialogue_offset_y");
                    TextTyper_DrawFallback(430,408,"推进");_editor_button(510,404,628,428,BattleEditor_EditorChoiceCaption("dialogue_mode",inspector_step.dialogue_mode)+" ▼",choice_menu_open&&choice_menu_context=="script_enemy_mode");
                    _editor_button(430,434,628,458,inspector_step.dialogue_block_battle?"[X] 等待气泡结束再继续":"[ ] 与后续脚本同时执行",inspector_step.dialogue_block_battle);
                }else if(inspector_step.property=="gb_hold"||inspector_step.property=="gb_release"){
                    draw_set_color(c_yellow);TextTyper_DrawFallback(430,286,inspector_step.property=="gb_hold"?"把待发射时间延长到 999 帧":"结束等待并进入原有发射动画");
                    if(inspector_step.property=="gb_hold") _editor_button(430,318,628,342,inspector_step.gb_move_sound?"[X] 播放默认 GB 等待音效":"[ ] 不播放默认 GB 音效",inspector_step.gb_move_sound);
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,360,inspector_step.property=="gb_hold"?"之后可用普通移动、物理移动、变色等控制；完成后再放一个“GB 立即发射”。":"不重新创建 GB，直接推进当前 GB 自己的 Alarm 时序。",18,194);
                }else if(inspector_step.property!="physics"&&inspector_step.property!="aim_motion"&&inspector_step.property!="shape"){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,284,"目标值");
                    if(inspector_step.property=="player_name") _editor_field(510,282,628,304,inspector_step.text_value,"script_text_value");
                    else if(inspector_step.property=="aim_target_uid") _editor_button(510,282,628,304,_editor_ellipsis(BattleEditor_AimTargetCaption(project,inspector_step.value),104)+" ▼",script_dropdown=="aim_target_value");
                    else if(inspector_step.property=="color"||inspector_step.property=="visual_color"||inspector_step.property=="color_frame") _editor_color_button(510,282,628,304,inspector_step.value,BattleEditor_ColorToHex(inspector_step.value,255));
                    else if(BattleEditor_IsBooleanControlProperty(inspector_step.property)){
                        var boolean_caption=real(inspector_step.value)!=0?"开":"关";
                        if(inspector_step.property=="follow") boolean_caption=real(inspector_step.value)!=0?"[X] 跟随战斗框":"[ ] 不跟随战斗框";
                        _editor_button(510,282,628,304,boolean_caption,real(inspector_step.value)!=0);
                    }
                    else if(BattleEditor_IsChoiceControlProperty(inspector_step.property)){
                        var choice_caption=BattleEditor_ControlChoiceCaption(inspector_step.property,inspector_step.value);
                        _editor_button(510,282,628,304,(inspector_step.property=="mask_color"?"     ":"")+choice_caption+" ▼",script_dropdown=="choice_value");
                        if(inspector_step.property=="mask_color"){
                            draw_set_color(BattleEditor_MaskColorValue(inspector_step.value));draw_rectangle(514,286,526,300,false);
                            draw_set_color(c_white);draw_rectangle(513,285,527,301,true);
                        }
                    }
                    else _editor_field(510,282,628,304,inspector_step.value,"script_value");
                }
                if(inspector_step.property=="follow"&&real(inspector_step.value)!=0){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,316,"目标框");
                    _editor_button(510,312,628,336,_editor_ellipsis(BattleEditor_FollowFrameCaption(project,inspector_step.follow_target_uid),104)+" ▼",script_dropdown=="control_follow_frame");
                }
                if(inspector_step.property=="damage_type") _editor_button(430,312,628,334,inspector_step.damage_change_visual?"[X] 同时修改显示颜色":"[ ] 只修改伤害判定",inspector_step.damage_change_visual);
                var bone_length_control=inspector_step.target_type=="bone"&&inspector_step.property=="length";
                if(bone_length_control){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,312,"长度锚点");
                    _editor_button(510,310,628,332,BattleEditor_LengthAnchorName(inspector_step.length_anchor)+" ▼",script_dropdown=="length_anchor");
                    draw_set_color(c_ltgray);TextTyper_DrawFallback(430,336,"头 > 尾（随对象角度）");
                }
                var instant_special_control=inspector_step.property=="speak"||inspector_step.property=="gb_hold"||inspector_step.property=="gb_release";
                var soul_system_control=inspector_step.target_type=="soul"&&(inspector_step.property=="soul_mode"||inspector_step.property=="blue_direction");
                if(soul_system_control){
                    var soul_mode_selected=inspector_step.property=="soul_mode"?clamp(round(real(inspector_step.value)),0,6):1;
                    if(soul_mode_selected==1){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,316,"蓝魂方向");
                        var soul_direction_choice=inspector_step.property=="soul_mode"?inspector_step.soul_blue_direction:inspector_step.value;
                        _editor_button(510,312,628,336,BattleEditor_BlueDirectionName(soul_direction_choice)+" ▼",script_dropdown=="soul_blue_direction");
                        _editor_button(430,342,628,366,inspector_step.blue_gravity_throw?"[X] 同时施加重力甩动":"[ ] 同时施加重力甩动",inspector_step.blue_gravity_throw);
                        draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,372,"不勾只切换模式和方向；勾选会把蓝魂甩向所选方向。",18,194);
                    }else{
                        draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,314,"执行到这一项时立即切换灵魂；选择蓝魂后会显示方向和重力甩动选项。",18,194);
                    }
                }else if(inspector_step.property!="physics"&&inspector_step.property!="aim_motion"&&BattleEditor_ControlStepUsesDuration(inspector_step)){
                    var timing_y=inspector_step.property=="control_vertex"?398:(inspector_step.property=="position"?400:(inspector_step.property=="orbit"?394:(inspector_step.property=="shape"?360:(bone_length_control?360:312))));
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,timing_y+2,"时长(帧)");_editor_field(510,timing_y,628,timing_y+22,inspector_step.duration,"script_duration");
                    _editor_button(430,timing_y+28,528,timing_y+50,"Tween: "+string(inspector_step.tween),script_dropdown=="tween");
                    _editor_button(532,timing_y+28,628,timing_y+50,"Ease: "+string(inspector_step.ease),script_dropdown=="ease");
                }
            }else if(inspector_step.kind=="wait"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"等待方式");
                _editor_button(430,234,628,258,BattleEditor_WaitModeName(inspector_step.wait_mode)+"  ▼",script_dropdown=="wait_mode");
                if(round(real(inspector_step.wait_mode))==0){
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,276,"等待时长（帧）");
                    _editor_field(430,296,628,320,inspector_step.duration,"script_duration");
                }else{
                    draw_set_color(c_gray);TextTyper_DrawFallback(430,276,"完成后额外等待（帧）");
                    _editor_field(430,296,628,320,inspector_step.wait_extra_duration,"script_wait_extra_duration");
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,328,"先等上一组并行步骤全部完成，再追加这里的等待时间。",18,194);
                }
            }else if(inspector_step.kind=="start_list"){
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,214,"拖右端口 > 列表头左端口",18,190);
            }else if(inspector_step.kind=="builtin_action"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"内建攻击函数");
                var function_path_inspector=inspector_step.action_name=="bone_function_path";
                var builtin_follow_available=BattleEditor_BuiltinActionCanFollow(inspector_step.action_name);
                var builtin_action_right=function_path_inspector?500:(builtin_follow_available?542:628);
                _editor_button(430,234,builtin_action_right,256,_editor_ellipsis(BattleEditor_BuiltinActionName(inspector_step.action_name),builtin_action_right-442)+" ▼",script_dropdown=="builtin_action");
                if(builtin_follow_available){
                    var builtin_follow_left=function_path_inspector?504:546;
                    var builtin_follow_right=function_path_inspector?562:628;
                    _editor_button(builtin_follow_left,234,builtin_follow_right,256,inspector_step.action_follow?"[X]跟随":"[ ]跟随",inspector_step.action_follow);
                }
                if(function_path_inspector) _editor_button(566,234,628,256,script_function_preview_uid==inspector_step.uid?"[X]轨迹":"[ ]轨迹",script_function_preview_uid==inspector_step.uid);
                if(inspector_step.action_name=="board_shape"){
                    var board_shape_defaults=BattleEditor_BuiltinActionDefaults("board_shape");
                    var board_shape_value=BattleEditor_ActionArgumentText(inspector_step.action_arguments,0,board_shape_defaults);
                    var board_shape_duration=BattleEditor_ActionArgumentText(inspector_step.action_arguments,1,board_shape_defaults);
                    var board_shape_labels=["目标控制 ID","目标形状","过渡帧数","曲线类型","缓动方向"];
                    for(var board_shape_row=0;board_shape_row<5;board_shape_row++){
                        var board_shape_y=264+board_shape_row*32;
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,board_shape_y+5,board_shape_labels[board_shape_row]);
                        if(board_shape_row==0) _editor_button(510,board_shape_y+2,628,board_shape_y+24,_editor_ellipsis(inspector_step.action_control_id,100)+"  ▼",script_dropdown=="board_shape_target");
                        else if(board_shape_row==1) _editor_button(510,board_shape_y+2,628,board_shape_y+24,BattleEditor_ActionParameterChoiceCaption("board_shape",BattleEditor_ReadNumberText(board_shape_value,1),"board_shape")+"  ▼",script_dropdown=="parameter_choice"&&script_parameter_choice_scope=="builtin"&&script_parameter_choice_index==0);
                        else if(board_shape_row==2) _editor_field(510,board_shape_y+2,628,board_shape_y+24,board_shape_duration,"script_action_param_1");
                        else if(board_shape_row==3) _editor_button(510,board_shape_y+2,628,board_shape_y+24,BattleEditor_TweenName(inspector_step.tween)+"  ▼",script_dropdown=="tween");
                        else _editor_button(510,board_shape_y+2,628,board_shape_y+24,BattleEditor_EaseName(inspector_step.ease)+"  ▼",script_dropdown=="ease");
                    }
                }else if(inspector_step.action_name=="bone_orbit"){
                    var orbit_defaults=BattleEditor_BuiltinActionDefaults("bone_orbit");
                    var orbit_visible_rows=6;
                    for(var orbit_visible_index=0;orbit_visible_index<orbit_visible_rows;orbit_visible_index++){
                        var orbit_row=script_parameter_scroll+orbit_visible_index;
                        if(orbit_row>=11) break;
                        var orbit_y=264+orbit_visible_index*28;
                        var orbit_value_a="",orbit_value_b="";
                        if(orbit_row==0){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,"Control ID");
                            _editor_field(510,orbit_y+2,628,orbit_y+24,inspector_step.action_control_id,"script_action_control_id");
                        }else if(orbit_row==1){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,"模板");
                            _editor_button(478,orbit_y+2,628,orbit_y+24,_editor_ellipsis(BattleEditor_ActionTemplateCaption(project,inspector_step.action_source_uid),136)+" ▼",script_dropdown=="action_template");
                        }else if(orbit_row==2||orbit_row==3){
                            var orbit_pair_start=orbit_row==2?0:2;
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,orbit_row==2?"中心":"半径");
                            TextTyper_DrawFallback(468,orbit_y+5,"X");TextTyper_DrawFallback(548,orbit_y+5,"Y");
                            orbit_value_a=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_start,orbit_defaults);
                            orbit_value_b=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_start+1,orbit_defaults);
                            _editor_field(480,orbit_y+2,544,orbit_y+24,orbit_value_a,"script_action_param_"+string(orbit_pair_start));
                            _editor_field(560,orbit_y+2,628,orbit_y+24,orbit_value_b,"script_action_param_"+string(orbit_pair_start+1));
                        }else if(orbit_row==4||orbit_row==5){
                            var orbit_pair_start=orbit_row==4?4:6;
                            var orbit_label_a=orbit_row==4?"数量":"转速";
                            var orbit_label_b=orbit_row==4?"起始角":"朝向偏移";
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,orbit_label_a);TextTyper_DrawFallback(522,orbit_y+5,orbit_label_b);
                            orbit_value_a=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_start,orbit_defaults);
                            orbit_value_b=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_pair_start+1,orbit_defaults);
                            _editor_field(466,orbit_y+2,516,orbit_y+24,orbit_value_a,"script_action_param_"+string(orbit_pair_start));
                            _editor_field(578,orbit_y+2,628,orbit_y+24,orbit_value_b,"script_action_param_"+string(orbit_pair_start+1));
                        }else if(orbit_row==6){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,"长度");
                            orbit_value_a=BattleEditor_ActionArgumentText(inspector_step.action_arguments,8,orbit_defaults);
                            _editor_field(478,orbit_y+2,628,orbit_y+24,orbit_value_a,"script_action_param_8");
                        }else if(orbit_row==7){
                            var orbit_color=BattleEditor_ActionArgumentText(inspector_step.action_arguments,12,orbit_defaults);
                            var orbit_layer=BattleEditor_ActionArgumentText(inspector_step.action_arguments,13,orbit_defaults);
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,"颜色");TextTyper_DrawFallback(526,orbit_y+5,"层级");
                            _editor_button(466,orbit_y+2,520,orbit_y+24,_editor_ellipsis(BattleEditor_DamageTypeName(BattleEditor_ReadNumberText(orbit_color,0)),48)+" ▼",script_dropdown=="parameter_choice"&&script_parameter_choice_index==12);
                            _editor_button(562,orbit_y+2,628,orbit_y+24,_editor_ellipsis(BattleEditor_LayerName(BattleEditor_ReadNumberText(orbit_layer,1)),58)+" ▼",script_dropdown=="parameter_choice"&&script_parameter_choice_index==13);
                        }else if(orbit_row==8||orbit_row==10){
                            var orbit_phase_entry=orbit_row==8;
                            var orbit_time_index=orbit_phase_entry?9:11;
                            orbit_value_a=BattleEditor_ActionArgumentText(inspector_step.action_arguments,orbit_time_index,orbit_defaults);
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,orbit_phase_entry?"进场":"退场");
                            _editor_field(466,orbit_y+2,510,orbit_y+24,orbit_value_a,"script_action_param_"+string(orbit_time_index));
                            _editor_button(514,orbit_y+2,570,orbit_y+24,_editor_ellipsis(BattleEditor_TweenName(orbit_phase_entry?inspector_step.tween:inspector_step.action_exit_tween),48)+" ▼",script_dropdown==(orbit_phase_entry?"tween":"action_exit_tween"));
                            _editor_button(574,orbit_y+2,628,orbit_y+24,_editor_ellipsis(BattleEditor_EaseName(orbit_phase_entry?inspector_step.ease:inspector_step.action_exit_ease),46)+" ▼",script_dropdown==(orbit_phase_entry?"ease":"action_exit_ease"));
                        }else{
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,orbit_y+5,"维持(-1=回合)");
                            orbit_value_a=BattleEditor_ActionArgumentText(inspector_step.action_arguments,10,orbit_defaults);
                            _editor_field(548,orbit_y+2,628,orbit_y+24,orbit_value_a,"script_action_param_10");
                        }
                    }
                    _editor_button(430,430,628,450,inspector_step.action_damage_change_visual?"[X] 同时修改显示颜色":"[ ] 只修改伤害判定",inspector_step.action_damage_change_visual);
                }else if(inspector_step.action_name=="bone_wall"){
                    var wall_single_direction=inspector_step.action_direction<=4;
                    var wall_x_label=wall_single_direction?"目标 X":"中心 X";
                    var wall_y_label=wall_single_direction?"目标 Y":"中心 Y";
                    var wall_extent_label=wall_single_direction?"目标高度":"中心半径";
                    var wall_labels=["控制 ID","方向","复制对象模板",wall_x_label,wall_y_label,"宽度","间距",wall_extent_label,"骨头长度","进退速度","停留帧","颜色","层级","进场曲线","进场缓动","退场曲线","退场缓动","警告框","警告帧数"];
                    var wall_defaults=BattleEditor_BuiltinActionDefaults("bone_wall");
                    var wall_visible_rows=6;
                    for(var wall_visible_index=0;wall_visible_index<wall_visible_rows;wall_visible_index++){
                        var wall_row=script_parameter_scroll+wall_visible_index;
                        if(wall_row>=array_length(wall_labels)) break;
                        var wall_row_y=264+wall_visible_index*28;
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,wall_row_y+5,wall_labels[wall_row]);
                        if(wall_row==0) _editor_field(510,wall_row_y+2,628,wall_row_y+24,inspector_step.action_control_id,"script_action_control_id");
                        else if(wall_row==1) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_BoneWallDirectionName(inspector_step.action_direction)+"  ▼",script_dropdown=="builtin_wall_direction");
                        else if(wall_row==2) _editor_button(510,wall_row_y+2,628,wall_row_y+24,_editor_ellipsis(BattleEditor_ActionTemplateCaption(project,inspector_step.action_source_uid),104)+" ▼",script_dropdown=="action_template");
                        else if(wall_row==13) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_TweenName(inspector_step.tween)+"  ▼",script_dropdown=="tween");
                        else if(wall_row==14) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_EaseName(inspector_step.ease)+"  ▼",script_dropdown=="ease");
                        else if(wall_row==15) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_TweenName(inspector_step.action_exit_tween)+"  ▼",script_dropdown=="action_exit_tween");
                        else if(wall_row==16) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_EaseName(inspector_step.action_exit_ease)+"  ▼",script_dropdown=="action_exit_ease");
                        else if(wall_row==17) _editor_button(510,wall_row_y+2,628,wall_row_y+24,inspector_step.warning_enabled?"[X] 启用":"[ ] 关闭",inspector_step.warning_enabled);
                        else if(wall_row==18) _editor_field(510,wall_row_y+2,628,wall_row_y+24,inspector_step.warning_duration,"script_warning_duration");
                        else{
                            var wall_argument_index=wall_row-3;
                            var wall_argument=BattleEditor_ActionArgumentText(inspector_step.action_arguments,wall_argument_index,wall_defaults);
                            if(wall_argument_index==8) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_DamageTypeName(BattleEditor_ReadNumberText(wall_argument,0))+"  ▼",script_dropdown=="builtin_wall_color");
                            else if(wall_argument_index==9) _editor_button(510,wall_row_y+2,628,wall_row_y+24,BattleEditor_LayerName(BattleEditor_ReadNumberText(wall_argument,0))+"  ▼",script_dropdown=="builtin_wall_layer");
                            else _editor_field(510,wall_row_y+2,628,wall_row_y+24,wall_argument,"script_action_param_"+string(wall_argument_index));
                        }
                    }
                    _editor_button(430,430,628,450,inspector_step.action_damage_change_visual?"[X] 同时修改显示颜色":"[ ] 只修改伤害判定",inspector_step.action_damage_change_visual);
                }else{
                    var action_labels=BattleEditor_ActionParameterLabels("builtin",inspector_step.action_name);
                    var action_defaults=BattleEditor_BuiltinActionDefaults(inspector_step.action_name);
                    var action_is_path=inspector_step.action_name=="bone_function_path";
                    var action_path_existing=action_is_path&&round(real(inspector_step.action_path_mode))==1;
                    var action_has_template=BattleEditor_BuiltinActionUsesTemplate(inspector_step.action_name)&&!action_path_existing;
                    var action_prefix_rows=action_is_path?(action_path_existing?2:3):(1+(action_has_template?1:0));
                    var action_row_count=action_prefix_rows+array_length(action_labels);
                    for(var action_visible_index=0;action_visible_index<4;action_visible_index++){
                        var action_row=script_parameter_scroll+action_visible_index;
                        if(action_row>=action_row_count) break;
                        var action_row_y=264+action_visible_index*42;
                        if(action_is_path&&action_row==0){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,"对象来源");
                            _editor_button(430,action_row_y+16,628,action_row_y+38,BattleEditor_FunctionPathModeName(inspector_step.action_path_mode)+" ▼",script_dropdown=="function_path_mode");
                        }else if(action_is_path&&action_row==1){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,action_path_existing?"已有对象组":"副本 Control ID");
                            if(action_path_existing) _editor_button(430,action_row_y+16,628,action_row_y+38,_editor_ellipsis(BattleEditor_FunctionPathTargetCaption(project,inspector_step),182)+" ▼",script_dropdown=="function_path_target");
                            else _editor_field(430,action_row_y+16,628,action_row_y+38,inspector_step.action_control_id,"script_action_control_id");
                        }else if(action_is_path&&!action_path_existing&&action_row==2){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,"复制哪个对象");
                            _editor_button(430,action_row_y+16,628,action_row_y+38,_editor_ellipsis(BattleEditor_FunctionPathCloneCaption(project,inspector_step.action_source_uid,inspector_step.action_path_legacy_default),182)+" ▼",script_dropdown=="action_template");
                        }else if(!action_is_path&&action_row==0){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,"控制 ID");
                            _editor_field(430,action_row_y+16,628,action_row_y+38,inspector_step.action_control_id,"script_action_control_id");
                        }else if(!action_is_path&&action_has_template&&action_row==1){
                            draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,"复制对象模板");
                            _editor_button(430,action_row_y+16,628,action_row_y+38,_editor_ellipsis(BattleEditor_ActionTemplateCaption(project,inspector_step.action_source_uid),182)+" ▼",script_dropdown=="action_template");
                        }else{
                            var action_parameter_index=action_row-action_prefix_rows;
                            if(action_parameter_index<array_length(action_labels)){
                                var action_parameter_kind=BattleEditor_ActionParameterKind("builtin",inspector_step.action_name,action_parameter_index);
                                var action_parameter_value=BattleEditor_ActionArgumentText(inspector_step.action_arguments,action_parameter_index,action_defaults);
                                draw_set_color(c_gray);TextTyper_DrawFallback(430,action_row_y,action_labels[action_parameter_index]);
                                if(action_parameter_kind=="identifier") _editor_field(430,action_row_y+16,628,action_row_y+38,inspector_step.action_path_variable,"script_action_path_variable");
                                else if(action_parameter_kind=="expression") _editor_field(430,action_row_y+16,628,action_row_y+38,action_parameter_value,"script_action_param_"+string(action_parameter_index));
                                else _editor_button(430,action_row_y+16,628,action_row_y+38,BattleEditor_ActionParameterChoiceCaption(action_parameter_kind,BattleEditor_ReadNumberText(action_parameter_value,0),inspector_step.action_name)+"  ▼",script_dropdown=="parameter_choice"&&script_parameter_choice_scope=="builtin"&&script_parameter_choice_index==action_parameter_index);
                            }
                        }
                    }
                    _editor_button(430,430,628,450,inspector_step.action_damage_change_visual?"[X] 同时修改显示颜色":"[ ] 只修改伤害判定",inspector_step.action_damage_change_visual);
                }
            }else if(inspector_step.kind=="screen_control"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"画面 / 镜头 / 滤镜动作");
                _editor_button(430,234,628,256,BattleEditor_ScreenActionName(inspector_step.screen_action)+"  ▼",script_dropdown=="screen_action");
                var screen_labels=BattleEditor_ActionParameterLabels("screen",inspector_step.screen_action);
                var screen_defaults=BattleEditor_ScreenActionDefaults(inspector_step.screen_action);
                var screen_row_count=array_length(screen_labels)+(inspector_step.screen_action=="camera_set"?2:0);
                if(screen_row_count<=0){
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,272,"这个动作没有参数。执行时会恢复默认镜头并清除全部滤镜。",18,194);
                }else for(var screen_visible_index=0;screen_visible_index<4;screen_visible_index++){
                    var screen_row=script_parameter_scroll+screen_visible_index;
                    if(screen_row>=screen_row_count) break;
                    var screen_row_y=264+screen_visible_index*42;
                    if(screen_row<array_length(screen_labels)){
                        var screen_parameter_kind=BattleEditor_ActionParameterKind("screen",inspector_step.screen_action,screen_row);
                        var screen_parameter_value=BattleEditor_ActionArgumentText(inspector_step.screen_arguments,screen_row,screen_defaults);
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,screen_row_y,screen_labels[screen_row]);
                        if(screen_parameter_kind=="boolean") _editor_button(430,screen_row_y+16,628,screen_row_y+38,BattleEditor_ActionParameterChoiceCaption(screen_parameter_kind,BattleEditor_ReadNumberText(screen_parameter_value,0),inspector_step.screen_action),BattleEditor_ReadNumberText(screen_parameter_value,0)!=0);
                        else _editor_field(430,screen_row_y+16,628,screen_row_y+38,screen_parameter_value,"script_screen_param_"+string(screen_row));
                    }else if(screen_row==array_length(screen_labels)){
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,screen_row_y,"过渡曲线");
                        _editor_button(430,screen_row_y+16,628,screen_row_y+38,BattleEditor_TweenName(inspector_step.tween)+"  ▼",script_dropdown=="tween");
                    }else{
                        draw_set_color(c_gray);TextTyper_DrawFallback(430,screen_row_y,"缓动方向");
                        _editor_button(430,screen_row_y+16,628,screen_row_y+38,BattleEditor_EaseName(inspector_step.ease)+"  ▼",script_dropdown=="ease");
                    }
                }
                if(screen_row_count>0){draw_set_color(c_ltgray);TextTyper_DrawFallback(430,434,"滚轮查看更多参数");}
            }else if(inspector_step.kind=="play_sound"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"游戏音效资源");
                _editor_button(430,234,594,258,_editor_ellipsis(BattleEditor_SoundOptionCaption(inspector_step.sound_name,project),142)+"  ▼",script_dropdown=="sound_name");_editor_audio_preview_button(600,234,628,258,"workspace_"+string(inspector_step.uid));
                TextTyper_DrawFallback(430,274,"播放时机");
                _editor_button(430,292,628,316,BattleEditor_SoundTimingName(inspector_step.sound_timing)+"  ▼",script_dropdown=="sound_timing");
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,330,"直接使用项目中实际存在的 snd... 资源。声音不会因脚本项目结束而被截断，因此整首音乐也可以播放。",18,190);
            }else if(inspector_step.kind=="enemy_appearance"){
                var selected_appearance_enemy=BattleEditor_FindEnemyByUid(project,inspector_step.enemy_uid);
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"敌人（内部 UID 引用）");
                _editor_button(430,234,628,258,is_undefined(selected_appearance_enemy)?"选择敌人  ▼":selected_appearance_enemy.name+"  ▼",script_dropdown=="enemy_target");
                TextTyper_DrawFallback(430,272,"部件");_editor_button(510,270,628,294,BattleEditor_EnemyPartName(inspector_step.enemy_part_key)+"  ▼",script_dropdown=="enemy_part_key");
                TextTyper_DrawFallback(430,308,"贴图 / 动画");_editor_button(430,326,628,350,_editor_ellipsis(BattleEditor_EnemyResourceCaption(project,inspector_step.enemy_resource_uid),174)+"  ▼",script_dropdown=="enemy_resource");
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,366,"名称只是显示。角色或资源改名后，这个项目仍通过内部 UID 自动指向同一个对象。",18,194);
            }else if(inspector_step.kind=="get_value"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"数值来源");
                _editor_button(430,234,628,258,_editor_ellipsis(BattleEditor_ValueTargetCaption(project,inspector_step),180)+"  ▼",script_dropdown=="value_target");
                TextTyper_DrawFallback(430,272,"读取属性");
                _editor_button(510,270,628,294,BattleEditor_ValuePropertyName(inspector_step.read_property)+"  ▼",script_dropdown=="value_property");
                TextTyper_DrawFallback(430,308,"命名为");
                _editor_field(510,306,628,330,inspector_step.read_variable_name,"script_read_variable_name");
                var read_name_valid=BattleEditor_IsVariableIdentifier(inspector_step.read_variable_name);
                var read_conflict=BattleEditor_VariableNameConflict(project,inspector_step.read_variable_name,inspector_step.uid);
                var read_name_reserved=BattleEditor_IsReservedVariableName(inspector_step.read_variable_name);
                if(!read_name_valid){
                    draw_set_color(c_red);TextTyper_DrawFallbackExt(430,340,"名称必须以字母、中文或下划线开头，不能含空格或运算符。",18,194);
                    _editor_button(430,382,628,406,"重新命名",false);
                }else if(read_name_reserved){
                    draw_set_color(c_red);TextTyper_DrawFallbackExt(430,340,"这是系统内建名称，必须重新命名；系统实时值不能被覆盖。",18,194);
                    _editor_button(430,382,628,406,"重新命名",false);
                }else if(read_conflict&&!inspector_step.read_overwrite_confirmed){
                    draw_set_color(c_yellow);TextTyper_DrawFallbackExt(430,340,"已有同名变量。这个读取项目在确认前不会覆盖。",18,194);
                    _editor_button(430,382,526,406,"覆盖原变量",false);
                    _editor_button(532,382,628,406,"重新命名",false);
                }else if(read_conflict){
                    draw_set_color(c_orange);TextTyper_DrawFallbackExt(430,340,"已确认覆盖：执行时原变量值会直接丢失。",18,194);
                    _editor_button(430,382,628,406,"撤销覆盖许可",false);
                }else{
                    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,340,"执行到这里时读取当帧数值，并建立一个可供后续公式使用的短变量名。",18,194);
                }
            }else if(inspector_step.kind=="run_script"){
                draw_set_color(c_red);TextTyper_DrawFallbackExt(430,216,"旧版任意 GML 脚本步骤已禁用。请选择“内建攻击函数”替换。",18,194);
            }else if(inspector_step.kind=="set_variable"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"变量名（创建或调用）");_editor_field(430,234,628,256,inspector_step.variable_name,"script_variable_name");
                TextTyper_DrawFallback(430,274,"运算");_editor_button(510,270,628,292,inspector_step.variable_operation+"  选择",script_dropdown=="variable_operation");
                TextTyper_DrawFallback(430,304,"数值 / 公式");_editor_field(430,322,628,344,inspector_step.expression,"script_expression");
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,354,"输入名称创建变量；后面的任何公式都能直接使用该名称。",18,190);
            }else if(inspector_step.kind=="condition"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"左侧公式");_editor_field(510,212,628,234,inspector_step.condition_left,"script_condition_left");
                TextTyper_DrawFallback(430,246,"比较");_editor_button(510,242,628,264,inspector_step.condition_operator+"  选择",script_dropdown=="condition_operator");
                TextTyper_DrawFallback(430,276,"右侧公式");_editor_field(510,272,628,294,inspector_step.condition_right,"script_condition_right");
                TextTyper_DrawFallback(430,306,"不成立跳过项数");_editor_field(550,302,628,324,inspector_step.skip_count,"script_skip_count");
            }else if(inspector_step.kind=="repeat"){
                draw_set_color(c_gray);TextTyper_DrawFallback(430,216,"重复次数 / 公式");_editor_field(540,212,628,234,inspector_step.repeat_count,"script_repeat_count");
                TextTyper_DrawFallback(430,246,"循环后续项目数");_editor_field(550,242,628,264,inspector_step.repeat_length,"script_repeat_length");
                TextTyper_DrawFallback(430,276,"每轮额外等待(帧)");_editor_field(550,272,628,294,inspector_step.repeat_interval,"script_repeat_interval");
                draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,310,"0 表示不限速；循环范围里的等待仍会生效。允许嵌套。",18,190);
            }
        }else{
            draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(430,190,"从左侧拖入积木，接到事件头下方。",18,190);
        }
        matrix_set(matrix_world,inspector_transition_old_world);
    }
    BattleEditor_WorkspaceDrawPalette(id);
    BattleEditor_WorkspaceDrawDrag(id);
    draw_set_color(c_ltgray);TextTyper_DrawFallback(8,456,"Esc 返回场景 · 拖动拼接 / 拆分 · Ctrl+滚轮缩放");
}else if(tab==2){
    draw_set_color(c_ltgray);TextTyper_DrawFallback(12,456,"Workspace 已收起 · Esc 返回，或切换其他标签");
}else if(tab==3){
    draw_set_alpha(0.78);draw_set_color(c_black);draw_rectangle(0,32,640,480,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(72,54,568,390,true);
    draw_set_color(c_yellow);TextTyper_DrawFallback(94,72,"开发者工具");
    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(94,96,"这里只改变测试流程，不会在你勾选时立刻跳状态。完成一次 FIGHT / ACT / ITEM / MERCY 后，下一场怪物回合才读取这里。",18,448);
    _editor_button(94,146,546,172,project.settings.developer_force_turn?"[X] 强制使用指定怪物回合":"[ ] 按正常顺序进入怪物回合",project.settings.developer_force_turn);
    draw_set_color(c_white);TextTyper_DrawFallback(94,190,"指定回合");
    _editor_field(194,186,330,212,project.settings.developer_turn,"developer_turn");
    _editor_button(336,186,546,212,"从已有怪物回合选择  ▼",developer_turn_dropdown);
    _editor_button(94,238,546,266,project.settings.developer_force_default_board?"[X] 测试时强制使用 130 x 130 预设方框":"[ ] 怪物回合使用项目自己的主框",project.settings.developer_force_default_board);
    _editor_button(94,274,546,302,project.settings.auto_switch_to_objects_on_run?"[X] 运行列表后切到对象页":"[ ] 运行列表后留在脚本页",project.settings.auto_switch_to_objects_on_run);
    var known_dev_turns=BattleEditor_GetKnownTurns(project);
    var known_text="脚本里已有怪物回合：";
    for(var known_dev_index=0;known_dev_index<array_length(known_dev_turns);known_dev_index++) known_text+=(known_dev_index>0?"、":"")+string(known_dev_turns[known_dev_index]);
    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(94,320,known_text,18,448);
    draw_set_color(c_gray);TextTyper_DrawFallbackExt(94,354,"回合文本与气泡台词按回合保存。",18,448);
}else if(tab==4){
    draw_set_alpha(0.96);draw_set_color(make_color_rgb(7,9,13));draw_rectangle(4,34,636,476,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(4,34,636,476,true);
    var help_old_scissor=gpu_get_scissor();
    BattleEditor_UiScissor(12,42,616,404);
    matrix_set(matrix_world,matrix_build(0,-help_scroll,0,0,0,0,1,1,1));
    if(!help_layout_ready){
        help_sections_cache=BattleEditor_HelpSections();
        help_section_offsets=[];
        help_section_lines=[];
        // Match the clickable directory geometry: rows start at y=94.
        var help_layout_y=94+array_length(help_sections_cache)*22+24;
        for(var help_layout_index=0;help_layout_index<array_length(help_sections_cache);help_layout_index++){
            array_push(help_section_offsets,help_layout_y);
            var wrapped_help_lines=TextTyper_WrapFallbackLines(help_sections_cache[help_layout_index].body,592,font_menu);
            array_push(help_section_lines,wrapped_help_lines);
            help_layout_y+=32+array_length(wrapped_help_lines)*18+18;
        }
        help_content_height_cache=help_layout_y+28;
        help_layout_ready=true;
    }
    var help_sections=help_sections_cache;
    var help_visible_top=help_scroll+42;
    var help_visible_bottom=help_scroll+446;
    draw_set_color(c_yellow);TextTyper_DrawFallback(22,50,"战斗弹幕编辑器教学");
    draw_set_color(c_ltgray);TextTyper_DrawFallback(22,72,"目录（点击跳转）");
    for(var help_index=0;help_index<array_length(help_sections);help_index++){
        var help_directory_y=94+help_index*22;
        if(help_directory_y+20>=help_visible_top&&help_directory_y<=help_visible_bottom) _editor_button(22,help_directory_y,318,help_directory_y+20,string(help_index+1)+". "+help_sections[help_index].title,false);
    }
    for(var help_section_index=0;help_section_index<array_length(help_sections);help_section_index++){
        var help_section=help_sections[help_section_index];
        var help_section_y=help_section_offsets[help_section_index];
        var visible_help_lines=help_section_lines[help_section_index];
        var help_section_bottom=help_section_y+32+array_length(visible_help_lines)*18;
        if(help_section_bottom<help_visible_top||help_section_y>help_visible_bottom) continue;
        draw_set_color(c_yellow);TextTyper_DrawFallback(22,help_section_y,string(help_section_index+1)+". "+help_section.title);
        draw_set_color(c_white);
        for(var help_line_index=0;help_line_index<array_length(visible_help_lines);help_line_index++){
            var help_line_y=help_section_y+24+help_line_index*18;
            if(help_line_y+18>=help_visible_top&&help_line_y<=help_visible_bottom) TextTyper_DrawFallback(22,help_line_y,visible_help_lines[help_line_index]);
        }
    }
    matrix_set(matrix_world,matrix_build_identity());
    BattleEditor_UiScissor(help_old_scissor);
    draw_set_alpha(0.98);draw_set_color(make_color_rgb(12,12,14));draw_rectangle(4,446,636,476,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(4,446,636,476,true);
    _editor_button(520,450,628,472,"回到目录",false);
    draw_set_color(c_ltgray);TextTyper_DrawFallback(16,454,"滚轮阅读；目录可直接跳到对应章节");
}

draw_set_alpha(1);
draw_set_color(c_white);

if(page_anim_progress<1){
    var page_fade=1-power(1-clamp(page_anim_progress,0,1),3);
    draw_set_alpha(0.22*(1-page_fade));draw_set_color(c_black);draw_rectangle(0,32,640,480,false);
    draw_set_alpha(1);draw_set_color(c_white);
}

if(context_open){
    draw_set_alpha(0.98);
    draw_set_color(make_color_rgb(12,12,12));draw_rectangle(context_x,context_y,context_x+112,context_y+132,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(context_x,context_y,context_x+112,context_y+132,true);
    var context_labels=["复制","剪下","贴上","删除","新增顶点","强制切换 [选单]"];
    for(var context_row=0;context_row<6;context_row++){
        var enabled=true;
        if((context_row==0)&&(context_event<0&&context_frame<-1)) enabled=false;
        if((context_row==1||context_row==3)&&(context_event<0&&context_frame<0)) enabled=false;
        if(context_row==2&&is_undefined(editor_clipboard)) enabled=false;
        if(context_row>=4&&context_frame<-1) enabled=false;
        draw_set_color(enabled?c_white:c_dkgray);
        TextTyper_DrawFallback(context_x+7,context_y+3+context_row*22,context_labels[context_row]);
    }
    if(context_submenu){
        draw_set_color(make_color_rgb(12,12,12));draw_rectangle(context_x+114,context_y+88,context_x+242,context_y+176,false);
        draw_set_color(c_white);draw_rectangle(context_x+114,context_y+88,context_x+242,context_y+176,true);
        var shape_labels=["正方形","矩形","圆形 / 椭圆","正三角形"];
        for(var shape_row=0;shape_row<4;shape_row++) TextTyper_DrawFallback(context_x+121,context_y+91+shape_row*22,shape_labels[shape_row]);
    }
}

if(script_context_open&&tab==2&&workspace_open){
    var script_menu_labels=BattleEditor_WorkspaceContextLabels(id);
    var script_context_rows=array_length(script_menu_labels);
    var script_context_height=script_context_rows*22;
    draw_set_alpha(0.98);draw_set_color(make_color_rgb(12,12,12));
    draw_roundrect_ext(script_context_x,script_context_y,script_context_x+190,script_context_y+script_context_height,5,5,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_roundrect_ext(script_context_x,script_context_y,script_context_x+190,script_context_y+script_context_height,5,5,true);
    for(var script_context_row=0;script_context_row<script_context_rows;script_context_row++){
        var script_row_enabled=true;
        if(script_context_list>=0&&!script_context_header&&script_context_step<0) script_row_enabled=false;
        if((script_context_list<0&&script_context_row==0)||(script_context_header&&script_context_row==2)) script_row_enabled=!is_undefined(script_list_clipboard);
        if((script_context_list<0&&script_context_row==1)||(script_context_list>=0&&!script_context_header&&script_context_row==2)) script_row_enabled=array_length(script_clipboard)>0;
        draw_set_color(script_row_enabled?c_white:c_dkgray);
        TextTyper_DrawFallback(script_context_x+7,script_context_y+3+script_context_row*22,script_menu_labels[script_context_row]);
    }
}

var draw_dropdown_list_valid=script_selected_list>=0&&script_selected_list<array_length(project.script_lists);
var draw_dropdown_step_valid=draw_dropdown_list_valid&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps);
var draw_dropdown_detached=script_dropdown=="formula_help"||script_dropdown=="formula_variable";
var draw_dropdown_list_only=script_dropdown=="entry_kind"||script_dropdown=="item_entry"||script_dropdown=="action_entry";
var draw_dropdown_selection_valid=draw_dropdown_detached||(draw_dropdown_list_only?draw_dropdown_list_valid:draw_dropdown_step_valid);
if(tab==2&&workspace_open&&script_dropdown!=""&&draw_dropdown_selection_valid){
    var dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var dropdown_anchor_y=220;
    if(script_dropdown=="formula_help"||script_dropdown=="formula_variable") dropdown_anchor_y=32;
    else if(script_dropdown=="entry_kind") dropdown_anchor_y=150;
    else if(script_dropdown=="item_entry"||script_dropdown=="action_entry") dropdown_anchor_y=174;
    else if(script_dropdown=="kind") dropdown_anchor_y=200;
    else if(script_dropdown=="create_category"||script_dropdown=="target_category") dropdown_anchor_y=226;
    else if(script_dropdown=="create_preset") dropdown_anchor_y=254;
    else if(script_dropdown=="create_board_shape"||script_dropdown=="create_layer") dropdown_anchor_y=394;
    else if(script_dropdown=="coordinate_mode"){
        var coordinate_anim_step=project.script_lists[script_selected_list].steps[script_selected_step];
        dropdown_anchor_y=coordinate_anim_step.property=="control_vertex"?394:306;
    }
    else if(script_dropdown=="create_damage") dropdown_anchor_y=368;
    else if(script_dropdown=="sound_timing") dropdown_anchor_y=318;
    else if(script_dropdown=="enemy_part_key"||script_dropdown=="value_property") dropdown_anchor_y=296;
    else if(script_dropdown=="enemy_resource") dropdown_anchor_y=352;
    else if(script_dropdown=="variable_operation") dropdown_anchor_y=294;
    else if(script_dropdown=="condition_operator") dropdown_anchor_y=266;
    else if(script_dropdown=="choice_value"||script_dropdown=="aim_target_value") dropdown_anchor_y=306;
    else if(script_dropdown=="aim_behavior") dropdown_anchor_y=334;
    else if(script_dropdown=="aim_motion_mode") dropdown_anchor_y=362;
    else if(script_dropdown=="control_follow_frame") dropdown_anchor_y=338;
    else if(script_dropdown=="length_anchor") dropdown_anchor_y=334;
    else if(script_dropdown=="soul_blue_direction") dropdown_anchor_y=336;
    else if(script_dropdown=="property_category"||script_dropdown=="property") dropdown_anchor_y=278;
    else if(script_dropdown!="tween"&&script_dropdown!="ease"&&script_dropdown!="action_exit_tween"&&script_dropdown!="action_exit_ease") dropdown_anchor_y=258;
    var dropdown_clip_old=gpu_get_scissor();
    BattleEditor_UiScissor(0,dropdown_anchor_y,640,max(1,ceil((480-dropdown_anchor_y)*dropdown_reveal)));
    draw_set_alpha(0.99*dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));
    if(script_dropdown=="entry_kind"){
        _editor_menu_frame(430,150,628,304);
        var entry_labels=["游戏开始","怪物回合","计时器数值","玩家受伤","玩家使用物品","脚本入口","行动项目"];
        for(var entry_row=0;entry_row<7;entry_row++){
            var entry_selected=entry_row==inspector_list.entry_kind;
            _editor_dropdown_selection(431,151+entry_row*22,627,171+entry_row*22,entry_selected);
            draw_set_color(entry_selected?c_yellow:c_white);TextTyper_DrawFallback(436,153+entry_row*22,entry_labels[entry_row]);
        }
    }else if(script_dropdown=="item_entry"){
        var item_options=project.initialization.items;
        var item_visible=min(8,max(1,array_length(item_options)-script_item_scroll));
        var item_bottom=174+item_visible*22;
        _editor_menu_frame(430,174,628,item_bottom);
        if(array_length(item_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(436,177,"物品栏为空");}
        else for(var item_row=0;item_row<item_visible;item_row++){
            var option_index=script_item_scroll+item_row;
            var item_selected=item_options[option_index].uid==inspector_list.entry_value;
            _editor_dropdown_selection(431,175+item_row*22,627,195+item_row*22,item_selected);
            draw_set_color(item_selected?c_yellow:c_white);
            TextTyper_DrawFallback(436,177+item_row*22,string(option_index+1)+". "+item_options[option_index].name);
        }
    }else if(script_dropdown=="action_entry"){
        var action_options=BattleEditor_ActionTriggerOptions(project);
        var action_visible=min(8,max(1,array_length(action_options)-script_action_entry_scroll));
        var action_bottom=174+action_visible*22;
        _editor_menu_frame(430,174,628,action_bottom);
        if(array_length(action_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(436,177,"还没有行动项目");}
        else for(var action_row=0;action_row<action_visible;action_row++){
            var action_option=action_options[script_action_entry_scroll+action_row];
            var action_selected=action_option.uid==inspector_list.entry_value;
            _editor_dropdown_selection(431,175+action_row*22,627,195+action_row*22,action_selected);
            draw_set_color(action_selected?c_yellow:c_white);TextTyper_DrawFallback(436,177+action_row*22,_editor_ellipsis(action_option.caption,176));
        }
    }else if(script_dropdown=="kind"){
        var kind_labels=["控制对象","创建对象","内建攻击函数","画面/镜头/滤镜","播放音效","切换敌人贴图","变量 / 公式","读取对象数值","条件判断","等待","循环范围","节点连接"];
        var kind_values=["control_object","create_object","builtin_action","screen_control","play_sound","enemy_appearance","set_variable","get_value","condition","wait","repeat","start_list"];
        _editor_menu_frame(500,200,638,464);
        for(var i=0;i<12;i++){
            var kind_selected=inspector_step.kind==kind_values[i];
            _editor_dropdown_selection(501,201+i*22,637,221+i*22,kind_selected);
            draw_set_color(kind_selected?c_yellow:c_white);TextTyper_DrawFallback(506,203+i*22,kind_labels[i]);
        }
    }else if(script_dropdown=="create_category"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(510,226,638,358);
        for(var create_category_row=0;create_category_row<6;create_category_row++){
            var create_category_selected=create_category_row==inspector_step.create_category;
            _editor_dropdown_selection(511,227+create_category_row*22,637,247+create_category_row*22,create_category_selected);
            draw_set_color(create_category_selected?c_yellow:c_white);TextTyper_DrawFallback(516,229+create_category_row*22,BattleEditor_ObjectPaletteCategoryName(create_category_row));
        }
    }else if(script_dropdown=="create_preset"){
        var create_options=BattleEditor_WorkspaceCreateOptions(project.script_lists[script_selected_list].steps[script_selected_step].create_category);
        var create_rows=min(6,array_length(create_options));
        var create_columns=max(1,ceil(array_length(create_options)/6));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,254,638,254+create_rows*22);
        for(var create_option_index=0;create_option_index<array_length(create_options);create_option_index++){
            var create_col=create_option_index div 6,create_row=create_option_index mod 6;
            var create_preset_selected=create_options[create_option_index].id==inspector_step.create_preset;
            _editor_dropdown_selection(421+create_col*109,255+create_row*22,528+create_col*109,275+create_row*22,create_preset_selected);
            draw_set_color(create_preset_selected?c_yellow:c_white);
            TextTyper_DrawFallback(426+create_col*109,257+create_row*22,create_options[create_option_index].name);
        }
    }else if(script_dropdown=="create_template_choice"){
        var create_choice_count=BattleEditor_WorkspaceCreateChoiceCount(script_create_choice_kind,project);
        var create_choice_visible=min(8,max(1,create_choice_count-script_create_choice_scroll));
        var create_choice_bottom=264+create_choice_visible*22;
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,264,638,create_choice_bottom);
        var create_choice_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
        var create_choice_current_value=BattleEditor_WorkspaceTemplateGet(create_choice_template,script_create_choice_path);
        if(script_create_choice_kind=="bone_aim_behavior") create_choice_current_value=!BattleEditor_WorkspaceTemplateGet(create_choice_template,"aim_enabled")?0:(BattleEditor_WorkspaceTemplateGet(create_choice_template,"aim_move_enabled")?2:1);
        var create_choice_current=BattleEditor_WorkspaceCreateChoiceIndex(script_create_choice_kind,create_choice_current_value,project);
        for(var create_choice_row=0;create_choice_row<create_choice_visible;create_choice_row++){
            var create_choice_index=script_create_choice_scroll+create_choice_row;
            var create_choice_value=BattleEditor_WorkspaceCreateChoiceValue(script_create_choice_kind,create_choice_index,project);
            var create_choice_selected=create_choice_index==create_choice_current;
            _editor_dropdown_selection(421,265+create_choice_row*22,637,285+create_choice_row*22,create_choice_selected);
            draw_set_color(create_choice_selected?c_yellow:c_white);TextTyper_DrawFallback(426,267+create_choice_row*22,_editor_ellipsis(BattleEditor_WorkspaceCreateChoiceCaption(script_create_choice_kind,create_choice_value,project),190));
        }
    }else if(script_dropdown=="create_clip_frames"){
        var create_clip_options=BattleEditor_FollowFrameOptions(project);
        var create_clip_visible=min(8,max(1,array_length(create_clip_options)-script_create_choice_scroll));
        var create_clip_bottom=264+create_clip_visible*22;
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,264,638,create_clip_bottom);
        var create_clip_template=BattleEditor_WorkspaceCreateNormalizeTemplate(inspector_step);
        for(var create_clip_row=0;create_clip_row<create_clip_visible;create_clip_row++){
            var create_clip_index=script_create_choice_scroll+create_clip_row;
            var create_clip_frame=create_clip_options[create_clip_index];
            var create_clip_selected=false;
            for(var create_clip_selected_index=0;create_clip_selected_index<array_length(create_clip_template.clip_frame_uids);create_clip_selected_index++) if(create_clip_template.clip_frame_uids[create_clip_selected_index]==create_clip_frame.uid){create_clip_selected=true;break;}
            _editor_dropdown_selection(421,265+create_clip_row*22,637,285+create_clip_row*22,create_clip_selected);
            draw_set_color(create_clip_selected?c_yellow:c_white);TextTyper_DrawFallback(426,267+create_clip_row*22,_editor_ellipsis(BattleEditor_FollowFrameCaption(project,create_clip_frame.uid),190));
        }
    }else if(script_dropdown=="create_board_shape"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,394,638,482);
        for(var create_shape_row=0;create_shape_row<4;create_shape_row++){
            var create_shape_selected=create_shape_row==inspector_step.create_board_shape;
            _editor_dropdown_selection(501,395+create_shape_row*22,637,415+create_shape_row*22,create_shape_selected);
            draw_set_color(create_shape_selected?c_yellow:c_white);TextTyper_DrawFallback(506,397+create_shape_row*22,BattleEditor_ControlChoiceCaption("shape",create_shape_row));
        }
    }else if(script_dropdown=="create_damage"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,368,638,478);
        for(var create_damage_index=0;create_damage_index<9;create_damage_index++){
            var create_damage_col=create_damage_index div 5,create_damage_row=create_damage_index mod 5;
            var create_damage_selected=create_damage_index==inspector_step.create_damage_type;
            _editor_dropdown_selection(411+create_damage_col*112,369+create_damage_row*22,521+create_damage_col*112,389+create_damage_row*22,create_damage_selected);
            draw_set_color(create_damage_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416+create_damage_col*112,371+create_damage_row*22,BattleEditor_DamageTypeName(create_damage_index));
        }
    }else if(script_dropdown=="create_layer"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,394,628,460);
        for(var create_layer_row=0;create_layer_row<3;create_layer_row++){
            var create_layer_selected=create_layer_row==inspector_step.create_layer_mode;
            _editor_dropdown_selection(501,395+create_layer_row*22,627,415+create_layer_row*22,create_layer_selected);
            draw_set_color(create_layer_selected?c_yellow:c_white);TextTyper_DrawFallback(506,397+create_layer_row*22,BattleEditor_LayerName(create_layer_row));
        }
    }else if(script_dropdown=="wait_mode"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(430,260,628,304);
        for(var wait_mode_row=0;wait_mode_row<2;wait_mode_row++){
            var wait_mode_selected=wait_mode_row==inspector_step.wait_mode;
            _editor_dropdown_selection(431,261+wait_mode_row*22,627,281+wait_mode_row*22,wait_mode_selected);
            draw_set_color(wait_mode_selected?c_yellow:c_white);TextTyper_DrawFallback(436,263+wait_mode_row*22,BattleEditor_WaitModeName(wait_mode_row));
        }
    }else if(script_dropdown=="builtin_action"){
        var action_options=BattleEditor_BuiltinActionOptions();
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,258,638,258+array_length(action_options)*22);
        for(var i=0;i<array_length(action_options);i++){
            var builtin_selected=action_options[i].id==inspector_step.action_name;
            _editor_dropdown_selection(421,259+i*22,637,279+i*22,builtin_selected);
            draw_set_color(builtin_selected?c_yellow:c_white);TextTyper_DrawFallback(426,261+i*22,action_options[i].name);
        }
    }else if(script_dropdown=="builtin_wall_direction"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,258,628,412);
        for(var wall_direction_row=0;wall_direction_row<7;wall_direction_row++){
            var wall_direction_selected=wall_direction_row+1==inspector_step.action_direction;
            _editor_dropdown_selection(501,259+wall_direction_row*22,627,279+wall_direction_row*22,wall_direction_selected);
            draw_set_color(wall_direction_selected?c_yellow:c_white);TextTyper_DrawFallback(506,261+wall_direction_row*22,BattleEditor_BoneWallDirectionName(wall_direction_row+1));
        }
    }else if(script_dropdown=="builtin_wall_color"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,258,628,456);
        for(var wall_color_row=0;wall_color_row<9;wall_color_row++){
            var wall_color_selected=wall_color_row==BattleEditor_ReadNumberText(BattleEditor_ActionArgumentText(inspector_step.action_arguments,8,BattleEditor_BuiltinActionDefaults("bone_wall")),0);
            _editor_dropdown_selection(501,259+wall_color_row*22,627,279+wall_color_row*22,wall_color_selected);
            draw_set_color(BattleEditor_ColorForType(wall_color_row));draw_rectangle(506,263+wall_color_row*22,518,273+wall_color_row*22,false);
            draw_set_color(wall_color_selected?c_yellow:c_white);TextTyper_DrawFallback(523,261+wall_color_row*22,BattleEditor_DamageTypeName(wall_color_row));
        }
    }else if(script_dropdown=="builtin_wall_layer"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,258,628,324);
        for(var wall_layer_row=0;wall_layer_row<3;wall_layer_row++){
            var wall_layer_selected=wall_layer_row==BattleEditor_ReadNumberText(BattleEditor_ActionArgumentText(inspector_step.action_arguments,9,BattleEditor_BuiltinActionDefaults("bone_wall")),0);
            _editor_dropdown_selection(501,259+wall_layer_row*22,627,279+wall_layer_row*22,wall_layer_selected);
            draw_set_color(wall_layer_selected?c_yellow:c_white);TextTyper_DrawFallback(506,261+wall_layer_row*22,BattleEditor_LayerName(wall_layer_row));
        }
    }else if(script_dropdown=="action_template"){
        var action_template_is_path=!is_undefined(inspector_step)&&inspector_step.kind=="builtin_action"&&inspector_step.action_name=="bone_function_path"&&round(real(inspector_step.action_path_mode))==0;
        var action_template_options=action_template_is_path?BattleEditor_FunctionPathCloneOptions(project):BattleEditor_ActionTemplateOptions(project);
        var action_template_visible=min(8,max(1,array_length(action_template_options)-script_template_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,258,638,258+action_template_visible*22);
        if(array_length(action_template_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,261,"没有可复制对象");}
        else for(var template_row=0;template_row<action_template_visible;template_row++){
            var template_option=action_template_options[script_template_scroll+template_row];
            var template_selected=template_option.uid==inspector_step.action_source_uid;
            _editor_dropdown_selection(411,259+template_row*22,637,279+template_row*22,template_selected);
            draw_set_color(template_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416,261+template_row*22,_editor_ellipsis("["+BattleEditor_TargetTypeName(template_option.target_type)+"] "+template_option.name,210));
        }
    }else if(script_dropdown=="function_path_mode"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,258,638,302);
        for(var path_mode_row=0;path_mode_row<2;path_mode_row++){
            var path_mode_selected=path_mode_row==round(real(inspector_step.action_path_mode));
            _editor_dropdown_selection(421,259+path_mode_row*22,637,279+path_mode_row*22,path_mode_selected);
            draw_set_color(path_mode_selected?c_yellow:c_white);TextTyper_DrawFallback(426,261+path_mode_row*22,BattleEditor_FunctionPathModeName(path_mode_row));
        }
    }else if(script_dropdown=="function_path_target"){
        var path_target_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var path_target_options=BattleEditor_FunctionPathTargetOptions(project);
        var path_target_visible=min(8,max(1,array_length(path_target_options)-script_target_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,258,638,258+path_target_visible*22);
        if(array_length(path_target_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,261,"没有可移动对象组");}
        else for(var path_target_row=0;path_target_row<path_target_visible;path_target_row++){
            var path_target=path_target_options[script_target_scroll+path_target_row];
            var path_target_runtime=struct_exists(path_target,"runtime_count")&&path_target.runtime_count>0;
            var path_target_selected=path_target.control_id==path_target_step.action_control_id&&path_target.target_type==path_target_step.action_path_target_type;
            _editor_dropdown_selection(411,259+path_target_row*22,637,279+path_target_row*22,path_target_selected);
            draw_set_color(path_target_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416,261+path_target_row*22,_editor_ellipsis(BattleEditor_TargetTypeName(path_target.target_type)+" / "+path_target.control_id+" · "+string(path_target.count)+" 个"+(path_target_runtime?" [运行时]":""),210));
        }
    }else if(script_dropdown=="board_shape_target"){
        var board_target_options=BattleEditor_ControlTargetOptions(project,"board");
        var board_target_visible=min(8,max(1,array_length(board_target_options)-script_target_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,258,638,258+board_target_visible*22);
        if(array_length(board_target_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,261,"没有可用战斗框");}
        else for(var board_target_row=0;board_target_row<board_target_visible;board_target_row++){
            var board_target=board_target_options[script_target_scroll+board_target_row];
            var board_target_selected=board_target.control_id==inspector_step.action_control_id;
            _editor_dropdown_selection(411,259+board_target_row*22,637,279+board_target_row*22,board_target_selected);
            draw_set_color(board_target_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416,261+board_target_row*22,_editor_ellipsis(board_target.control_id+"  ×"+string(board_target.count),210));
        }
    }else if(script_dropdown=="screen_action"){
        var screen_options=BattleEditor_ScreenActionOptions();
        var screen_action_visible=min(8,array_length(screen_options)-script_screen_action_scroll);
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(420,258,638,258+screen_action_visible*22);
        for(var i=0;i<screen_action_visible;i++){
            var screen_action_option=screen_options[script_screen_action_scroll+i];
            var screen_action_selected=screen_action_option.id==inspector_step.screen_action;
            _editor_dropdown_selection(421,259+i*22,637,279+i*22,screen_action_selected);
            draw_set_color(screen_action_selected?c_yellow:c_white);TextTyper_DrawFallback(426,261+i*22,screen_action_option.name);
        }
        draw_set_color(c_ltgray);TextTyper_DrawFallback(426,438,"滚轮查看更多独立滤镜");
    }else if(script_dropdown=="sound_name"){
        var sound_options=BattleEditor_SoundOptions(project);
        var sound_visible=min(8,max(1,array_length(sound_options)-script_sound_scroll));
        var sound_import_y=260+sound_visible*22;
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,260,638,sound_import_y+26);
        if(array_length(sound_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,263,"没有找到 snd... 音效");}
        else for(var sound_row=0;sound_row<sound_visible;sound_row++){
            var sound_option=sound_options[script_sound_scroll+sound_row];
            var sound_selected=sound_option==inspector_step.sound_name;
            _editor_dropdown_selection(411,261+sound_row*22,637,281+sound_row*22,sound_selected);
            draw_set_color(sound_selected?c_yellow:c_white);TextTyper_DrawFallback(416,263+sound_row*22,_editor_ellipsis(BattleEditor_SoundOptionCaption(sound_option,project),210));
        }
        _editor_button(412,sound_import_y+2,636,sound_import_y+24,"导入音频文件...",false);
    }else if(script_dropdown=="sound_timing"){
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(430,318,628,362);
        for(var sound_timing_row=0;sound_timing_row<2;sound_timing_row++){
            var sound_timing_selected=sound_timing_row==inspector_step.sound_timing;
            _editor_dropdown_selection(431,319+sound_timing_row*22,627,339+sound_timing_row*22,sound_timing_selected);
            draw_set_color(sound_timing_selected?c_yellow:c_white);TextTyper_DrawFallback(436,321+sound_timing_row*22,BattleEditor_SoundTimingName(sound_timing_row));
        }
    }else if(script_dropdown=="enemy_target"){
        var appearance_enemies=project.initialization.enemies;
        var appearance_enemy_visible=min(8,max(1,array_length(appearance_enemies)));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,260,638,260+appearance_enemy_visible*22);
        if(array_length(appearance_enemies)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,263,"没有敌人");}
        else for(var appearance_enemy_row=0;appearance_enemy_row<appearance_enemy_visible;appearance_enemy_row++){
            var appearance_enemy_option=appearance_enemies[appearance_enemy_row];
            var appearance_enemy_selected=appearance_enemy_option.uid==inspector_step.enemy_uid;
            _editor_dropdown_selection(411,261+appearance_enemy_row*22,637,281+appearance_enemy_row*22,appearance_enemy_selected);
            draw_set_color(appearance_enemy_selected?c_yellow:c_white);TextTyper_DrawFallback(416,263+appearance_enemy_row*22,_editor_ellipsis(appearance_enemy_option.name,210));
        }
    }else if(script_dropdown=="enemy_part_key"){
        var appearance_part_keys=BattleEditor_EnemyPartKeys();
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(500,296,638,296+array_length(appearance_part_keys)*22);
        for(var appearance_part_row=0;appearance_part_row<array_length(appearance_part_keys);appearance_part_row++){
            var appearance_part_selected=appearance_part_keys[appearance_part_row]==inspector_step.enemy_part_key;
            _editor_dropdown_selection(501,297+appearance_part_row*22,637,317+appearance_part_row*22,appearance_part_selected);
            draw_set_color(appearance_part_selected?c_yellow:c_white);TextTyper_DrawFallback(506,299+appearance_part_row*22,BattleEditor_EnemyPartName(appearance_part_keys[appearance_part_row]));
        }
    }else if(script_dropdown=="enemy_resource"){
        var appearance_resources=BattleEditor_EnemyTextureOptions(project,inspector_step.enemy_uid,inspector_step.enemy_part_key);
        var appearance_resource_visible=min(5,max(1,array_length(appearance_resources)-script_enemy_resource_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,352,638,352+appearance_resource_visible*22);
        if(array_length(appearance_resources)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,355,"这个角色还没有资源");}
        else for(var appearance_resource_row=0;appearance_resource_row<appearance_resource_visible;appearance_resource_row++){
            var appearance_resource_option=appearance_resources[script_enemy_resource_scroll+appearance_resource_row];
            var appearance_resource_selected=appearance_resource_option.uid==inspector_step.enemy_resource_uid;
            _editor_dropdown_selection(411,353+appearance_resource_row*22,637,373+appearance_resource_row*22,appearance_resource_selected);
            draw_set_color(appearance_resource_selected?c_yellow:c_white);TextTyper_DrawFallback(416,355+appearance_resource_row*22,_editor_ellipsis(appearance_resource_option.name,210));
        }
    }else if(script_dropdown=="value_target"){
        var value_targets=BattleEditor_ValueTargetOptions(project);
        var value_target_visible=min(8,max(1,array_length(value_targets)-script_value_target_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(410,260,638,260+value_target_visible*22);
        for(var value_target_row=0;value_target_row<value_target_visible;value_target_row++){
            var value_target_option=value_targets[script_value_target_scroll+value_target_row];
            var value_target_selected=value_target_option.key==inspector_step.read_target_key&&value_target_option.uid==inspector_step.read_target_uid&&value_target_option.target_type==inspector_step.read_target_type;
            _editor_dropdown_selection(411,261+value_target_row*22,637,281+value_target_row*22,value_target_selected);
            draw_set_color(value_target_selected?c_yellow:c_white);TextTyper_DrawFallback(416,263+value_target_row*22,_editor_ellipsis(value_target_option.name,210));
        }
    }else if(script_dropdown=="value_property"){
        var value_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var value_properties=BattleEditor_ValueProperties(value_step.read_target_key,value_step.read_target_type);
        var value_property_visible=min(8,max(1,array_length(value_properties)-script_value_property_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(430,296,638,296+value_property_visible*22);
        for(var value_property_row=0;value_property_row<value_property_visible;value_property_row++){
            var value_property_option=value_properties[script_value_property_scroll+value_property_row];
            var value_property_selected=value_property_option==value_step.read_property;
            _editor_dropdown_selection(431,297+value_property_row*22,637,317+value_property_row*22,value_property_selected);
            draw_set_color(value_property_selected?c_yellow:c_white);TextTyper_DrawFallback(436,299+value_property_row*22,BattleEditor_ValuePropertyName(value_property_option));
        }
    }else if(script_dropdown=="formula_help"){
        var formula_help_layout=BattleEditor_FormulaHelpLayout();
        var formula_help_lines=formula_help_layout.lines;
        var formula_help_bottom=formula_help_layout.bottom;
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(274,32,638,formula_help_bottom);
        draw_set_color(c_yellow);TextTyper_DrawFallback(282,36,"数学公式语法");
        for(var help_line_index=0;help_line_index<array_length(formula_help_lines);help_line_index++){
            draw_set_color(help_line_index>=8?c_ltgray:c_white);
            TextTyper_DrawFallback(282,58+help_line_index*20,formula_help_lines[help_line_index]);
        }
    }else if(script_dropdown=="formula_variable"){
        var formula_step=script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)?project.script_lists[script_selected_list].steps[script_selected_step]:undefined;
        var formula_options=BattleEditor_FormulaVariableOptions(project,formula_step,script_formula_target);
        var formula_visible=min(8,max(1,array_length(formula_options)-script_formula_variable_scroll));
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(370,32,638,32+formula_visible*22);
        for(var formula_row=0;formula_row<formula_visible;formula_row++) TextTyper_DrawFallback(376,35+formula_row*22,_editor_ellipsis(formula_options[script_formula_variable_scroll+formula_row].label,248));
    }else if(script_dropdown=="parameter_choice"){
        var parameter_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var parameter_action=script_parameter_choice_scope=="screen"?parameter_step.screen_action:parameter_step.action_name;
        var parameter_kind=BattleEditor_ActionParameterKind(script_parameter_choice_scope,parameter_action,script_parameter_choice_index);
        var parameter_choice_count=BattleEditor_ActionParameterChoiceCount(parameter_kind);
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(430,258,628,258+parameter_choice_count*22);
        var parameter_current_text=script_parameter_choice_scope=="screen"?BattleEditor_ActionArgumentText(parameter_step.screen_arguments,script_parameter_choice_index,BattleEditor_ScreenActionDefaults(parameter_step.screen_action)):BattleEditor_ActionArgumentText(parameter_step.action_arguments,script_parameter_choice_index,BattleEditor_BuiltinActionDefaults(parameter_step.action_name));
        var parameter_current_value=round(BattleEditor_ReadNumberText(parameter_current_text,0));
        for(var parameter_choice_row=0;parameter_choice_row<parameter_choice_count;parameter_choice_row++){
            var parameter_choice_selected=parameter_choice_row==parameter_current_value;
            _editor_dropdown_selection(431,259+parameter_choice_row*22,627,279+parameter_choice_row*22,parameter_choice_selected);
            draw_set_color(parameter_choice_selected?c_yellow:c_white);TextTyper_DrawFallback(436,261+parameter_choice_row*22,BattleEditor_ActionParameterChoiceCaption(parameter_kind,parameter_choice_row,parameter_action));
        }
    }else if(script_dropdown=="target_category"){
        var category_values=BattleEditor_ControlCategories();
        var category_bottom=226+array_length(category_values)*22;
        draw_set_color(make_color_rgb(8,8,10));draw_rectangle(510,226,638,category_bottom,false);
        draw_set_color(c_white);draw_rectangle(510,226,638,category_bottom,true);
        var category_mouse_y=editor_mouse.y;
        for(var category_row=0;category_row<array_length(category_values);category_row++){
            var category_y=226+category_row*22;
            var category_selected=script_selected_list>=0&&script_selected_step>=0&&project.script_lists[script_selected_list].steps[script_selected_step].target_category==category_values[category_row];
            var category_hover=category_mouse_y>=category_y&&category_mouse_y<category_y+22;
            if(category_hover&&!category_selected){draw_set_color(make_color_rgb(38,42,50));draw_rectangle(511,category_y+1,637,category_y+21,false);}
            _editor_dropdown_selection(511,category_y+1,637,category_y+21,category_selected);
            draw_set_color(category_selected?c_yellow:c_white);TextTyper_DrawFallback(516,category_y+3,BattleEditor_ControlCategoryName(category_values[category_row]));
        }
    }else if(script_dropdown=="target"){
        var selected_target_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var target_options=BattleEditor_ControlSourceOptions(project,selected_target_step);
        var target_visible=min(8,max(1,array_length(target_options)-script_target_scroll));
        var target_bottom=252+target_visible*22;
        // The closed control remains inspector-width. The popup width is
        // measured once when opened, with a 338px minimum and 430px cap.
        var target_popup_left=variable_instance_exists(id,"script_target_popup_left")?script_target_popup_left:300;
        draw_set_color(make_color_rgb(8,8,10));draw_rectangle(target_popup_left,252,638,target_bottom,false);
        draw_set_color(c_white);draw_rectangle(target_popup_left,252,638,target_bottom,true);
        if(array_length(target_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(target_popup_left+6,255,"这一类还没有可控制对象");}
        else for(var target_row=0;target_row<target_visible;target_row++){
            var target_option=target_options[script_target_scroll+target_row];
            var target_y=252+target_row*22;
            var option_group_kind=struct_exists(target_option,"group_kind")?string(target_option.group_kind):"";
            var selected_group_kind=struct_exists(selected_target_step,"target_group_kind")?string(selected_target_step.target_group_kind):"";
            var target_selected=selected_target_step.target==target_option.control_id&&selected_target_step.target_type==target_option.target_type&&selected_group_kind==option_group_kind;
            var target_hover=editor_mouse.y>=target_y&&editor_mouse.y<target_y+22;
            if(target_hover&&!target_selected){draw_set_color(make_color_rgb(38,42,50));draw_rectangle(target_popup_left+1,target_y+1,637,target_y+21,false);}
            _editor_dropdown_selection(target_popup_left+1,target_y+1,637,target_y+21,target_selected);
            var copy_mode=struct_exists(selected_target_step,"control_source_mode")&&round(real(selected_target_step.control_source_mode))==1;
            var target_label=BattleEditor_ControlSourceOptionLabel(target_option,copy_mode);
            target_label=_editor_ellipsis(target_label,638-target_popup_left-14);
            draw_set_color(target_selected?c_yellow:c_white);TextTyper_DrawFallback(target_popup_left+6,target_y+3,target_label);
        }
    }else if(script_dropdown=="property_category"){
        var property_category_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var property_categories=BattleEditor_ControlPropertyCategoriesForStep(property_category_step);
        _editor_menu_frame(420,278,638,278+array_length(property_categories)*22);
        for(var property_category_index=0;property_category_index<array_length(property_categories);property_category_index++){
            var property_category_selected=property_categories[property_category_index]==property_category_step.property_category;
            _editor_dropdown_selection(421,279+property_category_index*22,637,299+property_category_index*22,property_category_selected);
            draw_set_color(property_category_selected?c_yellow:c_white);TextTyper_DrawFallback(426,281+property_category_index*22,BattleEditor_ControlPropertyCategoryName(property_categories[property_category_index]));
        }
    }else if(script_dropdown=="property"){
        var property_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var property_values=BattleEditor_ControlPropertiesForStep(property_step,property_step.property_category);
        var property_rows=min(8,array_length(property_values));
        var property_columns=max(1,ceil(array_length(property_values)/8));
        _editor_menu_frame(420,278,638,278+property_rows*22);
        for(var i=0;i<array_length(property_values);i++){
            var col=i div 8,row=i mod 8;
            var property_selected=property_values[i]==property_step.property;
            _editor_dropdown_selection(421+col*109,279+row*22,528+col*109,299+row*22,property_selected);
            draw_set_color(property_selected?c_yellow:c_white);
            TextTyper_DrawFallback(426+col*109,281+row*22,BattleEditor_ControlPropertyName(property_values[i],property_step.target_type));
        }
    }else if(script_dropdown=="control_follow_frame"){
        var control_follow_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var control_follow_options=BattleEditor_FollowFrameOptions(project);
        var control_follow_visible=min(8,max(1,array_length(control_follow_options)-script_target_scroll));
        draw_set_color(make_color_rgb(8,8,10));draw_rectangle(410,338,628,338+control_follow_visible*22,false);
        draw_set_color(c_white);draw_rectangle(410,338,628,338+control_follow_visible*22,true);
        for(var control_follow_row=0;control_follow_row<control_follow_visible;control_follow_row++){
            var control_follow_option=control_follow_options[script_target_scroll+control_follow_row];
            var control_follow_y=338+control_follow_row*22;
            var control_follow_selected=control_follow_option.uid==control_follow_step.follow_target_uid
                ||(control_follow_step.follow_target_uid<0&&control_follow_option.uid==project.initialization.board.uid);
            _editor_dropdown_selection(411,control_follow_y+1,627,control_follow_y+21,control_follow_selected);
            draw_set_color(control_follow_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416,control_follow_y+3,_editor_ellipsis(BattleEditor_FollowFrameCaption(project,control_follow_option.uid),202));
        }
    }else if(script_dropdown=="coordinate_mode"){
        var coordinate_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var coordinate_y=coordinate_step.property=="control_vertex"?394:306;
        var coordinate_is_board_transform=coordinate_step.target_type=="board"&&coordinate_step.property=="position";
        _editor_menu_frame(430,coordinate_y,628,coordinate_y+44);
        for(var coordinate_row=0;coordinate_row<2;coordinate_row++){
            var coordinate_selected=(coordinate_step.coordinate_mode=="relative"?1:0)==coordinate_row;
            _editor_dropdown_selection(431,coordinate_y+1+coordinate_row*22,627,coordinate_y+21+coordinate_row*22,coordinate_selected);
            var coordinate_caption=coordinate_row==0?(coordinate_is_board_transform?"目标状态":"目标位置"):(coordinate_is_board_transform?"相对变化":"相对位移");
            draw_set_color(coordinate_selected?c_yellow:c_white);TextTyper_DrawFallback(436,coordinate_y+3+coordinate_row*22,coordinate_caption);
        }
    }else if(script_dropdown=="tween"||script_dropdown=="action_exit_tween"){
        _editor_menu_frame(420,220,628,360);
        var tween_labels=["Linear","Sine","Quad","Cubic","Quart","Quint","Expo","Circ","Back","Elastic","Bounce"];
        var selected_tween_value=script_dropdown=="action_exit_tween"?inspector_step.action_exit_tween:inspector_step.tween;
        for(var i=0;i<array_length(tween_labels);i++){
            var col=i div 7,row=i mod 7;
            var tween_selected=i==selected_tween_value;
            _editor_dropdown_selection(421+col*104,221+row*20,523+col*104,239+row*20,tween_selected);
            draw_set_color(tween_selected?c_yellow:c_white);TextTyper_DrawFallback(426+col*104,223+row*20,BattleEditor_TweenName(i));
        }
    }else if(script_dropdown=="ease"||script_dropdown=="action_exit_ease"){
        _editor_menu_frame(532,220,628,286);
        var selected_ease_value=script_dropdown=="action_exit_ease"?inspector_step.action_exit_ease:inspector_step.ease;
        for(var ease_row=0;ease_row<3;ease_row++){
            var ease_selected=ease_row==selected_ease_value;
            _editor_dropdown_selection(533,221+ease_row*22,627,241+ease_row*22,ease_selected);
            draw_set_color(ease_selected?c_yellow:c_white);TextTyper_DrawFallback(538,223+ease_row*22,BattleEditor_EaseName(ease_row));
        }
    }else if(script_dropdown=="variable_operation"){
        _editor_menu_frame(510,294,628,404);
        var operation_labels=["set 设为","add 加","subtract 减","multiply 乘","divide 除"];
        var operation_values=["set","add","subtract","multiply","divide"];
        for(var operation_row=0;operation_row<5;operation_row++){
            var operation_selected=operation_values[operation_row]==inspector_step.variable_operation;
            _editor_dropdown_selection(511,295+operation_row*22,627,315+operation_row*22,operation_selected);
            draw_set_color(operation_selected?c_yellow:c_white);TextTyper_DrawFallback(516,297+operation_row*22,operation_labels[operation_row]);
        }
    }else if(script_dropdown=="condition_operator"){
        _editor_menu_frame(510,266,628,398);
        var comparator_labels=["==","!=",">",">=","<","<="];
        for(var comparator_row=0;comparator_row<6;comparator_row++){
            var comparator_selected=comparator_labels[comparator_row]==inspector_step.condition_operator;
            _editor_dropdown_selection(511,267+comparator_row*22,627,287+comparator_row*22,comparator_selected);
            draw_set_color(comparator_selected?c_yellow:c_white);TextTyper_DrawFallback(516,269+comparator_row*22,comparator_labels[comparator_row]);
        }
    }else if(script_dropdown=="choice_value"){
        var choice_step=project.script_lists[script_selected_list].steps[script_selected_step];
        var choice_count=BattleEditor_ControlChoiceCount(choice_step.property);
        var mask_choice=choice_step.property=="mask_color";
        var choice_columns=mask_choice?3:1,choice_rows=mask_choice?6:choice_count;
        var choice_left=mask_choice?346:510,choice_column_width=mask_choice?94:118;
        draw_set_color(make_color_rgb(8,8,10));_editor_menu_frame(choice_left,306,628,306+choice_rows*22);
        for(var choice_index=0;choice_index<choice_count;choice_index++){
            var choice_column=choice_index div choice_rows,choice_row=choice_index mod choice_rows;
            var choice_x=choice_left+choice_column*choice_column_width,choice_y=306+choice_row*22;
            var choice_selected=round(real(choice_step.value))==choice_index;
            _editor_dropdown_selection(choice_x+1,choice_y+1,min(627,choice_x+choice_column_width-1),choice_y+21,choice_selected);
            var choice_text_x=choice_x+6;
            if(mask_choice){
                draw_set_color(BattleEditor_MaskColorValue(choice_index));draw_rectangle(choice_x+5,choice_y+5,choice_x+16,choice_y+17,false);
                draw_set_color(c_white);draw_rectangle(choice_x+4,choice_y+4,choice_x+17,choice_y+18,true);
                choice_text_x=choice_x+21;
            }
            draw_set_color(choice_selected?c_yellow:c_white);
            TextTyper_DrawFallback(choice_text_x,choice_y+3,TextTyper_EllipsisFallback(BattleEditor_ControlChoiceCaption(choice_step.property,choice_index),choice_column_width-(choice_text_x-choice_x)-4));
        }
    }else if(script_dropdown=="length_anchor"){
        var length_anchor_step=project.script_lists[script_selected_list].steps[script_selected_step];
        _editor_menu_frame(430,334,628,400);
        for(var length_anchor_row=0;length_anchor_row<3;length_anchor_row++){
            var length_anchor_y=334+length_anchor_row*22;
            _editor_dropdown_selection(431,length_anchor_y+1,627,length_anchor_y+21,round(real(length_anchor_step.length_anchor))==length_anchor_row);
            draw_set_color(round(real(length_anchor_step.length_anchor))==length_anchor_row?c_yellow:c_white);
            TextTyper_DrawFallback(436,length_anchor_y+3,BattleEditor_LengthAnchorDescription(length_anchor_row));
        }
    }else if(script_dropdown=="soul_blue_direction"){
        var soul_direction_step=project.script_lists[script_selected_list].steps[script_selected_step];
        _editor_menu_frame(510,336,628,424);
        for(var soul_direction_row=0;soul_direction_row<4;soul_direction_row++){
            var soul_direction_y=336+soul_direction_row*22;
            var current_soul_direction=soul_direction_step.property=="soul_mode"?soul_direction_step.soul_blue_direction:soul_direction_step.value;
            _editor_dropdown_selection(511,soul_direction_y+1,627,soul_direction_y+21,round(real(current_soul_direction))==soul_direction_row);
            draw_set_color(round(real(current_soul_direction))==soul_direction_row?c_yellow:c_white);
            TextTyper_DrawFallback(516,soul_direction_y+3,BattleEditor_BlueDirectionName(soul_direction_row));
        }
    }else if(script_dropdown=="aim_target_value"){
        var aim_value_options=BattleEditor_AimTargetOptions(project,-1);
        var aim_value_visible=min(8,max(1,array_length(aim_value_options)-script_target_scroll));
        _editor_menu_frame(410,306,628,306+aim_value_visible*22);
        if(array_length(aim_value_options)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(416,309,"没有可用对象");}
        else for(var aim_value_row=0;aim_value_row<aim_value_visible;aim_value_row++){
            var aim_value_option=aim_value_options[script_target_scroll+aim_value_row];
            var aim_value_current=inspector_step.property=="aim_motion"?inspector_step.aim_target_uid:inspector_step.value;
            var aim_value_selected=aim_value_option.uid==aim_value_current;
            _editor_dropdown_selection(411,307+aim_value_row*22,627,327+aim_value_row*22,aim_value_selected);
            draw_set_color(aim_value_selected?c_yellow:c_white);
            TextTyper_DrawFallback(416,309+aim_value_row*22,_editor_ellipsis("["+BattleEditor_TargetTypeName(aim_value_option.target_type)+"] "+aim_value_option.name,202));
        }
    }else if(script_dropdown=="aim_behavior"){
        _editor_menu_frame(430,334,628,400);
        for(var aim_behavior_row=0;aim_behavior_row<3;aim_behavior_row++){
            var aim_behavior_selected=round(real(inspector_step.aim_behavior))==aim_behavior_row;
            _editor_dropdown_selection(431,335+aim_behavior_row*22,627,355+aim_behavior_row*22,aim_behavior_selected);
            draw_set_color(aim_behavior_selected?c_yellow:c_white);
            TextTyper_DrawFallback(436,337+aim_behavior_row*22,BattleEditor_AimBehaviorName(aim_behavior_row));
        }
    }else if(script_dropdown=="aim_motion_mode"){
        _editor_menu_frame(430,362,628,406);
        for(var aim_motion_mode_row=0;aim_motion_mode_row<2;aim_motion_mode_row++){
            var aim_motion_mode_selected=(inspector_step.aim_continuous?1:0)==aim_motion_mode_row;
            _editor_dropdown_selection(431,363+aim_motion_mode_row*22,627,383+aim_motion_mode_row*22,aim_motion_mode_selected);
            draw_set_color(aim_motion_mode_selected?c_yellow:c_white);
            TextTyper_DrawFallback(436,365+aim_motion_mode_row*22,aim_motion_mode_row==0?"执行时锁定一次":"持续追踪目标");
        }
    }
    BattleEditor_UiScissor(dropdown_clip_old);
    draw_set_alpha(1);
}

if(tab==3&&developer_turn_dropdown){
    var developer_turns=BattleEditor_GetKnownTurns(project);
    var developer_dropdown_bottom=216+array_length(developer_turns)*24;
    var developer_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var developer_dropdown_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,216,640,max(1,ceil((480-216)*developer_dropdown_reveal)));
    draw_set_alpha(0.99*developer_dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(336,216,546,developer_dropdown_bottom,false);
    draw_set_alpha(developer_dropdown_reveal);draw_set_color(c_white);draw_rectangle(336,216,546,developer_dropdown_bottom,true);
    for(var developer_row=0;developer_row<array_length(developer_turns);developer_row++){
        var developer_selected=developer_turns[developer_row]==developer_turn;
        _editor_dropdown_selection(337,217+developer_row*24,545,239+developer_row*24,developer_selected);
        draw_set_color(developer_selected?c_yellow:c_white);
        TextTyper_DrawFallback(344,220+developer_row*24,"第 "+string(developer_turns[developer_row])+" 回合");
    }
    BattleEditor_UiScissor(developer_dropdown_old_scissor);
    draw_set_alpha(1);
}

if(font_dropdown_open&&!text_editor_open){
    var font_count=TextTyper_FontCount();
    var font_visible=min(10,font_count-font_dropdown_scroll);
    var font_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var font_dropdown_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,118,640,max(1,ceil((480-118)*font_dropdown_reveal)));
    draw_set_alpha(0.99*font_dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(286,118,570,118+font_visible*24,false);
    draw_set_alpha(font_dropdown_reveal);draw_set_color(c_white);draw_rectangle(286,118,570,118+font_visible*24,true);
    var selected_font_id=-1;
    if(font_dropdown_target=="turn") selected_font_id=BattleEditor_GetTurnData(project,developer_turn,true).turn_font;
    else if(font_dropdown_target=="dialogue") selected_font_id=BattleEditor_GetTurnData(project,developer_turn,true).dialogue_font;
    else if(font_dropdown_target=="script_enemy_speech"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) selected_font_id=project.script_lists[script_selected_list].steps[script_selected_step].dialogue_font;
    else if(font_dropdown_target=="typewriter"&&selected>=0&&selected<array_length(project.events)) selected_font_id=project.events[selected].font_id;
    for(var font_row=0;font_row<font_visible;font_row++){
        var font_id=font_dropdown_scroll+font_row;
        var font_selected=font_id==selected_font_id;
        _editor_dropdown_selection(287,119+font_row*24,569,141+font_row*24,font_selected);
        draw_set_color(font_selected?c_yellow:c_white);
        TextTyper_DrawFallback(294,122+font_row*24,string(font_id)+"  "+TextTyper_FontName(font_id));
    }
    BattleEditor_UiScissor(font_dropdown_old_scissor);
    draw_set_alpha(1);
}

if(damage_dropdown_open&&!text_editor_open){
    var damage_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var damage_dropdown_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,120,640,max(1,ceil((480-120)*damage_dropdown_reveal)));
    draw_set_alpha(0.99*damage_dropdown_reveal);
    draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(438,120,632,336,false);
    draw_set_alpha(damage_dropdown_reveal);
    draw_set_color(c_white);
    draw_rectangle(438,120,632,336,true);
    var selected_damage_type=-1;
    if(damage_dropdown_event>=0&&damage_dropdown_event<array_length(project.events)) selected_damage_type=project.events[damage_dropdown_event].damage_profile.type;
    for(var damage_row=0;damage_row<9;damage_row++){
        var damage_row_y=120+damage_row*24;
        var damage_selected=damage_row==selected_damage_type;
        _editor_dropdown_selection(439,damage_row_y+1,631,damage_row_y+23,damage_selected);
        draw_set_color(BattleEditor_ColorForType(damage_row));
        draw_rectangle(446,damage_row_y+6,458,damage_row_y+18,false);
        draw_set_color(damage_selected?c_yellow:c_white);
        TextTyper_DrawFallback(466,damage_row_y+4,BattleEditor_DamageTypeName(damage_row));
    }
    BattleEditor_UiScissor(damage_dropdown_old_scissor);
    draw_set_alpha(1);
}

if(gb_spawn_dropdown_open&&!text_editor_open){
    var gb_spawn_first=gb_spawn_dropdown_event==-1?1:0;
    var gb_spawn_count=19-gb_spawn_first;
    var gb_spawn_visible=min(10,gb_spawn_count-gb_spawn_dropdown_scroll);
    var gb_spawn_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var gb_spawn_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,102,640,max(1,ceil((480-102)*gb_spawn_reveal)));
    draw_set_alpha(0.99*gb_spawn_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(350,102,632,102+gb_spawn_visible*24,false);
    draw_set_alpha(gb_spawn_reveal);draw_set_color(c_white);draw_rectangle(350,102,632,102+gb_spawn_visible*24,true);
    var selected_gb_spawn=gb_spawn_dropdown_event==-1?project.initialization.gb_spawn_default.preset:(gb_spawn_dropdown_event>=0&&gb_spawn_dropdown_event<array_length(project.events)?project.events[gb_spawn_dropdown_event].spawn_preset:-1);
    for(var gb_spawn_row=0;gb_spawn_row<gb_spawn_visible;gb_spawn_row++){
        var gb_spawn_value=gb_spawn_first+gb_spawn_dropdown_scroll+gb_spawn_row;
        var gb_spawn_selected=gb_spawn_value==selected_gb_spawn;
        _editor_dropdown_selection(351,103+gb_spawn_row*24,631,125+gb_spawn_row*24,gb_spawn_selected);
        draw_set_color(gb_spawn_selected?c_yellow:c_white);
        TextTyper_DrawFallback(358,106+gb_spawn_row*24,BattleEditor_GBSpawnPresetName(gb_spawn_value));
    }
    BattleEditor_UiScissor(gb_spawn_old_scissor);
    draw_set_alpha(1);
}

if(gb_style_dropdown_open&&!text_editor_open){
    var gb_style_choice_count=1+array_length(project.resources.gb_styles);
    var gb_style_choice_visible=min(10,gb_style_choice_count-gb_style_dropdown_scroll);
    var gb_style_choice_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var gb_style_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,102,640,max(1,ceil((480-102)*gb_style_choice_reveal)));
    draw_set_alpha(0.99*gb_style_choice_reveal);draw_set_color(make_color_rgb(8,8,10));draw_rectangle(350,102,632,102+gb_style_choice_visible*24,false);
    draw_set_alpha(gb_style_choice_reveal);draw_set_color(c_white);draw_rectangle(350,102,632,102+gb_style_choice_visible*24,true);
    var selected_gb_style_uid=gb_style_dropdown_event>=0&&gb_style_dropdown_event<array_length(project.events)?project.events[gb_style_dropdown_event].gb_style_uid:-1;
    for(var gb_style_choice_row=0;gb_style_choice_row<gb_style_choice_visible;gb_style_choice_row++){
        var gb_style_choice_index=gb_style_dropdown_scroll+gb_style_choice_row;
        var gb_style_choice_value=BattleEditor_WorkspaceCreateChoiceValue("gb_style",gb_style_choice_index,project);
        var gb_style_choice_selected=gb_style_choice_value==selected_gb_style_uid;
        _editor_dropdown_selection(351,103+gb_style_choice_row*24,631,125+gb_style_choice_row*24,gb_style_choice_selected);
        draw_set_color(gb_style_choice_selected?c_yellow:c_white);TextTyper_DrawFallback(358,106+gb_style_choice_row*24,BattleEditor_GBStyleCaption(project,gb_style_choice_value));
    }
    BattleEditor_UiScissor(gb_style_old_scissor);
    draw_set_alpha(1);
}

if(choice_menu_open&&!text_editor_open){
    var editor_choice_count=BattleEditor_EditorChoiceCount(choice_menu_kind);
    var editor_choice_visible=min(10,editor_choice_count-choice_menu_scroll);
    var editor_choice_selected=-999999;
    if(choice_menu_context=="create_layer") editor_choice_selected=create_layer_mode;
    else if(choice_menu_context=="shield_mode") editor_choice_selected=project.initialization.shield_hud_mode;
    else if(choice_menu_context=="dialogue_template") editor_choice_selected=BattleEditor_GetTurnData(project,developer_turn,true).dialogue_template;
    else if(choice_menu_context=="turn_voice") editor_choice_selected=BattleEditor_VoiceIdToChoice(BattleEditor_GetTurnData(project,developer_turn,true).turn_voice);
    else if(choice_menu_context=="dialogue_voice") editor_choice_selected=BattleEditor_VoiceIdToChoice(BattleEditor_GetTurnData(project,developer_turn,true).dialogue_voice);
    else if(choice_menu_context=="script_enemy_voice"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) editor_choice_selected=BattleEditor_VoiceIdToChoice(project.script_lists[script_selected_list].steps[script_selected_step].dialogue_voice);
    else if(choice_menu_context=="script_enemy_template"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) editor_choice_selected=project.script_lists[script_selected_list].steps[script_selected_step].dialogue_template;
    else if(choice_menu_context=="script_enemy_mode"&&script_selected_list>=0&&script_selected_list<array_length(project.script_lists)&&script_selected_step>=0&&script_selected_step<array_length(project.script_lists[script_selected_list].steps)) editor_choice_selected=project.script_lists[script_selected_list].steps[script_selected_step].dialogue_mode;
    else if(choice_menu_context=="item_voice"&&selected_item>=0&&selected_item<array_length(project.initialization.items)) editor_choice_selected=BattleEditor_VoiceIdToChoice(project.initialization.items[selected_item].voice_id);
    else if(choice_menu_context=="item_after_use"&&selected_item>=0&&selected_item<array_length(project.initialization.items)) editor_choice_selected=project.initialization.items[selected_item].after_use_mode;
    else if(choice_menu_context=="enemy_part") editor_choice_selected=selected_enemy_part;
    else if(choice_menu_event>=0&&choice_menu_event<array_length(project.events)){
        var choice_event=project.events[choice_menu_event];
        if(choice_menu_context=="event_layer") editor_choice_selected=choice_event.layer_mode;
        else if(choice_menu_context=="visual_color_mode") editor_choice_selected=choice_event.visual_tint.mode;
        else if(choice_menu_context=="visual_color_preset") editor_choice_selected=choice_event.visual_tint.preset_type;
        else if(choice_menu_context=="bone_style") editor_choice_selected=choice_event.bone_style;
        else if(choice_menu_context=="bone_aim_behavior") editor_choice_selected=!choice_event.aim_enabled?0:(choice_event.aim_move_enabled?2:1);
        else if(choice_menu_context=="bone_aim_update") editor_choice_selected=choice_event.aim_continuous?1:0;
        else if(choice_menu_context=="gb_fake") editor_choice_selected=choice_event.fake_mode;
        else if(choice_menu_context=="gb_tween") editor_choice_selected=choice_event.transform.tween;
        else if(choice_menu_context=="gb_offset_direction") editor_choice_selected=choice_event.offset_direction_mode;
        else if(choice_menu_context=="solid_shape") editor_choice_selected=choice_event.shape_3d;
        else if(choice_menu_context=="typewriter_voice") editor_choice_selected=BattleEditor_VoiceIdToChoice(choice_event.voice_id);
        else if(choice_menu_context=="platform_type") editor_choice_selected=choice_event.sticky?1:0;
        else if(string_pos("wave_",choice_menu_context)==1){
            var selected_choice_motion=choice_menu_phase==0?choice_event.pre_motion:choice_event.post_motion;
            if(choice_menu_context=="wave_rotation") editor_choice_selected=selected_choice_motion.rotation_mode;
            else if(choice_menu_context=="wave_tween") editor_choice_selected=selected_choice_motion.tween;
            else if(choice_menu_context=="wave_ease") editor_choice_selected=selected_choice_motion.ease;
        }
    }
    var editor_choice_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var editor_choice_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,102,640,max(1,ceil((480-102)*editor_choice_reveal)));
    draw_set_alpha(0.99*editor_choice_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(420,102,632,102+editor_choice_visible*24,false);
    draw_set_alpha(editor_choice_reveal);draw_set_color(c_white);draw_rectangle(420,102,632,102+editor_choice_visible*24,true);
    for(var editor_choice_row=0;editor_choice_row<editor_choice_visible;editor_choice_row++){
        var editor_choice_value=choice_menu_scroll+editor_choice_row;
        var editor_choice_is_selected=editor_choice_value==editor_choice_selected;
        _editor_dropdown_selection(421,103+editor_choice_row*24,631,125+editor_choice_row*24,editor_choice_is_selected);
        draw_set_color(editor_choice_is_selected?c_yellow:c_white);
        TextTyper_DrawFallback(428,106+editor_choice_row*24,BattleEditor_EditorChoiceCaption(choice_menu_kind,editor_choice_value));
    }
    BattleEditor_UiScissor(editor_choice_old_scissor);
    draw_set_alpha(1);
}

if(follow_dropdown_open&&!text_editor_open){
    var follow_options=BattleEditor_FollowFrameOptions(project);
    var follow_visible=min(8,max(0,array_length(follow_options)-follow_dropdown_scroll));
    var follow_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var follow_dropdown_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,120,640,max(1,ceil((480-120)*follow_dropdown_reveal)));
    draw_set_alpha(0.99*follow_dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(438,120,632,120+follow_visible*24,false);
    draw_set_alpha(follow_dropdown_reveal);draw_set_color(c_white);
    draw_rectangle(438,120,632,120+follow_visible*24,true);
    var selected_follow_uid=follow_dropdown_event>=0&&follow_dropdown_event<array_length(project.events)?project.events[follow_dropdown_event].follow_target_uid:-999999;
    for(var follow_row=0;follow_row<follow_visible;follow_row++){
        var follow_frame=follow_options[follow_dropdown_scroll+follow_row];
        var follow_kind=follow_frame.kind==BATTLE_EDITOR_BOARD_KIND.MAIN?"主":(follow_frame.cover?"减":"加");
        var follow_selected=follow_frame.uid==selected_follow_uid;
        _editor_dropdown_selection(439,121+follow_row*24,631,143+follow_row*24,follow_selected);
        draw_set_color(follow_selected?c_yellow:c_white);
        TextTyper_DrawFallback(446,124+follow_row*24,"["+follow_kind+"] "+string_copy(follow_frame.name,1,16));
    }
    BattleEditor_UiScissor(follow_dropdown_old_scissor);
    draw_set_alpha(1);
}

if(aim_dropdown_open&&!text_editor_open&&aim_dropdown_event>=0&&aim_dropdown_event<array_length(project.events)){
    var aim_options=BattleEditor_AimTargetOptions(project,project.events[aim_dropdown_event].uid);
    var aim_visible=min(9,max(0,array_length(aim_options)-aim_dropdown_scroll));
    var aim_dropdown_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var aim_dropdown_old_scissor=gpu_get_scissor();BattleEditor_UiScissor(0,102,640,max(1,ceil((480-102)*aim_dropdown_reveal)));
    draw_set_alpha(0.99*aim_dropdown_reveal);draw_set_color(make_color_rgb(8,8,10));
    draw_rectangle(350,102,632,102+max(1,aim_visible)*24,false);
    draw_set_alpha(aim_dropdown_reveal);draw_set_color(c_white);
    draw_rectangle(350,102,632,102+max(1,aim_visible)*24,true);
    if(aim_visible<=0) TextTyper_DrawFallback(358,106,"没有可用对象");
    for(var aim_row=0;aim_row<aim_visible;aim_row++){
        var aim_option=aim_options[aim_dropdown_scroll+aim_row];
        var aim_selected=aim_option.uid==project.events[aim_dropdown_event].aim_target_uid;
        _editor_dropdown_selection(351,103+aim_row*24,631,125+aim_row*24,aim_selected);
        draw_set_color(aim_selected?c_yellow:c_white);
        TextTyper_DrawFallback(358,106+aim_row*24,"["+BattleEditor_TargetTypeName(aim_option.target_type)+"] "+string_copy(aim_option.name,1,18));
    }
    BattleEditor_UiScissor(aim_dropdown_old_scissor);
    draw_set_alpha(1);
}

if(clip_editor_open&&!text_editor_open&&clip_editor_event>=0&&clip_editor_event<array_length(project.events)){
    var clip_reveal=1-power(1-clamp(dropdown_anim_progress,0,1),3);
    var clip_object=project.events[clip_editor_event];
    draw_set_alpha(0.68*clip_reveal);draw_set_color(c_black);draw_rectangle(0,0,640,480,false);
    draw_set_alpha(0.99*clip_reveal);draw_set_color(make_color_rgb(13,15,20));draw_rectangle(104,66,536,414,false);
    draw_set_alpha(clip_reveal);draw_set_color(c_white);draw_rectangle(104,66,536,414,true);
    draw_set_color(c_yellow);TextTyper_DrawFallback(120,72,"裁剪 / 选择参与裁剪的战斗框");
    _editor_button(502,72,526,94,"×",false);
    _editor_button(120,82,270,104,"默认：全部框",clip_object.clip_mode=="all");
    _editor_button(276,82,432,104,"自定义框集合",clip_object.clip_mode=="selected");
    _editor_field(120,112,432,136,clip_editor_filter,"clip_filter");
    draw_set_color(c_gray);TextTyper_DrawFallback(438,115,"搜索");
    _editor_button(120,142,214,164,"全选",false);
    _editor_button(220,142,314,164,"清空",false);
    _editor_button(320,142,526,164,clip_object.clipped_collision?"[X] 裁掉判定":"[ ] 保留隐形判定",clip_object.clipped_collision);
    var clip_options=BattleEditor_FilterClipFrames(project,clip_editor_filter);
    var clip_visible=min(9,max(0,array_length(clip_options)-clip_editor_scroll));
    for(var clip_row=0;clip_row<clip_visible;clip_row++){
        var clip_frame=clip_options[clip_editor_scroll+clip_row];
        var clip_y=172+clip_row*24;
        var clip_selected=BattleEditor_UidArrayContains(clip_object.clip_frame_uids,clip_frame.uid);
        draw_set_color(clip_selected?make_color_rgb(56,52,15):make_color_rgb(18,18,20));draw_rectangle(120,clip_y,526,clip_y+22,false);
        draw_set_color(clip_selected?c_yellow:c_white);draw_rectangle(120,clip_y,526,clip_y+22,true);
        var clip_kind=clip_frame.kind==BATTLE_EDITOR_BOARD_KIND.MAIN?"主":(clip_frame.cover?"减":"加");
        var clip_label=_editor_ellipsis((clip_selected?"[X] ":"[ ] ")+"["+clip_kind+"] "+clip_frame.name+"  #"+clip_frame.control_id,322);
        TextTyper_DrawFallback(126,clip_y+3,clip_label);
        _editor_button(452,clip_y+1,524,clip_y+21,"同 ID",false);
    }
    draw_set_color(c_gray);TextTyper_DrawFallbackExt(120,392,"左侧勾单个框；“同 ID”一次选择同组框。",18,400);
    draw_set_alpha(1);
}

if(text_editor_open){
    draw_set_alpha(0.72);draw_set_color(c_black);draw_rectangle(0,0,640,480,false);
    draw_set_alpha(0.99);draw_set_color(make_color_rgb(15,17,22));draw_rectangle(62,48,578,424,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(62,48,578,424,true);
    draw_set_color(c_yellow);
    var editor_title=text_editor_target=="turn"?"回合文本编辑":(text_editor_target=="dialogue"?"敌人气泡台词编辑":(text_editor_target=="enemy_action_text"?"行动项目文本编辑":(text_editor_target=="script_enemy_speech"?"控制敌人说话":(text_editor_target=="item"?"物品食用文本编辑":(text_editor_target=="mercy_spare_response"?"饶恕回应编辑":(text_editor_target=="mercy_flee_success"?"逃跑成功回应编辑":(text_editor_target=="mercy_flee_fail"?"逃跑失败回应编辑":"打字机文本编辑")))))));
    TextTyper_DrawFallback(76,58,editor_title);
    _editor_button(526,56,552,78,"?",text_editor_help);
    _editor_button(554,56,572,78,"×",false);

    if(text_editor_help){
        draw_set_color(c_white);
        TextTyper_DrawFallbackExt(78,88,
            "普通 Enter 或 <br>：换行\n"+
            "<page>：结束本句；Z / Enter 后清屏并显示下一句\n"+
            "<wait=0.5>：等待 0.5 秒\n"+
            "<color=#FF6060>文字</color>\n"+
            "<color=#FF606080>文字</color>（含透明度）\n"+
            "<gradient=#FF0000,#0000FF>文字</gradient>\n"+
            "<shake>文字</shake>：普通震动\n"+
            "<glitch>文字</glitch>：RGB 色散震动\n"+
            "<float>文字</float>：正弦漂浮\n"+
            "<rotate=15>文字</rotate>\n"+
            "<cycle>文字</cycle>：彩虹循环\n\n"+
            "这些 Tag 映射到 text_typer 的真实命令。标签必须成对、正确嵌套；渐变与循环色当前会争用颜色，不建议互相嵌套。",
            18,474);
        _editor_button(474,390,562,414,"返回编辑",false);
    }else{
        draw_set_color(make_color_rgb(5,6,9));draw_rectangle(76,86,564,304,false);
        draw_set_color(text_editor_focus=="text"?c_yellow:c_white);draw_rectangle(76,86,564,304,true);
        var editor_visible=string_replace_all(text_editor_buffer,"&","#");
        BattleEditor_DrawEditableText(editor_visible,84,94,18,468);
        if(text_editor_focus=="text"&&((current_time div 450) mod 2)==0){
            var editor_caret_position=BattleEditor_TextCaretPosition(editor_visible,text_editor_caret,84,94,18,468);
            draw_set_color(c_yellow);draw_line(editor_caret_position[0],editor_caret_position[1],editor_caret_position[0],editor_caret_position[1]+15);
        }
        draw_set_color(text_editor_error==""?c_gray:c_red);
        TextTyper_DrawFallbackExt(78,308,text_editor_error==""?"输入测试：中文 ◀ > ▲ ▼ 🤣　　Enter 换行；? 查看 Tag":text_editor_error,18,484);
        _editor_button(76,338,122,360,"换行",false);
        _editor_button(124,338,170,360,"下一句",false);
        _editor_button(172,338,218,360,"等待",false);
        _editor_button(220,338,266,360,"颜色",false);
        _editor_button(268,338,314,360,"渐变",false);
        _editor_button(316,338,362,360,"震动",false);
        _editor_button(364,338,410,360,"色散",false);
        _editor_button(412,338,458,360,"漂浮",false);
        _editor_button(460,338,506,360,"旋转",false);
        _editor_button(508,338,562,360,"循环色",false);
        draw_set_color(c_gray);TextTyper_DrawFallback(76,370,"Hex / Alpha");
        _editor_field(168,366,300,388,text_editor_hex,"text_editor_hex");
        draw_set_color(c_ltgray);TextTyper_DrawFallback(308,370,"#RRGGBB 或 #RRGGBBAA");
        _editor_button(392,394,474,416,"取消",false);
        _editor_button(480,394,562,416,"确定",false);
    }

    if(color_picker_open){
        draw_set_alpha(0.985);draw_set_color(make_color_rgb(12,13,17));
        draw_rectangle(126,82,514,398,false);
        draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(126,82,514,398,true);
        var color_picker_title=color_picker_target=="gradient"?"选择渐变起始颜色":"选择文字颜色";
        if(color_picker_target=="workspace_create_color"||color_picker_target=="event_tint") color_picker_title="选择对象颜色";
        else if(color_picker_target=="global_board"||color_picker_target=="frame") color_picker_title="选择战斗框颜色";
        draw_set_color(c_yellow);TextTyper_DrawFallback(146,94,color_picker_title);

        // Saturation/value square: left is white, right is the selected hue,
        // top is bright and bottom is black.
        for(var picker_y=0;picker_y<24;picker_y++){
            var picker_value=255*(1-picker_y/23);
            for(var picker_x=0;picker_x<48;picker_x++){
                var picker_saturation=255*picker_x/47;
                draw_set_color(make_color_hsv(color_picker_hue,picker_saturation,picker_value));
                var cell_x1=146+picker_x*(348/48);
                var cell_y1=118+picker_y*(152/24);
                draw_rectangle(cell_x1,cell_y1,146+(picker_x+1)*(348/48)+1,118+(picker_y+1)*(152/24)+1,false);
            }
        }
        draw_set_color(c_white);draw_rectangle(146,118,494,270,true);
        var picker_cursor_x=146+color_picker_saturation/255*348;
        var picker_cursor_y=270-color_picker_value/255*152;
        draw_circle_color(picker_cursor_x,picker_cursor_y,4,c_black,c_white,true);

        // Hue wraps red at both ends, as on a conventional spectrum strip.
        for(var hue_index=0;hue_index<64;hue_index++){
            draw_set_color(make_color_hsv(round(hue_index/63*255),255,255));
            draw_rectangle(146+hue_index*(348/64),284,146+(hue_index+1)*(348/64)+1,304,false);
        }
        draw_set_color(c_white);draw_rectangle(146,284,494,304,true);
        var hue_cursor_x=146+color_picker_hue/255*348;
        draw_line(hue_cursor_x,282,hue_cursor_x,306);

        var alpha_color=make_color_hsv(color_picker_hue,color_picker_saturation,color_picker_value);
        for(var alpha_index=0;alpha_index<32;alpha_index++){
            draw_set_alpha(alpha_index/31);
            draw_set_color(alpha_color);
            draw_rectangle(146+alpha_index*(348/32),318,146+(alpha_index+1)*(348/32)+1,338,false);
        }
        draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(146,318,494,338,true);
        var alpha_cursor_x=146+color_picker_alpha/255*348;
        draw_line(alpha_cursor_x,316,alpha_cursor_x,340);

        draw_set_color(c_ltgray);TextTyper_DrawFallback(146,342,"Hue / 明度 / 饱和度 / Alpha    "+text_editor_hex);
        _editor_button(316,358,400,382,"取消",false);
        _editor_button(410,358,494,382,"插入",true);
    }
}

if(script_variables_open){
    draw_set_alpha(0.82);draw_set_color(c_black);draw_rectangle(0,32,640,480,false);
    draw_set_alpha(0.985);draw_set_color(make_color_rgb(10,12,17));draw_rectangle(82,62,558,426,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(82,62,558,426,true);
    draw_set_color(c_yellow);TextTyper_DrawFallback(98,76,"数字变量");
    _editor_button(420,72,474,96,"新增",false);_editor_button(478,72,532,96,"删除",false);
    draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(98,104,"变量可以在数值输入框和控制脚本公式中直接按名字使用。随机、三角函数、开根与对数也使用同一套公式。",18,434);
    var variable_count=array_length(project.variables);
    for(var variable_row=0;variable_row<9;variable_row++){
        var variable_index=script_variable_scroll+variable_row;
        if(variable_index>=variable_count) break;
        var variable_entry=project.variables[variable_index];
        _editor_button(98,154+variable_row*28,316,178+variable_row*28,string(variable_index+1)+". "+variable_entry.name,variable_index==script_selected_variable);
        draw_set_color(c_white);TextTyper_DrawFallback(326,158+variable_row*28,string(variable_entry.value));
    }
    if(script_selected_variable>=0&&script_selected_variable<variable_count){
        var selected_variable=project.variables[script_selected_variable];
        draw_set_color(c_gray);TextTyper_DrawFallback(366,154,"变量名");_editor_field(366,172,532,196,selected_variable.name,"global_variable_name");
        TextTyper_DrawFallback(366,208,"初始数值 / 公式");_editor_field(366,226,532,250,selected_variable.value,"global_variable_value");
        draw_set_color(c_ltgray);TextTyper_DrawFallbackExt(366,266,"可用：random、sin/cos/tan、sqrt、log、ln、abs、floor/ceil/round、min/max、clamp、pow、pi、e。",18,166);
    }
    _editor_button(444,390,532,414,"关闭",false);
}

// The same picker is reused by board, object, typewriter and script colors.
// Markup editing draws it inside its own modal above; ordinary properties draw
// it here so every color field has the same spectrum interaction.
if(color_picker_open&&!text_editor_open){
    draw_set_alpha(0.72);draw_set_color(c_black);draw_rectangle(0,32,640,480,false);
    draw_set_alpha(0.985);draw_set_color(make_color_rgb(12,13,17));draw_rectangle(126,82,514,398,false);
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(126,82,514,398,true);
    draw_set_color(c_yellow);TextTyper_DrawFallback(146,94,"选择颜色");
    for(var picker_y=0;picker_y<24;picker_y++){
        var picker_value=255*(1-picker_y/23);
        for(var picker_x=0;picker_x<48;picker_x++){
            var picker_saturation=255*picker_x/47;
            draw_set_color(make_color_hsv(color_picker_hue,picker_saturation,picker_value));
            var cell_x1=146+picker_x*(348/48);
            var cell_y1=118+picker_y*(152/24);
            draw_rectangle(cell_x1,cell_y1,146+(picker_x+1)*(348/48)+1,118+(picker_y+1)*(152/24)+1,false);
        }
    }
    draw_set_color(c_white);draw_rectangle(146,118,494,270,true);
    var picker_cursor_x=146+color_picker_saturation/255*348;
    var picker_cursor_y=270-color_picker_value/255*152;
    draw_circle_color(picker_cursor_x,picker_cursor_y,4,c_black,c_white,true);
    for(var hue_index=0;hue_index<64;hue_index++){
        draw_set_color(make_color_hsv(round(hue_index/63*255),255,255));
        draw_rectangle(146+hue_index*(348/64),284,146+(hue_index+1)*(348/64)+1,304,false);
    }
    draw_set_color(c_white);draw_rectangle(146,284,494,304,true);
    var hue_cursor_x=146+color_picker_hue/255*348;draw_line(hue_cursor_x,282,hue_cursor_x,306);
    var alpha_color=make_color_hsv(color_picker_hue,color_picker_saturation,color_picker_value);
    for(var alpha_index=0;alpha_index<32;alpha_index++){
        draw_set_alpha(alpha_index/31);draw_set_color(alpha_color);
        draw_rectangle(146+alpha_index*(348/32),318,146+(alpha_index+1)*(348/32)+1,338,false);
    }
    draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(146,318,494,338,true);
    var alpha_cursor_x=146+color_picker_alpha/255*348;draw_line(alpha_cursor_x,316,alpha_cursor_x,340);
    draw_set_color(c_ltgray);TextTyper_DrawFallback(146,342,"色相 / 明度 / 饱和度 / Alpha    "+text_editor_hex);
    _editor_button(316,358,400,382,"取消",false);
    _editor_button(410,358,494,382,"确定",true);
}

if(array_length(save_dialog_stack)>0){
    var save_stack_top_index=array_length(save_dialog_stack)-1;
    var save_backdrop_amount=save_stack_top_index>0?1:clamp(save_dialog_anim_progress,0,1);
    draw_set_alpha(0.76*save_backdrop_amount);draw_set_color(c_black);draw_rectangle(0,32,640,480,false);
    for(var save_stack_draw_index=0;save_stack_draw_index<=save_stack_top_index;save_stack_draw_index++){
    var save_draw_action=save_dialog_stack[save_stack_draw_index];
    var save_slide_raw=save_stack_draw_index==save_stack_top_index?clamp(save_dialog_anim_progress,0,1):1;
    var save_slide_amount=save_slide_raw*save_slide_raw*(3-2*save_slide_raw);
    // GameMaker has no draw_set_transform(). Keep the modal slide in the
    // ordinary world-matrix stack so opening a save window cannot crash Draw.
    var save_dialog_old_world=matrix_get(matrix_world);
    var save_dialog_offset=lerp(680,0,save_slide_amount);
    matrix_set(matrix_world,matrix_multiply(matrix_build(save_dialog_offset,0,0,0,0,0,1,1,1),save_dialog_old_world));
    var save_browser_mode=save_draw_action=="new_save"||save_draw_action=="load_browser";
    if(save_draw_action=="file_menu"){
        draw_set_alpha(0.99);draw_set_color(make_color_rgb(12,13,17));draw_rectangle(150,82,490,402,false);
        draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(150,82,490,402,true);
        draw_set_color(c_yellow);TextTyper_DrawFallback(170,100,"存档");
        var active_slot_name=save_active_name_cache;
        draw_set_color(c_ltgray);TextTyper_DrawFallback(170,124,"当前："+(active_slot_name==""?"尚未建立存档":active_slot_name));
        _editor_button(178,154,462,188,"新建存档",true);
        _editor_button(178,198,462,232,"保存当前存档",active_slot_name!="");
        _editor_button(178,242,462,276,"载入存档",array_length(save_browser_slots)>0);
        _editor_button(178,286,462,320,"撤销上次保存",save_active_backup_ready_cache);
        _editor_button(178,346,462,380,"取消",false);
    }else if(save_browser_mode){
        var save_mode=save_draw_action=="new_save";
        draw_set_alpha(0.99);draw_set_color(make_color_rgb(12,13,17));draw_rectangle(96,64,544,416,false);
        draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(96,64,544,416,true);
        draw_set_color(c_yellow);TextTyper_DrawFallback(118,80,save_mode?"新建存档":"载入存档");
        draw_set_color(c_ltgray);TextTyper_DrawFallback(118,98,"位置：运行文件同级 / save /");
        draw_set_color(c_gray);TextTyper_DrawFallback(118,116,save_mode?"存档名称":"当前选择");
        draw_set_color(make_color_rgb(4,5,8));draw_rectangle(178,112,520,138,false);
        draw_set_color(save_name_editing?c_yellow:c_white);draw_rectangle(178,112,520,138,true);
        var save_name_layout=BattleEditor_SingleLineLayout(save_name_buffer,save_name_editing?save_name_caret:string_length(save_name_buffer),326);
        draw_set_color(c_white);TextTyper_DrawFallback(184,117,save_name_layout.text);
        if(save_name_editing&&((current_time div 450) mod 2)==0){
            var save_name_visible_count=clamp(save_name_layout.caret-save_name_layout.start+1,0,string_length(save_name_layout.text));
            var save_name_prefix=save_name_visible_count>0?string_copy(save_name_layout.text,1,save_name_visible_count):"";
            var save_name_caret_x=min(517,184+TextTyper_StringWidthFallback(save_name_prefix));
            draw_set_color(c_yellow);draw_line(save_name_caret_x,115,save_name_caret_x,135);
        }
        draw_set_color(c_gray);TextTyper_DrawFallback(120,142,"存档列表（一个项目对应一个文件夹）");
        var save_visible=min(6,max(1,array_length(save_browser_slots)-save_browser_scroll));
        draw_set_color(make_color_rgb(5,6,9));draw_rectangle(120,154,520,334,false);
        draw_set_color(c_white);draw_rectangle(120,154,520,334,true);
        if(array_length(save_browser_slots)<=0){draw_set_color(c_gray);TextTyper_DrawFallback(134,166,"还没有文件夹存档");}
        else for(var save_row=0;save_row<save_visible;save_row++){
            var save_index=save_browser_scroll+save_row;
            var save_selected=save_index==save_browser_selected;
            _editor_dropdown_selection(122,156+save_row*30,518,182+save_row*30,save_selected);
            draw_set_color(save_selected?c_yellow:c_white);TextTyper_DrawFallback(132,162+save_row*30,save_browser_slots[save_index]);
            if(save_index<array_length(save_browser_backup_flags)&&save_browser_backup_flags[save_index]){draw_set_color(c_ltgray);TextTyper_DrawFallback(430,162+save_row*30,"有上一版");}
        }
        if(!save_mode) _editor_button(120,338,270,364,"导入旧 JSON...",true);
        _editor_button(120,372,210,400,"返回",false);
        if(!save_mode) _editor_button(218,372,370,400,"复原上次载入",save_undo_load_ready_cache);
        _editor_button(378,372,520,400,save_mode?"创建存档":"载入所选存档",true);
    }else{
        draw_set_alpha(0.99);draw_set_color(make_color_rgb(12,13,17));draw_rectangle(150,132,490,352,false);
        draw_set_alpha(1);draw_set_color(c_white);draw_rectangle(150,132,490,352,true);
        draw_set_color(c_yellow);
        var creating_save=save_draw_action=="save_confirm"&&save_operation_kind=="create";
        var creating_overwrite=creating_save&&BattleEditor_SaveSlotExists(save_pending_name);
        var confirm_title=save_draw_action=="save_confirm"?(creating_overwrite?"名称已存在":(creating_save?"确认新建存档":"确认保存")):(save_draw_action=="load_confirm"?"确认载入":(save_draw_action=="undo_save_confirm"?"撤销上次保存":"复原上次载入"));
        TextTyper_DrawFallback(170,152,confirm_title);
        draw_set_color(c_ltgray);
        var confirm_text="";
        if(save_draw_action=="save_confirm") confirm_text=creating_overwrite?"已经有名为“"+save_pending_name+"”的存档。确定要覆盖吗？覆盖前会保留上一版供一次撤销。":(creating_save?"建立 save/"+save_pending_name+"/ 并把当前项目保存进去。":"将当前项目保存到 save/"+save_pending_name+"/，覆盖前会保留上一版供一次撤销。");
        else if(save_draw_action=="load_confirm") confirm_text="载入会完整替换当前编辑状态。替换前会在 save/_runtime/ 保存一份，可用“复原上次载入”返回。";
        else if(save_draw_action=="undo_save_confirm") confirm_text="把存档“"+save_pending_name+"”恢复为覆盖保存前的上一版。当前内存里的编辑内容不会被改动。";
        else confirm_text="放弃当前载入结果，返回载入发生前的运行态副本。这个返回机会使用后会消耗。";
        TextTyper_DrawFallbackExt(170,188,confirm_text,20,300);
        _editor_button(226,306,316,332,"取消",false);
        _editor_button(324,306,414,332,"确定",true);
    }
    matrix_set(matrix_world,save_dialog_old_world);
    }
    draw_set_alpha(1);
}

if(is_struct(dropdown_draw_restore)){
    script_dropdown=dropdown_draw_restore.script_dropdown;
    font_dropdown_open=dropdown_draw_restore.font_dropdown_open;font_dropdown_target=dropdown_draw_restore.font_dropdown_target;font_dropdown_scroll=dropdown_draw_restore.font_dropdown_scroll;
    damage_dropdown_open=dropdown_draw_restore.damage_dropdown_open;damage_dropdown_event=dropdown_draw_restore.damage_dropdown_event;
    gb_spawn_dropdown_open=dropdown_draw_restore.gb_spawn_dropdown_open;gb_spawn_dropdown_event=dropdown_draw_restore.gb_spawn_dropdown_event;gb_spawn_dropdown_scroll=dropdown_draw_restore.gb_spawn_dropdown_scroll;
    gb_style_dropdown_open=dropdown_draw_restore.gb_style_dropdown_open;gb_style_dropdown_event=dropdown_draw_restore.gb_style_dropdown_event;gb_style_dropdown_scroll=dropdown_draw_restore.gb_style_dropdown_scroll;
    choice_menu_open=dropdown_draw_restore.choice_menu_open;choice_menu_context=dropdown_draw_restore.choice_menu_context;choice_menu_kind=dropdown_draw_restore.choice_menu_kind;choice_menu_event=dropdown_draw_restore.choice_menu_event;choice_menu_phase=dropdown_draw_restore.choice_menu_phase;choice_menu_scroll=dropdown_draw_restore.choice_menu_scroll;
    follow_dropdown_open=dropdown_draw_restore.follow_dropdown_open;follow_dropdown_event=dropdown_draw_restore.follow_dropdown_event;follow_dropdown_scroll=dropdown_draw_restore.follow_dropdown_scroll;
    aim_dropdown_open=dropdown_draw_restore.aim_dropdown_open;aim_dropdown_event=dropdown_draw_restore.aim_dropdown_event;aim_dropdown_scroll=dropdown_draw_restore.aim_dropdown_scroll;
    clip_editor_open=dropdown_draw_restore.clip_editor_open;clip_editor_event=dropdown_draw_restore.clip_editor_event;clip_editor_scroll=dropdown_draw_restore.clip_editor_scroll;clip_editor_filter=dropdown_draw_restore.clip_editor_filter;
    initialization_turn_dropdown=dropdown_draw_restore.initialization_turn_dropdown;battle_music_dropdown_open=dropdown_draw_restore.battle_music_dropdown_open;battle_music_scroll=dropdown_draw_restore.battle_music_scroll;
    developer_turn_dropdown=dropdown_draw_restore.developer_turn_dropdown;object_palette_category_open=dropdown_draw_restore.object_palette_category_open;
}

// The toolbar is the final draw layer. In Workspace this guarantees the fixed
// order: grid at the bottom, wires/lists in the middle, global buttons on top.
_editor_toolbar();

