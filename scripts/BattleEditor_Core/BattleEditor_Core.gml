function BattleEditor_DrawAuthoringContent(controller,tools_only) {
    with(controller){
    var draw_all_authoring_objects=!playing&&!timeline_half_play&&scene_objects_visible;
    var draw_selected_authoring_object=!playing&&!timeline_half_play&&!scene_objects_visible&&selected>=0;
    var draw_new_object_preview=timeline_half_play&&array_length(new_object_preview_uids)>0;
    var draw_board_authoring=!playing&&!timeline_half_play&&board_edit_session;
    if(draw_all_authoring_objects||draw_selected_authoring_object||draw_new_object_preview||draw_board_authoring){
        for(var i=0;i<array_length(project.events);i++){
            var attack=project.events[i];
            if(!BattleEditor_EventBelongsToTurn(attack,developer_turn)) continue;
            // A frozen playback frame keeps its real scheduled contents. Every
            // object placed during this editing session is drawn here as the
            // draggable replacement for its same-UID runtime instance.
            var is_session_preview=struct_exists(attack,"uid")&&BattleEditor_UidArrayContains(new_object_preview_uids,attack.uid);
            if(!draw_all_authoring_objects&&!(draw_selected_authoring_object&&i==selected)&&!(draw_new_object_preview&&is_session_preview)) continue;
            var track=attack.transform;
            var preview_group_selected=group_selection_active&&selected>=0&&BattleEditor_IsSameEventGroup(project.events[selected],attack);
            var alpha=i==selected?1:(preview_group_selected?0.88:0.58);
            var is_bone=attack.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&attack.preset=="bone";
            var is_gb=attack.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&attack.preset=="gb";
            var is_typewriter=attack.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER;
            var is_wave=attack.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(attack.preset=="slash"||attack.preset=="true_knife");
            var is_solid=attack.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(attack.preset=="bone_3d"||attack.preset=="bone_4d");
            var is_platform=attack.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&attack.preset=="platform";
            if(!tools_only){
            if(is_typewriter){
                draw_set_color(attack.transform.color);
                TextTyper_DrawFallbackTransformed(attack.transform.x,attack.transform.y,TextTyper_MarkupPlain(attack.text),attack.transform.scale_x,attack.transform.scale_y,attack.transform.angle);
            }else if(is_bone){
                var bone_color=attack.visual_tint.enabled
                    ?(attack.visual_tint.follow_damage_profile?BattleEditor_ColorForType(attack.damage_profile.type):attack.visual_tint.color)
                    :c_white;
                var bone_preview=BattleEditor_BoneWorldTransform(attack,project,main_board_preview);
                if(attack.bone_style==1) Battle_DrawBoneSpikeAt(bone_preview.x,bone_preview.y,attack.length,bone_preview.angle,0,bone_color,alpha);
                else draw_sprite_ext(spr_bone,0,bone_preview.x,bone_preview.y,(attack.length+10)/14,1,bone_preview.angle,bone_color,alpha);
            }else if(is_gb){
                var gb_color=attack.visual_tint.enabled
                    ?(attack.visual_tint.follow_damage_profile?BattleEditor_ColorForType(attack.damage_profile.type):attack.visual_tint.color)
                    :c_white;
                // Scene placement represents the destination. Spawn data may
                // intentionally live far outside the visible battle screen.
                var gb_preview_sprite=BattleEditor_GBStylePreviewSprite(id,project,attack.gb_style_uid);
                // Scene placement is a stable closed-mouth preview. The GB
                // resource page owns the one-shot firing preview.
                var gb_preview_frame=0;
                var gb_preview_definition=BattleEditor_GBStyleDefinition(project,attack.gb_style_uid);
                var gb_preview_angle=attack.angle_target-(is_undefined(gb_preview_definition)?0:gb_preview_definition.source_direction);
                draw_sprite_ext(gb_preview_sprite,gb_preview_frame,attack.target_x,attack.target_y,track.scale_x*2,track.scale_y*2,gb_preview_angle,gb_color,alpha);
            }else if(is_solid){
                var solid_color=attack.visual_tint.enabled
                    ?(attack.visual_tint.follow_damage_profile?BattleEditor_ColorForType(attack.damage_profile.type):attack.visual_tint.color)
                    :c_white;
                var solid_radius=max(12,max(abs(attack.size_x),abs(attack.size_y)));
                var solid_shift=max(6,abs(attack.size_z)*0.35);
                var solid_a=attack.angle_z;
                var solid_x1=track.x+lengthdir_x(solid_radius,solid_a+180),solid_y1=track.y+lengthdir_y(solid_radius,solid_a+180);
                var solid_x2=track.x+lengthdir_x(solid_radius,solid_a),solid_y2=track.y+lengthdir_y(solid_radius,solid_a);
                var solid_x3=track.x+lengthdir_x(solid_radius,solid_a+90),solid_y3=track.y+lengthdir_y(solid_radius,solid_a+90);
                var solid_x4=track.x+lengthdir_x(solid_radius,solid_a-90),solid_y4=track.y+lengthdir_y(solid_radius,solid_a-90);
                draw_set_color(solid_color);draw_set_alpha(alpha);
                draw_line_width(solid_x1,solid_y1,solid_x3,solid_y3,2);draw_line_width(solid_x3,solid_y3,solid_x2,solid_y2,2);draw_line_width(solid_x2,solid_y2,solid_x4,solid_y4,2);draw_line_width(solid_x4,solid_y4,solid_x1,solid_y1,2);
                draw_line_width(solid_x1+solid_shift,solid_y1-solid_shift,solid_x3+solid_shift,solid_y3-solid_shift,2);draw_line_width(solid_x3+solid_shift,solid_y3-solid_shift,solid_x2+solid_shift,solid_y2-solid_shift,2);draw_line_width(solid_x2+solid_shift,solid_y2-solid_shift,solid_x4+solid_shift,solid_y4-solid_shift,2);draw_line_width(solid_x4+solid_shift,solid_y4-solid_shift,solid_x1+solid_shift,solid_y1-solid_shift,2);
                draw_set_alpha(1);
            }else if(is_wave){
                var wave_color=attack.visual_tint.enabled
                    ?(attack.visual_tint.follow_damage_profile?BattleEditor_ColorForType(attack.damage_profile.type):attack.visual_tint.color)
                    :c_white;
                var half_preview_length=900;
                draw_set_color(wave_color);
                draw_line_width(track.x+lengthdir_x(half_preview_length,track.angle+180),track.y+lengthdir_y(half_preview_length,track.angle+180),track.x+lengthdir_x(half_preview_length,track.angle),track.y+lengthdir_y(half_preview_length,track.angle),attack.preset=="true_knife"?7:attack.visual_min_width);
            }else if(is_platform){
                var platform_sprite=attack.sticky?spr_battle_platform_green:spr_battle_platform_purple;
                draw_sprite_ext(platform_sprite,0,track.x,track.y,max(4,attack.width)/sprite_get_width(platform_sprite),1,track.angle,c_white,alpha);
            }else{
                var preview_sprite=asset_get_index(attack.sprite_source);
                var preview_color=c_white;
                if(attack.visual_tint.enabled){
                    if(attack.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&attack.visual_tint.follow_damage_profile) preview_color=BattleEditor_ColorForType(attack.damage_profile.type);
                    else preview_color=attack.visual_tint.color;
                }
                if(sprite_exists(preview_sprite)){
                    var preview_frame=0;
                    if(struct_exists(attack,"animation")&&attack.animation.fps>0&&sprite_get_number(preview_sprite)>1){
                        preview_frame=floor(current_time*0.001*attack.animation.fps) mod sprite_get_number(preview_sprite);
                    }
                    draw_sprite_ext(preview_sprite,preview_frame,track.x,track.y,track.scale_x,track.scale_y,track.angle,preview_color,alpha*track.alpha);
                }

            }
            }else if(!is_typewriter&&!is_bone&&!is_gb&&!is_solid&&!is_wave&&!is_platform&&!sprite_exists(asset_get_index(attack.sprite_source))){
                draw_set_color(i==selected?c_yellow:c_orange);
                draw_rectangle(track.x-12,track.y-12,track.x+12,track.y+12,true);
                TextTyper_DrawFallback(track.x-4,track.y-8,"?");
            }
        }

        if(tools_only&&draw_board_authoring){
            var editor_frames=project.initialization.frames;
            for(var frame_index=-1;frame_index<array_length(editor_frames);frame_index++){
            var frame=frame_index==-1?main_board_preview:editor_frames[frame_index];
            var world_vertices=BattleEditor_FrameWorldVertices(frame);
            draw_set_color(frame_index==selected_frame?c_yellow:(frame.cover?c_lime:c_aqua));
            for(var i=0;i<array_length(world_vertices);i++){
                draw_circle(world_vertices[i][0],world_vertices[i][1],frame_index==selected_frame?4:3,false);
            }
            }
        }
    }
    }
}

function BattleEditor_UiScissor(x,y=0,width=0,height=0) {
    // gpu_get_scissor returns physical pixels (a struct on current runners).
    // Restoring an opaque state must not multiply it again.
    if(is_struct(x)||is_array(x)){gpu_set_scissor(x);return;}
    if(variable_global_exists("battle_editor_ui_controller")&&instance_exists(global.battle_editor_ui_controller)){
        var c=global.battle_editor_ui_controller;
        gpu_set_scissor(floor(x*c.editor_ui_scale_x),floor(y*c.editor_ui_scale_y),max(1,ceil(width*c.editor_ui_scale_x)),max(1,ceil(height*c.editor_ui_scale_y)));
    }else gpu_set_scissor(x,y,width,height);
}

function BattleEditor_DrawUiOverlay(controller) {
    if(!instance_exists(controller)) return;
    if(controller.text_editor_preview_mode||(controller.playing&&!controller.timeline_seek_active)) return;
    if(instance_exists(turn_test)&&instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.IN_TURN) return;
    var viewport=Window_ContentViewport();
    var sw=viewport.window_width,sh=viewport.window_height;
    var ox=viewport.x,oy=viewport.y,w=viewport.width,h=viewport.height;
    if(surface_exists(controller.editor_ui_surface)&&(surface_get_width(controller.editor_ui_surface)!=w||surface_get_height(controller.editor_ui_surface)!=h)){
        surface_free(controller.editor_ui_surface);controller.editor_ui_surface=-1;
    }
    if(!surface_exists(controller.editor_ui_surface)) controller.editor_ui_surface=surface_create(w,h);
    if(!surface_exists(controller.editor_ui_surface)) return;
    var old_world=matrix_get(matrix_world),old_view=matrix_get(matrix_view),old_projection=matrix_get(matrix_projection);
    var old_font=draw_get_font(),old_color=draw_get_color(),old_alpha=draw_get_alpha();
    var old_halign=draw_get_halign(),old_valign=draw_get_valign();
    gpu_push_state();
    surface_set_target(controller.editor_ui_surface);
    draw_clear_alpha(c_black,0);
    camera_set_view_size(controller.editor_ui_camera,640,480);
    camera_apply(controller.editor_ui_camera);
    matrix_set(matrix_world,matrix_build_identity());
    gpu_set_scissor(0,0,w,h);
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha,bm_inv_src_alpha,bm_one,bm_inv_src_alpha);
    controller.editor_ui_scale_x=w/640;controller.editor_ui_scale_y=h/480;
    controller.editor_ui_drawing=true;
    global.battle_editor_ui_controller=controller;
    try {
        with(controller) event_perform(ev_draw,0);
    } finally {
        global.battle_editor_ui_controller=noone;
        controller.editor_ui_drawing=false;
        surface_reset_target();
        camera_set_view_size(controller.editor_ui_camera,sw,sh);
        camera_apply(controller.editor_ui_camera);
        matrix_set(matrix_world,matrix_build_identity());
        gpu_set_scissor(0,0,sw,sh);
        gpu_set_blendmode_ext(bm_one,bm_inv_src_alpha);
        draw_set_alpha(1);draw_set_color(c_white);
        draw_surface(controller.editor_ui_surface,ox,oy);
        gpu_pop_state();
        matrix_set(matrix_world,old_world);matrix_set(matrix_view,old_view);matrix_set(matrix_projection,old_projection);
        draw_set_font(old_font);draw_set_color(old_color);draw_set_alpha(old_alpha);
        draw_set_halign(old_halign);draw_set_valign(old_valign);
    }
}

enum BATTLE_EDITOR_OBJECT_KIND {
    SPRITE_HAZARD,
    MECHANIC_HAZARD,
    DECORATION,
    TYPEWRITER
}

enum BATTLE_EDITOR_BOARD_KIND {
    MAIN,
    ADD,
    SUBTRACT
}

enum BATTLE_EDITOR_LAYER {
    IN_BOARD,
    OUTSIDE,
    BELOW_BOARD
}

#macro BATTLE_EDITOR_ENEMY_LIMIT 15
#macro BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT 3

function BattleEditor_LayerName(layer_mode) {
    if(layer_mode==BATTLE_EDITOR_LAYER.OUTSIDE) return "框外";
    if(layer_mode==BATTLE_EDITOR_LAYER.BELOW_BOARD) return "框下";
    return "框内";
}

function BattleEditor_BoneStyleName(bone_style) {
    return round(real(bone_style))==1?"骨刺":"普通骨头";
}

/// Intent-level label for the generic target-facing operation. The runtime
/// remains shared by every movable/rotatable target.
function BattleEditor_AimBehaviorName(aim_behavior) {
    return ["仅面朝目标","面朝并向目标移动","只向目标方向移动"][clamp(round(real(aim_behavior)),0,2)];
}

function BattleEditor_BoneAimBehaviorName(aim_behavior) {
    return ["关闭指向","仅面朝目标","面朝并向目标移动"][clamp(round(real(aim_behavior)),0,2)];
}

function BattleEditor_LifetimeCaption(value) {
    return real(value)<0?"本回合":string(value);
}

function BattleEditor_AimBehaviorFromLegacy(move_speed,face_target) {
    var speed_text=string_trim(string(move_speed));
    if(speed_text==""||speed_text=="0"||speed_text=="0.0"||speed_text=="0.00") return 0;
    return face_target?1:2;
}

function BattleEditor_CycleLayer(layer_mode,direction=1) {
    layer_mode+=sign(direction);
    if(layer_mode>BATTLE_EDITOR_LAYER.BELOW_BOARD) layer_mode=BATTLE_EDITOR_LAYER.IN_BOARD;
    if(layer_mode<BATTLE_EDITOR_LAYER.IN_BOARD) layer_mode=BATTLE_EDITOR_LAYER.BELOW_BOARD;
    return layer_mode;
}

// INHERIT 只允许单个 GB 使用；初始化里的全局默认必须是实际预设。
enum BATTLE_EDITOR_GB_SPAWN {
    INHERIT,
    CUSTOM,
    SCREEN_CENTER,
    SCREEN_TOP,
    SCREEN_TOP_RIGHT,
    SCREEN_RIGHT,
    SCREEN_BOTTOM_RIGHT,
    SCREEN_BOTTOM,
    SCREEN_BOTTOM_LEFT,
    SCREEN_LEFT,
    SCREEN_TOP_LEFT,
    TARGET_TOP,
    TARGET_TOP_RIGHT,
    TARGET_RIGHT,
    TARGET_BOTTOM_RIGHT,
    TARGET_BOTTOM,
    TARGET_BOTTOM_LEFT,
    TARGET_LEFT,
    TARGET_TOP_LEFT
}

function BattleEditor_GBSpawnPresetName(preset) {
    switch(preset){
        case BATTLE_EDITOR_GB_SPAWN.INHERIT: return "无（继承默认）";
        case BATTLE_EDITOR_GB_SPAWN.CUSTOM: return "自定义坐标";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_CENTER: return "画面中心";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP: return "画面正上方外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP_RIGHT: return "画面右上角外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_RIGHT: return "画面右方外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM_RIGHT: return "画面右下角外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM: return "画面正下方外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM_LEFT: return "画面左下角外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_LEFT: return "画面左方外";
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP_LEFT: return "画面左上角外";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP: return "目标正上方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP_RIGHT: return "目标右上方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_RIGHT: return "目标右方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM_RIGHT: return "目标右下方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM: return "目标正下方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM_LEFT: return "目标左下方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_LEFT: return "目标左方";
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP_LEFT: return "目标左上方";
    }
    return "画面正上方外";
}

function BattleEditor_CycleGBSpawnPreset(preset, direction=1, allow_inherit=true) {
    var first=allow_inherit?BATTLE_EDITOR_GB_SPAWN.INHERIT:BATTLE_EDITOR_GB_SPAWN.CUSTOM;
    var last=BATTLE_EDITOR_GB_SPAWN.TARGET_TOP_LEFT;
    preset+=sign(direction);
    if(preset>last) preset=first;
    if(preset<first) preset=last;
    return preset;
}

function BattleEditor_FilterNumberText(value) {
    var source=string(value);
    var result="";
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if((ch>="0"&&ch<="9")||(string_lower(ch)>="a"&&string_lower(ch)<="z")||ord(ch)>127||ch=="_"||ch=="."||ch=="+"||ch=="-"||ch=="*"||ch=="/"||ch=="("||ch==")"||ch==","||ch==" ") result+=ch;
    }
    return result;
}

function BattleEditor_ExpressionVariables(project_or_controller) {
    if(is_undefined(project_or_controller)) return {};
    // GML has no is_instance() predicate.  The only accepted inputs here are
    // a project struct or a live runtime-controller instance, so structures
    // can be separated safely before calling instance-only reflection APIs.
    var controller_input=!is_struct(project_or_controller)&&instance_exists(project_or_controller);
    var project=controller_input&&variable_instance_exists(project_or_controller,"project")?project_or_controller.project:project_or_controller;
    var result=controller_input&&variable_instance_exists(project_or_controller,"runtime_variables")?project_or_controller.runtime_variables:{};
    if(!controller_input&&is_struct(project)&&struct_exists(project,"variables")&&is_array(project.variables)){
        for(var i=0;i<array_length(project.variables);i++){
            var entry=project.variables[i];
            if(is_struct(entry)&&struct_exists(entry,"name")) variable_struct_set(result,string(entry.name),struct_exists(entry,"value")?entry.value:0);
        }
    }
    // Variables authored as ordinary Workspace items are also valid names in
    // every formula field. Their runtime values still follow list order; zero
    // here is only an editor-side symbol declaration for validation.
    if(is_struct(project)&&struct_exists(project,"script_lists")&&is_array(project.script_lists)){
        for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
            var list_data=project.script_lists[list_index];
            if(!is_struct(list_data)||!struct_exists(list_data,"steps")||!is_array(list_data.steps)) continue;
            for(var step_index=0;step_index<array_length(list_data.steps);step_index++){
                var step_data=list_data.steps[step_index];
                if(is_struct(step_data)&&struct_exists(step_data,"kind")&&step_data.kind=="set_variable"&&struct_exists(step_data,"variable_name")&&string_length(string_trim(string(step_data.variable_name)))>0){
                    var step_variable_name=string_trim(string(step_data.variable_name));
                    if(!variable_struct_exists(result,step_variable_name)) variable_struct_set(result,step_variable_name,0);
                }
                if(is_struct(step_data)&&struct_exists(step_data,"kind")&&step_data.kind=="get_value"&&struct_exists(step_data,"read_variable_name")&&string_length(string_trim(string(step_data.read_variable_name)))>0){
                    var read_variable_name=string_trim(string(step_data.read_variable_name));
                    if(!variable_struct_exists(result,read_variable_name)) variable_struct_set(result,read_variable_name,0);
                }
            }
        }
    }
    if(is_struct(project)) BattleEditor_AppendBuiltinExpressionVariables(result,project,controller_input?project_or_controller:undefined);
    return result;
}

function BattleEditor_ExprSkip(parser) {
    while(parser.pos<=string_length(parser.source)&&string_char_at(parser.source,parser.pos)==" ") parser.pos+=1;
}

function BattleEditor_ExprFail(parser,message,error_pos=-1) {
    parser.valid=false;
    if(parser.error==""){
        parser.error=message;
        parser.error_pos=error_pos<0?parser.pos:error_pos;
    }
    return 0;
}

function BattleEditor_ExprParseIdentifier(parser) {
    BattleEditor_ExprSkip(parser);
    var result="";
    while(parser.pos<=string_length(parser.source)){
        var ch=string_char_at(parser.source,parser.pos);
        var lower=string_lower(ch);
        if((lower>="a"&&lower<="z")||(ch>="0"&&ch<="9")||ord(ch)>127||ch=="_"){result+=ch;parser.pos+=1;}
        else break;
    }
    return result;
}

function BattleEditor_ExprApplyFunction(name,args,parser) {
    name=string_lower(name);
    var count=array_length(args);
    if((name=="random"||name=="rand")&&count==1) return random(args[0]);
    if((name=="random"||name=="rand")&&count==2) return random_range(args[0],args[1]);
    if(name=="sin"&&count==1) return dsin(args[0]);
    if(name=="cos"&&count==1) return dcos(args[0]);
    if(name=="tan"&&count==1) return dtan(args[0]);
    if(name=="sqrt"&&count==1&&args[0]>=0) return sqrt(args[0]);
    if(name=="log"&&count==1&&args[0]>0) return log10(args[0]);
    if(name=="ln"&&count==1&&args[0]>0) return ln(args[0]);
    if(name=="abs"&&count==1) return abs(args[0]);
    if(name=="floor"&&count==1) return floor(args[0]);
    if(name=="ceil"&&count==1) return ceil(args[0]);
    if(name=="round"&&count==1) return round(args[0]);
    if(name=="min"&&count==2) return min(args[0],args[1]);
    if(name=="max"&&count==2) return max(args[0],args[1]);
    if(name=="clamp"&&count==3) return clamp(args[0],args[1],args[2]);
    if((name=="pow"||name=="power")&&count==2) return power(args[0],args[1]);
    var known=name=="random"||name=="rand"||name=="sin"||name=="cos"||name=="tan"||name=="sqrt"||name=="log"||name=="ln"||name=="abs"||name=="floor"||name=="ceil"||name=="round"||name=="min"||name=="max"||name=="clamp"||name=="pow"||name=="power";
    return BattleEditor_ExprFail(parser,known?("函数 "+name+" 的参数数量不正确"):("未知函数："+name));
}

function BattleEditor_ExprParsePrimary(parser) {
    BattleEditor_ExprSkip(parser);
    if(parser.pos>string_length(parser.source)) return BattleEditor_ExprFail(parser,"缺少数值、变量或右括号");
    var ch=string_char_at(parser.source,parser.pos);
    if(ch=="("){
        parser.pos+=1;
        var grouped=BattleEditor_ExprParseAdd(parser);
        BattleEditor_ExprSkip(parser);
        if(parser.pos>string_length(parser.source)||string_char_at(parser.source,parser.pos)!=")") BattleEditor_ExprFail(parser,"左括号没有对应的右括号");
        else parser.pos+=1;
        return grouped;
    }
    if((ch>="0"&&ch<="9")||ch=="."){
        var number_text="";
        var dots=0;
        while(parser.pos<=string_length(parser.source)){
            ch=string_char_at(parser.source,parser.pos);
            if(ch>="0"&&ch<="9") number_text+=ch;
            else if(ch=="."&&dots==0){number_text+=ch;dots+=1;}
            else break;
            parser.pos+=1;
        }
        if(number_text=="."||number_text=="") return BattleEditor_ExprFail(parser,"小数点前后至少需要一个数字");
        return real(number_text);
    }
    var identifier=BattleEditor_ExprParseIdentifier(parser);
    if(identifier=="") return BattleEditor_ExprFail(parser,"这里需要数值、变量或函数");
    BattleEditor_ExprSkip(parser);
    if(parser.pos<=string_length(parser.source)&&string_char_at(parser.source,parser.pos)=="("){
        parser.pos+=1;
        var args=[];
        BattleEditor_ExprSkip(parser);
        if(parser.pos<=string_length(parser.source)&&string_char_at(parser.source,parser.pos)==")") parser.pos+=1;
        else{
            while(parser.valid){
                array_push(args,BattleEditor_ExprParseAdd(parser));
                BattleEditor_ExprSkip(parser);
                if(parser.pos<=string_length(parser.source)&&string_char_at(parser.source,parser.pos)==","){parser.pos+=1;continue;}
                if(parser.pos<=string_length(parser.source)&&string_char_at(parser.source,parser.pos)==")"){parser.pos+=1;break;}
                BattleEditor_ExprFail(parser,"函数参数之间需要逗号，结尾需要右括号");
            }
        }
        return BattleEditor_ExprApplyFunction(identifier,args,parser);
    }
    var lower_identifier=string_lower(identifier);
    if(lower_identifier=="pi") return pi;
    if(lower_identifier=="e") return exp(1);
    if(variable_struct_exists(parser.variables,identifier)){
        var variable_value=variable_struct_get(parser.variables,identifier);
        if(is_real(variable_value)) return variable_value;
        var nested=BattleEditor_EvaluateNumberExpression(variable_value,parser.variables);
        if(nested.valid) return nested.value;
    }
    return BattleEditor_ExprFail(parser,"未知变量："+identifier);
}

function BattleEditor_ExprParseUnary(parser) {
    BattleEditor_ExprSkip(parser);
    if(parser.pos<=string_length(parser.source)){
        var ch=string_char_at(parser.source,parser.pos);
        if(ch=="+"){parser.pos+=1;return BattleEditor_ExprParseUnary(parser);}
        if(ch=="-"){parser.pos+=1;return -BattleEditor_ExprParseUnary(parser);}
    }
    return BattleEditor_ExprParsePrimary(parser);
}

function BattleEditor_ExprParseMul(parser) {
    var value=BattleEditor_ExprParseUnary(parser);
    while(parser.valid){
        BattleEditor_ExprSkip(parser);
        if(parser.pos>string_length(parser.source)) break;
        var op=string_char_at(parser.source,parser.pos);
        if(op!="*"&&op!="/") break;
        parser.pos+=1;
        var right=BattleEditor_ExprParseUnary(parser);
        if(op=="*") value*=right;
        else if(abs(right)<0.000000001) return BattleEditor_ExprFail(parser,"不能除以 0");
        else value/=right;
    }
    return value;
}

function BattleEditor_ExprParseAdd(parser) {
    var value=BattleEditor_ExprParseMul(parser);
    while(parser.valid){
        BattleEditor_ExprSkip(parser);
        if(parser.pos>string_length(parser.source)) break;
        var op=string_char_at(parser.source,parser.pos);
        if(op!="+"&&op!="-") break;
        parser.pos+=1;
        var right=BattleEditor_ExprParseMul(parser);
        if(op=="+") value+=right; else value-=right;
    }
    return value;
}

function BattleEditor_EvaluateNumberExpression(value,variables=undefined) {
    var parser={source:string(value),pos:1,valid:true,error:"",error_pos:1,variables:is_undefined(variables)?{}:variables};
    if(string_length(string_trim(parser.source))<=0) return {valid:false,value:0,error:"公式为空",error_pos:1};
    var parsed_value=BattleEditor_ExprParseAdd(parser);
    BattleEditor_ExprSkip(parser);
    if(parser.valid&&parser.pos<=string_length(parser.source)) BattleEditor_ExprFail(parser,"无法识别的符号："+string_char_at(parser.source,parser.pos));
    if(!parser.valid&&parser.error=="") parser.error="公式语法不完整";
    return {valid:parser.valid&&parser.pos>string_length(parser.source),value:parsed_value,error:parser.error,error_pos:parser.error_pos};
    /* Legacy shunting-yard evaluator retained below as unreachable source
       documentation for old projects. */
    var source=string_replace_all(string(value)," ","");
    source=string_replace_all(source,"\t","");
    if(string_length(source)<=0) return {valid:false,value:0};
    var output=[];
    var operators=[];
    var cursor=1;
    var expect_value=true;
    while(cursor<=string_length(source)){
        var ch=string_char_at(source,cursor);
        var signed_number=expect_value&&(ch=="+"||ch=="-")&&cursor<string_length(source);
        var next_char=signed_number?string_char_at(source,cursor+1):"";
        if((ch>="0"&&ch<="9")||ch=="."||(signed_number&&((next_char>="0"&&next_char<="9")||next_char=="."))){
            var number_text="";
            var dots=0;
            if(signed_number){number_text+=ch;cursor+=1;}
            while(cursor<=string_length(source)){
                ch=string_char_at(source,cursor);
                if(ch>="0"&&ch<="9") number_text+=ch;
                else if(ch=="."&&dots==0){number_text+=ch;dots+=1;}
                else break;
                cursor+=1;
            }
            if(number_text==""||number_text=="+"||number_text=="-"||number_text=="."||number_text=="+."||number_text=="-.") return {valid:false,value:0};
            array_push(output,real(number_text));
            expect_value=false;
            continue;
        }
        if(ch=="("&&expect_value){array_push(operators,ch);cursor+=1;continue;}
        if(ch==")"&&!expect_value){
            var found_open=false;
            while(array_length(operators)>0){
                var top=array_pop(operators);
                if(top=="("){found_open=true;break;}
                array_push(output,top);
            }
            if(!found_open) return {valid:false,value:0};
            cursor+=1;expect_value=false;continue;
        }
        if((ch=="+"||ch=="-"||ch=="*"||ch=="/")&&!expect_value){
            var precedence=(ch=="*"||ch=="/")?2:1;
            while(array_length(operators)>0){
                var top=operators[array_length(operators)-1];
                if(top=="(") break;
                var top_precedence=(top=="*"||top=="/")?2:1;
                if(top_precedence<precedence) break;
                array_push(output,array_pop(operators));
            }
            array_push(operators,ch);
            cursor+=1;expect_value=true;continue;
        }
        return {valid:false,value:0};
    }
    if(expect_value) return {valid:false,value:0};
    while(array_length(operators)>0){
        var top=array_pop(operators);
        if(top=="(") return {valid:false,value:0};
        array_push(output,top);
    }
    var values=[];
    for(var token_index=0;token_index<array_length(output);token_index++){
        var token=output[token_index];
        if(is_real(token)){array_push(values,token);continue;}
        if(array_length(values)<2) return {valid:false,value:0};
        var b=array_pop(values);
        var a=array_pop(values);
        if(token=="+") array_push(values,a+b);
        else if(token=="-") array_push(values,a-b);
        else if(token=="*") array_push(values,a*b);
        else if(token=="/"){
            if(abs(b)<0.000000001) return {valid:false,value:0};
            array_push(values,a/b);
        }
    }
    if(array_length(values)!=1) return {valid:false,value:0};
    return {valid:true,value:values[0]};
}

function BattleEditor_ReadNumberText(value, fallback) {
    var expression=BattleEditor_EvaluateNumberExpression(value);
    return expression.valid?expression.value:fallback;
}

function BattleEditor_IsNumberText(value) {
    return BattleEditor_EvaluateNumberExpression(value).valid;
}

// Single-line editor primitives shared by every ordinary input box.  The
// GameMaker keyboard_string value is only the current OS/IME composition; the
// complete authored value and its caret live in this returned state instead.
function BattleEditor_SingleLineEditStep(buffer,caret,keyboard_seen,keyboard_anchor) {
    var edit_buffer=string(buffer);
    var edit_caret=clamp(round(caret),0,string_length(edit_buffer));
    var edit_seen=string(keyboard_seen);
    var edit_anchor=clamp(round(keyboard_anchor),0,string_length(edit_buffer));

    if(keyboard_check(vk_control)&&keyboard_check_pressed(ord("V"))){
        var pasted_text=clipboard_get_text();
        keyboard_string="";
        edit_seen="";
        edit_anchor=edit_caret;
        if(string_length(pasted_text)>0){
            edit_buffer=string_insert(pasted_text,edit_buffer,edit_caret+1);
            edit_caret+=string_length(pasted_text);
        }
        edit_anchor=edit_caret;
    }

    var keyboard_now=TextTyper_NormalizeSupplementaryUnicode(keyboard_string);
    var keyboard_changed=keyboard_now!=edit_seen;
    if(keyboard_changed){
        var old_input_length=string_length(edit_seen);
        edit_anchor=clamp(edit_anchor,0,string_length(edit_buffer));
        if(old_input_length>0) edit_buffer=string_delete(edit_buffer,edit_anchor+1,old_input_length);
        if(string_length(keyboard_now)>0) edit_buffer=string_insert(keyboard_now,edit_buffer,edit_anchor+1);
        edit_caret=edit_anchor+string_length(keyboard_now);
        edit_seen=keyboard_now;
    }

    var move_left=keyboard_check_pressed(vk_left);
    var move_right=keyboard_check_pressed(vk_right);
    var move_home=keyboard_check_pressed(vk_home);
    var move_end=keyboard_check_pressed(vk_end);
    if(move_left||move_right||move_home||move_end){
        keyboard_string="";
        edit_seen="";
        if(move_left) edit_caret=max(0,edit_caret-1);
        if(move_right) edit_caret=min(string_length(edit_buffer),edit_caret+1);
        if(move_home) edit_caret=0;
        if(move_end) edit_caret=string_length(edit_buffer);
        edit_anchor=edit_caret;
    }
    if(keyboard_check_pressed(vk_backspace)&&!keyboard_changed&&edit_caret>0){
        edit_buffer=string_delete(edit_buffer,edit_caret,1);
        edit_caret-=1;
        keyboard_string="";
        edit_seen="";
        edit_anchor=edit_caret;
    }
    if(keyboard_check_pressed(vk_delete)&&edit_caret<string_length(edit_buffer)){
        edit_buffer=string_delete(edit_buffer,edit_caret+1,1);
        keyboard_string="";
        edit_seen="";
        edit_anchor=edit_caret;
    }
    return {buffer:edit_buffer,caret:edit_caret,keyboard_seen:edit_seen,keyboard_anchor:edit_anchor};
}

function BattleEditor_SingleLineLayout(value,caret,available_width) {
    var source=string(value);
    var source_length=string_length(source);
    var visible_start=1;
    var visible_end=source_length;
    var visible_caret=clamp(round(caret),0,source_length);
    var visible_text=source;
    while(TextTyper_StringWidthFallback(visible_text)>max(1,available_width)&&visible_end>=visible_start){
        var hidden_left=max(0,visible_caret-visible_start+1);
        var hidden_right=max(0,visible_end-visible_caret);
        if(hidden_left>hidden_right) visible_start+=1;
        else visible_end-=1;
        visible_text=visible_end>=visible_start?string_copy(source,visible_start,visible_end-visible_start+1):"";
    }
    return {text:visible_text,start:visible_start,last:visible_end,caret:visible_caret};
}

function BattleEditor_SingleLineCaretFromPoint(value,current_caret,available_width,point_x,text_x) {
    var source=string(value);
    var caret_layout_data=BattleEditor_SingleLineLayout(source,current_caret,available_width);
    var visible_fragment=caret_layout_data.text;
    if(string_length(visible_fragment)<=0) return clamp(caret_layout_data.start-1,0,string_length(source));
    var local_x=point_x-text_x;
    var previous_width=0;
    for(var i=1;i<=string_length(visible_fragment);i++){
        var next_width=TextTyper_StringWidthFallback(string_copy(visible_fragment,1,i));
        if(local_x<(previous_width+next_width)*0.5) return clamp(caret_layout_data.start+i-2,0,string_length(source));
        previous_width=next_width;
    }
    return clamp(caret_layout_data.start+string_length(visible_fragment)-1,0,string_length(source));
}

function BattleEditor_TextCaretPosition(text,caret,x,y,line_height,max_width) {
    var source=string(text);
    var target=clamp(round(caret),0,string_length(source));
    var cursor_x=x;
    var cursor_y=y;
    for(var i=1;i<=target;i++){
        var ch=string_char_at(source,i);
        if(ch=="\r") continue;
        if(ch=="\n"){cursor_x=x;cursor_y+=line_height;continue;}
        var char_width=TextTyper_StringWidthFallback(ch);
        if(cursor_x>x&&cursor_x-x+char_width>max_width){cursor_x=x;cursor_y+=line_height;}
        cursor_x+=char_width;
    }
    return [cursor_x,cursor_y];
}

function BattleEditor_TextCaretFromPoint(text,px,py,x,y,line_height,max_width) {
    var source=string(text);
    var best_index=0;
    var best_distance=999999;
    for(var caret=0;caret<=string_length(source);caret++){
        var position=BattleEditor_TextCaretPosition(source,caret,x,y,line_height,max_width);
        var vertical=abs(py-position[1]);
        // Choose the visual row first, then the nearest glyph boundary on
        // that row.  A small vertical multiplier let a far-right click jump
        // to the last line merely because its X happened to be closer.
        var distance=vertical*10000+abs(px-position[0]);
        if(distance<best_distance){best_distance=distance;best_index=caret;}
    }
    return best_index;
}

function BattleEditor_DrawEditableText(text,x,y,line_height,max_width) {
    var source=string(text);
    var cursor_x=x;
    var cursor_y=y;
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch=="\r") continue;
        if(ch=="\n"){cursor_x=x;cursor_y+=line_height;continue;}
        var visible_ch=ch=="&"?"#":ch;
        var char_width=TextTyper_StringWidthFallback(visible_ch);
        if(cursor_x>x&&cursor_x-x+char_width>max_width){cursor_x=x;cursor_y+=line_height;}
        TextTyper_DrawFallback(cursor_x,cursor_y,visible_ch);
        cursor_x+=char_width;
    }
}

function BattleEditor_HexNibble(ch) {
    return string_pos(string_upper(ch),"0123456789ABCDEF")-1;
}

function BattleEditor_ParseHexColor(value) {
    var source=string_upper(string(value));
    if(string_char_at(source,1)=="#") source=string_delete(source,1,1);
    if(string_length(source)!=6&&string_length(source)!=8) return undefined;
    for(var i=1;i<=string_length(source);i++) if(BattleEditor_HexNibble(string_char_at(source,i))<0) return undefined;
    var r=BattleEditor_HexNibble(string_char_at(source,1))*16+BattleEditor_HexNibble(string_char_at(source,2));
    var g=BattleEditor_HexNibble(string_char_at(source,3))*16+BattleEditor_HexNibble(string_char_at(source,4));
    var b=BattleEditor_HexNibble(string_char_at(source,5))*16+BattleEditor_HexNibble(string_char_at(source,6));
    var a=255;
    if(string_length(source)==8) a=BattleEditor_HexNibble(string_char_at(source,7))*16+BattleEditor_HexNibble(string_char_at(source,8));
    return {color:make_color_rgb(r,g,b),alpha:a/255};
}

function BattleEditor_HexByte(value) {
    var digits="0123456789ABCDEF";
    var byte=clamp(round(value),0,255);
    return string_char_at(digits,(byte div 16)+1)+string_char_at(digits,(byte mod 16)+1);
}

function BattleEditor_ColorToHex(color,alpha=255) {
    return "#"+BattleEditor_HexByte(color_get_red(color))+BattleEditor_HexByte(color_get_green(color))+BattleEditor_HexByte(color_get_blue(color))+BattleEditor_HexByte(alpha);
}

function BattleEditor_OpenColorPicker(controller,target,color,alpha=1) {
    controller.color_picker_open=true;
    controller.color_picker_target=target;
    controller.color_picker_hue=color_get_hue(color);
    controller.color_picker_saturation=color_get_saturation(color);
    controller.color_picker_value=color_get_value(color);
    controller.color_picker_alpha=clamp(round(alpha*255),0,255);
    controller.text_editor_hex=BattleEditor_ColorToHex(color,controller.color_picker_alpha);
    controller.focus_field="";
    keyboard_string="";
}

/// Converts the editor's readable XML-like markup into the commands already
/// understood by text_typer. The source text remains readable in JSON.
function BattleEditor_CompileTextMarkup(source) {
    return TextTyper_CompileMarkup(source);
    /* Legacy copy retained below only for old-project source compatibility;
       the public TextTyper API above is now authoritative. */
    source=string(source);
    var output="";
    var error="";
    var error_index=-1;
    var tags=[];
    var tag_closes=[];
    var cursor=1;
    while(cursor<=string_length(source)){
        var ch=string_char_at(source,cursor);
        if(ch=="\r"){cursor+=1;continue;}
        if(ch=="\n"){output+="&";cursor+=1;continue;}
        if(ch!="<"){output+=ch;cursor+=1;continue;}
        var close_at=cursor+1;
        while(close_at<=string_length(source)&&string_char_at(source,close_at)!=">") close_at+=1;
        if(close_at>string_length(source)){error="标签缺少 >";error_index=cursor;break;}
        var raw=string_copy(source,cursor+1,close_at-cursor-1);
        var tag=string_lower(string_trim(raw));
        var command="";
        var close_command="";
        var tag_name="";
        var self_closing=false;
        if(tag=="br"){
            command="&";self_closing=true;
        }else if(string_pos("wait=",tag)==1){
            var wait_text=string_copy(tag,6,string_length(tag)-5);
            if(!BattleEditor_IsNumberText(wait_text)||real(wait_text)<0){error="wait 必须是非负秒数";error_index=cursor;break;}
            command="{sleep "+string(real(wait_text)*room_speed)+"}";self_closing=true;
        }else if(string_pos("color=",tag)==1){
            var color_text=string_copy(raw,7,string_length(raw)-6);
            var parsed_color=BattleEditor_ParseHexColor(color_text);
            if(is_undefined(parsed_color)){error="color 必须是 #RRGGBB 或 #RRGGBBAA";error_index=cursor;break;}
            command="{color_text "+string(parsed_color.color)+"}{alpha "+string(parsed_color.alpha)+"}";
            close_command="{color_text "+string(c_white)+"}{alpha 1}";tag_name="color";
        }else if(string_pos("gradient=",tag)==1){
            var gradient_text=string_copy(raw,10,string_length(raw)-9);
            var comma=string_pos(",",gradient_text);
            if(comma<=0){error="gradient 需要两个 Hex 颜色";error_index=cursor;break;}
            var color_a=BattleEditor_ParseHexColor(string_copy(gradient_text,1,comma-1));
            var color_b=BattleEditor_ParseHexColor(string_copy(gradient_text,comma+1,string_length(gradient_text)-comma));
            if(is_undefined(color_a)||is_undefined(color_b)){error="gradient 颜色必须是有效 Hex";error_index=cursor;break;}
            command="{color_text "+string(color_a.color)+" "+string(color_b.color)+" "+string(color_a.color)+" "+string(color_b.color)+"}";
            close_command="{color_text "+string(c_white)+"}";tag_name="gradient";
        }else if(tag=="shake"){
            command="{effect 0}";close_command="{effect -1}";tag_name="shake";
        }else if(tag=="glitch"){
            command="{effect 1}";close_command="{effect -1}";tag_name="glitch";
        }else if(tag=="float"){
            command="{effect 2}";close_command="{effect -1}";tag_name="float";
        }else if(tag=="cycle"){
            command="{color `rainbow`}";close_command="{color `white`}";tag_name="cycle";
        }else if(string_pos("rotate=",tag)==1){
            var angle_text=string_copy(tag,8,string_length(tag)-7);
            if(!BattleEditor_IsNumberText(angle_text)){error="rotate 必须是角度数字";error_index=cursor;break;}
            command="{angle "+angle_text+"}";close_command="{angle 0}";tag_name="rotate";
        }else if(string_pos("/",tag)==1){
            var closing_name=string_copy(tag,2,string_length(tag)-1);
            if(array_length(tags)<=0||tags[array_length(tags)-1]!=closing_name){error="结束标签不匹配："+raw;error_index=cursor;break;}
            command=tag_closes[array_length(tag_closes)-1];
            array_delete(tags,array_length(tags)-1,1);
            array_delete(tag_closes,array_length(tag_closes)-1,1);
            self_closing=true;
        }else{
            error="未知标签："+raw;error_index=cursor;break;
        }
        output+=command;
        if(!self_closing){array_push(tags,tag_name);array_push(tag_closes,close_command);}
        cursor=close_at+1;
    }
    if(error==""&&array_length(tags)>0){error="缺少结束标签：</"+tags[array_length(tags)-1]+">";error_index=string_length(source)+1;}
    return {text:output,error:error,error_index:error_index};
}

function BattleEditor_TextMarkupPlain(source) {
    return TextTyper_MarkupPlain(source);
    /* Legacy copy retained below only for old-project source compatibility. */
    var result="";
    var inside=false;
    source=string(source);
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch=="<"){inside=true;continue;}
        if(ch==">"){inside=false;continue;}
        if(!inside) result+=ch;
    }
    result=string_replace_all(result,"&","#");
    return result;
}

function BattleEditor_TweenName(tween) {
    switch(tween){
        case ANIM_TWEEN.LINEAR:return "线性";
        case ANIM_TWEEN.SINE:return "正弦";
        case ANIM_TWEEN.QUAD:return "二次";
        case ANIM_TWEEN.CUBIC:return "三次";
        case ANIM_TWEEN.QUART:return "四次";
        case ANIM_TWEEN.QUINT:return "五次";
        case ANIM_TWEEN.EXPO:return "指数";
        case ANIM_TWEEN.CIRC:return "圆弧";
        case ANIM_TWEEN.BACK:return "回退";
        case ANIM_TWEEN.ELASTIC:return "弹性";
        case ANIM_TWEEN.BOUNCE:return "弹跳";
    }
    return "线性";
}

function BattleEditor_EaseName(ease) {
    if(ease==ANIM_EASE.IN) return "渐入";
    if(ease==ANIM_EASE.OUT) return "渐出";
    return "渐入渐出";
}

function BattleEditor_CycleTween(tween,direction=1) {
    tween+=sign(direction);
    if(tween>ANIM_TWEEN.BOUNCE) tween=ANIM_TWEEN.LINEAR;
    if(tween<ANIM_TWEEN.LINEAR) tween=ANIM_TWEEN.BOUNCE;
    return tween;
}

function BattleEditor_CycleEase(ease,direction=1) {
    ease+=sign(direction);
    if(ease>ANIM_EASE.IN_OUT) ease=ANIM_EASE.IN;
    if(ease<ANIM_EASE.IN) ease=ANIM_EASE.IN_OUT;
    return ease;
}

function BattleEditor_ResolveGBSpawn(event_data, initialization) {
    var global_spawn=initialization.gb_spawn_default;
    var preset=event_data.spawn_preset;
    var spawn_x=event_data.spawn_x;
    var spawn_y=event_data.spawn_y;
    var spawn_angle=event_data.angle_start;
    // All directional presets use one radial distance: the complete 640x480
    // battle-screen diagonal. This keeps cardinal and diagonal presets equally
    // far away and guarantees every preset spawn is outside the visible screen.
    var distance=point_distance(0,0,640,480);
    if(preset==BATTLE_EDITOR_GB_SPAWN.INHERIT){
        preset=global_spawn.preset;
        spawn_x=global_spawn.x;
        spawn_y=global_spawn.y;
        spawn_angle=global_spawn.angle;
        distance=point_distance(0,0,640,480);
    }

    var tx=event_data.target_x;
    var ty=event_data.target_y;
    switch(preset){
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_CENTER: spawn_x=320;spawn_y=240;break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP: spawn_x=320+lengthdir_x(distance,90);spawn_y=240+lengthdir_y(distance,90);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP_RIGHT: spawn_x=320+lengthdir_x(distance,45);spawn_y=240+lengthdir_y(distance,45);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_RIGHT: spawn_x=320+lengthdir_x(distance,0);spawn_y=240+lengthdir_y(distance,0);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM_RIGHT: spawn_x=320+lengthdir_x(distance,315);spawn_y=240+lengthdir_y(distance,315);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM: spawn_x=320+lengthdir_x(distance,270);spawn_y=240+lengthdir_y(distance,270);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_BOTTOM_LEFT: spawn_x=320+lengthdir_x(distance,225);spawn_y=240+lengthdir_y(distance,225);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_LEFT: spawn_x=320+lengthdir_x(distance,180);spawn_y=240+lengthdir_y(distance,180);break;
        case BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP_LEFT: spawn_x=320+lengthdir_x(distance,135);spawn_y=240+lengthdir_y(distance,135);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP: spawn_x=tx+lengthdir_x(distance,90);spawn_y=ty+lengthdir_y(distance,90);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP_RIGHT: spawn_x=tx+lengthdir_x(distance,45);spawn_y=ty+lengthdir_y(distance,45);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_RIGHT: spawn_x=tx+lengthdir_x(distance,0);spawn_y=ty+lengthdir_y(distance,0);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM_RIGHT: spawn_x=tx+lengthdir_x(distance,315);spawn_y=ty+lengthdir_y(distance,315);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM: spawn_x=tx+lengthdir_x(distance,270);spawn_y=ty+lengthdir_y(distance,270);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_BOTTOM_LEFT: spawn_x=tx+lengthdir_x(distance,225);spawn_y=ty+lengthdir_y(distance,225);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_LEFT: spawn_x=tx+lengthdir_x(distance,180);spawn_y=ty+lengthdir_y(distance,180);break;
        case BATTLE_EDITOR_GB_SPAWN.TARGET_TOP_LEFT: spawn_x=tx+lengthdir_x(distance,135);spawn_y=ty+lengthdir_y(distance,135);break;
    }
    return [spawn_x,spawn_y,spawn_angle];
}

function BattleEditor_SetInputCapture(enabled) {
    if(!variable_global_exists("_gmu_input_state_override")) return false;
    if(!ds_exists(global._gmu_input_state_override,ds_type_map)) return false;
    var inputs=[INPUT.CONFIRM,INPUT.CANCEL,INPUT.MENU,INPUT.UP,INPUT.DOWN,INPUT.LEFT,INPUT.RIGHT];
    for(var i=0;i<array_length(inputs);i++){
        if(enabled) Input_SetStateOverride(inputs[i],INPUT_STATE.NULL);
        else Input_RemoveStateOverride(inputs[i]);
    }
    return true;
}

function BattleEditor_NewTransformTrack(x,y) {
    return {
        x:x, y:y,
        scale_x:1, scale_y:1,
        angle:0,
        alpha:1,
        color:c_white,
        tween:ANIM_TWEEN.SINE,
        ease:ANIM_EASE.IN_OUT
    };
}

function BattleEditor_NewAnimation() {
    return {
        frames: [],
        frame_count: 1,
        fps: 8,
        loop: true
    };
}

function BattleEditor_BundledGBFramePath(frame_index) {
    return BattleEditor_PathJoin(working_directory,"editor_gb_defaults/spr_gb_"+string(clamp(round(frame_index),0,3))+".png");
}

function BattleEditor_BundledGBHeadPath(frame_index) {
    return BattleEditor_PathJoin(working_directory,"editor_gb_defaults/spr_gasterblaster_"+string(clamp(round(frame_index),0,5))+".png");
}

function BattleEditor_BundledGBBeamPath(variant_index) {
    var names=["white","orange","blue"];
    return BattleEditor_PathJoin(working_directory,"editor_gb_defaults/spr_gb_beam_"+names[clamp(round(variant_index),0,2)]+".png");
}

/// The immutable built-in template and every newly named GB use the six
/// detailed head frames from the bundled attack material. The user can then
/// replace, add, remove or reorder frames without changing the built-in copy.
function BattleEditor_NewGBAnimation() {
    return {
        frames:[
            BattleEditor_BundledGBHeadPath(0),
            BattleEditor_BundledGBHeadPath(1),
            BattleEditor_BundledGBHeadPath(2),
            BattleEditor_BundledGBHeadPath(3),
            BattleEditor_BundledGBHeadPath(4),
            BattleEditor_BundledGBHeadPath(5)
        ],
        frame_interval:2
    };
}

function BattleEditor_NewGBBeamVariant(variant_index) {
    return {
        animation:{frames:[BattleEditor_BundledGBBeamPath(variant_index)],frame_interval:2}
    };
}

function BattleEditor_NewGBBeam() {
    return {
        variants:[
            BattleEditor_NewGBBeamVariant(0),
            BattleEditor_NewGBBeamVariant(1),
            BattleEditor_NewGBBeamVariant(2)
        ],
        // The bundled Undertale beam art points down. Runtime rotation maps
        // that source direction to the attack's semantic firing angle.
        source_direction:270,
        source_offset:20,
        base_scale:1.8,
        launch_ratio:0.20,
        breath_ratio:0.32,
        hit_inset:4
    };
}

function BattleEditor_SetGBBeamSpriteOffset(sprite,source_direction) {
    if(!sprite_exists(sprite)) return;
    var source_facing=((round(real(source_direction)/90)*90) mod 360+360) mod 360;
    if(source_facing==0) sprite_set_offset(sprite,0,round(sprite_get_height(sprite)*0.5));
    else if(source_facing==90) sprite_set_offset(sprite,round(sprite_get_width(sprite)*0.5),sprite_get_height(sprite));
    else if(source_facing==180) sprite_set_offset(sprite,sprite_get_width(sprite),round(sprite_get_height(sprite)*0.5));
    else sprite_set_offset(sprite,round(sprite_get_width(sprite)*0.5),0);
}

function BattleEditor_NewGBStyle(project,name="自定义 GB") {
    return {
        uid:BattleEditor_AllocateUid(project),
        name:name,
        animation:BattleEditor_NewGBAnimation(),
        // The editable six-frame Undertale source art points down. This is a
        // property of the artwork, not the attack direction selected later.
        source_direction:270,
        origin_x:21,
        origin_y:28,
        beam:BattleEditor_NewGBBeam()
    };
}

/// -1 remains the stable public ID for the immutable built-in GB. Keeping its
/// complete definition here lets editor preview and editor runtime use the
/// same six-frame artwork without serialising a fake user-created style.
function BattleEditor_BuiltinGBStyle() {
    static style={
        uid:-1,
        name:"内置默认 GB",
        animation:BattleEditor_NewGBAnimation(),
        source_direction:270,
        origin_x:21,
        origin_y:28,
        beam:BattleEditor_NewGBBeam()
    };
    return style;
}

function BattleEditor_FindGBStyle(project,style_uid) {
    if(real(style_uid)<0||!is_struct(project)||!struct_exists(project,"resources")||!struct_exists(project.resources,"gb_styles")) return undefined;
    for(var i=0;i<array_length(project.resources.gb_styles);i++) if(project.resources.gb_styles[i].uid==style_uid) return project.resources.gb_styles[i];
    return undefined;
}

function BattleEditor_GBStyleDefinition(project,style_uid) {
    if(real(style_uid)<0) return BattleEditor_BuiltinGBStyle();
    return BattleEditor_FindGBStyle(project,style_uid);
}

function BattleEditor_GBStyleCaption(project,style_uid) {
    if(real(style_uid)<0) return "内置默认 GB";
    var style=BattleEditor_FindGBStyle(project,style_uid);
    return is_undefined(style)?"原版 GB（原组已删除）":style.name;
}

function BattleEditor_UniqueGBStyleName(project,base_name="自定义 GB",except_uid=-1) {
    var base=string_trim(string(base_name));if(base=="") base="自定义 GB";
    var candidate=base,suffix=2,used=true;
    while(used){
        used=false;
        for(var i=0;i<array_length(project.resources.gb_styles);i++){
            var style=project.resources.gb_styles[i];
            if(style.uid!=except_uid&&style.name==candidate){used=true;break;}
        }
        if(used){candidate=base+" "+string(suffix);suffix+=1;}
    }
    return candidate;
}

function BattleEditor_RemoveGBStyleReferences(project,style_uid) {
    for(var gb_event_i=0;gb_event_i<array_length(project.events);gb_event_i++){
        var gb_event_data=project.events[gb_event_i];
        if(gb_event_data.preset=="gb"&&gb_event_data.gb_style_uid==style_uid) gb_event_data.gb_style_uid=-1;
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var steps=project.script_lists[list_index].steps;
        for(var step_index=0;step_index<array_length(steps);step_index++){
            var step=steps[step_index];
            if(step.kind=="create_object"&&struct_exists(step,"create_template")&&is_struct(step.create_template)&&step.create_template.preset=="gb"&&step.create_template.gb_style_uid==style_uid) step.create_template.gb_style_uid=-1;
        }
    }
}

function BattleEditor_ApplyGBStyle(gb,style,controller=undefined) {
    if(!instance_exists(gb)||is_undefined(style)||!is_struct(style)||!is_struct(style.animation)) return false;
    var use_shared_cache=!is_undefined(controller)&&instance_exists(controller)&&variable_instance_exists(controller,"project")&&struct_exists(style,"uid");
    var loaded=use_shared_cache
        ?{sprite:BattleEditor_GBStylePreviewSprite(controller,controller.project,style.uid),owns:false}
        :BattleEditor_LoadAnimationSprite("",style.animation,false);
    if(!sprite_exists(loaded.sprite)) return false;
    gb.sprite_index=loaded.sprite;
    gb.editor_gb_owned_sprite=loaded.owns;
    gb.editor_gb_frame_interval=max(1,round(real(style.animation.frame_interval)));
    gb.editor_sprite_angle_offset=-real(style.source_direction);
    if(loaded.owns) sprite_set_offset(loaded.sprite,round(real(style.origin_x)),round(real(style.origin_y)));
    var beam_variant_number=0;
    if(gb.type==2) beam_variant_number=1;
    else if(gb.type==1||gb.type==8) beam_variant_number=2;
    var beam_variant=style.beam.variants[beam_variant_number];
    var beam_loaded=use_shared_cache
        ?{sprite:BattleEditor_GBStylePreviewBeamSprite(controller,controller.project,style.uid,beam_variant_number),owns:false}
        :BattleEditor_LoadAnimationSprite("",beam_variant.animation,false);
    if(sprite_exists(beam_loaded.sprite)){
        if(beam_loaded.owns) BattleEditor_SetGBBeamSpriteOffset(beam_loaded.sprite,style.beam.source_direction);
        gb.editor_gb_beam_sprite=beam_loaded.sprite;
        gb.editor_gb_owned_beam_sprite=beam_loaded.owns;
        gb.editor_gb_beam_frame_interval=max(1,round(real(beam_variant.animation.frame_interval)));
        gb.editor_gb_beam_uses_own_color=beam_variant_number>0;
        gb.editor_gb_beam_source_direction=real(style.beam.source_direction);
        gb.editor_gb_beam_source_offset=max(0,real(style.beam.source_offset));
        gb._beam_scale_default=max(0.01,real(style.beam.base_scale));
        gb.beam_visual_launch_scale=gb._beam_scale_default*max(0,real(style.beam.launch_ratio));
        gb.beam_visual_breath_amplitude=gb._beam_scale_default*max(0,real(style.beam.breath_ratio));
        gb.beam_hit_inset=max(0,real(style.beam.hit_inset));
    }
    gb.image_index=0;
    return true;
}

function BattleEditor_FreeGBStyleSpriteCache(cache) {
    if(!is_array(cache)) return;
    for(var i=0;i<array_length(cache);i++) if(is_struct(cache[i])&&cache[i].owns&&sprite_exists(cache[i].sprite)) sprite_delete(cache[i].sprite);
}

/// Full-animation cache shared by scene preview, hit testing and the GB resource
/// subpage. It reloads only when that named group's serialized data changes.
function BattleEditor_GBStylePreviewSprite(controller,project,style_uid) {
    var style=BattleEditor_GBStyleDefinition(project,style_uid);
    if(is_undefined(style)||!instance_exists(controller)) return spr_gb;
    if(!variable_instance_exists(controller,"gb_style_sprite_cache")) controller.gb_style_sprite_cache=[];
    var signature=json_stringify(style.animation)+"|"+string(style.origin_x)+"|"+string(style.origin_y);
    for(var i=0;i<array_length(controller.gb_style_sprite_cache);i++){
        var cached=controller.gb_style_sprite_cache[i];
        if(cached.uid!=style_uid) continue;
        if(cached.signature==signature&&sprite_exists(cached.sprite)) return cached.sprite;
        if(cached.owns&&sprite_exists(cached.sprite)) sprite_delete(cached.sprite);
        var refreshed=BattleEditor_LoadAnimationSprite("",style.animation,false);
        cached.signature=signature;cached.sprite=sprite_exists(refreshed.sprite)?refreshed.sprite:spr_gb;cached.owns=refreshed.owns;
        if(refreshed.owns) sprite_set_offset(cached.sprite,round(real(style.origin_x)),round(real(style.origin_y)));
        return cached.sprite;
    }
    var loaded=BattleEditor_LoadAnimationSprite("",style.animation,false);
    var sprite=sprite_exists(loaded.sprite)?loaded.sprite:spr_gb;
    if(loaded.owns) sprite_set_offset(sprite,round(real(style.origin_x)),round(real(style.origin_y)));
    array_push(controller.gb_style_sprite_cache,{uid:style_uid,signature:signature,sprite:sprite,owns:loaded.owns});
    return sprite;
}

function BattleEditor_GBStylePreviewBeamSprite(controller,project,style_uid,variant_index=0) {
    var style=BattleEditor_GBStyleDefinition(project,style_uid);
    if(is_undefined(style)||!instance_exists(controller)) return spr_gb_beam;
    if(!variable_instance_exists(controller,"gb_style_beam_sprite_cache")) controller.gb_style_beam_sprite_cache=[];
    variant_index=clamp(round(variant_index),0,2);
    var variant=style.beam.variants[variant_index];
    var signature=json_stringify(variant.animation)+"|"+string(style.beam.source_direction);
    for(var i=0;i<array_length(controller.gb_style_beam_sprite_cache);i++){
        var cached=controller.gb_style_beam_sprite_cache[i];
        if(cached.uid!=style_uid||cached.variant!=variant_index) continue;
        if(cached.signature==signature&&sprite_exists(cached.sprite)) return cached.sprite;
        if(cached.owns&&sprite_exists(cached.sprite)) sprite_delete(cached.sprite);
        var refreshed=BattleEditor_LoadAnimationSprite("",variant.animation,false);
        cached.signature=signature;cached.sprite=sprite_exists(refreshed.sprite)?refreshed.sprite:spr_gb_beam;cached.owns=refreshed.owns;
        if(refreshed.owns) BattleEditor_SetGBBeamSpriteOffset(cached.sprite,style.beam.source_direction);
        return cached.sprite;
    }
    var loaded=BattleEditor_LoadAnimationSprite("",variant.animation,false);
    var sprite=sprite_exists(loaded.sprite)?loaded.sprite:spr_gb_beam;
    if(loaded.owns) BattleEditor_SetGBBeamSpriteOffset(sprite,style.beam.source_direction);
    array_push(controller.gb_style_beam_sprite_cache,{uid:style_uid,variant:variant_index,signature:signature,sprite:sprite,owns:loaded.owns});
    return sprite;
}

// Every damaging sprite hazard uses the visible, non-transparent pixels as
// its collision shape. Packaged assets are prepared once and then reused;
// dynamically loaded sprites are prepared on creation because their indexes
// may later be deleted and recycled by GameMaker.
function BattleEditor_EnsurePreciseHazardMask(sprite, persistent_asset=false) {
    if(!sprite_exists(sprite)) return false;
    static prepared_assets=[];
    if(persistent_asset){
        for(var i=0;i<array_length(prepared_assets);i++){
            if(prepared_assets[i]==sprite) return true;
        }
    }
    sprite_collision_mask(
        sprite,
        true,
        bboxmode_automatic,
        0,0,0,0,
        bboxkind_precise,
        1
    );
    if(persistent_asset) array_push(prepared_assets,sprite);
    return true;
}

// Compiled sprite assets keep their original collision data even when
// sprite_collision_mask() is called on them in the Windows VM runner. Cache
// one dynamic duplicate per source asset so every instance receives a real
// alpha mask without duplicating a sprite for every attack or timeline seek.
function BattleEditor_PreciseHazardResourceSprite(resource_sprite) {
    if(!sprite_exists(resource_sprite)) return -1;
    static source_sprites=[];
    static precise_sprites=[];
    for(var i=0;i<array_length(source_sprites);i++){
        if(source_sprites[i]==resource_sprite&&sprite_exists(precise_sprites[i])) return precise_sprites[i];
    }
    var precise_sprite=sprite_duplicate(resource_sprite);
    if(!sprite_exists(precise_sprite)) return resource_sprite;
    BattleEditor_EnsurePreciseHazardMask(precise_sprite,false);
    array_push(source_sprites,resource_sprite);
    array_push(precise_sprites,precise_sprite);
    return precise_sprite;
}

function BattleEditor_TrimOwnedSprite(sprite) {
    var result={sprite:sprite,trim_x:0,trim_y:0};
    if(!sprite_exists(sprite)) return result;
    var source_width=sprite_get_width(sprite),source_height=sprite_get_height(sprite);
    if(source_width<=1||source_height<=1) return result;
    // Imported enemy cutouts often retain a large shared animation canvas.
    // Preserve the authored origin but stop drawing/uploading transparent
    // 960x840 margins for every body part on every frame.
    sprite_collision_mask(sprite,false,bboxmode_automatic,0,0,0,0,bboxkind_rectangular,1);
    var crop_left=clamp(floor(sprite_get_bbox_left(sprite)),0,source_width-1);
    var crop_top=clamp(floor(sprite_get_bbox_top(sprite)),0,source_height-1);
    var crop_right=clamp(ceil(sprite_get_bbox_right(sprite)),crop_left,source_width-1);
    var crop_bottom=clamp(ceil(sprite_get_bbox_bottom(sprite)),crop_top,source_height-1);
    var crop_width=crop_right-crop_left+1,crop_height=crop_bottom-crop_top+1;
    if(crop_width>=source_width&&crop_height>=source_height) return result;
    var crop_surface=surface_create(crop_width,crop_height);
    if(!surface_exists(crop_surface)) return result;
    var trimmed=-1;
    var source_frames=max(1,sprite_get_number(sprite));
    for(var frame_index=0;frame_index<source_frames;frame_index++){
        surface_set_target(crop_surface);
        draw_clear_alpha(c_black,0);
        draw_set_color(c_white);draw_set_alpha(1);
        draw_sprite(sprite,frame_index,-crop_left,-crop_top);
        surface_reset_target();
        var frame_sprite=sprite_create_from_surface(crop_surface,0,0,crop_width,crop_height,false,false,0,0);
        if(!sprite_exists(frame_sprite)) continue;
        if(!sprite_exists(trimmed)) trimmed=frame_sprite;
        else{sprite_merge(trimmed,frame_sprite);sprite_delete(frame_sprite);}
    }
    surface_free(crop_surface);
    draw_set_color(c_white);draw_set_alpha(1);
    if(sprite_exists(trimmed)){
        sprite_delete(sprite);
        result.sprite=trimmed;
        result.trim_x=crop_left;
        result.trim_y=crop_top;
    }
    return result;
}

// 自定义对象既可读取一张横向 sprite strip，也可逐帧加入独立图片。
// 返回的 owns 字段用于保证运行时只删除动态加载的 sprite，不碰工程资源。
function BattleEditor_LoadAnimationSprite(sprite_source, animation, precise_collision=false, trim_transparent=false) {
    var result = {sprite:-1, owns:false, trim_x:0, trim_y:0};
    if (is_struct(animation) && struct_exists(animation,"frames") && is_array(animation.frames) && array_length(animation.frames)>0) {
        var merged=-1;
        for(var i=0;i<array_length(animation.frames);i++){
            var frame_path=animation.frames[i];
            if(string_length(frame_path)<=0||!file_exists(frame_path)) continue;
            var frame_sprite=sprite_add(frame_path,1,false,false,0,0);
            if(!sprite_exists(frame_sprite)) continue;
            if(!sprite_exists(merged)) merged=frame_sprite;
            else{
                sprite_merge(merged,frame_sprite);
                sprite_delete(frame_sprite);
            }
        }
        if(sprite_exists(merged)){
            if(trim_transparent){
                var trimmed_merged=BattleEditor_TrimOwnedSprite(merged);
                merged=trimmed_merged.sprite;
                result.trim_x=trimmed_merged.trim_x;
                result.trim_y=trimmed_merged.trim_y;
            }
            if(precise_collision) BattleEditor_EnsurePreciseHazardMask(merged,false);
            result.sprite=merged;
            result.owns=true;
            return result;
        }
    }

    var resource_sprite=asset_get_index(sprite_source);
    if(sprite_exists(resource_sprite)){
        result.sprite=precise_collision?BattleEditor_PreciseHazardResourceSprite(resource_sprite):resource_sprite;
        return result;
    }
    if(file_exists(sprite_source)){
        result.sprite=sprite_add(sprite_source,max(1,animation.frame_count),false,false,0,0);
        result.owns=sprite_exists(result.sprite);
        if(result.owns&&trim_transparent){
            var trimmed_source=BattleEditor_TrimOwnedSprite(result.sprite);
            result.sprite=trimmed_source.sprite;
            result.trim_x=trimmed_source.trim_x;
            result.trim_y=trimmed_source.trim_y;
        }
        if(result.owns&&precise_collision) BattleEditor_EnsurePreciseHazardMask(result.sprite,false);
    }
    return result;
}

function BattleEditor_DefaultItems() {
    return [
        {name:"怪物糖果",heal:20,eat_text:"* 你吃掉了怪物糖果。<br>* 恢复了 20 HP。",voice_id:0,after_use_mode:0},
        {name:"怪物糖果",heal:20,eat_text:"* 你吃掉了怪物糖果。<br>* 恢复了 20 HP。",voice_id:0,after_use_mode:0},
        {name:"方便面",heal:40,eat_text:"* 你吃掉了方便面。<br>* 恢复了 40 HP。",voice_id:0,after_use_mode:0},
        {name:"方便面",heal:40,eat_text:"* 你吃掉了方便面。<br>* 恢复了 40 HP。",voice_id:0,after_use_mode:0},
        {name:"英雄料理",heal:80,eat_text:"* 你吃掉了英雄料理。<br>* 恢复了 80 HP。",voice_id:0,after_use_mode:0},
        {name:"英雄料理",heal:80,eat_text:"* 你吃掉了英雄料理。<br>* 恢复了 80 HP。",voice_id:0,after_use_mode:0},
        {name:"奶油派",heal:128,eat_text:"* 你吃掉了奶油派。<br>* 恢复了 128 HP。",voice_id:0,after_use_mode:0},
        {name:"奶油派",heal:128,eat_text:"* 你吃掉了奶油派。<br>* 恢复了 128 HP。",voice_id:0,after_use_mode:0}
    ];
}

function BattleEditor_VoiceName(voice_id) {
    switch(round(real(voice_id))){
        case -1:return "无声";
        case 0:return "默认文字音";
        case 1:return "打字机音";
        case 2:return "Sans";
        case 3:return "Toriel";
    }
    return "默认文字音";
}

function BattleEditor_VoiceChoiceToId(choice_index) {
    return clamp(round(real(choice_index)),0,4)-1;
}

function BattleEditor_VoiceIdToChoice(voice_id) {
    return clamp(round(real(voice_id))+1,0,4);
}

function BattleEditor_NewEnemyPart(source="",offset_x=0,offset_y=0) {
    return {
        source:source,
        asset_uid:-1,
        offset_x:offset_x,
        offset_y:offset_y,
        origin_x:0,
        origin_y:0,
        deform_with_torso:false,
        deform_sole_offset_y:0,
        animation:BattleEditor_NewAnimation()
    };
}

function BattleEditor_EnemyDirectoryName(value) {
    var result=BattleEditor_SanitizeSaveName(value);
    if(string_length(result)<=0) result="未命名角色";
    return result;
}

function BattleEditor_BundledEnemyResourcePath(character_name,file_name) {
    return BattleEditor_PathJoin(BattleEditor_PathJoin(working_directory,"editor_enemy_defaults/"+BattleEditor_EnemyDirectoryName(character_name)),file_name);
}

function BattleEditor_NewEnemyTextureResource(project,enemy_uid,name,path,part_hint="body",animation=undefined) {
    if(!struct_exists(project,"resources")||!is_struct(project.resources)) project.resources={audio:[],enemy_textures:[]};
    if(!struct_exists(project.resources,"enemy_textures")||!is_array(project.resources.enemy_textures)) project.resources.enemy_textures=[];
    if(is_undefined(animation)) animation=BattleEditor_NewAnimation();
    var resource={uid:BattleEditor_AllocateUid(project),enemy_uid:enemy_uid,name:name,path:path,part_hint:part_hint,animation:animation};
    array_push(project.resources.enemy_textures,resource);
    return resource;
}

function BattleEditor_RegisterBundledSansResources(project,enemy_uid) {
    var result={body_uid:-1,head_uid:-1};
    var body=BattleEditor_NewEnemyTextureResource(project,enemy_uid,"身体 / 默认",BattleEditor_BundledEnemyResourcePath("Sans","spr_sans_bbody_0.png"),"body");
    var head=BattleEditor_NewEnemyTextureResource(project,enemy_uid,"表情 / 默认",BattleEditor_BundledEnemyResourcePath("Sans","spr_sans_bface_0.png"),"head");
    result.body_uid=body.uid;result.head_uid=head.uid;
    for(var face_index=1;face_index<=10;face_index++) BattleEditor_NewEnemyTextureResource(project,enemy_uid,"表情 "+string(face_index),BattleEditor_BundledEnemyResourcePath("Sans","spr_sans_bface_"+string(face_index)+".png"),"head");
    for(var battle_face_index=0;battle_face_index<=14;battle_face_index++) BattleEditor_NewEnemyTextureResource(project,enemy_uid,"表情 / 战斗 "+string(battle_face_index+1),BattleEditor_BundledEnemyResourcePath("Sans","spr_sansb_face_"+string(battle_face_index)+".png"),"head");
    BattleEditor_NewEnemyTextureResource(project,enemy_uid,"腿 / 站立",BattleEditor_BundledEnemyResourcePath("Sans","spr_sansb_legs_0.png"),"legs");
    BattleEditor_NewEnemyTextureResource(project,enemy_uid,"腿 / 坐下",BattleEditor_BundledEnemyResourcePath("Sans","spr_sansb_legs_sit_0.png"),"legs");
    var animation_specs=[
        {name:"身体 / 向下手势",prefix:"spr_sansb_handdown_",count:5,part:"body",fps:12,loop:false},
        {name:"身体 / 向上手势",prefix:"spr_sansb_handup_",count:6,part:"body",fps:12,loop:false},
        {name:"身体 / 右挥击",prefix:"spr_sansb_rightstrike_",count:6,part:"body",fps:12,loop:false},
        {name:"身体 / 躯干动作",prefix:"spr_sansb_torso_",count:8,part:"body",fps:10,loop:true},
        {name:"脸部 / 蓝眼",prefix:"spr_sansb_blueeye_",count:2,part:"face",fps:8,loop:true},
        {name:"脸部 / 汗",prefix:"spr_sansb_face_sweat_",count:3,part:"face",fps:8,loop:true}
    ];
    for(var spec_index=0;spec_index<array_length(animation_specs);spec_index++){
        var spec=animation_specs[spec_index];var frames=[];
        for(var frame_index=0;frame_index<spec.count;frame_index++) array_push(frames,BattleEditor_BundledEnemyResourcePath("Sans",spec.prefix+string(frame_index)+".png"));
        BattleEditor_NewEnemyTextureResource(project,enemy_uid,spec.name,frames[0],spec.part,{frames:frames,frame_count:1,fps:spec.fps,loop:spec.loop});
    }
    return result;
}

function BattleEditor_NewEnemyAction(project,name="查看",text="* 它看起来很普通。") {
    return {uid:BattleEditor_AllocateUid(project),name:name,text:text};
}

function BattleEditor_NewEnemy(project,x=320,y=166,is_default=false) {
    var enemy_uid=BattleEditor_AllocateUid(project);
    var default_resources=is_default?BattleEditor_RegisterBundledSansResources(project,enemy_uid):{body_uid:-1,head_uid:-1};
    var body_part=BattleEditor_NewEnemyPart(is_default?BattleEditor_BundledEnemyResourcePath("Sans","spr_sans_bbody_0.png"):"");
    var head_part=BattleEditor_NewEnemyPart(is_default?BattleEditor_BundledEnemyResourcePath("Sans","spr_sans_bface_0.png"):"");
    body_part.asset_uid=default_resources.body_uid;head_part.asset_uid=default_resources.head_uid;
    // The default body includes the feet.  Keep its lower edge fixed and let
    // only the upper edge follow the idle formula, otherwise the whole Sans
    // sprite visibly slides across the floor instead of swaying in place.
    if(is_default){body_part.deform_with_torso=true;body_part.deform_sole_offset_y=48;}
    var result={
        uid:enemy_uid,name:is_default?"Sans":"敌人",control_id:"enemies",
        x:x,y:y,scale_x:is_default?1.8:1,scale_y:is_default?1.8:1,
        // Sans' original battle body is a 54x48 body plus a 30x28 face.
        // Dynamic images use a top-left origin, so these values place the
        // union around the public enemy centre instead of guessing per Draw.
        rig_offset_x:is_default?-48.6:0,rig_offset_y:is_default?-19.8:0,
        sway_x:"cos(time*3.75)*4",torso_y:"sin(time*7.5)*3",head_y:"sin(time*7.5)*4",
        parts:{
            body:body_part,
            head:head_part,
            face:BattleEditor_NewEnemyPart("",12,-26),
            left_hand:BattleEditor_NewEnemyPart(""),right_hand:BattleEditor_NewEnemyPart(""),
            legs:BattleEditor_NewEnemyPart("")
        },
        actions:[],
        animation_scripts:{gravity_up:"",gravity_down:"",gravity_left:"",gravity_right:""}
    };
    if(is_default){
        // The supplied native-size head sits over the 54x48 body at (12,-26).
        // The default rig is 1.8x; keep that source placement, then lower the
        // head by two world pixels so the jaw meets the smaller body cleanly.
        result.parts.head.offset_x=21.6;result.parts.head.offset_y=-44.8;
        array_push(result.actions,BattleEditor_NewEnemyAction(project,"查看","* SANS 1 ATK 1 DEF&* 最简单的敌人。只能造成 1 点伤害。"));
        array_push(result.actions,BattleEditor_NewEnemyAction(project,"开玩笑","* Sans 没有笑。"));
        array_push(result.actions,BattleEditor_NewEnemyAction(project,"下一回合","* 你准备面对下一轮攻击。"));
    }else array_push(result.actions,BattleEditor_NewEnemyAction(project));
    return result;
}

function BattleEditor_RemapCopiedUid(value,old_values,new_values) {
    for(var remap_index=0;remap_index<array_length(old_values);remap_index++) if(old_values[remap_index]==value) return new_values[remap_index];
    return value;
}

function BattleEditor_CopyEnemyResourceFile(destination_folder,source_path,prefix) {
    var source_file_path=string(source_path);
    if(string_length(source_file_path)<=0||!file_exists(source_file_path)) return source_file_path;
    var destination=BattleEditor_UniqueResourceDestination(destination_folder,source_file_path,prefix);
    return BattleEditor_CopyFileOverwrite(source_file_path,destination)?destination:source_file_path;
}

/// Pick a nearby position where a newly duplicated full-size rig is visibly
/// separate from the authored enemies already on the canvas. This is only the
/// duplicate's initial placement; enemy coordinates remain completely free.
function BattleEditor_DuplicateEnemyPosition(project,source) {
    var source_x=real(source.x),source_y=real(source.y);
    var offsets=[
        [128,0],[-128,0],[0,112],[0,-112],
        [256,0],[-256,0],[128,112],[-128,112],[128,-112],[-128,-112]
    ];
    for(var offset_index=0;offset_index<array_length(offsets);offset_index++){
        var candidate_x=source_x+offsets[offset_index][0];
        var candidate_y=source_y+offsets[offset_index][1];
        var clear=true;
        for(var enemy_index=0;enemy_index<array_length(project.initialization.enemies);enemy_index++){
            var existing_enemy=project.initialization.enemies[enemy_index];
            if(point_distance(candidate_x,candidate_y,real(existing_enemy.x),real(existing_enemy.y))<96){clear=false;break;}
        }
        if(clear) return [candidate_x,candidate_y];
    }
    return [source_x+128,source_y+112];
}

/// Restore one enemy to the bundled Sans rig without importing resource UIDs
/// from a throw-away project. The enemy keeps its stable identity, Control ID
/// and authored world position, while every rebuilt part points at resources
/// that actually belong to the current project.
function BattleEditor_ResetEnemyToDefault(project,enemy_index) {
    if(!is_struct(project)||!struct_exists(project,"initialization")||!is_array(project.initialization.enemies)) return undefined;
    if(enemy_index<0||enemy_index>=array_length(project.initialization.enemies)) return undefined;
    var source=project.initialization.enemies[enemy_index];
    if(!is_struct(source)) return undefined;
    var preserved_uid=source.uid;
    var preserved_control_id=source.control_id;
    var preserved_x=source.x;
    var preserved_y=source.y;

    // Resetting discards this enemy's old resource bindings. Keep resources of
    // every other enemy untouched; files on disk remain available for undo.
    var kept_resources=[];
    for(var resource_index=0;resource_index<array_length(project.resources.enemy_textures);resource_index++){
        var resource=project.resources.enemy_textures[resource_index];
        if(!is_struct(resource)||resource.enemy_uid!=preserved_uid) array_push(kept_resources,resource);
    }
    project.resources.enemy_textures=kept_resources;

    var reset_enemy=BattleEditor_NewEnemy(project,preserved_x,preserved_y,true);
    var generated_uid=reset_enemy.uid;
    for(var new_resource_index=0;new_resource_index<array_length(project.resources.enemy_textures);new_resource_index++){
        var new_resource=project.resources.enemy_textures[new_resource_index];
        if(is_struct(new_resource)&&new_resource.enemy_uid==generated_uid) new_resource.enemy_uid=preserved_uid;
    }
    reset_enemy.uid=preserved_uid;
    reset_enemy.editor_uid=preserved_uid;
    reset_enemy.editor_target_type="enemy";
    reset_enemy.control_id=preserved_control_id;
    reset_enemy.name=BattleEditor_MakeUniqueName(project,"Sans",preserved_uid);
    project.initialization.enemies[enemy_index]=reset_enemy;
    return reset_enemy;
}

/// Duplicate one complete authored enemy while preserving ownership boundaries.
/// Display data is copied, but every identity-bearing enemy/action/resource/list
/// receives a new UID so later edits cannot leak back into the source character.
function BattleEditor_DuplicateEnemy(project,source_index) {
    if(!is_struct(project)||!struct_exists(project,"initialization")||!is_array(project.initialization.enemies)) return undefined;
    if(source_index<0||source_index>=array_length(project.initialization.enemies)||array_length(project.initialization.enemies)>=BATTLE_EDITOR_ENEMY_LIMIT) return undefined;
    var source=project.initialization.enemies[source_index];
    if(!is_struct(source)) return undefined;

    var duplicate=json_parse(json_stringify(source));
    var source_enemy_uid=source.uid;
    duplicate.uid=BattleEditor_AllocateUid(project);
    duplicate.name=BattleEditor_MakeUniqueName(project,source.name);
    duplicate.control_id=BattleEditor_NextCopiedControlId(project,source.control_id);
    var duplicate_position=BattleEditor_DuplicateEnemyPosition(project,source);
    duplicate.x=duplicate_position[0];
    duplicate.y=duplicate_position[1];
    duplicate.editor_uid=duplicate.uid;
    duplicate.editor_target_type="enemy";

    var old_action_uids=[],new_action_uids=[];
    for(var action_index=0;action_index<array_length(duplicate.actions);action_index++){
        var copied_action=duplicate.actions[action_index];
        array_push(old_action_uids,copied_action.uid);
        copied_action.uid=BattleEditor_AllocateUid(project);
        array_push(new_action_uids,copied_action.uid);
    }
    var destination_folder=BattleEditor_EnsureEnemyResourceDirectory(BattleEditor_RuntimeSaveDirectory("current"),duplicate.name);

    var old_resource_uids=[],new_resource_uids=[];
    var source_resource_count=array_length(project.resources.enemy_textures);
    for(var resource_index=0;resource_index<source_resource_count;resource_index++){
        var source_resource=project.resources.enemy_textures[resource_index];
        if(!is_struct(source_resource)||source_resource.enemy_uid!=source_enemy_uid) continue;
        var copied_resource=json_parse(json_stringify(source_resource));
        array_push(old_resource_uids,copied_resource.uid);
        copied_resource.uid=BattleEditor_AllocateUid(project);
        copied_resource.enemy_uid=duplicate.uid;
        array_push(new_resource_uids,copied_resource.uid);
        copied_resource.path=BattleEditor_CopyEnemyResourceFile(destination_folder,copied_resource.path,"asset_");
        if(!is_struct(copied_resource.animation)) copied_resource.animation=BattleEditor_NewAnimation();
        var copied_animation_frames=[];
        for(var frame_index=0;frame_index<array_length(copied_resource.animation.frames);frame_index++) array_push(copied_animation_frames,BattleEditor_CopyEnemyResourceFile(destination_folder,copied_resource.animation.frames[frame_index],"frame_"));
        copied_resource.animation.frames=copied_animation_frames;
        array_push(project.resources.enemy_textures,copied_resource);
    }

    var part_keys=BattleEditor_EnemyPartKeys();
    for(var part_index=0;part_index<array_length(part_keys);part_index++){
        var copied_part=variable_struct_get(duplicate.parts,part_keys[part_index]);
        var old_part_asset=struct_exists(copied_part,"asset_uid")?copied_part.asset_uid:-1;
        var owned_asset_index=-1;
        for(var owned_asset_search=0;owned_asset_search<array_length(old_resource_uids);owned_asset_search++) if(old_resource_uids[owned_asset_search]==old_part_asset){owned_asset_index=owned_asset_search;break;}
        if(owned_asset_index>=0){
            var new_part_asset=new_resource_uids[owned_asset_index];
            copied_part.asset_uid=new_part_asset;
            var mapped_resource=BattleEditor_FindEnemyTextureResource(project,new_part_asset);
            if(!is_undefined(mapped_resource)){
                copied_part.source=mapped_resource.path;
                copied_part.animation=json_parse(json_stringify(mapped_resource.animation));
            }
        }else{
            // A stale/foreign UID must never make a duplicate resolve another
            // enemy's texture. Preserve the visible source directly instead.
            copied_part.asset_uid=-1;
            copied_part.source=BattleEditor_CopyEnemyResourceFile(destination_folder,copied_part.source,"part_");
            if(is_struct(copied_part.animation)&&is_array(copied_part.animation.frames)){
                var copied_part_frames=[];
                for(var part_frame_index=0;part_frame_index<array_length(copied_part.animation.frames);part_frame_index++) array_push(copied_part_frames,BattleEditor_CopyEnemyResourceFile(destination_folder,copied_part.animation.frames[part_frame_index],"part_frame_"));
                copied_part.animation.frames=copied_part_frames;
            }
        }
    }

    // ACT-triggered Workspace lists are part of the enemy's authored behaviour.
    // Clone the matching list graph and remap links, enemy targets and action IDs.
    var old_list_uids=[],new_list_uids=[],copied_lists=[];
    var source_list_count=array_length(project.script_lists);
    for(var list_index=0;list_index<source_list_count;list_index++){
        var source_list=project.script_lists[list_index];
        if(source_list.entry_kind!=BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION||BattleEditor_RemapCopiedUid(source_list.entry_value,old_action_uids,new_action_uids)==source_list.entry_value) continue;
        var copied_list=json_parse(json_stringify(source_list));
        array_push(old_list_uids,copied_list.uid);
        copied_list.uid=BattleEditor_AllocateUid(project);
        array_push(new_list_uids,copied_list.uid);
        copied_list.name=copied_list.name+"_"+duplicate.name;
        copied_list.world_x+=36;copied_list.world_y+=36;
        copied_list.entry_value=BattleEditor_RemapCopiedUid(copied_list.entry_value,old_action_uids,new_action_uids);
        for(var step_index=0;step_index<array_length(copied_list.steps);step_index++){
            var copied_step=copied_list.steps[step_index];
            copied_step.uid=BattleEditor_AllocateUid(project);
            if(struct_exists(copied_step,"enemy_uid")&&copied_step.enemy_uid==source_enemy_uid) copied_step.enemy_uid=duplicate.uid;
            if(struct_exists(copied_step,"target_uid")&&copied_step.target_uid==source_enemy_uid) copied_step.target_uid=duplicate.uid;
            if(struct_exists(copied_step,"target_type")&&copied_step.target_type=="enemy"&&copied_step.target==source.control_id) copied_step.target=duplicate.control_id;
        }
        array_push(copied_lists,copied_list);
    }
    for(var copied_list_index=0;copied_list_index<array_length(copied_lists);copied_list_index++){
        var linked_list=copied_lists[copied_list_index];
        for(var copied_step_index=0;copied_step_index<array_length(linked_list.steps);copied_step_index++){
            var linked_step=linked_list.steps[copied_step_index];
            if(!struct_exists(linked_step,"target_list_uid")) continue;
            for(var link_index=0;link_index<array_length(old_list_uids);link_index++) if(linked_step.target_list_uid==old_list_uids[link_index]){linked_step.target_list_uid=new_list_uids[link_index];break;}
        }
        array_push(project.script_lists,linked_list);
    }

    array_push(project.initialization.enemies,duplicate);
    return duplicate;
}

function BattleEditor_EnemyPartKeys() {return ["body","head","face","left_hand","right_hand","legs"];}
function BattleEditor_EnemyPartName(key) {
    switch(key){case "body":return "身体";case "head":return "头部";case "face":return "脸";case "left_hand":return "左手";case "right_hand":return "右手";case "legs":return "脚 / 腿";}
    return key;
}

function BattleEditor_FindEnemyByUid(project,enemy_uid) {
    if(!is_struct(project)||!struct_exists(project,"initialization")||!is_array(project.initialization.enemies)) return undefined;
    for(var enemy_index=0;enemy_index<array_length(project.initialization.enemies);enemy_index++){
        var enemy=project.initialization.enemies[enemy_index];
        if(is_struct(enemy)&&struct_exists(enemy,"uid")&&enemy.uid==enemy_uid) return enemy;
    }
    return undefined;
}

function BattleEditor_FindEnemyTextureResource(project,resource_uid) {
    if(!is_struct(project)||!struct_exists(project,"resources")||!is_struct(project.resources)||!struct_exists(project.resources,"enemy_textures")) return undefined;
    for(var resource_index=0;resource_index<array_length(project.resources.enemy_textures);resource_index++){
        var resource=project.resources.enemy_textures[resource_index];
        if(is_struct(resource)&&resource.uid==resource_uid) return resource;
    }
    return undefined;
}

function BattleEditor_EnemyTextureOptions(project,enemy_uid,part_key="") {
    var result=[];
    if(!is_struct(project)||!struct_exists(project,"resources")||!struct_exists(project.resources,"enemy_textures")) return result;
    for(var resource_index=0;resource_index<array_length(project.resources.enemy_textures);resource_index++){
        var resource=project.resources.enemy_textures[resource_index];
        if(!is_struct(resource)||resource.enemy_uid!=enemy_uid) continue;
        // part_hint is a UI suggestion only. Any enemy-owned image may be put
        // on any part; the editor must not hard-code an artistic restriction.
        array_push(result,resource);
    }
    return result;
}

function BattleEditor_EnemyPartResolved(project,enemy,part_key) {
    var part=variable_struct_get(enemy.parts,part_key);
    if(struct_exists(part,"asset_uid")&&part.asset_uid>=0){
        var resource=BattleEditor_FindEnemyTextureResource(project,part.asset_uid);
        if(!is_undefined(resource)){
            var resolved=json_parse(json_stringify(part));
            resolved.source=resource.path;
            resolved.animation=resource.animation;
            return resolved;
        }
    }
    return part;
}

function BattleEditor_LoadEnemyPartSprite(part) {
    var loaded=BattleEditor_LoadAnimationSprite(string(part.source),part.animation,false,true);
    if(loaded.owns&&sprite_exists(loaded.sprite)) sprite_set_offset(loaded.sprite,round(real(part.origin_x))-loaded.trim_x,round(real(part.origin_y))-loaded.trim_y);
    return loaded;
}

function BattleEditor_EnemyAnimationFrame(part,sprite_id,elapsed_frames) {
    if(!sprite_exists(sprite_id)) return 0;
    var animation_frame_count=max(1,sprite_get_number(sprite_id));
    if(animation_frame_count<=1) return 0;
    var animation_rate=max(0.001,real(part.animation.fps));
    var animation_frame=floor(max(0,elapsed_frames)*animation_rate/GAME_FPS);
    if(part.animation.loop) return animation_frame mod animation_frame_count;
    return min(animation_frame_count-1,animation_frame);
}

function BattleEditor_LoadEnemyVisualCache(project,enemy) {
    var sprites={};var parts={};var owned=[];var keys=BattleEditor_EnemyPartKeys();
    for(var part_index=0;part_index<array_length(keys);part_index++){
        var key=keys[part_index];var part=BattleEditor_EnemyPartResolved(project,enemy,key);
        if(!struct_exists(part,"runtime_start")) part.runtime_start=0;
        var loaded=BattleEditor_LoadEnemyPartSprite(part);
        variable_struct_set(sprites,key,sprite_exists(loaded.sprite)?loaded.sprite:-1);
        variable_struct_set(parts,key,part);
        if(loaded.owns&&sprite_exists(loaded.sprite)) array_push(owned,loaded.sprite);
    }
    return {sprites:sprites,parts:parts,owned:owned};
}

function BattleEditor_FreeEnemyVisualCache(cache) {
    if(!is_struct(cache)||!struct_exists(cache,"owned")||!is_array(cache.owned)) return;
    for(var index=0;index<array_length(cache.owned);index++) if(sprite_exists(cache.owned[index])) sprite_delete(cache.owned[index]);
    cache.owned=[];
}

function BattleEditor_EvaluateEnemyPoseFormula(source,idle_time) {
    source=string(source);
    // Fast paths for the default rig expressions. They used to rebuild the
    // recursive parser three times per enemy on every rendered frame.
    if(source=="cos(time*3.75)*4") return {valid:true,value:dcos(idle_time*3.75)*4};
    if(source=="sin(time*7.5)*3") return {valid:true,value:dsin(idle_time*7.5)*3};
    if(source=="sin(time*7.5)*4") return {valid:true,value:dsin(idle_time*7.5)*4};

    // A formula with neither time nor randomness is constant until edited.
    // Dynamic custom formulae retain the full parser and existing semantics.
    var lower=string_lower(source);
    var constant=string_pos("time",lower)<=0&&string_pos("random",lower)<=0&&string_pos("rand",lower)<=0;
    if(constant){
        static cached_sources=[];
        static cached_results=[];
        for(var cache_index=0;cache_index<array_length(cached_sources);cache_index++) if(cached_sources[cache_index]==source) return cached_results[cache_index];
        var constant_result=BattleEditor_EvaluateNumberExpression(source,{time:idle_time});
        if(array_length(cached_sources)>=128){array_delete(cached_sources,0,1);array_delete(cached_results,0,1);}
        array_push(cached_sources,source);array_push(cached_results,constant_result);
        return constant_result;
    }
    return BattleEditor_EvaluateNumberExpression(source,{time:idle_time});
}

function BattleEditor_EnemyPoseValues(enemy,idle_time) {
    var sway_result=BattleEditor_EvaluateEnemyPoseFormula(enemy.sway_x,idle_time);
    var torso_result=BattleEditor_EvaluateEnemyPoseFormula(enemy.torso_y,idle_time);
    var head_result=BattleEditor_EvaluateEnemyPoseFormula(enemy.head_y,idle_time);
    var sway=sway_result.valid?sway_result.value:0;
    var torso=torso_result.valid?torso_result.value:0;
    var head=head_result.valid?head_result.value:torso;
    return {sway:sway,torso:torso,head:head};
}

function BattleEditor_EnemyPartPoseWithValues(enemy,part_key,root_x,root_y,pose_values,view_scale=1) {
    var part=variable_struct_get(enemy.parts,part_key);
    var y_motion=(part_key=="head"||part_key=="face")?pose_values.head:pose_values.torso;
    // A sole-anchored part consumes horizontal sway as a deformation in the
    // renderer. Do not also translate its origin, or the feet and the entire
    // assembled enemy visibly drift left and right.
    var anchored=struct_exists(part,"deform_with_torso")&&part.deform_with_torso;
    var x_motion=anchored?0:pose_values.sway;
    return [
        root_x+(enemy.rig_offset_x+part.offset_x+x_motion)*view_scale,
        root_y+(enemy.rig_offset_y+part.offset_y+y_motion)*view_scale
    ];
}

function BattleEditor_EnemyPartPose(enemy,part_key,root_x,root_y,idle_time,view_scale=1) {
    return BattleEditor_EnemyPartPoseWithValues(enemy,part_key,root_x,root_y,BattleEditor_EnemyPoseValues(enemy,idle_time),view_scale);
}

/// Shared renderer for the live encounter and the independent visual editor.
/// The editor changes only root_x/root_y and selection decoration; asset,
/// animation, offset and sway semantics remain identical to battle playback.
function BattleEditor_DrawEnemyVisual(enemy,cache,root_x,root_y,idle_time,selected_part_key="",view_scale=1) {
    if(!is_struct(cache)) return false;
    var order=["legs","body","left_hand","right_hand","head","face"];
    view_scale=max(0.001,real(view_scale));
    var draw_scale_x=enemy.scale_x*view_scale,draw_scale_y=enemy.scale_y*view_scale;
    // The three formulas describe one rig pose, not six independent parts.
    // Parse/evaluate them once per enemy draw instead of eighteen times per
    // frame; every part then consumes the same coherent result.
    var pose_values=BattleEditor_EnemyPoseValues(enemy,idle_time);
    for(var order_index=0;order_index<array_length(order);order_index++){
        var key=order[order_index];var sprite_id=variable_struct_get(cache.sprites,key);
        if(!sprite_exists(sprite_id)) continue;
        var part=variable_struct_get(cache.parts,key);
        var pose=BattleEditor_EnemyPartPoseWithValues(enemy,key,root_x,root_y,pose_values,view_scale);
        var frame=BattleEditor_EnemyAnimationFrame(part,sprite_id,idle_time-part.runtime_start);
        if(struct_exists(part,"deform_with_torso")&&part.deform_with_torso){
            // A complete Sans body and layered Dust legs both anchor their
            // feet. Only the upper edge follows X/Y sway; the lower edge stays
            // at the authored root, so sway reads as a posture instead of a
            // world-space translation of the whole character.
            var anchored_base_x=root_x+(enemy.rig_offset_x+part.offset_x)*view_scale;
            var anchored_left=anchored_base_x-sprite_get_xoffset(sprite_id)*draw_scale_x;
            var anchored_top_left=anchored_left+pose_values.sway*view_scale;
            var anchored_motion_y=pose[1]-(root_y+(enemy.rig_offset_y+part.offset_y)*view_scale);
            var anchored_sole_offset=struct_exists(part,"deform_sole_offset_y")?real(part.deform_sole_offset_y):0;
            var anchored_bottom=root_y+(enemy.rig_offset_y+part.offset_y+anchored_sole_offset*enemy.scale_y)*view_scale;
            var anchored_top=anchored_bottom-sprite_get_height(sprite_id)*draw_scale_y+anchored_motion_y;
            var anchored_width=sprite_get_width(sprite_id)*draw_scale_x;
            draw_sprite_pos(sprite_id,frame,anchored_top_left,anchored_top,anchored_top_left+anchored_width,anchored_top,anchored_left+anchored_width,anchored_bottom,anchored_left,anchored_bottom,1);
        }else draw_sprite_ext(sprite_id,frame,pose[0],pose[1],draw_scale_x,draw_scale_y,0,c_white,1);
        if(selected_part_key==key){
            var left=pose[0]-sprite_get_xoffset(sprite_id)*draw_scale_x;
            var top=pose[1]-sprite_get_yoffset(sprite_id)*draw_scale_y;
            var right=left+sprite_get_width(sprite_id)*draw_scale_x;
            var bottom=top+sprite_get_height(sprite_id)*draw_scale_y;
            draw_set_color(c_yellow);draw_rectangle(min(left,right)-2,min(top,bottom)-2,max(left,right)+2,max(top,bottom)+2,true);
        }
    }
    return true;
}

function BattleEditor_EnemyResourceCaption(project,resource_uid) {
    var resource=BattleEditor_FindEnemyTextureResource(project,resource_uid);
    return is_undefined(resource)?"未选择资源":resource.name;
}

// UID is an internal save-file identity. Authors work with a unique display
// name and an intentionally repeatable control_id instead.
function BattleEditor_AllocateUid(project) {
    if (!struct_exists(project,"next_uid")) project.next_uid=1;
    var result=project.next_uid;
    project.next_uid+=1;
    return result;
}

function BattleEditor_FindExistingControlUid(project,object_data) {
    if(!is_struct(project)||!is_struct(object_data)||!struct_exists(object_data,"control_id")) return -1;
    var wanted_id=string(object_data.control_id);
    var wanted_type=BattleEditor_DataTargetType(object_data);
    if(wanted_id==""||wanted_type=="") return -1;
    var candidates=[];
    if(struct_exists(project,"initialization")&&is_struct(project.initialization)){
        var identity_init=project.initialization;
        if(struct_exists(identity_init,"board")&&is_struct(identity_init.board)) array_push(candidates,identity_init.board);
        if(struct_exists(identity_init,"frames")&&is_array(identity_init.frames)) for(var identity_frame=0;identity_frame<array_length(identity_init.frames);identity_frame++) array_push(candidates,identity_init.frames[identity_frame]);
        if(struct_exists(identity_init,"enemies")&&is_array(identity_init.enemies)) for(var identity_enemy=0;identity_enemy<array_length(identity_init.enemies);identity_enemy++) array_push(candidates,identity_init.enemies[identity_enemy]);
    }
    if(struct_exists(project,"events")&&is_array(project.events)) for(var identity_event=0;identity_event<array_length(project.events);identity_event++) array_push(candidates,project.events[identity_event]);
    for(var identity_index=0;identity_index<array_length(candidates);identity_index++){
        var candidate=candidates[identity_index];
        if(!is_struct(candidate)||candidate==object_data||!struct_exists(candidate,"control_uid")) continue;
        if(string(candidate.control_id)==wanted_id&&BattleEditor_DataTargetType(candidate)==wanted_type) return candidate.control_uid;
    }
    return -1;
}

function BattleEditor_AssignIdentity(project,object_data,base_name="对象",control_id="",match_existing_control_group=false) {
    if (!struct_exists(object_data,"uid")) object_data.uid=BattleEditor_AllocateUid(project);
    else if (is_real(object_data.uid)) project.next_uid=max(project.next_uid,object_data.uid+1);
    if (!struct_exists(object_data,"name")||string_length(string(object_data.name))<=0) object_data.name=base_name;
    if (!struct_exists(object_data,"control_id")||string_length(string(object_data.control_id))<=0){
        object_data.control_id=control_id==""?string(object_data.name):control_id;
    }
    if(!struct_exists(object_data,"control_uid")){
        var existing_control_uid=match_existing_control_group?BattleEditor_FindExistingControlUid(project,object_data):-1;
        object_data.control_uid=existing_control_uid>=0?existing_control_uid:BattleEditor_AllocateUid(project);
    }
    return object_data;
}

function BattleEditor_NameUsed(project,candidate,except_uid=-1) {
    if (candidate=="") return true;
    var init=project.initialization;
    if(struct_exists(init,"board")&&init.board.name==candidate&&(!struct_exists(init.board,"uid")||init.board.uid!=except_uid)) return true;
    if(struct_exists(init,"frames")&&is_array(init.frames)){
        for(var i=0;i<array_length(init.frames);i++){
            var frame=init.frames[i];
            if(frame.name==candidate&&(!struct_exists(frame,"uid")||frame.uid!=except_uid)) return true;
        }
    }
    if(struct_exists(init,"enemies")&&is_array(init.enemies)){
        for(var enemy_index=0;enemy_index<array_length(init.enemies);enemy_index++){
            var enemy=init.enemies[enemy_index];
            if(enemy.name==candidate&&(!struct_exists(enemy,"uid")||enemy.uid!=except_uid)) return true;
        }
    }
    if(struct_exists(project,"events")&&is_array(project.events)){
        for(var event_index=0;event_index<array_length(project.events);event_index++){
            var candidate_event=project.events[event_index];
            if(candidate_event.name==candidate&&(!struct_exists(candidate_event,"uid")||candidate_event.uid!=except_uid)) return true;
        }
    }
    return false;
}

function BattleEditor_MakeUniqueName(project,preferred,except_uid=-1) {
    var base=string(preferred);
    if(string_length(base)<=0) base="对象";
    if(!BattleEditor_NameUsed(project,base,except_uid)) return base;
    var suffix=2;
    while(BattleEditor_NameUsed(project,base+"_"+string(suffix),except_uid)) suffix+=1;
    return base+"_"+string(suffix);
}

function BattleEditor_ControlIdCount(project,control_id) {
    var key=string(control_id);
    var count=0;
    var init=project.initialization;
    if(struct_exists(init,"board")&&struct_exists(init.board,"control_id")&&init.board.control_id==key) count+=1;
    if(struct_exists(init,"frames")&&is_array(init.frames)){
        for(var i=0;i<array_length(init.frames);i++) if(struct_exists(init.frames[i],"control_id")&&init.frames[i].control_id==key) count+=1;
    }
    if(struct_exists(project,"events")&&is_array(project.events)){
        for(var i=0;i<array_length(project.events);i++) if(struct_exists(project.events[i],"control_id")&&project.events[i].control_id==key) count+=1;
    }
    return count;
}

function BattleEditor_ControlIdUsed(project,control_id) {
    var key=string(control_id);
    if(string_length(key)<=0) return true;
    var options=BattleEditor_ControlTargetOptions(project);
    for(var i=0;i<array_length(options);i++) if(string(options[i].control_id)==key) return true;
    return false;
}

/// Return the first unused ID for a newly authored independent control group.
/// A semantic base without digits starts at base1; a numbered base advances
/// within that independent sequence. Copy batches never use this rule: they
/// keep the complete source ID and append _2, _3, and so on.
function BattleEditor_NextControlId(project,source_id="object") {
    var source=string(source_id);
    if(string_length(source)<=0) source="object";
    var prefix=source,number=1;
    if(string_length(source)>0){
        var digit_start=string_length(source)+1;
        for(var i=string_length(source);i>=1;i--){
            var ch=string_char_at(source,i);
            if(string_pos(ch,"0123456789")<=0) break;
            digit_start=i;
        }
        if(digit_start<=string_length(source)){
            prefix=string_copy(source,1,digit_start-1);
            number=max(1,round(real(string_copy(source,digit_start,string_length(source)-digit_start+1)))+1);
        }
    }
    var candidate=prefix+string(number);
    while(BattleEditor_ControlIdUsed(project,candidate)){number+=1;candidate=prefix+string(number);}
    return candidate;
}

/// Copies keep their source identity and receive a copy-group suffix. A1 is
/// therefore copied as A1_2 (then A1_3), never renamed to the unrelated A2.
function BattleEditor_NextCopiedControlId(project,source_id) {
    var source=string(source_id);
    if(string_length(source)<=0) source="object";
    var copy_index=2;
    var candidate=source+"_"+string(copy_index);
    while(BattleEditor_ControlIdUsed(project,candidate)){copy_index+=1;candidate=source+"_"+string(copy_index);}
    return candidate;
}

enum BATTLE_EDITOR_SCRIPT_ENTRY {
    GAME_START,
    MONSTER_TURN,
    TIMER_VALUE,
    PLAYER_HURT,
    ITEM_USED,
    SCRIPT_ENTRY,
    ACT_ACTION,
    ORPHAN = -1
}

enum BATTLE_EDITOR_ITEM_AFTER_USE {
    IMMEDIATE,
    APPEND_TURN,
    REPLACE_TURN
}

function BattleEditor_ItemAfterUseModeName(mode) {
    switch(clamp(round(real(mode)),BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE,BATTLE_EDITOR_ITEM_AFTER_USE.REPLACE_TURN)){
        case BATTLE_EDITOR_ITEM_AFTER_USE.APPEND_TURN:return "追加到下一怪物回合";
        case BATTLE_EDITOR_ITEM_AFTER_USE.REPLACE_TURN:return "替代下一怪物回合";
    }
    return "即时执行（不接管回合）";
}

function BattleEditor_ItemByUid(project,item_uid) {
    if(!is_struct(project)||!struct_exists(project,"initialization")||!struct_exists(project.initialization,"items")) return undefined;
    for(var item_index=0;item_index<array_length(project.initialization.items);item_index++){
        var item_data=project.initialization.items[item_index];
        if(struct_exists(item_data,"uid")&&string(item_data.uid)==string(item_uid)) return item_data;
    }
    return undefined;
}

function BattleEditor_ActionTriggerOptions(project) {
    var result=[];
    if(is_undefined(project)||!is_struct(project)||!struct_exists(project,"initialization")) return result;
    for(var enemy_index=0;enemy_index<array_length(project.initialization.enemies);enemy_index++){
        var enemy=project.initialization.enemies[enemy_index];
        if(!struct_exists(enemy,"actions")||!is_array(enemy.actions)) continue;
        for(var action_index=0;action_index<array_length(enemy.actions);action_index++){
            var action=enemy.actions[action_index];
            array_push(result,{uid:action.uid,enemy_index:enemy_index,action_index:action_index,caption:enemy.name+" / "+action.name});
        }
    }
    return result;
}

function BattleEditor_ActionTriggerCaption(project,action_uid) {
    var options=BattleEditor_ActionTriggerOptions(project);
    for(var i=0;i<array_length(options);i++) if(options[i].uid==action_uid) return options[i].caption;
    return "未选择行动项目";
}

function BattleEditor_ScriptEntryName(entry_kind,entry_value="",project=undefined) {
    switch(entry_kind){
        case BATTLE_EDITOR_SCRIPT_ENTRY.ORPHAN:return "游离积木（不执行）";
        case BATTLE_EDITOR_SCRIPT_ENTRY.GAME_START:return "游戏开始";
        case BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN:return "怪物回合 "+string(entry_value);
        case BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE:return "计时器 = "+string(entry_value);
        case BATTLE_EDITOR_SCRIPT_ENTRY.PLAYER_HURT:return "玩家受伤";
        case BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED:return "使用物品后";
        case BATTLE_EDITOR_SCRIPT_ENTRY.SCRIPT_ENTRY:return "脚本入口";
        case BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION:return "行动："+BattleEditor_ActionTriggerCaption(project,entry_value);
    }
    return "脚本入口";
}

function BattleEditor_NewScriptStep(project,kind="control_object") {
    return {
        uid:BattleEditor_AllocateUid(project),
        kind:kind,
        duration:60,
        wait_mode:0,
        // Used only by "wait for previous completion". Keeping it separate
        // preserves the author's fixed-wait value when switching modes.
        wait_extra_duration:0,
        target_mode:"control_id",
        // 0 controls existing runtime/scene targets. 1 clones the selected
        // authored scene group, applies this operation only to that new batch,
        // then exposes the copies under copy_control_id for later controls.
        control_source_mode:0,
        copy_control_id:"",
        copy_control_id_auto:true,
        target:"",
        target_type:"",
        // Stable authored-group identity. target remains the readable label
        // and legacy/runtime-generated fallback; renaming it cannot sever a
        // control step from an authored scene group.
        target_group_uid:-1,
        // Optional constructor/controller identity. The ordinary target type
        // still identifies the actual object or path node for old saves.
        target_group_kind:"",
        target_category:"game",
        property_category:"transform",
        target_uid:-1,
        target_list_uid:-1,
        property:"position",
        value:0,
        // Generic runtime follow is a capability of every created movable
        // object, not a Bone-only implementation detail.  The selected frame
        // is stored separately so turning follow off never forgets the choice.
        follow_target_uid:-1,
        follow_value_initialized:false,
        // Damage-rule changes normally recolour the attack as well. Authors
        // may disable this per operation to change collision behaviour only.
        damage_change_visual:true,
        // Only used by the blue-soul direction control.  Direction selection
        // and the optional Sans-style impulse are intentionally separate UI
        // decisions: changing gravity does not have to throw the soul.
        soul_blue_direction:1,
        blue_gravity_throw:false,
        text_value:"",
        dialogue_font:2,
        dialogue_voice:2,
        dialogue_template:0,
        dialogue_offset_x:"92",
        dialogue_offset_y:"-34",
        // 0 types and closes automatically. 1 keeps the native X-to-skip,
        // Z-to-confirm interaction. Manual speech blocks subsequent script
        // rows by default, while authors may explicitly let it run in parallel.
        dialogue_mode:1,
        dialogue_block_battle:true,
        position_x:"",
        position_y:"",
        position_angle:"",
        // A battle frame exposes its complete transform in the position item.
        // Empty fields mean "do not change this component".
        board_transform_width:"",
        board_transform_height:"",
        board_shape_width:"80",
        board_shape_height:"80",
        board_shape_radius_x:"40",
        board_shape_radius_y:"40",
        board_shape_triangle_width:"80",
        board_shape_triangle_height:"70",
        points:[[-40,-40],[40,-40],[40,40],[-40,40]],
        point_index:0,
        vertex_uids:[],
        vertex_target_x:0,
        vertex_target_y:0,
        coordinate_mode:"absolute",
        orbit_center_x:"320",
        orbit_center_y:"240",
        orbit_use_group_center:true,
        physics_direction:"0",
        physics_speed:"4",
        physics_acceleration:"0",
        physics_curve_speed:"0",
        physics_rotation_speed:"0",
        // Composite target motion. Unlike the old five separate Bone-only
        // switches, this is one generic control operation for every target
        // that exposes a world position. A locked shot captures one direction
        // at execution time; continuous mode deliberately tracks every frame.
        aim_target_uid:-2,
        aim_continuous:false,
        aim_move_speed:"4",
        aim_face_target:true,
        aim_behavior:1,
        // Optional pre-move telegraph. It belongs to the control operation,
        // not to any particular projectile family.
        warning_enabled:false,
        warning_duration:30,
        warning_angle_mode:0,
        warning_angle:"0",
        // These shortcuts manipulate the existing GB alarm state. Generic
        // movement, easing and colour control remain shared with all objects.
        gb_hold_while_moving:false,
        gb_move_sound:true,
        // Bone-local length reference: 0=center, 1=head fixed, 2=tail fixed.
        // This deliberately follows the Bone's own angle instead of screen
        // up/down, so horizontal and arbitrarily rotated bones use one rule.
        length_anchor:0,
        create_category:0,
        create_preset:"bone",
        create_control_id:"",
        create_control_id_auto:true,
        create_x:"320",
        create_y:"240",
        create_angle:"90",
        create_lifetime:"-1",
        create_size:"48",
        // Runtime-created frames use real full dimensions.  The old single
        // create_size field represented four equal half-extents and silently
        // forced a square; keep it only for non-frame object families and
        // legacy migration.
        create_width:"60",
        create_height:"60",
        create_board_shape:0,
        create_board_up:"30",
        create_board_down:"30",
        create_board_left:"30",
        create_board_right:"30",
        create_board_radius_x:"30",
        create_board_radius_y:"30",
        create_board_triangle_size:"40",
        create_board_rotate:"0",
        create_board_depth:"10",
        create_damage_type:0,
        create_layer_mode:BATTLE_EDITOR_LAYER.IN_BOARD,
        // Workspace creation edits the same complete event structure used by
        // the scene editor.  It is a template, not a second runtime model;
        // execution deep-clones it and sends it through BattleEditor_SpawnEvent.
        create_template:BattleEditor_WorkspaceCreateDefaultData("bone"),
        create_animation_frame_index:0,
        tween:0,
        ease:0,
        script_name:"",
        script_arguments:"",
        wait_for_script:false,
        action_name:"bone_orbit",
        action_control_id:"",
        action_control_id_auto:true,
        action_source_uid:-1,
        action_direction:1,
        action_arguments:BattleEditor_BuiltinActionDefaults("bone_orbit"),
        // Function-path variables are local to this constructor. A local A may
        // shadow a project/runtime A while the curve is sampled without
        // replacing the outer value.
        action_path_variable:"t",
        // Function path source: 0=clone one authored object, 1=move an
        // existing Control-ID group while preserving every member's relative
        // offset. Legacy saves that used the old implicit default Bone keep a
        // private compatibility flag; new UI does not offer that extra source.
        action_path_mode:0,
        action_path_target_type:"bone",
        action_path_legacy_default:false,
        // Built-in arrangements may follow the main battle frame directly.
        // This is an action option, not an implicit Control Object step.
        action_follow:false,
        // Constructors may normally reclaim their generated group when their
        // algorithm ends. Keeping the group is explicit and defaults off so
        // old projects preserve their previous lifecycle.
        action_keep_objects:false,
        action_damage_change_visual:true,
        // Entry and exit are separate visual phases. The ordinary tween/ease
        // pair remains the entry curve for save compatibility.
        action_exit_tween:0,
        action_exit_ease:0,
        sound_name:"snd_bone_out",
        sound_timing:0,
        step_sound_enabled:false,
        read_target_key:"soul",
        read_target_uid:-1,
        read_target_type:"soul",
        read_property:"x",
        read_variable_name:"A",
        read_overwrite_confirmed:false,
        // Enemy and appearance resources are referenced by stable UIDs. Their
        // display names and on-disk character folders may be renamed freely.
        enemy_uid:-1,
        enemy_part_key:"body",
        enemy_resource_uid:-1,
        screen_action:"camera_set",
        screen_arguments:BattleEditor_ScreenActionDefaults("camera_set"),
        variable_name:"value",
        expression:"0",
        variable_operation:"set",
        condition_left:"value",
        condition_operator:">=",
        condition_right:"0",
        skip_count:1,
        repeat_count:"2",
        repeat_length:1,
        // Extra delay between completed iterations. Zero means every
        // instantaneous row in every iteration executes in the same frame;
        // an explicit Wait inside the repeated range still blocks normally.
        repeat_interval:"0",
        enabled:true
    };
}

function BattleEditor_ScriptListNameUsed(project,candidate) {
    if(!is_struct(project)||!struct_exists(project,"script_lists")||!is_array(project.script_lists)) return false;
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        if(is_struct(list_data)&&struct_exists(list_data,"name")&&string(list_data.name)==candidate) return true;
    }
    return false;
}

/// Display numbering is author-facing and independent from the project-wide
/// UID allocator. Enemies, boards and objects may already have consumed UIDs,
/// but the first ordinary script list must still be named 列表_1.
function BattleEditor_NextScriptListName(project) {
    var number=1;
    while(BattleEditor_ScriptListNameUsed(project,"列表_"+string(number))) number+=1;
    return "列表_"+string(number);
}

/// One data model for headed lists and loose stacks. ORPHAN is intentionally
/// not an executable entry and has no header/port in the canvas.
function BattleEditor_WorkspaceHasHeader(list_data) {
    return is_struct(list_data)&&(!struct_exists(list_data,"entry_kind")||list_data.entry_kind!=BATTLE_EDITOR_SCRIPT_ENTRY.ORPHAN);
}

function BattleEditor_WorkspaceSetOpen(controller,opened) {
    controller.tab=2;
    controller.workspace_open=opened;
    controller.script_stack_drag=undefined;controller.script_drag_mode="";controller.script_link_drag=false;
    controller.script_dropdown="";controller.script_context_open=false;controller.script_variables_open=false;
    if(opened){
        controller.script_inspector_anim_progress=0;
        controller.script_inspector_anim_phase=controller.script_selected_list>=0?1:0;
        controller.script_inspector_pending_list=controller.script_selected_list;
        controller.script_inspector_pending_step=controller.script_selected_step;
    }
    controller.status_text=opened?"Workspace：拖动左侧积木；Esc 返回场景":"Workspace 已收起；Esc 返回，或切换其他标签";
}

/// Called only after text/dialog/playback handlers have consumed Escape.
/// A press dismisses one interaction layer, never calls game_end/room_goto.
function BattleEditor_WorkspaceEscape(controller) {
    if(controller.tab!=2) return false;
    if(!is_undefined(controller.script_stack_drag)){controller.script_stack_drag=undefined;controller.script_drag_mode="";return true;}
    if(controller.script_link_drag){controller.script_link_drag=false;return true;}
    if(controller.script_dropdown!=""){controller.script_dropdown="";return true;}
    if(controller.script_context_open){controller.script_context_open=false;return true;}
    if(controller.script_variables_open){controller.script_variables_open=false;return true;}
    BattleEditor_WorkspaceSetOpen(controller,!controller.workspace_open);
    return true;
}

function BattleEditor_WorkspaceHeaderHeight(list_data) {return BattleEditor_WorkspaceHasHeader(list_data)?34:0;}
function BattleEditor_WorkspaceHeight(list_data) {return BattleEditor_WorkspaceHeaderHeight(list_data)+max(1,array_length(list_data.steps))*48;}

function BattleEditor_WorkspacePaletteKinds() {
    return ["control_object","create_object","builtin_action","screen_control","play_sound","enemy_appearance","set_variable","get_value","condition","wait","repeat","start_list"];
}

/// Maintain existing flat loop spans while editing, rather than inventing a
/// second nested runtime. Inserting in a loop expands it; detaching part of a
/// loop shrinks the original. Moved repeat rows carry their own span with them.
function BattleEditor_WorkspaceSpliceSteps(list_data,index,remove_count,inserted) {
    var old_count=array_length(list_data.steps);
    index=clamp(round(index),0,old_count);
    remove_count=clamp(round(remove_count),0,old_count-index);
    var inserted_count=array_length(inserted);
    for(var i=0;i<old_count;i++){
        var step=list_data.steps[i];
        if(step.kind!="repeat"||(i>=index&&i<index+remove_count)) continue;
        var span=max(0,round(real(step.repeat_length))),end_index=min(old_count,i+1+span);
        var removed=max(0,min(end_index,index+remove_count)-max(i+1,index));
        var added=(index>i&&index<=end_index)?inserted_count:0;
        if(removed>0||added>0) step.repeat_length=max(0,span-removed+added);
    }
    if(remove_count>0) array_delete(list_data.steps,index,remove_count);
    for(var j=0;j<inserted_count;j++) array_insert(list_data.steps,index+j,inserted[j]);
}

function BattleEditor_WorkspaceChanged(controller) {
    controller.script_layout_revision+=1;
    controller.timeline_duration_dirty=true;
    controller.runtime_snapshot_pending=true;
    controller.runtime_snapshot_idle_frames=0;
    controller.script_dropdown="";
    controller.script_context_open=false;
}

function BattleEditor_WorkspaceRepeatRanges(controller,list_data) {
    var key="u_"+string(list_data.uid);
    if(struct_exists(controller.script_layout_cache,key)){
        var cached=controller.script_layout_cache[$ key];
        if(cached.revision==controller.script_layout_revision&&cached.count==array_length(list_data.steps)) return cached.ranges;
    }
    var ranges=[];
    for(var i=0;i<array_length(list_data.steps);i++){
        var step=list_data.steps[i];
        if(step.kind=="repeat"&&(!struct_exists(step,"enabled")||step.enabled)){
            var end_index=min(array_length(list_data.steps),i+1+max(0,round(real(step.repeat_length))));
            if(end_index>i+1) array_push(ranges,{first:i,last:end_index});
        }
    }
    // Cache membership runs at edit time. Rendering uses these to colour the
    // ORIGINAL outside contour, never to draw another enclosing rectangle.
    var count=array_length(list_data.steps),delta=array_create(count+1,0),edge_runs=[];
    for(var ri=0;ri<array_length(ranges);ri++){
        delta[ranges[ri].first]+=1;delta[ranges[ri].last]-=1;
    }
    var active=0;
    for(var si=0;si<count;si++){
        active+=delta[si];
        var in_repeat=active>0,last_run=array_length(edge_runs)-1;
        if(last_run>=0&&edge_runs[last_run].in_repeat==in_repeat) edge_runs[last_run].last=si+1;
        else array_push(edge_runs,{first:si,last:si+1,in_repeat:in_repeat});
    }
    controller.script_layout_cache[$ key]={revision:controller.script_layout_revision,count:count,ranges:ranges,edge_runs:edge_runs};
    return ranges;
}

function BattleEditor_WorkspaceOutlineSegment(px1,py1,px2,py2,color) {
    draw_vertex_color(px1,py1,color,1);draw_vertex_color(px2,py2,color,1);
}

/// One perimeter submission. Row boundaries are not drawn or recoloured.
function BattleEditor_WorkspaceDrawOutline(controller,list_data,px,py,width,height,header_height,zoom,selected,visible_count=-1) {
    BattleEditor_WorkspaceRepeatRanges(controller,list_data);
    var runs=controller.script_layout_cache[$ "u_"+string(list_data.uid)].edge_runs;
    var normal=selected?make_color_rgb(155,202,244):make_color_rgb(87,112,142);
    var loop_color=BattleEditor_ScriptStepBorderColor("repeat",false);
    var run_count=array_length(runs),radius=min(7*zoom,width*0.5,height*0.5);
    if(visible_count>=0) while(run_count>0&&runs[run_count-1].first>=visible_count) run_count--;
    var top_color=header_height==0&&run_count>0&&runs[0].in_repeat?loop_color:normal;
    var bottom_color=run_count>0&&runs[run_count-1].in_repeat?loop_color:normal;
    draw_primitive_begin(pr_linelist);
    BattleEditor_WorkspaceOutlineSegment(px+radius,py,px+width-radius,py,top_color);
    BattleEditor_WorkspaceOutlineSegment(px+radius,py+height,px+width-radius,py+height,bottom_color);
    // Each rounded corner belongs to the same outer edge, not another layer.
    for(var corner=0;corner<4;corner++){
        var cx=px+(corner==0||corner==3?radius:width-radius);
        var cy=py+(corner<2?radius:height-radius);
        var angle_start=180-corner*90,col=corner<2?top_color:bottom_color;
        for(var segment=0;segment<4;segment++){
            var a1=angle_start-segment*22.5,a2=a1-22.5;
            BattleEditor_WorkspaceOutlineSegment(cx+lengthdir_x(radius,a1),cy+lengthdir_y(radius,a1),cx+lengthdir_x(radius,a2),cy+lengthdir_y(radius,a2),col);
        }
    }
    if(header_height>radius||run_count==0){
        var header_bottom=run_count==0?py+height-radius:py+header_height;
        BattleEditor_WorkspaceOutlineSegment(px,py+radius,px,header_bottom,normal);
        BattleEditor_WorkspaceOutlineSegment(px+width,py+radius,px+width,header_bottom,normal);
    }
    for(var ri=0;ri<run_count;ri++){
        var run=runs[ri],edge_top=max(py+radius,py+header_height+run.first*48*zoom);
        var edge_bottom=min(py+height-radius,py+header_height+run.last*48*zoom);
        if(edge_bottom<=edge_top) continue;
        var col=run.in_repeat?loop_color:normal;
        BattleEditor_WorkspaceOutlineSegment(px,edge_top,px,edge_bottom,col);
        BattleEditor_WorkspaceOutlineSegment(px+width,edge_top,px+width,edge_bottom,col);
    }
    draw_primitive_end();
}

/// Pure candidate search. The moving suffix is never removed during preview.
/// Cursor proximity is only a hint; a release commits exactly one splice.
function BattleEditor_WorkspaceSnap(project,drag,world_x,world_y,zoom) {
    var result={list_uid:-1,index:0,x:world_x,y:world_y};
    var best=22/max(0.35,zoom);
    for(var i=array_length(project.script_lists)-1;i>=0;i--){
        var target=project.script_lists[i];
        if(drag.mode=="list") continue;
        if(abs(world_x-target.world_x)>100/max(0.35,zoom)) continue;
        var count=array_length(target.steps);
        if(drag.mode=="head"){
            if(BattleEditor_WorkspaceHasHeader(target)) continue;
            var gap=abs(world_y+34-target.world_y);
            if(gap<best){best=gap;result={list_uid:target.uid,index:0,x:target.world_x,y:target.world_y-34};}
            continue;
        }
        if(target.uid==drag.source_uid) count=drag.first;
        if(target.uid==drag.source_uid&&drag.first==0) continue;
        var top=target.world_y+BattleEditor_WorkspaceHeaderHeight(target);
        var slot=clamp(round((world_y-top)/48),0,count);
        var gap=abs(world_y-(top+slot*48));
        if(gap<best){best=gap;result={list_uid:target.uid,index:slot,x:target.world_x,y:top+slot*48};}
    }
    return result;
}

/// Commit by identity, never by the inspector's animated selection/index.
/// Source data stays untouched until this function has validated both ends.
function BattleEditor_WorkspaceCommitDrop(project,drag,world_x,world_y,turn_number) {
    var source=BattleEditor_FindScriptList(project,drag.source_uid);
    var target=BattleEditor_FindScriptList(project,drag.snap.list_uid);
    if(drag.mode=="list"){
        if(is_undefined(source)) return -1;
        source.world_x=world_x;source.world_y=world_y;
        return source.uid;
    }
    if(drag.mode=="head"){
        var entry_value="";
        if(drag.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN) entry_value=turn_number;
        if(drag.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE) entry_value=60;
        if(drag.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED) entry_value=array_length(project.initialization.items)>0?project.initialization.items[0].uid:-1;
        if(drag.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION){var actions=BattleEditor_ActionTriggerOptions(project);entry_value=array_length(actions)>0?actions[0].uid:-1;}
        if(!is_undefined(target)&&!BattleEditor_WorkspaceHasHeader(target)){
            target.entry_kind=drag.entry_kind;target.entry_value=entry_value;target.world_y-=34;
            target.turn=max(1,round(real(turn_number)));
            return target.uid;
        }
        var headed=BattleEditor_NewScriptList(project,world_x,world_y,drag.entry_kind,entry_value,turn_number);
        array_push(project.script_lists,headed);return headed.uid;
    }
    var payload=[];
    if(drag.mode=="new") array_push(payload,BattleEditor_NewScriptStep(project,drag.kind));
    else{
        if(is_undefined(source)||drag.first<0||drag.first>=array_length(source.steps)) return -1;
        if(!is_undefined(target)&&target.uid==source.uid&&drag.snap.index>drag.first) return -1;
        for(var p=drag.first;p<array_length(source.steps);p++) array_push(payload,source.steps[p]);
        BattleEditor_WorkspaceSpliceSteps(source,drag.first,array_length(payload),[]);
    }
    if(is_undefined(target)){
        target=BattleEditor_NewScriptList(project,world_x,world_y,BATTLE_EDITOR_SCRIPT_ENTRY.ORPHAN,"",turn_number);
        array_push(project.script_lists,target);
    }
    BattleEditor_WorkspaceSpliceSteps(target,drag.snap.list_uid<0?0:drag.snap.index,0,payload);
    if(!is_undefined(source)&&source.uid!=target.uid&&!BattleEditor_WorkspaceHasHeader(source)&&array_length(source.steps)==0){
        for(var i=0;i<array_length(project.script_lists);i++) if(project.script_lists[i].uid==source.uid){array_delete(project.script_lists,i,1);break;}
    }
    return target.uid;
}

function BattleEditor_WorkspaceBeginDrag(controller,mode,source_uid,first,kind,entry_kind,mx,my,offset_x,offset_y) {
    controller.script_stack_drag={mode:mode,source_uid:source_uid,first:first,kind:kind,entry_kind:entry_kind,
        press_x:mx,press_y:my,offset_x:offset_x,offset_y:offset_y,active:mode=="new"||mode=="head",x:0,y:0,
        snap:{list_uid:-1,index:0,x:0,y:0}};
    controller.script_drag_mode="stack";
}

function BattleEditor_WorkspaceNewPaletteInput(controller,mx,my,click,wheel) {
    if(click&&BattleEditor_PointInRect(mx,my,542,8,632,30)){
        controller.script_dropdown=controller.script_dropdown=="formula_help"?"":"formula_help";
        controller.script_context_open=false;return true;
    }
    if(controller.script_dropdown=="formula_help"){
        if(click&&!BattleEditor_PointInRect(mx,my,274,32,638,BattleEditor_FormulaHelpLayout().bottom)) controller.script_dropdown="";
        return true;
    }
    if(controller.script_dropdown!=""||controller.script_context_open) return false;
    if(click&&BattleEditor_PointInRect(mx,my,8,36,30,58)){
        controller.script_palette_open=!controller.script_palette_open;return true;
    }
    // A sliding panel owns its visible footprint but not the canvas beside it.
    var progress=controller.script_palette_progress;
    var slide=-184*power(1-progress,3);
    if(progress<1) return progress>0&&BattleEditor_PointInRect(mx,my,max(0,8+slide),62,176+slide,448);
    if(!controller.script_palette_open||!BattleEditor_PointInRect(mx,my,8,62,176,448)) return false;
    if(wheel!=0) controller.script_palette_scroll=clamp(controller.script_palette_scroll+wheel,0,controller.script_palette_category==0?0:2);
    if(click){
        if(my<90){controller.script_palette_category=mx<92?0:1;controller.script_palette_scroll=0;return true;}
        var visible_row=floor((my-96)/34);
        if(visible_row<0||visible_row>=10||my>=432) return true;
        var row=visible_row+controller.script_palette_scroll;
        if(controller.script_palette_category==0&&row>=0&&row<7)
            BattleEditor_WorkspaceBeginDrag(controller,"head",-1,0,"",row,mx,my,28/controller.script_zoom,14/controller.script_zoom);
        else if(controller.script_palette_category==1){
            var kinds=BattleEditor_WorkspacePaletteKinds();
            if(row>=0&&row<array_length(kinds)) BattleEditor_WorkspaceBeginDrag(controller,"new",-1,0,kinds[row],-1,mx,my,28/controller.script_zoom,14/controller.script_zoom);
        }
    }
    return true;
}

function BattleEditor_WorkspaceHit(controller,mx,my) {
    for(var i=array_length(controller.project.script_lists)-1;i>=0;i--){
        var item=controller.project.script_lists[i],z=controller.script_zoom;
        var px=controller.script_pan_x+item.world_x*z,py=controller.script_pan_y+item.world_y*z;
        var header=BattleEditor_WorkspaceHeaderHeight(item)*z;
        if(BattleEditor_PointInRect(mx,my,px,py,px+238*z,py+BattleEditor_WorkspaceHeight(item)*z)){
            var is_header=header>0&&my<py+header;
            return {list_index:i,header:is_header,step_index:is_header?-1:(array_length(item.steps)>0?clamp(floor((my-py-header)/(48*z)),0,array_length(item.steps)-1):-1)};
        }
    }
    return {list_index:-1,header:false,step_index:-1};
}

function BattleEditor_WorkspaceContextLabels(controller) {
    if(controller.script_context_list<0) return ["贴上列表","贴上游离积木","显示 / 收起积木面板"];
    if(controller.script_context_header) return ["复制整张列表","剪下整张列表","贴上整张列表","删除整张列表"];
    return ["复制项目","剪下项目","贴到下方","删除项目","启用 / 禁用项目"];
}

function BattleEditor_WorkspaceRemoveList(project,uid) {
    for(var i=array_length(project.script_lists)-1;i>=0;i--){
        var item=project.script_lists[i];
        if(item.uid==uid){array_delete(project.script_lists,i,1);continue;}
        for(var j=0;j<array_length(item.steps);j++) if(item.steps[j].target_list_uid==uid) item.steps[j].target_list_uid=-1;
    }
}

function BattleEditor_WorkspacePasteList(controller,world_x,world_y) {
    if(is_undefined(controller.script_list_clipboard)) return;
    var copy=BattleEditor_StorageClone(controller.script_list_clipboard),old_uid=copy.uid;
    copy.uid=BattleEditor_AllocateUid(controller.project);copy.name=copy.name+"_复制";copy.world_x=world_x;copy.world_y=world_y;
    for(var i=0;i<array_length(copy.steps);i++){
        copy.steps[i].uid=BattleEditor_AllocateUid(controller.project);
        if(copy.steps[i].target_list_uid==old_uid) copy.steps[i].target_list_uid=copy.uid;
    }
    array_push(controller.project.script_lists,copy);
}

function BattleEditor_WorkspaceContextInput(controller,mx,my,click,right_click) {
    if(right_click){
        controller.script_link_drag=false;controller.script_drag_mode="";
        var hit=BattleEditor_WorkspaceHit(controller,mx,my);
        controller.script_context_open=true;
        controller.script_context_x=clamp(mx,4,446);controller.script_context_y=clamp(my,34,330);
        controller.script_context_world_x=(mx-controller.script_pan_x)/controller.script_zoom;
        controller.script_context_world_y=(my-controller.script_pan_y)/controller.script_zoom;
        controller.script_context_list=hit.list_index;controller.script_context_step=hit.step_index;controller.script_context_header=hit.header;
        return true;
    }
    if(!controller.script_context_open||!click) return false;
    var labels=BattleEditor_WorkspaceContextLabels(controller);
    var row=floor((my-controller.script_context_y)/22);
    if(!BattleEditor_PointInRect(mx,my,controller.script_context_x,controller.script_context_y,controller.script_context_x+190,controller.script_context_y+array_length(labels)*22)){controller.script_context_open=false;return true;}
    if(row<0||row>=array_length(labels)) return true;
    var project=controller.project,li=controller.script_context_list,si=controller.script_context_step;
    if(li<0){
        if(row==0) BattleEditor_WorkspacePasteList(controller,controller.script_context_world_x,controller.script_context_world_y);
        else if(row==1&&array_length(controller.script_clipboard)>0){
            var loose=BattleEditor_NewScriptList(project,controller.script_context_world_x,controller.script_context_world_y,BATTLE_EDITOR_SCRIPT_ENTRY.ORPHAN,"",controller.developer_turn);
            for(var i=0;i<array_length(controller.script_clipboard);i++){var pasted=BattleEditor_StorageClone(controller.script_clipboard[i]);pasted.uid=BattleEditor_AllocateUid(project);array_push(loose.steps,pasted);}
            array_push(project.script_lists,loose);
        }else if(row==2) controller.script_palette_open=!controller.script_palette_open;
    }else if(li<array_length(project.script_lists)){
        var item=project.script_lists[li];
        if(controller.script_context_header){
            if(row==0||row==1) controller.script_list_clipboard=BattleEditor_StorageClone(item);
            if(row==1||row==3) BattleEditor_WorkspaceRemoveList(project,item.uid);
            if(row==2) BattleEditor_WorkspacePasteList(controller,item.world_x+36,item.world_y+36);
        }else if(si>=0&&si<array_length(item.steps)){
            if(row==0||row==1) controller.script_clipboard=[BattleEditor_StorageClone(item.steps[si])];
            if(row==1||row==3) BattleEditor_WorkspaceSpliceSteps(item,si,1,[]);
            if(row==2){
                var payload=[];
                for(var i=0;i<array_length(controller.script_clipboard);i++){var pasted=BattleEditor_StorageClone(controller.script_clipboard[i]);pasted.uid=BattleEditor_AllocateUid(project);array_push(payload,pasted);}
                BattleEditor_WorkspaceSpliceSteps(item,si+1,0,payload);
            }
            if(row==4) item.steps[si].enabled=!(struct_exists(item.steps[si],"enabled")?item.steps[si].enabled:true);
            if(!BattleEditor_WorkspaceHasHeader(item)&&array_length(item.steps)==0) BattleEditor_WorkspaceRemoveList(project,item.uid);
        }
    }
    controller.script_selected_list=-1;controller.script_selected_step=-1;
    controller.script_inspector_pending_list=-1;controller.script_inspector_pending_step=-1;
    BattleEditor_WorkspaceChanged(controller);return true;
}

function BattleEditor_WorkspaceDrawPalette(controller) {
    draw_set_color(make_color_rgb(34,44,62));draw_roundrect_ext(8,36,30,58,5,5,false);
    draw_set_color(c_white);
    var tip=controller.script_palette_open?16:22,back=controller.script_palette_open?22:16;
    draw_line_width(back,42,tip,47,2);draw_line_width(tip,47,back,52,2);
    draw_set_color(make_color_rgb(34,44,62));draw_roundrect_ext(542,8,632,30,5,5,false);
    draw_set_color(c_white);TextTyper_DrawFallback(555,11,"公式 ?");
    if(controller.script_palette_progress<=0) return;
    var palette_matrix=matrix_get(matrix_world);
    var palette_offset=-184*power(1-controller.script_palette_progress,3);
    matrix_set(matrix_world,matrix_multiply(matrix_build(palette_offset,0,0,0,0,0,1,1,1),palette_matrix));
    draw_set_color(make_color_rgb(17,22,31));draw_roundrect_ext(8,62,176,448,7,7,false);
    draw_set_color(make_color_rgb(122,145,172));draw_roundrect_ext(8,62,176,448,7,7,true);
    draw_set_color(controller.script_palette_category==0?make_color_rgb(60,90,115):make_color_rgb(28,34,44));draw_rectangle(14,68,89,90,false);
    draw_set_color(controller.script_palette_category==1?make_color_rgb(60,90,115):make_color_rgb(28,34,44));draw_rectangle(93,68,170,90,false);
    draw_set_color(c_white);TextTyper_DrawFallback(21,71,"事件头");TextTyper_DrawFallback(111,71,"积木");
    var headers=["游戏开始","怪物回合","计时器","玩家受伤","使用物品后","脚本入口","行动项目"];
    var kinds=BattleEditor_WorkspacePaletteKinds(),count=controller.script_palette_category==0?array_length(headers):array_length(kinds);
    for(var row=0;row<10;row++){
        var index=row+controller.script_palette_scroll;if(index>=count) break;
        var row_y=96+row*34,label=controller.script_palette_category==0?headers[index]:BattleEditor_ScriptStepName(kinds[index]);
        var fill=controller.script_palette_category==0?make_color_rgb(45,69,99):BattleEditor_ScriptStepFillColor(kinds[index],false);
        draw_set_color(fill);draw_roundrect_ext(14,row_y,170,row_y+30,6,6,false);
        draw_set_color(c_white);TextTyper_DrawFallbackTransformed(21,row_y+7,label,0.8,0.8,0);
    }
    draw_set_color(make_color_rgb(162,178,195));TextTyper_DrawFallback(18,435,"拖到画布；滚轮翻动");
    matrix_set(matrix_world,palette_matrix);
}

/// Resolve a port against its visible drag position without modifying list data.
/// A negative step index is the header inlet; other indices are step outlets.
function BattleEditor_WorkspacePortPosition(controller,list_data,step_index=-1) {
    var wx=list_data.world_x,wy=list_data.world_y;
    var header=BattleEditor_WorkspaceHeaderHeight(list_data),row=step_index;
    var drag=controller.script_stack_drag;
    if(!is_undefined(drag)&&drag.active&&drag.source_uid==list_data.uid){
        if(drag.mode=="list"){wx=drag.x;wy=drag.y;}
        else if(drag.mode=="tail"&&step_index>=drag.first){
            wx=drag.x;wy=drag.y;header=0;row-=drag.first;
        }
    }
    return {x:controller.script_pan_x+(wx+(step_index<0?0:238))*controller.script_zoom,
        y:controller.script_pan_y+(wy+(step_index<0?17:header+row*48+24))*controller.script_zoom};
}

/// Canvas controls have their own explicit style, not inspector-position rules.
function BattleEditor_WorkspaceDrawRunButton(px,py,zoom) {
    var x1=px+190*zoom,y1=py+4*zoom,x2=px+232*zoom,y2=py+30*zoom;
    draw_set_alpha(1);draw_set_color(make_color_rgb(62,82,105));
    draw_roundrect_ext(x1,y1,x2,y2,5*zoom,5*zoom,false);
    draw_set_color(make_color_rgb(25,33,46));
    draw_roundrect_ext(x1+zoom,y1+zoom,x2-zoom,y2-zoom,4*zoom,4*zoom,false);
    draw_set_color(c_white);
    TextTyper_DrawFallbackTransformed(x1+3*zoom,y1+3*zoom,"运行",zoom,zoom,0);
}

function BattleEditor_WorkspaceDrawDrag(controller) {
    if(is_undefined(controller.script_stack_drag)||!controller.script_stack_drag.active) return;
    var drag=controller.script_stack_drag,z=controller.script_zoom;
    var drag_x=controller.script_pan_x+drag.x*z,drag_y=controller.script_pan_y+drag.y*z;
    var source=BattleEditor_FindScriptList(controller.project,drag.source_uid);
    var count=is_undefined(source)?1:max(1,array_length(source.steps)-drag.first);
    var h=drag.mode=="head"?34:count*48;
    if(drag.mode=="list"&&!is_undefined(source)) h=BattleEditor_WorkspaceHeight(source);
    if(drag.snap.list_uid>=0){
        var sx=controller.script_pan_x+drag.snap.x*z,sy=controller.script_pan_y+drag.snap.y*z;
        draw_set_color(make_color_rgb(70,240,195));draw_line_width(sx,sy,sx+238*z,sy,3);
    }
    draw_set_alpha(0.9);draw_set_color(make_color_rgb(35,49,68));draw_roundrect_ext(drag_x,drag_y,drag_x+238*z,drag_y+h*z,7*z,7*z,false);
    draw_set_alpha(1);draw_set_color(make_color_rgb(110,230,210));draw_roundrect_ext(drag_x,drag_y,drag_x+238*z,drag_y+h*z,7*z,7*z,true);
    if(drag.mode=="head"||drag.mode=="list"){
        draw_set_color(c_white);TextTyper_DrawFallbackTransformed(drag_x+8*z,drag_y+9*z,TextTyper_EllipsisFallback(is_undefined(source)?BattleEditor_ScriptEntryName(drag.entry_kind):source.name,178),z*0.85,z*0.85,0);
    }
    var ghost_header=drag.mode=="list"&&!is_undefined(source)?BattleEditor_WorkspaceHeaderHeight(source):0;
    if(ghost_header>0){
        BattleEditor_WorkspaceDrawRunButton(drag_x,drag_y,z);
        draw_set_color(make_color_rgb(130,190,255));
        draw_circle(drag_x,drag_y+17*z,max(3,4*z),false);
    }
    var rows_to_draw=is_undefined(source)?1:array_length(source.steps)-drag.first;
    if(drag.mode!="head") for(var row=0;row<rows_to_draw;row++){
        var ry=drag_y+(ghost_header+row*48)*z;if(ry>480)break;if(ry+48*z<32)continue;
        var label=is_undefined(source)?BattleEditor_ScriptStepName(drag.kind):BattleEditor_ScriptStepName(source.steps[drag.first+row].kind);
        draw_set_color(c_white);TextTyper_DrawFallbackTransformed(drag_x+8*z,ry+9*z,label,z*0.85,z*0.85,0);
        if(!is_undefined(source)&&source.steps[drag.first+row].kind=="start_list"){
            draw_set_color(make_color_rgb(115,190,255));
            draw_circle(drag_x+238*z,ry+24*z,max(3,4*z),false);
        }
    }
}

/// Presentation-only split: -1 hides a whole moving stack, otherwise the
/// returned prefix remains at the origin. Source data stays intact until drop.
function BattleEditor_WorkspaceVisibleCount(list_data,drag) {
    var count=array_length(list_data.steps);
    if(is_undefined(drag)||!drag.active||drag.source_uid!=list_data.uid) return count;
    if(drag.mode=="list") return -1;
    if(drag.mode!="tail") return count;
    var prefix=clamp(drag.first,0,count);
    return prefix==0&&!BattleEditor_WorkspaceHasHeader(list_data)?-1:prefix;
}

function BattleEditor_NewScriptList(project,world_x,world_y,entry_kind=BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN,entry_value=1,timeline_turn=1) {
    var list_uid=BattleEditor_AllocateUid(project);
    return {
        uid:list_uid,
        name:BattleEditor_NextScriptListName(project),
        world_x:world_x,
        world_y:world_y,
        entry_kind:entry_kind,
        entry_value:entry_value,
        turn:max(1,round(real(timeline_turn))),
        steps:[]
    };
}

function BattleEditor_ScriptStepName(kind) {
    switch(kind){
        case "control_object":return "控制对象";
        case "create_object":return "创建对象";
        case "wait":return "等待";
        case "start_list":return "节点连接";
        case "builtin_action":return "内建攻击函数";
        case "screen_control":return "画面 / 镜头 / 滤镜";
        case "play_sound":return "播放音效";
        case "enemy_appearance":return "切换敌人贴图 / 动画";
        case "get_value":return "读取对象数值";
        case "run_script":return "旧脚本（已禁用）";
        case "set_variable":return "变量 / 公式";
        case "condition":return "条件判断";
        case "repeat":return "循环范围";
    }
    return "控制对象";
}

function BattleEditor_ScriptStepFillColor(kind,selected=false) {
    switch(kind){
        case "control_object":return selected?make_color_rgb(26,66,96):make_color_rgb(15,39,57);
        case "create_object":return selected?make_color_rgb(34,82,73):make_color_rgb(19,47,42);
        case "builtin_action":return selected?make_color_rgb(91,55,20):make_color_rgb(53,32,14);
        case "screen_control":return selected?make_color_rgb(68,40,93):make_color_rgb(39,24,54);
        case "play_sound":return selected?make_color_rgb(87,39,72):make_color_rgb(50,23,42);
        case "enemy_appearance":return selected?make_color_rgb(36,78,92):make_color_rgb(20,45,54);
        case "set_variable":case "get_value":return selected?make_color_rgb(25,77,69):make_color_rgb(15,44,40);
        case "condition":return selected?make_color_rgb(91,38,42):make_color_rgb(52,23,26);
        case "wait":return selected?make_color_rgb(61,62,86):make_color_rgb(35,36,50);
        case "repeat":return selected?make_color_rgb(82,69,24):make_color_rgb(47,40,15);
        case "start_list":return selected?make_color_rgb(28,70,81):make_color_rgb(17,41,47);
        case "run_script":return selected?make_color_rgb(58,58,58):make_color_rgb(30,30,30);
    }
    return selected?make_color_rgb(54,58,66):make_color_rgb(18,20,26);
}

function BattleEditor_ScriptStepBorderColor(kind,selected=false) {
    if(selected) return c_yellow;
    switch(kind){
        case "control_object":return make_color_rgb(80,174,235);
        case "create_object":return make_color_rgb(87,218,181);
        case "builtin_action":return make_color_rgb(244,158,67);
        case "screen_control":return make_color_rgb(182,117,239);
        case "play_sound":return make_color_rgb(236,112,194);
        case "enemy_appearance":return make_color_rgb(92,205,226);
        case "set_variable":case "get_value":return make_color_rgb(72,207,182);
        case "condition":return make_color_rgb(239,92,99);
        case "wait":return make_color_rgb(157,161,205);
        case "repeat":return make_color_rgb(231,197,73);
        case "start_list":return make_color_rgb(84,198,222);
        case "run_script":return make_color_rgb(128,128,128);
    }
    return make_color_rgb(90,98,112);
}

function BattleEditor_WaitModeName(wait_mode) {
    return round(real(wait_mode))==1?"等上一个步骤执行完":"固定帧数";
}

/// Audio resources are immutable during a Runner session unless the project's
/// imported-resource list changes. Cache the complete selector array by that
/// list: the music page used to enumerate every GameMaker asset, probe every
/// imported file and sort the result on every Draw frame.
function BattleEditor_AudioOptionsCached(project=undefined,sound_effects_only=true) {
    var cache_signature=sound_effects_only?"sfx":"music";
    var imported=[];
    if(!is_undefined(project)&&is_struct(project)&&struct_exists(project,"resources")&&is_struct(project.resources)&&struct_exists(project.resources,"audio")&&is_array(project.resources.audio)){
        imported=project.resources.audio;
        for(var signature_index=0;signature_index<array_length(imported);signature_index++) cache_signature+="|"+string(imported[signature_index].path);
    }
    if(!variable_global_exists("battle_editor_audio_options_cache")||!is_struct(global.battle_editor_audio_options_cache)){
        global.battle_editor_audio_options_cache={};
        global.battle_editor_audio_options_cache_count=0;
    }
    if(struct_exists(global.battle_editor_audio_options_cache,cache_signature)) return global.battle_editor_audio_options_cache[$ cache_signature];

    var result=[];
    var seen={};
    var sound_assets=asset_get_ids(asset_sound);
    for(var asset_index=0;asset_index<array_length(sound_assets);asset_index++){
        var sound_name=audio_get_name(sound_assets[asset_index]);
        if(sound_effects_only&&string_pos("snd",string_lower(sound_name))!=1) continue;
        var bundled_key="a|"+string_lower(sound_name);
        if(!struct_exists(seen,bundled_key)){seen[$ bundled_key]=true;array_push(result,sound_name);}
    }
    for(var imported_index=0;imported_index<array_length(imported);imported_index++){
        var imported_path=string(imported[imported_index].path);
        if(!file_exists(imported_path)) continue;
        var imported_key="a|"+string_lower(imported_path);
        if(!struct_exists(seen,imported_key)){seen[$ imported_key]=true;array_push(result,imported_path);}
    }
    array_sort(result,true);
    if(global.battle_editor_audio_options_cache_count>=64){global.battle_editor_audio_options_cache={};global.battle_editor_audio_options_cache_count=0;}
    global.battle_editor_audio_options_cache[$ cache_signature]=result;
    global.battle_editor_audio_options_cache_count+=1;
    return result;
}

function BattleEditor_SoundOptions(project=undefined) {
    return BattleEditor_AudioOptionsCached(project,true);
}

/// Formal music may use any bundled GameMaker audio asset. Workspace sound
/// effects deliberately keep their snd... filter, but a BGM selector must not
/// hide resources such as shop_theme merely because of their naming style.
function BattleEditor_MusicOptions(project=undefined) {
    return BattleEditor_AudioOptionsCached(project,false);
}

function BattleEditor_SoundOptionCaption(sound_name,project=undefined) {
    var value=string(sound_name);
    if(file_exists(value)&&!is_undefined(project)&&is_struct(project)&&struct_exists(project,"resources")&&struct_exists(project.resources,"audio")){
        for(var imported_index=0;imported_index<array_length(project.resources.audio);imported_index++) if(string_lower(string(project.resources.audio[imported_index].path))==string_lower(value)) return "导入 / "+string(project.resources.audio[imported_index].name);
    }
    return file_exists(value)?("导入 / "+filename_name(value)):value;
}

function BattleEditor_ResolveSoundAsset(sound_name) {
    var value=string_trim(string(sound_name));
    var bundled_asset=asset_get_index(value);
    if(bundled_asset>=0&&audio_exists(bundled_asset)) return bundled_asset;
    if(!file_exists(value)) return -1;
    if(!variable_global_exists("battle_editor_external_audio_cache")||!is_array(global.battle_editor_external_audio_cache)) global.battle_editor_external_audio_cache=[];
    for(var cache_index=0;cache_index<array_length(global.battle_editor_external_audio_cache);cache_index++){
        var cached=global.battle_editor_external_audio_cache[cache_index];
        if(string_lower(cached.path)==string_lower(value)&&audio_exists(cached.asset)) return cached.asset;
    }
    var streamed=audio_create_stream(value);
    if(audio_exists(streamed)) array_push(global.battle_editor_external_audio_cache,{path:value,asset:streamed});
    return streamed;
}

function BattleEditor_VoiceSoundAsset(voice_id) {
    switch(clamp(round(real(voice_id)),-1,3)){
        case 0:return snd_text_voice_default;
        case 1:return snd_text_voice_typer;
        case 2:return snd_text_voice_sans;
        case 3:return snd_text_voice_toriel;
    }
    return -1;
}

function BattleEditor_AudioPreviewStop(controller) {
    if(!instance_exists(controller)) return false;
    if(variable_instance_exists(controller,"audio_preview_handle")&&controller.audio_preview_handle>=0)
        audio_stop_sound(controller.audio_preview_handle);
    controller.audio_preview_handle=-1;
    controller.audio_preview_name="";
    controller.audio_preview_source="";
    return true;
}

function BattleEditor_AudioPreviewToggle(controller,sound_asset,sound_name="",source_key="") {
    if(!instance_exists(controller)) return false;
    if(controller.audio_preview_handle>=0&&audio_is_playing(controller.audio_preview_handle)&&controller.audio_preview_source==source_key){
        BattleEditor_AudioPreviewStop(controller);
        controller.status_text="已停止音效预览";
        return false;
    }
    BattleEditor_AudioPreviewStop(controller);
    if(!audio_exists(sound_asset)){
        controller.status_text="这个选项没有可播放的音效";
        return false;
    }
    controller.audio_preview_handle=audio_play_sound(sound_asset,100,false);
    controller.audio_preview_name=sound_name==""?audio_get_name(sound_asset):string(sound_name);
    controller.audio_preview_source=string(source_key);
    controller.status_text="正在预览："+controller.audio_preview_name;
    return controller.audio_preview_handle>=0;
}

function BattleEditor_AudioPreviewToggleNamed(controller,sound_name,source_key="") {
    var sound_asset=BattleEditor_ResolveSoundAsset(sound_name);
    return BattleEditor_AudioPreviewToggle(controller,sound_asset,string(sound_name),source_key);
}

function BattleEditor_AudioPreviewToggleVoice(controller,voice_id,source_key="") {
    return BattleEditor_AudioPreviewToggle(controller,BattleEditor_VoiceSoundAsset(voice_id),BattleEditor_VoiceName(voice_id),source_key);
}

function BattleEditor_SoundTimingName(timing) {
    return round(real(timing))==1?"步骤执行结束时":"步骤执行时";
}

/// Stage a Workspace list/step selection without replacing the Inspector text
/// in the same frame.  Repeated clicks merely replace the pending destination;
/// the one shared card finishes retracting before the latest choice expands.
function BattleEditor_RequestScriptSelection(controller,list_index,step_index) {
    if(!instance_exists(controller)) return false;
    list_index=round(real(list_index));
    step_index=round(real(step_index));
    if(controller.script_inspector_anim_phase<0){
        controller.script_inspector_pending_list=list_index;
        controller.script_inspector_pending_step=step_index;
        return true;
    }
    if(controller.script_selected_list==list_index&&controller.script_selected_step==step_index) return false;
    controller.script_inspector_pending_list=list_index;
    controller.script_inspector_pending_step=step_index;
    if(controller.script_selected_list>=0){
        controller.script_inspector_anim_phase=-1;
        controller.script_inspector_anim_progress=max(0.15,controller.script_inspector_anim_progress);
    }else{
        controller.script_selected_list=list_index;
        controller.script_selected_step=step_index;
        controller.script_inspector_last_list=list_index;
        controller.script_inspector_last_step=step_index;
        controller.script_inspector_anim_phase=list_index>=0?1:0;
        controller.script_inspector_anim_progress=0;
    }
    return true;
}

function BattleEditor_IsFormulaField(field) {
    return string_pos("script_action_param_",field)==1||string_pos("script_screen_param_",field)==1||string_pos("script_physics_",field)==1||string_pos("script_create_formula_",field)==1
        ||field=="script_value"||field=="script_position_x"||field=="script_position_y"||field=="script_position_angle"||field=="script_board_transform_width"||field=="script_board_transform_height"||field=="script_orbit_center_x"||field=="script_orbit_center_y"
        ||string_pos("script_board_shape_",field)==1
        ||field=="script_create_x"||field=="script_create_y"||field=="script_create_angle"||field=="script_create_lifetime"||field=="script_create_size"
        ||field=="script_create_width"||field=="script_create_height"||field=="script_create_board_rotate"||field=="script_create_board_depth"
        ||field=="script_create_board_up"||field=="script_create_board_down"||field=="script_create_board_left"||field=="script_create_board_right"
        ||field=="script_create_board_radius_x"||field=="script_create_board_radius_y"||field=="script_create_board_triangle_size"
        ||field=="script_create_board_vertex_x"||field=="script_create_board_vertex_y"
        ||field=="script_warning_angle"||field=="script_aim_move_speed"||field=="script_dialogue_offset_x"||field=="script_dialogue_offset_y"
        ||field=="script_expression"||field=="script_condition_left"||field=="script_condition_right"||field=="script_repeat_count"||field=="script_repeat_interval";
}

function BattleEditor_SetStepFormulaField(step,field,value) {
    value=string(value);
    if(string_pos("script_create_formula_",field)==1){
        BattleEditor_WorkspaceCreateNormalizeTemplate(step);
        return BattleEditor_WorkspaceTemplateSet(step.create_template,string_delete(field,1,string_length("script_create_formula_")),value);
    }
    if(field=="script_value") step.value=value;
    else if(field=="script_position_x") step.position_x=value;
    else if(field=="script_position_y") step.position_y=value;
    else if(field=="script_position_angle") step.position_angle=value;
    else if(field=="script_board_transform_width") step.board_transform_width=value;
    else if(field=="script_board_transform_height") step.board_transform_height=value;
    else if(field=="script_board_shape_width") step.board_shape_width=value;
    else if(field=="script_board_shape_height") step.board_shape_height=value;
    else if(field=="script_board_shape_radius_x") step.board_shape_radius_x=value;
    else if(field=="script_board_shape_radius_y") step.board_shape_radius_y=value;
    else if(field=="script_board_shape_triangle_width") step.board_shape_triangle_width=value;
    else if(field=="script_board_shape_triangle_height") step.board_shape_triangle_height=value;
    else if(field=="script_orbit_center_x") step.orbit_center_x=value;
    else if(field=="script_orbit_center_y") step.orbit_center_y=value;
    else if(field=="script_warning_angle") step.warning_angle=value;
    else if(field=="script_dialogue_offset_x") step.dialogue_offset_x=value;
    else if(field=="script_dialogue_offset_y") step.dialogue_offset_y=value;
    else if(field=="script_physics_direction") step.physics_direction=value;
    else if(field=="script_physics_speed") step.physics_speed=value;
    else if(field=="script_physics_acceleration") step.physics_acceleration=value;
    else if(field=="script_physics_curve_speed") step.physics_curve_speed=value;
    else if(field=="script_physics_rotation_speed") step.physics_rotation_speed=value;
    else if(field=="script_aim_move_speed") step.aim_move_speed=value;
    else if(field=="script_create_x") step.create_x=value;
    else if(field=="script_create_y") step.create_y=value;
    else if(field=="script_create_angle") step.create_angle=value;
    else if(field=="script_create_lifetime") step.create_lifetime=value;
    else if(field=="script_create_size") step.create_size=value;
    else if(field=="script_create_width") step.create_width=value;
    else if(field=="script_create_height") step.create_height=value;
    else if(field=="script_create_board_up") step.create_board_up=value;
    else if(field=="script_create_board_down") step.create_board_down=value;
    else if(field=="script_create_board_left") step.create_board_left=value;
    else if(field=="script_create_board_right") step.create_board_right=value;
    else if(field=="script_create_board_radius_x") step.create_board_radius_x=value;
    else if(field=="script_create_board_radius_y") step.create_board_radius_y=value;
    else if(field=="script_create_board_triangle_size") step.create_board_triangle_size=value;
    else if(field=="script_create_board_vertex_x"){
        step.point_index=clamp(round(real(step.point_index)),0,array_length(step.points)-1);
        step.points[step.point_index][0]=value;
    }
    else if(field=="script_create_board_vertex_y"){
        step.point_index=clamp(round(real(step.point_index)),0,array_length(step.points)-1);
        step.points[step.point_index][1]=value;
    }
    else if(field=="script_create_board_rotate") step.create_board_rotate=value;
    else if(field=="script_create_board_depth") step.create_board_depth=value;
    else if(field=="script_expression") step.expression=value;
    else if(field=="script_condition_left") step.condition_left=value;
    else if(field=="script_condition_right") step.condition_right=value;
    else if(field=="script_repeat_count") step.repeat_count=value;
    else if(field=="script_repeat_interval") step.repeat_interval=value;
    else if(string_pos("script_action_param_",field)==1){
        var action_index=real(string_delete(field,1,string_length("script_action_param_")));
        step.action_arguments=BattleEditor_ActionArgumentsSet(step.action_arguments,action_index,value,BattleEditor_BuiltinActionDefaults(step.action_name));
    }else if(string_pos("script_screen_param_",field)==1){
        var screen_index=real(string_delete(field,1,string_length("script_screen_param_")));
        step.screen_arguments=BattleEditor_ActionArgumentsSet(step.screen_arguments,screen_index,value,BattleEditor_ScreenActionDefaults(step.screen_action));
    }else return false;
    return true;
}

function BattleEditor_GetStepFormulaField(step,field) {
    if(string_pos("script_create_formula_",field)==1){
        BattleEditor_WorkspaceCreateNormalizeTemplate(step);
        return string(BattleEditor_WorkspaceTemplateGet(step.create_template,string_delete(field,1,string_length("script_create_formula_"))));
    }
    if(field=="script_value") return string(step.value);
    if(field=="script_position_x") return string(step.position_x);
    if(field=="script_position_y") return string(step.position_y);
    if(field=="script_position_angle") return string(step.position_angle);
    if(field=="script_board_transform_width") return string(step.board_transform_width);
    if(field=="script_board_transform_height") return string(step.board_transform_height);
    if(field=="script_board_shape_width") return string(step.board_shape_width);
    if(field=="script_board_shape_height") return string(step.board_shape_height);
    if(field=="script_board_shape_radius_x") return string(step.board_shape_radius_x);
    if(field=="script_board_shape_radius_y") return string(step.board_shape_radius_y);
    if(field=="script_board_shape_triangle_width") return string(step.board_shape_triangle_width);
    if(field=="script_board_shape_triangle_height") return string(step.board_shape_triangle_height);
    if(field=="script_orbit_center_x") return string(step.orbit_center_x);
    if(field=="script_orbit_center_y") return string(step.orbit_center_y);
    if(field=="script_physics_direction") return string(step.physics_direction);
    if(field=="script_physics_speed") return string(step.physics_speed);
    if(field=="script_physics_acceleration") return string(step.physics_acceleration);
    if(field=="script_physics_curve_speed") return string(step.physics_curve_speed);
    if(field=="script_physics_rotation_speed") return string(step.physics_rotation_speed);
    if(field=="script_aim_move_speed") return string(step.aim_move_speed);
    if(field=="script_create_x") return string(step.create_x);
    if(field=="script_create_y") return string(step.create_y);
    if(field=="script_create_angle") return string(step.create_angle);
    if(field=="script_create_lifetime") return string(step.create_lifetime);
    if(field=="script_create_size") return string(step.create_size);
    if(field=="script_create_width") return string(step.create_width);
    if(field=="script_create_height") return string(step.create_height);
    if(field=="script_create_board_up") return string(step.create_board_up);
    if(field=="script_create_board_down") return string(step.create_board_down);
    if(field=="script_create_board_left") return string(step.create_board_left);
    if(field=="script_create_board_right") return string(step.create_board_right);
    if(field=="script_create_board_radius_x") return string(step.create_board_radius_x);
    if(field=="script_create_board_radius_y") return string(step.create_board_radius_y);
    if(field=="script_create_board_triangle_size") return string(step.create_board_triangle_size);
    if(field=="script_create_board_vertex_x") return array_length(step.points)>0?string(step.points[clamp(round(real(step.point_index)),0,array_length(step.points)-1)][0]):"0";
    if(field=="script_create_board_vertex_y") return array_length(step.points)>0?string(step.points[clamp(round(real(step.point_index)),0,array_length(step.points)-1)][1]):"0";
    if(field=="script_create_board_rotate") return string(step.create_board_rotate);
    if(field=="script_create_board_depth") return string(step.create_board_depth);
    if(field=="script_expression") return string(step.expression);
    if(field=="script_condition_left") return string(step.condition_left);
    if(field=="script_condition_right") return string(step.condition_right);
    if(field=="script_repeat_count") return string(step.repeat_count);
    if(field=="script_repeat_interval") return string(step.repeat_interval);
    if(string_pos("script_action_param_",field)==1){
        var action_index=real(string_delete(field,1,string_length("script_action_param_")));
        return BattleEditor_ActionArgumentText(step.action_arguments,action_index,BattleEditor_BuiltinActionDefaults(step.action_name));
    }
    if(string_pos("script_screen_param_",field)==1){
        var screen_index=real(string_delete(field,1,string_length("script_screen_param_")));
        return BattleEditor_ActionArgumentText(step.screen_arguments,screen_index,BattleEditor_ScreenActionDefaults(step.screen_action));
    }
    return "";
}

/// Safe high-level attack constructors extracted from reusable games.sb3
/// patterns. These are IDs plus editable schemas, never arbitrary assets.
function BattleEditor_BuiltinActionOptions() {
    return [
        {id:"bone_orbit",name:"椭圆旋转骨阵",labels:"中心 X;中心 Y;横向半径;纵向半径;骨头数量;起始角度;每帧转速;朝向角度偏移;骨头长度;进场帧数;维持（-1=本回合）;退场帧数;伤害颜色;绘制层级",defaults:"320;240;110;70;12;0;1.5;0;44;20;120;20;0;1"},
        {id:"bone_wave",name:"波浪骨阵",labels:"排列中心 X;排列中心 Y;排列方向;覆盖范围;骨头数量;骨头长度;自身摆动半径;正弦速度;生命周期（-1=回合）;伤害颜色;绘制层级",defaults:"320;240;0;260;12;120;65;4;180;0;0"},
        {id:"bone_corridor",name:"长廊骨",labels:"移动方向;起点 X;起点 Y;生成点数量（每点一对）;前后间距;通道半宽;骨头长度;生成中心最小值（横向 Y / 纵向 X）;生成中心最大值（横向 Y / 纵向 X）;每点正弦相位增量;移动速度;生命周期（-1=回合）;伤害颜色;绘制层级",defaults:"0;-40;240;12;60;55;120;190;290;30;3;260;0;0"},
        {id:"bone_physics",name:"物理散射（固定重力算法）",labels:"生成中心 X;生成中心 Y;对象数量;随机 X 动量下限;随机 X 动量上限;随机 Y 动量下限;随机 Y 动量上限;随机角动量下限;随机角动量上限;随机长度下限;随机长度上限（上下限相同=固定值）;生命周期（负数=本回合一直存在）;伤害颜色;绘制层级",defaults:"320;240;18;-3;3;-5;-2;-8;8;20;70;180;0;1"},
        {id:"bone_3d",name:"3D 骨",labels:"中心 X;中心 Y;立体形状;X 轴角度;Y 轴角度;Z 轴角度;X 轴转速;Y 轴转速;Z 轴转速;X 尺寸;Y 尺寸;Z 尺寸;水平速度;垂直速度;生命周期（-1=回合）;边缘留白;世界 Z;透视距离;伤害颜色;伤害数值;绘制层级",defaults:"320;240;0;20;25;0;0.5;0.8;0.25;40;40;40;0;0;180;8;0;420;0;2;1"},
        {id:"bone_4d",name:"4D 骨 / 超立方体",labels:"中心 X;中心 Y;世界 Z;X 轴角度;Y 轴角度;Z 轴角度;XW 平面角度;YW 平面角度;ZW 平面角度;X 轴转速;Y 轴转速;Z 轴转速;XW 平面转速;YW 平面转速;ZW 平面转速;X 尺寸;Y 尺寸;Z 尺寸;W 尺寸;生命周期（-1=回合）;边缘留白;3D 透视距离;4D 透视距离;伤害颜色;伤害数值;绘制层级",defaults:"320;240;0;20;25;0;0;0;0;0.5;0.8;0.25;0.4;0.6;0.3;40;40;40;40;180;8;420;260;0;2;1"},
        {id:"gb_pinwheel",name:"GB 风车",labels:"中心 X;中心 Y;半径 X;半径 Y;数量;起始角度;每个增加角度;朝向角度偏移;生成间隔（0 为同时）;实际发射间隔（0 为同时）;发射前等待帧数;光束时长;进场帧数;颜色",defaults:"320;240;130;90;8;0;45;0;0;0;35;50;35;0"},
        {id:"bone_wall",name:"骨墙",labels:"目标中心 X;目标中心 Y;宽度;间距;目标高度或中心半径;骨头长度;进退速度;停留（-1=本回合）;伤害颜色;绘制层级",defaults:"320;240;24;14;70;640;7;90;0;0"},
        {id:"bone_function_path",name:"函数轨迹",labels:"起始点 X;起始点 Y;X(自变量) 偏移公式;Y(自变量) 偏移公式;自变量起始值;自变量结束值;移动/生命周期（-1=回合）;对象长度;固定角度;朝向方式;伤害颜色;绘制层级;局部自变量名称",defaults:"X;Y;t;sin(t)*40;0;360;180;44;0;1;0;1"},
        {id:"board_shape",name:"平滑切换战斗框形状",labels:"目标形状;过渡帧数",defaults:"1;30"}
    ];
}

function BattleEditor_ScreenActionOptions() {
    return [
        {id:"camera_set",name:"镜头位置 / 缩放 / 旋转",labels:"中心X;中心Y;缩放X;缩放Y;旋转角;过渡帧",defaults:"320;240;1;1;0;30"},
        {id:"camera_sine",name:"正弦晃屏",labels:"X振幅;Y振幅;角度振幅;速度;时长",defaults:"8;4;3;6;180"},
        {id:"camera_shake",name:"镜头震动",labels:"X 强度;Y 强度;X 抖动间隔;Y 抖动间隔;随机方向;X 衰减;Y 衰减;启用拖影",defaults:"8;8;1;1;1;0.35;0.35;0"},
        {id:"effect_hue",name:"滤镜 / 色相",labels:"色相角（度）",defaults:"0"},
        {id:"effect_saturation",name:"滤镜 / 饱和度",labels:"饱和度倍率",defaults:"1"},
        {id:"effect_brightness",name:"滤镜 / 亮度",labels:"亮度偏移",defaults:"0"},
        {id:"effect_contrast",name:"滤镜 / 对比度",labels:"对比度倍率",defaults:"1"},
        {id:"effect_grayscale",name:"滤镜 / 灰度",labels:"灰度强度（0~1）",defaults:"0"},
        {id:"effect_invert",name:"滤镜 / 反色",labels:"反色强度（0~1）",defaults:"0"},
        {id:"effect_glitch_amount",name:"滤镜 / 故障",labels:"故障强度",defaults:"0.35"},
        {id:"effect_chromatic",name:"滤镜 / 色差",labels:"色差像素",defaults:"3"},
        {id:"effect_scanline",name:"滤镜 / 扫描线",labels:"扫描线强度（0~1）",defaults:"0.15"},
        {id:"effect_wave",name:"滤镜 / 画面波浪",labels:"波浪强度",defaults:"1.5"},
        {id:"effect_vignette_amount",name:"滤镜 / 暗角",labels:"暗角强度（0~1）",defaults:"0.35"},
        {id:"effect_pixelate",name:"滤镜 / 像素化",labels:"像素块大小",defaults:"1"},
        {id:"effect_blur",name:"模糊",labels:"迭代次数;横向强度;纵向强度",defaults:"3;1;1"},
        {id:"screen_reset",name:"重置镜头与效果",labels:"无参数",defaults:""}
    ];
}

function BattleEditor_ActionOption(options,action_id) {
    for(var i=0;i<array_length(options);i++) if(options[i].id==action_id) return options[i];
    return options[0];
}

function BattleEditor_BuiltinActionName(action_id) {return BattleEditor_ActionOption(BattleEditor_BuiltinActionOptions(),action_id).name;}
function BattleEditor_BuiltinActionLabels(action_id) {return BattleEditor_ActionOption(BattleEditor_BuiltinActionOptions(),action_id).labels;}
function BattleEditor_BuiltinActionDefaults(action_id) {return BattleEditor_ActionOption(BattleEditor_BuiltinActionOptions(),action_id).defaults;}
function BattleEditor_BuiltinActionCanFollow(action_id) {return action_id!="board_shape";}

function BattleEditor_ObjectPaletteCategoryName(category) {
    switch(clamp(round(real(category)),0,5)){
        case 0:return "内建攻击";
        case 1:return "自定义弹幕";
        case 2:return "装饰";
        case 3:return "战斗框";
        case 4:return "打字机";
        case 5:return "蓝魂平台";
    }
    return "内建攻击";
}

function BattleEditor_WorkspaceCreateOptions(category) {
    switch(clamp(round(real(category)),0,5)){
        case 0:return [
            {id:"bone",name:"骨头"},{id:"bone_spike",name:"骨刺"},{id:"gb",name:"GB"},{id:"true_knife",name:"真刀"},{id:"slash",name:"斩击"},
            {id:"friendship_pellet",name:"友谊颗粒"},{id:"fireball",name:"火球"},{id:"spear",name:"长矛"},{id:"trident",name:"三叉戟"},
            {id:"knife",name:"刀子"},{id:"bone_3d",name:"3D 骨"},{id:"bone_4d",name:"4D 骨"}
        ];
        case 1:return [{id:"custom_sprite",name:"自定义弹幕"}];
        case 2:return [{id:"decoration",name:"装饰"}];
        case 3:return [{id:"board_add",name:"加框"},{id:"board_subtract",name:"减框"}];
        case 4:return [{id:"typewriter",name:"打字机"}];
        case 5:return [{id:"platform",name:"蓝魂平台"}];
    }
    return [{id:"bone",name:"骨头"}];
}

function BattleEditor_WorkspaceCreatePresetName(preset) {
    for(var category=0;category<6;category++){
        var options=BattleEditor_WorkspaceCreateOptions(category);
        for(var i=0;i<array_length(options);i++) if(options[i].id==preset) return options[i].name;
    }
    return "骨头";
}

function BattleEditor_WorkspaceCreateApplyPresetDefaults(step,preset) {
    step.create_preset=preset;
    step.create_angle=(preset=="bone"||preset=="bone_spike")?"90":"0";
    step.create_lifetime="-1";
    step.create_size=(preset=="platform"||preset=="bone"||preset=="bone_spike")?"48":((preset=="bone_3d"||preset=="bone_4d")?"40":"1");
    if(preset=="board_add"||preset=="board_subtract"){
        step.create_width="60";
        step.create_height="60";
        step.create_board_shape=0;
        step.create_board_up="30";step.create_board_down="30";
        step.create_board_left="30";step.create_board_right="30";
        step.create_board_radius_x="30";step.create_board_radius_y="30";
        step.create_board_triangle_size="40";
        step.points=[["-40","-40"],["40","-40"],["40","40"],["-40","40"]];
        step.point_index=0;
        step.create_board_rotate="0";
        step.create_board_depth=preset=="board_subtract"?"-10":"10";
    }
    step.create_damage_type=0;
    step.create_layer_mode=(preset=="gb"||preset=="true_knife"||preset=="slash"||preset=="bone_3d"||preset=="bone_4d"||preset=="decoration")?BATTLE_EDITOR_LAYER.OUTSIDE:BATTLE_EDITOR_LAYER.IN_BOARD;
    step.create_template=BattleEditor_WorkspaceCreateDefaultData(preset);
    step.create_animation_frame_index=0;
    return step;
}

function BattleEditor_WorkspaceCreateSizeName(preset) {
    if(preset=="bone"||preset=="bone_spike") return "长度";
    if(preset=="platform") return "宽度";
    if(preset=="bone_3d"||preset=="bone_4d") return "尺寸";
    return "缩放";
}

function BattleEditor_WorkspaceCreateTargetType(preset) {
    if(preset=="bone"||preset=="bone_spike") return "bone";
    if(preset=="gb") return "gb";
    if(preset=="true_knife") return "true_knife";
    if(preset=="slash") return "slash";
    if(preset=="bone_3d") return "bone_3d";
    if(preset=="bone_4d") return "bone_4d";
    if(preset=="platform") return "platform";
    if(preset=="typewriter") return "typewriter";
    if(preset=="decoration") return "decoration";
    if(preset=="board_add"||preset=="board_subtract") return "board";
    return "sprite_hazard";
}

function BattleEditor_WorkspaceCreateDefaultData(preset) {
    var data;
    if(preset=="bone"||preset=="bone_spike") data=BattleEditor_NewBone(320,240,0,preset=="bone_spike");
    else if(preset=="gb") data=BattleEditor_NewGB(320,240,0);
    else if(preset=="true_knife"||preset=="slash") data=BattleEditor_NewWaveHazard(320,240,preset,0);
    else if(preset=="bone_3d"||preset=="bone_4d") data=BattleEditor_NewSolidBone(320,240,preset,0);
    else if(preset=="platform") data=BattleEditor_NewPlatform(320,240,0);
    else if(preset=="typewriter") data=BattleEditor_NewTypewriter(320,240,0);
    else if(preset=="decoration") data=BattleEditor_NewDecoration(320,240,0);
    else if(preset=="custom_sprite") data=BattleEditor_NewCustomSpriteHazard(320,240,0);
    else data=BattleEditor_NewBuiltinSpriteHazard(320,240,preset,0);
    data.uid=-1;
    data.control_id="";
    // Workspace-created movable objects follow the main frame by default.
    // Scene-canvas defaults are untouched because this constructor is used
    // only by the Workspace Create Object step.
    if(preset!="board_add"&&preset!="board_subtract"){
        data.follow=true;
        data.follow_target_uid=-1;
    }
    if(struct_exists(data,"clipped")){
        if(!struct_exists(data,"clip_mode")) data.clip_mode="all";
        if(!struct_exists(data,"clip_frame_uids")) data.clip_frame_uids=[];
        if(!struct_exists(data,"clipped_collision")) data.clipped_collision=true;
    }
    return data;
}

function BattleEditor_StructApplyMissingDefaults(target,defaults) {
    if(!is_struct(target)||!is_struct(defaults)) return target;
    var names=variable_struct_get_names(defaults);
    for(var i=0;i<array_length(names);i++){
        var key=names[i];
        var default_value=variable_struct_get(defaults,key);
        if(!variable_struct_exists(target,key)) variable_struct_set(target,key,json_parse(json_stringify(default_value)));
        else{
            var target_value=variable_struct_get(target,key);
            if(is_struct(target_value)&&is_struct(default_value)) BattleEditor_StructApplyMissingDefaults(target_value,default_value);
        }
    }
    return target;
}

function BattleEditor_WorkspaceCreateNormalizeTemplate(step) {
    var defaults=BattleEditor_WorkspaceCreateDefaultData(step.create_preset);
    if(!struct_exists(step,"create_template")||!is_struct(step.create_template)){
        step.create_template=defaults;
        // Exact one-time migration from the former reduced Workspace fields.
        step.create_template.transform.x=step.create_x;
        step.create_template.transform.y=step.create_y;
        step.create_template.transform.angle=step.create_angle;
        if(struct_exists(step.create_template,"duration")) step.create_template.duration=step.create_lifetime;
        if(struct_exists(step.create_template,"layer_mode")) step.create_template.layer_mode=step.create_layer_mode;
        if(struct_exists(step.create_template,"damage_profile")) step.create_template.damage_profile.type=step.create_damage_type;
        if(step.create_preset=="bone"||step.create_preset=="bone_spike") step.create_template.length=step.create_size;
        else if(step.create_preset=="platform") step.create_template.width=step.create_size;
        else if(step.create_preset=="bone_3d"||step.create_preset=="bone_4d"){
            step.create_template.size_x=step.create_size;step.create_template.size_y=step.create_size;step.create_template.size_z=step.create_size;
            if(step.create_preset=="bone_4d") step.create_template.size_w=step.create_size;
        }else if(struct_exists(step.create_template,"transform")){
            step.create_template.transform.scale_x=step.create_size;
            step.create_template.transform.scale_y=step.create_size;
        }
    }else BattleEditor_StructApplyMissingDefaults(step.create_template,defaults);
    if(struct_exists(step.create_template,"visual_tint")) BattleEditor_SetVisualTintMode(step.create_template,step.create_template.visual_tint.mode);
    if(!struct_exists(step,"create_animation_frame_index")) step.create_animation_frame_index=0;
    return step.create_template;
}

function BattleEditor_WorkspaceCreateField(path,label,kind="number",choice="") {
    return {path:path,label:label,kind:kind,choice:choice};
}

function BattleEditor_WorkspaceCreateFields(preset) {
    var f=[];
    if(preset=="bone"||preset=="bone_spike"){
        array_push(f,BattleEditor_WorkspaceCreateField("bone_style","骨头类型","choice","bone_style"));
        array_push(f,BattleEditor_WorkspaceCreateField("transform.x","初始 X"));array_push(f,BattleEditor_WorkspaceCreateField("transform.y","初始 Y"));
        array_push(f,BattleEditor_WorkspaceCreateField("transform.angle","初始角度"));array_push(f,BattleEditor_WorkspaceCreateField("rotate","自转速度"));
        array_push(f,BattleEditor_WorkspaceCreateField("length","长度"));array_push(f,BattleEditor_WorkspaceCreateField("duration","生命周期","lifetime"));
        array_push(f,BattleEditor_WorkspaceCreateField("hspeed","水平速度"));array_push(f,BattleEditor_WorkspaceCreateField("vspeed","垂直速度"));
        array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.type","伤害颜色","choice","damage"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.damage","伤害 / 紫色占用值"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.heal_amount","回血数值"));
        array_push(f,BattleEditor_WorkspaceCreateField("green_guard_blockable","绿盾可格挡","bool"));array_push(f,BattleEditor_WorkspaceCreateField("green_guard_destroy_on_block","格挡后销毁","bool"));
        array_push(f,BattleEditor_WorkspaceCreateField("aim_enabled","朝向目标的行为","choice","bone_aim_behavior"));array_push(f,BattleEditor_WorkspaceCreateField("aim_target_uid","指向目标","choice","aim_target"));array_push(f,BattleEditor_WorkspaceCreateField("aim_continuous","方向更新方式","choice","aim_update"));
        array_push(f,BattleEditor_WorkspaceCreateField("aim_move_speed","向目标移动速度"));
    }else if(preset=="gb"){
        if(variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)&&array_length(global.battle_editor_project_runtime.resources.gb_styles)>0) array_push(f,BattleEditor_WorkspaceCreateField("gb_style_uid","GB 贴图组","choice","gb_style"));
        array_push(f,BattleEditor_WorkspaceCreateField("target_x","瞄准目标 X"));array_push(f,BattleEditor_WorkspaceCreateField("target_y","瞄准目标 Y"));
        array_push(f,BattleEditor_WorkspaceCreateField("spawn_preset","出生预设","choice","gb_spawn"));array_push(f,BattleEditor_WorkspaceCreateField("spawn_x","自定义出生 X"));array_push(f,BattleEditor_WorkspaceCreateField("spawn_y","自定义出生 Y"));array_push(f,BattleEditor_WorkspaceCreateField("spawn_distance","出生距离"));
        array_push(f,BattleEditor_WorkspaceCreateField("angle_start","起始角度"));array_push(f,BattleEditor_WorkspaceCreateField("angle_target","目标角度"));
        array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_x","横向缩放"));array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_y","纵向缩放"));
        array_push(f,BattleEditor_WorkspaceCreateField("move_time","移动帧数"));array_push(f,BattleEditor_WorkspaceCreateField("charge_time","发射前等待帧数"));array_push(f,BattleEditor_WorkspaceCreateField("beam_time","光束帧数"));
        array_push(f,BattleEditor_WorkspaceCreateField("fake_mode","真假模式","choice","fake"));array_push(f,BattleEditor_WorkspaceCreateField("transform.tween","移动曲线","choice","tween"));array_push(f,BattleEditor_WorkspaceCreateField("transform.ease","移动缓动","choice","ease"));
        array_push(f,BattleEditor_WorkspaceCreateField("offset_enabled","启用 GB 偏移","bool"));array_push(f,BattleEditor_WorkspaceCreateField("offset_direction_mode","退出方向模式","choice","gb_offset_direction"));array_push(f,BattleEditor_WorkspaceCreateField("offset_direction","自定义退出方向（自动时忽略）"));array_push(f,BattleEditor_WorkspaceCreateField("offset_speed","偏移初始速度"));array_push(f,BattleEditor_WorkspaceCreateField("offset_acceleration","每帧速度变化"));array_push(f,BattleEditor_WorkspaceCreateField("offset_rotation_speed","GB 本体旋转速度"));
        array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.type","伤害颜色","choice","damage"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.damage","伤害 / 紫色占用值"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.heal_amount","回血数值"));
    }else if(preset=="true_knife"||preset=="slash"){
        array_push(f,BattleEditor_WorkspaceCreateField("transform.x","起点 X"));array_push(f,BattleEditor_WorkspaceCreateField("transform.y","起点 Y"));array_push(f,BattleEditor_WorkspaceCreateField("transform.angle","角度"));array_push(f,BattleEditor_WorkspaceCreateField("duration","生命周期","lifetime"));
        array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.type","伤害颜色","choice","damage"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.damage","单次伤害"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.heal_amount","回血数值"));
        array_push(f,BattleEditor_WorkspaceCreateField("warning_time","警告帧数"));array_push(f,BattleEditor_WorkspaceCreateField("active_time","攻击帧数"));array_push(f,BattleEditor_WorkspaceCreateField("visual_min_width","最窄宽度"));array_push(f,BattleEditor_WorkspaceCreateField("visual_max_width","最宽宽度"));array_push(f,BattleEditor_WorkspaceCreateField("warning_width","警告宽度"));array_push(f,BattleEditor_WorkspaceCreateField("invincibility_frames","专属无敌帧"));
        var phases=["pre_motion","post_motion"],phase_names=["攻击前","攻击后"];
        for(var phase_i=0;phase_i<2;phase_i++){
            var p=phases[phase_i],n=phase_names[phase_i];
            array_push(f,BattleEditor_WorkspaceCreateField(p+".direction",n+"方向"));array_push(f,BattleEditor_WorkspaceCreateField(p+".speed",n+"初速"));array_push(f,BattleEditor_WorkspaceCreateField(p+".acceleration",n+"加速度"));array_push(f,BattleEditor_WorkspaceCreateField(p+".curve_speed",n+"弯曲角速"));
            array_push(f,BattleEditor_WorkspaceCreateField(p+".rotation_mode",n+"旋转模式","choice","wave_rotation"));array_push(f,BattleEditor_WorkspaceCreateField(p+".rotation_speed",n+"旋转速度"));array_push(f,BattleEditor_WorkspaceCreateField(p+".target_angle",n+"目标角"));array_push(f,BattleEditor_WorkspaceCreateField(p+".rotation_time",n+"旋转用时"));array_push(f,BattleEditor_WorkspaceCreateField(p+".tween",n+"旋转曲线","choice","tween"));array_push(f,BattleEditor_WorkspaceCreateField(p+".ease",n+"旋转缓动","choice","ease"));
        }
    }else if(preset=="bone_3d"||preset=="bone_4d"){
        var solid_keys=BattleEditor_SolidBoneFieldKeys(preset),solid_labels=BattleEditor_SolidBoneFieldLabels(preset);
        for(var solid_i=0;solid_i<array_length(solid_keys);solid_i++){
            var solid_key=solid_keys[solid_i];
            var solid_path=(solid_key=="x"||solid_key=="y")?"transform."+solid_key:(solid_key=="damage_type"?"damage_profile.type":(solid_key=="damage"?"damage_profile.damage":solid_key));
            array_push(f,BattleEditor_WorkspaceCreateField(solid_path,solid_key=="duration"?"生命周期":solid_labels[solid_i],solid_key=="shape_3d"?"choice":(solid_key=="duration"?"lifetime":"number"),solid_key=="shape_3d"?"solid_shape":""));
        }
    }else if(preset=="platform"){
        array_push(f,BattleEditor_WorkspaceCreateField("transform.x","中心 X"));array_push(f,BattleEditor_WorkspaceCreateField("transform.y","中心 Y"));array_push(f,BattleEditor_WorkspaceCreateField("transform.angle","角度"));
        array_push(f,BattleEditor_WorkspaceCreateField("width","宽度"));array_push(f,BattleEditor_WorkspaceCreateField("duration","生命周期","lifetime"));array_push(f,BattleEditor_WorkspaceCreateField("hspeed","水平速度"));array_push(f,BattleEditor_WorkspaceCreateField("vspeed","垂直速度"));
        array_push(f,BattleEditor_WorkspaceCreateField("sticky","平台类型","choice","platform_type"));array_push(f,BattleEditor_WorkspaceCreateField("bounce","碰框反弹","bool"));
    }else if(preset=="typewriter"){
        array_push(f,BattleEditor_WorkspaceCreateField("transform.x","文字起始 X"));array_push(f,BattleEditor_WorkspaceCreateField("transform.y","文字起始 Y"));array_push(f,BattleEditor_WorkspaceCreateField("transform.angle","角度"));array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_x","横向缩放"));array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_y","纵向缩放"));array_push(f,BattleEditor_WorkspaceCreateField("transform.alpha","透明度"));
        array_push(f,BattleEditor_WorkspaceCreateField("text","文字内容","text"));array_push(f,BattleEditor_WorkspaceCreateField("speed","打字速度"));array_push(f,BattleEditor_WorkspaceCreateField("font_id","字体","choice","font"));array_push(f,BattleEditor_WorkspaceCreateField("voice_id","打字音效","choice","voice"));array_push(f,BattleEditor_WorkspaceCreateField("text_color","基础颜色","color"));array_push(f,BattleEditor_WorkspaceCreateField("text_depth","绘制深度"));array_push(f,BattleEditor_WorkspaceCreateField("page_requires_confirm","翻页需要确认","bool"));array_push(f,BattleEditor_WorkspaceCreateField("page_delay","自动翻页延迟"));
    }else{
        array_push(f,BattleEditor_WorkspaceCreateField("transform.x","初始 X"));array_push(f,BattleEditor_WorkspaceCreateField("transform.y","初始 Y"));array_push(f,BattleEditor_WorkspaceCreateField("transform.angle","角度"));array_push(f,BattleEditor_WorkspaceCreateField("transform.alpha","透明度"));array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_x","横向缩放"));array_push(f,BattleEditor_WorkspaceCreateField("transform.scale_y","纵向缩放"));
        if(preset=="custom_sprite"||preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("sprite_source","Sprite 资源或图片路径","path"));
        if(preset=="custom_sprite"||preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("animation.frames","逐帧图片","frames"));
        if(preset=="custom_sprite"||preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("animation.frame_count","横向精灵条帧数"));
        if(preset=="custom_sprite"||preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("animation.fps","动画 FPS"));
        if(preset=="custom_sprite"||preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("animation.loop","循环播放","bool"));
        if(preset=="decoration") array_push(f,BattleEditor_WorkspaceCreateField("script_name","执行脚本资源","text"));
        array_push(f,BattleEditor_WorkspaceCreateField("duration","生命周期","lifetime"));
        if(preset!="decoration"){
            array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.type","伤害颜色","choice","damage"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.damage","伤害 / 紫色占用值"));array_push(f,BattleEditor_WorkspaceCreateField("damage_profile.heal_amount","回血数值"));
        }
    }
    // Follow belongs to Create Object itself rather than to one projectile
    // family.  It stays in the same scrollable form and uses the existing
    // frame selector, so ADD/SUBTRACT frames can be selected explicitly.
    if(preset!="board_add"&&preset!="board_subtract"){
        array_insert(f,0,BattleEditor_WorkspaceCreateField("follow_target_uid","跟随目标框","choice","follow_frame"));
        array_insert(f,0,BattleEditor_WorkspaceCreateField("follow","跟随战斗框","bool"));
    }

    // Every damage-capable creation form exposes the same explicit rule:
    // changing damage mechanics and changing the visible colour remain
    // separate author decisions.
    var damage_type_field=-1;
    for(var damage_field_index=0;damage_field_index<array_length(f);damage_field_index++){
        if(f[damage_field_index].path=="damage_profile.type"){damage_type_field=damage_field_index;break;}
    }
    if(damage_type_field>=0) array_insert(f,damage_type_field+1,BattleEditor_WorkspaceCreateField("damage_profile.change_visual","同时修改显示颜色","bool"));

    // Visual tint belongs beside the damage palette, not at the remote end of
    // a long object form. Damage colour controls behaviour; visual colour is
    // the independent on-screen tint. Keeping them adjacent makes that
    // distinction visible without compressing either control into "...".
    if(preset!="typewriter"&&preset!="platform"){
        var tint_insert=array_length(f);
        for(var tint_find=0;tint_find<array_length(f);tint_find++){
            if(string_pos("damage_profile.",f[tint_find].path)==1) tint_insert=tint_find+1;
        }
        // Decorations have no damage palette; put their sole visual colour
        // immediately after transform alpha instead of at the bottom.
        if(preset=="decoration"){
            tint_insert=0;
            for(var decoration_find=0;decoration_find<array_length(f);decoration_find++){
                if(f[decoration_find].path=="transform.alpha") tint_insert=decoration_find+1;
            }
        }
        if(preset!="decoration"){
            // The author-facing choice is deliberately a checkbox rather than
            // a three-state implementation-mode menu. Checked exposes the
            // fixed colour-template dropdown; unchecked exposes the palette.
            // Legacy follow-mode data is still understood as a checked
            // template and is not rewritten until the author changes it.
            array_insert(f,tint_insert,BattleEditor_WorkspaceCreateField("visual_tint.mode","固定模板","visual_template_toggle"));
            tint_insert+=1;
        }
        array_insert(f,tint_insert,BattleEditor_WorkspaceCreateField("visual_tint.color","显示颜色","color"));
    }
    array_push(f,BattleEditor_WorkspaceCreateField("layer_mode","绘制层级","choice","layer"));
    if(preset=="custom_sprite"||preset=="decoration"||preset=="platform"||preset=="bone"||preset=="bone_spike"){
        array_push(f,BattleEditor_WorkspaceCreateField("clipped","按战斗框裁剪","bool"));
        array_push(f,BattleEditor_WorkspaceCreateField("clip_mode","裁剪范围","choice","clip_mode"));
        array_push(f,BattleEditor_WorkspaceCreateField("clip_frame_uids","自定义裁剪框","clip_frames"));
        array_push(f,BattleEditor_WorkspaceCreateField("clipped_collision","裁掉部分无碰撞","bool"));
    }
    return f;
}

function BattleEditor_WorkspaceTemplateGet(data,path) {
    if(path=="animation.frames") return data.animation.frames;
    var parts=string_split(path,"."),value=data;
    for(var i=0;i<array_length(parts);i++){
        if(!is_struct(value)||!variable_struct_exists(value,parts[i])) return "";
        value=variable_struct_get(value,parts[i]);
    }
    return value;
}

function BattleEditor_WorkspaceTemplateSet(data,path,value) {
    var parts=string_split(path,"."),target=data;
    for(var i=0;i<array_length(parts)-1;i++){
        if(!is_struct(target)||!variable_struct_exists(target,parts[i])) return false;
        target=variable_struct_get(target,parts[i]);
    }
    if(!is_struct(target)) return false;
    variable_struct_set(target,parts[array_length(parts)-1],value);
    return true;
}

function BattleEditor_WorkspaceCreateChoiceCount(choice,project=undefined) {
    if(choice=="gb_style") return is_undefined(project)?1:1+array_length(project.resources.gb_styles);
    if(choice=="follow_frame") return is_undefined(project)?0:array_length(BattleEditor_FollowFrameOptions(project));
    if(choice=="aim_target") return is_undefined(project)?0:array_length(BattleEditor_AimTargetOptions(project,-1));
    if(choice=="gb_spawn") return 19;
    if(choice=="tween") return 11;
    if(choice=="font") return TextTyper_FontCount();
    if(choice=="voice") return 5;
    if(choice=="damage") return 9;
    if(choice=="visual_color_mode") return 3;
    if(choice=="visual_color_preset") return 9;
    if(choice=="solid_shape") return 6;
    if(choice=="layer"||choice=="fake"||choice=="ease"||choice=="wave_rotation") return 3;
    if(choice=="gb_offset_direction") return 2;
    if(choice=="clip_mode") return 2;
    if(choice=="lifetime_mode") return 2;
    if(choice=="bone_aim_behavior") return 3;
    if(choice=="aim_update") return 2;
    return 2;
}

function BattleEditor_WorkspaceCreateChoiceValue(choice,index,project=undefined) {
    if(choice=="gb_style") return index<=0?-1:project.resources.gb_styles[clamp(index-1,0,array_length(project.resources.gb_styles)-1)].uid;
    if(choice=="follow_frame"){
        var follow_options=BattleEditor_FollowFrameOptions(project);
        return array_length(follow_options)>0?follow_options[clamp(index,0,array_length(follow_options)-1)].uid:-1;
    }
    if(choice=="aim_target"){
        var aim_options=BattleEditor_AimTargetOptions(project,-1);
        return array_length(aim_options)>0?aim_options[clamp(index,0,array_length(aim_options)-1)].uid:-1;
    }
    if(choice=="solid_shape"&&index==5) return 6;
    if(choice=="voice") return index-1;
    if(choice=="clip_mode") return index==1?"selected":"all";
    if(choice=="lifetime_mode") return index==0?-1:60;
    if(choice=="bone_aim_behavior"||choice=="aim_update") return index;
    return index;
}

function BattleEditor_WorkspaceCreateChoiceIndex(choice,value,project=undefined) {
    if(choice=="lifetime_mode") return real(value)<0?0:1;
    if(choice=="bone_aim_behavior") return clamp(round(real(value)),0,2);
    if(choice=="aim_update") return real(value)!=0?1:0;
    if(choice=="gb_style"){
        if(real(value)<0||is_undefined(project)) return 0;
        for(var gb_style_i=0;gb_style_i<array_length(project.resources.gb_styles);gb_style_i++) if(project.resources.gb_styles[gb_style_i].uid==value) return gb_style_i+1;
        return 0;
    }
    if(choice=="follow_frame"){
        var follow_options=BattleEditor_FollowFrameOptions(project);
        for(var follow_i=0;follow_i<array_length(follow_options);follow_i++) if(follow_options[follow_i].uid==value) return follow_i;
        return 0;
    }
    if(choice=="aim_target"){
        var aim_options=BattleEditor_AimTargetOptions(project,-1);
        for(var aim_i=0;aim_i<array_length(aim_options);aim_i++) if(aim_options[aim_i].uid==value) return aim_i;
        return 0;
    }
    if(choice=="clip_mode") return string(value)=="selected"?1:0;
    value=round(real(value));
    if(choice=="solid_shape"&&value==6) return 5;
    if(choice=="voice") return clamp(value+1,0,4);
    return clamp(value,0,BattleEditor_WorkspaceCreateChoiceCount(choice,project)-1);
}

function BattleEditor_WorkspaceCreateChoiceCaption(choice,value,project=undefined) {
    if(choice=="gb_style") return BattleEditor_GBStyleCaption(project,value);
    if(choice=="follow_frame") return BattleEditor_FollowFrameCaption(project,value);
    if(choice=="aim_target") return BattleEditor_AimTargetCaption(project,value);
    if(choice=="layer") return BattleEditor_LayerName(value);
    if(choice=="damage") return BattleEditor_DamageTypeName(value);
    if(choice=="visual_color_mode") return BattleEditor_VisualColorModeName(value);
    if(choice=="visual_color_preset") return BattleEditor_VisualColorPresetName(value);
    if(choice=="bone_style") return BattleEditor_BoneStyleName(value);
    if(choice=="gb_spawn") return BattleEditor_GBSpawnPresetName(value);
    if(choice=="fake") return ["真实 GB","假 GB 动画","假 GB 掉落"][clamp(round(real(value)),0,2)];
    if(choice=="gb_offset_direction") return round(real(value))==0?"自动：沿 GB 后方":"自定义：绝对角度";
    if(choice=="tween") return BattleEditor_TweenName(value);
    if(choice=="ease") return BattleEditor_EaseName(value);
    if(choice=="wave_rotation") return BattleEditor_WaveRotationModeName(value);
    if(choice=="solid_shape") return BattleEditor_SolidBoneShapeName(value);
    if(choice=="platform_type") return real(value)!=0?"绿色（带玩家）":"紫色（不带玩家）";
    if(choice=="font") return TextTyper_FontName(value);
    if(choice=="voice") return BattleEditor_VoiceName(value);
    if(choice=="clip_mode") return string(value)=="selected"?"自定义框":"全部框";
    if(choice=="lifetime_mode") return real(value)<0?"本回合一直存在":"指定存活帧数";
    if(choice=="bone_aim_behavior") return BattleEditor_BoneAimBehaviorName(value);
    if(choice=="aim_update") return BattleEditor_EditorChoiceCaption("aim_update",value);
    return string(value);
}

function BattleEditor_WorkspaceCreateFieldHeight(field) {
    return field.kind=="frames"?68:42;
}

function BattleEditor_WorkspaceCreateFieldsHeight(fields) {
    var result=0;
    for(var i=0;i<array_length(fields);i++) result+=BattleEditor_WorkspaceCreateFieldHeight(fields[i]);
    return result;
}

function BattleEditor_BuiltinActionUsesTemplate(action_id) {
    return action_id=="bone_orbit"||action_id=="bone_wave"||action_id=="bone_corridor"||action_id=="bone_physics"||action_id=="bone_wall"||action_id=="bone_function_path";
}

function BattleEditor_BuiltinActionCanKeepObjects(action_id) {
    // Board morphs do not generate a group. GB owns a dedicated skull/beam
    // lifecycle, so "keep this ordinary generated group" would be ambiguous.
    return action_id!="board_shape"&&action_id!="gb_pinwheel";
}

function BattleEditor_BuiltinActionHasDamageColor(action_id) {
    switch(action_id){
        case "bone_orbit":case "bone_wave":case "bone_corridor":case "bone_physics":
        case "bone_3d":case "bone_4d":case "gb_pinwheel":case "bone_wall":case "bone_function_path":
            return true;
    }
    return false;
}

function BattleEditor_ActionTemplateOptions(project) {
    var result=[{uid:-1,name:"默认骨头",target_type:"bone"}];
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    for(var i=0;i<array_length(project.events);i++){
        var template_event=project.events[i];
        if(!BattleEditor_EventBelongsToTurn(template_event,authoring_turn)) continue;
        // GB owns two positions plus a beam lifecycle, so it remains handled
        // by the dedicated GB windmill constructor instead of being cloned as
        // an ordinary point object.
        if(BattleEditor_DataTargetType(template_event)=="gb") continue;
        array_push(result,{uid:template_event.uid,name:template_event.name,target_type:BattleEditor_DataTargetType(template_event)});
    }
    return result;
}

function BattleEditor_ActionTemplateCaption(project,source_uid) {
    var options=BattleEditor_ActionTemplateOptions(project);
    for(var i=0;i<array_length(options);i++) if(options[i].uid==source_uid) return "["+BattleEditor_TargetTypeName(options[i].target_type)+"] "+options[i].name;
    return "默认骨头";
}

function BattleEditor_FunctionPathCloneOptions(project) {
    var source=BattleEditor_ActionTemplateOptions(project),result=[];
    for(var i=0;i<array_length(source);i++){
        if(source[i].uid<0||source[i].target_type=="board") continue;
        var properties=BattleEditor_ControlPropertiesForType(source[i].target_type,"transform"),can_move=false;
        for(var property_index=0;property_index<array_length(properties);property_index++) if(properties[property_index]=="position"){can_move=true;break;}
        if(can_move) array_push(result,source[i]);
    }
    return result;
}

function BattleEditor_FunctionPathCloneCaption(project,source_uid,legacy_default=false) {
    var options=BattleEditor_FunctionPathCloneOptions(project);
    for(var i=0;i<array_length(options);i++) if(options[i].uid==source_uid) return "["+BattleEditor_TargetTypeName(options[i].target_type)+"] "+options[i].name;
    return legacy_default?"旧存档默认骨头（兼容）":"选择要复制的对象";
}

function BattleEditor_FunctionPathTargetOptions(project) {
    var source=BattleEditor_ControlTargetOptions(project);
    var result=[];
    for(var option_index=0;option_index<array_length(source);option_index++){
        var option=source[option_index];
        if(option.target_type=="gb"||option.target_type=="path_point") continue;
        var properties=BattleEditor_ControlPropertiesForType(option.target_type,"transform");
        var can_move=false;
        for(var property_index=0;property_index<array_length(properties);property_index++) if(properties[property_index]=="position"){can_move=true;break;}
        if(can_move) array_push(result,option);
    }
    return result;
}

function BattleEditor_FunctionPathModeName(mode) {
    return round(real(mode))==1?"带动已有对象组":"复制已有对象";
}

function BattleEditor_FunctionPathTargetCaption(project,step) {
    var options=BattleEditor_FunctionPathTargetOptions(project);
    for(var i=0;i<array_length(options);i++) if(options[i].control_id==step.action_control_id&&options[i].target_type==step.action_path_target_type){
        var runtime_count=struct_exists(options[i],"runtime_count")?options[i].runtime_count:0;
        return BattleEditor_TargetTypeName(options[i].target_type)+" / "+options[i].control_id+" · "+string(options[i].count)+" 个"+(runtime_count>0?" [运行时]":"");
    }
    return "选择已有对象组";
}
function BattleEditor_ScreenActionName(action_id) {
    if(action_id=="effect_color") return "旧组合色彩调整";
    if(action_id=="effect_glitch") return "旧组合故障效果";
    if(action_id=="effect_vignette") return "旧组合暗角/像素化";
    return BattleEditor_ActionOption(BattleEditor_ScreenActionOptions(),action_id).name;
}
function BattleEditor_ScreenActionLabels(action_id) {
    if(action_id=="effect_color") return "色相角;饱和度;亮度;对比度;灰度;反色";
    if(action_id=="effect_glitch") return "故障强度;色差像素;扫描线;波浪";
    if(action_id=="effect_vignette") return "暗角;像素块大小";
    return BattleEditor_ActionOption(BattleEditor_ScreenActionOptions(),action_id).labels;
}
function BattleEditor_ScreenActionDefaults(action_id) {
    if(action_id=="effect_color") return "0;1;0;1;0;0";
    if(action_id=="effect_glitch") return "0.35;3;0.15;1.5";
    if(action_id=="effect_vignette") return "0.35;1";
    return BattleEditor_ActionOption(BattleEditor_ScreenActionOptions(),action_id).defaults;
}

/// Parameter metadata is author-facing only. Values remain serialized in the
/// legacy semicolon form so existing saves and runtime parsing stay compatible,
/// but the Workspace never exposes that representation.
function BattleEditor_ActionParameterLabels(scope,action_id) {
    var source=scope=="screen"?BattleEditor_ScreenActionLabels(action_id):BattleEditor_BuiltinActionLabels(action_id);
    if(string_trim(source)==""||source=="无参数") return [];
    return string_split(source,";");
}

function BattleEditor_ActionParameterKind(scope,action_id,index) {
    if(scope=="builtin"){
        if(action_id=="board_shape"&&index==0) return "board_shape";
        if((action_id=="bone_wave"&&index==2)||(action_id=="bone_corridor"&&index==0)) return "axis";
        if(action_id=="bone_3d"&&index==2) return "solid_shape";
        if(action_id=="bone_function_path"&&index==9) return "path_facing";
        if(action_id=="bone_function_path"&&index==12) return "identifier";
        if((action_id=="bone_orbit"&&index==12)||(action_id=="bone_wave"&&index==9)||(action_id=="bone_corridor"&&index==12)||(action_id=="bone_physics"&&index==12)||(action_id=="gb_pinwheel"&&index==13)||(action_id=="bone_wall"&&index==8)) return "color";
        if(action_id=="bone_function_path"&&index==10) return "color";
        if((action_id=="bone_3d"&&index==18)||(action_id=="bone_4d"&&index==23)) return "color";
        if((action_id=="bone_orbit"&&index==13)||(action_id=="bone_wave"&&index==10)||(action_id=="bone_corridor"&&index==13)||(action_id=="bone_physics"&&index==13)||(action_id=="bone_wall"&&index==9)) return "layer";
        if(action_id=="bone_function_path"&&index==11) return "layer";
        if((action_id=="bone_3d"&&index==20)||(action_id=="bone_4d"&&index==25)) return "layer";
    }else if(scope=="screen"&&action_id=="camera_shake"&&(index==4||index==7)) return "boolean";
    return "expression";
}

function BattleEditor_ActionParameterChoiceCount(kind) {
    switch(kind){
        case "axis":return 2;
        case "color":return 9;
        case "layer":return 3;
        case "boolean":return 2;
        case "solid_shape":return 6;
        case "board_shape":return 4;
        case "path_facing":return 2;
    }
    return 0;
}

function BattleEditor_ActionParameterChoiceCaption(kind,value,action_id="") {
    value=round(real(value));
    switch(kind){
        case "axis":
            if(action_id=="bone_corridor") return value==0?"横向移动（生成点上下曲线）":"纵向移动（生成点左右曲线）";
            return value==0?"横向排列（骨头上下摆动）":"纵向排列（骨头左右摆动）";
        case "color":return BattleEditor_DamageTypeName(clamp(value,0,8));
        case "layer":return BattleEditor_LayerName(clamp(value,0,2));
        case "boolean":return value==0?"关":"开";
        case "solid_shape":return BattleEditor_SolidBoneShapeName(value>=5?6:value);
        case "board_shape":return ["矩形","椭圆","正三角形","多边形"][clamp(value,0,3)];
        case "path_facing":return value==0?"固定角度":"跟随路径切线";
    }
    return string(value);
}

function BattleEditor_BoneWallDirectionName(direction) {
    switch(clamp(round(direction),1,7)){
        case 2:return "下";
        case 3:return "左";
        case 4:return "右";
        case 5:return "上下";
        case 6:return "左右";
        case 7:return "四个方向";
    }
    return "上";
}

function BattleEditor_ActionArgumentText(source,index,defaults="") {
    var parts=BattleEditor_ActionParts(source);
    if(index>=0&&index<array_length(parts)) return string_trim(parts[index]);
    var fallback_parts=BattleEditor_ActionParts(defaults);
    if(index>=0&&index<array_length(fallback_parts)) return string_trim(fallback_parts[index]);
    return "";
}

function BattleEditor_ActionArgumentsSet(source,index,value,defaults="") {
    var parts=BattleEditor_ActionParts(source);
    var fallback_parts=BattleEditor_ActionParts(defaults);
    var count=max(index+1,max(array_length(parts),array_length(fallback_parts)));
    var result="";
    for(var i=0;i<count;i++){
        var item=i<array_length(parts)?string_trim(parts[i]):(i<array_length(fallback_parts)?string_trim(fallback_parts[i]):"");
        if(i==index) item=string(value);
        if(i>0) result+=";";
        result+=item;
    }
    return result;
}

function BattleEditor_ActionArgumentsRemove(source,index) {
    var parts=BattleEditor_ActionParts(source),result="";
    for(var i=0;i<array_length(parts);i++){
        if(i==index) continue;
        if(string_length(result)>0) result+=";";
        result+=string_trim(parts[i]);
    }
    return result;
}

function BattleEditor_NewProject() {
    var result={
        format: "uteu_attack_editor",
        version: 33,
        next_uid: 2,
        name: "未命名攻击",
        duration: -1,
        settings: {
            auto_switch_to_objects_on_run: true,
            developer_force_turn: false,
            developer_turn: 1,
            developer_force_default_board: false,
            editor_show_objects: true
        },
        initialization: {
            soul: "battle_soul_red",
            player_name: "hi175570",
            lv: 25,
            hp: 114514,
            max_hp: 114514,
            natural_max_hp: 114514,
            atk: 10,
            def: 10,
            shield: 100,
            shield_max: 100,
            shield_natural_max: 100,
            turn_text: "* 第一回合",
            turn_text_x: 58,
            turn_text_y: 270,
            character_dialogue: "",
            turn_font: 0,
            dialogue_font: 2,
            turn_voice: 1,
            dialogue_voice: 2,
            // Empty is an explicit no-music selection. Frame sync keeps the
            // same BGM player but corrects its native track position against
            // logical game frames when the Runner cannot sustain full speed.
            battle_music: "",
            battle_music_frame_sync: false,
            mercy_spare_label: "* 饶恕",
            mercy_spare_response: "",
            mercy_flee_enabled: true,
            mercy_flee_label: "* 逃跑",
            mercy_flee_success_text: "",
            mercy_flee_fail_text: "",
            // Coordinates describe the visible centre of the complete enemy
            // rig and the origin of the complete battle HUD group.
            enemy_x: 320,
            enemy_y: 166,
            hud_x: 30,
            hud_y: 401,
            hud_show_hp_label: true,
            hud_show_bar: true,
            hud_show_kr: true,
            hud_show_numbers: true,
            hud_show_shield: true,
            hud_show_overhead: false,
            shield_enabled: true,
            shield_hud_mode: BATTLE_SHIELD_HUD_MODE.BELOW_HP,
            board_color_default: c_white,
            player_board: {x:320,y:320,up:65,down:65,left:283,right:283,angle:0},
            // 玩家/菜单回合仍用上面的长方形；怪物回合的新项目默认使用 130 x 130 正方形。
            board: {uid:1,control_id:"main_board",kind:BATTLE_EDITOR_BOARD_KIND.MAIN,name:"主框",shape:"rect",cover:false,x:320,y:320,up:65,down:65,left:65,right:65,angle:0,rotate:0,board_depth:0,color_frame:c_white},
            frames: [],
            gb_spawn_default: {preset:BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP,x:320,y:-560,angle:270,distance:800},
            items: BattleEditor_DefaultItems(),
            enemies: []
        },
        turns: [
            {turn:1,text:"* 第一回合",dialogue:"",turn_font:0,dialogue_font:2,turn_voice:1,dialogue_voice:2,
                dialogue_template:0,dialogue_offset_x:92,dialogue_offset_y:-34}
        ],
        variables: [],
        resources: {audio:[],enemy_textures:[],gb_styles:[]},
        events: [],
        script_lists: []
    };
    array_push(result.initialization.enemies,BattleEditor_NewEnemy(result,320,166,true));
    return result;
}

function BattleEditor_GetKnownTurns(project) {
    var result=[1];
    for(var turn_index=0;turn_index<array_length(project.turns);turn_index++){
        var turn_number=max(1,round(real(project.turns[turn_index].turn)));
        var turn_exists=false;
        for(var known_index=0;known_index<array_length(result);known_index++) if(result[known_index]==turn_number){turn_exists=true;break;}
        if(!turn_exists) array_push(result,turn_number);
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        if(list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN){
            var script_turn=max(1,round(real(list_data.entry_value)));
            var script_turn_exists=false;
            for(var script_known_index=0;script_known_index<array_length(result);script_known_index++) if(result[script_known_index]==script_turn){script_turn_exists=true;break;}
            if(!script_turn_exists) array_push(result,script_turn);
        }else if(list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE){
            var timer_turn=BattleEditor_ScriptListTimelineTurn(list_data);
            var timer_turn_exists=false;
            for(var timer_known_index=0;timer_known_index<array_length(result);timer_known_index++) if(result[timer_known_index]==timer_turn){timer_turn_exists=true;break;}
            if(!timer_turn_exists) array_push(result,timer_turn);
        }
    }
    for(var event_index=0;event_index<array_length(project.events);event_index++){
        var event_turn=BattleEditor_EventTurn(project.events[event_index]);
        var event_turn_exists=false;
        for(var event_known_index=0;event_known_index<array_length(result);event_known_index++) if(result[event_known_index]==event_turn){event_turn_exists=true;break;}
        if(!event_turn_exists) array_push(result,event_turn);
    }
    array_sort(result,true);
    return result;
}

/// Scene events and timer-entry lists live on one authored monster-turn
/// timeline. Old projects had no tag at all; their existing work belongs to
/// turn 1, which is the only timeline those versions could represent.
function BattleEditor_EventTurn(event_data) {
    return is_struct(event_data)&&struct_exists(event_data,"turn")?max(1,round(real(event_data.turn))):1;
}

function BattleEditor_EventBelongsToTurn(event_data,turn_number) {
    return BattleEditor_EventTurn(event_data)==max(1,round(real(turn_number)));
}

function BattleEditor_ScriptListTimelineTurn(list_data) {
    if(!is_struct(list_data)) return 1;
    if(struct_exists(list_data,"entry_kind")&&list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN) return max(1,round(real(list_data.entry_value)));
    return struct_exists(list_data,"turn")?max(1,round(real(list_data.turn))):1;
}

function BattleEditor_ScriptListBelongsToTurn(list_data,turn_number) {
    if(!is_struct(list_data)) return false;
    if(!BattleEditor_WorkspaceHasHeader(list_data)) return false;
    var wanted=max(1,round(real(turn_number)));
    if(list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN) return max(1,round(real(list_data.entry_value)))==wanted;
    if(list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE) return BattleEditor_ScriptListTimelineTurn(list_data)==wanted;
    return true;
}

function BattleEditor_EventCountForTurn(project,turn_number) {
    var count=0;
    for(var event_index=0;event_index<array_length(project.events);event_index++) if(BattleEditor_EventBelongsToTurn(project.events[event_index],turn_number)) count+=1;
    return count;
}

/// Change the editor's authored turn as one operation. Besides changing the
/// label, this ends any frozen replay, drops its transient placement previews,
/// resets selection and rebuilds the duration/board for the chosen timeline.
function BattleEditor_SetAuthoringTurn(controller,turn_number) {
    if(!instance_exists(controller)) return 1;
    var next_turn=max(1,round(real(turn_number)));
    var has_runtime=(variable_instance_exists(controller,"playing")&&controller.playing)
        ||(variable_instance_exists(controller,"timeline_half_play")&&controller.timeline_half_play)
        ||(variable_instance_exists(controller,"timeline_seek_active")&&controller.timeline_seek_active);
    if(has_runtime) BattleEditor_RuntimeStop(controller);
    controller.developer_turn=next_turn;
    controller.project.settings.developer_turn=next_turn;
    BattleEditor_GetTurnData(controller.project,next_turn,true);
    controller.selected=-1;
    controller.selected_frame=-2;
    controller.selected_animation_frame=-1;
    controller.group_selection_active=false;
    controller.group_selection_type="";
    controller.group_selection_control_id="";
    controller.scene_click_cycle_uids=[];
    controller.cursor_time=0;
    controller.new_object_preview_uids=[];
    controller.timeline_live_seek_time=-1;
    controller.timeline_live_seek_target=0;
    controller.timeline_live_seek_pending=false;
    controller.timeline_reseek_requested=false;
    controller.timeline_duration_dirty=true;
    BattleEditor_RefreshDurationCache(controller);
    BattleEditor_RestoreAuthoringBoard(controller);
    return next_turn;
}

function BattleEditor_GetTurnData(project,turn_number,create_if_missing=true) {
    turn_number=max(1,round(real(turn_number)));
    for(var i=0;i<array_length(project.turns);i++) if(project.turns[i].turn==turn_number) return project.turns[i];
    if(!create_if_missing) return undefined;
    var init=project.initialization;
    var created={
        turn:turn_number,
        text:"* 第"+string(turn_number)+"回合",
        dialogue:"",
        turn_font:init.turn_font,
        dialogue_font:init.dialogue_font,
        turn_voice:init.turn_voice,
        dialogue_voice:init.dialogue_voice,
        dialogue_template:0,
        dialogue_offset_x:92,
        dialogue_offset_y:-34
    };
    array_push(project.turns,created);
    return created;
}

function BattleEditor_DialogueTemplateName(template) {
    switch(round(real(template))){
        case 0:return "宽气泡・尖角向左";
        case 1:return "宽气泡・尖角向右";
        case 2:return "小气泡・尖角向左";
        case 3:return "小气泡・尖角向右";
        case 4:return "无框短句";
    }
    return "宽气泡・尖角向左";
}

/// Runs only the animation-script resource selected by an enemy entry.  The
/// script receives (enemy_index, enemy_data, gravity_direction); editor data
/// for boards, bullets and GBs is never selected by this animation channel.
function BattleEditor_RunEnemyGravityScripts(enemy_host,gravity_direction) {
    if(!instance_exists(enemy_host)||!variable_global_exists("battle_editor_project_runtime")) return 0;
    var runtime_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
    var executed=0;
    for(var enemy_index=0;enemy_index<array_length(runtime_project.initialization.enemies);enemy_index++){
        var enemy_data=runtime_project.initialization.enemies[enemy_index];
        var script_name="";
        switch(gravity_direction){
            case DIR.UP:script_name=enemy_data.animation_scripts.gravity_up;break;
            case DIR.DOWN:script_name=enemy_data.animation_scripts.gravity_down;break;
            case DIR.LEFT:script_name=enemy_data.animation_scripts.gravity_left;break;
            case DIR.RIGHT:script_name=enemy_data.animation_scripts.gravity_right;break;
        }
        if(string_length(string(script_name))<=0) continue;
        var script_asset=asset_get_index(string(script_name));
        if(script_asset<0||!script_exists(script_asset)) continue;
        with(enemy_host) script_execute(script_asset,enemy_index,enemy_data,gravity_direction);
        executed+=1;
    }
    return executed;
}

function BattleEditor_ResolveMonsterTurn(project,natural_turn) {
    if(project.settings.developer_force_turn) return max(1,round(project.settings.developer_turn));
    return max(1,round(natural_turn));
}

function BattleEditor_ApplyTurnPresentation(project,turn_number) {
    var turn_data=BattleEditor_GetTurnData(project,turn_number,true);
    if(instance_exists(battle)) Battle_SetMenuDialog("{font "+string(turn_data.turn_font)+"}{voice "+string(turn_data.turn_voice)+"}"+TextTyper_CompileMarkup(turn_data.text).text);
    return turn_data;
}

function BattleEditor_NewBone(x, y, time = 0, bone_style = 0) {
    var track=BattleEditor_NewTransformTrack(x,y);
    track.angle=90;
    bone_style=clamp(round(real(bone_style)),0,1);
    return {
        kind: BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD,
        preset: "bone",
        name: bone_style==1?"骨刺":"bone",
        editor_visible: true,
        time: max(0, time),
        transform: track,
        length: 48,
        bone_style: bone_style,
        rotate: 0,
        hspeed: 0,
        vspeed: 0,
        duration: -1,
        follow: false,
        // Follow uses local coordinates relative to one authored frame.
        follow_target_uid: 1,
        follow_local_coordinates: true,
        // Legacy point/point_at are retained only for old API compatibility.
        // Editor pointing uses a stable object UID and is independent of the
        // old "stick bone to board edge" shortcut.
        point: 0,
        point_at: 0,
        aim_enabled: false,
        aim_target_uid: -1,
        aim_continuous: true,
        aim_move_enabled: false,
        aim_move_speed: 0,
        green_guard_blockable: false,
        green_guard_destroy_on_block: false,
        clipped: true,
        layer_mode: BATTLE_EDITOR_LAYER.IN_BOARD,
        damage_profile: {type:0, damage:2, heal_amount:10, color_rules:true, change_visual:false},
        visual_tint: {enabled:true, mode:1, preset_type:0, custom_color:c_white, follow_damage_profile:false, color:c_white}
    };
}

function BattleEditor_NewPlatform(x,y,time=0) {
    return {
        kind:BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD,
        preset:"platform",
        name:"蓝魂平台",
        editor_visible:true,
        time:max(0,time),
        transform:BattleEditor_NewTransformTrack(x,y),
        width:48,
        sticky:true,
        bounce:false,
        hspeed:0,
        vspeed:0,
        duration:-1,
        auto_destroy:false,
        layer_mode:BATTLE_EDITOR_LAYER.IN_BOARD,
        layer_user_set:true,
        clipped:true,
        clip_mode:"all",
        clip_frame_uids:[],
        clipped_collision:true,
        visual_tint:{enabled:false,mode:2,preset_type:0,custom_color:c_white,follow_damage_profile:false,color:c_white}
    };
}

function BattleEditor_NewCustomSpriteHazard(x,y,time=0) {
    return {
        kind:BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD,
        preset:"custom_sprite",
        name:"sprite_hazard",
        editor_visible:true,
        time:max(0,time),
        transform:BattleEditor_NewTransformTrack(x,y),
        duration:-1,
        sprite_source:"",
        animation:BattleEditor_NewAnimation(),
        clipped:true,
        layer_mode:BATTLE_EDITOR_LAYER.IN_BOARD,
        damage_profile:{type:0,damage:2,heal_amount:10,color_rules:true,change_visual:false},
        visual_tint:{enabled:true,mode:1,preset_type:0,custom_color:c_white,follow_damage_profile:false,color:c_white}
    };
}

function BattleEditor_BuiltinHazardName(preset) {
    switch(preset){
        case "friendship_pellet": return "友谊颗粒";
        case "fireball": return "火球";
        case "spear": return "长矛";
        case "trident": return "三叉戟";
        case "knife": return "刀子";
        case "slash": return "斩击";
        case "true_knife": return "真刀";
        case "bone_3d": return "3D 骨";
        case "bone_4d": return "4D 骨";
    }
    return "内建攻击";
}

function BattleEditor_SolidBoneShapeName(shape) {
    var names=["立方体","正四面体","正八面体","正十二面体","正二十面体","四角锥"];
    var shape_index=round(shape)==6?5:clamp(round(shape),0,4);
    return names[shape_index];
}

/// 3D/4D geometry keeps every scalar author-facing. Arrays are assembled only
/// at the final constructor call, so the editor never exposes a comma list.
function BattleEditor_SolidBoneFieldKeys(preset) {
    if(preset=="bone_4d") return ["x","y","time","duration","angle_x","angle_y","angle_z","angle_xw","angle_yw","angle_zw","rotate_x","rotate_y","rotate_z","rotate_xw","rotate_yw","rotate_zw","size_x","size_y","size_z","size_w","world_z","perspective_distance","perspective4d_distance","edge_trim","damage_type","damage"];
    return ["x","y","time","duration","shape_3d","angle_x","angle_y","angle_z","rotate_x","rotate_y","rotate_z","size_x","size_y","size_z","hspeed","vspeed","world_z","perspective_distance","edge_trim","damage_type","damage"];
}

function BattleEditor_SolidBoneFieldLabels(preset) {
    if(preset=="bone_4d") return ["中心 X","中心 Y","出生时间","存活帧（-1 无限）","X 轴角度","Y 轴角度","Z 轴角度","XW 平面角度","YW 平面角度","ZW 平面角度","X 轴转速","Y 轴转速","Z 轴转速","XW 平面转速","YW 平面转速","ZW 平面转速","X 尺寸","Y 尺寸","Z 尺寸","W 尺寸","世界 Z","3D 透视距离","4D 透视距离","边缘留白","伤害颜色","伤害 / 紫色占用值"];
    return ["中心 X","中心 Y","出生时间","存活帧（-1 无限）","立体形状","X 轴角度","Y 轴角度","Z 轴角度","X 轴转速","Y 轴转速","Z 轴转速","X 尺寸","Y 尺寸","Z 尺寸","水平速度","垂直速度","世界 Z","透视距离","边缘留白","伤害颜色","伤害 / 紫色占用值"];
}

function BattleEditor_SolidBoneFieldValue(event_data,key) {
    if(key=="x"||key=="y") return variable_struct_get(event_data.transform,key);
    if(key=="damage_type") return event_data.damage_profile.type;
    if(key=="damage") return event_data.damage_profile.damage;
    return variable_struct_get(event_data,key);
}

function BattleEditor_SetSolidBoneField(event_data,key,value) {
    if(key=="x"||key=="y") variable_struct_set(event_data.transform,key,value);
    else if(key=="time") event_data.time=max(0,value);
    else if(key=="duration") event_data.duration=value<0?-1:max(1,value);
    else if(key=="shape_3d") event_data.shape_3d=round(value)>=5?6:clamp(round(value),0,4);
    else if(key=="damage_type") event_data.damage_profile.type=clamp(round(value),0,8);
    else if(key=="damage") event_data.damage_profile.damage=max(0,value);
    else if(key=="perspective_distance"||key=="perspective4d_distance") variable_struct_set(event_data,key,max(32,value));
    else if(key=="edge_trim") event_data.edge_trim=max(0,value);
    else variable_struct_set(event_data,key,value);
    return true;
}

function BattleEditor_NewSolidBone(x,y,preset,time=0) {
    return {
        kind:BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD,
        preset:preset,
        name:BattleEditor_BuiltinHazardName(preset),
        editor_visible:true,
        time:max(0,time),
        transform:BattleEditor_NewTransformTrack(x,y),
        duration:-1,
        shape_3d:0,
        angle_x:20,angle_y:25,angle_z:0,
        angle_xw:0,angle_yw:0,angle_zw:0,
        rotate_x:0.5,rotate_y:0.8,rotate_z:0.25,
        rotate_xw:0.4,rotate_yw:0.6,rotate_zw:0.3,
        size_x:40,size_y:40,size_z:40,size_w:40,
        hspeed:0,vspeed:0,world_z:0,
        perspective_distance:420,perspective4d_distance:260,
        edge_trim:8,
        layer_mode:BATTLE_EDITOR_LAYER.OUTSIDE,
        layer_user_set:false,
        clipped:false,
        damage_profile:{type:0,damage:2,heal_amount:10,color_rules:true,change_visual:false},
        visual_tint:{enabled:true,mode:1,preset_type:0,custom_color:c_white,follow_damage_profile:false,color:c_white}
    };
}

function BattleEditor_BuiltinHazardSprite(preset) {
    switch(preset){
        case "friendship_pellet": return "spr_editor_friendship_pellet";
        case "fireball": return "spr_editor_fireball";
        case "spear": return "spr_editor_spear";
        case "trident": return "spr_editor_trident";
        case "knife": return "spr_editor_knife";
    }
    return "";
}

function BattleEditor_WaveRotationModeName(mode) {
    if(mode==1) return "持续转速";
    if(mode==2) return "曲线转到目标角";
    return "不旋转";
}

/// Built-in sprite hazards are first-class presets. They use packaged assets,
/// but keep the same transform/damage/layer system as a custom sprite hazard.
function BattleEditor_NewBuiltinSpriteHazard(x,y,preset,time=0) {
    var result=BattleEditor_NewCustomSpriteHazard(x,y,time);
    result.preset=preset;
    result.name=BattleEditor_BuiltinHazardName(preset);
    result.sprite_source=BattleEditor_BuiltinHazardSprite(preset);
    result.animation.fps=(preset=="friendship_pellet"||preset=="fireball")?8:0;
    result.animation.loop=true;
    result.builtin_locked_sprite=true;
    return result;
}

function BattleEditor_NewWaveHazard(x,y,preset,time=0) {
    var is_true_knife=preset=="true_knife";
    return {
        kind:BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD,
        preset:preset,
        name:BattleEditor_BuiltinHazardName(preset),
        editor_visible:true,
        time:max(0,time),
        transform:BattleEditor_NewTransformTrack(x,y),
        duration:-1,
        warning_time:is_true_knife?12:48,
        active_time:is_true_knife?18:72,
        visual_min_width:is_true_knife?7:10,
        visual_max_width:is_true_knife?40:26,
        warning_width:is_true_knife?40:1.5,
        invincibility_frames:is_true_knife?30:0,
        pre_motion:{direction:0,speed:0,acceleration:0,curve_speed:0,rotation_mode:0,rotation_speed:0,target_angle:0,rotation_time:48,tween:ANIM_TWEEN.SINE,ease:ANIM_EASE.IN_OUT},
        post_motion:{direction:0,speed:0,acceleration:0,curve_speed:0,rotation_mode:0,rotation_speed:0,target_angle:0,rotation_time:is_true_knife?18:72,tween:ANIM_TWEEN.SINE,ease:ANIM_EASE.IN_OUT},
        layer_mode:BATTLE_EDITOR_LAYER.OUTSIDE,
        layer_user_set:false,
        damage_profile:{type:0,damage:is_true_knife?55:2,heal_amount:10,color_rules:true,change_visual:false},
        visual_tint:{enabled:true,mode:1,preset_type:is_true_knife?6:0,custom_color:is_true_knife?c_red:c_white,follow_damage_profile:false,color:is_true_knife?c_red:c_white}
    };
}

function BattleEditor_NewGB(target_x, target_y, time = 0) {
    var track=BattleEditor_NewTransformTrack(320,-64);
    return {
        kind: BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD,
        preset: "gb",
        name: "gb",
        editor_visible: true,
        time: max(0, time),
        transform: track,
        target_x: target_x,
        target_y: target_y,
        spawn_preset: BATTLE_EDITOR_GB_SPAWN.INHERIT,
        spawn_x: 320,
        spawn_y: -64,
        spawn_distance: 800,
        angle_start: 270,
        angle_target: 270,
        damage_profile: {type:0, damage:2, heal_amount:10, color_rules:true, change_visual:false},
        visual_tint: {enabled:true, mode:1, preset_type:0, custom_color:c_white, follow_damage_profile:false, color:c_white},
        move_time: 45,
        charge_time: 35,
        beam_time: 50,
        fake_mode: 0,
        // -1 is the immutable original engine GB. Named custom groups live in
        // project.resources.gb_styles and are referenced by stable UID.
        gb_style_uid: -1,
        // Scratch's GB offset has a fixed movement direction, an initial speed,
        // a per-frame speed change and an independent body rotation. It does
        // not continuously bend the movement direction.
        offset_enabled: false,
        offset_direction_mode: 0,
        offset_direction: 0,
        offset_speed: 0,
        offset_acceleration: 1,
        offset_rotation_speed: 0,
        offset_curve_speed: 0,
        layer_mode: BATTLE_EDITOR_LAYER.OUTSIDE,
        layer_user_set: false
    };
}

function BattleEditor_NewFrame(x, y, cover = 0) {
    return {
        kind: cover ? BATTLE_EDITOR_BOARD_KIND.SUBTRACT : BATTLE_EDITOR_BOARD_KIND.ADD,
        name: cover ? "减框" : "加框",
        shape: "rect",
        cover: cover,
        x: x,
        y: y,
        up: 30,
        down: 30,
        left: 30,
        right: 30,
        angle: 0,
        rotate: 0,
        board_depth: cover ? -10 : 10,
        color_frame: c_white
    };
}

function BattleEditor_FrameRectVertices(frame) {
    return [[-frame.left,-frame.up],[frame.right,-frame.up],[frame.right,frame.down],[-frame.left,frame.down]];
}

function BattleEditor_FrameEnsureVertexUids(project,frame) {
    if(!struct_exists(frame,"vertex_uids")||!is_array(frame.vertex_uids)) frame.vertex_uids=[];
    while(array_length(frame.vertex_uids)<array_length(frame.vertices)) array_push(frame.vertex_uids,BattleEditor_AllocateUid(project));
    if(array_length(frame.vertex_uids)>array_length(frame.vertices)) array_resize(frame.vertex_uids,array_length(frame.vertices));
    return frame.vertex_uids;
}

function BattleEditor_FrameEnsurePolygon(frame,project=undefined) {
    if(is_undefined(project)) project=global.battle_editor_project_runtime;
    if(frame.shape=="polygon"&&struct_exists(frame,"vertices")&&array_length(frame.vertices)>=3){BattleEditor_FrameEnsureVertexUids(project,frame);return frame.vertices;}
    if(frame.shape=="circle"){
        frame.vertices=[];
        for(var i=0;i<16;i++) array_push(frame.vertices,[lengthdir_x(frame.radius_x,i*360/16),lengthdir_y(frame.radius_y,i*360/16)]);
    }else if(frame.shape=="triangle"){
        var triangle_size=struct_exists(frame,"triangle_size")?frame.triangle_size:40;
        frame.vertices=[[0,-triangle_size],[triangle_size*0.866,triangle_size*0.5],[-triangle_size*0.866,triangle_size*0.5]];
    }else frame.vertices=BattleEditor_FrameRectVertices(frame);
    frame.shape="polygon";
    frame.vertex_uids=[];
    BattleEditor_FrameEnsureVertexUids(project,frame);
    return frame.vertices;
}

function BattleEditor_FrameSetPreset(frame,shape) {
    switch(shape){
        case "square":
            frame.shape="rect";
            frame.up=30;frame.down=30;frame.left=30;frame.right=30;
            if(struct_exists(frame,"vertices")) frame.vertices=[];
            if(struct_exists(frame,"vertex_uids")) frame.vertex_uids=[];
            break;
        case "rect":
            frame.shape="rect";
            frame.up=30;frame.down=30;frame.left=45;frame.right=45;
            if(struct_exists(frame,"vertices")) frame.vertices=[];
            if(struct_exists(frame,"vertex_uids")) frame.vertex_uids=[];
            break;
        case "circle":
            frame.shape="circle";
            frame.radius_x=30;frame.radius_y=30;
            frame.up=30;frame.down=30;frame.left=30;frame.right=30;
            if(struct_exists(frame,"vertices")) frame.vertices=[];
            if(struct_exists(frame,"vertex_uids")) frame.vertex_uids=[];
            break;
        case "triangle":
            frame.shape="triangle";
            frame.triangle_size=40;
            if(struct_exists(frame,"vertices")) frame.vertices=[];
            if(struct_exists(frame,"vertex_uids")) frame.vertex_uids=[];
            break;
        case "polygon": BattleEditor_FrameEnsurePolygon(frame); break;
    }
    return frame;
}

function BattleEditor_FrameWorldVertices(frame) {
    var local_vertices;
    if(frame.shape=="polygon"&&struct_exists(frame,"vertices")) local_vertices=frame.vertices;
    else if(frame.shape=="circle"){
        local_vertices=[];
        for(var i=0;i<16;i++) array_push(local_vertices,[lengthdir_x(frame.radius_x,i*360/16),lengthdir_y(frame.radius_y,i*360/16)]);
    }else if(frame.shape=="triangle"){
        var triangle_size=struct_exists(frame,"triangle_size")?frame.triangle_size:40;
        local_vertices=[[0,-triangle_size],[triangle_size*0.866,triangle_size*0.5],[-triangle_size*0.866,triangle_size*0.5]];
    }else local_vertices=BattleEditor_FrameRectVertices(frame);
    var result=[];
    for(var i=0;i<array_length(local_vertices);i++){
        var local_vertex=local_vertices[i];
        array_push(result,RotateAround(frame.x,frame.y,frame.x+local_vertex[0],frame.y+local_vertex[1],frame.x,frame.y,frame.angle));
    }
    return result;
}

function BattleEditor_FrameVertexHit(frame,px,py,radius=9) {
    var vertices=BattleEditor_FrameWorldVertices(frame);
    for(var i=array_length(vertices)-1;i>=0;i--) if(point_distance(px,py,vertices[i][0],vertices[i][1])<=radius) return i;
    return -1;
}

function BattleEditor_FrameSetVertexWorld(frame,index,world_x,world_y) {
    var vertices=BattleEditor_FrameEnsurePolygon(frame);
    if(index<0||index>=array_length(vertices)) return false;
    var local_point=RotateAround(frame.x,frame.y,world_x,world_y,frame.x,frame.y,-frame.angle);
    vertices[index]=[local_point[0]-frame.x,local_point[1]-frame.y];
    frame.vertices=vertices;
    return true;
}

function BattleEditor_FollowFrameData(project,frame_uid,main_preview=undefined) {
    if(!is_undefined(main_preview)&&is_struct(main_preview)&&struct_exists(main_preview,"uid")&&main_preview.uid==frame_uid) return main_preview;
    if(project.initialization.board.uid==frame_uid) return project.initialization.board;
    for(var i=0;i<array_length(project.initialization.frames);i++) if(project.initialization.frames[i].uid==frame_uid) return project.initialization.frames[i];
    return !is_undefined(main_preview)&&is_struct(main_preview)?main_preview:project.initialization.board;
}

function BattleEditor_FollowFrameOptions(project) {
    var result=[project.initialization.board];
    for(var i=0;i<array_length(project.initialization.frames);i++) array_push(result,project.initialization.frames[i]);
    return result;
}

function BattleEditor_FollowFrameCaption(project,frame_uid) {
    var frame=BattleEditor_FollowFrameData(project,frame_uid);
    return string(frame.name)+(frame.kind==BATTLE_EDITOR_BOARD_KIND.MAIN?"（主框）":(frame.cover?"（减框）":"（加框）"));
}

function BattleEditor_FilterClipFrames(project,query="") {
    var frames=BattleEditor_FollowFrameOptions(project);
    var needle=string_lower(string_trim(string(query)));
    if(needle=="") return frames;
    var result=[];
    for(var i=0;i<array_length(frames);i++){
        var frame=frames[i];
        var haystack=string_lower(string(frame.name)+" "+string(frame.control_id)+" "+(frame.cover?"减框 subtract":(frame.kind==BATTLE_EDITOR_BOARD_KIND.MAIN?"主框 main":"加框 add")));
        if(string_pos(needle,haystack)>0) array_push(result,frame);
    }
    return result;
}

function BattleEditor_BoneWorldTransform(event_data,project,main_preview=undefined) {
    var track=event_data.transform;
    if(!struct_exists(event_data,"follow")||!event_data.follow) return {x:track.x,y:track.y,angle:track.angle};
    var frame=BattleEditor_FollowFrameData(project,event_data.follow_target_uid,main_preview);
    var rotated=RotateAround(0,0,track.x,track.y,0,0,frame.angle);
    return {x:frame.x+rotated[0],y:frame.y+rotated[1],angle:track.angle+frame.angle};
}

function BattleEditor_BoneSetFollow(event_data,enabled,project,main_preview=undefined,target_uid=undefined) {
    if(!is_struct(event_data)||event_data.preset!="bone") return false;
    var old_world=BattleEditor_BoneWorldTransform(event_data,project,main_preview);
    if(!is_undefined(target_uid)) event_data.follow_target_uid=target_uid;
    if(enabled){
        var frame=BattleEditor_FollowFrameData(project,event_data.follow_target_uid,main_preview);
        var local=RotateAround(0,0,old_world.x-frame.x,old_world.y-frame.y,0,0,-frame.angle);
        event_data.transform.x=local[0];
        event_data.transform.y=local[1];
        event_data.transform.angle=old_world.angle-frame.angle;
        event_data.follow=true;
    }else{
        event_data.transform.x=old_world.x;
        event_data.transform.y=old_world.y;
        event_data.transform.angle=old_world.angle;
        event_data.follow=false;
    }
    event_data.follow_local_coordinates=true;
    return true;
}

function BattleEditor_DistanceToSegment(px,py,ax,ay,bx,by) {
    var dx=bx-ax,dy=by-ay;
    var denom=dx*dx+dy*dy;
    if(denom<=0) return point_distance(px,py,ax,ay);
    var t=clamp(((px-ax)*dx+(py-ay)*dy)/denom,0,1);
    return point_distance(px,py,ax+dx*t,ay+dy*t);
}

function BattleEditor_FrameAddVertexWorld(frame,world_x,world_y) {
    var vertices=BattleEditor_FrameEnsurePolygon(frame);
    var converted=RotateAround(frame.x,frame.y,world_x,world_y,frame.x,frame.y,-frame.angle);
    array_push(vertices,[converted[0]-frame.x,converted[1]-frame.y]);
    BattleEditor_FrameEnsureVertexUids(global.battle_editor_project_runtime,frame);
    frame.vertices=vertices;
    return array_length(vertices)-1;
}

function BattleEditor_CreateFramePreview(frame,owner=noone) {
    var preview;
    if(frame.shape=="polygon"||frame.shape=="triangle"){
        preview=Battle_CreateBoardPoints(frame.x,frame.y,frame.board_depth,frame.angle,frame.rotate,frame.cover);
        var preview_vertices=BattleEditor_FrameWorldVertices(frame);
        for(var i=0;i<array_length(preview_vertices);i++){
            var local_preview=RotateAround(frame.x,frame.y,preview_vertices[i][0],preview_vertices[i][1],frame.x,frame.y,-frame.angle);
            Battle_AddBoardVertex(preview,local_preview[0]-frame.x,local_preview[1]-frame.y);
        }
    }else if(frame.shape=="circle") preview=Battle_CreateBoardEllipse(frame.x,frame.y,frame.radius_x,frame.radius_y,frame.board_depth,frame.angle,frame.rotate,frame.cover);
    else preview=Battle_CreateBoardRect(frame.x,frame.y,frame.up,frame.down,frame.left,frame.right,frame.board_depth,frame.angle,frame.rotate,frame.cover);
    preview.editor_shape=frame.shape;
    preview.color_frame=frame.color_frame;
    preview.editor_uid=frame.uid;
    preview.editor_name=frame.name;
    preview.control_id=frame.control_id;
    preview.editor_control_uid=struct_exists(frame,"control_uid")?frame.control_uid:-1;
    preview.editor_target_type="board";
    preview.editor_preview_board=true;
    preview.editor_preview_owner=owner;
    // A movement/tween completion is never allowed to delete an editor board.
    // Explicit lifecycle operations below set editor_force_destroy first.
    preview.editor_force_destroy=false;
    preview.editor_destroy_original=preview.destroy;
    preview.destroy=method(preview,function(){
        var owner_active=instance_exists(editor_preview_owner)
            &&((variable_instance_exists(editor_preview_owner,"playing")&&editor_preview_owner.playing)
                ||(variable_instance_exists(editor_preview_owner,"timeline_half_play")&&editor_preview_owner.timeline_half_play));
        if(owner_active&&!editor_force_destroy) return false;
        editor_destroy_original();
        return true;
    });
    preview.editor_vertex_uids=struct_exists(frame,"vertex_uids")?json_parse(json_stringify(frame.vertex_uids)):[];
    return preview;
}

function BattleEditor_NewDecoration(x, y, time = 0) {
    return {
        kind: BATTLE_EDITOR_OBJECT_KIND.DECORATION,
        preset: "custom_sprite",
        name: "decoration",
        editor_visible: true,
        time: max(0,time),
        transform: BattleEditor_NewTransformTrack(x,y),
        duration: -1,
        sprite_source: "",
        animation: BattleEditor_NewAnimation(),
        script_name: "",
        clipped: true,
        layer_mode: BATTLE_EDITOR_LAYER.OUTSIDE,
        visual_tint: {enabled:true, mode:2, preset_type:0, custom_color:c_white, follow_damage_profile:false, color:c_white}
    };
}

function BattleEditor_NewTypewriter(x,y,time=0) {
    return {
        kind:BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER,
        preset:"typewriter",
        name:"typewriter",
        editor_visible:true,
        time:max(0,time),
        transform:BattleEditor_NewTransformTrack(x,y),
        text:"* 在这里输入文字。",
        speed:2,
        font_id:0,
        voice_id:0,
        text_color:"white",
        text_depth:DEPTH_BATTLE.UI_HIGH,
        page_requires_confirm:false,
        page_delay:30,
        layer_mode:BATTLE_EDITOR_LAYER.OUTSIDE
    };
}

function BattleEditor_NewItem() {
    return {
        name: "新物品",
        heal: 20,
        eat_text: "* 你吃掉了新物品。<br>* 恢复了 20 HP。",
        voice_id: 0,
        after_use_mode: BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE
    };
}

/// One-time project migration for supplementary characters entered through
/// Windows. JSON project data is acyclic, so recursively normalizing string
/// values is safe and also repairs old dialogue before the next save rewrites
/// it as standard UTF-8.
function BattleEditor_NormalizeProjectUnicode(value) {
    if(is_string(value)) return TextTyper_NormalizeSupplementaryUnicode(value);
    if(is_array(value)){
        for(var array_index=0;array_index<array_length(value);array_index++) value[array_index]=BattleEditor_NormalizeProjectUnicode(value[array_index]);
        return value;
    }
    if(is_struct(value)){
        var names=variable_struct_get_names(value);
        for(var name_index=0;name_index<array_length(names);name_index++){
            var name=names[name_index];
            variable_struct_set(value,name,BattleEditor_NormalizeProjectUnicode(variable_struct_get(value,name)));
        }
    }
    return value;
}

function BattleEditor_ProjectNormalize(project) {
    if (!is_struct(project)) return BattleEditor_NewProject();
    if (!struct_exists(project, "format")) project.format = "uteu_attack_editor";
    if (!struct_exists(project, "version")) project.version = 2;
    var source_version=real(project.version);
    if(source_version<29) project=BattleEditor_NormalizeProjectUnicode(project);
    if (!struct_exists(project, "name")) project.name = "未命名攻击";
    if (!struct_exists(project, "duration")) project.duration = -1;
    if (!struct_exists(project,"settings")||!is_struct(project.settings)) project.settings={auto_switch_to_objects_on_run:true};
    if (!struct_exists(project.settings,"auto_switch_to_objects_on_run")) project.settings.auto_switch_to_objects_on_run=true;
    if (!struct_exists(project.settings,"developer_force_turn")) project.settings.developer_force_turn=false;
    if (!struct_exists(project.settings,"developer_turn")) project.settings.developer_turn=1;
    if (!struct_exists(project.settings,"developer_force_default_board")) project.settings.developer_force_default_board=false;
    if (!struct_exists(project.settings,"editor_show_objects")) project.settings.editor_show_objects=true;
    project.settings.developer_turn=max(1,round(real(project.settings.developer_turn)));
    if (!struct_exists(project, "next_uid")) project.next_uid = 1;
    if (!struct_exists(project, "events") || !is_array(project.events)) project.events = [];
    if (!struct_exists(project, "script_lists") || !is_array(project.script_lists)) project.script_lists = [];
    // A duplicated list UID is one logical list split by a stale/replayed
    // journal, not several lists.  Merge it before step de-duplication.  The
    // old order did the reverse: it stripped repeated steps from later copies
    // and left an overlapping stack of empty list shells plus one detached
    // wait/branch fragment.
    var merged_lists=[];
    var merged_list_indices={};
    var merged_legacy_list_indices={};
    var merged_old_list_uids=[];
    var merged_new_list_uids=[];
    for(var merge_list_index=0;merge_list_index<array_length(project.script_lists);merge_list_index++){
        var incoming_list=project.script_lists[merge_list_index];
        if(!is_struct(incoming_list)) continue;
        if(!struct_exists(incoming_list,"uid")) incoming_list.uid=BattleEditor_AllocateUid(project);
        if(!struct_exists(incoming_list,"steps")||!is_array(incoming_list.steps)) incoming_list.steps=[];
        var list_uid_key="list_"+string(incoming_list.uid);
        // v32 briefly repaired duplicate UIDs by assigning fresh IDs after
        // their steps had already been split.  Those fragments are still the
        // exact same inaccessible node: same name, entry and pixel position.
        // Coalesce that one historical format once; v33+ may intentionally
        // place two distinct nodes at the same coordinates.
        var legacy_list_key="";
        if(source_version<33&&struct_exists(incoming_list,"name")&&struct_exists(incoming_list,"world_x")&&struct_exists(incoming_list,"world_y")&&struct_exists(incoming_list,"entry_kind")&&struct_exists(incoming_list,"entry_value")){
            legacy_list_key="legacy_"+string(incoming_list.name)+"|"+string(incoming_list.world_x)+"|"+string(incoming_list.world_y)+"|"+string(incoming_list.entry_kind)+"|"+string(incoming_list.entry_value)+"|"+string(struct_exists(incoming_list,"turn")?incoming_list.turn:1);
        }
        var merge_target_index=variable_struct_exists(merged_list_indices,list_uid_key)?variable_struct_get(merged_list_indices,list_uid_key):-1;
        if(merge_target_index<0&&legacy_list_key!=""&&variable_struct_exists(merged_legacy_list_indices,legacy_list_key)) merge_target_index=variable_struct_get(merged_legacy_list_indices,legacy_list_key);
        if(merge_target_index<0){
            var new_merged_index=array_length(merged_lists);
            variable_struct_set(merged_list_indices,list_uid_key,new_merged_index);
            if(legacy_list_key!="") variable_struct_set(merged_legacy_list_indices,legacy_list_key,new_merged_index);
            array_push(merged_lists,incoming_list);
            continue;
        }
        var canonical_list=merged_lists[merge_target_index];
        if(incoming_list.uid!=canonical_list.uid){array_push(merged_old_list_uids,incoming_list.uid);array_push(merged_new_list_uids,canonical_list.uid);}
        var canonical_step_uids={};
        for(var canonical_step_index=0;canonical_step_index<array_length(canonical_list.steps);canonical_step_index++){
            var canonical_step=canonical_list.steps[canonical_step_index];
            if(is_struct(canonical_step)&&struct_exists(canonical_step,"uid")) variable_struct_set(canonical_step_uids,"step_"+string(canonical_step.uid),true);
        }
        for(var incoming_step_index=0;incoming_step_index<array_length(incoming_list.steps);incoming_step_index++){
            var incoming_step=incoming_list.steps[incoming_step_index];
            var incoming_step_key=is_struct(incoming_step)&&struct_exists(incoming_step,"uid")?"step_"+string(incoming_step.uid):"";
            if(incoming_step_key==""||!variable_struct_exists(canonical_step_uids,incoming_step_key)){
                array_push(canonical_list.steps,incoming_step);
                if(incoming_step_key!="") variable_struct_set(canonical_step_uids,incoming_step_key,true);
            }
        }
        var incoming_field_names=variable_struct_get_names(incoming_list);
        for(var incoming_field_index=0;incoming_field_index<array_length(incoming_field_names);incoming_field_index++){
            var incoming_field=incoming_field_names[incoming_field_index];
            if(incoming_field!="steps"&&!variable_struct_exists(canonical_list,incoming_field)) variable_struct_set(canonical_list,incoming_field,variable_struct_get(incoming_list,incoming_field));
        }
    }
    project.script_lists=merged_lists;
    if(array_length(merged_old_list_uids)>0){
        for(var merged_reference_list_index=0;merged_reference_list_index<array_length(project.script_lists);merged_reference_list_index++){
            var merged_reference_list=project.script_lists[merged_reference_list_index];
            for(var merged_reference_step_index=0;merged_reference_step_index<array_length(merged_reference_list.steps);merged_reference_step_index++){
                var merged_reference_step=merged_reference_list.steps[merged_reference_step_index];
                if(!is_struct(merged_reference_step)||!struct_exists(merged_reference_step,"target_list_uid")) continue;
                for(var merged_reference_index=0;merged_reference_index<array_length(merged_old_list_uids);merged_reference_index++) if(merged_reference_step.target_list_uid==merged_old_list_uids[merged_reference_index]){
                    merged_reference_step.target_list_uid=merged_new_list_uids[merged_reference_index];
                    break;
                }
            }
        }
    }
    // A step UID is immutable identity. Two editor processes used to append to
    // the same recovery journal from different stale bases, which could replay
    // one newly-created step two or three times with the exact same UID. The
    // editor and its index-based recovery changes edit the first visible copy,
    // so keep that effective occurrence. Keeping the final stale copy made a
    // corrected field appear to roll back after the next load. Legitimate copy
    // commands always allocate a fresh UID and are never removed here.
    var normalized_step_uids={};
    for(var duplicate_list_index=0;duplicate_list_index<array_length(project.script_lists);duplicate_list_index++){
        var duplicate_list=project.script_lists[duplicate_list_index];
        if(!is_struct(duplicate_list)||!struct_exists(duplicate_list,"steps")||!is_array(duplicate_list.steps)) continue;
        for(var duplicate_step_index=0;duplicate_step_index<array_length(duplicate_list.steps);duplicate_step_index++){
            var duplicate_step=duplicate_list.steps[duplicate_step_index];
            if(!is_struct(duplicate_step)||!struct_exists(duplicate_step,"uid")) continue;
            var duplicate_uid_key="step_"+string(duplicate_step.uid);
            if(variable_struct_exists(normalized_step_uids,duplicate_uid_key)){
                array_delete(duplicate_list.steps,duplicate_step_index,1);
                duplicate_step_index-=1;
            }
            else variable_struct_set(normalized_step_uids,duplicate_uid_key,true);
        }
    }
    if (!struct_exists(project,"variables")||!is_array(project.variables)) project.variables=[];
    if (!struct_exists(project,"resources")||!is_struct(project.resources)) project.resources={audio:[],enemy_textures:[],gb_styles:[]};
    if (!struct_exists(project.resources,"audio")||!is_array(project.resources.audio)) project.resources.audio=[];
    if (!struct_exists(project.resources,"enemy_textures")||!is_array(project.resources.enemy_textures)) project.resources.enemy_textures=[];
    if (!struct_exists(project.resources,"gb_styles")||!is_array(project.resources.gb_styles)) project.resources.gb_styles=[];
    for(var audio_resource_index=array_length(project.resources.audio)-1;audio_resource_index>=0;audio_resource_index--){
        var audio_resource=project.resources.audio[audio_resource_index];
        if(!is_struct(audio_resource)){array_delete(project.resources.audio,audio_resource_index,1);continue;}
        if(!struct_exists(audio_resource,"path")) audio_resource.path="";
        if(!struct_exists(audio_resource,"name")||string_length(string(audio_resource.name))<=0) audio_resource.name=filename_name(string(audio_resource.path));
    }
    for(var enemy_resource_index=array_length(project.resources.enemy_textures)-1;enemy_resource_index>=0;enemy_resource_index--){
        var enemy_resource=project.resources.enemy_textures[enemy_resource_index];
        if(!is_struct(enemy_resource)){array_delete(project.resources.enemy_textures,enemy_resource_index,1);continue;}
        if(!struct_exists(enemy_resource,"uid")) enemy_resource.uid=BattleEditor_AllocateUid(project);
        if(!struct_exists(enemy_resource,"enemy_uid")) enemy_resource.enemy_uid=-1;
        if(!struct_exists(enemy_resource,"path")) enemy_resource.path="";
        if(!struct_exists(enemy_resource,"name")||string_length(string(enemy_resource.name))<=0) enemy_resource.name=filename_name(string(enemy_resource.path));
        if(!struct_exists(enemy_resource,"part_hint")) enemy_resource.part_hint="body";
        if(!struct_exists(enemy_resource,"animation")||!is_struct(enemy_resource.animation)) enemy_resource.animation=BattleEditor_NewAnimation();
        if(!struct_exists(enemy_resource.animation,"frames")||!is_array(enemy_resource.animation.frames)) enemy_resource.animation.frames=[];
        if(!struct_exists(enemy_resource.animation,"frame_count")) enemy_resource.animation.frame_count=1;
        if(!struct_exists(enemy_resource.animation,"fps")) enemy_resource.animation.fps=8;
        if(!struct_exists(enemy_resource.animation,"loop")) enemy_resource.animation.loop=true;
    }
    for(var gb_style_index=array_length(project.resources.gb_styles)-1;gb_style_index>=0;gb_style_index--){
        var gb_style=project.resources.gb_styles[gb_style_index];
        if(!is_struct(gb_style)){array_delete(project.resources.gb_styles,gb_style_index,1);continue;}
        if(!struct_exists(gb_style,"uid")) gb_style.uid=BattleEditor_AllocateUid(project);
        if(!struct_exists(gb_style,"name")||string_length(string_trim(string(gb_style.name)))<=0) gb_style.name="自定义 GB";
        if(!struct_exists(gb_style,"animation")||!is_struct(gb_style.animation)) gb_style.animation=BattleEditor_NewGBAnimation();
        if(!struct_exists(gb_style.animation,"frames")||!is_array(gb_style.animation.frames)||array_length(gb_style.animation.frames)<=0) gb_style.animation.frames=BattleEditor_NewGBAnimation().frames;
        if(!struct_exists(gb_style.animation,"frame_interval")) gb_style.animation.frame_interval=2;
        gb_style.animation.frame_interval=max(1,round(real(gb_style.animation.frame_interval)));
        if(!struct_exists(gb_style,"source_direction")) gb_style.source_direction=0;
        gb_style.source_direction=((round(real(gb_style.source_direction)/90)*90) mod 360+360) mod 360;
        if(!struct_exists(gb_style,"origin_x")) gb_style.origin_x=36;
        if(!struct_exists(gb_style,"origin_y")) gb_style.origin_y=21;
        if(!struct_exists(gb_style,"beam")||!is_struct(gb_style.beam)) gb_style.beam=BattleEditor_NewGBBeam();
        var default_gb_beam=BattleEditor_NewGBBeam();
        if(!struct_exists(gb_style.beam,"variants")||!is_array(gb_style.beam.variants)) gb_style.beam.variants=default_gb_beam.variants;
        while(array_length(gb_style.beam.variants)<3) array_push(gb_style.beam.variants,default_gb_beam.variants[array_length(gb_style.beam.variants)]);
        if(array_length(gb_style.beam.variants)>3) array_resize(gb_style.beam.variants,3);
        for(var gb_beam_variant_index=0;gb_beam_variant_index<3;gb_beam_variant_index++){
            var gb_beam_variant=gb_style.beam.variants[gb_beam_variant_index];
            if(!is_struct(gb_beam_variant)){gb_beam_variant=default_gb_beam.variants[gb_beam_variant_index];gb_style.beam.variants[gb_beam_variant_index]=gb_beam_variant;}
            if(!struct_exists(gb_beam_variant,"animation")||!is_struct(gb_beam_variant.animation)) gb_beam_variant.animation=default_gb_beam.variants[gb_beam_variant_index].animation;
            if(!struct_exists(gb_beam_variant.animation,"frames")||!is_array(gb_beam_variant.animation.frames)||array_length(gb_beam_variant.animation.frames)<=0) gb_beam_variant.animation.frames=default_gb_beam.variants[gb_beam_variant_index].animation.frames;
            if(!struct_exists(gb_beam_variant.animation,"frame_interval")) gb_beam_variant.animation.frame_interval=2;
            gb_beam_variant.animation.frame_interval=max(1,round(real(gb_beam_variant.animation.frame_interval)));
        }
        if(!struct_exists(gb_style.beam,"source_direction")) gb_style.beam.source_direction=default_gb_beam.source_direction;
        gb_style.beam.source_direction=((round(real(gb_style.beam.source_direction)/90)*90) mod 360+360) mod 360;
        if(!struct_exists(gb_style.beam,"source_offset")) gb_style.beam.source_offset=default_gb_beam.source_offset;
        if(!struct_exists(gb_style.beam,"base_scale")) gb_style.beam.base_scale=default_gb_beam.base_scale;
        if(!struct_exists(gb_style.beam,"launch_ratio")) gb_style.beam.launch_ratio=default_gb_beam.launch_ratio;
        if(!struct_exists(gb_style.beam,"breath_ratio")) gb_style.beam.breath_ratio=default_gb_beam.breath_ratio;
        if(!struct_exists(gb_style.beam,"hit_inset")) gb_style.beam.hit_inset=default_gb_beam.hit_inset;
        gb_style.beam.source_offset=max(0,real(gb_style.beam.source_offset));
        gb_style.beam.base_scale=max(0.01,real(gb_style.beam.base_scale));
        gb_style.beam.launch_ratio=max(0,real(gb_style.beam.launch_ratio));
        gb_style.beam.breath_ratio=max(0,real(gb_style.beam.breath_ratio));
        gb_style.beam.hit_inset=max(0,real(gb_style.beam.hit_inset));
        gb_style.name=BattleEditor_UniqueGBStyleName(project,gb_style.name,gb_style.uid);
    }
    for(var variable_index=0;variable_index<array_length(project.variables);variable_index++){
        var variable_data=project.variables[variable_index];
        if(!is_struct(variable_data)){variable_data={name:"变量_"+string(variable_index+1),value:0};project.variables[variable_index]=variable_data;}
        if(!struct_exists(variable_data,"name")) variable_data.name="变量_"+string(variable_index+1);
        if(!struct_exists(variable_data,"value")) variable_data.value=0;
    }
    if (!struct_exists(project, "initialization") || !is_struct(project.initialization)) {
        project.initialization = BattleEditor_NewProject().initialization;
    }
    var init = project.initialization;
    if (!struct_exists(init, "soul")) init.soul = "battle_soul_red";
    if (!struct_exists(init, "player_name")) init.player_name = Player_GetName();
    if (!struct_exists(init, "hp")) init.hp = 128;
    if (!struct_exists(init, "max_hp")) init.max_hp = 128;
    if (!struct_exists(init, "turn_text")) init.turn_text = "* 第一回合";
    if (!struct_exists(init, "turn_text_x")) init.turn_text_x = 58;
    if (!struct_exists(init, "turn_text_y")) init.turn_text_y = 270;
    if (!struct_exists(init, "character_dialogue")) init.character_dialogue = "";
    if (!struct_exists(init, "turn_font")) init.turn_font = 0;
    if (!struct_exists(init, "dialogue_font")) init.dialogue_font = 2;
    if (!struct_exists(init, "turn_voice")) init.turn_voice = 1;
    if (!struct_exists(init, "dialogue_voice")) init.dialogue_voice = 2;
    if (!struct_exists(init, "battle_music")) init.battle_music = "";
    if (!struct_exists(init, "battle_music_frame_sync")) init.battle_music_frame_sync = false;
    if (!struct_exists(init,"mercy_spare_label")) init.mercy_spare_label="* 饶恕";
    if (!struct_exists(init,"mercy_spare_response")) init.mercy_spare_response="";
    if (!struct_exists(init,"mercy_flee_enabled")) init.mercy_flee_enabled=true;
    if (!struct_exists(init,"mercy_flee_label")) init.mercy_flee_label="* 逃跑";
    if (!struct_exists(init,"mercy_flee_success_text")) init.mercy_flee_success_text="";
    if (!struct_exists(init,"mercy_flee_fail_text")) init.mercy_flee_fail_text="";
    init.mercy_spare_label=string(init.mercy_spare_label);
    init.mercy_spare_response=string(init.mercy_spare_response);
    init.mercy_flee_enabled=bool(init.mercy_flee_enabled);
    init.mercy_flee_label=string(init.mercy_flee_label);
    init.mercy_flee_success_text=string(init.mercy_flee_success_text);
    init.mercy_flee_fail_text=string(init.mercy_flee_fail_text);
    init.battle_music=string(init.battle_music);
    init.battle_music_frame_sync=bool(init.battle_music_frame_sync);
    init.turn_voice=clamp(round(real(init.turn_voice)),-1,3);
    init.dialogue_voice=clamp(round(real(init.dialogue_voice)),-1,3);
    if (!struct_exists(init, "enemy_x")) init.enemy_x = 320;
    if (!struct_exists(init, "enemy_y")) init.enemy_y = 166;
    if(!struct_exists(init,"enemies")||!is_array(init.enemies)) init.enemies=[];
    if(array_length(init.enemies)<=0) array_push(init.enemies,BattleEditor_NewEnemy(project,init.enemy_x,init.enemy_y,true));
    var enemy_part_keys=BattleEditor_EnemyPartKeys();
    for(var enemy_index=0;enemy_index<array_length(init.enemies);enemy_index++){
        var enemy_data=init.enemies[enemy_index];
        if(!is_struct(enemy_data)){enemy_data=BattleEditor_NewEnemy(project,init.enemy_x,init.enemy_y,enemy_index==0);init.enemies[enemy_index]=enemy_data;}
        if(!struct_exists(enemy_data,"name")) enemy_data.name="敌人_"+string(enemy_index+1);
        if(!struct_exists(enemy_data,"control_id")) enemy_data.control_id="enemies";
        enemy_data.editor_target_type="enemy";
        BattleEditor_AssignIdentity(project,enemy_data,"敌人_"+string(enemy_index+1),"enemies",true);
        enemy_data.editor_uid=enemy_data.uid;
        if(!struct_exists(enemy_data,"x")) enemy_data.x=enemy_index==0?init.enemy_x:320;
        if(!struct_exists(enemy_data,"y")) enemy_data.y=enemy_index==0?init.enemy_y:166;
        if(!struct_exists(enemy_data,"scale_x")) enemy_data.scale_x=104/212;
        if(!struct_exists(enemy_data,"scale_y")) enemy_data.scale_y=139/324;
        if(!struct_exists(enemy_data,"rig_offset_x")) enemy_data.rig_offset_x=(480-482)*enemy_data.scale_x;
        if(!struct_exists(enemy_data,"rig_offset_y")) enemy_data.rig_offset_y=(360-494)*enemy_data.scale_y;
        if(!struct_exists(enemy_data,"sway_x")) enemy_data.sway_x="cos(time*3.75)*4";
        if(!struct_exists(enemy_data,"torso_y")) enemy_data.torso_y="sin(time*7.5)*3";
        if(!struct_exists(enemy_data,"head_y")) enemy_data.head_y="sin(time*7.5)*4";
        if(!struct_exists(enemy_data,"parts")||!is_struct(enemy_data.parts)) enemy_data.parts={};
        for(var enemy_part_index=0;enemy_part_index<array_length(enemy_part_keys);enemy_part_index++){
            var enemy_part_key=enemy_part_keys[enemy_part_index];
            if(!struct_exists(enemy_data.parts,enemy_part_key)) variable_struct_set(enemy_data.parts,enemy_part_key,BattleEditor_NewEnemyPart(""));
            var enemy_part=variable_struct_get(enemy_data.parts,enemy_part_key);
            if(!struct_exists(enemy_part,"source")) enemy_part.source="";
            if(!struct_exists(enemy_part,"asset_uid")) enemy_part.asset_uid=-1;
            if(!struct_exists(enemy_part,"offset_x")) enemy_part.offset_x=0;
            if(!struct_exists(enemy_part,"offset_y")) enemy_part.offset_y=0;
            if(!struct_exists(enemy_part,"origin_x")) enemy_part.origin_x=0;
            if(!struct_exists(enemy_part,"origin_y")) enemy_part.origin_y=0;
            if(!struct_exists(enemy_part,"deform_with_torso")) enemy_part.deform_with_torso=string(enemy_part.source)=="spr_enemy_dust_legs";
            if(!struct_exists(enemy_part,"deform_sole_offset_y")) enemy_part.deform_sole_offset_y=string(enemy_part.source)=="spr_enemy_dust_legs"?296:0;
            if(!struct_exists(enemy_part,"animation")||!is_struct(enemy_part.animation)) enemy_part.animation=BattleEditor_NewAnimation();
            if(!struct_exists(enemy_part.animation,"frames")||!is_array(enemy_part.animation.frames)) enemy_part.animation.frames=[];
            if(!struct_exists(enemy_part.animation,"frame_count")) enemy_part.animation.frame_count=1;
            if(!struct_exists(enemy_part.animation,"fps")) enemy_part.animation.fps=8;
            if(!struct_exists(enemy_part.animation,"loop")) enemy_part.animation.loop=true;
        }
        if(!struct_exists(enemy_data,"animation_scripts")||!is_struct(enemy_data.animation_scripts)) enemy_data.animation_scripts={gravity_up:"",gravity_down:"",gravity_left:"",gravity_right:""};
        if(!struct_exists(enemy_data.animation_scripts,"gravity_up")) enemy_data.animation_scripts.gravity_up="";
        if(!struct_exists(enemy_data.animation_scripts,"gravity_down")) enemy_data.animation_scripts.gravity_down="";
        if(!struct_exists(enemy_data.animation_scripts,"gravity_left")) enemy_data.animation_scripts.gravity_left="";
        if(!struct_exists(enemy_data.animation_scripts,"gravity_right")) enemy_data.animation_scripts.gravity_right="";
        if(!struct_exists(enemy_data,"actions")||!is_array(enemy_data.actions)){
            enemy_data.actions=[];
            if(enemy_index==0){
                array_push(enemy_data.actions,BattleEditor_NewEnemyAction(project,"查看","* 三个方框盯着你。&* 其中至少两个并不存在。"));
                array_push(enemy_data.actions,BattleEditor_NewEnemyAction(project,"测试","* 这是机制测试对象。&* 它拒绝提供任何背景故事。"));
                array_push(enemy_data.actions,BattleEditor_NewEnemyAction(project,"下一回合","* 你要求进入下一回合。&* 攻击测试照常开始。"));
            }else array_push(enemy_data.actions,BattleEditor_NewEnemyAction(project));
        }
        if(array_length(enemy_data.actions)>6) array_resize(enemy_data.actions,6);
        for(var enemy_action_index=0;enemy_action_index<array_length(enemy_data.actions);enemy_action_index++){
            var enemy_action=enemy_data.actions[enemy_action_index];
            if(!is_struct(enemy_action)){enemy_action=BattleEditor_NewEnemyAction(project,"行动 "+string(enemy_action_index+1),string(enemy_action));enemy_data.actions[enemy_action_index]=enemy_action;}
            if(!struct_exists(enemy_action,"uid")) enemy_action.uid=BattleEditor_AllocateUid(project);
            if(!struct_exists(enemy_action,"name")) enemy_action.name="行动 "+string(enemy_action_index+1);
            if(!struct_exists(enemy_action,"text")) enemy_action.text="";
        }
    }
    init.enemy_x=init.enemies[0].x;
    init.enemy_y=init.enemies[0].y;
    if (!struct_exists(init, "hud_x")) init.hud_x = 30;
    if (!struct_exists(init, "hud_y")) init.hud_y = 401;
    if (!struct_exists(init,"hud_show_hp_label")) init.hud_show_hp_label=true;
    if (!struct_exists(init,"hud_show_bar")) init.hud_show_bar=true;
    if (!struct_exists(init,"hud_show_kr")) init.hud_show_kr=true;
    if (!struct_exists(init,"hud_show_numbers")) init.hud_show_numbers=true;
    if (!struct_exists(init,"hud_show_shield")) init.hud_show_shield=true;
    if (!struct_exists(init,"hud_show_overhead")) init.hud_show_overhead=false;
    if (!struct_exists(init,"shield_enabled")) init.shield_enabled=true;
    if (!struct_exists(init,"shield_hud_mode")) init.shield_hud_mode=BATTLE_SHIELD_HUD_MODE.BELOW_HP;
    if (!struct_exists(init, "board_color_default")) init.board_color_default = c_white;
    if (!struct_exists(init, "board") || !is_struct(init.board)) init.board = {kind:BATTLE_EDITOR_BOARD_KIND.MAIN,name:"主框",shape:"rect",cover:false,x:BATTLE_BOARD.X,y:BATTLE_BOARD.Y,up:BATTLE_BOARD.UP,down:BATTLE_BOARD.DOWN,left:BATTLE_BOARD.LEFT,right:BATTLE_BOARD.RIGHT,angle:0,rotate:0,board_depth:0};
    if (!struct_exists(init.board, "kind")) init.board.kind=BATTLE_EDITOR_BOARD_KIND.MAIN;
    if (!struct_exists(init.board, "name")) init.board.name="主框";
    if (!struct_exists(init.board, "shape")) init.board.shape="rect";
    if (!struct_exists(init.board, "cover")) init.board.cover=false;
    if (!struct_exists(init.board, "x")) init.board.x=BATTLE_BOARD.X;
    if (!struct_exists(init.board, "y")) init.board.y=BATTLE_BOARD.Y;
    if (!struct_exists(init.board, "up")) init.board.up=BATTLE_BOARD.UP;
    if (!struct_exists(init.board, "down")) init.board.down=BATTLE_BOARD.DOWN;
    if (!struct_exists(init.board, "left")) init.board.left=BATTLE_BOARD.LEFT;
    if (!struct_exists(init.board, "right")) init.board.right=BATTLE_BOARD.RIGHT;
    if (!struct_exists(init.board, "angle")) init.board.angle = 0;
    if (!struct_exists(init.board, "rotate")) init.board.rotate = 0;
    if (!struct_exists(init.board, "board_depth")) init.board.board_depth = 0;
    if (!struct_exists(init.board,"radius_x")) init.board.radius_x=30;
    if (!struct_exists(init.board,"radius_y")) init.board.radius_y=30;
    if (!struct_exists(init.board,"vertices")) init.board.vertices=[];
    if(!struct_exists(init.board,"triangle_size")) init.board.triangle_size=40;
    if(init.board.shape=="polygon") BattleEditor_FrameEnsureVertexUids(project,init.board);
    if (!struct_exists(init.board,"color_frame")) init.board.color_frame=init.board_color_default;
    BattleEditor_AssignIdentity(project,init.board,"主框","main_board",true);
    if (!struct_exists(init, "frames") || !is_array(init.frames)) init.frames = [];
    for(var frame_index=0;frame_index<array_length(init.frames);frame_index++){
        var frame=init.frames[frame_index];
        if(!struct_exists(frame,"kind")) frame.kind=frame.cover?BATTLE_EDITOR_BOARD_KIND.SUBTRACT:BATTLE_EDITOR_BOARD_KIND.ADD;
        if(!struct_exists(frame,"name")) frame.name=frame.cover?"减框":"加框";
        if(!struct_exists(frame,"shape")) frame.shape="rect";
        if(!struct_exists(frame,"radius_x")) frame.radius_x=30;
        if(!struct_exists(frame,"radius_y")) frame.radius_y=30;
        if(!struct_exists(frame,"vertices")) frame.vertices=[];
        if(!struct_exists(frame,"triangle_size")) frame.triangle_size=40;
        if(frame.shape=="polygon") BattleEditor_FrameEnsureVertexUids(project,frame);
        if(!struct_exists(frame,"rotate")) frame.rotate=0;
        if(!struct_exists(frame,"board_depth")) frame.board_depth=frame.cover?-10:10;
        if(!struct_exists(frame,"color_frame")) frame.color_frame=init.board_color_default;
        BattleEditor_AssignIdentity(project,frame,frame.cover?"减框":"加框","",true);
    }
    if (!struct_exists(init,"gb_spawn_default")||!is_struct(init.gb_spawn_default)) init.gb_spawn_default={preset:BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP,x:320,y:-560,angle:270,distance:800};
    if (!struct_exists(init.gb_spawn_default,"preset")||init.gb_spawn_default.preset==BATTLE_EDITOR_GB_SPAWN.INHERIT) init.gb_spawn_default.preset=BATTLE_EDITOR_GB_SPAWN.SCREEN_TOP;
    if (!struct_exists(init.gb_spawn_default,"x")) init.gb_spawn_default.x=320;
    if (!struct_exists(init.gb_spawn_default,"y")) init.gb_spawn_default.y=-64;
    if (!struct_exists(init.gb_spawn_default,"angle")) init.gb_spawn_default.angle=270;
    init.gb_spawn_default.distance=800;
    if (!struct_exists(init, "items") || !is_array(init.items)) init.items = BattleEditor_DefaultItems();
    if(!struct_exists(init,"lv")) init.lv=25;
    if(!struct_exists(init,"atk")) init.atk=10;
    if(!struct_exists(init,"def")) init.def=10;
    if(!struct_exists(init,"shield_natural_max")) init.shield_natural_max=100;
    if(!struct_exists(init,"shield_max")) init.shield_max=init.shield_natural_max;
    if(!struct_exists(init,"shield")) init.shield=init.shield_max;
    if(!struct_exists(init,"natural_max_hp")) init.natural_max_hp=max(1,init.max_hp);
    init.natural_max_hp=max(1,real(init.natural_max_hp));
    init.max_hp=clamp(real(init.max_hp),1,init.natural_max_hp);
    init.hp=clamp(real(init.hp),0,init.max_hp);
    if(!struct_exists(init,"player_board")||!is_struct(init.player_board)) init.player_board={x:BATTLE_BOARD.X,y:BATTLE_BOARD.Y,up:BATTLE_BOARD.UP,down:BATTLE_BOARD.DOWN,left:BATTLE_BOARD.LEFT,right:BATTLE_BOARD.RIGHT,angle:0};
    var player_board_data=init.player_board;
    if(!struct_exists(player_board_data,"x")) player_board_data.x=BATTLE_BOARD.X;
    if(!struct_exists(player_board_data,"y")) player_board_data.y=BATTLE_BOARD.Y;
    if(!struct_exists(player_board_data,"up")) player_board_data.up=BATTLE_BOARD.UP;
    if(!struct_exists(player_board_data,"down")) player_board_data.down=BATTLE_BOARD.DOWN;
    if(!struct_exists(player_board_data,"left")) player_board_data.left=BATTLE_BOARD.LEFT;
    if(!struct_exists(player_board_data,"right")) player_board_data.right=BATTLE_BOARD.RIGHT;
    if(!struct_exists(player_board_data,"angle")) player_board_data.angle=0;
    // Monster-turn board dimensions are authored data. In particular, keep
    // the legacy 130 x 130 square instead of silently replacing it with the
    // separate player/menu rectangle.
    // Turn presentation is indexed independently from the attack workspace.
    // Legacy files keep their original first-turn text and dialogue.
    if(!struct_exists(project,"turns")||!is_array(project.turns)){
        project.turns=[{turn:1,text:init.turn_text,dialogue:init.character_dialogue,turn_font:init.turn_font,dialogue_font:init.dialogue_font,turn_voice:init.turn_voice,dialogue_voice:init.dialogue_voice,
            dialogue_template:0,dialogue_offset_x:92,dialogue_offset_y:-34}];
    }
    for(var turn_data_index=0;turn_data_index<array_length(project.turns);turn_data_index++){
        var turn_data=project.turns[turn_data_index];
        if(!is_struct(turn_data)){
            turn_data={turn:turn_data_index+1,text:"* 第"+string(turn_data_index+1)+"回合",dialogue:"",turn_font:init.turn_font,dialogue_font:init.dialogue_font,turn_voice:init.turn_voice,dialogue_voice:init.dialogue_voice,
                dialogue_template:0,dialogue_offset_x:92,dialogue_offset_y:-34};
            project.turns[turn_data_index]=turn_data;
        }
        if(!struct_exists(turn_data,"turn")) turn_data.turn=turn_data_index+1;
        turn_data.turn=max(1,round(real(turn_data.turn)));
        if(!struct_exists(turn_data,"text")) turn_data.text="* 第"+string(turn_data.turn)+"回合";
        if(!struct_exists(turn_data,"dialogue")) turn_data.dialogue="";
        if(!struct_exists(turn_data,"turn_font")) turn_data.turn_font=init.turn_font;
        if(!struct_exists(turn_data,"dialogue_font")) turn_data.dialogue_font=init.dialogue_font;
        if(!struct_exists(turn_data,"turn_voice")) turn_data.turn_voice=init.turn_voice;
        if(!struct_exists(turn_data,"dialogue_voice")) turn_data.dialogue_voice=init.dialogue_voice;
        turn_data.turn_voice=clamp(round(real(turn_data.turn_voice)),-1,3);
        turn_data.dialogue_voice=clamp(round(real(turn_data.dialogue_voice)),-1,3);
        if(!struct_exists(turn_data,"dialogue_template")) turn_data.dialogue_template=0;
        if(!struct_exists(turn_data,"dialogue_offset_x")) turn_data.dialogue_offset_x=92;
        if(!struct_exists(turn_data,"dialogue_offset_y")) turn_data.dialogue_offset_y=-34;
        turn_data.dialogue_template=clamp(round(real(turn_data.dialogue_template)),0,4);
    }
    for(var item_index=0;item_index<array_length(init.items);item_index++){
        var normalized_item=init.items[item_index];
        if(!struct_exists(normalized_item,"uid")) normalized_item.uid=BattleEditor_AllocateUid(project);
        if(!struct_exists(normalized_item,"on_use_script")) normalized_item.on_use_script="";
        if(!struct_exists(normalized_item,"voice_id")) normalized_item.voice_id=0;
        if(!struct_exists(normalized_item,"after_use_mode")) normalized_item.after_use_mode=BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE;
        normalized_item.voice_id=clamp(round(real(normalized_item.voice_id)),-1,3);
        normalized_item.after_use_mode=clamp(round(real(normalized_item.after_use_mode)),BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE,BATTLE_EDITOR_ITEM_AFTER_USE.REPLACE_TURN);
    }
    for(var i=0;i<array_length(project.events);i++){
        var e=project.events[i];
        // Versions through v31 shared one untagged scene timeline. Preserve
        // every existing object as authored first-turn content.
        if(!struct_exists(e,"turn")) e.turn=1;
        e.turn=max(1,round(real(e.turn)));
        var fallback_name="对象";
        if(struct_exists(e,"preset")&&e.preset=="bone") fallback_name=struct_exists(e,"bone_style")&&round(real(e.bone_style))==1?"骨刺":"骨头";
        else if(struct_exists(e,"preset")&&e.preset=="platform") fallback_name="蓝魂平台";
        else if(struct_exists(e,"preset")&&e.preset=="gb") fallback_name="GB";
        else if(struct_exists(e,"preset")&&(e.preset=="slash"||e.preset=="true_knife")) fallback_name=BattleEditor_BuiltinHazardName(e.preset);
        else if(struct_exists(e,"preset")&&e.preset!="custom_sprite") fallback_name=BattleEditor_BuiltinHazardName(e.preset);
        else if(struct_exists(e,"kind")&&e.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION) fallback_name="装饰";
        else if(struct_exists(e,"kind")&&e.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER) fallback_name="打字机";
        BattleEditor_AssignIdentity(project,e,fallback_name,"",true);
        if(!struct_exists(e,"editor_visible")) e.editor_visible=true;
        if(e.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
            if(!struct_exists(e,"voice_id")) e.voice_id=0;
            e.voice_id=clamp(round(real(e.voice_id)),-1,3);
        }
        if(!struct_exists(e,"transform")){
            var old_x=struct_exists(e,"x")?e.x:320;
            var old_y=struct_exists(e,"y")?e.y:320;
            e.transform=BattleEditor_NewTransformTrack(old_x,old_y);
            if(struct_exists(e,"angle")) e.transform.angle=e.angle;
            if(struct_exists(e,"scale_x")) e.transform.scale_x=e.scale_x;
            if(struct_exists(e,"scale_y")) e.transform.scale_y=e.scale_y;
        }
        if(!struct_exists(e.transform,"x")) e.transform.x=320;
        if(!struct_exists(e.transform,"y")) e.transform.y=320;
        if(!struct_exists(e.transform,"scale_x")) e.transform.scale_x=1;
        if(!struct_exists(e.transform,"scale_y")) e.transform.scale_y=1;
        if(!struct_exists(e.transform,"angle")) e.transform.angle=0;
        if(!struct_exists(e.transform,"alpha")) e.transform.alpha=1;
        if(!struct_exists(e.transform,"color")) e.transform.color=c_white;
        if(!struct_exists(e.transform,"tween")) e.transform.tween=ANIM_TWEEN.SINE;
        if(!struct_exists(e.transform,"ease")) e.transform.ease=ANIM_EASE.IN_OUT;
        if(!struct_exists(e,"duration")) e.duration=-1;
        if(e.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
            if(!struct_exists(e,"text")) e.text="* 在这里输入文字。";
            if(!struct_exists(e,"speed")) e.speed=2;
            if(!struct_exists(e,"font_id")) e.font_id=0;
            if(!struct_exists(e,"text_color")) e.text_color="white";
            if(!struct_exists(e,"text_depth")) e.text_depth=DEPTH_BATTLE.UI_HIGH;
            if(!struct_exists(e,"page_requires_confirm")) e.page_requires_confirm=false;
            if(!struct_exists(e,"page_delay")) e.page_delay=30;
        }
        if(!struct_exists(e,"preset")) e.preset=e.kind==0?"bone":"gb";
        if(!struct_exists(e,"damage_profile")&&e.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION&&(!struct_exists(e,"preset")||e.preset!="platform")){
            var old_type=struct_exists(e,"type")?e.type:0;
            e.damage_profile={type:old_type,damage:2,heal_amount:10,color_rules:true,change_visual:true};
        }
        if(struct_exists(e,"damage_profile")&&!struct_exists(e.damage_profile,"heal_amount")) e.damage_profile.heal_amount=10;
        if(struct_exists(e,"damage_profile")&&!struct_exists(e.damage_profile,"change_visual")) e.damage_profile.change_visual=true;
        // v8 created every colour with white's value (2). Migrate only that
        // known default, leaving any number the author actually changed alone.
        if(source_version<9&&struct_exists(e,"damage_profile")&&e.damage_profile.damage==2){
            var migrated_damage_type=round(real(e.damage_profile.type));
            if(migrated_damage_type>=4) e.damage_profile.damage=BattleEditor_DefaultDamageForType(migrated_damage_type);
        }
        if(!struct_exists(e,"visual_tint")) e.visual_tint={enabled:true,mode:e.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION?2:0,preset_type:0,custom_color:c_white,follow_damage_profile:e.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION,color:c_white};
        if(!struct_exists(e.visual_tint,"follow_damage_profile")) e.visual_tint.follow_damage_profile=e.kind!=BATTLE_EDITOR_OBJECT_KIND.DECORATION;
        if(!struct_exists(e.visual_tint,"color")) e.visual_tint.color=c_white;
        if(!struct_exists(e.visual_tint,"mode")) e.visual_tint.mode=e.visual_tint.follow_damage_profile?0:2;
        if(!struct_exists(e.visual_tint,"preset_type")) e.visual_tint.preset_type=struct_exists(e,"damage_profile")?clamp(round(real(e.damage_profile.type)),0,8):0;
        if(!struct_exists(e.visual_tint,"custom_color")) e.visual_tint.custom_color=e.visual_tint.color;
        BattleEditor_SetVisualTintMode(e,e.visual_tint.mode);
        if((struct_exists(e,"sprite_source")||e.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION)&&!struct_exists(e,"animation")) e.animation=BattleEditor_NewAnimation();
        if(struct_exists(e,"animation")){
            if(!struct_exists(e.animation,"frames")||!is_array(e.animation.frames)) e.animation.frames=[];
            if(!struct_exists(e.animation,"frame_count")) e.animation.frame_count=1;
            if(!struct_exists(e.animation,"fps")) e.animation.fps=8;
            if(!struct_exists(e.animation,"loop")) e.animation.loop=true;
        }
        if(!struct_exists(e,"clipped")) e.clipped=true;
        if(!struct_exists(e,"layer_mode")) e.layer_mode=e.clipped?BATTLE_EDITOR_LAYER.IN_BOARD:BATTLE_EDITOR_LAYER.OUTSIDE;
        // Earlier builds overwrote each mechanic preset's OUTSIDE default with
        // the generic creation layer. Migrate that accidental value once. An
        // explicit author choice sets layer_user_set and is then preserved.
        if(e.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&!struct_exists(e,"layer_user_set")){
            e.layer_mode=BATTLE_EDITOR_LAYER.OUTSIDE;
            e.layer_user_set=false;
        }
        e.clipped=e.layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD;
        if(!struct_exists(e,"clip_mode")) e.clip_mode="all";
        if(!struct_exists(e,"clip_frame_uids")||!is_array(e.clip_frame_uids)) e.clip_frame_uids=[];
        if(!struct_exists(e,"clipped_collision")) e.clipped_collision=true;
        if(e.preset=="bone_3d"||e.preset=="bone_4d"){
            var solid_defaults=BattleEditor_NewSolidBone(e.transform.x,e.transform.y,e.preset,e.time);
            var solid_keys=BattleEditor_SolidBoneFieldKeys(e.preset);
            for(var solid_key_index=0;solid_key_index<array_length(solid_keys);solid_key_index++){
                var solid_key=solid_keys[solid_key_index];
                if(solid_key=="x"||solid_key=="y"||solid_key=="time"||solid_key=="duration"||solid_key=="damage_type"||solid_key=="damage") continue;
                if(!struct_exists(e,solid_key)) variable_struct_set(e,solid_key,variable_struct_get(solid_defaults,solid_key));
            }
            e.duration=real(e.duration)<0?-1:max(1,real(e.duration));
            e.edge_trim=max(0,real(e.edge_trim));
            e.perspective_distance=max(32,real(e.perspective_distance));
            e.perspective4d_distance=max(32,real(e.perspective4d_distance));
        }else if(e.preset=="platform"){
            if(!struct_exists(e,"width")) e.width=48;
            if(!struct_exists(e,"sticky")) e.sticky=true;
            if(!struct_exists(e,"bounce")) e.bounce=false;
            if(!struct_exists(e,"hspeed")) e.hspeed=0;
            if(!struct_exists(e,"vspeed")) e.vspeed=0;
            if(!struct_exists(e,"auto_destroy")) e.auto_destroy=false;
            e.width=max(4,real(e.width));
        }else if(e.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&e.preset=="gb"){
            if(!struct_exists(e,"gb_style_uid")) e.gb_style_uid=-1;
            if(real(e.gb_style_uid)>=0&&is_undefined(BattleEditor_FindGBStyle(project,e.gb_style_uid))) e.gb_style_uid=-1;
            if(!struct_exists(e,"spawn_preset")) e.spawn_preset=BATTLE_EDITOR_GB_SPAWN.CUSTOM;
            if(!struct_exists(e,"spawn_x")) e.spawn_x=e.transform.x;
            if(!struct_exists(e,"spawn_y")) e.spawn_y=e.transform.y;
            e.spawn_distance=800;
            if(!struct_exists(e,"angle_start")) e.angle_start=270;
            if(!struct_exists(e,"angle_target")) e.angle_target=e.angle_start;
            if(!struct_exists(e,"offset_enabled")) e.offset_enabled=false;
            // Older editor builds exposed only a numeric direction. Preserve
            // that authored value as an absolute angle; newly created GBs use
            // Scratch's blank-direction shorthand (current angle + 180).
            if(!struct_exists(e,"offset_direction_mode")) e.offset_direction_mode=1;
            if(!struct_exists(e,"offset_direction")) e.offset_direction=0;
            if(!struct_exists(e,"offset_speed")) e.offset_speed=0;
            if(!struct_exists(e,"offset_acceleration")) e.offset_acceleration=1;
            if(!struct_exists(e,"offset_rotation_speed")) e.offset_rotation_speed=0;
            if(!struct_exists(e,"offset_curve_speed")) e.offset_curve_speed=0;
        }else if(e.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(e.preset=="slash"||e.preset=="true_knife")){
            var normalized_true_knife=e.preset=="true_knife";
            if(!struct_exists(e,"warning_time")) e.warning_time=normalized_true_knife?12:48;
            if(!struct_exists(e,"active_time")) e.active_time=normalized_true_knife?30:72;
            if(!struct_exists(e,"visual_min_width")) e.visual_min_width=normalized_true_knife?7:10;
            if(!struct_exists(e,"visual_max_width")) e.visual_max_width=normalized_true_knife?40:26;
            if(!struct_exists(e,"warning_width")) e.warning_width=normalized_true_knife?40:max(0.5,e.visual_min_width*0.15);
            if(!struct_exists(e,"invincibility_frames")) e.invincibility_frames=normalized_true_knife?30:0;
            if(!struct_exists(e,"pre_motion")) e.pre_motion={direction:0,speed:0,acceleration:0,curve_speed:0,rotation_mode:0,rotation_speed:0,target_angle:e.transform.angle,rotation_time:e.warning_time,tween:ANIM_TWEEN.SINE,ease:ANIM_EASE.IN_OUT};
            if(!struct_exists(e,"post_motion")) e.post_motion={direction:0,speed:0,acceleration:0,curve_speed:0,rotation_mode:0,rotation_speed:0,target_angle:e.transform.angle,rotation_time:e.active_time,tween:ANIM_TWEEN.SINE,ease:ANIM_EASE.IN_OUT};
            var motion_sets=[e.pre_motion,e.post_motion];
            for(var motion_index=0;motion_index<2;motion_index++){
                var motion=motion_sets[motion_index];
                if(!struct_exists(motion,"direction")) motion.direction=0;
                if(!struct_exists(motion,"speed")) motion.speed=0;
                if(!struct_exists(motion,"acceleration")) motion.acceleration=0;
                if(!struct_exists(motion,"curve_speed")) motion.curve_speed=0;
                if(!struct_exists(motion,"rotation_mode")) motion.rotation_mode=0;
                if(!struct_exists(motion,"rotation_speed")) motion.rotation_speed=0;
                if(!struct_exists(motion,"target_angle")) motion.target_angle=e.transform.angle;
                if(!struct_exists(motion,"rotation_time")) motion.rotation_time=motion_index==0?e.warning_time:e.active_time;
                if(!struct_exists(motion,"tween")) motion.tween=ANIM_TWEEN.SINE;
                if(!struct_exists(motion,"ease")) motion.ease=ANIM_EASE.IN_OUT;
                motion.rotation_mode=clamp(round(motion.rotation_mode),0,2);
            }
            if(normalized_true_knife){
                // True Knife timing/width is an engine preset. Existing editor
                // files are migrated to the same visible release animation.
                e.warning_time=12;
                e.active_time=18;
                e.visual_min_width=7;
                e.visual_max_width=40;
                e.warning_width=40;
                e.invincibility_frames=max(0,round(real(e.invincibility_frames)));
                // True Knife is one configurable high-damage hit. Old files
                // already normalized to 55 keep that value, while new and
                // edited files are no longer overwritten whenever they load.
                e.damage_profile.damage=max(0,real(e.damage_profile.damage));
                // The constructor supplies the red/free-colour default. Do not
                // overwrite an author's later choice every time the file loads;
                // mode and its legacy compatibility flag were normalized above.
            }else{
                // Slash exposes one visual width. The breathing maximum is
                // 2.6x and the crisp warning is 0.15x (10px -> 26px / 1.5px).
                e.visual_max_width=max(1,e.visual_min_width*2.6);
                e.warning_width=max(0.5,e.visual_min_width*0.15);
            }
        }else if(e.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&e.preset=="bone"){
            if(!struct_exists(e,"bone_style")) e.bone_style=0;
            e.bone_style=clamp(round(real(e.bone_style)),0,1);
            if(!struct_exists(e,"follow")) e.follow=false;
            if(!struct_exists(e,"follow_target_uid")||e.follow_target_uid<0) e.follow_target_uid=init.board.uid;
            // Migrate the former absolute followed position once. New files
            // store a true local offset relative to the selected frame.
            if(!struct_exists(e,"follow_local_coordinates")){
                if(e.follow){
                    var legacy_follow_frame=BattleEditor_FollowFrameData(project,e.follow_target_uid);
                    var legacy_local=RotateAround(0,0,e.transform.x-legacy_follow_frame.x,e.transform.y-legacy_follow_frame.y,0,0,-legacy_follow_frame.angle);
                    e.transform.x=legacy_local[0];e.transform.y=legacy_local[1];
                    e.transform.angle-=legacy_follow_frame.angle;
                }
                e.follow_local_coordinates=true;
            }
            // Kept only so old scripts that inspect these fields do not fail.
            e.follow_board=e.follow;
            e.follow_angle=0;
            if(!struct_exists(e,"point")) e.point=0;
            if(!struct_exists(e,"point_at")) e.point_at=0;
            if(!struct_exists(e,"aim_enabled")) e.aim_enabled=false;
            if(!struct_exists(e,"aim_target_uid")) e.aim_target_uid=-1;
            if(!struct_exists(e,"aim_continuous")) e.aim_continuous=true;
            if(!struct_exists(e,"aim_move_enabled")) e.aim_move_enabled=false;
            if(!struct_exists(e,"aim_move_speed")) e.aim_move_speed=0;
            if(!struct_exists(e,"green_guard_blockable")) e.green_guard_blockable=false;
            if(!struct_exists(e,"green_guard_destroy_on_block")) e.green_guard_destroy_on_block=false;
        }
    }
    // Old projects often reused generic object names. Keep control IDs intact,
    // but make author-facing names unique in a stable project order.
    init.board.name=BattleEditor_MakeUniqueName(project,init.board.name,init.board.uid);
    for(var enemy_name_index=0;enemy_name_index<array_length(init.enemies);enemy_name_index++){
        var named_enemy=init.enemies[enemy_name_index];
        named_enemy.name=BattleEditor_MakeUniqueName(project,named_enemy.name,named_enemy.uid);
    }
    for(var frame_name_index=0;frame_name_index<array_length(init.frames);frame_name_index++){
        var named_frame=init.frames[frame_name_index];
        named_frame.name=BattleEditor_MakeUniqueName(project,named_frame.name,named_frame.uid);
    }
    for(var event_name_index=0;event_name_index<array_length(project.events);event_name_index++){
        var named_event=project.events[event_name_index];
        named_event.name=BattleEditor_MakeUniqueName(project,named_event.name,named_event.uid);
    }
    // List UIDs are also identities used by node links and by the recovery
    // journal. Preserve every list, but repair duplicate IDs left by the old
    // double-replay bug so future field records can address one list exactly.
    for(var list_uid_scan_index=0;list_uid_scan_index<array_length(project.script_lists);list_uid_scan_index++){
        var list_uid_scan=project.script_lists[list_uid_scan_index];
        if(!is_struct(list_uid_scan)) continue;
        if(struct_exists(list_uid_scan,"uid")&&is_real(list_uid_scan.uid)) project.next_uid=max(project.next_uid,list_uid_scan.uid+1);
        if(!struct_exists(list_uid_scan,"steps")||!is_array(list_uid_scan.steps)) continue;
        for(var step_uid_scan_index=0;step_uid_scan_index<array_length(list_uid_scan.steps);step_uid_scan_index++){
            var step_uid_scan=list_uid_scan.steps[step_uid_scan_index];
            if(is_struct(step_uid_scan)&&struct_exists(step_uid_scan,"uid")&&is_real(step_uid_scan.uid)) project.next_uid=max(project.next_uid,step_uid_scan.uid+1);
        }
    }
    var normalized_list_uids={};
    for(var script_list_index=0;script_list_index<array_length(project.script_lists);script_list_index++){
        var script_list=project.script_lists[script_list_index];
        var list_uid_key=struct_exists(script_list,"uid")?"list_"+string(script_list.uid):"";
        if(list_uid_key==""||variable_struct_exists(normalized_list_uids,list_uid_key)){
            script_list.uid=BattleEditor_AllocateUid(project);
            list_uid_key="list_"+string(script_list.uid);
        }
        variable_struct_set(normalized_list_uids,list_uid_key,true);
        if(!struct_exists(script_list,"name")) script_list.name="列表_"+string(script_list.uid);
        if(!struct_exists(script_list,"world_x")) script_list.world_x=0;
        if(!struct_exists(script_list,"world_y")) script_list.world_y=0;
        if(!struct_exists(script_list,"entry_kind")) script_list.entry_kind=BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN;
        if(!struct_exists(script_list,"entry_value")) script_list.entry_value=1;
        if(!struct_exists(script_list,"turn")) script_list.turn=1;
        script_list.turn=max(1,round(real(script_list.turn)));
        if(!struct_exists(script_list,"steps")||!is_array(script_list.steps)) script_list.steps=[];
        for(var script_step_index=0;script_step_index<array_length(script_list.steps);script_step_index++){
            var script_step=script_list.steps[script_step_index];
            if(!struct_exists(script_step,"uid")) script_step.uid=BattleEditor_AllocateUid(project);
            if(!struct_exists(script_step,"kind")) script_step.kind="wait";
            if(!struct_exists(script_step,"duration")) script_step.duration=60;
            if(!struct_exists(script_step,"wait_mode")) script_step.wait_mode=0;
            if(!struct_exists(script_step,"wait_extra_duration")) script_step.wait_extra_duration=0;
            if(!struct_exists(script_step,"target_mode")) script_step.target_mode="control_id";
            if(!struct_exists(script_step,"control_source_mode")) script_step.control_source_mode=0;
            script_step.control_source_mode=clamp(round(real(script_step.control_source_mode)),0,1);
            if(!struct_exists(script_step,"copy_control_id")) script_step.copy_control_id="";
            if(!struct_exists(script_step,"copy_control_id_auto")) script_step.copy_control_id_auto=string_length(string(script_step.copy_control_id))<=0;
            if(!struct_exists(script_step,"target")) script_step.target="";
            if(!struct_exists(script_step,"target_type")) script_step.target_type="";
            if(!struct_exists(script_step,"target_group_uid")){
                script_step.target_group_uid=-1;
                if(script_step.kind=="control_object"&&script_step.target_mode!="uid"&&string(script_step.target)!=""&&string(script_step.target_type)!=""){
                    var migrated_control_group=BattleEditor_FindUniqueAuthoredControlGroup(project,script_step.target,script_step.target_type,false);
                    if(is_undefined(migrated_control_group)) migrated_control_group=BattleEditor_FindUniqueAuthoredControlGroup(project,script_step.target,script_step.target_type,true);
                    if(!is_undefined(migrated_control_group)){
                        script_step.target_group_uid=migrated_control_group.uid;
                        script_step.target=migrated_control_group.control_id;
                    }
                }
            }else if(script_step.target_group_uid>=0){
                var current_control_group=BattleEditor_ControlGroupByUid(project,script_step.target_group_uid,script_step.target_type);
                if(!is_undefined(current_control_group)) script_step.target=current_control_group.control_id;
            }
            if(!struct_exists(script_step,"target_group_kind")) script_step.target_group_kind="";
            if(!struct_exists(script_step,"target_category")) script_step.target_category=BattleEditor_ControlCategoryForType(script_step.target_type);
            if(!struct_exists(script_step,"target_uid")) script_step.target_uid=-1;
            if(!struct_exists(script_step,"target_list_uid")) script_step.target_list_uid=-1;
            if(!struct_exists(script_step,"property")) script_step.property="x";
            if(!struct_exists(script_step,"property_category")) script_step.property_category=BattleEditor_ControlPropertyCategory(script_step.property,script_step.target_type);
            if(!struct_exists(script_step,"value")) script_step.value=0;
            if(!struct_exists(script_step,"follow_target_uid")) script_step.follow_target_uid=-1;
            if(!struct_exists(script_step,"follow_value_initialized")) script_step.follow_value_initialized=script_step.property=="follow";
            if(!struct_exists(script_step,"damage_change_visual")) script_step.damage_change_visual=true;
            if(!struct_exists(script_step,"soul_blue_direction")) script_step.soul_blue_direction=1;
            if(!struct_exists(script_step,"blue_gravity_throw")) script_step.blue_gravity_throw=false;
            if(!struct_exists(script_step,"text_value")) script_step.text_value="";
            if(!struct_exists(script_step,"dialogue_font")) script_step.dialogue_font=2;
            if(!struct_exists(script_step,"dialogue_voice")) script_step.dialogue_voice=2;
            if(!struct_exists(script_step,"dialogue_template")) script_step.dialogue_template=0;
            if(!struct_exists(script_step,"dialogue_offset_x")) script_step.dialogue_offset_x="92";
            if(!struct_exists(script_step,"dialogue_offset_y")) script_step.dialogue_offset_y="-34";
            if(!struct_exists(script_step,"dialogue_mode")) script_step.dialogue_mode=1;
            if(!struct_exists(script_step,"dialogue_block_battle")) script_step.dialogue_block_battle=true;
            script_step.dialogue_mode=clamp(round(real(script_step.dialogue_mode)),0,1);
            if(!struct_exists(script_step,"position_x")) script_step.position_x="";
            if(!struct_exists(script_step,"position_y")) script_step.position_y="";
            if(!struct_exists(script_step,"position_angle")) script_step.position_angle="";
            if(!struct_exists(script_step,"board_transform_width")) script_step.board_transform_width="";
            if(!struct_exists(script_step,"board_transform_height")) script_step.board_transform_height="";
            if(!struct_exists(script_step,"board_shape_width")) script_step.board_shape_width="80";
            if(!struct_exists(script_step,"board_shape_height")) script_step.board_shape_height="80";
            if(!struct_exists(script_step,"board_shape_radius_x")) script_step.board_shape_radius_x="40";
            if(!struct_exists(script_step,"board_shape_radius_y")) script_step.board_shape_radius_y="40";
            if(!struct_exists(script_step,"board_shape_triangle_width")) script_step.board_shape_triangle_width="80";
            if(!struct_exists(script_step,"board_shape_triangle_height")) script_step.board_shape_triangle_height="70";
            // Migrate old one-axis movement without inventing a value for the
            // untouched axis. Empty means exactly "keep the current value".
            if(script_step.property=="x"){
                script_step.position_x=string(script_step.value);
                script_step.position_y="";
                script_step.property="position";
            }else if(script_step.property=="y"){
                script_step.position_x="";
                script_step.position_y=string(script_step.value);
                script_step.property="position";
            }else if(script_step.property=="angle"){
                // Position is the single transform entry.  Preserve old
                // standalone-angle steps as an angle-only position control.
                script_step.position_x="";
                script_step.position_y="";
                script_step.position_angle=string(script_step.value);
                script_step.property="position";
            }else if(script_step.target_type=="board"&&script_step.property=="width"){
                // Old saves used a separate width operation. Keep its exact
                // effect while migrating it into the unified frame transform.
                script_step.position_x="";
                script_step.position_y="";
                script_step.position_angle="";
                script_step.board_transform_width=string(script_step.value);
                script_step.board_transform_height="";
                script_step.property="position";
            }else if(script_step.target_type=="board"&&script_step.property=="height"){
                script_step.position_x="";
                script_step.position_y="";
                script_step.position_angle="";
                script_step.board_transform_width="";
                script_step.board_transform_height=string(script_step.value);
                script_step.property="position";
            }
            if(!struct_exists(script_step,"points")||!is_array(script_step.points)) script_step.points=[[-40,-40],[40,-40],[40,40],[-40,40]];
            if(!struct_exists(script_step,"point_index")) script_step.point_index=0;
            if(!struct_exists(script_step,"vertex_uids")||!is_array(script_step.vertex_uids)) script_step.vertex_uids=[];
            if(!struct_exists(script_step,"vertex_target_x")) script_step.vertex_target_x=0;
            if(!struct_exists(script_step,"vertex_target_y")) script_step.vertex_target_y=0;
            if(!struct_exists(script_step,"coordinate_mode")) script_step.coordinate_mode="absolute";
            if(!struct_exists(script_step,"orbit_center_x")) script_step.orbit_center_x="320";
            if(!struct_exists(script_step,"orbit_center_y")) script_step.orbit_center_y="240";
            if(!struct_exists(script_step,"orbit_use_group_center")) script_step.orbit_use_group_center=true;
            if(!struct_exists(script_step,"physics_direction")) script_step.physics_direction="0";
            if(!struct_exists(script_step,"physics_speed")) script_step.physics_speed="4";
            if(!struct_exists(script_step,"physics_acceleration")) script_step.physics_acceleration="0";
            if(!struct_exists(script_step,"physics_curve_speed")) script_step.physics_curve_speed="0";
            if(!struct_exists(script_step,"physics_rotation_speed")) script_step.physics_rotation_speed="0";
            if(!struct_exists(script_step,"aim_target_uid")) script_step.aim_target_uid=-2;
            if(!struct_exists(script_step,"aim_continuous")) script_step.aim_continuous=false;
            if(!struct_exists(script_step,"aim_move_speed")) script_step.aim_move_speed="4";
            if(!struct_exists(script_step,"aim_face_target")) script_step.aim_face_target=true;
            if(!struct_exists(script_step,"aim_behavior")) script_step.aim_behavior=BattleEditor_AimBehaviorFromLegacy(script_step.aim_move_speed,script_step.aim_face_target);
            script_step.aim_behavior=clamp(round(real(script_step.aim_behavior)),0,2);
            // Keep the legacy flag coherent for tolerant older readers.
            script_step.aim_face_target=script_step.aim_behavior!=2;
            if(!struct_exists(script_step,"warning_enabled")) script_step.warning_enabled=false;
            if(!struct_exists(script_step,"warning_duration")) script_step.warning_duration=30;
            if(!struct_exists(script_step,"warning_angle_mode")) script_step.warning_angle_mode=0;
            if(!struct_exists(script_step,"warning_angle")) script_step.warning_angle="0";
            if(!struct_exists(script_step,"gb_hold_while_moving")) script_step.gb_hold_while_moving=false;
            if(!struct_exists(script_step,"gb_move_sound")) script_step.gb_move_sound=true;
            if(!struct_exists(script_step,"length_anchor")) script_step.length_anchor=0;
            if(!struct_exists(script_step,"create_category")) script_step.create_category=0;
            if(!struct_exists(script_step,"create_preset")) script_step.create_preset="bone";
            if(!struct_exists(script_step,"create_control_id")) script_step.create_control_id="created_"+string(script_step.uid);
            if(!struct_exists(script_step,"create_control_id_auto")) script_step.create_control_id_auto=false;
            if(!struct_exists(script_step,"create_x")) script_step.create_x="320";
            if(!struct_exists(script_step,"create_y")) script_step.create_y="240";
            if(!struct_exists(script_step,"create_angle")) script_step.create_angle="90";
            if(!struct_exists(script_step,"create_lifetime")) script_step.create_lifetime="-1";
            if(!struct_exists(script_step,"create_size")) script_step.create_size="48";
            var legacy_create_is_board=script_step.create_preset=="board_add"||script_step.create_preset=="board_subtract";
            // Older Workspace frame steps had one value that was copied to
            // up/down/left/right.  Preserve that exact square as full width
            // and height while all new steps expose independent dimensions.
            if(!struct_exists(script_step,"create_width")) script_step.create_width=legacy_create_is_board?"("+string(script_step.create_size)+")*2":"60";
            if(!struct_exists(script_step,"create_height")) script_step.create_height=legacy_create_is_board?"("+string(script_step.create_size)+")*2":"60";
            if(!struct_exists(script_step,"create_board_shape")) script_step.create_board_shape=0;
            if(!struct_exists(script_step,"create_board_up")) script_step.create_board_up=legacy_create_is_board?string(script_step.create_size):"30";
            if(!struct_exists(script_step,"create_board_down")) script_step.create_board_down=legacy_create_is_board?string(script_step.create_size):"30";
            if(!struct_exists(script_step,"create_board_left")) script_step.create_board_left=legacy_create_is_board?string(script_step.create_size):"30";
            if(!struct_exists(script_step,"create_board_right")) script_step.create_board_right=legacy_create_is_board?string(script_step.create_size):"30";
            if(!struct_exists(script_step,"create_board_radius_x")) script_step.create_board_radius_x="30";
            if(!struct_exists(script_step,"create_board_radius_y")) script_step.create_board_radius_y="30";
            if(!struct_exists(script_step,"create_board_triangle_size")) script_step.create_board_triangle_size="40";
            if(!struct_exists(script_step,"create_board_rotate")) script_step.create_board_rotate="0";
            if(!struct_exists(script_step,"create_board_depth")) script_step.create_board_depth=script_step.create_preset=="board_subtract"?"-10":"10";
            if(!struct_exists(script_step,"create_damage_type")) script_step.create_damage_type=0;
            if(!struct_exists(script_step,"create_layer_mode")) script_step.create_layer_mode=BATTLE_EDITOR_LAYER.IN_BOARD;
            var create_template_had_follow=struct_exists(script_step,"create_template")&&is_struct(script_step.create_template)&&struct_exists(script_step.create_template,"follow");
            BattleEditor_WorkspaceCreateNormalizeTemplate(script_step);
            // Follow defaults ON for newly authored Workspace creations. Old
            // saves predate that choice, so missing data must retain their old
            // independent-world-coordinate behaviour instead of silently
            // changing every existing attack when the project is opened.
            if(source_version<28&&!create_template_had_follow){
                script_step.create_template.follow=false;
                script_step.create_template.follow_target_uid=-1;
            }
            if(!struct_exists(script_step,"tween")) script_step.tween=0;
            if(!struct_exists(script_step,"ease")) script_step.ease=0;
            if(!struct_exists(script_step,"script_name")) script_step.script_name="";
            if(!struct_exists(script_step,"script_arguments")) script_step.script_arguments="";
            if(!struct_exists(script_step,"wait_for_script")) script_step.wait_for_script=false;
            if(!struct_exists(script_step,"action_name")) script_step.action_name="bone_orbit";
            if(!struct_exists(script_step,"action_control_id")) script_step.action_control_id="builtin_"+string(script_step.uid);
            if(!struct_exists(script_step,"action_control_id_auto")) script_step.action_control_id_auto=false;
            if(!struct_exists(script_step,"action_source_uid")) script_step.action_source_uid=-1;
            if(!struct_exists(script_step,"action_arguments")) script_step.action_arguments=BattleEditor_BuiltinActionDefaults(script_step.action_name);
            if(is_array(script_step.action_arguments)){
                var joined_action_arguments="";
                for(var stored_argument_index=0;stored_argument_index<array_length(script_step.action_arguments);stored_argument_index++){
                    if(stored_argument_index>0) joined_action_arguments+=";";
                    joined_action_arguments+=string(script_step.action_arguments[stored_argument_index]);
                }
                script_step.action_arguments=joined_action_arguments;
            }
            if(!struct_exists(script_step,"action_path_variable")||!BattleEditor_FunctionPathVariableNameValid(script_step.action_path_variable)) script_step.action_path_variable="t";
            if(!struct_exists(script_step,"action_path_mode")) script_step.action_path_mode=0;
            if(!struct_exists(script_step,"action_path_target_type")) script_step.action_path_target_type="bone";
            if(!struct_exists(script_step,"action_path_legacy_default")) script_step.action_path_legacy_default=source_version<19&&script_step.action_name=="bone_function_path"&&round(real(script_step.action_path_mode))==0&&real(script_step.action_source_uid)<0;
            if(!struct_exists(script_step,"action_follow")) script_step.action_follow=false;
            if(!struct_exists(script_step,"action_keep_objects")) script_step.action_keep_objects=false;
            if(!struct_exists(script_step,"action_damage_change_visual")) script_step.action_damage_change_visual=true;
            if(!struct_exists(script_step,"action_exit_tween")) script_step.action_exit_tween=script_step.tween;
            if(!struct_exists(script_step,"action_exit_ease")) script_step.action_exit_ease=script_step.ease;
            if(script_step.action_name=="bone_wave"){
                var legacy_wave_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_wave_parts)==13){
                    // v25 accidentally interpreted Wave as a two-sided
                    // corridor. Restore the original games.sb3 meaning: one
                    // row whose already-created members move on sine paths.
                    // Preserve the v25 visible centre and range while dropping
                    // only its erroneous corridor gap.
                    var legacy_wave_axis=clamp(round(real(legacy_wave_parts[2])),0,1);
                    var legacy_wave_mid="(("+string_trim(legacy_wave_parts[7])+")+("+string_trim(legacy_wave_parts[8])+"))/2";
                    var legacy_wave_radius="abs(("+string_trim(legacy_wave_parts[8])+")-("+string_trim(legacy_wave_parts[7])+"))/2";
                    var legacy_wave_x=legacy_wave_axis==0?string_trim(legacy_wave_parts[0]):legacy_wave_mid;
                    var legacy_wave_y=legacy_wave_axis==0?legacy_wave_mid:string_trim(legacy_wave_parts[1]);
                    script_step.action_arguments=legacy_wave_x+";"+legacy_wave_y+";"+string_trim(legacy_wave_parts[2])+";"+string_trim(legacy_wave_parts[3])+";"+string_trim(legacy_wave_parts[4])
                        +";"+string_trim(legacy_wave_parts[6])+";"+legacy_wave_radius+";"+string_trim(legacy_wave_parts[9])+";"+string_trim(legacy_wave_parts[10])+";"+string_trim(legacy_wave_parts[11])+";"+string_trim(legacy_wave_parts[12]);
                }
            }
            if(script_step.action_name=="bone_corridor"){
                var legacy_corridor_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_corridor_parts)==11){
                    // A corridor is a sequence of paired openings. Existing
                    // projects stay perfectly straight by using identical
                    // min/max generation centres; authors can then separate
                    // the bounds to make the spawn point trace a sine curve.
                    var legacy_corridor_axis=clamp(round(real(legacy_corridor_parts[0])),0,1);
                    var legacy_corridor_center=string_trim(legacy_corridor_parts[legacy_corridor_axis==0?2:1]);
                    script_step.action_arguments=string_trim(legacy_corridor_parts[0])+";"+string_trim(legacy_corridor_parts[1])+";"+string_trim(legacy_corridor_parts[2])+";"+string_trim(legacy_corridor_parts[3])+";"+string_trim(legacy_corridor_parts[4])+";"+string_trim(legacy_corridor_parts[5])+";"+string_trim(legacy_corridor_parts[6])
                        +";"+legacy_corridor_center+";"+legacy_corridor_center+";30;"+string_trim(legacy_corridor_parts[7])+";"+string_trim(legacy_corridor_parts[8])+";"+string_trim(legacy_corridor_parts[9])+";"+string_trim(legacy_corridor_parts[10]);
                }
            }
            if(source_version<15&&script_step.kind=="builtin_action"){
                var legacy_action_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(script_step.action_name=="bone_physics"&&array_length(legacy_action_parts)==13){
                    // The old editor invented a random polar direction and a
                    // hidden random spawn disc. Convert it once to explicit X/Y
                    // momentum ranges; the new runtime contains no implicit
                    // random direction or position.
                    var legacy_speed_min=string_trim(legacy_action_parts[3]);
                    var legacy_speed_max=string_trim(legacy_action_parts[4]);
                    var legacy_speed_abs="max(abs("+legacy_speed_min+"),abs("+legacy_speed_max+"))";
                    script_step.action_arguments=string_trim(legacy_action_parts[0])+";"+string_trim(legacy_action_parts[1])+";"+string_trim(legacy_action_parts[2])
                        +";-("+legacy_speed_abs+");"+legacy_speed_abs+";-("+legacy_speed_abs+");"+legacy_speed_abs
                        +";"+string_trim(legacy_action_parts[5])+";"+string_trim(legacy_action_parts[6])
                        +";"+string_trim(legacy_action_parts[7])+";"+string_trim(legacy_action_parts[8])
                        +";"+string_trim(legacy_action_parts[9])+";"+string_trim(legacy_action_parts[10])+";"+string_trim(legacy_action_parts[11]);
                }else if(script_step.action_name=="gb_pinwheel"&&array_length(legacy_action_parts)==11){
                    var legacy_pinwheel_count=string_trim(legacy_action_parts[4]);
                    script_step.action_arguments=string_trim(legacy_action_parts[0])+";"+string_trim(legacy_action_parts[1])+";"+string_trim(legacy_action_parts[2])+";"+string_trim(legacy_action_parts[3])
                        +";"+legacy_pinwheel_count+";"+string_trim(legacy_action_parts[5])+";(360 / max(1,"+legacy_pinwheel_count+"));"+string_trim(legacy_action_parts[6])
                        +";0;0;"+string_trim(legacy_action_parts[7])+";"+string_trim(legacy_action_parts[8])+";"+string_trim(legacy_action_parts[9])+";"+string_trim(legacy_action_parts[10]);
                }
            }
            if(!struct_exists(script_step,"sound_name")) script_step.sound_name="snd_bone_out";
            if(!struct_exists(script_step,"sound_timing")) script_step.sound_timing=0;
            // Older projects already contain sound_name/timing because those
            // fields powered the standalone sound item. Never interpret that
            // dormant default as an enabled per-step sound after migration.
            if(!struct_exists(script_step,"step_sound_enabled")) script_step.step_sound_enabled=false;
            if(!struct_exists(script_step,"read_target_key")) script_step.read_target_key="soul";
            if(!struct_exists(script_step,"read_target_uid")) script_step.read_target_uid=-1;
            if(!struct_exists(script_step,"read_target_type")) script_step.read_target_type="soul";
            if(!struct_exists(script_step,"read_property")) script_step.read_property="x";
            if(!struct_exists(script_step,"read_variable_name")) script_step.read_variable_name="A";
            if(!struct_exists(script_step,"read_overwrite_confirmed")) script_step.read_overwrite_confirmed=false;
            if(!struct_exists(script_step,"enemy_uid")) script_step.enemy_uid=-1;
            if(!struct_exists(script_step,"enemy_part_key")) script_step.enemy_part_key="body";
            if(!struct_exists(script_step,"enemy_resource_uid")) script_step.enemy_resource_uid=-1;
            var legacy_wall_direction=script_step.action_name=="bone_wall_up"?1:(script_step.action_name=="bone_wall_down"?2:(script_step.action_name=="bone_wall_left"?3:(script_step.action_name=="bone_wall_right"?4:0)));
            if(legacy_wall_direction>0){
                script_step.action_name="bone_wall";
                script_step.action_direction=legacy_wall_direction;
            }else if(script_step.action_name=="bone_wall"&&!struct_exists(script_step,"action_direction")&&source_version<11){
                var legacy_wall_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_wall_parts)>=10){
                    script_step.action_direction=clamp(round(real(legacy_wall_parts[2])),1,4);
                    script_step.action_arguments=BattleEditor_ActionArgumentsRemove(script_step.action_arguments,2);
                }
            }
            if(!struct_exists(script_step,"action_direction")) script_step.action_direction=1;
            if(script_step.action_name=="bone_wall"&&source_version<12){
                var legacy_center_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_center_parts)>=4){
                    var legacy_center_axis=clamp(round(script_step.action_direction),1,4)<=2?0:1;
                    var legacy_center_source=string_trim(legacy_center_parts[legacy_center_axis]);
                    var legacy_center_count=string_trim(legacy_center_parts[2]);
                    var legacy_center_spacing=string_trim(legacy_center_parts[3]);
                    var migrated_center="("+legacy_center_source+") + (("+legacy_center_count+") - 1) * ("+legacy_center_spacing+") / 2";
                    script_step.action_arguments=BattleEditor_ActionArgumentsSet(script_step.action_arguments,legacy_center_axis,migrated_center,BattleEditor_BuiltinActionDefaults("bone_wall"));
                }
            }
            if(script_step.action_name=="bone_wall"&&source_version<16){
                var legacy_wall_length_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_wall_length_parts)==9){
                    // v16 separates travel/centre radius from the visible Bone
                    // length. Existing walls retain their former movement and
                    // receive the new full-screen default length.
                    script_step.action_arguments=string_trim(legacy_wall_length_parts[0])+";"+string_trim(legacy_wall_length_parts[1])+";"+string_trim(legacy_wall_length_parts[2])+";"+string_trim(legacy_wall_length_parts[3])+";"+string_trim(legacy_wall_length_parts[4])
                        +";640;"+string_trim(legacy_wall_length_parts[5])+";"+string_trim(legacy_wall_length_parts[6])+";"+string_trim(legacy_wall_length_parts[7])+";"+string_trim(legacy_wall_length_parts[8]);
                }
            }
            if(script_step.action_name=="bone_orbit"&&source_version<16){
                var legacy_orbit_facing_parts=BattleEditor_ActionParts(script_step.action_arguments);
                if(array_length(legacy_orbit_facing_parts)==13){
                    // Default zero now means face the actual centre. Preserve
                    // every old timing/colour field while inserting the new
                    // author-facing orientation offset.
                    script_step.action_arguments=string_trim(legacy_orbit_facing_parts[0])+";"+string_trim(legacy_orbit_facing_parts[1])+";"+string_trim(legacy_orbit_facing_parts[2])+";"+string_trim(legacy_orbit_facing_parts[3])+";"+string_trim(legacy_orbit_facing_parts[4])+";"+string_trim(legacy_orbit_facing_parts[5])+";"+string_trim(legacy_orbit_facing_parts[6])
                        +";0;"+string_trim(legacy_orbit_facing_parts[7])+";"+string_trim(legacy_orbit_facing_parts[8])+";"+string_trim(legacy_orbit_facing_parts[9])+";"+string_trim(legacy_orbit_facing_parts[10])+";"+string_trim(legacy_orbit_facing_parts[11])+";"+string_trim(legacy_orbit_facing_parts[12]);
                }
            }
            if(source_version<17&&script_step.kind=="builtin_action"&&script_step.action_keep_objects){
                // v17 removes the duplicate "keep" switch. Its old true state
                // is represented by the constructor's existing lifetime field:
                // -1 means remain until ordinary end-of-turn cleanup.
                var persistent_lifetime_index=-1;
                switch(script_step.action_name){
                    case "bone_orbit":persistent_lifetime_index=10;break;
                    case "bone_wave":persistent_lifetime_index=8;break;
                    case "bone_corridor":persistent_lifetime_index=11;break;
                    case "bone_physics":persistent_lifetime_index=11;break;
                    case "bone_3d":persistent_lifetime_index=14;break;
                    case "bone_4d":persistent_lifetime_index=19;break;
                    case "bone_function_path":persistent_lifetime_index=6;break;
                    case "bone_wall":persistent_lifetime_index=7;break;
                }
                if(persistent_lifetime_index>=0) script_step.action_arguments=BattleEditor_ActionArgumentsSet(script_step.action_arguments,persistent_lifetime_index,-1,BattleEditor_BuiltinActionDefaults(script_step.action_name));
            }
            // Retain the serialized legacy field for tolerant old-save round
            // trips, but it is no longer an author-facing or runtime input.
            script_step.action_keep_objects=false;
            if(!struct_exists(script_step,"screen_action")) script_step.screen_action="camera_set";
            if(!struct_exists(script_step,"screen_arguments")) script_step.screen_arguments=BattleEditor_ScreenActionDefaults(script_step.screen_action);
            if(!struct_exists(script_step,"variable_name")) script_step.variable_name="value";
            if(!struct_exists(script_step,"expression")) script_step.expression="0";
            if(!struct_exists(script_step,"variable_operation")) script_step.variable_operation="set";
            if(!struct_exists(script_step,"condition_left")) script_step.condition_left="value";
            if(!struct_exists(script_step,"condition_operator")) script_step.condition_operator=">=";
            if(!struct_exists(script_step,"condition_right")) script_step.condition_right="0";
            if(!struct_exists(script_step,"skip_count")) script_step.skip_count=1;
            if(!struct_exists(script_step,"repeat_count")) script_step.repeat_count="2";
            if(!struct_exists(script_step,"repeat_length")) script_step.repeat_length=1;
            if(!struct_exists(script_step,"repeat_interval")) script_step.repeat_interval="0";
            if(!struct_exists(script_step,"enabled")) script_step.enabled=true;
        }
        if(source_version<14){
            // v14 separates every filter into its own list item. Multiple
            // instantaneous replacement steps still execute on the same frame,
            // preserving old visuals without exposing packed parameter text.
            var separated_steps=[];
            for(var legacy_step_index=0;legacy_step_index<array_length(script_list.steps);legacy_step_index++){
                var legacy_step=script_list.steps[legacy_step_index];
                var separated_ids=[];
                if(legacy_step.kind=="screen_control"){
                    if(legacy_step.screen_action=="effect_color") separated_ids=["effect_hue","effect_saturation","effect_brightness","effect_contrast","effect_grayscale","effect_invert"];
                    else if(legacy_step.screen_action=="effect_glitch") separated_ids=["effect_glitch_amount","effect_chromatic","effect_scanline","effect_wave"];
                    else if(legacy_step.screen_action=="effect_vignette") separated_ids=["effect_vignette_amount","effect_pixelate"];
                }
                if(array_length(separated_ids)<=0){
                    array_push(separated_steps,legacy_step);
                }else{
                    var legacy_screen_parts=BattleEditor_ActionParts(legacy_step.screen_arguments);
                    for(var separated_index=0;separated_index<array_length(separated_ids);separated_index++){
                        var separated_step=json_parse(json_stringify(legacy_step));
                        if(separated_index>0) separated_step.uid=BattleEditor_AllocateUid(project);
                        separated_step.screen_action=separated_ids[separated_index];
                        separated_step.screen_arguments=separated_index<array_length(legacy_screen_parts)?string_trim(legacy_screen_parts[separated_index]):BattleEditor_ScreenActionDefaults(separated_step.screen_action);
                        array_push(separated_steps,separated_step);
                    }
                }
            }
            script_list.steps=separated_steps;
        }
    }
    // Old or partially-authored copy-control steps may not yet have an output
    // ID. Fill them only after every list has been normalized so each batch
    // sees the IDs already claimed by earlier batches: source_2, source_3...
    for(var copy_list_index=0;copy_list_index<array_length(project.script_lists);copy_list_index++){
        var copy_list=project.script_lists[copy_list_index];
        for(var copy_step_index=0;copy_step_index<array_length(copy_list.steps);copy_step_index++){
            var copy_step=copy_list.steps[copy_step_index];
            if(copy_step.kind!="control_object"||round(real(copy_step.control_source_mode))!=1) continue;
            if(string_length(string_trim(string(copy_step.copy_control_id)))>0) continue;
            copy_step.copy_control_id=BattleEditor_NextCopiedControlId(project,copy_step.target);
            copy_step.copy_control_id_auto=true;
        }
    }
    project.version=33;
    return project;
}

function BattleEditor_EventEndTime(event_data) {
    var start=max(0,event_data.time);
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="gb") return start+max(1,event_data.move_time)+max(0,event_data.charge_time)+max(1,event_data.beam_time)+20;
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(event_data.preset=="slash"||event_data.preset=="true_knife")) return start+max(0,event_data.warning_time)+max(1,event_data.active_time)+(event_data.preset=="true_knife"?0:10);
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
        var plain_length=string_length(TextTyper_MarkupPlain(event_data.text));
        return start+max(1,plain_length*max(1,event_data.speed+1))+15;
    }
    if(struct_exists(event_data,"duration")&&event_data.duration>0) return start+event_data.duration;
    return start+60;
}

/// Authoring previews obey the same schedule as runtime spawning. Persistent
/// objects remain after their start; finite mechanics disappear after their
/// complete warning/active/dismissal interval.
function BattleEditor_EventVisibleAtTime(event_data,preview_time) {
    if(struct_exists(event_data,"editor_visible")&&!event_data.editor_visible) return false;
    var start=max(0,event_data.time);
    if(preview_time<start) return false;
    var has_finite_end=false;
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD) has_finite_end=true;
    else if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER) has_finite_end=true;
    else if(struct_exists(event_data,"duration")&&event_data.duration>0) has_finite_end=true;
    return !has_finite_end||preview_time<=BattleEditor_EventEndTime(event_data);
}

function BattleEditor_EffectiveDuration(project,turn_number=undefined) {
    if(struct_exists(project,"duration")&&project.duration>0) return project.duration;
    var filter_turn=!is_undefined(turn_number);
    var active_turn=filter_turn?max(1,round(real(turn_number))):1;
    var result=0;
    for(var event_index=0;event_index<array_length(project.events);event_index++){
        var duration_event=project.events[event_index];
        if(filter_turn&&!BattleEditor_EventBelongsToTurn(duration_event,active_turn)) continue;
        result=max(result,BattleEditor_EventEndTime(duration_event));
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        if(filter_turn&&!BattleEditor_ScriptListBelongsToTurn(list_data,active_turn)) continue;
        var list_entry_time=list_data.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE?max(0,real(list_data.entry_value)):0;
        result=max(result,list_entry_time+BattleEditor_ScriptListDuration(project,list_data,[]));
    }
    // Leave one tenth of a second after the calculated final frame so dismissal
    // animation and timeline seeking do not land exactly on the endpoint.
    return result>0?ceil(result+GAME_FPS*0.1):0;
}

/// Calculate one list from its own start frame. Node connections are genuine
/// parallel branches: the child starts at the current cursor, while the parent
/// continues.  The longest resulting endpoint determines the visible timeline.
/// A cycle contributes zero at the recursive edge; the runtime operation budget
/// remains the authority for intentionally cyclic graphs.
function BattleEditor_ScriptListDuration(project,list_data,visiting,inherited_previous_duration=0) {
    if(is_undefined(list_data)||!is_struct(list_data)) return 0;
    if(!BattleEditor_WorkspaceHasHeader(list_data)) return 0;
    for(var visit_index=0;visit_index<array_length(visiting);visit_index++) if(visiting[visit_index]==list_data.uid) return 0;
    var next_visiting=array_create(array_length(visiting));
    array_copy(next_visiting,0,visiting,0,array_length(visiting));
    array_push(next_visiting,list_data.uid);
    // A connected list continues the caller's current parallel block. This is
    // what lets a leading "wait for previous completion" in the child wait for
    // the caller's last real action. The connection row itself remains zero
    // duration and never replaces that inherited action.
    var list_time=0,previous_step_duration=max(0,inherited_previous_duration),list_latest_end=0;
    var step_index=0,loops=[];
    // Mirror RuntimeScriptStep's loop stack. A repeat item owns the following
    // N items. Instantaneous rows do not invent an iteration delay; only an
    // explicit Wait in the range or repeat_interval advances the next pass.
    while(step_index<array_length(list_data.steps)||array_length(loops)>0){
        if(array_length(loops)>0){
            var loop_top=loops[array_length(loops)-1];
            if(step_index>=loop_top.end_index){
                previous_step_duration=0;
                if(loop_top.remaining>1){
                    loop_top.remaining-=1;
                    list_time+=loop_top.interval;
                    step_index=loop_top.start_index;
                }
                else array_delete(loops,array_length(loops)-1,1);
                continue;
            }
        }
        if(step_index>=array_length(list_data.steps)) break;
        var step=list_data.steps[step_index];
        if(struct_exists(step,"enabled")&&!step.enabled){step_index+=1;continue;}
        if(step.kind=="repeat"){
            var repeat_amount=max(0,round(BattleEditor_RuntimeNumber(project,step.repeat_count,0)));
            var repeat_length=max(0,round(BattleEditor_RuntimeNumber(project,step.repeat_length,0)));
            var repeat_interval=struct_exists(step,"repeat_interval")?max(0,BattleEditor_RuntimeNumber(project,step.repeat_interval,0)):0;
            var repeat_start=step_index+1;
            var repeat_end=min(array_length(list_data.steps),repeat_start+repeat_length);
            if(repeat_amount>0&&repeat_end>repeat_start){array_push(loops,{start_index:repeat_start,end_index:repeat_end,remaining:repeat_amount,interval:repeat_interval});step_index=repeat_start;}
            else step_index=repeat_end;
            continue;
        }
        var duration_step_end=list_time;
        if(step.kind=="wait"){
            if(struct_exists(step,"wait_mode")&&round(real(step.wait_mode))==1){
                var wait_extra=struct_exists(step,"wait_extra_duration")?max(0,real(step.wait_extra_duration)):0;
                list_time+=previous_step_duration+wait_extra;
            }
            else list_time+=max(0,step.duration);
            list_latest_end=max(list_latest_end,list_time);
            duration_step_end=list_time;
            previous_step_duration=0;
        }else if(step.kind=="start_list"){
            var child_list=BattleEditor_FindScriptList(project,step.target_list_uid);
            if(!is_undefined(child_list)){
                var child_duration=BattleEditor_ScriptListDuration(project,child_list,next_visiting,previous_step_duration);
                list_latest_end=max(list_latest_end,list_time+child_duration);
                duration_step_end=list_time+child_duration;
            }
        }else{
            var parallel_step_duration=max(0,BattleEditor_ScriptStepDurationHint(project,step));
            previous_step_duration=max(previous_step_duration,parallel_step_duration);
            list_latest_end=max(list_latest_end,list_time+parallel_step_duration);
            duration_step_end=list_time+parallel_step_duration;
        }
        step_index+=1;
    }
    return max(list_time,list_latest_end);
}

function BattleEditor_TimelineDuration(project,turn_number=undefined) {
    return max(60,BattleEditor_EffectiveDuration(project,turn_number));
}

/// Rebuild the authoring duration only at an explicit project boundary.
/// Draw and ordinary Step code must read this cache; they must never poll and
/// reparse Workspace formulas while the author is idle.
function BattleEditor_RefreshDurationCache(controller) {
    if(!instance_exists(controller)||!variable_instance_exists(controller,"project")) return 60;
    var cache_turn=variable_instance_exists(controller,"developer_turn")?controller.developer_turn
        :(variable_instance_exists(controller,"script_monster_turn")?controller.script_monster_turn:controller.project.settings.developer_turn);
    controller.timeline_effective_duration_cache=BattleEditor_EffectiveDuration(controller.project,cache_turn);
    controller.timeline_duration_cache=max(60,controller.timeline_effective_duration_cache);
    controller.timeline_duration_cache_time=current_time;
    controller.timeline_duration_dirty=false;
    return controller.timeline_duration_cache;
}

/// Formats the editor's logical-frame clock without exposing raw frame counts.
/// Runtime timing is normalized to GAME_FPS even though the Windows runner may
/// render at a higher refresh rate through global.delta_time_factor.
function BattleEditor_FormatTimelineTime(frame_time) {
    var total_tenths=max(0,floor(real(frame_time)*10/GAME_FPS));
    var total_seconds=total_tenths div 10;
    var minutes=total_seconds div 60;
    var seconds=total_seconds mod 60;
    var tenths=total_tenths mod 10;
    return string(minutes)+":"+(seconds<10?"0":"")+string(seconds)+"."+string(tenths);
}

/// Accept the human timeline notation used beside the scrubber. Plain numeric
/// input remains a frame count for old habits and project compatibility.
function BattleEditor_ParseTimelineTime(value,fallback_frames=0) {
    var source=string_trim(string(value));
    if(string_length(source)<=0) return {valid:false,value:fallback_frames};
    var colon=string_pos(":",source);
    if(colon<=0){
        var frame_result=BattleEditor_EvaluateNumberExpression(source);
        return {valid:frame_result.valid,value:frame_result.valid?max(0,frame_result.value):fallback_frames};
    }
    if(string_pos(":",string_delete(source,1,colon))>0) return {valid:false,value:fallback_frames};
    var minute_text=string_trim(string_copy(source,1,colon-1));
    var second_text=string_trim(string_copy(source,colon+1,string_length(source)-colon));
    var minute_result=BattleEditor_EvaluateNumberExpression(minute_text);
    var second_result=BattleEditor_EvaluateNumberExpression(second_text);
    if(!minute_result.valid||!second_result.valid||minute_result.value<0||second_result.value<0) return {valid:false,value:fallback_frames};
    return {valid:true,value:max(0,round((minute_result.value*60+second_result.value)*GAME_FPS))};
}

/// User-facing manual shown by the editor's rightmost ? page.  Keep this
/// separate from README design notes: every sentence here describes something
/// the attack author can actually operate in the UI.
function BattleEditor_HelpSections() {
    return [
        {title:"快速开始",body:"1. 在“初始化”确认玩家、回合文字、敌人与战斗框。\n2. 到“新对象”放置攻击、装饰或额外框。\n3. 点击“脚本”直接进入 Workspace，顶栏收起。从左侧拖出怪物回合事件头，再把控制项目拖到它下方；Esc 返回场景与顶栏，再按 Esc 回来。\n4. 点列表头的运行按钮预览；确认后打开“存档”。\n5. 第一次使用选“新建存档”，以后选“保存当前存档”；每个存档都会写入运行文件同级的 save 文件夹。正常开始优先读取最新编辑现场；在全局设置中明确选择存档后，则读取指定的文件夹存档，直到编辑器产生新的现场修改。"},
        {title:"公式、函数与变量",body:"所有标为数值/公式的输入框都可直接计算，不只接受固定数字。支持 + - * /、括号、pi、e、random、sin/cos/tan、sqrt、log/ln、abs、floor/ceil/round、min/max、clamp 和 pow。函数轨迹可自行命名局部自变量，位移公式还可使用 0~1 的 progress；局部名称允许与项目变量重名，计算后不会改掉外部值。函数轨迹的起始点公式另有局部大写 X/Y：选择已有对象组时，它们表示执行瞬间的组中心，所以填 X、Y 就会从当前位置开始。\n先点一个公式框，顶栏会出现“插入变量”：下拉里使用中文说明列出当前函数局部自变量、时间、回合、灵魂、HP/KR、护盾以及场景对象可用的 X、Y、角度和可配置数值，选中后插入稳定的公式名称。\n复杂或很长的来源可在 Workspace 加入“读取对象数值”：选择对象与属性，再命名为 A 等短变量。普通项目变量重名时不会静默覆盖，必须在 Inspector 内明确选择覆盖或重新命名；函数局部自变量不受这条限制。物理散射的最小/最大范围也支持公式；两端均为整数时抽整数，否则按输入中较多的小数位抽样。"},
        {title:"初始化",body:"玩家与物品：设置名称、LV、ATK、DEF、HP、HP 上限、护盾、HUD 显示和物品栏。物品栏最多 114 项，每项可编辑名称、恢复量、食用文本、打字音效和使用后脚本方式。\n回合文本：选择或新增怪物回合，分别编辑战斗框文字和敌人气泡的文本、字体、打字音效、气泡样式与相对敌人偏移。\n敌人角色：最多十五个。新增会建立独立的空敌人；复制会复制所选敌人的部件资源、局部位置、摆动、ACT 与动画引用，并把副本放到附近可见空位。名称和角色资源目录同步，但脚本引用使用隐藏 UID，改名不会断开。原版 FIGHT/ACT 没有滚动，所以只有前三个能在原版菜单中精确选择，第 4～15 个仍可显示和被脚本控制。点“可视化编辑”后可在独立画布选择 Root 或六个部件并拖动；右栏可精确改局部坐标、资源原点、整体缩放，也可新建逐帧动画、导入帧、设置 FPS/循环并播放预览。\nACT、GB 与音乐：每个敌人可编辑自己的行动项目；GB 设置可新建贴图组并编辑本体帧、三套光束帧和一次完整发射预览；正式战斗音乐可从真实资源或导入音频选择，并可切换正常播放或低 FPS 逻辑帧校正。\n画面与菜单：集中设置 HUD、敌人、回合文字锚点，玩家/怪物回合框与全局框颜色；四按钮页说明 FIGHT、ACT、ITEM 的来源，并允许编辑 MERCY 的显示文字、回应和逃跑开关。"},
        {title:"新对象",body:"先用分类下拉在内建攻击、自定义弹幕、装饰、战斗框、打字机与蓝魂平台之间切换，不必退出后重新打开页面。\n内建攻击：骨头、骨刺、GB、真刀、斩击、友谊颗粒、火球、长矛、三叉戟、刀子、3D 骨和 4D 骨。\n自定义弹幕：选择内建或文件贴图，可增删动画帧、设置 FPS、伤害规则、视觉颜色、裁剪与层级。装饰不造成伤害，但同样拥有位置、旋转、缩放、透明度、颜色、动画、可选执行脚本与层级。打字机和蓝魂平台也直接从这里放置。\n战斗框只有一个主框；可新增任意数量的加框与减框。新对象页负责鼠标放置和拖动；Workspace 的“创建对象”提供同一套对象字段，但坐标必须在 Inspector 输入。"},
        {title:"选择、拖动与旋转",body:"单击选择一个对象；再次双击同一对象会选择同类型、同控制 ID 的整组。\n单对象拖动保留鼠标抓取点，不会瞬移到光标。组拖动给每个成员增加同一个位移，保持彼此间距。\n选中后不必把鼠标停在对象上：在场景区域滚轮每格旋转 1°，Ctrl+滚轮为 5°，Shift+滚轮为 10°。组选择会把你双击的主对象当作世界坐标原点：主对象位置不动，其他成员绕它旋转，所有成员的自身角度同步变化。\n组选择时提交属性字段，只把实际修改的字段应用到整组。GB 在场景中拖的是目标点；骨头和普通对象拖的是生成点。"},
        {title:"战斗框与顶点",body:"加框扩大可活动区域；减框从可活动区域挖洞，洞内显示真实背景，不是盖黑色。全部框在暂停和播放时都持续绘制。\n右键空白边可新增顶点，右键拖动顶点可变形成任意多边形。规则矩形、椭圆和正三角形只有在单独编辑顶点时才转换成多边形。顶点内部用隐藏 UID 引用，插入其他点不会令脚本控制错位。\n边框固定为 5px；拉伸节点不会改变粗细。脚本可用“平滑切换战斗框形状”选择目标框、矩形/椭圆/正三角形/多边形、过渡帧、Tween 与 Ease；手动编辑形状仍立即生效。"},
        {title:"跟随、指向与裁剪",body:"跟随模式把骨头的位置解释为所选战斗框的局部坐标：框移动或旋转时，骨头仍保持相对位置。普通移动不会取消跟随。\n控制对象的“朝向 / 追踪目标”适用于任何具备世界位置的目标，并明确提供“仅面朝目标”“面朝并向目标移动”“只向目标方向移动”三种行为。方向更新另选“执行时锁定一次”或“持续追踪目标”：锁定一次会保存执行帧方向，随后沿该方向直线越过目标当时的位置；持续追踪才每帧重新计算。移动前警告线和骨墙警告框会以红色、黄色交替闪烁，警告结束后才开始攻击。\n创建 Bone 时使用相同的行为、目标和方向更新下拉菜单，并以隐藏 UID 保存，不用手填坐标；它可以和框跟随同时使用。\n裁剪可选“全部框”或精确勾选多个框；搜索、单选及“同 ID”批量勾选都可用。“被裁剪部分无碰撞”开启后，看不见的那一段也不会伤人。\n框下层只用于表演，没有碰撞；框内受板面裁剪；框外不受裁剪。GB、真刀、斩击默认在框外。"},
        {title:"脚本 Workspace",body:"左侧积木栏分为事件头和普通积木，可以收起或滚动。事件头单独拖到画布，或接到游离积木串上方；普通积木落在空白处不会自动建立事件头，也不会执行。游离串可以编辑和保存，接上事件头后才运行。\n拖列表头移动整串；从中间拖动会带走该项及后续串，靠近另一串的插入位置会显示吸附线，松手才提交。Esc 或右键取消拖放，原数据不变。右键用于复制、剪下、贴上、删除和启用切换，不用于新建积木。原有节点连接继续保留，但只能启动带事件头的列表。物品与行动通过稳定 UID 绑定，改名或重名不会串项。\n拼接后的项目只有整体圆角外框，中间没有分隔边。循环直接修改原有外边框中覆盖自身及后续范围的部分，不叠加第二层矩形，内部分界保持原样，选取和循环色不会改变文字颜色；在循环内插入或拆走项目会相应更新范围。\n项目类型包括控制对象、创建对象、内建攻击函数、画面/镜头/滤镜、播放音效、切换敌人贴图/动画、变量/公式、读取对象数值、条件判断、等待、循环范围和节点连接。创建对象与新对象共用完整数据结构，只少画布拖放；除战斗框外的新创建对象默认跟随主框，可在表单选择任意加框或减框。切换敌人贴图按稳定敌人 UID、身体部件和当前角色目录资源选择，不需要手写路径。各大类节点使用不同颜色。\n控制对象顶部的“控制原件”和“复制后控制”是两种独立来源。控制原件显示成员对象组、真实 Control ID、数量和各构造器控制节点；复制后控制只显示可复制的作者场景对象来源，并要求填写副本 Control ID；系统对象可以被控制，但不会出现在复制来源。旋转轨、波浪、长廊、物理发射、函数轨迹、GB 风车和骨墙都有各自命名的控制节点，可移动对应中心；旋转轨等还会显示半径或摆动范围等专属参数。成员对象组移动会保持构造关系，不会下一帧弹回原位。控制对象的“启用跟随”会读取创建时状态，并可切换跟随及目标框。\n节点连接允许连接回自己的列表并受操作预算保护。连接本身是零耗时的控制流，不会冒充一个可等待步骤；如果 A 列表先执行动作再连接到 B，而 B 开头选择“等上一个步骤执行完”，B 会继续等待 A 中连接前的最后一个实际动作。函数轨迹可复制一个已有对象，或带动已有对象组；前者不改原件，后者不复制、不销毁原组并保持相对位置。预览轨迹只在参数改变后重算。内建函数生成的 Control ID 会在原对象组选单标记“运行时”。生命周期直接选择“本回合一直存在”或“指定存活帧数”，不必输入神秘的 -1；旧存档仍兼容。控制 Bone 长度可选中心、头端固定或尾端固定。\n等待可选固定帧数，或等上一个已启用步骤执行完；后一种模式还能填写完成后额外等待的帧数。敌人说话可选自动打字后继续，或使用 X 加速、Z 确认；手动推进默认阻塞该列表的后续项目，也可以取消勾选让气泡与后续脚本并行。条件是不成立时跳过指定后续项目数的 if；当前没有独立 else 节点。除独立播放音效外，每个项目都可附加执行时或执行结束时音效；长音乐不会因项目结束而被截断。"},
        {title:"文本与 XML 标签",body:"回合文本、敌人气泡、物品食用文本和场景打字机共用同一个文本窗口。回合文本、气泡、物品和自由打字机都能分别选择无声、默认文字音、打字机音、Sans 或 Toriel。可以点击任意位置插入文字；Enter 是换行。点窗口右上角 ? 可查准确标签。\n常用：<br> 换行；<page> 下一句；<wait=0.5> 等待；<color=#RRGGBBAA>...</color>；<gradient=#色,#色>...</gradient>；<shake>、<glitch>、<float>、<rotate=15>、<cycle>。\n所有文本支持 Z 继续、X 加速/跳过逐字打印；自动打字机可选择是否等待 Z。普通回合文本、敌人气泡、物品文字和自由打字机与死亡文本使用同一套字体组和彩色 Emoji 图集；Windows 直接输入被拆成代理对的表情会在保存和显示前自动合并。游戏结束文字尚未打完时也可按 Z 尝试复活；编辑器预览会返回编辑器，正常开始的战斗会重新进入战斗。"},
        {title:"颜色与伤害",body:"新建攻击默认勾选“固定模板”：勾选时从颜色模板下拉选择显示颜色，取消时才开放自由调色板。颜色判定使用另一项独立下拉；显示成橙色并不等于橙色判定。旧项目已经保存的颜色模式不会被重置。\n白色普通伤害；蓝色在移动时伤害；橙色在未移动时伤害；亮绿回血并立刻消失；黄色高伤害/可射击；深绿扣当前 HP 上限；红色秒杀。紫色不会立即扣血，而是从黄色当前 HP 的右端向左增长并覆盖黄色区域，最多 40；下一次其他颜色通过自身条件、护盾和无敌时间并真正造成伤害时，占用值才会一起结算并清空，紫色段会随机向上弹出后旋转掉落，而且该结算可以把最后一点 HP 吃掉。回血仍照常增加 HP，但每 2 点治疗量只能抵消 1 点紫色占用；例如治疗 20 最多清除 10 点，余量不足 2 不会清除半点。HUD 会用同一条缓动曲线同步显示黄色增长和紫色消退，治疗抵消不会播放受击掉落。深蓝攻击接触时按住 X 可取消本次伤害。\n伤害数据参考 all_scripts.md，并叠加 UTE 的 DEF/5。真刀保持一次高伤模型，默认 55 HP，但伤害和专属无敌帧都可配置；命中瞬间保留原 KR 端点，HP 到 1 后未能直扣的余量继续加入 KR。"},
        {title:"播放、开发者与存档",body:"时间轴编辑当前玩家回合之后的下一怪物回合；敌人台词结束才是 0:00。右侧先显示“编辑 / 定格 / 播放”状态，再显示当前时间与总时间。\n只在玩家回合/编辑状态拖动时间轴。拖动时会从该回合基线直接求值到目标帧并保持冻结；不是快速播放，进行一半的移动、旋转、缩放和曲线会停在对应进度。快捷函数生成的攻击也会显示。冻结时仍可放置细节，新对象从当前游标开始；空格或 Esc 退出并恢复玩家回合。播放从同一个 0:00 完整运行；播放中按空格冻结当前真实画面，再按一次恢复，Esc 直接退出。怪物回合结束时，底层状态代码必定把主框恢复成玩家回合长方形；90° 倍数旋转的矩形会先等价换位长宽再归零角度，因此不会额外反向转一圈。\n开发者页可强制指定项目已有的怪物回合，也可临时强制 130x130 测试方框。\n顶栏“存档”包含新建、保存当前、载入、撤销上次保存和取消。新存档从空白默认工程建立，不复制当前项目。每个存档是 save 下的独立文件夹，包含 project.json、textures 和 audio；保存覆盖前保留上一版，可撤销一次；载入前保存当前运行态，可复原一次。所有保存、覆盖、载入和复原都有确认步骤。导入的贴图和音频会复制进项目拥有的资源目录，不依赖原素材路径。"},
{title:"快捷操作",body:"游戏“设置”的窗口缩放可等比例放大游戏与编辑器，并记住选择。Workspace 左上小箭头收放积木栏，右上“公式 ?”再次点击可收起。\n左键：选择/拖动；双击：选择同类型同控制 ID 组；右键：对象或列表上下文菜单。\n脚本画布空白拖动：平移 Workspace；Ctrl+滚轮：缩放。Esc 收起或恢复 Workspace，保留选中项和视角；收起时可切换其他标签。输入、下拉、拖放等交互优先取消，不会一次穿透多层。\n选中场景对象或战斗框后滚轮：1°；Ctrl+滚轮：5°；Shift+滚轮：10°。右侧属性面板上的滚轮仍用于浏览参数。\n文本：Z 确认/下一句，X 加速；播放：空格暂停或继续，Esc 退出预览并返回玩家回合。下拉菜单展开后，点击任何菜单外空白处即可收起。"}
    ];
}

function BattleEditor_HelpLineCount(text_value) {
    var result=1;
    var source=string(text_value);
    for(var i=1;i<=string_length(source);i++) if(string_char_at(source,i)=="\n") result+=1;
    return result;
}

function BattleEditor_HelpSectionOffset(section_index) {
    var sections=BattleEditor_HelpSections();
    // Directory rows begin at y=94 and occupy 22 px each. Keep the first
    // chapter below the final row instead of overlapping chapter 12.
    var offset=94+array_length(sections)*22+24;
    for(var i=0;i<section_index&&i<array_length(sections);i++) offset+=32+BattleEditor_HelpLineCount(sections[i].body)*18+18;
    return offset;
}

function BattleEditor_HelpContentHeight() {
    var sections=BattleEditor_HelpSections();
    return BattleEditor_HelpSectionOffset(array_length(sections))+28;
}

function BattleEditor_PathJoin(base_path,child_path) {
    var base=string_replace_all(string(base_path),"\\","/");
    var child=string_replace_all(string(child_path),"\\","/");
    while(string_length(base)>0&&string_char_at(base,string_length(base))=="/") base=string_delete(base,string_length(base),1);
    while(string_length(child)>0&&string_char_at(child,1)=="/") child=string_delete(child,1,1);
    if(string_length(base)<=0) return child;
    if(string_length(child)<=0) return base;
    return base+"/"+child;
}

function BattleEditor_EnsureDirectory(path) {
    if(directory_exists(path)) return true;
    directory_create(path);
    return directory_exists(path);
}

/// Windows desktop builds have the file sandbox disabled. working_directory
/// therefore resolves to the folder containing the running game data: beside
/// the packaged EXE, or beside the .win supplied to Runner.
function BattleEditor_SaveRoot() {
    var root=BattleEditor_PathJoin(working_directory,"save");
    BattleEditor_EnsureDirectory(root);
    return root;
}

function BattleEditor_SaveStateDirectory() {
    var result=BattleEditor_PathJoin(BattleEditor_SaveRoot(),"_state");
    BattleEditor_EnsureDirectory(result);
    return result;
}

function BattleEditor_RuntimeSaveDirectory(snapshot_name="current") {
    var runtime_root=BattleEditor_PathJoin(BattleEditor_SaveRoot(),"_runtime");
    BattleEditor_EnsureDirectory(runtime_root);
    var result=BattleEditor_PathJoin(runtime_root,snapshot_name);
    BattleEditor_EnsureDirectory(result);
    return result;
}

function BattleEditor_SanitizeSaveName(value) {
    var result=string_trim(string(value));
    var invalid=["<",">",":","\"","/","\\","|","?","*"];
    for(var invalid_index=0;invalid_index<array_length(invalid);invalid_index++) result=string_replace_all(result,invalid[invalid_index],"_");
    while(string_length(result)>0){
        var last=string_char_at(result,string_length(result));
        if(last!="."&&last!=" ") break;
        result=string_delete(result,string_length(result),1);
    }
    if(result=="."||result=="..") result="";
    if(string_length(result)>0&&string_char_at(result,1)=="_") result="存档"+result;
    return string_copy(result,1,64);
}

function BattleEditor_SaveSlotDirectory(slot_name) {
    return BattleEditor_PathJoin(BattleEditor_SaveRoot(),BattleEditor_SanitizeSaveName(slot_name));
}

function BattleEditor_SaveSlotExists(slot_name) {
    var clean=BattleEditor_SanitizeSaveName(slot_name);
    if(string_length(clean)<=0) return false;
    return file_exists(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(clean),"project.json"));
}

function BattleEditor_NextSaveSlotName() {
    var base_name="新存档";
    var suffix=1;
    while(true){
        var candidate=suffix==1?base_name:base_name+" "+string(suffix);
        if(!directory_exists(BattleEditor_SaveSlotDirectory(candidate))) return candidate;
        suffix+=1;
    }
}

function BattleEditor_SaveSlotBackupFlags(slot_names) {
    var result=[];
    for(var slot_index=0;slot_index<array_length(slot_names);slot_index++) array_push(result,BattleEditor_SaveSlotHasBackup(slot_names[slot_index]));
    return result;
}

function BattleEditor_ListSaveSlots() {
    var result=[];
    var root=BattleEditor_SaveRoot();
    var found=file_find_first(BattleEditor_PathJoin(root,"*"),fa_directory);
    while(found!=""){
        var folder_name=filename_name(found);
        if(folder_name!="."&&folder_name!=".."&&string_length(folder_name)>0&&string_char_at(folder_name,1)!="_"){
            var folder_path=BattleEditor_PathJoin(root,folder_name);
            if(directory_exists(folder_path)&&file_exists(BattleEditor_PathJoin(folder_path,"project.json"))) array_push(result,folder_name);
        }
        found=file_find_next();
    }
    file_find_close();
    array_sort(result,true);
    return result;
}

function BattleEditor_SaveActiveSlotName(slot_name) {
    var clean=BattleEditor_SanitizeSaveName(slot_name);
    if(string_length(clean)<=0) return false;
    var active_written=File_WriteAllText(BattleEditor_PathJoin(BattleEditor_SaveStateDirectory(),"active.txt"),clean);
    // Keep recency portable with the save folder itself. Some supported
    // runners do not expose file_get_modified_time(), so filesystem metadata
    // cannot be used safely to choose a default after a save is copied to a
    // different machine or build directory.
    if(active_written&&directory_exists(BattleEditor_SaveSlotDirectory(clean))){
        File_WriteAllText(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(clean),"_last_used.txt"),string(date_current_datetime()));
    }
    return active_written;
}

function BattleEditor_SaveBattleSource(value) {
    return File_WriteAllText(BattleEditor_PathJoin(BattleEditor_SaveStateDirectory(),"battle_source.txt"),string(value));
}

function BattleEditor_LoadBattleSource() {
    var value=File_ReadAllText(BattleEditor_PathJoin(BattleEditor_SaveStateDirectory(),"battle_source.txt"));
    if(is_undefined(value)) return "current";
    var clean=string_trim(string(value));
    return string_length(clean)>0?clean:"current";
}

function BattleEditor_SelectBattleSlot(slot_name) {
    var clean=BattleEditor_SanitizeSaveName(slot_name);
    if(!BattleEditor_SaveSlotExists(clean)) return false;
    if(!BattleEditor_SaveActiveSlotName(clean)) return false;
    return BattleEditor_SaveBattleSource("slot:"+clean);
}

function BattleEditor_LoadActiveSlotName() {
    var value=File_ReadAllText(BattleEditor_PathJoin(BattleEditor_SaveStateDirectory(),"active.txt"));
    if(!is_undefined(value)){
        var clean=BattleEditor_SanitizeSaveName(value);
        if(string_length(clean)>0&&file_exists(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(clean),"project.json"))) return clean;
    }

    // A fresh portable copy may already contain several save folders but no
    // machine-local active.txt. Prefer the portable recency marker written by
    // save/load. Old saves have no marker, so fall back deterministically to
    // the first listed slot instead of calling a runner-specific file-time API.
    // Once resolved, persist the choice so normal battle entry never rescans.
    var slots=BattleEditor_ListSaveSlots();
    var latest=array_length(slots)>0?slots[0]:"";
    var latest_time=-1;
    for(var slot_index=0;slot_index<array_length(slots);slot_index++){
        var marker_text=File_ReadAllText(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(slots[slot_index]),"_last_used.txt"));
        if(!is_undefined(marker_text)){
            var marker_time=real(string_trim(marker_text));
            if(marker_time>latest_time){latest_time=marker_time;latest=slots[slot_index];}
        }
    }
    if(latest!="") BattleEditor_SaveActiveSlotName(latest);
    return latest;
}

function BattleEditor_StringEndsWith(value,suffix) {
    var source=string_lower(string(value));
    var ending=string_lower(string(suffix));
    if(string_length(ending)>string_length(source)) return false;
    return string_copy(source,string_length(source)-string_length(ending)+1,string_length(ending))==ending;
}

function BattleEditor_ResourceFolderForPath(path) {
    var image_ext_values=[".png",".jpg",".jpeg",".webp",".bmp",".gif"];
    for(var image_ext_cursor=0;image_ext_cursor<array_length(image_ext_values);image_ext_cursor++) if(BattleEditor_StringEndsWith(path,image_ext_values[image_ext_cursor])) return "textures";
    var audio_ext_values=[".wav",".ogg",".mp3",".flac",".wma",".aac",".m4a"];
    for(var audio_ext_cursor=0;audio_ext_cursor<array_length(audio_ext_values);audio_ext_cursor++) if(BattleEditor_StringEndsWith(path,audio_ext_values[audio_ext_cursor])) return "audio";
    return "";
}

function BattleEditor_SafeResourceFileName(path) {
    var result=filename_name(string(path));
    var invalid=["<",">",":","\"","/","\\","|","?","*"];
    for(var invalid_index=0;invalid_index<array_length(invalid);invalid_index++) result=string_replace_all(result,invalid[invalid_index],"_");
    if(string_length(result)<=0) result="resource.bin";
    return result;
}

function BattleEditor_CopyFileOverwrite(source,destination) {
    if(string_lower(string(source))==string_lower(string(destination))) return file_exists(destination);
    if(file_exists(destination)) file_delete(destination);
    return file_copy(source,destination)&&file_exists(destination);
}

function BattleEditor_UniqueResourceDestination(folder,source_path,prefix="r") {
    BattleEditor_EnsureDirectory(folder);
    var base=BattleEditor_SafeResourceFileName(source_path);
    var index=1;
    var destination=BattleEditor_PathJoin(folder,prefix+string(index)+"_"+base);
    while(file_exists(destination)){index+=1;destination=BattleEditor_PathJoin(folder,prefix+string(index)+"_"+base);}
    return destination;
}

/// File-picker imports are staged immediately under save/_runtime/current.
/// The in-memory project points at this owned copy, so deleting or moving the
/// user's original file after selection cannot break a later save.
function BattleEditor_StageResource(source_path) {
    var source=string(source_path);
    var kind=BattleEditor_ResourceFolderForPath(source);
    if(kind==""||!file_exists(source)) return source;
    var destination_folder=BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory("current"),kind);
    var destination=BattleEditor_UniqueResourceDestination(destination_folder,source,"import_");
    return BattleEditor_CopyFileOverwrite(source,destination)?destination:source;
}

function BattleEditor_EnsureEnemyResourceDirectory(root,enemy_name) {
    var textures=BattleEditor_PathJoin(root,"textures");
    var enemies=BattleEditor_PathJoin(textures,"enemies");
    var character=BattleEditor_PathJoin(enemies,BattleEditor_EnemyDirectoryName(enemy_name));
    BattleEditor_EnsureDirectory(textures);
    BattleEditor_EnsureDirectory(enemies);
    BattleEditor_EnsureDirectory(character);
    return character;
}

/// Imports one enemy-owned visual resource. The resource keeps the enemy UID;
/// the directory uses the current display name and can therefore be migrated
/// without breaking Workspace steps.
function BattleEditor_StageEnemyResource(project,enemy_uid,source_path,part_hint="body",display_name="") {
    project=BattleEditor_ProjectNormalize(project);
    var enemy=BattleEditor_FindEnemyByUid(project,enemy_uid);
    var source=string(source_path);
    if(is_undefined(enemy)||!file_exists(source)||BattleEditor_ResourceFolderForPath(source)!="textures") return undefined;
    var destination_folder=BattleEditor_EnsureEnemyResourceDirectory(BattleEditor_RuntimeSaveDirectory("current"),enemy.name);
    var destination=BattleEditor_UniqueResourceDestination(destination_folder,source,"asset_");
    if(!BattleEditor_CopyFileOverwrite(source,destination)) return undefined;
    if(display_name=="") display_name=filename_name(source);
    return BattleEditor_NewEnemyTextureResource(project,enemy_uid,display_name,destination,part_hint);
}

function BattleEditor_StageEnemyAnimationFrame(project,resource_uid,source_path) {
    project=BattleEditor_ProjectNormalize(project);
    var resource=BattleEditor_FindEnemyTextureResource(project,resource_uid);
    if(is_undefined(resource)||!file_exists(source_path)) return "";
    var enemy=BattleEditor_FindEnemyByUid(project,resource.enemy_uid);
    if(is_undefined(enemy)) return "";
    var destination_folder=BattleEditor_EnsureEnemyResourceDirectory(BattleEditor_RuntimeSaveDirectory("current"),enemy.name);
    var destination=BattleEditor_UniqueResourceDestination(destination_folder,source_path,"frame_");
    if(!BattleEditor_CopyFileOverwrite(source_path,destination)) return "";
    if(!is_struct(resource.animation)) resource.animation=BattleEditor_NewAnimation();
    if(!is_array(resource.animation.frames)) resource.animation.frames=[];
    array_push(resource.animation.frames,destination);
    if(string_length(string(resource.path))<=0) resource.path=destination;
    return destination;
}

/// Rename is a resource migration, not a reference rewrite. Script steps and
/// parts retain their UIDs; only owned file paths move to the new character
/// directory. This is the practical reason display names are never identities.
function BattleEditor_RenameEnemyResourceDirectory(project,enemy_uid,old_name,new_name) {
    project=BattleEditor_ProjectNormalize(project);
    var enemy=BattleEditor_FindEnemyByUid(project,enemy_uid);
    if(is_undefined(enemy)) return false;
    var target_folder=BattleEditor_EnsureEnemyResourceDirectory(BattleEditor_RuntimeSaveDirectory("current"),new_name);
    var old_folder=BattleEditor_EnsureEnemyResourceDirectory(BattleEditor_RuntimeSaveDirectory("current"),old_name);
    var old_prefix=string_lower(string_replace_all(old_folder,"\\","/"));
    if(string_char_at(old_prefix,string_length(old_prefix))!="/") old_prefix+="/";
    var target_prefix=string_lower(string_replace_all(target_folder,"\\","/"));
    if(string_char_at(target_prefix,string_length(target_prefix))!="/") target_prefix+="/";
    var changed=false;var copied_old_paths=[];
    for(var resource_index=0;resource_index<array_length(project.resources.enemy_textures);resource_index++){
        var resource=project.resources.enemy_textures[resource_index];
        if(resource.enemy_uid!=enemy_uid) continue;
        var old_path=string(resource.path);
        if(file_exists(old_path)){
            var new_path=BattleEditor_UniqueResourceDestination(target_folder,old_path,"asset_");
            if(BattleEditor_CopyFileOverwrite(old_path,new_path)){
                resource.path=new_path;changed=true;
                var normalized_old_path=string_lower(string_replace_all(old_path,"\\","/"));
                if(string_pos(old_prefix,normalized_old_path)==1&&string_pos(target_prefix,normalized_old_path)!=1) array_push(copied_old_paths,old_path);
            }
        }
        var new_frames=[];
        for(var frame_index=0;frame_index<array_length(resource.animation.frames);frame_index++){
            var old_frame=string(resource.animation.frames[frame_index]);var new_frame=old_frame;
            if(file_exists(old_frame)){
                new_frame=BattleEditor_UniqueResourceDestination(target_folder,old_frame,"frame_");
                if(!BattleEditor_CopyFileOverwrite(old_frame,new_frame)) new_frame=old_frame;
                else{
                    changed=true;
                    var normalized_old_frame=string_lower(string_replace_all(old_frame,"\\","/"));
                    if(string_pos(old_prefix,normalized_old_frame)==1&&string_pos(target_prefix,normalized_old_frame)!=1) array_push(copied_old_paths,old_frame);
                }
            }
            array_push(new_frames,new_frame);
        }
        resource.animation.frames=new_frames;
    }
    // Keep legacy source fields readable, but derive their values from the
    // UID-owned catalog instead of treating the old path as identity.
    var part_keys=BattleEditor_EnemyPartKeys();
    for(var part_index=0;part_index<array_length(part_keys);part_index++){
        var part=variable_struct_get(enemy.parts,part_keys[part_index]);
        var assigned=BattleEditor_FindEnemyTextureResource(project,part.asset_uid);
        if(!is_undefined(assigned)){part.source=assigned.path;part.animation=assigned.animation;}
    }
    // Remove only files owned by the old runtime character directory, and
    // only after every replacement path has been written. Bundled defaults
    // and user originals are never deleted. Saved slots therefore contain one
    // active character directory whose name matches the character display.
    for(var delete_index=0;delete_index<array_length(copied_old_paths);delete_index++){
        var delete_path=copied_old_paths[delete_index];
        if(file_exists(delete_path)) file_delete(delete_path);
    }
    if(old_prefix!=target_prefix&&directory_exists(old_folder)) directory_destroy(old_folder);
    return changed||BattleEditor_EnemyDirectoryName(old_name)==BattleEditor_EnemyDirectoryName(new_name);
}

function BattleEditor_RegisterImportedAudio(project,source_path) {
    project=BattleEditor_ProjectNormalize(project);
    var staged=BattleEditor_StageResource(source_path);
    if(!file_exists(staged)||BattleEditor_ResourceFolderForPath(staged)!="audio") return "";
    for(var audio_index=0;audio_index<array_length(project.resources.audio);audio_index++){
        if(string_lower(string(project.resources.audio[audio_index].path))==string_lower(staged)) return staged;
    }
    array_push(project.resources.audio,{name:filename_name(source_path),path:staged});
    return staged;
}

function BattleEditor_ResolveProjectResourceValue(value,resource_root) {
    if(is_string(value)){
        var normalized=string_replace_all(value,"\\","/");
        if(string_pos("textures/",string_lower(normalized))==1||string_pos("audio/",string_lower(normalized))==1){
            var absolute=BattleEditor_PathJoin(resource_root,normalized);
            if(file_exists(absolute)) return absolute;
        }
        return value;
    }
    if(is_array(value)){
        for(var array_index=0;array_index<array_length(value);array_index++) value[array_index]=BattleEditor_ResolveProjectResourceValue(value[array_index],resource_root);
        return value;
    }
    if(is_struct(value)){
        var names=variable_struct_get_names(value);
        for(var name_index=0;name_index<array_length(names);name_index++){
            var name=names[name_index];
            if(name=="_storage_root") continue;
            variable_struct_set(value,name,BattleEditor_ResolveProjectResourceValue(variable_struct_get(value,name),resource_root));
        }
    }
    return value;
}

function BattleEditor_EnemyResourceRelativeFolder(project,source) {
    if(!is_struct(project)||!struct_exists(project,"resources")||!struct_exists(project.resources,"enemy_textures")) return "";
    var normalized_source=string_lower(string_replace_all(string(source),"\\","/"));
    for(var resource_index=0;resource_index<array_length(project.resources.enemy_textures);resource_index++){
        var resource=project.resources.enemy_textures[resource_index];
        if(!is_struct(resource)) continue;
        var matched=string_lower(string_replace_all(string(resource.path),"\\","/"))==normalized_source;
        if(!matched&&is_struct(resource.animation)&&is_array(resource.animation.frames)){
            for(var frame_index=0;frame_index<array_length(resource.animation.frames);frame_index++){
                if(string_lower(string_replace_all(string(resource.animation.frames[frame_index]),"\\","/"))==normalized_source){matched=true;break;}
            }
        }
        if(!matched) continue;
        var enemy=BattleEditor_FindEnemyByUid(project,resource.enemy_uid);
        if(is_undefined(enemy)) return "textures/enemies/未归属角色";
        return "textures/enemies/"+BattleEditor_EnemyDirectoryName(enemy.name);
    }
    return "";
}

/// Returns an owned resource path relative to root, or an empty string when
/// path is outside that root.  Keeping this relative identity is important:
/// a resource already stored as textures/enemies/DUST/body.png must not become
/// r1_body.png, r2_body.png, ... every time current is committed to a slot.
function BattleEditor_OwnedResourceRelativePath(path,root) {
    if(string_length(string(root))<=0) return "";
    var normalized_path=string_replace_all(string(path),"\\","/");
    var normalized_root=string_replace_all(string(root),"\\","/");
    while(string_length(normalized_root)>0&&string_char_at(normalized_root,string_length(normalized_root))=="/") normalized_root=string_delete(normalized_root,string_length(normalized_root),1);
    var prefix=normalized_root+"/";
    if(string_pos(string_lower(prefix),string_lower(normalized_path))!=1) return "";
    var relative=string_copy(normalized_path,string_length(prefix)+1,string_length(normalized_path));
    var relative_lower=string_lower(relative);
    if(string_pos("textures/",relative_lower)!=1&&string_pos("audio/",relative_lower)!=1) return "";
    return relative;
}

function BattleEditor_PackageProjectResourceValue(value,context) {
    if(is_string(value)){
        var original=string(value);
        var source=original;
        var kind=BattleEditor_ResourceFolderForPath(source);
        if(kind=="") return value;
        if(!file_exists(source)&&string_length(context.source_root)>0){
            var rooted=BattleEditor_PathJoin(context.source_root,source);
            if(file_exists(rooted)) source=rooted;
        }
        if(!file_exists(source)) return value;
        for(var map_index=0;map_index<array_length(context.sources);map_index++) if(string_lower(context.sources[map_index])==string_lower(source)) return context.relative[map_index];

        // A save may package from its own folder or from _runtime/current.
        // Preserve an already-owned relative path in both cases.  Re-deriving
        // only the basename lost resource identity and caused each save to
        // manufacture another numbered copy of the same five DUST images.
        var relative=BattleEditor_OwnedResourceRelativePath(source,context.destination_root);
        if(relative!=""){
            array_push(context.sources,source);array_push(context.relative,relative);
            return relative;
        }
        relative=BattleEditor_OwnedResourceRelativePath(source,context.source_root);
        var relative_folder="";
        var destination_name="";
        if(relative!=""){
            var last_slash=0;
            for(var slash_index=1;slash_index<=string_length(relative);slash_index++) if(string_char_at(relative,slash_index)=="/") last_slash=slash_index;
            relative_folder=last_slash>0?string_copy(relative,1,last_slash-1):kind;
            destination_name=last_slash>0?string_delete(relative,1,last_slash):BattleEditor_SafeResourceFileName(source);
        }else{
            relative_folder=BattleEditor_EnemyResourceRelativeFolder(context.project,source);
            if(relative_folder=="") relative_folder=kind;
            destination_name=BattleEditor_SafeResourceFileName(source);
            relative=relative_folder+"/"+destination_name;
        }
        var destination_folder=context.destination_root;
        var folder_parts=string_split(relative_folder,"/");
        for(var folder_index=0;folder_index<array_length(folder_parts);folder_index++){
            destination_folder=BattleEditor_PathJoin(destination_folder,folder_parts[folder_index]);
            BattleEditor_EnsureDirectory(destination_folder);
        }
        // Runtime imports already receive a unique owned filename. A formal
        // save must keep that filename stable: choosing another rN_ name on
        // every save duplicated the same asset hundreds of times and could
        // exhaust file handles before project.json was replaced.
        var destination=BattleEditor_PathJoin(destination_folder,destination_name);
        var normalized_source=string_lower(string_replace_all(source,"\\","/"));
        var normalized_destination=string_lower(string_replace_all(destination,"\\","/"));
        if(normalized_source!=normalized_destination&&!BattleEditor_CopyFileOverwrite(source,destination)) return value;
        relative=relative_folder+"/"+filename_name(destination);
        array_push(context.sources,source);array_push(context.relative,relative);
        return relative;
    }
    if(is_array(value)){
        for(var array_index=0;array_index<array_length(value);array_index++) value[array_index]=BattleEditor_PackageProjectResourceValue(value[array_index],context);
        return value;
    }
    if(is_struct(value)){
        var names=variable_struct_get_names(value);
        for(var name_index=0;name_index<array_length(names);name_index++){
            var name=names[name_index];
            if(name=="_storage_root") continue;
            variable_struct_set(value,name,BattleEditor_PackageProjectResourceValue(variable_struct_get(value,name),context));
        }
    }
    return value;
}

function BattleEditor_CopySelectedStructFields(source,field_names) {
    var result={};
    for(var field_index=0;field_index<array_length(field_names);field_index++){
        var field_name=field_names[field_index];
        if(struct_exists(source,field_name)) variable_struct_set(result,field_name,variable_struct_get(source,field_name));
    }
    return result;
}

/// A control step is itself a tagged union.  Persisting every possible
/// inspector field here would merely move the old 97-field problem down one
/// level, so select the payload from the active property as well.
function BattleEditor_ControlStepFieldsForStorage(step) {
    var fields=[
        "target_mode","control_source_mode","copy_control_id","copy_control_id_auto",
        "target","target_type","target_group_uid","target_group_kind","target_category",
        "property_category","target_uid","target_list_uid","property"
    ];
    var property_name=string(step.property);
    switch(property_name){
        case "position":
            array_push(fields,"position_x","position_y","position_angle","coordinate_mode");
            if(step.target_type=="board"){
                array_push(fields,"board_transform_width","board_transform_height");
            }
            break;
        case "orbit":
            // The requested rotation amount is the payload of an orbit step.
            // Omitting it from sparse storage silently restored the default 0
            // after compaction/reload even though the inspector had saved it.
            array_push(fields,"value","orbit_center_x","orbit_center_y","orbit_use_group_center");
            break;
        case "physics":
            array_push(fields,"physics_direction","physics_speed","physics_acceleration","physics_curve_speed","physics_rotation_speed");
            break;
        case "aim_motion":
            array_push(fields,"aim_target_uid","aim_continuous","aim_move_speed","aim_face_target","aim_behavior");
            break;
        case "control_vertex":
            array_push(fields,"vertex_uids","vertex_target_x","vertex_target_y","coordinate_mode");
            break;
        case "shape":
            array_push(fields,"value","board_shape_width","board_shape_height","board_shape_radius_x","board_shape_radius_y","board_shape_triangle_width","board_shape_triangle_height");
            break;
        case "length":
            array_push(fields,"value","length_anchor");
            break;
        case "damage_type":
            array_push(fields,"value","damage_change_visual");
            break;
        case "follow":
            array_push(fields,"value","follow_target_uid","follow_value_initialized");
            break;
        case "soul_mode":
            array_push(fields,"value","soul_blue_direction","blue_gravity_throw");
            break;
        case "blue_direction":
            array_push(fields,"value","blue_gravity_throw");
            break;
        case "speak":
            array_push(fields,"text_value","dialogue_font","dialogue_voice","dialogue_template","dialogue_offset_x","dialogue_offset_y","dialogue_mode","dialogue_block_battle");
            break;
        case "text":
        case "player_name":
            array_push(fields,"text_value");
            break;
        case "gb_hold":
        case "gb_release":
            // These commands have no numeric payload.
            break;
        default:
            array_push(fields,"value");
            break;
    }
    var is_move=property_name=="position"||property_name=="orbit"||property_name=="physics"||property_name=="aim_motion";
    if(is_move){
        array_push(fields,"warning_enabled","warning_duration","warning_angle_mode","warning_angle");
        if(step.target_type=="gb") array_push(fields,"gb_hold_while_moving","gb_move_sound");
    }
    if(BattleEditor_ControlStepUsesDuration(step)) array_push(fields,"duration","tween","ease");
    return fields;
}

/// Runtime steps are normalized into one convenient superset while editing,
/// but that superset is not the file format. Persist only fields meaningful to
/// the selected kind; ProjectNormalize restores defaults after loading old or
/// sparse saves. This keeps a Wait from carrying the entire editor inspector.
function BattleEditor_ScriptStepForStorage(step) {
    var common=["uid","kind","step_sound_enabled","sound_name","sound_timing"];
    var fields=[];
    switch(string(step.kind)){
        case "wait":
            fields=["wait_mode"];
            if(struct_exists(step,"wait_mode")&&round(real(step.wait_mode))==1) array_push(fields,"wait_extra_duration");
            else array_push(fields,"duration");
            break;
        case "start_list":fields=["target_list_uid"];break;
        case "control_object":fields=BattleEditor_ControlStepFieldsForStorage(step);break;
        case "create_object":fields=[
            "create_category","create_preset","create_control_id","create_control_id_auto","create_x","create_y","create_angle","create_lifetime","create_size",
            "create_width","create_height","create_board_shape","create_board_up","create_board_down","create_board_left","create_board_right","create_board_radius_x","create_board_radius_y",
            "create_board_triangle_size","create_board_rotate","create_board_depth","create_damage_type","create_layer_mode","create_template","create_animation_frame_index","points","point_index","tween","ease"
        ];break;
        case "builtin_action":fields=[
            "action_name","action_control_id","action_control_id_auto","action_source_uid","action_direction","action_arguments","action_path_variable","action_path_mode","action_path_target_type",
            "action_path_legacy_default","action_follow","action_keep_objects","action_damage_change_visual","action_exit_tween","action_exit_ease",
            "warning_enabled","warning_duration","tween","ease"
        ];break;
        case "screen_control":fields=["screen_action","screen_arguments","tween","ease"];break;
        case "play_sound":fields=["sound_name","sound_timing"];common=["uid","kind"];break;
        case "enemy_appearance":fields=["enemy_uid","enemy_part_key","enemy_resource_uid"];break;
        case "get_value":fields=["read_target_key","read_target_uid","read_target_type","read_property","read_variable_name","read_overwrite_confirmed"];break;
        case "set_variable":fields=["variable_name","expression","variable_operation"];break;
        case "condition":fields=["condition_left","condition_operator","condition_right","skip_count"];break;
        case "repeat":fields=["repeat_count","repeat_length","repeat_interval"];break;
        case "run_script":fields=["script_name","script_arguments","wait_for_script"];break;
    }
    var result=BattleEditor_CopySelectedStructFields(step,common);
    for(var field_index=0;field_index<array_length(fields);field_index++){
        var field_name=fields[field_index];
        if(struct_exists(step,field_name)) variable_struct_set(result,field_name,variable_struct_get(step,field_name));
    }
    // Built-in arguments are separate UI fields and separate persisted values.
    // Keeping the old semicolon string only in memory would make changing one
    // argument journal the whole mystery-number row again.
    if(string(step.kind)=="builtin_action"&&struct_exists(result,"action_arguments")&&!is_array(result.action_arguments)) result.action_arguments=string_split(string(result.action_arguments),";");
    if(struct_exists(step,"enabled")&&!step.enabled) result.enabled=false;
    return result;
}

function BattleEditor_ProjectSparseForStorage(project) {
    var stored={};
    var project_fields=variable_struct_get_names(project);
    for(var project_field_index=0;project_field_index<array_length(project_fields);project_field_index++){
        var project_field=project_fields[project_field_index];
        if(project_field!="script_lists"&&project_field!="_storage_root") variable_struct_set(stored,project_field,variable_struct_get(project,project_field));
    }
    stored.script_lists=[];
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var source_list=project.script_lists[list_index];
        var stored_list={};
        var list_fields=variable_struct_get_names(source_list);
        for(var list_field_index=0;list_field_index<array_length(list_fields);list_field_index++){
            var list_field=list_fields[list_field_index];
            if(list_field!="steps") variable_struct_set(stored_list,list_field,variable_struct_get(source_list,list_field));
        }
        stored_list.steps=[];
        for(var step_index=0;step_index<array_length(source_list.steps);step_index++) array_push(stored_list.steps,BattleEditor_ScriptStepForStorage(source_list.steps[step_index]));
        array_push(stored.script_lists,stored_list);
    }
    return stored;
}

function BattleEditor_StorageClone(value) {
    if(is_array(value)){
        var cloned_array=[];
        for(var array_index=0;array_index<array_length(value);array_index++) array_push(cloned_array,BattleEditor_StorageClone(value[array_index]));
        return cloned_array;
    }
    if(is_struct(value)){
        var cloned_struct={};
        var names=variable_struct_get_names(value);
        for(var name_index=0;name_index<array_length(names);name_index++){
            var name=names[name_index];
            variable_struct_set(cloned_struct,name,BattleEditor_StorageClone(variable_struct_get(value,name)));
        }
        return cloned_struct;
    }
    return value;
}

function BattleEditor_StorageValueEqual(left,right) {
    if(is_array(left)||is_array(right)){
        if(!is_array(left)||!is_array(right)||array_length(left)!=array_length(right)) return false;
        for(var array_index=0;array_index<array_length(left);array_index++) if(!BattleEditor_StorageValueEqual(left[array_index],right[array_index])) return false;
        return true;
    }
    if(is_struct(left)||is_struct(right)){
        if(!is_struct(left)||!is_struct(right)) return false;
        var left_names=variable_struct_get_names(left),right_names=variable_struct_get_names(right);
        if(array_length(left_names)!=array_length(right_names)) return false;
        for(var name_index=0;name_index<array_length(left_names);name_index++){
            var name=left_names[name_index];
            if(!variable_struct_exists(right,name)||!BattleEditor_StorageValueEqual(variable_struct_get(left,name),variable_struct_get(right,name))) return false;
        }
        return true;
    }
    if(is_undefined(left)||is_undefined(right)) return is_undefined(left)&&is_undefined(right);
    if(is_string(left)!=is_string(right)||is_real(left)!=is_real(right)) return false;
    return left==right;
}

function BattleEditor_StorageNameInArray(names,name) {
    for(var index=0;index<array_length(names);index++) if(names[index]==name) return true;
    return false;
}

function BattleEditor_StorageArrayUsesUniqueUids(values) {
    if(!is_array(values)||array_length(values)<=0) return false;
    var seen={};
    for(var item_index=0;item_index<array_length(values);item_index++){
        var item=values[item_index];
        if(!is_struct(item)||!struct_exists(item,"uid")) return false;
        var key="uid_"+string(item.uid);
        if(variable_struct_exists(seen,key)) return false;
        variable_struct_set(seen,key,true);
    }
    return true;
}

function BattleEditor_StorageUidSelector(value,item=undefined) {
    if(is_undefined(item)||!is_struct(item)) return "@uid:"+string(value);
    // Recovery journals are temporary transaction logs, so favour redundant,
    // self-describing identity over tiny records. UID remains authoritative;
    // the readable fields make a damaged journal auditable without copying the
    // entire enclosing list. They are hints only because name/position/kind can
    // themselves be the field changed by this operation.
    var selector={selector:"uid",uid:string(value)};
    var identity_fields=["name","world_x","world_y","entry_kind","entry_value","turn","kind","action_name","target_type","control_id"];
    for(var identity_index=0;identity_index<array_length(identity_fields);identity_index++){
        var identity_name=identity_fields[identity_index];
        if(variable_struct_exists(item,identity_name)) variable_struct_set(selector,identity_name,BattleEditor_StorageClone(variable_struct_get(item,identity_name)));
    }
    return selector;
}

/// Numeric paths remain readable for old journals. New journals address
/// identity-bearing list items by UID, so inserting a list or step cannot make
/// a later field edit land on its neighbour.
function BattleEditor_StorageResolveArrayIndex(values,key) {
    if(!is_array(values)) return -1;
    if(is_real(key)){
        var numeric_index=round(key);
        return numeric_index>=0&&numeric_index<array_length(values)?numeric_index:-1;
    }
    var wanted="";
    if(is_struct(key)&&variable_struct_exists(key,"uid")) wanted=string(variable_struct_get(key,"uid"));
    else{
        var selector=string(key);
        if(string_pos("@uid:",selector)!=1) return -1;
        wanted=string_delete(selector,1,5);
    }
    var result=-1;
    for(var item_index=0;item_index<array_length(values);item_index++){
        var item=values[item_index];
        if(!is_struct(item)||!struct_exists(item,"uid")||string(item.uid)!=wanted) continue;
        if(result>=0) return -1;
        result=item_index;
    }
    return result;
}

/// Produce semantic field operations. Scalar edits become one set operation;
/// array insertion/removal becomes one splice around the unchanged prefix and
/// suffix. No operation contains an enclosing script list or project copy.
function BattleEditor_StorageCollectChanges(previous,current,path,operations) {
    if(is_struct(previous)&&is_struct(current)){
        var current_names=variable_struct_get_names(current);
        var previous_names=variable_struct_get_names(previous);
        for(var current_index=0;current_index<array_length(current_names);current_index++){
            var current_name=current_names[current_index];
            var child_path=BattleEditor_StorageClone(path);array_push(child_path,current_name);
            if(!variable_struct_exists(previous,current_name)) array_push(operations,{op:"set",path:child_path,value:BattleEditor_StorageClone(variable_struct_get(current,current_name))});
            else BattleEditor_StorageCollectChanges(variable_struct_get(previous,current_name),variable_struct_get(current,current_name),child_path,operations);
        }
        for(var previous_index=0;previous_index<array_length(previous_names);previous_index++){
            var previous_name=previous_names[previous_index];
            if(!BattleEditor_StorageNameInArray(current_names,previous_name)){
                var remove_path=BattleEditor_StorageClone(path);array_push(remove_path,previous_name);
                array_push(operations,{op:"remove",path:remove_path});
            }
        }
        return operations;
    }
    if(is_array(previous)&&is_array(current)){
        var previous_length=array_length(previous),current_length=array_length(current);
        var uid_addressable=BattleEditor_StorageArrayUsesUniqueUids(previous)&&BattleEditor_StorageArrayUsesUniqueUids(current);
        if(uid_addressable){
            var uid_prefix=0,uid_shared_limit=min(previous_length,current_length);
            while(uid_prefix<uid_shared_limit&&string(previous[uid_prefix].uid)==string(current[uid_prefix].uid)) uid_prefix+=1;
            var uid_suffix=0,uid_remaining_limit=uid_shared_limit-uid_prefix;
            while(uid_suffix<uid_remaining_limit&&string(previous[previous_length-uid_suffix-1].uid)==string(current[current_length-uid_suffix-1].uid)) uid_suffix+=1;
            for(var uid_front_index=0;uid_front_index<uid_prefix;uid_front_index++){
                var uid_front_path=BattleEditor_StorageClone(path);array_push(uid_front_path,BattleEditor_StorageUidSelector(previous[uid_front_index].uid,previous[uid_front_index]));
                BattleEditor_StorageCollectChanges(previous[uid_front_index],current[uid_front_index],uid_front_path,operations);
            }
            for(var uid_back_offset=uid_suffix-1;uid_back_offset>=0;uid_back_offset--){
                var previous_back_index=previous_length-uid_back_offset-1;
                var current_back_index=current_length-uid_back_offset-1;
                var uid_back_path=BattleEditor_StorageClone(path);array_push(uid_back_path,BattleEditor_StorageUidSelector(previous[previous_back_index].uid,previous[previous_back_index]));
                BattleEditor_StorageCollectChanges(previous[previous_back_index],current[current_back_index],uid_back_path,operations);
            }
            if(uid_prefix+uid_suffix<previous_length||uid_prefix+uid_suffix<current_length){
                var uid_inserted=[];
                for(var uid_insert_index=uid_prefix;uid_insert_index<current_length-uid_suffix;uid_insert_index++) array_push(uid_inserted,BattleEditor_StorageClone(current[uid_insert_index]));
                array_push(operations,{op:"splice",path:BattleEditor_StorageClone(path),index:uid_prefix,remove:previous_length-uid_prefix-uid_suffix,items:uid_inserted});
            }
            return operations;
        }
        if(previous_length==current_length){
            for(var array_index=0;array_index<current_length;array_index++){
                var item_path=BattleEditor_StorageClone(path);array_push(item_path,array_index);
                BattleEditor_StorageCollectChanges(previous[array_index],current[array_index],item_path,operations);
            }
            return operations;
        }
        var prefix=0,shared_limit=min(previous_length,current_length);
        while(prefix<shared_limit&&BattleEditor_StorageValueEqual(previous[prefix],current[prefix])) prefix+=1;
        var suffix=0,remaining_limit=shared_limit-prefix;
        while(suffix<remaining_limit&&BattleEditor_StorageValueEqual(previous[previous_length-suffix-1],current[current_length-suffix-1])) suffix+=1;
        var inserted=[];
        for(var insert_index=prefix;insert_index<current_length-suffix;insert_index++) array_push(inserted,BattleEditor_StorageClone(current[insert_index]));
        array_push(operations,{op:"splice",path:BattleEditor_StorageClone(path),index:prefix,remove:previous_length-prefix-suffix,items:inserted});
        return operations;
    }
    if(!BattleEditor_StorageValueEqual(previous,current)) array_push(operations,{op:"set",path:BattleEditor_StorageClone(path),value:BattleEditor_StorageClone(current)});
    return operations;
}

function BattleEditor_StorageSetAtPath(root,path,value,depth=0) {
    if(depth>=array_length(path)) return BattleEditor_StorageClone(value);
    var key=path[depth];
    if(is_array(root)){
        var array_index=BattleEditor_StorageResolveArrayIndex(root,key);
        if(array_index>=0) root[array_index]=BattleEditor_StorageSetAtPath(root[array_index],path,value,depth+1);
    }
    else if(is_struct(root)){
        var child=variable_struct_exists(root,key)?variable_struct_get(root,key):{};
        variable_struct_set(root,key,BattleEditor_StorageSetAtPath(child,path,value,depth+1));
    }
    return root;
}

function BattleEditor_StorageRemoveAtPath(root,path,depth=0) {
    if(depth>=array_length(path)) return root;
    var key=path[depth];
    if(depth==array_length(path)-1){
        if(is_array(root)){
            var remove_index=BattleEditor_StorageResolveArrayIndex(root,key);
            if(remove_index>=0) array_delete(root,remove_index,1);
        }
        else if(is_struct(root)&&variable_struct_exists(root,key)) variable_struct_remove(root,key);
        return root;
    }
    if(is_array(root)){
        var child_index=BattleEditor_StorageResolveArrayIndex(root,key);
        if(child_index>=0) root[child_index]=BattleEditor_StorageRemoveAtPath(root[child_index],path,depth+1);
    }
    else if(is_struct(root)&&variable_struct_exists(root,key)) variable_struct_set(root,key,BattleEditor_StorageRemoveAtPath(variable_struct_get(root,key),path,depth+1));
    return root;
}

function BattleEditor_StorageSpliceAtPath(root,path,index,remove_count,items,depth=0) {
    if(depth>=array_length(path)){
        if(!is_array(root)) return root;
        index=clamp(round(real(index)),0,array_length(root));
        remove_count=clamp(round(real(remove_count)),0,array_length(root)-index);
        // Appended recovery records must be safe to replay after an interrupted
        // compact.  Older builds could install the merged project.json but
        // leave project.changes in place; the next launch then inserted the
        // same list/step again.  Later index-based edits split those identical
        // UIDs into several overlapping list shells.  A real duplicate/copy
        // command always allocates a fresh UID, so suppressing an already-live
        // UID for insertion-only splices is lossless and makes this operation
        // idempotent at the point where the corruption used to begin.
        var inserted_items=items;
        if(remove_count==0&&BattleEditor_StorageArrayUsesUniqueUids(root)){
            inserted_items=[];
            for(var candidate_index=0;candidate_index<array_length(items);candidate_index++){
                var candidate=items[candidate_index];
                if(is_struct(candidate)&&struct_exists(candidate,"uid")&&BattleEditor_StorageResolveArrayIndex(root,BattleEditor_StorageUidSelector(candidate.uid))>=0) continue;
                array_push(inserted_items,candidate);
            }
            if(array_length(inserted_items)<=0) return root;
        }
        var spliced=[];
        for(var before_index=0;before_index<index;before_index++) array_push(spliced,root[before_index]);
        for(var item_index=0;item_index<array_length(inserted_items);item_index++) array_push(spliced,BattleEditor_StorageClone(inserted_items[item_index]));
        for(var after_index=index+remove_count;after_index<array_length(root);after_index++) array_push(spliced,root[after_index]);
        return spliced;
    }
    var key=path[depth];
    if(is_array(root)){
        var array_index=BattleEditor_StorageResolveArrayIndex(root,key);
        if(array_index>=0) root[array_index]=BattleEditor_StorageSpliceAtPath(root[array_index],path,index,remove_count,items,depth+1);
    }
    else if(is_struct(root)&&variable_struct_exists(root,key)) variable_struct_set(root,key,BattleEditor_StorageSpliceAtPath(variable_struct_get(root,key),path,index,remove_count,items,depth+1));
    return root;
}

function BattleEditor_StorageApplyOperation(root,operation) {
    if(!is_struct(operation)||!struct_exists(operation,"op")||!struct_exists(operation,"path")||!is_array(operation.path)) return root;
    switch(string(operation.op)){
        case "set":if(struct_exists(operation,"value")) return BattleEditor_StorageSetAtPath(root,operation.path,operation.value);break;
        case "remove":return BattleEditor_StorageRemoveAtPath(root,operation.path);
        case "splice":
            if(struct_exists(operation,"index")&&struct_exists(operation,"remove")&&struct_exists(operation,"items")&&is_array(operation.items)) return BattleEditor_StorageSpliceAtPath(root,operation.path,operation.index,operation.remove,operation.items);
            break;
    }
    return root;
}

function BattleEditor_ProjectForStorage(project,destination_root) {
    var source_root=struct_exists(project,"_storage_root")?string(project._storage_root):"";
    // Clone after sparsifying so packaging never mutates the live project and
    // never serializes the unused 97-field editing superset.
    var stored=json_parse(json_stringify(BattleEditor_ProjectSparseForStorage(BattleEditor_ProjectNormalize(project))));
    var context={source_root:source_root,destination_root:destination_root,project:stored,sources:[],relative:[]};
    return BattleEditor_PackageProjectResourceValue(stored,context);
}

function BattleEditor_SaveProjectFolder(project,folder,make_backup=false) {
    if(!BattleEditor_EnsureDirectory(folder)) return false;
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"textures"));
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"audio"));
    var stored=BattleEditor_ProjectForStorage(project,folder);
    // The editor owns the UI for this data; project.json is a transport and
    // recovery format, not a hand-edited document. Keep named saves compact as
    // well, matching the incremental recovery base instead of spending time
    // and disk space on pretty-print indentation.
    var serialized=json_stringify(stored);
    var project_path=BattleEditor_PathJoin(folder,"project.json");
    var temporary_path=BattleEditor_PathJoin(folder,"project.new.json");
    if(!File_WriteAllText(temporary_path,serialized)) return false;
    var temporary_text=File_ReadAllText(temporary_path);
    if(is_undefined(temporary_text)||string_length(temporary_text)<=0){file_delete(temporary_path);return false;}
    try {json_parse(temporary_text);} catch(e){file_delete(temporary_path);return false;}
    if(make_backup&&file_exists(project_path)){
        var backup_folder=BattleEditor_PathJoin(folder,"_backup");
        BattleEditor_EnsureDirectory(backup_folder);
        if(!BattleEditor_CopyFileOverwrite(project_path,BattleEditor_PathJoin(backup_folder,"project.json"))){file_delete(temporary_path);return false;}
    }
    var write_ok=File_WriteAllText(project_path,temporary_text);
    if(file_exists(temporary_path)) file_delete(temporary_path);
    if(!write_ok) return false;
    var verification=File_ReadAllText(project_path);
    if(is_undefined(verification)||string_length(verification)<=0) return false;
    try {json_parse(verification);} catch(e){return false;}
    return true;
}

function BattleEditor_SaveProject(project,path) {
    var serialized=json_stringify(BattleEditor_ProjectSparseForStorage(BattleEditor_ProjectNormalize(project)));
    if(!File_WriteAllText(path,serialized)) return false;
    var verification=File_ReadAllText(path);
    if(is_undefined(verification)||string_length(verification)<=0) return false;
    try {json_parse(verification);} catch(e){return false;}
    return true;
}

function BattleEditor_LoadProject(path) {
    var text=File_ReadAllText(path);
    if(is_undefined(text)) return undefined;
    try {
        var loaded=BattleEditor_ProjectNormalize(json_parse(text));
        var resource_root=filename_path(path);
        loaded=BattleEditor_ResolveProjectResourceValue(loaded,resource_root);
        loaded._storage_root=resource_root;
        return loaded;
    } catch(e) {
        show_message("攻击文件读取失败：\n"+string(e));
        return undefined;
    }
}

function BattleEditor_SaveSlot(project,slot_name) {
    var clean=BattleEditor_SanitizeSaveName(slot_name);
    if(string_length(clean)<=0) return {ok:false,name:"",path:""};
    var folder=BattleEditor_SaveSlotDirectory(clean);
    var ok=BattleEditor_SaveProjectFolder(project,folder,true);
    if(ok) BattleEditor_SaveActiveSlotName(clean);
    return {ok:ok,name:clean,path:BattleEditor_PathJoin(folder,"project.json")};
}

function BattleEditor_LoadSlot(slot_name) {
    var clean=BattleEditor_SanitizeSaveName(slot_name);
    if(string_length(clean)<=0) return undefined;
    var loaded=BattleEditor_LoadProject(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(clean),"project.json"));
    if(!is_undefined(loaded)) BattleEditor_SaveActiveSlotName(clean);
    return loaded;
}

function BattleEditor_SaveSlotHasBackup(slot_name) {
    return file_exists(BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(slot_name),"_backup/project.json"));
}

function BattleEditor_UndoSlotSave(slot_name) {
    var folder=BattleEditor_SaveSlotDirectory(slot_name);
    var backup=BattleEditor_PathJoin(folder,"_backup/project.json");
    var project_path=BattleEditor_PathJoin(folder,"project.json");
    if(!file_exists(backup)||!BattleEditor_CopyFileOverwrite(backup,project_path)) return false;
    file_delete(backup);
    return file_exists(project_path);
}

function BattleEditor_SaveRuntimeSnapshot(project,snapshot_name="current") {
    if(string(snapshot_name)=="current"&&!BattleEditor_RuntimeSnapshotSessionOwned()) return true;
    // Recovery snapshots stay beside the executable and already reference
    // editor-staged resources. Re-running the distributable save packager here
    // copied every texture/audio file again after ordinary clicks, list edits
    // and node drags. Keep formal slot saves fully packaged, but make the
    // continuously refreshed recovery copy an atomic JSON-only write.
    var folder=BattleEditor_RuntimeSaveDirectory(snapshot_name);
    if(!BattleEditor_EnsureDirectory(folder)) return false;
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"textures"));
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"audio"));
    // Recovery data is portable project data too.  Resolve/copy owned
    // resources into this snapshot once, then store textures/... or audio/...
    // instead of leaking the current computer's C:/... path into project.json.
    var stored=BattleEditor_ProjectForStorage(project,folder);
    var serialized=json_stringify(stored);
    var write_ok=BattleEditor_CommitRuntimeSnapshot(folder,serialized);
    if(write_ok&&string(snapshot_name)=="current") BattleEditor_SaveBattleSource("current");
    return write_ok;
}

/// Fast path for the continuously refreshed recovery copy. The caller already
/// produced this compact JSON to detect whether the project changed, so doing
/// another normalize + pretty stringify + read + parse + second text write is
/// pure duplicate work and causes a visible editor hitch after wheel/key edits.
/// Explicit slot saves keep the slower verified/package path above.
function BattleEditor_SaveRuntimeSnapshotSerialized(serialized,snapshot_name="current") {
    if(string(snapshot_name)=="current"&&!BattleEditor_RuntimeSnapshotSessionOwned()) return true;
    if(!is_string(serialized)||string_length(serialized)<=0) return false;
    var folder=BattleEditor_RuntimeSaveDirectory(snapshot_name);
    if(!BattleEditor_EnsureDirectory(folder)) return false;
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"textures"));
    BattleEditor_EnsureDirectory(BattleEditor_PathJoin(folder,"audio"));
    try {
        var decoded=json_parse(serialized);
        serialized=json_stringify(BattleEditor_ProjectForStorage(decoded,folder));
    } catch(e) {return false;}
    var write_ok=BattleEditor_CommitRuntimeSnapshot(folder,serialized);
    if(write_ok&&string(snapshot_name)=="current") BattleEditor_SaveBattleSource("current");
    return write_ok;
}

/// Compact base+journal as one recoverable transaction. project.precompact.json
/// remains the authoritative old base until both journal files are confirmed
/// gone. A crash at any point therefore loads either old-base+journal or the
/// new compact base, never new-base+journal twice.
function BattleEditor_CommitRuntimeSnapshot(folder,serialized) {
    if(!is_string(serialized)||string_length(serialized)<=0) return false;
    try {json_parse(serialized);} catch(e){return false;}
    var project_path=BattleEditor_PathJoin(folder,"project.json");
    var temporary_path=BattleEditor_PathJoin(folder,"project.new.json");
    var precompact_path=BattleEditor_PathJoin(folder,"project.precompact.json");
    var compact_state_path=BattleEditor_PathJoin(folder,"project.compaction-state");
    var legacy_journal_path=BattleEditor_PathJoin(folder,"project.incremental");
    var changes_path=BattleEditor_PathJoin(folder,"project.changes");
    var old_project_text=file_exists(project_path)?File_ReadAllText(project_path):undefined;

    // GameMaker can keep a save file undeletable for the remainder of a frame.
    // The old implementation therefore could install the merged base while
    // leaving the old journal beside it. Use an overwriteable state marker and
    // truncate journals instead of depending on deletion succeeding.
    if(!is_undefined(old_project_text)){
        if(!File_WriteAllText(precompact_path,old_project_text)) return false;
    }
    if(!File_WriteAllText(compact_state_path,"prepared")) return false;
    if(!File_WriteAllText(temporary_path,serialized)) return false;
    var temporary_text=File_ReadAllText(temporary_path);
    if(is_undefined(temporary_text)||string_length(temporary_text)<=0){if(file_exists(temporary_path)) file_delete(temporary_path);return false;}
    try {json_parse(temporary_text);} catch(e){if(file_exists(temporary_path)) file_delete(temporary_path);return false;}
    var write_ok=File_WriteAllText(project_path,temporary_text);
    if(file_exists(temporary_path)) file_delete(temporary_path);
    if(!write_ok) return false;

    if(file_exists(legacy_journal_path)) File_WriteAllText(legacy_journal_path,"");
    if(file_exists(changes_path)) File_WriteAllText(changes_path,"");
    var journals_cleared=!BattleEditor_RuntimeJournalHasContent(legacy_journal_path)&&!BattleEditor_RuntimeJournalHasContent(changes_path);
    if(!journals_cleared){
        if(!is_undefined(old_project_text)) File_WriteAllText(project_path,old_project_text);
        return false;
    }
    if(!File_WriteAllText(compact_state_path,"committed")) return false;
    if(file_exists(precompact_path)) file_delete(precompact_path);
    return true;
}

function BattleEditor_RuntimeJournalHasContent(path) {
    if(!file_exists(path)) return false;
    var journal_text=File_ReadAllText(path);
    return !is_undefined(journal_text)&&string_length(string_trim(string(journal_text)))>0;
}

/// Compatibility reader for the short-lived text-delta recovery format used
/// by an earlier build. New edits never append this format.
function BattleEditor_ApplyRuntimeSnapshotJournal(serialized,journal_path) {
    if(!file_exists(journal_path)) return serialized;
    var file=file_text_open_read(journal_path);
    if(file==-1) return serialized;
    var result=serialized;
    while(!file_text_eof(file)){
        var line=string_trim(file_text_readln(file));
        if(string_length(line)<=0) continue;
        try {
            var patch=json_parse(line);
            var prefix=clamp(round(real(patch.prefix)),0,string_length(result));
            var removed=clamp(round(real(patch.removed)),0,string_length(result)-prefix);
            var tail_start=prefix+removed+1;
            var tail_length=string_length(result)-prefix-removed;
            result=string_copy(result,1,prefix)+string(patch.inserted)+(tail_length>0?string_copy(result,tail_start,tail_length):"");
        } catch(e) {
            // A crash may leave only the final append incomplete. Earlier
            // records are already valid recovery state, so stop at that tail.
            break;
        }
    }
    file_text_close(file);
    return result;
}

/// The current recovery journal is semantic: changing one numeric field writes
/// one path/value operation, and adding/removing entries writes one array
/// splice.  It never serializes the containing list or project.
function BattleEditor_AppendRuntimeSnapshotChanges(operations,snapshot_name="current") {
    if(!is_array(operations)||array_length(operations)<=0) return true;
    if(string(snapshot_name)=="current"&&!BattleEditor_RuntimeSnapshotSessionOwned()) return true;
    var folder=BattleEditor_RuntimeSaveDirectory(snapshot_name);
    if(!BattleEditor_EnsureDirectory(folder)) return false;
    // Imported resources are staged under current before their field change is
    // journaled.  Journal the owned relative name, never that machine's
    // absolute staging path, so an uncompacted recovery log also moves with
    // the executable.
    var portable_operations=json_parse(json_stringify(operations));
    var package_context={source_root:"",destination_root:folder,project:{},sources:[],relative:[]};
    portable_operations=BattleEditor_PackageProjectResourceValue(portable_operations,package_context);
    var record=json_stringify({version:1,operations:portable_operations});
    return File_AppendLine(BattleEditor_PathJoin(folder,"project.changes"),record);
}

/// Only the newest editor process may mutate the shared recovery journal.
/// Formal named saves are intentionally unaffected.
function BattleEditor_ClaimRuntimeSnapshotSession() {
    var folder=BattleEditor_RuntimeSaveDirectory("current");
    if(!BattleEditor_EnsureDirectory(folder)) return false;
    var token=string(date_current_datetime())+"_"+string(get_timer())+"_"+string(irandom(2147483646));
    global.battle_editor_runtime_snapshot_session=token;
    return File_WriteAllText(BattleEditor_PathJoin(folder,"editor-session.txt"),token);
}

function BattleEditor_RuntimeSnapshotSessionOwned() {
    // Compatibility for callers outside battle_editor. Every current editor
    // claims ownership before its first write.
    if(!variable_global_exists("battle_editor_runtime_snapshot_session")) return true;
    var token=string(global.battle_editor_runtime_snapshot_session);
    if(string_length(token)<=0) return true;
    var session_path=BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory("current"),"editor-session.txt");
    if(!file_exists(session_path)) return false;
    var owner=File_ReadAllText(session_path);
    return !is_undefined(owner)&&string(owner)==token;
}

function BattleEditor_ApplyRuntimeSnapshotChanges(project,changes_path) {
    if(!file_exists(changes_path)) return project;
    var file=file_text_open_read(changes_path);
    if(file==-1) return project;
    var result=project;
    while(!file_text_eof(file)){
        var line=string_trim(file_text_readln(file));
        if(string_length(line)<=0) continue;
        try {
            var record=json_parse(line);
            if(!is_struct(record)||!struct_exists(record,"operations")||!is_array(record.operations)) continue;
            for(var operation_index=0;operation_index<array_length(record.operations);operation_index++) result=BattleEditor_StorageApplyOperation(result,record.operations[operation_index]);
        } catch(e) {
            // Appending is the only non-atomic operation. A crash can truncate
            // the final line; every complete record before it is still valid.
            break;
        }
    }
    file_text_close(file);
    return result;
}

function BattleEditor_LoadRuntimeSnapshot(snapshot_name="current") {
    var folder=BattleEditor_RuntimeSaveDirectory(snapshot_name);
    var project_path=BattleEditor_PathJoin(folder,"project.json");
    var precompact_path=BattleEditor_PathJoin(folder,"project.precompact.json");
    var compact_state_path=BattleEditor_PathJoin(folder,"project.compaction-state");
    var legacy_journal_path=BattleEditor_PathJoin(folder,"project.incremental");
    var changes_path=BattleEditor_PathJoin(folder,"project.changes");
    var has_journal=BattleEditor_RuntimeJournalHasContent(legacy_journal_path)||BattleEditor_RuntimeJournalHasContent(changes_path);
    var compact_state=file_exists(compact_state_path)?string_trim(string(File_ReadAllText(compact_state_path))):"";
    // An interrupted compact may already have installed the new base while the
    // old journal still exists. Replay that journal only on its paired backup.
    var interrupted=compact_state=="prepared"||(compact_state==""&&has_journal&&file_exists(precompact_path));
    var load_path=((interrupted&&has_journal)||!file_exists(project_path))&&file_exists(precompact_path)?precompact_path:project_path;
    var text=File_ReadAllText(load_path);
    if(is_undefined(text)) return undefined;
    text=BattleEditor_ApplyRuntimeSnapshotJournal(text,legacy_journal_path);
    try {
        var decoded=json_parse(text);
        decoded=BattleEditor_ApplyRuntimeSnapshotChanges(decoded,changes_path);
        var loaded=BattleEditor_ProjectNormalize(decoded);
        loaded=BattleEditor_ResolveProjectResourceValue(loaded,folder);
        loaded._storage_root=folder;
        return loaded;
    } catch(e) {
        show_message("攻击恢复副本读取失败：\n"+string(e));
        return undefined;
    }
}

function BattleEditor_RuntimeSnapshotExists(snapshot_name="current") {
    return file_exists(BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory(snapshot_name),"project.json"));
}

function BattleEditor_CaptureUndoLoad(project) {
    return BattleEditor_SaveRuntimeSnapshot(project,"undo_load");
}

function BattleEditor_ConsumeUndoLoad() {
    var path=BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory("undo_load"),"project.json");
    var loaded=BattleEditor_LoadProject(path);
    if(!is_undefined(loaded)&&file_exists(path)) file_delete(path);
    return loaded;
}

function BattleEditor_DefaultProjectPath() {
    var battle_source=BattleEditor_LoadBattleSource();
    if(string_pos("slot:",battle_source)==1){
        var selected_slot=BattleEditor_SanitizeSaveName(string_delete(battle_source,1,5));
        if(BattleEditor_SaveSlotExists(selected_slot)) return BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(selected_slot),"project.json");
    }
    if(battle_source=="current") return BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory("current"),"project.json");
    var active=BattleEditor_LoadActiveSlotName();
    if(active!="") return BattleEditor_PathJoin(BattleEditor_SaveSlotDirectory(active),"project.json");
    return BattleEditor_PathJoin(BattleEditor_RuntimeSaveDirectory("current"),"project.json");
}

/// Resolve the project selected for both editor startup and normal Start.
/// There is deliberately only one source priority here: Settings may select a
/// named slot explicitly; otherwise both entries use the continuously updated
/// editor snapshot (base JSON plus every complete semantic change record).
/// The active named slot is only a portable fallback when that source is gone.
function BattleEditor_LoadStartupProject(prefer_live_editor=false) {
    var loaded=undefined;
    var battle_source=BattleEditor_LoadBattleSource();
    // A named slot/current setting chooses what a fresh process opens. Once an
    // editor project exists in this process, that in-memory project stays
    // authoritative across battle entry, death and return-to-menu. Formal Save
    // is for persistence after the application itself closes, not for moving
    // between rooms inside one running application.
    if(prefer_live_editor
    &&variable_global_exists("battle_editor_project_live_from_editor")&&global.battle_editor_project_live_from_editor
    &&variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)){
        loaded=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
    }
    if(is_undefined(loaded)&&string_pos("slot:",battle_source)==1){
        var selected_slot=BattleEditor_SanitizeSaveName(string_delete(battle_source,1,5));
        if(selected_slot!="") loaded=BattleEditor_LoadSlot(selected_slot);
    }else if(is_undefined(loaded)){
        if(is_undefined(loaded)) loaded=BattleEditor_LoadRuntimeSnapshot("current");
    }
    if(is_undefined(loaded)){
        var active=BattleEditor_LoadActiveSlotName();
        if(active!="") loaded=BattleEditor_LoadSlot(active);
    }
    if(is_undefined(loaded)&&battle_source!="current") loaded=BattleEditor_LoadRuntimeSnapshot("current");
    return loaded;
}

function BattleEditor_LoadEditorStartupProject() {
    // Re-entering the editor after a battle/game-over is still the same app
    // session and must not discard unsaved in-memory edits.
    var loaded=BattleEditor_LoadStartupProject(true);
    return is_undefined(loaded)?BattleEditor_NewProject():loaded;
}

function BattleEditor_AdoptLoadedProject(controller,loaded) {
    if(!instance_exists(controller)||is_undefined(loaded)) return false;
    controller.project=BattleEditor_ProjectNormalize(loaded);
    controller.turn_presentation_signature="";
    controller.developer_turn=controller.project.settings.developer_turn;
    controller.timeline_effective_duration_cache=BattleEditor_EffectiveDuration(controller.project,controller.developer_turn);
    controller.timeline_duration_cache=max(60,controller.timeline_effective_duration_cache);
    controller.timeline_duration_cache_time=current_time;
    controller.timeline_duration_dirty=false;
    controller.main_board_preview=controller.project.initialization.board;
    global.battle_editor_project_runtime=controller.project;
    controller.developer_turn_dropdown=false;
    controller.scene_objects_visible=controller.project.settings.editor_show_objects;
    controller.new_object_preview_uids=[];
    controller.selected=-1;controller.selected_frame=-2;controller.selected_item=-1;controller.selected_animation_frame=-1;
    controller.board_edit_session=false;controller.board_palette=false;
    controller.script_selected_list=-1;controller.script_selected_step=-1;controller.script_selected_variable=-1;
    controller.context_open=false;controller.script_dropdown="";
    BattleEditor_ApplyInitialization(controller.project);
    BattleEditor_RestoreAuthoringBoard(controller);
    controller.runtime_snapshot_state=BattleEditor_StorageClone(BattleEditor_ProjectSparseForStorage(controller.project));
    controller.runtime_snapshot_pending=false;
    controller.runtime_snapshot_patch_count=0;
    return true;
}

/// Normal game entry uses exactly the same source resolver as editor startup.
/// A live editor project wins over its not-yet-flushed recovery checkpoint,
/// while fresh launches read that checkpoint including project.changes.
function BattleEditor_LoadSavedProjectForBattle() {
    var loaded=BattleEditor_LoadStartupProject(true);
    if(is_undefined(loaded)){
        global.battle_editor_project_runtime=BattleEditor_NewProject();
        return false;
    }
    global.battle_editor_project_runtime=loaded;
    // Do not consume this after one battle. Death, escape and another Start all
    // remain inside the same process and must continue using the same project.
    global.battle_editor_project_live_from_editor=true;
    return true;
}

function BattleEditorItemType(item_data) : ItemTypeSimple(item_data.name, item_data.eat_text) constructor {
    _item_uid = item_data.uid;
    _heal_amount = item_data.heal;
    _eat_text = item_data.eat_text;
    _voice_id = item_data.voice_id;

    function OnUse(inventory, index) {
        Dialog_Add("{voice "+string(_voice_id)+"}"+TextTyper_CompileMarkup(_eat_text).text);
        Dialog_Start();
        // Items share the same max-HP-repair rule as survival-mode healing:
        // when green damage lowered the current maximum, one quarter of the
        // item's power is spent restoring that maximum before ordinary HP.
        Player_HealWithMaxHpRecovery(_heal_amount,0.25,1);
        audio_play_sound(snd_item_heal, 0, false);
        BattleEditor_NotifyItemUsed(_item_uid);
        inventory.Remove(index);
    }
}

function BattleEditor_ItemTriggerCaption(project,item_uid) {
    if(!is_struct(project)||!struct_exists(project,"initialization")) return "选择库存物品";
    var items=project.initialization.items;
    for(var i=0;i<array_length(items);i++){
        if(struct_exists(items[i],"uid")&&string(items[i].uid)==string(item_uid)) return string(i+1)+". "+items[i].name;
    }
    return "选择库存物品";
}

function BattleEditor_RuntimeInitialization() {
    if(variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)){
        var runtime_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
        return runtime_project.initialization;
    }
    return undefined;
}

function BattleEditor_RuntimeMercyValue(field_name,fallback) {
    var runtime_init=BattleEditor_RuntimeInitialization();
    if(is_undefined(runtime_init)||!struct_exists(runtime_init,field_name)) return fallback;
    return variable_struct_get(runtime_init,field_name);
}

function BattleEditor_SoulModeName(mode) {
    var soul_names=["红魂","蓝魂","绿魂","紫魂","黄魂","橙魂","青魂"];
    return soul_names[clamp(round(real(mode)),0,6)];
}

function BattleEditor_SoulModeObject(mode) {
    switch(clamp(round(real(mode)),0,6)){
        case 1:return battle_soul_blue;
        case 2:return battle_soul_green;
        case 3:return battle_soul_purple;
        case 4:return battle_soul_yellow;
        case 5:return battle_soul_orange;
        case 6:return battle_soul_aqua;
    }
    return battle_soul_red;
}

function BattleEditor_SoulModeFromName(soul_name) {
    switch(string_lower(string(soul_name))){
        case "battle_soul_blue":return 1;
        case "battle_soul_green":return 2;
        case "battle_soul_purple":return 3;
        case "battle_soul_yellow":return 4;
        case "battle_soul_orange":return 5;
        case "battle_soul_aqua":return 6;
    }
    return 0;
}

function BattleEditor_SetSoulMode(mode) {
    var soul_object=BattleEditor_SoulModeObject(mode);
    var current_soul=instance_find(battle_soul,0);
    if(instance_exists(current_soul)&&current_soul.object_index==soul_object) return true;
    return Battle_SetSoul(soul_object);
}

function BattleEditor_BlueDirectionName(direction_choice) {
    var direction_names=["上","下","左","右"];
    return direction_names[clamp(round(real(direction_choice)),0,3)];
}

function BattleEditor_BlueDirectionValue(direction_choice) {
    switch(clamp(round(real(direction_choice)),0,3)){
        case 0:return DIR.UP;
        case 1:return DIR.DOWN;
        case 2:return DIR.LEFT;
        case 3:return DIR.RIGHT;
    }
    return DIR.DOWN;
}

/// Set blue gravity independently from the optional throw. This mirrors the
/// distinction between Battle_SetSoul(blue) and BlueSoulControl(dir): a plain
/// direction edit reorients gravity, while the checkbox requests the impact.
function BattleEditor_SetBlueSoulDirection(direction_choice,apply_throw=false) {
    var blue_direction=BattleEditor_BlueDirectionValue(direction_choice);
    if(apply_throw) BlueSoulControl(blue_direction,10);
    else{
        if(!instance_exists(battle_soul_blue)) BattleEditor_SetSoulMode(1);
        var plain_soul=instance_find(battle_soul_blue,0);
        if(!instance_exists(plain_soul)) return false;
        plain_soul.dir=blue_direction;
        plain_soul.move=0;
        plain_soul.impact=0;
        plain_soul.jump_state=2;
        plain_soul.on_block=0;
        plain_soul.on_board=0;
        plain_soul.on_platform=0;
    }
    var blue_soul=instance_find(battle_soul_blue,0);
    if(!instance_exists(blue_soul)) return false;
    blue_soul.dir=blue_direction;
    // A scrubbed target frame has delta 0, so expose the selected orientation
    // immediately instead of waiting for the next ordinary blue-soul Step.
    switch(blue_direction){
        case DIR.RIGHT:blue_soul.image_angle=90;break;
        case DIR.UP:blue_soul.image_angle=180;break;
        case DIR.LEFT:blue_soul.image_angle=-90;break;
        default:blue_soul.image_angle=0;break;
    }
    return true;
}

function BattleEditor_GetVisualEnemyInstance(enemy_index) {
    if(!instance_exists(battle)||enemy_index<0||enemy_index>=BATTLE_EDITOR_ENEMY_LIMIT) return noone;
    if(enemy_index<BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT) return Battle_GetEnemy(enemy_index);
    if(!variable_instance_exists(battle,"_battle_editor_extra_enemies")) return noone;
    var extra_index=enemy_index-BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT;
    if(extra_index<0||extra_index>=array_length(battle._battle_editor_extra_enemies)) return noone;
    var visual_enemy=battle._battle_editor_extra_enemies[extra_index];
    return instance_exists(visual_enemy)?visual_enemy:noone;
}

function BattleEditor_ApplyInitialization(project) {
    project = BattleEditor_ProjectNormalize(project);
    if(!variable_global_exists("battle_editor_enemy_visual_revision")) global.battle_editor_enemy_visual_revision=0;
    global.battle_editor_enemy_visual_revision+=1;
    var init = project.initialization;
    Player_SetName(init.player_name);
    Player_SetLv(max(1,round(init.lv)));
    Player_SetNaturalHpMax(max(1,init.natural_max_hp));
    Player_SetHpMax(max(1, init.max_hp));
    Player_SetHp(clamp(init.hp, 1, init.max_hp));
    Player_SetKr(0);
    Player_ClearPurpleOccupancy();
    Player_SetAtk(init.atk);
    Player_SetDef(init.def);
    if(instance_exists(battle)){
        battle._menu_mercy_flee_enabled=init.mercy_flee_enabled;
        Battle_ShieldConfigure(max(0,init.shield_natural_max),battle._shield_drain_per_second,init.shield_hud_mode,init.shield_enabled,battle._shield_recover_per_second,battle._shield_recover_delay_seconds);
        Battle_ShieldSetMax(clamp(init.shield_max,0,init.shield_natural_max));
        Battle_ShieldSet(clamp(init.shield,0,init.shield_max));
    }
    if(instance_exists(battle_board)){
        battle_board.color_frame=init.board_color_default;
        if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed) battle_board.mainboard.color_frame=init.board_color_default;
    }

    var inventory = Item_GetInventoryItems();
    var item_types = Item_GetTypeManager();
    // The stock inventory is capped at eight slots. The editor may author
    // more than eight entries, so grow the live inventory before rebuilding
    // it; otherwise every newly-added item after the defaults is silently
    // rejected and the in-game item menu appears not to refresh.
    inventory.SetCapacity(ITEM_INVENTORY_CAPACITY);
    inventory.Clear();
    var raw_ids = [];
    var live_item_count=min(ITEM_INVENTORY_CAPACITY,array_length(init.items));
    for (var i = 0; i < live_item_count; i++) {
        var item_id = "battle_editor_item_" + string(i);
        var item_type = new BattleEditorItemType(init.items[i]);
        if (item_types.Contains(item_id)) struct_set(item_types.contents, item_id, item_type);
        else item_types.Register(item_id, item_type);
        inventory.Add(item_id);
        array_push(raw_ids, item_id);
    }
    Player_SetInvItem(raw_ids);
    global.battle_editor_project_runtime = project;
    // The stock battle core owns three targetable enemy slots and its target
    // menu has no scrolling. Keep those three fully native. Enemy 4..15 are
    // real battle_enemy_test instances for display and script control, but are
    // intentionally absent from FIGHT/ACT rather than pretending to be usable.
    if(instance_exists(battle)){
        if(!variable_global_exists("battle_editor_syncing_enemies")) global.battle_editor_syncing_enemies=false;
        if(!global.battle_editor_syncing_enemies){
            global.battle_editor_syncing_enemies=true;
            var desired_enemy_count=min(BATTLE_EDITOR_ENEMY_LIMIT,array_length(init.enemies));
            var desired_targetable_count=min(BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT,desired_enemy_count);
            for(var enemy_slot=0;enemy_slot<BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT;enemy_slot++){
                var live_enemy=Battle_GetEnemy(enemy_slot);
                if(enemy_slot<desired_targetable_count){
                    if(!instance_exists(live_enemy)||live_enemy.object_index!=battle_enemy_test){
                        Battle_SetEnemy(battle_enemy_test,enemy_slot);
                        live_enemy=Battle_GetEnemy(enemy_slot);
                    }
                    if(instance_exists(live_enemy)){
                        var enemy_init=init.enemies[enemy_slot];
                        live_enemy._enemy_slot=enemy_slot;
                        live_enemy._battle_editor_visual_only=false;
                        live_enemy.visible=true;
                        live_enemy.x=enemy_init.x;
                        live_enemy.y=enemy_init.y;
                        // Do not leave an existing slot bound to the enemy data
                        // it loaded before this edit. Duplication changes the
                        // project revision and must refresh every slot now,
                        // even while the initialization panel owns input.
                        if(variable_instance_exists(live_enemy,"_reload_editor_enemies")&&is_callable(live_enemy._reload_editor_enemies)) live_enemy._reload_editor_enemies(true);
                        Battle_SetEnemyName(enemy_slot,enemy_init.name);
                        Battle_SetEnemyCenterPos(enemy_slot,enemy_init.x,enemy_init.y);
                        Battle_SetEnemyActionNumber(enemy_slot,min(6,array_length(enemy_init.actions)));
                        for(var action_index=0;action_index<6;action_index++){
                            Battle_SetEnemyActionName(enemy_slot,action_index,action_index<array_length(enemy_init.actions)?enemy_init.actions[action_index].name:"");
                        }
                    }
                }else if(instance_exists(live_enemy)) Battle_RemoveEnemy(enemy_slot);
            }
            if(!variable_instance_exists(battle,"_battle_editor_extra_enemies")) battle._battle_editor_extra_enemies=[];
            for(var visual_slot=BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT;visual_slot<BATTLE_EDITOR_ENEMY_LIMIT;visual_slot++){
                var visual_index=visual_slot-BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT;
                var visual_enemy=visual_index<array_length(battle._battle_editor_extra_enemies)?battle._battle_editor_extra_enemies[visual_index]:noone;
                if(visual_slot<desired_enemy_count){
                    if(!instance_exists(visual_enemy)||visual_enemy.object_index!=battle_enemy_test){
                        visual_enemy=instance_create_depth(init.enemies[visual_slot].x,init.enemies[visual_slot].y,DEPTH_BATTLE.ENEMY,battle_enemy_test);
                        visual_enemy._enemy_slot=visual_slot;
                        visual_enemy._battle_editor_visual_only=true;
                        battle._battle_editor_extra_enemies[visual_index]=visual_enemy;
                        with(visual_enemy) event_user(BATTLE_ENEMY_EVENT.INIT);
                    }
                    if(instance_exists(visual_enemy)){
                        visual_enemy._enemy_slot=visual_slot;
                        visual_enemy._battle_editor_visual_only=true;
                        visual_enemy.visible=true;
                        visual_enemy.x=init.enemies[visual_slot].x;
                        visual_enemy.y=init.enemies[visual_slot].y;
                        if(variable_instance_exists(visual_enemy,"_reload_editor_enemies")&&is_callable(visual_enemy._reload_editor_enemies)) visual_enemy._reload_editor_enemies(true);
                    }
                }else{
                    if(instance_exists(visual_enemy)) instance_destroy(visual_enemy);
                    if(visual_index<array_length(battle._battle_editor_extra_enemies)) battle._battle_editor_extra_enemies[visual_index]=noone;
                }
            }
            global.battle_editor_syncing_enemies=false;
        }
    }
    if(instance_exists(battle)){
        var natural_turn=max(1,Battle_GetTurnNumber()+1);
        BattleEditor_ApplyTurnPresentation(project,BattleEditor_ResolveMonsterTurn(project,natural_turn));
    }
    BattleEditor_ApplyLayout(init);
    if(instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.MENU){
        var live_menu=Battle_GetMenu();
        if(live_menu==BATTLE_MENU.FIGHT_TARGET||live_menu==BATTLE_MENU.ACT_TARGET||live_menu==BATTLE_MENU.ITEM||live_menu==BATTLE_MENU.MERCY) Battle_SetMenu(live_menu);
    }
}

function BattleEditor_IsEditorBattle() {
    return instance_exists(battle_editor)||room==room_battle_editor;
}

/// Shared death entry so every soul colour and the KR drain path preserve the
/// editor return target in exactly the same way.
function BattleEditor_StartGameOver(soul_instance) {
    if(!instance_exists(soul_instance)) return false;
    var z=Storage_SetTempFlag(FLAG_TEMP_GAMEOVER_SOUL_X,soul_instance.x-camera.x);
    z.Set(FLAG_TEMP_GAMEOVER_SOUL_Y,soul_instance.y-camera.y);
    z.Set(FLAG_TEMP_GAMEOVER_SOUL_COLOR,soul_instance.image_blend);
    global.battle_editor_revive_pending=BattleEditor_IsEditorBattle();
    room_goto(room_gameover);
    return true;
}

function BattleEditor_ReturnFromGameOver() {
    var return_to_editor=variable_global_exists("battle_editor_revive_pending")&&global.battle_editor_revive_pending;
    global.battle_editor_revive_pending=false;
    if(return_to_editor){
        if(variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)){
            var project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
            var init=project.initialization;
            Player_SetNaturalHpMax(max(1,init.natural_max_hp));
            Player_SetHpMax(max(1,init.max_hp));
            Player_SetHp(clamp(init.hp,1,init.max_hp));
            Player_SetKr(0);
        }else{
            Player_SetHp(max(1,Player_GetHpMax()));
            Player_SetKr(0);
        }
        room_goto(room_battle_editor);
    }else{
        room_goto(room_battle);
    }
    return return_to_editor;
}

function BattleEditor_ApplyLayout(init) {
    if(instance_exists(battle_ui)){
        battle_ui.x=init.hud_x;
        battle_ui.y=init.hud_y;
        battle_ui.show_hp_label=init.hud_show_hp_label;
        battle_ui.show_bar=init.hud_show_bar;
        battle_ui.show_kr=init.hud_show_kr;
        battle_ui.show_numbers=init.hud_show_numbers;
        battle_ui.show_shield=init.hud_show_shield;
        battle_ui.show_overhead=init.hud_show_overhead;
    }
    if(instance_exists(battle_enemy_test)){
        var layout_enemy_count=min(BATTLE_EDITOR_ENEMY_LIMIT,array_length(init.enemies));
        for(var layout_enemy_slot=0;layout_enemy_slot<layout_enemy_count;layout_enemy_slot++){
            var layout_enemy=BattleEditor_GetVisualEnemyInstance(layout_enemy_slot);
            if(!instance_exists(layout_enemy)||layout_enemy.object_index!=battle_enemy_test) continue;
            var layout_enemy_data=init.enemies[layout_enemy_slot];
            layout_enemy.x=layout_enemy_data.x;
            layout_enemy.y=layout_enemy_data.y;
            if(layout_enemy_slot<BATTLE_EDITOR_TARGETABLE_ENEMY_LIMIT){
                Battle_SetEnemyCenterPos(layout_enemy_slot,layout_enemy_data.x,layout_enemy_data.y);
                Battle_SetEnemyName(layout_enemy_slot,layout_enemy_data.name);
            }
        }
    }
    // Enemy names are cached into the currently visible target menu text.
    // Rebuild that text immediately when Initialization changes instead of
    // waiting for the next monster turn/menu transition.
    if(instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.MENU){
        var layout_menu=Battle_GetMenu();
        if(layout_menu==BATTLE_MENU.FIGHT_TARGET||layout_menu==BATTLE_MENU.ACT_TARGET||layout_menu==BATTLE_MENU.ACT_ACTION){
            Battle_SetMenu(layout_menu,false);
        }
    }
}

function BattleEditor_ForceDestroyBoard(board) {
    if(!is_struct(board)||board._destroyed) return false;
    if(variable_struct_exists(board,"editor_force_destroy")) board.editor_force_destroy=true;
    board.destroy();
    return true;
}

/// A 90-degree multiple is only a different local-coordinate description of
/// the same axis-aligned rectangle.  Before the mandatory player-turn return,
/// rewrite that description to angle 0 and rotate the four half-extents with
/// it.  The screen image does not move, while the reset animation no longer
/// performs a pointless reverse spin.  Non-rectangular and arbitrary-angle
/// boards are intentionally left untouched.
function BattleEditor_CanonicalizeRectBoardQuarterTurn() {
    if(!instance_exists(battle_board)||!is_struct(battle_board.mainboard)||battle_board.mainboard._destroyed) return false;
    var board=battle_board.mainboard;
    var is_rect=variable_struct_exists(board,"up")&&variable_struct_exists(board,"down")&&variable_struct_exists(board,"left")&&variable_struct_exists(board,"right")
        &&(!variable_struct_exists(board,"editor_shape")||board.editor_shape=="rect");
    if(!is_rect||battle_board.custom_mainboard) return false;
    var source_angle=real(battle_board.angle);
    var quarter=round(source_angle/90);
    if(abs(angle_difference(source_angle,quarter*90))>0.001) return false;
    quarter=((quarter mod 4)+4) mod 4;
    var old_up=battle_board.up,old_down=battle_board.down,old_left=battle_board.left,old_right=battle_board.right;
    // RotateAround uses GameMaker screen coordinates (positive angles rotate
    // local +X upward).  Therefore 90 and 270 are the reverse of the usual
    // Cartesian mapping; keeping these cases explicit prevents asymmetric
    // rectangles from visibly flipping during the player-turn reset.
    if(quarter==1){
        battle_board.up=old_right;battle_board.down=old_left;battle_board.left=old_up;battle_board.right=old_down;
    }else if(quarter==2){
        battle_board.up=old_down;battle_board.down=old_up;battle_board.left=old_right;battle_board.right=old_left;
    }else if(quarter==3){
        battle_board.up=old_left;battle_board.down=old_right;battle_board.left=old_down;battle_board.right=old_up;
    }
    Anim_Destroy(battle_board,"angle");
    battle_board.angle=0;
    board.x=battle_board.x;board.y=battle_board.y;
    board.up=battle_board.up;board.down=battle_board.down;board.left=battle_board.left;board.right=battle_board.right;
    board.angle=0;
    board.update();
    return true;
}

/// Normal monster-turn exit morphs any custom main-board contour back into the
/// player-menu rectangle. This controller lives in the existing board update
/// list, because RuntimeStop correctly tears down attack patterns before the
/// BOARD_RESETTING transition begins.
function BattleEditor_StartPlayerBoardReturnMorph(target_up,target_down,target_left,target_right,duration,tween=ANIM_TWEEN.LINEAR,ease=ANIM_EASE.OUT) {
    if(!instance_exists(battle_board)||!is_struct(battle_board.mainboard)||battle_board.mainboard._destroyed) return false;
    var source_board=battle_board.mainboard;
    var source_shape=variable_struct_exists(source_board,"editor_shape")?string(source_board.editor_shape):(variable_struct_exists(source_board,"radius_x")?"circle":(variable_struct_exists(source_board,"rect")&&source_board.rect?"rect":"polygon"));
    if(source_shape=="rect"&&!battle_board.custom_mainboard) return false;

    var source_points=BattleEditor_RuntimeResampleBoardContour(BattleEditor_RuntimeBoardSourceContour(source_board),32);
    var target_points=BattleEditor_RuntimeResampleBoardContour([[-target_left,-target_up],[target_right,-target_up],[target_right,target_down],[-target_left,target_down]],32);
    var morph_board=source_board;
    if(variable_struct_exists(source_board,"radius_x")){
        morph_board=Battle_CreateBoardPoints(source_board.x,source_board.y,source_board.board_depth,source_board.angle,source_board.rotate,source_board.cover);
        morph_board.color_frame=source_board.color_frame;
        BattleEditor_ForceDestroyBoard(source_board);
        battle_board.mainboard=morph_board;
    }else{
        if(variable_struct_exists(morph_board,"up")) variable_struct_remove(morph_board,"up");
        if(variable_struct_exists(morph_board,"down")) variable_struct_remove(morph_board,"down");
        if(variable_struct_exists(morph_board,"left")) variable_struct_remove(morph_board,"left");
        if(variable_struct_exists(morph_board,"right")) variable_struct_remove(morph_board,"right");
        morph_board.rect=0;
    }
    morph_board.listVertex=BattleEditor_RuntimeCopyBoardPoints(source_points);
    morph_board.editor_shape=source_shape;
    morph_board.editor_morphing=true;
    BattleEditor_RuntimeUpdateConvexMorphGeometry(morph_board);
    battle_board.custom_mainboard=true;

    var return_controller={
        _destroyed:false,
        _battle_editor_player_board_return:true,
        target:morph_board,
        age:0,
        duration:max(1,duration),
        start_points:source_points,
        target_points:target_points,
        tween:tween,
        ease:ease,
        update:function(){
            if(_destroyed) return;
            if(!is_struct(target)||target._destroyed){_destroyed=true;__Battle_RemoveBoardController(self);return;}
            age+=global.delta_time_factor;
            var complete=age>=duration;
            var amount=complete?1:Anim_GetValue(tween,ease,clamp(age/duration,0,1));
            target.x=battle_board.x;target.y=battle_board.y;target.angle=battle_board.angle;
            for(var point_index=0;point_index<array_length(start_points);point_index++){
                target.listVertex[point_index][0]=lerp(start_points[point_index][0],target_points[point_index][0],amount);
                target.listVertex[point_index][1]=lerp(start_points[point_index][1],target_points[point_index][1],amount);
            }
            BattleEditor_RuntimeUpdateConvexMorphGeometry(target);
            if(complete){
                target.editor_shape="rect";
                target.editor_morphing=false;
                _destroyed=true;
                __Battle_RemoveBoardController(self);
            }
        }
    };
    array_push(global.boards_controller_array,return_controller);
    return true;
}

function BattleEditor_DestroyPreviewFrames(controller) {
    for(var i=0;i<array_length(controller.preview_frames);i++){
        var frame=controller.preview_frames[i];
        BattleEditor_ForceDestroyBoard(frame);
    }
    controller.preview_frames=[];
}

function BattleEditor_ShrinkDestroyBoard(board,duration=12) {
    if(!is_struct(board)||board._destroyed) return false;
    var shrink={
        _destroyed:false,
        target:board,
        age:0,
        duration:max(1,duration),
        rect:struct_exists(board,"rect")&&board.rect,
        ellipse:struct_exists(board,"radius_x"),
        up:struct_exists(board,"up")?board.up:0,
        down:struct_exists(board,"down")?board.down:0,
        left:struct_exists(board,"left")?board.left:0,
        right:struct_exists(board,"right")?board.right:0,
        radius_x:struct_exists(board,"radius_x")?board.radius_x:0,
        radius_y:struct_exists(board,"radius_y")?board.radius_y:0,
        vertices:struct_exists(board,"listVertex")?json_parse(json_stringify(board.listVertex)):[],
        update:function(){
            if(_destroyed) return;
            if(!is_struct(target)||target._destroyed){_destroyed=true;__Battle_RemoveBoardController(self);return;}
            age+=global.delta_time_factor;
            var scale=max(0,1-age/duration);
            if(rect){target.up=up*scale;target.down=down*scale;target.left=left*scale;target.right=right*scale;}
            else if(ellipse){target.radius_x=radius_x*scale;target.radius_y=radius_y*scale;}
            else{
                target.listVertex=[];
                for(var i=0;i<array_length(vertices);i++) array_push(target.listVertex,[vertices[i][0]*scale,vertices[i][1]*scale]);
                target.updateDivide();
            }
            if(scale<=0){BattleEditor_ForceDestroyBoard(target);_destroyed=true;__Battle_RemoveBoardController(self);}
        }
    };
    array_push(global.boards_controller_array,shrink);
    return true;
}

function BattleEditor_DestroyPreviewFramesAnimated(controller,duration=12) {
    for(var i=0;i<array_length(controller.preview_frames);i++) BattleEditor_ShrinkDestroyBoard(controller.preview_frames[i],duration);
    controller.preview_frames=[];
    controller.board_preview_active=false;
}

/// Return the real soul to the currently selected player-menu button.
/// Timeline controls are allowed to animate system objects, so merely deleting
/// preview objects is insufficient: a surviving x/y track can keep the soul
/// inside the monster board even after every later seek. Resolve the actual
/// button instance so authored button movement remains respected.
function BattleEditor_RestoreSoulToMenuButton() {
    if(!instance_exists(battle_soul)) return false;
    var soul=instance_find(battle_soul,0);
    Anim_Destroy(soul,"x");
    Anim_Destroy(soul,"y");
    Anim_Destroy(soul,"image_angle");
    var choice=instance_exists(battle)?clamp(round(Battle_GetMenuChoiceButton()),0,3):0;
    var button_types=[battle_button_fight,battle_button_act,battle_button_item,battle_button_mercy];
    var button=instance_find(button_types[choice],0);
    if(instance_exists(button)){
        soul.x=button.x+16;
        soul.y=button.y+22;
    }
    soul.image_angle=0;
    return true;
}

function BattleEditor_ResolvePlayerBoardProject(controller=noone) {
    if(instance_exists(controller)&&variable_instance_exists(controller,"project")&&is_struct(controller.project)) return controller.project;
    if(variable_global_exists("battle_editor_project_runtime")&&is_struct(global.battle_editor_project_runtime)) return global.battle_editor_project_runtime;
    return undefined;
}

/// Authoritative player-turn board reset. Unlike the ordinary wrapper-field
/// animation this also replaces an ellipse/polygon/morph mainboard by a real
/// rectangle, so no custom shape can leak into the next menu.
function BattleEditor_ForceRestorePlayerBoard(controller=noone) {
    // Menu/dialogue time always uses the red soul. Non-red initialization is
    // applied only when the real monster turn begins at timeline 0:00.
    if(instance_exists(battle_soul)){
        BattleEditor_SetSoulMode(0);
        BattleEditor_RestoreSoulToMenuButton();
    }
    if(!instance_exists(battle_board)) return false;
    var restore_project=BattleEditor_ResolvePlayerBoardProject(controller);
    Anim_Destroy(battle_board);
    var player_board_data=(!is_undefined(restore_project)&&struct_exists(restore_project,"initialization")&&struct_exists(restore_project.initialization,"player_board"))?restore_project.initialization.player_board:{x:BATTLE_BOARD.X,y:BATTLE_BOARD.Y,up:BATTLE_BOARD.UP,down:BATTLE_BOARD.DOWN,left:BATTLE_BOARD.LEFT,right:BATTLE_BOARD.RIGHT,angle:0};
    var old_mainboard=battle_board.mainboard;
    if(is_struct(old_mainboard)&&!old_mainboard._destroyed) Anim_Destroy(old_mainboard);
    var mainboard_is_rect=is_struct(old_mainboard)&&!old_mainboard._destroyed
        &&variable_struct_exists(old_mainboard,"up")&&variable_struct_exists(old_mainboard,"down")
        &&variable_struct_exists(old_mainboard,"left")&&variable_struct_exists(old_mainboard,"right")
        &&(!variable_struct_exists(old_mainboard,"editor_shape")||old_mainboard.editor_shape=="rect");
    if(!mainboard_is_rect||battle_board.custom_mainboard){
        BattleEditor_ForceDestroyBoard(battle_board.mainboard);
        battle_board.mainboard=Battle_CreateBoardRect(player_board_data.x,player_board_data.y,player_board_data.up,player_board_data.down,player_board_data.left,player_board_data.right,0,player_board_data.angle);
    }
    battle_board.x=player_board_data.x;
    battle_board.y=player_board_data.y;
    battle_board.up=player_board_data.up;
    battle_board.down=player_board_data.down;
    battle_board.left=player_board_data.left;
    battle_board.right=player_board_data.right;
    battle_board.angle=player_board_data.angle;
    // battle_board's own Step normally mirrors these wrapper fields into a
    // rectangular mainboard. Do it now as well so an editor action cannot
    // leave one rendered frame of the former monster-turn square behind.
    if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed){
        battle_board.mainboard.x=player_board_data.x;
        battle_board.mainboard.y=player_board_data.y;
        battle_board.mainboard.up=player_board_data.up;
        battle_board.mainboard.down=player_board_data.down;
        battle_board.mainboard.left=player_board_data.left;
        battle_board.mainboard.right=player_board_data.right;
        battle_board.mainboard.angle=player_board_data.angle;
        battle_board.mainboard.editor_shape="rect";
        battle_board.mainboard.editor_morphing=false;
        battle_board.mainboard.update();
    }
    var restored_color=(!is_undefined(restore_project)&&struct_exists(restore_project.initialization,"board_color_default"))?restore_project.initialization.board_color_default:c_white;
    battle_board.color_frame=restored_color;
    if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed) battle_board.mainboard.color_frame=restored_color;
    battle_board.custom_mainboard=false;
    return true;
}

function BattleEditor_RestorePlayerBoard(controller) {
    BattleEditor_DestroyPreviewFrames(controller);
    var restored=BattleEditor_ForceRestorePlayerBoard(controller);
    controller.board_preview_active=false;
    return restored;
}

/// Editor-only emergency exit from a monster-turn preview. This is deliberately
/// a state transition rather than merely deleting the timeline objects: doing
/// the latter during enemy speech left TURN_PREPARATION waiting on dialogue
/// state that could no longer finish, which looked like a complete input lock.
function BattleEditor_ForceExitMonsterTurn(controller) {
    if(!BattleEditor_IsEditorBattle()||!instance_exists(battle)) return false;
    var current_state=Battle_GetState();
    if(current_state!=BATTLE_STATE.TURN_PREPARATION&&current_state!=BATTLE_STATE.IN_TURN) return false;

    if(instance_exists(battle_dialog_enemy)) with(battle_dialog_enemy) instance_destroy();
    BattleEditor_RuntimeStop(controller);

    // If speech was interrupted, first complete preparation so the normal
    // TURN_START/TURN_END callbacks stay paired and the turn counter advances
    // exactly as it does for a preview stopped after the attack has begun.
    if(Battle_GetState()==BATTLE_STATE.TURN_PREPARATION) Battle_EndTurnPreparation();
    if(Battle_GetState()==BATTLE_STATE.IN_TURN) Battle_EndTurn();

    // BOARD_RESETTING normally waits for animation completion. A force-exit is
    // expected to return control immediately, so finish that boundary now.
    Battle_SetState(BATTLE_STATE.MENU);
    Battle_SetMenu(BATTLE_MENU.BUTTON,false);
    BattleEditor_ForceRestorePlayerBoard(controller);
    return true;
}

/// Update only one auxiliary ADD/SUBTRACT preview after an editor drag. A
/// vertex handle moves every Step; rebuilding/copying every other frame in the
/// project here wastes most of the CPU time even though their data is static.
/// Shape changes still fall back to the full synchronizer so old saves and the
/// first rect-to-polygon edit keep the exact existing migration behaviour.
function BattleEditor_SyncSingleAuxiliaryBoardPreview(controller,frame_index) {
    if(!instance_exists(controller)||!instance_exists(battle_board)) return false;
    if(frame_index<0||frame_index>=array_length(controller.project.initialization.frames)) return false;
    if(frame_index>=array_length(controller.preview_frames)) return false;
    var frame=controller.project.initialization.frames[frame_index];
    var preview=controller.preview_frames[frame_index];
    if(!is_struct(preview)||preview._destroyed||!struct_exists(preview,"editor_shape")||preview.editor_shape!=frame.shape) return false;

    preview.x=frame.x;preview.y=frame.y;
    preview.angle=frame.angle;preview.rotate=frame.rotate;
    preview.board_depth=frame.board_depth;preview.cover=frame.cover;
    preview.color_frame=frame.color_frame;
    preview.editor_name=frame.name;preview.control_id=frame.control_id;preview.editor_control_uid=struct_exists(frame,"control_uid")?frame.control_uid:-1;
    if(struct_exists(frame,"vertex_uids")){
        preview.editor_vertex_uids=[];
        for(var uid_index=0;uid_index<array_length(frame.vertex_uids);uid_index++) array_push(preview.editor_vertex_uids,frame.vertex_uids[uid_index]);
    }
    if(frame.shape=="rect"){
        preview.up=frame.up;preview.down=frame.down;preview.left=frame.left;preview.right=frame.right;
    }else if(frame.shape=="circle"){
        preview.radius_x=frame.radius_x;preview.radius_y=frame.radius_y;
    }else if(frame.shape=="polygon"){
        preview.listVertex=[];
        for(var vertex_index=0;vertex_index<array_length(frame.vertices);vertex_index++) array_push(preview.listVertex,[frame.vertices[vertex_index][0],frame.vertices[vertex_index][1]]);
        preview.updateDivide();
    }else if(frame.shape=="triangle"){
        preview.listVertex=[[0,-frame.triangle_size],[frame.triangle_size*0.866,frame.triangle_size*0.5],[-frame.triangle_size*0.866,frame.triangle_size*0.5]];
        preview.updateDivide();
    }
    controller.board_preview_active=true;
    return true;
}

function BattleEditor_SyncBoardPreview(controller, rebuild = false, preserve_live_main = undefined) {
    if(!instance_exists(battle_board)) return false;
    // Adding or editing an auxiliary ADD/SUBTRACT frame in the ordinary
    // player-turn editor must not replace the live wide menu board with the
    // authored monster-turn main board.  Main-board editing and playback do
    // need the authored main board.  Infer that distinction for old call
    // sites, while allowing runtime callers to override it explicitly.
    if(is_undefined(preserve_live_main)){
        preserve_live_main=controller.object_index==battle_editor
            &&!controller.playing
            &&!controller.timeline_half_play
            &&(!variable_instance_exists(controller,"selected_frame")||controller.selected_frame!=-1);
    }
    // Only one editor/runtime controller may own the board composition.  This
    // also removes orphan previews left by an interrupted previous controller,
    // which otherwise appear as an unselectable second frame.
    if(variable_global_exists("boards_array")){
        for(var orphan_index=array_length(global.boards_array)-1;orphan_index>=0;orphan_index--){
            var orphan=global.boards_array[orphan_index];
            if(!is_struct(orphan)||orphan._destroyed||!struct_exists(orphan,"editor_preview_board")) continue;
            var owned_by_current=struct_exists(orphan,"editor_preview_owner")&&orphan.editor_preview_owner==controller;
            var referenced=orphan==battle_board.mainboard;
            if(!referenced) for(var owned_index=0;owned_index<array_length(controller.preview_frames);owned_index++) if(controller.preview_frames[owned_index]==orphan){referenced=true;break;}
            if(!referenced) BattleEditor_ForceDestroyBoard(orphan);
        }
    }
    var board=variable_instance_exists(controller,"main_board_preview")&&is_struct(controller.main_board_preview)?controller.main_board_preview:controller.project.initialization.board;
    if(!preserve_live_main){
        battle_board.x=board.x;
        battle_board.y=board.y;
        battle_board.up=board.up;
        battle_board.down=board.down;
        battle_board.left=board.left;
        battle_board.right=board.right;
        battle_board.angle=board.angle;
        if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed) battle_board.mainboard.color_frame=board.color_frame;
        var main_needs_custom=board.shape!="rect";
        var main_shape_matches=is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed&&struct_exists(battle_board.mainboard,"editor_shape")&&battle_board.mainboard.editor_shape==board.shape;
        if(main_needs_custom&&(!main_shape_matches||rebuild)){
            if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed) BattleEditor_ForceDestroyBoard(battle_board.mainboard);
            battle_board.mainboard=BattleEditor_CreateFramePreview(board,controller);
        }else if(!main_needs_custom&&(battle_board.custom_mainboard||!is_struct(battle_board.mainboard)||battle_board.mainboard._destroyed)){
            if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed) BattleEditor_ForceDestroyBoard(battle_board.mainboard);
            battle_board.mainboard=Battle_CreateBoardRect(board.x,board.y,board.up,board.down,board.left,board.right,board.board_depth,board.angle,board.rotate,0);
            battle_board.mainboard.editor_shape="rect";
        }
        battle_board.custom_mainboard=main_needs_custom;
        if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed){
            battle_board.mainboard.editor_uid=board.uid;
            battle_board.mainboard.editor_name=board.name;
            battle_board.mainboard.control_id=board.control_id;
            battle_board.mainboard.editor_control_uid=struct_exists(board,"control_uid")?board.control_uid:-1;
            battle_board.mainboard.editor_target_type="board";
            battle_board.mainboard.editor_preview_board=true;
            battle_board.mainboard.editor_preview_owner=controller;
        }
        if(main_needs_custom){
            var main_preview=battle_board.mainboard;
            main_preview.x=board.x;main_preview.y=board.y;main_preview.angle=board.angle;main_preview.rotate=board.rotate;main_preview.board_depth=board.board_depth;
            main_preview.color_frame=board.color_frame;
            if(board.shape=="polygon"){
                main_preview.listVertex=[];
                for(var main_vertex=0;main_vertex<array_length(board.vertices);main_vertex++) array_push(main_preview.listVertex,[board.vertices[main_vertex][0],board.vertices[main_vertex][1]]);
                main_preview.updateDivide();
            }else if(board.shape=="circle"){main_preview.radius_x=board.radius_x;main_preview.radius_y=board.radius_y;}
            else if(board.shape=="triangle"){
                main_preview.listVertex=[[0,-board.triangle_size],[board.triangle_size*0.866,board.triangle_size*0.5],[-board.triangle_size*0.866,board.triangle_size*0.5]];
                main_preview.updateDivide();
            }
        }
    }
    controller.board_preview_active=true;

    var frame_data=controller.project.initialization.frames;
    var preview_mismatch=rebuild||array_length(controller.preview_frames)!=array_length(frame_data);
    if(!preview_mismatch){
        for(var shape_index=0;shape_index<array_length(frame_data);shape_index++){
            var shape_preview=controller.preview_frames[shape_index];
            if(!is_struct(shape_preview)||shape_preview._destroyed||!struct_exists(shape_preview,"editor_shape")||shape_preview.editor_shape!=frame_data[shape_index].shape){preview_mismatch=true;break;}
        }
    }
    if(preview_mismatch){
        BattleEditor_DestroyPreviewFrames(controller);
        for(var i=0;i<array_length(frame_data);i++){
            var f=frame_data[i];
            var preview=BattleEditor_CreateFramePreview(f,controller);
            array_push(controller.preview_frames,preview);
        }
    }else{
        for(var i=0;i<array_length(frame_data);i++){
            var f=frame_data[i];
            var preview=controller.preview_frames[i];
            preview.x=f.x; preview.y=f.y;
            preview.editor_vertex_uids=struct_exists(f,"vertex_uids")?json_parse(json_stringify(f.vertex_uids)):[];
            preview.angle=f.angle; preview.rotate=f.rotate;
            preview.board_depth=f.board_depth; preview.cover=f.cover;
            preview.color_frame=f.color_frame;
            if(f.shape=="rect"){
                preview.up=f.up;preview.down=f.down;preview.left=f.left;preview.right=f.right;
            }else if(f.shape=="circle"){
                preview.radius_x=f.radius_x;preview.radius_y=f.radius_y;
            }else if(f.shape=="polygon"){
                preview.listVertex=[];
                for(var vertex_index=0;vertex_index<array_length(f.vertices);vertex_index++) array_push(preview.listVertex,[f.vertices[vertex_index][0],f.vertices[vertex_index][1]]);
                preview.updateDivide();
            }else if(f.shape=="triangle"){
                preview.listVertex=[[0,-f.triangle_size],[f.triangle_size*0.866,f.triangle_size*0.5],[-f.triangle_size*0.866,f.triangle_size*0.5]];
                preview.updateDivide();
            }
        }
    }
    return true;
}

/// Restore the wide player/menu board, then attach only the authored auxiliary
/// ADD/SUBTRACT frames.  This keeps connected clipping borders visible in the
/// ordinary editor without ever replacing the live main board by the square
/// monster-turn initialization board.
function BattleEditor_RestoreAuthoringBoard(controller) {
    var restored=BattleEditor_RestorePlayerBoard(controller);
    if(!restored||!instance_exists(controller)||controller.object_index!=battle_editor) return restored;
    if(!variable_instance_exists(controller,"project")||!is_struct(controller.project)) return restored;
    if(!struct_exists(controller.project.initialization,"frames")||array_length(controller.project.initialization.frames)<=0) return restored;
    BattleEditor_SyncBoardPreview(controller,true,true);
    return true;
}

function BattleEditor_RuntimeEnsureController(controller) {
    if(!instance_exists(controller)) return false;
    if(!variable_instance_exists(controller,"project")){
        controller.project=variable_global_exists("battle_editor_project_runtime")
            ? global.battle_editor_project_runtime
            : BattleEditor_NewProject();
    }
    // Projects are normalized at their real boundaries (new/load/runtime
    // attach). RuntimeStep calls this helper for every simulated frame, so a
    // full schema migration here made one timeline drag normalize the entire
    // save hundreds of times. Retain only a cheap malformed/legacy guard.
    var runtime_project_needs_normalize=!is_struct(controller.project)
        ||!struct_exists(controller.project,"version")
        ||real(controller.project.version)<32
        ||!struct_exists(controller.project,"initialization")
        ||!struct_exists(controller.project,"events")
        ||!is_array(controller.project.events)
        ||!struct_exists(controller.project,"script_lists")
        ||!is_array(controller.project.script_lists);
    if(runtime_project_needs_normalize) controller.project=BattleEditor_ProjectNormalize(controller.project);
    if(!variable_instance_exists(controller,"runtime_instances")) controller.runtime_instances=[];
    if(!variable_instance_exists(controller,"preview_frames")) controller.preview_frames=[];
    if(!variable_instance_exists(controller,"fired")) controller.fired=[];
    if(!variable_instance_exists(controller,"script_runtime_states")) controller.script_runtime_states=[];
    if(!variable_instance_exists(controller,"script_scheduled_sounds")) controller.script_scheduled_sounds=[];
    if(!variable_instance_exists(controller,"script_timer_fired")) controller.script_timer_fired=[];
    if(!variable_instance_exists(controller,"script_vertex_animations")) controller.script_vertex_animations=[];
    if(!variable_instance_exists(controller,"script_patterns")) controller.script_patterns=[];
    if(!variable_instance_exists(controller,"runtime_variables")) controller.runtime_variables=BattleEditor_ExpressionVariables(controller.project);
    if(!variable_instance_exists(controller,"script_monster_turn")) controller.script_monster_turn=instance_exists(battle)?max(1,Battle_GetTurnNumber()):1;
    if(!variable_instance_exists(controller,"keep_board_on_stop")) controller.keep_board_on_stop=false;
    if(!variable_instance_exists(controller,"preserve_paused_board")) controller.preserve_paused_board=false;
    if(!variable_instance_exists(controller,"playing")) controller.playing=false;
    if(!variable_instance_exists(controller,"playhead")) controller.playhead=0;
    if(!variable_instance_exists(controller,"timeline_seek_active")) controller.timeline_seek_active=false;
    if(!variable_instance_exists(controller,"timeline_seek_target")) controller.timeline_seek_target=0;
    if(!variable_instance_exists(controller,"timeline_half_play")) controller.timeline_half_play=false;
    if(!variable_instance_exists(controller,"timeline_full_play")) controller.timeline_full_play=false;
    if(!variable_instance_exists(controller,"new_object_preview_uids")){
        controller.new_object_preview_uids=[];
        if(variable_instance_exists(controller,"new_object_preview_uid")&&controller.new_object_preview_uid>=0) array_push(controller.new_object_preview_uids,controller.new_object_preview_uid);
    }
    if(!variable_instance_exists(controller,"runtime_anim_baseline")) controller.runtime_anim_baseline=[];
    if(!variable_instance_exists(controller,"runtime_animator_baseline")) controller.runtime_animator_baseline=[];
    if(!variable_instance_exists(controller,"runtime_animation_scope_active")) controller.runtime_animation_scope_active=false;
    if(!variable_instance_exists(controller,"runtime_effective_duration")) controller.runtime_effective_duration=0;
    if(!variable_instance_exists(controller,"runtime_seek_animation_scope_active")) controller.runtime_seek_animation_scope_active=false;
    if(!variable_instance_exists(controller,"runtime_seek_kept_anims")) controller.runtime_seek_kept_anims=[];
    if(!variable_instance_exists(controller,"runtime_seek_kept_animators")) controller.runtime_seek_kept_animators=[];
    if(!variable_instance_exists(controller,"runtime_seek_suspended_anims")) controller.runtime_seek_suspended_anims=[];
    if(!variable_instance_exists(controller,"runtime_seek_suspended_animators")) controller.runtime_seek_suspended_animators=[];
    if(!variable_instance_exists(controller,"timeline_seek_complete")) controller.timeline_seek_complete=true;
    return true;
}

function BattleEditor_RuntimeNormalDelta() {
    return GAME_FPS/max(1,game_get_speed(gamespeed_fps));
}

function BattleEditor_RuntimeReferenceInArray(values,target) {
    for(var value_index=0;value_index<array_length(values);value_index++) if(values[value_index]==target) return true;
    return false;
}

function BattleEditor_RuntimeCaptureAnimationBaseline(controller) {
    controller.runtime_anim_baseline=[];
    controller.runtime_animator_baseline=[];
    for(var anim_index=0;anim_index<array_length(global._anim_data);anim_index++) array_push(controller.runtime_anim_baseline,global._anim_data[anim_index]);
    for(var animator_index=0;animator_index<array_length(global._animators);animator_index++) array_push(controller.runtime_animator_baseline,global._animators[animator_index]);
    controller.runtime_animation_scope_active=true;
}

/// Detach animations which existed before this preview once for the complete
/// seek. The previous implementation split and rejoined both global arrays on
/// every replayed frame; dragging near the end of a timeline therefore paid
/// the same increasingly expensive ownership scan hundreds of times.
function BattleEditor_RuntimeSeekAnimationScopeBegin(controller) {
    if(!BattleEditor_RuntimeEnsureController(controller)) return false;
    if(controller.runtime_seek_animation_scope_active) return true;
    var kept_anims=[],runtime_anims=[];
    var kept_animators=[],runtime_animators=[];
    for(var anim_index=0;anim_index<array_length(global._anim_data);anim_index++){
        var anim_item=global._anim_data[anim_index];
        if(BattleEditor_RuntimeReferenceInArray(controller.runtime_anim_baseline,anim_item)) array_push(kept_anims,anim_item);
        else array_push(runtime_anims,anim_item);
    }
    for(var animator_index=0;animator_index<array_length(global._animators);animator_index++){
        var animator_item=global._animators[animator_index];
        if(BattleEditor_RuntimeReferenceInArray(controller.runtime_animator_baseline,animator_item)) array_push(kept_animators,animator_item);
        else array_push(runtime_animators,animator_item);
    }
    controller.runtime_seek_kept_anims=kept_anims;
    controller.runtime_seek_kept_animators=kept_animators;
    controller.runtime_seek_animation_scope_active=true;
    global._anim_data=runtime_anims;
    global._animators=runtime_animators;
    return true;
}

function BattleEditor_RuntimeSeekAnimationScopeEnd(controller) {
    if(!instance_exists(controller)||!variable_instance_exists(controller,"runtime_seek_animation_scope_active")||!controller.runtime_seek_animation_scope_active) return;
    var runtime_anims=global._anim_data;
    var runtime_animators=global._animators;
    global._anim_data=controller.runtime_seek_kept_anims;
    global._animators=controller.runtime_seek_kept_animators;
    for(var anim_index=0;anim_index<array_length(runtime_anims);anim_index++) array_push(global._anim_data,runtime_anims[anim_index]);
    for(var animator_index=0;animator_index<array_length(runtime_animators);animator_index++) array_push(global._animators,runtime_animators[animator_index]);
    controller.runtime_seek_kept_anims=[];
    controller.runtime_seek_kept_animators=[];
    controller.runtime_seek_animation_scope_active=false;
}

/// A frozen timeline frame must not leave replay-owned Anim tracks in the
/// world's live arrays: world.Step would advance them while the author is only
/// moving the mouse. Keep the tracks themselves, however, so a later forward
/// scrub can continue from this exact state instead of replaying frame zero.
function BattleEditor_RuntimeSuspendSeekAnimations(controller) {
    if(!instance_exists(controller)||!controller.runtime_seek_animation_scope_active) return false;
    controller.runtime_seek_suspended_anims=global._anim_data;
    controller.runtime_seek_suspended_animators=global._animators;
    global._anim_data=controller.runtime_seek_kept_anims;
    global._animators=controller.runtime_seek_kept_animators;
    controller.runtime_seek_kept_anims=[];
    controller.runtime_seek_kept_animators=[];
    controller.runtime_seek_animation_scope_active=false;
    return true;
}

function BattleEditor_RuntimeResumeSeekAnimations(controller) {
    if(!instance_exists(controller)) return false;
    var suspended_anims=controller.runtime_seek_suspended_anims;
    var suspended_animators=controller.runtime_seek_suspended_animators;
    controller.runtime_seek_suspended_anims=[];
    controller.runtime_seek_suspended_animators=[];
    BattleEditor_RuntimeSeekAnimationScopeBegin(controller);
    for(var anim_index=0;anim_index<array_length(suspended_anims);anim_index++) array_push(global._anim_data,suspended_anims[anim_index]);
    for(var animator_index=0;animator_index<array_length(suspended_animators);animator_index++) array_push(global._animators,suspended_animators[animator_index]);
    return true;
}

/// During a seek, advance only animation tracks created by this replay. Aging
/// pre-existing menu/enemy animations by two minutes would corrupt the editor
/// merely because its timeline was inspected.
function BattleEditor_RuntimeSeekAnimStep(controller) {
    // RuntimeBeginSeek keeps the non-preview tracks detached for the whole
    // synchronous replay, so the hot per-frame path is now only Anim_Step().
    if(controller.runtime_seek_animation_scope_active){
        Anim_Step();
        return;
    }
    var kept_anims=[],runtime_anims=[];
    var kept_animators=[],runtime_animators=[];
    for(var anim_index=0;anim_index<array_length(global._anim_data);anim_index++){
        var anim_item=global._anim_data[anim_index];
        if(BattleEditor_RuntimeReferenceInArray(controller.runtime_anim_baseline,anim_item)) array_push(kept_anims,anim_item);
        else array_push(runtime_anims,anim_item);
    }
    for(var animator_index=0;animator_index<array_length(global._animators);animator_index++){
        var animator_item=global._animators[animator_index];
        if(BattleEditor_RuntimeReferenceInArray(controller.runtime_animator_baseline,animator_item)) array_push(kept_animators,animator_item);
        else array_push(runtime_animators,animator_item);
    }
    global._anim_data=runtime_anims;
    global._animators=runtime_animators;
    Anim_Step();
    runtime_anims=global._anim_data;
    runtime_animators=global._animators;
    global._anim_data=kept_anims;
    global._animators=kept_animators;
    for(var remaining_anim=0;remaining_anim<array_length(runtime_anims);remaining_anim++) array_push(global._anim_data,runtime_anims[remaining_anim]);
    for(var remaining_animator=0;remaining_animator<array_length(runtime_animators);remaining_animator++) array_push(global._animators,runtime_animators[remaining_animator]);
}

function BattleEditor_RuntimeDiscardReplayAnimations(controller) {
    if(!controller.runtime_animation_scope_active) return;
    for(var anim_index=array_length(global._anim_data)-1;anim_index>=0;anim_index--){
        if(!BattleEditor_RuntimeReferenceInArray(controller.runtime_anim_baseline,global._anim_data[anim_index])) array_delete(global._anim_data,anim_index,1);
    }
    for(var animator_index=array_length(global._animators)-1;animator_index>=0;animator_index--){
        if(!BattleEditor_RuntimeReferenceInArray(controller.runtime_animator_baseline,global._animators[animator_index])) array_delete(global._animators,animator_index,1);
    }
    controller.runtime_animation_scope_active=false;
}

/// Keep the exact replayed frame alive while returning control to the editor.
/// Anim tracks use the shared zero delta; built-in movement, sprite playback
/// and alarms are also stopped because GameMaker advances those independently.
function BattleEditor_RuntimeFreezeAtCursor(controller,target_time) {
    if(!BattleEditor_RuntimeEnsureController(controller)) return false;
    controller.playhead=max(0,target_time);
    controller.cursor_time=controller.playhead;
    controller.playing=false;
    controller.timeline_seek_active=false;
    controller.timeline_full_play=false;
    controller.timeline_half_play=true;
    controller.preserve_paused_board=true;
    // Leave every target at the value calculated for this cursor. Replay Anim
    // tracks and built-in instance clocks are suspended rather than discarded,
    // allowing a forward scrub to advance only the newly requested interval.
    BattleEditor_RuntimeSuspendSeekAnimations(controller);
    global.delta_time_factor=0;
    for(var runtime_index=0;runtime_index<array_length(controller.runtime_instances);runtime_index++){
        var runtime_inst=controller.runtime_instances[runtime_index];
        if(!instance_exists(runtime_inst)) continue;
        if(!variable_instance_exists(runtime_inst,"_battle_editor_runtime_frozen")||!runtime_inst._battle_editor_runtime_frozen){
            runtime_inst._battle_editor_seek_hspeed=runtime_inst.hspeed;
            runtime_inst._battle_editor_seek_vspeed=runtime_inst.vspeed;
            runtime_inst._battle_editor_seek_image_speed=runtime_inst.image_speed;
            runtime_inst._battle_editor_seek_visible=runtime_inst.visible;
            runtime_inst._battle_editor_seek_alarms=array_create(12,-1);
            for(var saved_alarm_index=0;saved_alarm_index<12;saved_alarm_index++) runtime_inst._battle_editor_seek_alarms[saved_alarm_index]=runtime_inst.alarm[saved_alarm_index];
        }
        with(runtime_inst){
            _battle_editor_runtime_frozen=true;
            speed=0;
            hspeed=0;
            vspeed=0;
            image_speed=0;
            for(var alarm_index=0;alarm_index<12;alarm_index++) alarm[alarm_index]=-1;
        }
        // A newly authored object has one editor-owned, draggable rendering
        // for the remainder of this seek session. The replay also spawned an
        // instance with the same editor UID at the cursor; hide that one so it
        // cannot remain behind as a second, immovable copy while the author
        // drags the real project data. Starting/seeking again clears the
        // exception and rebuilds the ordinary runtime representation.
        if(variable_instance_exists(runtime_inst,"editor_uid")
        &&BattleEditor_UidArrayContains(controller.new_object_preview_uids,runtime_inst.editor_uid)) runtime_inst.visible=false;
    }
    return true;
}

function BattleEditor_RuntimeResumeFrozenInstances(controller) {
    if(!instance_exists(controller)) return false;
    for(var runtime_index=0;runtime_index<array_length(controller.runtime_instances);runtime_index++){
        var runtime_inst=controller.runtime_instances[runtime_index];
        if(!instance_exists(runtime_inst)||!variable_instance_exists(runtime_inst,"_battle_editor_runtime_frozen")||!runtime_inst._battle_editor_runtime_frozen) continue;
        runtime_inst._battle_editor_runtime_frozen=false;
        if(variable_instance_exists(runtime_inst,"_battle_editor_seek_hspeed")) runtime_inst.hspeed=runtime_inst._battle_editor_seek_hspeed;
        if(variable_instance_exists(runtime_inst,"_battle_editor_seek_vspeed")) runtime_inst.vspeed=runtime_inst._battle_editor_seek_vspeed;
        if(variable_instance_exists(runtime_inst,"_battle_editor_seek_image_speed")) runtime_inst.image_speed=runtime_inst._battle_editor_seek_image_speed;
        if(variable_instance_exists(runtime_inst,"_battle_editor_seek_visible")) runtime_inst.visible=runtime_inst._battle_editor_seek_visible;
        if(variable_instance_exists(runtime_inst,"_battle_editor_seek_alarms")&&is_array(runtime_inst._battle_editor_seek_alarms)){
            for(var restored_alarm_index=0;restored_alarm_index<min(12,array_length(runtime_inst._battle_editor_seek_alarms));restored_alarm_index++) runtime_inst.alarm[restored_alarm_index]=runtime_inst._battle_editor_seek_alarms[restored_alarm_index];
        }
    }
    return true;
}

/// Advance one hidden simulation slice. Only instances which already existed
/// at the beginning of the slice receive an object step/alarm decrement; newly
/// scheduled objects begin on the next slice, matching an ordinary frame.
function BattleEditor_RuntimeSeekTick(controller,seek_delta) {
    var existing_instances=[];
    for(var existing_index=0;existing_index<array_length(controller.runtime_instances);existing_index++){
        var existing_inst=controller.runtime_instances[existing_index];
        if(instance_exists(existing_inst)) array_push(existing_instances,existing_inst);
    }

    global.delta_time_factor=seek_delta;
    // Runtime board/object controls use the engine's real Anim_Create system.
    // Advance it inside this non-rendered calculation so a moving subtract
    // frame is evaluated at the destination time instead of animating later.
    // Animations advance before this tick's scheduler, matching world.Step:
    // an event created at time T begins animating on the following tick.
    BattleEditor_RuntimeSeekAnimStep(controller);
    BattleEditor_RuntimeStep(controller);

    for(var runtime_index=0;runtime_index<array_length(existing_instances);runtime_index++){
        var runtime_inst=existing_instances[runtime_index];
        if(!instance_exists(runtime_inst)) continue;
        with(runtime_inst) event_perform(ev_step,ev_step_begin);
        if(instance_exists(runtime_inst)) with(runtime_inst) event_perform(ev_step,ev_step_normal);
        if(instance_exists(runtime_inst)) with(runtime_inst) event_perform(ev_step,ev_step_end);
        if(!instance_exists(runtime_inst)) continue;

        // Reproduce GameMaker's built-in movement and alarm clock, neither of
        // which is advanced by event_perform() itself.
        runtime_inst.x+=runtime_inst.hspeed;
        runtime_inst.y+=runtime_inst.vspeed;
        for(var alarm_index=0;alarm_index<12;alarm_index++){
            if(!instance_exists(runtime_inst)) break;
            if(runtime_inst.alarm[alarm_index]>=0){
                runtime_inst.alarm[alarm_index]-=1;
                if(runtime_inst.alarm[alarm_index]<=0){
                    runtime_inst.alarm[alarm_index]=-1;
                    with(runtime_inst) event_perform(ev_alarm,alarm_index);
                }
            }
        }

        if(instance_exists(runtime_inst)&&runtime_inst.image_speed!=0&&runtime_inst.sprite_index>=0){
            var frame_count=max(1,sprite_get_number(runtime_inst.sprite_index));
            runtime_inst.image_index+=runtime_inst.image_speed*max(1,seek_delta/max(0.001,BattleEditor_RuntimeNormalDelta()));
            if(runtime_inst.image_index>=frame_count){
                with(runtime_inst) event_perform(ev_other,7);
                if(instance_exists(runtime_inst)) runtime_inst.image_index=runtime_inst.image_index mod frame_count;
            }
        }
    }
    return true;
}

/// A timeline scrub is a real state calculation, not a visible fast-forward.
/// Reset the next monster turn, execute every due event/script/shortcut in
/// order inside this one editor frame, then expose only the frozen result.
function BattleEditor_RuntimeBeginSeek(controller,target_time,preserve_new_object_preview=false,force_rebuild=false) {
    var duration_was_dirty=!variable_instance_exists(controller,"timeline_duration_dirty")||controller.timeline_duration_dirty;
    if(!variable_instance_exists(controller,"timeline_duration_cache")
    ||!variable_instance_exists(controller,"timeline_duration_dirty")
    ||controller.timeline_duration_dirty) BattleEditor_RefreshDurationCache(controller);
    var seek_duration=variable_instance_exists(controller,"timeline_duration_cache")
        ?controller.timeline_duration_cache:BattleEditor_TimelineDuration(controller.project);
    var seek_target=clamp(real(target_time),0,seek_duration);
    // Every object created or pasted during one frozen-timeline editing
    // session remains the draggable authoring copy. Rebuilding or scrubbing
    // that same session must not replace the previous UID with only the most
    // recent object; only RuntimeStop (explicit timeline exit) clears it.
    var preserve_preview_session=preserve_new_object_preview
        ||(variable_instance_exists(controller,"timeline_half_play")&&controller.timeline_half_play)
        ||(variable_instance_exists(controller,"timeline_seek_active")&&controller.timeline_seek_active);
    var preserved_preview_uids=preserve_preview_session&&variable_instance_exists(controller,"new_object_preview_uids")
        ?json_parse(json_stringify(controller.new_object_preview_uids)):[];
    global.battle_editor_seek_audio_silent=true;
    global.battle_editor_seek_audio_exact_birth=false;
    var continue_forward=!force_rebuild&&!preserve_new_object_preview&&!duration_was_dirty
        &&variable_instance_exists(controller,"timeline_half_play")&&controller.timeline_half_play
        &&variable_instance_exists(controller,"playhead")&&seek_target>=controller.playhead;
    if(continue_forward){
        BattleEditor_RuntimeResumeFrozenInstances(controller);
        BattleEditor_RuntimeResumeSeekAnimations(controller);
    }else{
        if(!BattleEditor_RuntimeStart(controller)){
            global.battle_editor_seek_audio_silent=false;
            return false;
        }
        BattleEditor_RuntimeSeekAnimationScopeBegin(controller);
    }
    if(preserve_preview_session) controller.new_object_preview_uids=preserved_preview_uids;
    controller.timeline_seek_target=seek_target;
    controller.timeline_seek_active=true;
    controller.timeline_half_play=false;
    controller.timeline_full_play=false;
    controller.playing=true;
    if(seek_target<=0){
        BattleEditor_RuntimeSeekTick(controller,0);
    }else{
        var seek_iterations=0;
        // Seeking is atomic from the renderer's point of view. Never yield a
        // partially replayed frame to Draw: a cursor click must expose only
        // the exact destination state, not a visible fast-forward from zero.
        var seek_iteration_limit=max(1,ceil(seek_target-controller.playhead)+2);
        while(controller.playhead<seek_target&&seek_iterations<seek_iteration_limit){
            var seek_previous_playhead=controller.playhead;
            // One logical frame keeps event starts, waits and partial tween
            // progress aligned with the authored 60-FPS timeline. The final
            // slice may be fractional, so the frozen pose is the exact cursor.
            BattleEditor_RuntimeSeekTick(controller,min(1,seek_target-controller.playhead));
            seek_iterations+=1;
            if(controller.playhead<=seek_previous_playhead+0.000001) break;
        }
    }
    controller.timeline_seek_complete=controller.playhead>=seek_target-0.0001;
    // A True Knife placed exactly at the cursor has age zero. Prime only its
    // zero-delta presentation step so the cut sprite exists in the frozen
    // target frame without advancing the knife lifecycle past its start.
    global.delta_time_factor=0;
    if(controller.timeline_seek_complete){
        var prime_count=array_length(controller.runtime_instances);
        for(var prime_index=0;prime_index<prime_count;prime_index++){
            var prime_inst=controller.runtime_instances[prime_index];
            if(instance_exists(prime_inst)&&prime_inst.object_index==battle_bullet_knife_wave&&prime_inst.wave_kind==1&&!prime_inst.knife_spawned){
                var prime_is_exact=variable_instance_exists(prime_inst,"editor_birth_time")&&abs(prime_inst.editor_birth_time-seek_target)<=0.0001;
                global.battle_editor_seek_audio_exact_birth=prime_is_exact;
                with(prime_inst) event_perform(ev_step,ev_step_normal);
                global.battle_editor_seek_audio_exact_birth=false;
            }
        }
    }
    BattleEditor_RuntimeFreezeAtCursor(controller,controller.playhead);
    global.battle_editor_seek_audio_silent=false;
    global.battle_editor_seek_audio_exact_birth=false;
    return true;
}

function BattleEditor_RuntimeStop(controller) {
    if(!BattleEditor_RuntimeEnsureController(controller)) return false;
    // A frozen scrub uses zero delta. Restore ordinary editor timing before
    // destroying or restarting its live objects.
    global.delta_time_factor=BattleEditor_RuntimeNormalDelta();
    controller.timeline_seek_active=false;
    controller.timeline_half_play=false;
    controller.timeline_full_play=false;
    controller.new_object_preview_uids=[];
    if(variable_instance_exists(controller,"timeline_live_seek_pending")) controller.timeline_live_seek_pending=false;
    // Restore detached non-preview animations before normal cleanup. This is
    // also the recovery path if a seek is interrupted by an editor exit.
    BattleEditor_RuntimeSeekAnimationScopeEnd(controller);
    controller.runtime_seek_suspended_anims=[];
    controller.runtime_seek_suspended_animators=[];
    BattleEditor_RuntimeDiscardReplayAnimations(controller);
    for (var i = 0; i < array_length(controller.runtime_instances); i++) {
        var inst = controller.runtime_instances[i];
        if (instance_exists(inst)) {
            Anim_Destroy(inst);
            instance_destroy(inst);
        }
    }
    controller.runtime_instances = [];
    // The real-turn controller has no editor preview that needs these shared
    // dynamic sprites after teardown. Release each style once here instead of
    // making every pinwheel member load/merge and own six identical PNGs.
    if(controller.object_index==turn_test){
        if(variable_instance_exists(controller,"gb_style_sprite_cache")){
            BattleEditor_FreeGBStyleSpriteCache(controller.gb_style_sprite_cache);
            controller.gb_style_sprite_cache=[];
        }
        if(variable_instance_exists(controller,"gb_style_beam_sprite_cache")){
            BattleEditor_FreeGBStyleSpriteCache(controller.gb_style_beam_sprite_cache);
            controller.gb_style_beam_sprite_cache=[];
        }
    }
    controller.playing = false;
    controller.playhead = 0;
    controller.fired = array_create(array_length(controller.project.events), false);
    controller.script_runtime_states=[];
    controller.script_scheduled_sounds=[];
    controller.script_timer_fired=[];
    controller.script_vertex_animations=[];
    controller.script_patterns=[];
    controller.runtime_variables=BattleEditor_ExpressionVariables(controller.project);
    BattleEditor_RuntimeRestoreScreen(controller);
    if(variable_global_exists("battle_editor_runtime_controller")&&global.battle_editor_runtime_controller==controller) global.battle_editor_runtime_controller=noone;
    // Pausing/finishing playback must not replace the editor's board with the
    // player-menu rectangle. The same MAIN/ADD/SUBTRACT data stays rendered.
    if(instance_exists(battle_board)){
        if(struct_exists(controller,"keep_board_on_stop")&&controller.keep_board_on_stop){
            // Pausing is a freeze, not a rewind.  Script tracks animate the
            // live BattleBoard structs; rebuilding here discarded their final
            // position/shape and made the board visibly snap back to the
            // initialization square.  RuntimeStart performs the deliberate
            // reset before the next preview, so leave the current composition
            // untouched while the author inspects a paused frame.
            if(!controller.board_preview_active) BattleEditor_SyncBoardPreview(controller,true);
            controller.preserve_paused_board=true;
        }else BattleEditor_DestroyPreviewFramesAnimated(controller,12);
    }
    if (os_type == os_windows) keyboard_virtual_hide();
    return true;
}

/// Natural timeline completion may clean up ordinary runtime objects at once,
/// but a real GB must be allowed to finish its visible narrowing animation.
function BattleEditor_RuntimeVisualsReadyToStop(controller) {
    if(!instance_exists(controller)||!variable_instance_exists(controller,"runtime_instances")) return true;
    for(var i=0;i<array_length(controller.runtime_instances);i++){
        var inst=controller.runtime_instances[i];
        if(!instance_exists(inst)) continue;
        if(variable_instance_exists(inst,"_battle_editor_runtime_hold_until_destroy")&&inst._battle_editor_runtime_hold_until_destroy) return false;
        if(inst.object_index!=battle_bullet_gb) continue;
        if(variable_instance_exists(inst,"fake_mode")&&inst.fake_mode!=0) continue;
        if(!variable_instance_exists(inst,"_beam_closing")||!inst._beam_closing) return false;
        if(!variable_instance_exists(inst,"_beam_close_complete")||!inst._beam_close_complete) return false;
    }
    return true;
}

function BattleEditor_Exit(controller) {
    BattleEditor_RuntimeStop(controller);
    BattleEditor_SetInputCapture(false);
    keyboard_string="";
    if(os_type==os_windows) keyboard_virtual_hide();
    // Every room now presents through one 640x480 output surface. The
    // persistent camera gives legacy 320x240 rooms a matching 320x240 view,
    // rather than changing the application surface and causing shrink/pixel
    // regressions on the following room transition.
    display_set_gui_size(640,480);
    if(surface_exists(application_surface)) surface_resize(application_surface,640,480);
    Border_SetEnabled(false,false);
    return true;
}

function BattleEditor_RuntimeStart(controller) {
    if(!BattleEditor_RuntimeEnsureController(controller)) return false;
    if(variable_instance_exists(controller,"audio_preview_handle")) BattleEditor_AudioPreviewStop(controller);
    // Resolve the active authored turn before duration and event scheduling.
    // turn_test already resolved its natural turn in Create; manual editor
    // playback follows the turn currently selected by the author.
    if(controller.object_index==battle_editor){
        controller.script_monster_turn=max(1,round(real(controller.developer_turn)));
    }
    if(!variable_instance_exists(controller,"timeline_duration_cache")
    ||!variable_instance_exists(controller,"timeline_duration_dirty")
    ||controller.timeline_duration_dirty) BattleEditor_RefreshDurationCache(controller);
    BattleEditor_RuntimeStop(controller);
    // Everything created after this point belongs to this playback/seek and
    // may be removed safely when a target frame is frozen or playback ends.
    BattleEditor_RuntimeCaptureAnimationBaseline(controller);
    controller.preserve_paused_board=false;
    // A manual editor preview starts from the initialization values. A real
    // monster turn must preserve damage from preceding turns instead of
    // silently healing the player back to the authored initial HP.
    if(controller.object_index==battle_editor) BattleEditor_ApplyInitialization(controller.project);
    // turn_test receives TURN_START only after enemy dialogue and board
    // preparation end. The editor preview already defines its own origin as
    // that same instant, so this is the single correct place to leave red.
    if(instance_exists(battle_soul)) BattleEditor_SetSoulMode(BattleEditor_SoulModeFromName(controller.project.initialization.soul));
    controller.playing = true;
    controller.playhead = 0;
    controller.fired = array_create(array_length(controller.project.events), false);
    controller.script_runtime_states=[];
    controller.script_scheduled_sounds=[];
    controller.script_timer_fired=[];
    controller.script_vertex_animations=[];
    controller.script_patterns=[];
    controller.runtime_variables=BattleEditor_ExpressionVariables(controller.project);
    // Duration depends only on authored project data during one playback.
    // Recomputing it inside every replayed frame repeatedly walked every
    // object and every Workspace item while the user dragged the timeline.
    controller.runtime_effective_duration=BattleEditor_EffectiveDuration(controller.project,controller.script_monster_turn);
    BattleEditor_RuntimeCaptureScreen(controller);
    global.battle_editor_runtime_controller=controller;
    BattleEditor_SyncBoardPreview(controller,true);
    var pending_item_uid="";
    var pending_item_mode=BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE;
    if(controller.object_index!=battle_editor&&instance_exists(battle)){
        if(variable_instance_exists(battle,"_battle_editor_pending_item_uid")) pending_item_uid=string(battle._battle_editor_pending_item_uid);
        if(variable_instance_exists(battle,"_battle_editor_pending_item_mode")) pending_item_mode=clamp(round(real(battle._battle_editor_pending_item_mode)),BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE,BATTLE_EDITOR_ITEM_AFTER_USE.REPLACE_TURN);
    }
    BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.GAME_START,"");
    // A deferred item attack starts at the same post-dialogue zero as every
    // normal monster-turn list. REPLACE is explicit authored data; no script
    // inspection guesses whether a list "looks like" an attack.
    if(pending_item_mode!=BATTLE_EDITOR_ITEM_AFTER_USE.REPLACE_TURN) BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN,controller.script_monster_turn);
    if(string_length(pending_item_uid)>0) BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED,pending_item_uid);
    if(controller.object_index!=battle_editor&&instance_exists(battle)){
        battle._battle_editor_pending_item_uid="";
        battle._battle_editor_pending_item_mode=BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE;
    }
    if (os_type == os_windows) {
        keyboard_string = "";
        keyboard_virtual_hide();
    }
    return true;
}

function BattleEditor_RuntimeStartList(controller,list_uid) {
    var requested_list=BattleEditor_FindScriptList(controller.project,list_uid);
    if(is_undefined(requested_list)||!BattleEditor_WorkspaceHasHeader(requested_list)) return false;
    if(!BattleEditor_RuntimeStart(controller)) return false;
    // RuntimeStart performs the shared initialization and timeline setup. A
    // header preview then replaces automatic entry lists with exactly the list
    // the author clicked, so testing one branch never also fires Game Start or
    // the current monster-turn entry by surprise.
    controller.script_runtime_states=[];
    controller.script_timer_fired=[];
    return BattleEditor_StartScriptList(controller,list_uid);
}

function BattleEditor_RuntimeBoardByUid(controller,frame_uid) {
    if(!instance_exists(controller)||!instance_exists(battle_board)) return noone;
    if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed&&struct_exists(battle_board.mainboard,"editor_uid")&&battle_board.mainboard.editor_uid==frame_uid) return battle_board.mainboard;
    for(var i=0;i<array_length(controller.preview_frames);i++){
        var frame=controller.preview_frames[i];
        if(is_struct(frame)&&!frame._destroyed&&struct_exists(frame,"editor_uid")&&frame.editor_uid==frame_uid) return frame;
    }
    return is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed?battle_board.mainboard:noone;
}

/// Returns [found,x,y]. Runtime instances win; authored data is the fallback
/// so a bone can point at an object whose own timeline spawn is still pending.
function BattleEditor_RuntimePointTarget(controller,target_uid) {
    // -2 is the stable system target for the live player soul. It is not an
    // authored object UID and therefore survives every save/load/rename.
    if(target_uid==-2&&instance_exists(battle_soul)) return [true,battle_soul.x,battle_soul.y];
    if(target_uid<0) return [false,0,0];
    if(instance_exists(controller)){
        for(var runtime_index=0;runtime_index<array_length(controller.runtime_instances);runtime_index++){
            var runtime_target=controller.runtime_instances[runtime_index];
            if(instance_exists(runtime_target)&&variable_instance_exists(runtime_target,"editor_uid")&&runtime_target.editor_uid==target_uid)
                return [true,runtime_target.x,runtime_target.y];
        }
        if(instance_exists(battle_board)){
            if(is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed&&struct_exists(battle_board.mainboard,"editor_uid")&&battle_board.mainboard.editor_uid==target_uid)
                return [true,battle_board.mainboard.x,battle_board.mainboard.y];
            for(var preview_index=0;preview_index<array_length(controller.preview_frames);preview_index++){
                var preview_target=controller.preview_frames[preview_index];
                if(is_struct(preview_target)&&!preview_target._destroyed&&struct_exists(preview_target,"editor_uid")&&preview_target.editor_uid==target_uid)
                    return [true,preview_target.x,preview_target.y];
            }
        }
        var point_project=controller.project;
        for(var enemy_index=0;enemy_index<array_length(point_project.initialization.enemies);enemy_index++){
            var enemy_target=point_project.initialization.enemies[enemy_index];
            if(enemy_target.uid==target_uid) return [true,enemy_target.x,enemy_target.y];
        }
        for(var event_index=0;event_index<array_length(point_project.events);event_index++){
            var event_target=point_project.events[event_index];
            if(variable_instance_exists(controller,"script_monster_turn")&&!BattleEditor_EventBelongsToTurn(event_target,controller.script_monster_turn)) continue;
            if(event_target.uid!=target_uid) continue;
            if(event_target.preset=="bone"){
                var bone_world=BattleEditor_BoneWorldTransform(event_target,point_project);
                return [true,bone_world.x,bone_world.y];
            }
            return [true,event_target.transform.x,event_target.transform.y];
        }
    }
    return [false,0,0];
}

function BattleEditor_SpawnEvent(event_data, initialization=undefined, controller=undefined) {
    var spawn_track=event_data.transform;
    if(event_data.preset=="bone_3d"||event_data.preset=="bone_4d"){
        var solid_instance;
        if(event_data.preset=="bone_4d"){
            solid_instance=Battle_MakeBone4D(spawn_track.x,spawn_track.y,event_data.world_z,
                [event_data.angle_x,event_data.angle_y,event_data.angle_z],
                [event_data.angle_xw,event_data.angle_yw,event_data.angle_zw],
                [event_data.rotate_x,event_data.rotate_y,event_data.rotate_z],
                [event_data.rotate_xw,event_data.rotate_yw,event_data.rotate_zw],
                [event_data.size_x,event_data.size_y,event_data.size_z,event_data.size_w],
                event_data.damage_profile.type,event_data.layer_mode,event_data.duration,event_data.edge_trim);
            solid_instance.perspective4d_distance=event_data.perspective4d_distance;
        }else{
            solid_instance=Battle_MakeBone3D(spawn_track.x,spawn_track.y,event_data.angle_x,event_data.angle_y,event_data.angle_z,
                event_data.rotate_x,event_data.rotate_y,event_data.rotate_z,event_data.size_x,event_data.size_y,event_data.size_z,
                event_data.vspeed,event_data.hspeed,event_data.shape_3d,event_data.damage_profile.type,event_data.layer_mode,
                event_data.duration,event_data.edge_trim,event_data.world_z,true,event_data.perspective_distance);
        }
        solid_instance.perspective_distance=event_data.perspective_distance;
        solid_instance.editor_damage_enabled=true;
        solid_instance.hp_damage=max(0,event_data.damage_profile.damage);
        solid_instance.heal_amount=event_data.damage_profile.heal_amount;
        solid_instance.editor_visual_override=event_data.visual_tint.enabled&&!event_data.visual_tint.follow_damage_profile;
        solid_instance.editor_visual_color=event_data.visual_tint.color;
        BattleEditor_RuntimeAssignIdentity(solid_instance,event_data);
        return solid_instance;
    }
    if(event_data.preset=="platform"){
        var platform=Battle_MakePlatform(spawn_track.x,spawn_track.y,event_data.width,spawn_track.angle,event_data.hspeed,event_data.vspeed,event_data.sticky,event_data.bounce,event_data.duration,event_data.auto_destroy);
        Battle_SetAttackLayer(platform,event_data.layer_mode);
        BattleEditor_RuntimeAssignIdentity(platform,event_data);
        return platform;
    }
    if (event_data.kind == BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD&&event_data.preset=="bone") {
        var follow_target=event_data.follow&&!is_undefined(controller)?BattleEditor_RuntimeBoardByUid(controller,event_data.follow_target_uid):noone;
        var spawn_x=spawn_track.x;
        var spawn_y=spawn_track.y;
        if(event_data.follow&&is_struct(follow_target)){
            spawn_x=follow_target.x+spawn_track.x;
            spawn_y=follow_target.y+spawn_track.y;
        }
        var bone=Battle_MakeBone(
            spawn_x, spawn_y, event_data.length,
            event_data.hspeed, event_data.vspeed, event_data.damage_profile.type,
            event_data.layer_mode, spawn_track.angle, event_data.rotate, false, event_data.duration,
            event_data.follow, false, follow_target, noone,
            0, 0, noone, noone,
            event_data.green_guard_blockable, event_data.green_guard_destroy_on_block,
            event_data.bone_style
        );
        bone.heal_amount=event_data.damage_profile.heal_amount;
        bone.editor_damage_enabled=true;
        bone.hp_damage=max(0,event_data.damage_profile.damage);
        bone.kr_damage=max(0,event_data.damage_profile.damage);
        bone.editor_visual_override=event_data.visual_tint.enabled&&!event_data.visual_tint.follow_damage_profile;
        bone.editor_visual_color=event_data.visual_tint.color;
        BattleEditor_RuntimeAssignIdentity(bone,event_data);
        bone.editor_aim_enabled=event_data.aim_enabled;
        bone.editor_aim_target_uid=event_data.aim_target_uid;
        bone.editor_aim_continuous=event_data.aim_continuous;
        bone.editor_aim_move_enabled=event_data.aim_move_enabled;
        bone.editor_aim_move_speed=event_data.aim_move_speed;
        bone.editor_aim_controller=controller;
        bone.editor_aim_applied=false;
        return bone;
    }

    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.SPRITE_HAZARD){
        var hazard_depth=event_data.layer_mode==BATTLE_EDITOR_LAYER.OUTSIDE?DEPTH_BATTLE.BULLET_OUTSIDE_LOW:DEPTH_BATTLE.BULLET;
        var hazard=instance_create_depth(spawn_track.x,spawn_track.y,hazard_depth,battle_editor_sprite_hazard);
        // Runtime controls may change damage/type/visual state. The instance
        // must own that mutable data; sharing the authored event struct made a
        // timeline preview permanently recolour the draggable scene object.
        hazard.Setup(json_parse(json_stringify(event_data)));
        BattleEditor_RuntimeAssignIdentity(hazard,event_data);
        return hazard;
    }

    if (event_data.kind == BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="gb") {
        if(is_undefined(initialization)) initialization=global.battle_editor_project_runtime.initialization;
        var spawn=BattleEditor_ResolveGBSpawn(event_data,initialization);
        var gb = Battle_MakeGB(
            spawn[0], spawn[1],
            event_data.target_x, event_data.target_y,
            spawn[2], event_data.angle_target,
            spawn_track.scale_x*2, spawn_track.scale_y*2,
            event_data.damage_profile.type,
            event_data.charge_time, event_data.beam_time, event_data.move_time,
            false, event_data.fake_mode, spawn_track.tween, spawn_track.ease,event_data.layer_mode
        );
        gb.heal_amount=event_data.damage_profile.heal_amount;
        gb.editor_damage_enabled=true;
        gb.hp_damage=max(0,event_data.damage_profile.damage);
        gb.kr_damage=max(0,event_data.damage_profile.damage);
        gb.editor_visual_override=event_data.visual_tint.enabled&&!event_data.visual_tint.follow_damage_profile;
        gb.editor_visual_color=event_data.visual_tint.color;
        gb.editor_gb_builtin_style=real(event_data.gb_style_uid)<0;
        var gb_style=BattleEditor_GBStyleDefinition(global.battle_editor_project_runtime,event_data.gb_style_uid);
        if(!is_undefined(gb_style)) BattleEditor_ApplyGBStyle(gb,gb_style,controller);
        if(event_data.offset_enabled){
            var gb_offset_direction=round(real(event_data.offset_direction_mode))==0?event_data.angle_target+180:event_data.offset_direction;
            Battle_GBSetOffset(gb,gb_offset_direction,event_data.offset_speed,event_data.offset_acceleration,event_data.offset_rotation_speed);
        }
        BattleEditor_RuntimeAssignIdentity(gb,event_data);
        return gb;
    }
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(event_data.preset=="slash"||event_data.preset=="true_knife")){
        var wave=event_data.preset=="true_knife"
            ?Battle_MakeTrueKnife(spawn_track.x,spawn_track.y,spawn_track.angle,event_data.warning_time,event_data.active_time,event_data.visual_min_width,event_data.visual_max_width,event_data.damage_profile.type,event_data.layer_mode,event_data.invincibility_frames,event_data.damage_profile.damage)
            :Battle_MakeSlash(spawn_track.x,spawn_track.y,spawn_track.angle,event_data.warning_time,event_data.active_time,event_data.visual_min_width,event_data.visual_max_width,event_data.damage_profile.type,event_data.warning_width,event_data.layer_mode);
        var pre=event_data.pre_motion;
        var post=event_data.post_motion;
        Battle_WaveSetMotion(wave,pre.direction,pre.speed,pre.acceleration,pre.rotation_speed,pre.curve_speed,true);
        Battle_WaveSetMotion(wave,post.direction,post.speed,post.acceleration,post.rotation_speed,post.curve_speed,false);
        Battle_WaveSetRotation(wave,true,pre.rotation_mode,pre.target_angle,pre.rotation_time,pre.tween,pre.ease);
        Battle_WaveSetRotation(wave,false,post.rotation_mode,post.target_angle,post.rotation_time,post.tween,post.ease);
        wave.wave_color=event_data.visual_tint.follow_damage_profile?BattleEditor_ColorForType(event_data.damage_profile.type):event_data.visual_tint.color;
        wave.hp_damage=event_data.preset=="true_knife"?max(0,event_data.damage_profile.damage):max(1,event_data.damage_profile.damage);
        if(event_data.preset=="true_knife") wave.kr_damage=0;
        wave.heal_amount=event_data.damage_profile.heal_amount;
        BattleEditor_RuntimeAssignIdentity(wave,event_data);
        return wave;
    }
    if (event_data.kind == BATTLE_EDITOR_OBJECT_KIND.DECORATION) {
        var deco=instance_create_depth(spawn_track.x,spawn_track.y,DEPTH_BATTLE.BULLET_OUTSIDE_LOW,battle_editor_decoration);
        deco.Setup(event_data);
        BattleEditor_RuntimeAssignIdentity(deco,event_data);
        return deco;
    }
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
        var base_color_command=is_real(event_data.text_color)?"{color_text "+string(event_data.text_color)+"}":"{color `"+string(event_data.text_color)+"`}";
        var prefix="{font "+string(event_data.font_id)+"}{voice "+string(event_data.voice_id)+"}{speed "+string(event_data.speed)+"}"+base_color_command+"{depth "+string(event_data.text_depth)+"}";
        var compiled_text=TextTyper_CompileMarkup(event_data.text);
        var runtime_text=compiled_text.text;
        if(!event_data.page_requires_confirm) runtime_text=string_replace_all(runtime_text,"{pause}{clear}","{sleep "+string(max(0,event_data.page_delay))+"}{clear}");
        var typer=TextTyper_Add(spawn_track.x,spawn_track.y,event_data.text_depth,prefix+runtime_text);
        typer._angle=spawn_track.angle;
        typer._scale_x=spawn_track.scale_x;
        typer._scale_y=spawn_track.scale_y;
        typer._alpha=spawn_track.alpha;
        if(event_data.layer_mode==BATTLE_EDITOR_LAYER.IN_BOARD&&instance_exists(battle_board)) typer._surface_target=Battle_GetBoardSurface();
        else if(event_data.layer_mode==BATTLE_EDITOR_LAYER.BELOW_BOARD) typer.depth=DEPTH_BATTLE.BULLET;
        BattleEditor_RuntimeAssignIdentity(typer,event_data);
        return typer;
    }
    return noone;
}

function BattleEditor_RuntimeStep(controller) {
    if(!BattleEditor_RuntimeEnsureController(controller)) return false;
    if (!controller.playing) return;
    controller.playhead += global.delta_time_factor;
    for(var timer_list_index=0;timer_list_index<array_length(controller.project.script_lists);timer_list_index++){
        var timer_list=controller.project.script_lists[timer_list_index];
        if(!BattleEditor_ScriptListBelongsToTurn(timer_list,controller.script_monster_turn)) continue;
        if(timer_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE&&controller.playhead>=real(timer_list.entry_value)){
            var timer_seen=false;
            for(var timer_seen_index=0;timer_seen_index<array_length(controller.script_timer_fired);timer_seen_index++) if(controller.script_timer_fired[timer_seen_index]==timer_list.uid){timer_seen=true;break;}
            if(!timer_seen){array_push(controller.script_timer_fired,timer_list.uid);BattleEditor_StartScriptList(controller,timer_list.uid);}
        }
    }
    for (var i = 0; i < array_length(controller.project.events); i++) {
        if(!BattleEditor_EventBelongsToTurn(controller.project.events[i],controller.script_monster_turn)) continue;
        if (!controller.fired[i] && controller.project.events[i].time <= controller.playhead) {
            controller.fired[i] = true;
            var exact_seek_birth=controller.timeline_seek_active&&abs(controller.project.events[i].time-controller.timeline_seek_target)<=0.0001;
            if(variable_global_exists("battle_editor_seek_audio_silent")&&global.battle_editor_seek_audio_silent) global.battle_editor_seek_audio_exact_birth=exact_seek_birth;
            var inst = BattleEditor_SpawnEvent(controller.project.events[i],controller.project.initialization,controller);
            if(variable_global_exists("battle_editor_seek_audio_silent")&&global.battle_editor_seek_audio_silent) global.battle_editor_seek_audio_exact_birth=false;
            if (instance_exists(inst)) BattleEditor_RuntimeTrack(controller,inst);
        }
    }
    var exact_seek_script_frame=controller.timeline_seek_active&&abs(controller.playhead-controller.timeline_seek_target)<=0.0001;
    if(variable_global_exists("battle_editor_seek_audio_silent")&&global.battle_editor_seek_audio_silent) global.battle_editor_seek_audio_exact_birth=exact_seek_script_frame;
    BattleEditor_RuntimeScriptStep(controller);
    if(variable_global_exists("battle_editor_seek_audio_silent")&&global.battle_editor_seek_audio_silent) global.battle_editor_seek_audio_exact_birth=false;
    BattleEditor_RuntimeVertexStep(controller);
    BattleEditor_RuntimePatternStep(controller);
    var effective_duration=controller.runtime_effective_duration;
    // The computed length is a lower bound. A list can still be alive because
    // of a conditional/repeat/node connection, so never cut it off merely
    // because the static estimate elapsed.
    var scripts_finished=array_length(controller.script_runtime_states)<=0&&array_length(controller.script_scheduled_sounds)<=0;
    var vertices_finished=array_length(controller.script_vertex_animations)<=0;
    // A frame-follow adapter is a persistent transform relationship rather
    // than unfinished attack work. It remains alive until runtime teardown,
    // but must not keep an otherwise completed monster turn open forever.
    var patterns_finished=true;
    for(var finish_pattern_index=0;finish_pattern_index<array_length(controller.script_patterns);finish_pattern_index++){
        var finish_pattern=controller.script_patterns[finish_pattern_index];
        if(!is_struct(finish_pattern)||finish_pattern.kind!="control_follow_instance"){
            patterns_finished=false;
            break;
        }
    }
    var visuals_finished=BattleEditor_RuntimeVisualsReadyToStop(controller);
    if (!controller.timeline_seek_active&&effective_duration>0&&controller.playhead >= effective_duration&&scripts_finished&&vertices_finished&&patterns_finished&&visuals_finished){
        var runtime_is_real_turn=controller.object_index==turn_test;
        // A full editor preview is inspection, not an actual monster turn.
        // Hold its final calculated frame so ADD/SUBTRACT boards and hazards
        // stay visible instead of entering RuntimeStop's teardown animation.
        if(controller.object_index==battle_editor&&controller.timeline_full_play){
            BattleEditor_RuntimeFreezeAtCursor(controller,controller.playhead);
        }else{
            BattleEditor_RuntimeStop(controller);
            if(runtime_is_real_turn&&instance_exists(battle)&&Battle_GetState()==BATTLE_STATE.IN_TURN) Battle_EndTurn();
        }
    }
    return true;
}

/// The authored runtime, rather than battle's coarse countdown, is the
/// authority for the end of a real editor-driven monster turn. The static
/// duration is useful for the timeline and as a lower bound, but a repeat,
/// branch or deferred pattern may still be alive when that estimate reaches
/// zero. RuntimeStep ends the turn only after every live script/pattern is
/// actually finished.
function BattleEditor_RuntimeOwnsTurnEnd() {
    if(!variable_global_exists("battle_editor_runtime_controller")) return false;
    var controller=global.battle_editor_runtime_controller;
    return instance_exists(controller)
        &&controller.object_index==turn_test
        &&variable_instance_exists(controller,"playing")
        &&controller.playing;
}

function BattleEditor_RuntimeAssignIdentity(target,event_data) {
    if(!instance_exists(target)) return target;
    target.editor_uid=event_data.uid;
    target.editor_name=event_data.name;
    target.control_id=event_data.control_id;
    target.editor_control_uid=struct_exists(event_data,"control_uid")?event_data.control_uid:-1;
    target.editor_target_type=BattleEditor_DataTargetType(event_data);
    target.editor_birth_time=struct_exists(event_data,"time")?real(event_data.time):0;
    target.editor_clip_mode=struct_exists(event_data,"clip_mode")?event_data.clip_mode:"all";
    target.editor_clip_frame_uids=struct_exists(event_data,"clip_frame_uids")?json_parse(json_stringify(event_data.clip_frame_uids)):[];
    target.editor_clipped_collision=struct_exists(event_data,"clipped_collision")?event_data.clipped_collision:true;
    return target;
}

function BattleEditor_UidArrayContains(values,uid) {
    if(!is_array(values)) return false;
    for(var i=0;i<array_length(values);i++) if(values[i]==uid) return true;
    return false;
}

function BattleEditor_RuntimeClipBoards(target) {
    var result=[];
    if(!instance_exists(target)||!variable_instance_exists(target,"editor_clip_frame_uids")) return result;
    var selected=target.editor_clip_frame_uids;
    for(var i=0;i<array_length(global.boards_array);i++){
        var board=global.boards_array[i];
        if(!is_struct(board)||board._destroyed||!struct_exists(board,"editor_uid")) continue;
        if(BattleEditor_UidArrayContains(selected,board.editor_uid)) array_push(result,board);
    }
    return result;
}

function BattleEditor_DrawRuntimeBoardFill(board,alpha) {
    if(variable_struct_exists(board,"listVertex")){
        board.drawFillAlpha(alpha);
        return;
    }
    if(variable_struct_exists(board,"radius_x")&&variable_struct_exists(board,"radius_y")){
        draw_set_alpha(alpha);
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(board.x,board.y);
        var precision=max(24,variable_struct_exists(board,"precision")?board.precision:96);
        for(var i=0;i<=precision;i++){
            var pos=RotateAround(board.x,board.y,board.x+lengthdir_x(board.radius_x,i*360/precision),board.y+lengthdir_y(board.radius_y,i*360/precision),board.x,board.y,board.angle);
            draw_vertex(pos[0],pos[1]);
        }
        draw_primitive_end();
        draw_set_alpha(1);
    }
}

function BattleEditor_BuildRuntimeClipMask(target) {
    if(!instance_exists(battle_board)||!surface_exists(battle_board._surface_editor_clip_mask)) return -1;
    var boards=BattleEditor_RuntimeClipBoards(target);
    shader_reset();
    surface_set_target(battle_board._surface_editor_clip_mask);
    draw_clear_alpha(c_white,0);
    gpu_set_colorwriteenable(false,false,false,true);
    gpu_set_blendenable(false);
    for(var pass=0;pass<2;pass++){
        for(var i=0;i<array_length(boards);i++) if(boards[i].cover==pass) BattleEditor_DrawRuntimeBoardFill(boards[i],pass==0?1:0);
    }
    gpu_set_blendenable(true);
    gpu_set_colorwriteenable(true,true,true,true);
    surface_reset_target();
    return battle_board._surface_editor_clip_mask;
}

function BattleEditor_CustomClipBegin(target) {
    if(!instance_exists(target)||!variable_instance_exists(target,"editor_clip_mode")||target.editor_clip_mode!="selected") return false;
    var mask=BattleEditor_BuildRuntimeClipMask(target);
    if(!surface_exists(mask)) return false;
    shader_set(shd_battle_editor_clip);
    texture_set_stage(shader_get_sampler_index(shd_battle_editor_clip,"u_clip_mask"),surface_get_texture(mask));
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_clip,"u_target_size"),640,480);
    return true;
}

function BattleEditor_CustomClipEnd(active) {
    if(active) shader_reset();
}

function BattleEditor_ClipCollisionAllowed(target,px,py) {
    if(!instance_exists(target)||!variable_instance_exists(target,"editor_clip_mode")||target.editor_clip_mode!="selected") return true;
    if(!variable_instance_exists(target,"editor_clipped_collision")||!target.editor_clipped_collision) return true;
    var boards=BattleEditor_RuntimeClipBoards(target);
    var inside_add=false;
    for(var i=0;i<array_length(boards);i++){
        var board=boards[i];
        if(board.cover){if(board.contains(px,py)) return false;}
        else if(board.contains(px,py)) inside_add=true;
    }
    return inside_add;
}

function BattleEditor_DataTargetType(data) {
    if(!is_struct(data)) return "";
    if(struct_exists(data,"editor_target_type")) return string(data.editor_target_type);
    if(struct_exists(data,"shape")) return "board";
    if(struct_exists(data,"preset")&&data.preset=="bone") return "bone";
    if(struct_exists(data,"preset")&&data.preset=="bone_3d") return "bone_3d";
    if(struct_exists(data,"preset")&&data.preset=="bone_4d") return "bone_4d";
    if(struct_exists(data,"preset")&&data.preset=="gb") return "gb";
    if(struct_exists(data,"preset")&&data.preset=="slash") return "slash";
    if(struct_exists(data,"preset")&&data.preset=="true_knife") return "true_knife";
    if(struct_exists(data,"preset")&&data.preset=="platform") return "platform";
    if(struct_exists(data,"kind")&&data.kind==BATTLE_EDITOR_OBJECT_KIND.DECORATION) return "decoration";
    if(struct_exists(data,"kind")&&data.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER) return "typewriter";
    return "sprite_hazard";
}

function BattleEditor_AuthoredControlSources(project) {
    var result=[];
    if(!is_struct(project)) return result;
    if(struct_exists(project,"initialization")&&is_struct(project.initialization)){
        var source_init=project.initialization;
        if(struct_exists(source_init,"board")&&is_struct(source_init.board)) array_push(result,source_init.board);
        if(struct_exists(source_init,"frames")&&is_array(source_init.frames)) for(var source_frame=0;source_frame<array_length(source_init.frames);source_frame++) array_push(result,source_init.frames[source_frame]);
        if(struct_exists(source_init,"enemies")&&is_array(source_init.enemies)) for(var source_enemy=0;source_enemy<array_length(source_init.enemies);source_enemy++) array_push(result,source_init.enemies[source_enemy]);
    }
    if(struct_exists(project,"events")&&is_array(project.events)) for(var source_event=0;source_event<array_length(project.events);source_event++) array_push(result,project.events[source_event]);
    return result;
}

function BattleEditor_ControlGroupByUid(project,control_uid,target_type="") {
    if(control_uid<0) return undefined;
    var sources=BattleEditor_AuthoredControlSources(project);
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(!struct_exists(source,"control_uid")||source.control_uid!=control_uid) continue;
        if(target_type!=""&&BattleEditor_DataTargetType(source)!=target_type) continue;
        return {uid:source.control_uid,control_id:string(source.control_id),target_type:BattleEditor_DataTargetType(source)};
    }
    return undefined;
}

function BattleEditor_ControlGroupMemberCount(project,control_uid,target_type="") {
    if(control_uid<0) return 0;
    var sources=BattleEditor_AuthoredControlSources(project),count=0;
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(!struct_exists(source,"control_uid")||source.control_uid!=control_uid) continue;
        if(target_type!=""&&BattleEditor_DataTargetType(source)!=target_type) continue;
        count+=1;
    }
    return count;
}

/// Keep the editable label and stable group identity separate. Renaming a
/// complete group only updates labels. Renaming it to another group's label
/// explicitly merges the identities, including every existing script ref.
function BattleEditor_ReconcileControlGroupLabel(project,control_uid,target_type,new_label) {
    if(control_uid<0||new_label=="") return control_uid;
    var sources=BattleEditor_AuthoredControlSources(project),resolved_uid=control_uid;
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(!struct_exists(source,"control_uid")||source.control_uid==control_uid) continue;
        if(BattleEditor_DataTargetType(source)==target_type&&string(source.control_id)==string(new_label)){resolved_uid=source.control_uid;break;}
    }
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(struct_exists(source,"control_uid")&&source.control_uid==control_uid&&BattleEditor_DataTargetType(source)==target_type){source.control_uid=resolved_uid;source.control_id=new_label;}
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        for(var step_index=0;step_index<array_length(list_data.steps);step_index++){
            var step_data=list_data.steps[step_index];
            if(step_data.kind=="control_object"&&struct_exists(step_data,"target_group_uid")&&step_data.target_group_uid==control_uid&&step_data.target_type==target_type){
                step_data.target_group_uid=resolved_uid;
                step_data.target=new_label;
            }
        }
    }
    return resolved_uid;
}

/// Legacy control steps stored only a visible Control ID. Resolve it once to
/// one stable authored group. If that old label no longer exists, a unique
/// object display-name match repairs the common "rename after selecting"
/// case without guessing between several candidates.
function BattleEditor_FindUniqueAuthoredControlGroup(project,label,target_type,match_name=false) {
    var sources=BattleEditor_AuthoredControlSources(project);
    var found_uid=-1,found_id="",distinct=0;
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(!struct_exists(source,"control_uid")||BattleEditor_DataTargetType(source)!=target_type) continue;
        var matches=match_name
            ?(struct_exists(source,"name")&&string(source.name)==string(label))
            :(struct_exists(source,"control_id")&&string(source.control_id)==string(label));
        if(!matches) continue;
        if(found_uid<0){found_uid=source.control_uid;found_id=string(source.control_id);distinct=1;}
        else if(source.control_uid!=found_uid) distinct+=1;
    }
    if(distinct!=1) return undefined;
    return {uid:found_uid,control_id:found_id,target_type:target_type};
}

function BattleEditor_IsSameEventGroup(a,b) {
    if(!is_struct(a)||!is_struct(b)||BattleEditor_DataTargetType(a)!=BattleEditor_DataTargetType(b)) return false;
    if(BattleEditor_EventTurn(a)!=BattleEditor_EventTurn(b)) return false;
    if(struct_exists(a,"control_uid")&&struct_exists(b,"control_uid")) return a.control_uid==b.control_uid;
    return string(a.control_id)!=""&&string(a.control_id)==string(b.control_id);
}

/// Counts the exact editable group shown by a scene double-click. Control IDs
/// are allowed to be reused by different object types, so this must never use
/// the broader project-wide ControlIdCount helper.
function BattleEditor_EventGroupCount(project,target_type,control_id,control_uid=-1,turn_number=undefined) {
    if(string(control_id)==""&&control_uid<0) return 0;
    var count=0;
    for(var i=0;i<array_length(project.events);i++){
        var candidate_event=project.events[i];
        if(!is_undefined(turn_number)&&!BattleEditor_EventBelongsToTurn(candidate_event,turn_number)) continue;
        if(BattleEditor_DataTargetType(candidate_event)!=target_type) continue;
        if(control_uid>=0){
            if(struct_exists(candidate_event,"control_uid")&&candidate_event.control_uid==control_uid) count++;
        }else if(string(candidate_event.control_id)==string(control_id)) count++;
    }
    return count;
}

function BattleEditor_EventWorldPose(event_data,project,main_preview=undefined) {
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="gb"){
        return {x:event_data.target_x,y:event_data.target_y,angle:event_data.angle_target};
    }
    if(event_data.preset=="bone"&&struct_exists(event_data,"follow")&&event_data.follow){
        return BattleEditor_BoneWorldTransform(event_data,project,main_preview);
    }
    return {x:event_data.transform.x,y:event_data.transform.y,angle:event_data.transform.angle};
}

function BattleEditor_SetEventWorldPosition(event_data,world_x,world_y,project,main_preview=undefined) {
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="gb"){
        event_data.target_x=world_x;
        event_data.target_y=world_y;
        return true;
    }
    if(event_data.preset=="bone"&&struct_exists(event_data,"follow")&&event_data.follow){
        var follow_frame=BattleEditor_FollowFrameData(project,event_data.follow_target_uid,main_preview);
        var local=RotateAround(0,0,world_x-follow_frame.x,world_y-follow_frame.y,0,0,-follow_frame.angle);
        event_data.transform.x=local[0];
        event_data.transform.y=local[1];
        return true;
    }
    event_data.transform.x=world_x;
    event_data.transform.y=world_y;
    return true;
}

/// Mouse-wheel rotation acts on the selected object without requiring the
/// pointer to remain over its sprite. In a group, the primary object the user
/// clicked is the world-space origin (like a camera/parent pivot): it stays in
/// place while the other members orbit it and every member turns with it.
function BattleEditor_RotateEventSelection(project,primary_index,angle_delta,main_preview=undefined,group_type="",group_control_id="") {
    if(primary_index<0||primary_index>=array_length(project.events)||angle_delta==0) return 0;
    var member_indices=[];
    if(string(group_control_id)!=""){
        var primary_group_uid=struct_exists(project.events[primary_index],"control_uid")?project.events[primary_index].control_uid:-1;
        for(var i=0;i<array_length(project.events);i++){
            var candidate=project.events[i];
            if(BattleEditor_DataTargetType(candidate)!=group_type) continue;
            var identity_matches=primary_group_uid>=0
                ?(struct_exists(candidate,"control_uid")&&candidate.control_uid==primary_group_uid)
                :(string(candidate.control_id)==string(group_control_id));
            if(identity_matches) array_push(member_indices,i);
        }
    }else array_push(member_indices,primary_index);
    if(array_length(member_indices)<=0) return 0;

    var primary_pose=BattleEditor_EventWorldPose(project.events[primary_index],project,main_preview);
    var center_x=primary_pose.x;
    var center_y=primary_pose.y;

    var world_group=array_length(member_indices)>1||string(group_control_id)!="";
    for(var rotate_index=0;rotate_index<array_length(member_indices);rotate_index++){
        var member=project.events[member_indices[rotate_index]];
        var member_pose=BattleEditor_EventWorldPose(member,project,main_preview);
        if(world_group){
            var rotated=RotateAround(center_x,center_y,member_pose.x,member_pose.y,center_x,center_y,angle_delta);
            BattleEditor_SetEventWorldPosition(member,rotated[0],rotated[1],project,main_preview);
        }
        if(member.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&member.preset=="gb"){
            member.angle_target+=angle_delta;
            // Group rotation turns the complete incoming path as well as the
            // final GB pose. Directional presets derive their spawn position;
            // a custom absolute spawn point must be rotated explicitly.
            if(world_group){
                member.angle_start+=angle_delta;
                if(member.spawn_preset==BATTLE_EDITOR_GB_SPAWN.CUSTOM){
                    var rotated_spawn=RotateAround(center_x,center_y,member.spawn_x,member.spawn_y,center_x,center_y,angle_delta);
                    member.spawn_x=rotated_spawn[0];
                    member.spawn_y=rotated_spawn[1];
                }
            }
        }else member.transform.angle+=angle_delta;
    }
    return array_length(member_indices);
}

/// Copies only the field which the author explicitly submitted. Scene dragging
/// deliberately does not call this function; group dragging applies a delta.
function BattleEditor_SyncEventGroupField(project,primary_index,field_name,wave_phase=0,group_type="",group_control_id="") {
    if(primary_index<0||primary_index>=array_length(project.events)) return;
    var source=project.events[primary_index];
    var source_group_uid=struct_exists(source,"control_uid")?source.control_uid:-1;
    for(var i=0;i<array_length(project.events);i++){
        if(i==primary_index) continue;
        var target=project.events[i];
        var same_group=string(group_control_id)!=""
            ?(BattleEditor_DataTargetType(target)==group_type&&(source_group_uid>=0
                ?(struct_exists(target,"control_uid")&&target.control_uid==source_group_uid)
                :(string(target.control_id)==string(group_control_id))))
            :BattleEditor_IsSameEventGroup(source,target);
        if(!same_group) continue;
        switch(field_name){
            case "object_control_id": target.control_id=source.control_id; break;
            case "object_sprite": target.sprite_source=source.sprite_source; break;
            case "object_script": target.script_name=source.script_name; break;
            case "visual_color":
                target.visual_tint.color=source.visual_tint.color;target.visual_tint.enabled=source.visual_tint.enabled;target.visual_tint.mode=source.visual_tint.mode;
                target.visual_tint.preset_type=source.visual_tint.preset_type;target.visual_tint.custom_color=source.visual_tint.custom_color;target.visual_tint.follow_damage_profile=source.visual_tint.follow_damage_profile;
                break;
            case "follow_damage_profile": BattleEditor_SetVisualTintMode(target,source.visual_tint.follow_damage_profile?0:2); break;
            case "visual_color_mode":
                target.visual_tint.mode=source.visual_tint.mode;target.visual_tint.preset_type=source.visual_tint.preset_type;target.visual_tint.custom_color=source.visual_tint.custom_color;
                BattleEditor_SetVisualTintMode(target,target.visual_tint.mode);
                break;
            case "visual_color_preset":
                target.visual_tint.preset_type=source.visual_tint.preset_type;
                BattleEditor_SetVisualTintPreset(target,target.visual_tint.preset_type);
                break;
            case "text_color": target.text_color=source.text_color; break;
            case "object_heal_amount": target.damage_profile.heal_amount=source.damage_profile.heal_amount; break;
            case "object_damage": target.damage_profile.damage=source.damage_profile.damage; break;
            case "damage_type":
                BattleEditor_ApplyDamageTypeToEvent(target,source.damage_profile.type);
                break;
            case "damage_change_visual": BattleEditor_SetDamageChangeVisual(target,source.damage_profile.change_visual); break;
            case "layer_mode": target.layer_mode=source.layer_mode;target.clipped=source.clipped;if(struct_exists(source,"layer_user_set")) target.layer_user_set=source.layer_user_set; break;
            case "spawn_preset": target.spawn_preset=source.spawn_preset; break;
            case "fake_mode": target.fake_mode=source.fake_mode; break;
            case "gb_style_uid": if(target.preset=="gb") target.gb_style_uid=source.gb_style_uid; break;
            case "track_tween": target.transform.tween=source.transform.tween; break;
            case "wave_rotation_mode": if(wave_phase==0) target.pre_motion.rotation_mode=source.pre_motion.rotation_mode; else target.post_motion.rotation_mode=source.post_motion.rotation_mode; break;
            case "wave_tween": if(wave_phase==0) target.pre_motion.tween=source.pre_motion.tween; else target.post_motion.tween=source.post_motion.tween; break;
            case "wave_ease": if(wave_phase==0) target.pre_motion.ease=source.pre_motion.ease; else target.post_motion.ease=source.post_motion.ease; break;
            case "animation_fps": target.animation.fps=source.animation.fps; break;
            case "animation_loop": target.animation.loop=source.animation.loop; break;
            case "typewriter_speed": target.speed=source.speed; break;
            case "typewriter_depth": target.text_depth=source.text_depth; break;
            case "font_id": target.font_id=source.font_id; break;
            case "typewriter_voice": target.voice_id=source.voice_id; break;
            case "typewriter_confirm": target.page_requires_confirm=source.page_requires_confirm; break;
            case "green_guard_blockable": target.green_guard_blockable=source.green_guard_blockable; break;
            case "green_guard_destroy_on_block": target.green_guard_destroy_on_block=source.green_guard_destroy_on_block; break;
            case "bone_style": target.bone_style=source.bone_style; break;
            case "aim_enabled": target.aim_enabled=source.aim_enabled; break;
            case "aim_target_uid": target.aim_target_uid=source.aim_target_uid; break;
            case "aim_continuous": target.aim_continuous=source.aim_continuous; break;
            case "aim_move_enabled": target.aim_move_enabled=source.aim_move_enabled; break;
            case "aim_move_speed":
            case "bone_aim_speed": target.aim_move_speed=source.aim_move_speed; break;
            case "clip_mode": target.clip_mode=source.clip_mode; break;
            case "clip_frames":
                target.clip_mode=source.clip_mode;
                target.clip_frame_uids=[];
                array_copy(target.clip_frame_uids,0,source.clip_frame_uids,0,array_length(source.clip_frame_uids));
                break;
            case "clipped_collision": target.clipped_collision=source.clipped_collision; break;
            case "track_x": target.transform.x=source.transform.x; break;
            case "track_y": target.transform.y=source.transform.y; break;
            case "track_angle": target.transform.angle=source.transform.angle; break;
            case "track_scale_x": target.transform.scale_x=source.transform.scale_x; break;
            case "track_scale_y": target.transform.scale_y=source.transform.scale_y; break;
            case "track_alpha": target.transform.alpha=source.transform.alpha; break;
            case "bone_length": target.length=source.length; break;
            case "bone_hspeed": target.hspeed=source.hspeed; break;
            case "bone_vspeed": target.vspeed=source.vspeed; break;
            case "bone_rotate": target.rotate=source.rotate; break;
            case "platform_width": target.width=source.width; break;
            case "platform_hspeed": target.hspeed=source.hspeed; break;
            case "platform_vspeed": target.vspeed=source.vspeed; break;
            case "platform_sticky": target.sticky=source.sticky; break;
            case "platform_bounce": target.bounce=source.bounce; break;
            case "object_duration": target.duration=source.duration; break;
            case "object_time": target.time=source.time; break;
            case "gb_spawn_x": target.spawn_x=source.spawn_x; break;
            case "gb_spawn_y": target.spawn_y=source.spawn_y; break;
            case "gb_spawn_angle": target.angle_start=source.angle_start; break;
            case "gb_spawn_distance": target.spawn_distance=source.spawn_distance; break;
            case "gb_target_angle": target.angle_target=source.angle_target; break;
            case "gb_target_x": target.target_x=source.target_x; break;
            case "gb_target_y": target.target_y=source.target_y; break;
            case "gb_move_time": target.move_time=source.move_time; break;
            case "gb_charge_time": target.charge_time=source.charge_time; break;
            case "gb_beam_time": target.beam_time=source.beam_time; break;
            case "gb_offset_enabled": target.offset_enabled=source.offset_enabled; break;
            case "gb_offset_direction_mode": target.offset_direction_mode=source.offset_direction_mode; break;
            case "gb_offset_direction": target.offset_direction=source.offset_direction; break;
            case "gb_offset_speed": target.offset_speed=source.offset_speed; break;
            case "gb_offset_acceleration": target.offset_acceleration=source.offset_acceleration; break;
            case "gb_offset_rotation": target.offset_rotation_speed=source.offset_rotation_speed; break;
            case "gb_offset_curve": target.offset_curve_speed=source.offset_curve_speed; break;
            case "wave_warning_time": target.warning_time=source.warning_time; break;
            case "wave_active_time": target.active_time=source.active_time; break;
            case "wave_min_width": target.visual_min_width=source.visual_min_width;target.visual_max_width=source.visual_max_width;target.warning_width=source.warning_width; break;
            case "wave_max_width": target.visual_max_width=source.visual_max_width;target.warning_width=source.warning_width; break;
            case "true_knife_invincibility": target.invincibility_frames=source.invincibility_frames; break;
            case "wave_motion_direction": if(wave_phase==0) target.pre_motion.direction=source.pre_motion.direction; else target.post_motion.direction=source.post_motion.direction; break;
            case "wave_motion_speed": if(wave_phase==0) target.pre_motion.speed=source.pre_motion.speed; else target.post_motion.speed=source.post_motion.speed; break;
            case "wave_motion_acceleration": if(wave_phase==0) target.pre_motion.acceleration=source.pre_motion.acceleration; else target.post_motion.acceleration=source.post_motion.acceleration; break;
            case "wave_motion_curve": if(wave_phase==0) target.pre_motion.curve_speed=source.pre_motion.curve_speed; else target.post_motion.curve_speed=source.post_motion.curve_speed; break;
            case "wave_rotation_speed": if(wave_phase==0) target.pre_motion.rotation_speed=source.pre_motion.rotation_speed; else target.post_motion.rotation_speed=source.post_motion.rotation_speed; break;
            case "wave_rotation_target": if(wave_phase==0) target.pre_motion.target_angle=source.pre_motion.target_angle; else target.post_motion.target_angle=source.post_motion.target_angle; break;
            case "wave_rotation_time": if(wave_phase==0) target.pre_motion.rotation_time=source.pre_motion.rotation_time; else target.post_motion.rotation_time=source.post_motion.rotation_time; break;
        }
    }
}

/// Follow is a coordinate-system conversion, not a copied boolean. Convert
/// every selected bone separately so each one keeps its own world position.
function BattleEditor_SetGroupBoneFollow(project,primary_index,enabled,target_uid,main_board_preview,group_type="",group_control_id="") {
    if(primary_index<0||primary_index>=array_length(project.events)) return;
    var source=project.events[primary_index];
    var source_group_uid=struct_exists(source,"control_uid")?source.control_uid:-1;
    for(var i=0;i<array_length(project.events);i++){
        var target=project.events[i];
        var same_group=string(group_control_id)!=""
            ?(BattleEditor_DataTargetType(target)==group_type&&(source_group_uid>=0
                ?(struct_exists(target,"control_uid")&&target.control_uid==source_group_uid)
                :(string(target.control_id)==string(group_control_id))))
            :BattleEditor_IsSameEventGroup(source,target);
        if(!same_group||target.preset!="bone") continue;
        BattleEditor_BoneSetFollow(target,enabled,project,main_board_preview,target_uid);
    }
}

function BattleEditor_TargetTypeName(target_type) {
    switch(target_type){
        case "bone":return "骨头";
        case "gb":return "GB";
        case "slash":return "斩击";
        case "true_knife":return "真刀";
        case "bone_3d":return "3D 骨";
        case "bone_4d":return "4D 骨";
        case "path_point":return "路径点";
        case "platform":return "蓝魂平台";
        case "board":return "战斗框";
        case "decoration":return "装饰";
        case "sprite_hazard":return "贴图弹幕";
        case "typewriter":return "打字机";
        case "enemy":return "敌人";
        case "player_data":return "玩家数据";
        case "soul":return "灵魂";
        case "hud_all":return "HUD 整体";
        case "hud_name":return "玩家名字";
        case "hud_lv":return "LV";
        case "hud_vitals":return "HP / KR / 护盾";
        case "battle_buttons":return "四个按钮";
        case "button_fight":return "战斗按钮";
        case "button_act":return "行动按钮";
        case "button_item":return "物品按钮";
        case "button_mercy":return "仁慈按钮";
    }
    return "对象";
}

function BattleEditor_ControlCategoryForType(target_type) {
    switch(target_type){
        case "player_data":return "game";
        case "soul":return "game";
        case "enemy":return "enemy";
        case "hud_all":
        case "hud_name":
        case "hud_lv":
        case "hud_vitals":
        case "battle_buttons":
        case "button_fight":
        case "button_act":
        case "button_item":
        case "button_mercy":return "interface";
        case "board":return "board";
        case "bone":
        case "gb":
        case "slash":
        case "true_knife":
        case "bone_3d":
        case "bone_4d":
        case "path_point":
        case "platform":
        case "sprite_hazard":return "hazard";
        case "decoration":
        case "typewriter":return "visual";
    }
    return "game";
}

function BattleEditor_ControlCategoryName(category) {
    switch(category){
        case "game":return "玩家与规则";
        case "enemy":return "敌人";
        case "interface":return "战斗界面";
        case "board":return "战斗框";
        case "hazard":return "攻击对象";
        case "visual":return "装饰与文字";
    }
    return "游戏与玩家";
}

function BattleEditor_ControlCategories() {
    return ["hazard","board","visual","enemy","game","interface"];
}

function BattleEditor_BuiltinActionGeneratedTargetType(project,step) {
    if(!is_struct(step)||!struct_exists(step,"action_name")) return "";
    if(step.action_name=="bone_function_path"&&struct_exists(step,"action_path_mode")&&round(real(step.action_path_mode))==1) return "";
    if(step.action_name=="bone_function_path"&&(!struct_exists(step,"action_source_uid")||real(step.action_source_uid)<0)&&(!struct_exists(step,"action_path_legacy_default")||!step.action_path_legacy_default)) return "";
    if(BattleEditor_BuiltinActionUsesTemplate(step.action_name)){
        var source_uid=struct_exists(step,"action_source_uid")?step.action_source_uid:-1;
        if(source_uid>=0){
            for(var event_index=0;event_index<array_length(project.events);event_index++){
                if(project.events[event_index].uid==source_uid) return BattleEditor_DataTargetType(project.events[event_index]);
            }
        }
        return "bone";
    }
    switch(step.action_name){
        case "bone_3d":return "bone_3d";
        case "bone_4d":return "bone_4d";
        case "gb_pinwheel":return "gb";
    }
    return "";
}

function BattleEditor_BuiltinActionControllerKind(action_name) {
    switch(string(action_name)){
        case "bone_orbit":return "bone_orbit";
        case "bone_wave":return "bone_wave";
        case "bone_corridor":return "bone_corridor";
        case "bone_physics":return "bone_physics";
        case "bone_function_path":return "bone_function_path";
        case "gb_pinwheel":return "gb_pinwheel";
        case "bone_wall":return "bone_wall";
    }
    return "";
}

function BattleEditor_ControlGroupName(group_kind) {
    switch(string(group_kind)){
        case "bone_orbit":return "旋转轨节点";
        case "bone_wave":return "波浪节点";
        case "bone_corridor":return "长廊节点";
        case "bone_physics":return "物理发射节点";
        case "bone_function_path":return "函数轨迹节点";
        case "gb_pinwheel":return "GB 风车节点";
        case "bone_wall":return "骨墙节点";
    }
    return "路径控制节点";
}

function BattleEditor_ControlSourceOptionLabel(option,copy_mode=false) {
    var option_group_kind=struct_exists(option,"group_kind")?string(option.group_kind):"";
    if(option_group_kind!="") return "构造控制点｜"+BattleEditor_ControlGroupName(option_group_kind)+"｜控制ID："+string(option.control_id);
    var source_name=struct_exists(option,"display_name")?string(option.display_name):BattleEditor_TargetTypeName(option.target_type);
    var source_type=BattleEditor_TargetTypeName(option.target_type);
    var runtime_count=struct_exists(option,"runtime_count")?max(0,round(real(option.runtime_count))):0;
    var source_kind="场景对象组";
    if(copy_mode) source_kind="复制来源";
    else if(runtime_count>=option.count&&runtime_count>0) source_kind="运行时对象组";
    else if(runtime_count>0) source_kind="场景＋运行时组";
    else if(!struct_exists(option,"display_name")) source_kind="系统对象";
    return source_kind+"｜"+source_name+"｜"+source_type+" ×"+string(option.count)+"｜"+(copy_mode?"原":"")+"控制ID："+string(option.control_id);
}

/// Size the popup once when it opens. It may grow beyond the inspector for
/// long author names, but a hard cap keeps it from swallowing the workspace.
function BattleEditor_ControlSourcePopupLeft(options,copy_mode=false) {
    var popup_width=338;
    for(var option_index=0;option_index<array_length(options);option_index++){
        var option_width=ceil(TextTyper_StringWidthFallback(BattleEditor_ControlSourceOptionLabel(options[option_index],copy_mode)))+14;
        popup_width=max(popup_width,option_width);
    }
    popup_width=clamp(popup_width,338,430);
    return 638-popup_width;
}

function BattleEditor_ControlTargetOptions(project,category="") {
    var result=[];
    // System-provided battle objects are real runtime targets even though the
    // author does not need to create them on the scene timeline first.
    array_push(result,{control_id:"player",target_type:"player_data",count:1,runtime_count:0});
    array_push(result,{control_id:"soul",target_type:"soul",count:1,runtime_count:0});
    array_push(result,{control_id:"hud",target_type:"hud_all",count:1,runtime_count:0});
    array_push(result,{control_id:"hud",target_type:"hud_name",count:1,runtime_count:0});
    array_push(result,{control_id:"hud",target_type:"hud_lv",count:1,runtime_count:0});
    array_push(result,{control_id:"hud",target_type:"hud_vitals",count:1,runtime_count:0});
    array_push(result,{control_id:"battle_buttons",target_type:"battle_buttons",count:4,runtime_count:0});
    array_push(result,{control_id:"battle_buttons",target_type:"button_fight",count:1,runtime_count:0});
    array_push(result,{control_id:"battle_buttons",target_type:"button_act",count:1,runtime_count:0});
    array_push(result,{control_id:"battle_buttons",target_type:"button_item",count:1,runtime_count:0});
    array_push(result,{control_id:"battle_buttons",target_type:"button_mercy",count:1,runtime_count:0});
    var source_data=[];
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    array_push(source_data,project.initialization.board);
    for(var frame_index=0;frame_index<array_length(project.initialization.frames);frame_index++) array_push(source_data,project.initialization.frames[frame_index]);
    for(var enemy_index=0;enemy_index<array_length(project.initialization.enemies);enemy_index++) array_push(source_data,project.initialization.enemies[enemy_index]);
    for(var event_index=0;event_index<array_length(project.events);event_index++) if(BattleEditor_EventBelongsToTurn(project.events[event_index],authoring_turn)) array_push(source_data,project.events[event_index]);
    for(var source_index=0;source_index<array_length(source_data);source_index++){
        var data=source_data[source_index];
        var id_text=struct_exists(data,"control_id")?string(data.control_id):"";
        if(string_length(id_text)<=0) continue;
        var type_key=BattleEditor_DataTargetType(data);
        var data_control_uid=struct_exists(data,"control_uid")?data.control_uid:-1;
        var found_index=-1;
        for(var i=0;i<array_length(result);i++){
            var option_control_uid=struct_exists(result[i],"group_uid")?result[i].group_uid:-1;
            if(result[i].target_type==type_key&&((data_control_uid>=0&&option_control_uid==data_control_uid)||(data_control_uid<0&&option_control_uid<0&&result[i].control_id==id_text))){found_index=i;break;}
        }
        var data_name=struct_exists(data,"name")?string(data.name):BattleEditor_TargetTypeName(type_key);
        if(found_index>=0){
            result[found_index].count+=1;
            if(!struct_exists(result[found_index],"display_name")) result[found_index].display_name=data_name;
        }
        else array_push(result,{control_id:id_text,target_type:type_key,group_uid:data_control_uid,display_name:data_name,count:1,runtime_count:0});
    }
    // Constructor output is a real Control-ID target even though it does not
    // exist on the scene timeline yet. Keep the generated member group and its
    // algorithm controller as two explicit capabilities: the former controls
    // the objects, while the latter controls the path/centre/shape parameters.
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        if(!is_struct(list_data)||!struct_exists(list_data,"steps")||!is_array(list_data.steps)) continue;
        if(!BattleEditor_ScriptListBelongsToTurn(list_data,authoring_turn)) continue;
        for(var step_index=0;step_index<array_length(list_data.steps);step_index++){
            var step_data=list_data.steps[step_index];
            if(!is_struct(step_data)||!struct_exists(step_data,"kind")) continue;
            if(step_data.kind=="control_object"&&struct_exists(step_data,"control_source_mode")&&round(real(step_data.control_source_mode))==1){
                var copy_id=struct_exists(step_data,"copy_control_id")?string(step_data.copy_control_id):"";
                var copy_type=struct_exists(step_data,"target_type")?string(step_data.target_type):"";
                if(copy_id!=""&&copy_type!=""){
                    var copy_group_uid=struct_exists(step_data,"target_group_uid")?step_data.target_group_uid:-1;
                    var copy_count=BattleEditor_ControlCloneSourceCount(project,step_data.target,copy_type,copy_group_uid);
                    var copy_found=-1;
                    for(var copy_option_index=0;copy_option_index<array_length(result);copy_option_index++) if(result[copy_option_index].control_id==copy_id&&result[copy_option_index].target_type==copy_type){copy_found=copy_option_index;break;}
                    if(copy_found>=0){result[copy_found].count+=copy_count;result[copy_found].runtime_count+=copy_count;}
                    else array_push(result,{control_id:copy_id,target_type:copy_type,count:copy_count,runtime_count:copy_count});
                }
                continue;
            }
            if(step_data.kind=="create_object"){
                var create_id=struct_exists(step_data,"create_control_id")?string(step_data.create_control_id):"";
                var create_type=BattleEditor_WorkspaceCreateTargetType(struct_exists(step_data,"create_preset")?step_data.create_preset:"bone");
                if(create_id!=""){
                    var create_found=-1;
                    for(var create_option_index=0;create_option_index<array_length(result);create_option_index++) if(result[create_option_index].control_id==create_id&&result[create_option_index].target_type==create_type){create_found=create_option_index;break;}
                    if(create_found>=0){result[create_found].count+=1;result[create_found].runtime_count+=1;}
                    else array_push(result,{control_id:create_id,target_type:create_type,count:1,runtime_count:1});
                }
                continue;
            }
            if(step_data.kind!="builtin_action") continue;
            var generated_type=BattleEditor_BuiltinActionGeneratedTargetType(project,step_data);
            var generated_id=struct_exists(step_data,"action_control_id")?string(step_data.action_control_id):"";
            if(generated_type!=""&&generated_id!=""){
                var generated_found=-1;
                for(var option_index=0;option_index<array_length(result);option_index++) if(result[option_index].control_id==generated_id&&result[option_index].target_type==generated_type){generated_found=option_index;break;}
                var generated_count=BattleEditor_BuiltinActionGeneratedCount(project,step_data);
                if(generated_found>=0){result[generated_found].count+=generated_count;result[generated_found].runtime_count+=generated_count;}
                else array_push(result,{control_id:generated_id,target_type:generated_type,display_name:BattleEditor_BuiltinActionName(step_data.action_name),count:generated_count,runtime_count:generated_count});
            }
            var controller_kind=BattleEditor_BuiltinActionControllerKind(step_data.action_name);
            if(controller_kind!=""&&generated_id!=""){
                var point_found=-1;
                for(var point_option_index=0;point_option_index<array_length(result);point_option_index++){
                    var point_kind=struct_exists(result[point_option_index],"group_kind")?string(result[point_option_index].group_kind):"";
                    if(result[point_option_index].control_id==generated_id&&result[point_option_index].target_type=="path_point"&&point_kind==controller_kind){point_found=point_option_index;break;}
                }
                if(point_found>=0){result[point_found].count+=1;result[point_found].runtime_count+=1;}
                else array_push(result,{control_id:generated_id,target_type:"path_point",group_kind:controller_kind,count:1,runtime_count:1});
            }
        }
    }
    if(string_length(string(category))<=0) return result;
    var filtered=[];
    for(var option_index=0;option_index<array_length(result);option_index++){
        var option=result[option_index];
        if(BattleEditor_ControlCategoryForType(option.target_type)==category) array_push(filtered,option);
    }
    return filtered;
}

/// Copy-mode sources are authored, instantiable scene events only. System
/// targets (board, soul, HUD, enemies and buttons) remain controllable but are
/// deliberately absent here, so this mode cannot accidentally duplicate them.
function BattleEditor_ControlCloneSourceOptions(project,category="") {
    var result=[];
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    for(var event_index=0;event_index<array_length(project.events);event_index++){
        var data=project.events[event_index];
        if(!BattleEditor_EventBelongsToTurn(data,authoring_turn)) continue;
        var id_text=struct_exists(data,"control_id")?string(data.control_id):"";
        var type_key=BattleEditor_DataTargetType(data);
        if(id_text==""||type_key=="") continue;
        if(category!=""&&BattleEditor_ControlCategoryForType(type_key)!=category) continue;
        var data_control_uid=struct_exists(data,"control_uid")?data.control_uid:-1;
        var found=-1;
        for(var option_index=0;option_index<array_length(result);option_index++){
            var option_control_uid=struct_exists(result[option_index],"group_uid")?result[option_index].group_uid:-1;
            if(result[option_index].target_type==type_key&&((data_control_uid>=0&&option_control_uid==data_control_uid)||(data_control_uid<0&&option_control_uid<0&&result[option_index].control_id==id_text))){found=option_index;break;}
        }
        var object_name=struct_exists(data,"name")?string(data.name):BattleEditor_TargetTypeName(type_key);
        if(found>=0) result[found].count+=1;
        else array_push(result,{control_id:id_text,target_type:type_key,group_uid:data_control_uid,display_name:object_name,count:1,runtime_count:0});
    }
    return result;
}

function BattleEditor_ControlCloneSourceCount(project,control_id,target_type,group_uid=-1) {
    var count=0;
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    for(var event_index=0;event_index<array_length(project.events);event_index++){
        var data=project.events[event_index];
        if(!BattleEditor_EventBelongsToTurn(data,authoring_turn)) continue;
        var identity_matches=group_uid>=0
            ?(struct_exists(data,"control_uid")&&data.control_uid==group_uid)
            :(struct_exists(data,"control_id")&&string(data.control_id)==string(control_id));
        if(identity_matches&&BattleEditor_DataTargetType(data)==target_type) count+=1;
    }
    return count;
}

/// Read the authored follow state behind a Control-ID option.  Runtime-created
/// groups do not have a scene instance while the inspector is open, so their
/// Create Object template is the source of truth.  This prevents a freshly
/// selected Follow control from lying that the default-following object is off.
function BattleEditor_ControlFollowSourceState(project,step) {
    var result={enabled:false,frame_uid:-1};
    if(!is_struct(project)||!is_struct(step)) return result;
    var wanted_id=string(step.target),wanted_type=string(step.target_type);
    var wanted_group=struct_exists(step,"target_group_uid")?step.target_group_uid:-1;
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    for(var event_index=0;event_index<array_length(project.events);event_index++){
        var source=project.events[event_index];
        if(!BattleEditor_EventBelongsToTurn(source,authoring_turn)) continue;
        var identity_matches=wanted_group>=0
            ?(struct_exists(source,"control_uid")&&source.control_uid==wanted_group)
            :(struct_exists(source,"control_id")&&string(source.control_id)==wanted_id);
        if(!identity_matches||BattleEditor_DataTargetType(source)!=wanted_type) continue;
        result.enabled=struct_exists(source,"follow")&&source.follow;
        result.frame_uid=struct_exists(source,"follow_target_uid")?source.follow_target_uid:-1;
        return result;
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var list_data=project.script_lists[list_index];
        if(!BattleEditor_ScriptListBelongsToTurn(list_data,authoring_turn)) continue;
        for(var step_index=0;step_index<array_length(list_data.steps);step_index++){
            var source_step=list_data.steps[step_index];
            if(source_step.kind=="create_object"
            &&string(source_step.create_control_id)==wanted_id
            &&BattleEditor_WorkspaceCreateTargetType(source_step.create_preset)==wanted_type){
                var source_template=BattleEditor_WorkspaceCreateNormalizeTemplate(source_step);
                result.enabled=struct_exists(source_template,"follow")&&source_template.follow;
                result.frame_uid=struct_exists(source_template,"follow_target_uid")?source_template.follow_target_uid:-1;
                return result;
            }
            if(source_step.kind=="builtin_action"
            &&string(source_step.action_control_id)==wanted_id
            &&BattleEditor_BuiltinActionGeneratedTargetType(project,source_step)==wanted_type){
                result.enabled=struct_exists(source_step,"action_follow")&&source_step.action_follow;
                result.frame_uid=-1;
                return result;
            }
        }
    }
    return result;
}

/// Initialize a Follow operation once per selected target. Switching away and
/// back keeps the author's edited value; selecting another target reads that
/// target's actual authored source state again.
function BattleEditor_ControlFollowApplySourceDefault(project,step,force=false) {
    if(!is_struct(step)||step.property!="follow") return false;
    if(!force&&struct_exists(step,"follow_value_initialized")&&step.follow_value_initialized) return false;
    var source_state=BattleEditor_ControlFollowSourceState(project,step);
    step.value=source_state.enabled?1:0;
    step.follow_target_uid=source_state.frame_uid;
    step.follow_value_initialized=true;
    return true;
}

function BattleEditor_ControlSourceOptions(project,step) {
    if(is_struct(step)&&struct_exists(step,"control_source_mode")&&round(real(step.control_source_mode))==1) return BattleEditor_ControlCloneSourceOptions(project,step.target_category);
    return BattleEditor_ControlTargetOptions(project,step.target_category);
}

function BattleEditor_BoardControlSource(project,step) {
    if(!is_struct(step)||step.target_type!="board") return undefined;
    var sources=BattleEditor_AuthoredControlSources(project);
    for(var source_index=0;source_index<array_length(sources);source_index++){
        var source=sources[source_index];
        if(BattleEditor_DataTargetType(source)!="board") continue;
        var matches=struct_exists(step,"target_group_uid")&&step.target_group_uid>=0
            ?(struct_exists(source,"control_uid")&&source.control_uid==step.target_group_uid)
            :(struct_exists(source,"control_id")&&string(source.control_id)==string(step.target));
        if(matches) return source;
    }
    return undefined;
}

function BattleEditor_BoardDataBounds(frame) {
    if(is_undefined(frame)||!is_struct(frame)) return [80,80];
    if(struct_exists(frame,"shape")&&frame.shape=="circle") return [max(0,real(frame.radius_x))*2,max(0,real(frame.radius_y))*2];
    if(struct_exists(frame,"shape")&&frame.shape=="rect") return [max(0,real(frame.left)+real(frame.right)),max(0,real(frame.up)+real(frame.down))];
    if(struct_exists(frame,"shape")&&frame.shape=="triangle"){
        var triangle_size=max(0,real(frame.triangle_size));
        return [triangle_size*1.7320508075688772,triangle_size*1.5];
    }
    if(struct_exists(frame,"vertices")&&is_array(frame.vertices)&&array_length(frame.vertices)>0){
        var min_x=real(frame.vertices[0][0]),max_x=min_x,min_y=real(frame.vertices[0][1]),max_y=min_y;
        for(var vertex_index=1;vertex_index<array_length(frame.vertices);vertex_index++){
            min_x=min(min_x,real(frame.vertices[vertex_index][0]));max_x=max(max_x,real(frame.vertices[vertex_index][0]));
            min_y=min(min_y,real(frame.vertices[vertex_index][1]));max_y=max(max_y,real(frame.vertices[vertex_index][1]));
        }
        return [max(0,max_x-min_x),max(0,max_y-min_y)];
    }
    return [80,80];
}

/// Populate frame controls from the authored target instead of showing a
/// mystery zero or the generic 80x80 placeholder after target selection.
function BattleEditor_ApplyBoardControlDefaults(project,step) {
    var frame=BattleEditor_BoardControlSource(project,step);
    if(is_undefined(frame)) return false;
    var bounds=BattleEditor_BoardDataBounds(frame);
    step.board_shape_width=string(bounds[0]);step.board_shape_height=string(bounds[1]);
    step.board_shape_radius_x=string(bounds[0]*0.5);step.board_shape_radius_y=string(bounds[1]*0.5);
    step.board_shape_triangle_width=string(bounds[0]);step.board_shape_triangle_height=string(bounds[1]);
    step.position_x=string(frame.x);step.position_y=string(frame.y);step.position_angle=string(frame.angle);
    step.board_transform_width=string(bounds[0]);step.board_transform_height=string(bounds[1]);
    if(step.property=="rotate") step.value=string(frame.rotate);
    return true;
}

function BattleEditor_BuiltinActionGeneratedCount(project,step) {
    if(!is_struct(step)||!struct_exists(step,"action_name")) return 0;
    var p=BattleEditor_ActionParts(step.action_arguments);
    switch(step.action_name){
        case "bone_orbit":return max(1,round(BattleEditor_ActionNumber(project,p,4,12)));
        case "bone_wave":return max(1,round(BattleEditor_ActionNumber(project,p,4,12)));
        case "bone_corridor":return max(1,round(BattleEditor_ActionNumber(project,p,3,12)))*2;
        case "bone_physics":return max(1,round(BattleEditor_ActionNumber(project,p,2,18)));
        case "bone_wall":
            var wall_count=max(1,round(BattleEditor_ActionNumber(project,p,2,24)));
            var wall_direction=struct_exists(step,"action_direction")?clamp(round(step.action_direction),1,7):1;
            return wall_count*(wall_direction==7?4:(wall_direction>=5?2:1));
        case "bone_function_path":case "bone_3d":case "bone_4d":return 1;
        case "gb_pinwheel":return max(1,round(BattleEditor_ActionNumber(project,p,4,8)));
    }
    return 0;
}

function BattleEditor_ValueTargetOptions(project) {
    var result=[
        {key:"time",uid:-1,target_type:"time",name:"时间与回合"},
        {key:"player",uid:-1,target_type:"player_data",name:"玩家数值"},
        {key:"soul",uid:-1,target_type:"soul",name:"玩家灵魂"},
        {key:"shield",uid:-1,target_type:"shield",name:"护盾"}
    ];
    var exact_targets=BattleEditor_AimTargetOptions(project,-1);
    for(var i=0;i<array_length(exact_targets);i++){
        var source=exact_targets[i];
        array_push(result,{key:"object",uid:source.uid,target_type:source.target_type,name:"["+BattleEditor_TargetTypeName(source.target_type)+"] "+source.name});
    }
    return result;
}

function BattleEditor_ValueTargetCaption(project,step) {
    var options=BattleEditor_ValueTargetOptions(project);
    for(var i=0;i<array_length(options);i++) if(options[i].key==step.read_target_key&&options[i].uid==step.read_target_uid) return options[i].name;
    return "选择数值来源";
}

function BattleEditor_ValueProperties(target_key,target_type) {
    switch(target_key){
        case "time":return ["time","turn"];
        case "player":return ["player_hp","player_max_hp","player_natural_max_hp","player_kr","player_lv","player_atk","player_def"];
        case "shield":return ["shield_value","shield_max","shield_natural_max"];
        case "soul":return ["x","y","angle"];
    }
    var result=["x","y","angle"];
    var source=BattleEditor_ControlPropertiesAllForType(target_type);
    var excluded=["position","orbit","physics","control_vertex","shape","player_name","text","color","follow","follow_board","follow_angle","aim_enabled","aim_target_uid","aim_continuous","aim_move_enabled","green_guard_blockable","green_guard_destroy_on_block"];
    for(var i=0;i<array_length(source);i++){
        var property=source[i],skip=false;
        for(var j=0;j<array_length(excluded);j++) if(property==excluded[j]){skip=true;break;}
        if(skip) continue;
        var exists=false;
        for(var j=0;j<array_length(result);j++) if(result[j]==property){exists=true;break;}
        if(!exists) array_push(result,property);
    }
    return result;
}

function BattleEditor_ValuePropertyName(property) {
    switch(property){
        case "time":return "当前时间（帧）";
        case "turn":return "当前怪物回合";
        case "player_kr":return "当前 KR";
        case "x":return "X 坐标";
        case "y":return "Y 坐标";
        case "angle":return "角度";
    }
    return BattleEditor_ControlPropertyName(property);
}

function BattleEditor_ValueToken(target_key,target_uid,property) {
    if(target_key=="object") return "obj_"+string(target_uid)+"_"+string(property);
    if(target_key=="soul"&&(property=="x"||property=="y"||property=="angle")) return "soul_"+property;
    return string(property);
}

function BattleEditor_VariableNameConflict(project,name,except_uid=-1) {
    name=string_trim(string(name));
    if(name=="") return false;
    if(BattleEditor_IsReservedVariableName(name)) return true;
    for(var i=0;i<array_length(project.variables);i++) if(string_trim(string(project.variables[i].name))==name) return true;
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++){
        var steps=project.script_lists[list_index].steps;
        for(var step_index=0;step_index<array_length(steps);step_index++){
            var other_step=steps[step_index];
            if(other_step.uid==except_uid) continue;
            if(other_step.kind=="set_variable"&&string_trim(string(other_step.variable_name))==name) return true;
            if(other_step.kind=="get_value"&&string_trim(string(other_step.read_variable_name))==name) return true;
        }
    }
    return false;
}

function BattleEditor_IsReservedVariableName(name) {
    name=string_trim(string(name));
    var system_names=["time","turn","t","progress","player_hp","player_max_hp","player_natural_max_hp","player_kr","player_lv","player_atk","player_def","shield_value","shield_max","shield_natural_max","soul_x","soul_y","soul_angle","pi","e"];
    for(var i=0;i<array_length(system_names);i++) if(name==system_names[i]) return true;
    return false;
}

function BattleEditor_IsVariableIdentifier(name) {
    name=string_trim(string(name));
    if(name=="") return false;
    for(var i=1;i<=string_length(name);i++){
        var ch=string_char_at(name,i),lower=string_lower(ch);
        var valid=(lower>="a"&&lower<="z")||ord(ch)>127||ch=="_"||(i>1&&ch>="0"&&ch<="9");
        if(!valid) return false;
    }
    return true;
}

function BattleEditor_FunctionPathVariableNameValid(name) {
    name=string_trim(string(name));
    if(!BattleEditor_IsVariableIdentifier(name)) return false;
    // These names are evaluated as constants or as the independent normalized
    // curve progress, so reusing them as the sampled parameter would lie to
    // the author. Every ordinary project/runtime name may be shadowed.
    var lower_name=string_lower(name);
    return lower_name!="pi"&&lower_name!="e"&&lower_name!="progress";
}

function BattleEditor_FunctionPathVariableName(step_or_pattern) {
    if(is_struct(step_or_pattern)&&struct_exists(step_or_pattern,"parameter_name")&&BattleEditor_FunctionPathVariableNameValid(step_or_pattern.parameter_name)) return string_trim(string(step_or_pattern.parameter_name));
    if(is_struct(step_or_pattern)&&struct_exists(step_or_pattern,"action_path_variable")&&BattleEditor_FunctionPathVariableNameValid(step_or_pattern.action_path_variable)) return string_trim(string(step_or_pattern.action_path_variable));
    return "t";
}

/// Formula validation and the insertion menu need the same local scope as the
/// runtime sampler. Only X/Y curve expressions receive the sampled variable;
/// base coordinates and duration remain ordinary project formulas.
function BattleEditor_ExpressionVariablesForFormula(project_or_controller,step,field) {
    var result=BattleEditor_ExpressionVariables(project_or_controller);
    if(is_struct(step)&&struct_exists(step,"kind")&&step.kind=="builtin_action"&&step.action_name=="bone_function_path"){
        if(field=="script_action_param_0"||field=="script_action_param_1"){
            variable_struct_set(result,"X",0);
            variable_struct_set(result,"Y",0);
        }
        if(field=="script_action_param_2"||field=="script_action_param_3") variable_struct_set(result,BattleEditor_FunctionPathVariableName(step),0);
    }
    return result;
}

function BattleEditor_FindProjectValueData(project,target_uid) {
    if(struct_exists(project.initialization.board,"uid")&&project.initialization.board.uid==target_uid) return project.initialization.board;
    for(var i=0;i<array_length(project.initialization.frames);i++) if(project.initialization.frames[i].uid==target_uid) return project.initialization.frames[i];
    for(var i=0;i<array_length(project.initialization.enemies);i++) if(project.initialization.enemies[i].uid==target_uid) return project.initialization.enemies[i];
    for(var i=0;i<array_length(project.events);i++) if(project.events[i].uid==target_uid) return project.events[i];
    return undefined;
}

function BattleEditor_FindRuntimeValueTarget(controller,target_uid) {
    if(!is_undefined(controller)&&instance_exists(controller)){
        for(var i=0;i<array_length(controller.runtime_instances);i++){
            var candidate=controller.runtime_instances[i];
            if(instance_exists(candidate)&&variable_instance_exists(candidate,"editor_uid")&&candidate.editor_uid==target_uid) return candidate;
        }
        if(instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&variable_struct_exists(battle_board.mainboard,"editor_uid")&&battle_board.mainboard.editor_uid==target_uid) return battle_board.mainboard;
        for(var i=0;i<array_length(controller.preview_frames);i++){
            var frame=controller.preview_frames[i];
            if(is_struct(frame)&&variable_struct_exists(frame,"editor_uid")&&frame.editor_uid==target_uid) return frame;
        }
    }
    return undefined;
}

function BattleEditor_ReadNumericProperty(target,target_type,property,fallback=0) {
    if(is_undefined(target)) return fallback;
    if(property=="angle"){
        var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
        if(is_struct(target)&&variable_struct_exists(target,angle_property)) return variable_struct_get(target,angle_property);
        if(!is_struct(target)&&instance_exists(target)&&variable_instance_exists(target,angle_property)) return variable_instance_get(target,angle_property);
        if(is_struct(target)&&variable_struct_exists(target,"transform")) return target.transform.angle;
        return fallback;
    }
    if(is_struct(target)&&variable_struct_exists(target,"transform")&&(property=="x"||property=="y"||property=="scale_x"||property=="scale_y"||property=="alpha")) return variable_struct_get(target.transform,property);
    if(is_struct(target)&&variable_struct_exists(target,"damage_profile")){
        if(property=="damage"&&variable_struct_exists(target.damage_profile,"damage")) return target.damage_profile.damage;
        if(property=="damage_type"&&variable_struct_exists(target.damage_profile,"type")) return target.damage_profile.type;
        if(property=="heal_amount"&&variable_struct_exists(target.damage_profile,"heal_amount")) return target.damage_profile.heal_amount;
    }
    if(property=="damage") property="hp_damage";
    else if(property=="damage_type") property="type";
    else if(property=="layer_mode") property="out";
    else if(target_type=="bone_3d"||target_type=="bone_4d"){
        switch(property){
            case "angle_x":property="anglex";break;
            case "angle_y":property="angley";break;
            case "angle_z":property="anglez";break;
            case "angle_xw":property="anglexw";break;
            case "angle_yw":property="angleyw";break;
            case "angle_zw":property="anglezw";break;
            case "rotate_x":property="angxs";break;
            case "rotate_y":property="angys";break;
            case "rotate_z":property="angzs";break;
            case "rotate_xw":property="angxws";break;
            case "rotate_yw":property="angyws";break;
            case "rotate_zw":property="angzws";break;
            case "size_x":property="scalex";break;
            case "size_y":property="scaley";break;
            case "size_z":property="scalez";break;
            case "size_w":property="scalew";break;
        }
    }
    if(is_struct(target)&&variable_struct_exists(target,property)){
        var struct_value=variable_struct_get(target,property);
        return is_real(struct_value)?struct_value:fallback;
    }
    if(!is_struct(target)&&instance_exists(target)&&variable_instance_exists(target,property)){
        var instance_value=variable_instance_get(target,property);
        return is_real(instance_value)?instance_value:fallback;
    }
    return fallback;
}

function BattleEditor_AppendBuiltinExpressionVariables(result,project,controller=undefined) {
    var runtime=!is_undefined(controller)&&instance_exists(controller);
    variable_struct_set(result,"time",runtime?controller.playhead:0);
    variable_struct_set(result,"turn",runtime?controller.script_monster_turn:1);
    // Function-path actions replace these two values only while sampling their
    // own curve. Declaring them here keeps editor formula validation readable.
    variable_struct_set(result,"t",0);
    variable_struct_set(result,"progress",0);
    variable_struct_set(result,"player_hp",Player_GetHp());
    variable_struct_set(result,"player_max_hp",Player_GetHpMax());
    variable_struct_set(result,"player_natural_max_hp",Player_GetNaturalHpMax());
    variable_struct_set(result,"player_kr",global.kr?Player_GetKr():0);
    variable_struct_set(result,"player_lv",Player_GetLv());
    variable_struct_set(result,"player_atk",Player_GetAtk());
    variable_struct_set(result,"player_def",Player_GetDef());
    variable_struct_set(result,"shield_value",instance_exists(battle)&&variable_instance_exists(battle,"_shield")?battle._shield:0);
    variable_struct_set(result,"shield_max",instance_exists(battle)&&variable_instance_exists(battle,"_shield_max")?battle._shield_max:0);
    variable_struct_set(result,"shield_natural_max",instance_exists(battle)&&variable_instance_exists(battle,"_shield_natural_max")?battle._shield_natural_max:0);
    var soul_instance=instance_exists(battle_soul)?instance_find(battle_soul,0):noone;
    variable_struct_set(result,"soul_x",instance_exists(soul_instance)?soul_instance.x:320);
    variable_struct_set(result,"soul_y",instance_exists(soul_instance)?soul_instance.y:240);
    variable_struct_set(result,"soul_angle",instance_exists(soul_instance)&&variable_instance_exists(soul_instance,"angle")?soul_instance.angle:0);
    var value_targets=BattleEditor_ValueTargetOptions(project);
    for(var target_index=0;target_index<array_length(value_targets);target_index++){
        var option=value_targets[target_index];
        if(option.key!="object") continue;
        var source=BattleEditor_FindProjectValueData(project,option.uid);
        var live_target=runtime?BattleEditor_FindRuntimeValueTarget(controller,option.uid):undefined;
        var properties=BattleEditor_ValueProperties("object",option.target_type);
        for(var property_index=0;property_index<array_length(properties);property_index++){
            var property=properties[property_index];
            var fallback=BattleEditor_ReadNumericProperty(source,option.target_type,property,0);
            variable_struct_set(result,BattleEditor_ValueToken("object",option.uid,property),BattleEditor_ReadNumericProperty(live_target,option.target_type,property,fallback));
        }
    }
}

function BattleEditor_FormulaVariableOptions(project,step=undefined,field="") {
    var result=[];
    var local_path_name="";
    if(is_struct(step)&&struct_exists(step,"kind")&&step.kind=="builtin_action"&&step.action_name=="bone_function_path"
        &&(field=="script_action_param_0"||field=="script_action_param_1")){
        array_push(result,{token:"X",label:"函数轨迹 / 当前对象组中心 X"});
        array_push(result,{token:"Y",label:"函数轨迹 / 当前对象组中心 Y"});
    }
    if(is_struct(step)&&struct_exists(step,"kind")&&step.kind=="builtin_action"&&step.action_name=="bone_function_path"
        &&(field=="script_action_param_2"||field=="script_action_param_3")){
        local_path_name=BattleEditor_FunctionPathVariableName(step);
        array_push(result,{token:local_path_name,label:"函数局部自变量 / "+local_path_name+"（覆盖同名外部变量）"});
    }
    var builtin_options=[
        {token:"time",label:"时间 / 当前帧"},{token:"turn",label:"回合 / 当前怪物回合"},
        {token:"progress",label:"函数轨迹 / 进度 0~1"},
        {token:"soul_x",label:"灵魂 / X 坐标"},{token:"soul_y",label:"灵魂 / Y 坐标"},{token:"soul_angle",label:"灵魂 / 角度"},
        {token:"player_hp",label:"玩家 / 当前 HP"},{token:"player_max_hp",label:"玩家 / 当前 HP 上限"},{token:"player_natural_max_hp",label:"玩家 / 原始 HP 上限"},{token:"player_kr",label:"玩家 / 当前 KR"},
        {token:"player_lv",label:"玩家 / LV"},{token:"player_atk",label:"玩家 / ATK"},{token:"player_def",label:"玩家 / DEF"},
        {token:"shield_value",label:"护盾 / 当前值"},{token:"shield_max",label:"护盾 / 当前上限"},{token:"shield_natural_max",label:"护盾 / 自然上限"}
    ];
    for(var builtin_index=0;builtin_index<array_length(builtin_options);builtin_index++) if(builtin_options[builtin_index].token!=local_path_name) array_push(result,builtin_options[builtin_index]);
    for(var variable_index=0;variable_index<array_length(project.variables);variable_index++){
        var project_variable_name=string(project.variables[variable_index].name);
        if(project_variable_name!=local_path_name) array_push(result,{token:project_variable_name,label:"自定变量 / "+project_variable_name});
    }
    for(var list_index=0;list_index<array_length(project.script_lists);list_index++) for(var step_index=0;step_index<array_length(project.script_lists[list_index].steps);step_index++){
        var listed_step=project.script_lists[list_index].steps[step_index];
        var authored_name=listed_step.kind=="set_variable"?listed_step.variable_name:(listed_step.kind=="get_value"?listed_step.read_variable_name:"");
        if(string_length(string_trim(string(authored_name)))>0&&string(authored_name)!=local_path_name) array_push(result,{token:string(authored_name),label:"脚本变量 / "+string(authored_name)});
    }
    var targets=BattleEditor_ValueTargetOptions(project);
    for(var target_index=0;target_index<array_length(targets);target_index++){
        var target=targets[target_index];
        if(target.key!="object") continue;
        var properties=BattleEditor_ValueProperties(target.key,target.target_type);
        for(var property_index=0;property_index<array_length(properties);property_index++){
            var property=properties[property_index];
            array_push(result,{token:BattleEditor_ValueToken(target.key,target.uid,property),label:target.name+" / "+BattleEditor_ValuePropertyName(property)});
        }
    }
    return result;
}

function BattleEditor_FormulaHelpLines() {
    return [
        "运算：+  -  *  /  (  )",
        "常量：pi、e",
        "sin(x)、cos(x)、tan(x)  使用角度",
        "sqrt(x)、abs(x)、floor(x)、ceil(x)、round(x)",
        "log(x)、ln(x)",
        "min(a,b)、max(a,b)、clamp(x,min,max)",
        "pow(a,b) / power(a,b)",
        "random(max) / random(min,max)",
        "变量：在公式输入框上点右键浏览并插入",
        "空白公式允许保存；运行时由该参数自己的默认值处理"
    ];
}

/// Cache wrapping by font; help drawing and hit testing share the same bounds.
function BattleEditor_FormulaHelpLayout() {
    static cached=undefined;
    var font=draw_get_font();
    if(is_undefined(cached)||cached.font!=font){
        var source=BattleEditor_FormulaHelpLines(),lines=[];
        for(var i=0;i<array_length(source);i++){
            var wrapped=TextTyper_WrapFallbackLines(source[i],344,font);
            for(var j=0;j<array_length(wrapped);j++) array_push(lines,wrapped[j]);
        }
        cached={font:font,lines:lines,bottom:58+array_length(lines)*20+8};
    }
    return cached;
}

function BattleEditor_RuntimeGetValue(controller,step) {
    var name=string_trim(string(step.read_variable_name));
    if(!BattleEditor_IsVariableIdentifier(name)||BattleEditor_IsReservedVariableName(name)) return false;
    if(BattleEditor_VariableNameConflict(controller.project,name,step.uid)&&!step.read_overwrite_confirmed) return false;
    var token=BattleEditor_ValueToken(step.read_target_key,step.read_target_uid,step.read_property);
    var variables=BattleEditor_ExpressionVariables(controller);
    if(!variable_struct_exists(variables,token)) return false;
    variable_struct_set(variables,name,variable_struct_get(variables,token));
    controller.runtime_variables=variables;
    return true;
}

/// UID-based target list for persistent pointing. Names are author-facing;
/// duplicate display names remain safe because the saved reference is the UID.
function BattleEditor_AimTargetOptions(project,self_uid=-1) {
    var result=[{uid:-2,name:"玩家",target_type:"soul"}];
    var source_data=[];
    var authoring_turn=struct_exists(project,"settings")&&struct_exists(project.settings,"developer_turn")?project.settings.developer_turn:1;
    array_push(source_data,project.initialization.board);
    for(var frame_index=0;frame_index<array_length(project.initialization.frames);frame_index++) array_push(source_data,project.initialization.frames[frame_index]);
    for(var enemy_index=0;enemy_index<array_length(project.initialization.enemies);enemy_index++) array_push(source_data,project.initialization.enemies[enemy_index]);
    for(var event_index=0;event_index<array_length(project.events);event_index++) if(BattleEditor_EventBelongsToTurn(project.events[event_index],authoring_turn)) array_push(source_data,project.events[event_index]);
    for(var source_index=0;source_index<array_length(source_data);source_index++){
        var data=source_data[source_index];
        if(!struct_exists(data,"uid")||data.uid==self_uid) continue;
        array_push(result,{uid:data.uid,name:struct_exists(data,"name")?string(data.name):"对象",target_type:BattleEditor_DataTargetType(data)});
    }
    return result;
}

function BattleEditor_AimTargetCaption(project,target_uid) {
    var options=BattleEditor_AimTargetOptions(project,-1);
    for(var i=0;i<array_length(options);i++){
        if(options[i].uid==target_uid) return BattleEditor_TargetTypeName(options[i].target_type)+" / "+options[i].name;
    }
    return "未选择目标";
}

function BattleEditor_ControlPropertiesAllForTypeBase(target_type) {
    switch(target_type){
        case "path_point":return ["position","orbit","physics"];
        case "bone":return ["position","orbit","physics","rotate","length","bone_style","hspeed","vspeed","duration","damage_type","damage","heal_amount","visual_color","layer_mode","follow","follow_board","follow_angle","green_guard_blockable","green_guard_destroy_on_block"];
        case "gb":return ["position","physics","follow","gb_hold","gb_release","scale_x","scale_y","aim_x","aim_y","target_angle","move_time","charge_time","beam_time","fake_mode","offset_direction","offset_speed","offset_acceleration","offset_rotation_speed","damage_type","damage","heal_amount","visual_color","layer_mode"];
        case "slash":return ["position","orbit","physics","follow","warning_time","active_time","visual_min_width","pre_direction","pre_speed","pre_acceleration","pre_curve_speed","pre_rotation_mode","pre_rotation_speed","pre_rotation_target","pre_rotation_time","post_direction","post_speed","post_acceleration","post_curve_speed","post_rotation_mode","post_rotation_speed","post_rotation_target","post_rotation_time","damage_type","damage","heal_amount","visual_color","layer_mode"];
        case "true_knife":return ["position","orbit","physics","follow","damage_type","damage","invincibility_frames","visual_color","post_direction","post_speed","post_acceleration","post_curve_speed","post_rotation_mode","post_rotation_speed","post_rotation_target","post_rotation_time","layer_mode"];
        case "bone_3d":return ["position","orbit","physics","follow","angle_x","angle_y","angle_z","rotate_x","rotate_y","rotate_z","size_x","size_y","size_z","hspeed","vspeed","world_z","perspective_distance","edge_trim","duration","damage_type","damage","visual_color","layer_mode"];
        case "bone_4d":return ["position","orbit","physics","follow","angle_x","angle_y","angle_z","angle_xw","angle_yw","angle_zw","rotate_x","rotate_y","rotate_z","rotate_xw","rotate_yw","rotate_zw","size_x","size_y","size_z","size_w","world_z","perspective_distance","perspective4d_distance","edge_trim","duration","damage_type","damage","visual_color","layer_mode"];
        case "platform":return ["position","orbit","physics","follow","width","hspeed","vspeed","duration","platform_sticky","platform_bounce","layer_mode"];
        case "board":return ["position","orbit","physics","rotate","shape","radius_x","radius_y","triangle_size","up","down","left","right","color_frame","mask_color","cover","control_vertex"];
        case "decoration":return ["position","orbit","physics","follow","scale_x","scale_y","alpha","visual_color","duration","layer_mode"];
        case "sprite_hazard":return ["position","orbit","physics","follow","scale_x","scale_y","alpha","damage_type","damage","heal_amount","visual_color","duration","layer_mode"];
        case "typewriter":return ["position","orbit","physics","follow","scale_x","scale_y","alpha","font_id","text"];
        case "enemy":return ["position","orbit","physics","speak","scale_x","scale_y"];
        case "player_data":return ["player_name","player_lv","player_hp","player_max_hp","player_natural_max_hp","player_atk","player_def","shield_value","shield_max","shield_natural_max"];
        // Blue direction and the optional gravity throw are conditional fields
        // inside this one mode-switch item, not separate pseudo-functions.
        case "soul":return ["soul_mode","physics"];
        case "hud_all":return ["position","physics"];
        case "hud_name":return ["position"];
        case "hud_lv":return ["position"];
        case "hud_vitals":return ["position","show_hp_label","show_bar","show_kr","show_numbers","show_shield","show_overhead","shield_hud_mode"];
        case "battle_buttons":return ["position","physics","scale_x","scale_y"];
        case "button_fight":return ["position","physics","scale_x","scale_y"];
        case "button_act":return ["position","physics","scale_x","scale_y"];
        case "button_item":return ["position","physics","scale_x","scale_y"];
        case "button_mercy":return ["position","physics","scale_x","scale_y"];
    }
    return ["position"];
}

/// Aiming is exposed by capability rather than projectile family. Every
/// authoring target that already supports world-position control receives the
/// same composite aim-and-move operation; runtime separately checks whether an
/// angle property exists before trying to rotate its artwork.
function BattleEditor_ControlPropertiesAllForType(target_type) {
    var result=BattleEditor_ControlPropertiesAllForTypeBase(target_type);
    var movable=false;
    for(var property_index=0;property_index<array_length(result);property_index++) if(result[property_index]=="position"){movable=true;break;}
    if(movable) array_push(result,"aim_motion");
    return result;
}

function BattleEditor_ControlPropertyCategory(property_name,target_type="") {
    if(property_name=="width"&&(target_type=="platform"||target_type=="board")) return "transform";
    if(property_name=="height"&&target_type=="board") return "transform";
    switch(property_name){
        case "position":case "angle":case "rotate":case "scale_x":case "scale_y":case "alpha":
        case "hspeed":case "vspeed":case "length":case "duration":case "size_x":case "size_y":case "size_z":case "size_w":
        case "world_z":case "perspective_distance":case "perspective4d_distance":case "edge_trim":return "transform";
        case "orbit":case "angle_x":case "angle_y":case "angle_z":case "angle_xw":case "angle_yw":case "angle_zw":
        case "rotate_x":case "rotate_y":case "rotate_z":case "rotate_xw":case "rotate_yw":case "rotate_zw":return "rotation";
        case "physics":case "aim_motion":return "motion";
        case "pre_direction":case "pre_speed":case "pre_acceleration":case "pre_curve_speed":
        case "post_direction":case "post_speed":case "post_acceleration":case "post_curve_speed":
        case "offset_direction":case "offset_speed":case "offset_acceleration":return "motion";
        case "pre_rotation_mode":case "pre_rotation_speed":case "pre_rotation_target":case "pre_rotation_time":
        case "post_rotation_mode":case "post_rotation_speed":case "post_rotation_target":case "post_rotation_time":
        case "offset_rotation_speed":return "rotation";
        case "damage_type":case "damage":case "heal_amount":case "invincibility_frames":case "green_guard_blockable":case "green_guard_destroy_on_block":return "damage";
        case "warning_time":case "active_time":case "warning_width":case "visual_min_width":case "visual_max_width":
        case "move_time":case "charge_time":case "beam_time":case "aim_x":case "aim_y":case "target_angle":case "fake_mode":case "gb_hold":case "gb_release":case "speak":
        case "soul_mode":case "blue_direction":case "bone_style":case "platform_sticky":case "platform_bounce":return "mechanic";
        case "shape":case "width":case "height":case "radius_x":case "radius_y":case "orbit_radius_x":case "orbit_radius_y":case "pattern_span":case "pattern_amplitude":case "pattern_speed":case "wall_extent":case "triangle_size":case "cover":
        case "up":case "down":case "left":case "right":case "control_vertex":case "color_frame":case "mask_color":return "shape";
        case "player_name":case "player_lv":case "player_hp":case "player_max_hp":case "player_natural_max_hp":
        case "player_atk":case "player_def":case "shield_value":case "shield_max":case "shield_natural_max":return "data";
        case "show_hp_label":case "show_bar":case "show_kr":case "show_numbers":case "show_shield":case "show_overhead":case "shield_hud_mode":return "display";
        case "font_id":case "text":case "color":case "visual_color":case "layer_mode":return "appearance";
        case "follow":case "follow_board":case "follow_angle":case "point":case "point_at":
        case "aim_enabled":case "aim_target_uid":case "aim_continuous":case "aim_move_enabled":case "aim_move_speed":return "follow";
    }
    return "other";
}

function BattleEditor_ControlPropertyCategoryName(category) {
    switch(category){
        case "transform":return "变换";
        case "motion":return "移动";
        case "rotation":return "旋转";
        case "damage":return "伤害";
        case "mechanic":return "机制";
        case "shape":return "形状";
        case "data":return "数值";
        case "display":return "显示";
        case "appearance":return "外观";
        case "follow":return "跟随";
    }
    return "其他";
}

function BattleEditor_ControlPropertyCategoriesForType(target_type) {
    var all_properties=BattleEditor_ControlPropertiesAllForType(target_type);
    var result=[];
    for(var i=0;i<array_length(all_properties);i++){
        var category=BattleEditor_ControlPropertyCategory(all_properties[i],target_type);
        var exists=false;
        for(var j=0;j<array_length(result);j++) if(result[j]==category){exists=true;break;}
        if(!exists) array_push(result,category);
    }
    return result;
}

function BattleEditor_ControlPropertiesForType(target_type,category="") {
    var all_properties=BattleEditor_ControlPropertiesAllForType(target_type);
    if(string_length(string(category))<=0) return all_properties;
    var result=[];
    for(var i=0;i<array_length(all_properties);i++) if(BattleEditor_ControlPropertyCategory(all_properties[i],target_type)==category) array_push(result,all_properties[i]);
    return result;
}

function BattleEditor_ControlPropertiesAllForStep(step) {
    var base=BattleEditor_ControlPropertiesAllForType(step.target_type);
    if(step.target_type!="path_point") return base;
    var group_kind=struct_exists(step,"target_group_kind")?string(step.target_group_kind):"";
    switch(group_kind){
        case "bone_orbit":return ["position","orbit","physics","aim_motion","orbit_radius_x","orbit_radius_y","pattern_speed"];
        case "bone_wave":return ["position","orbit","physics","aim_motion","pattern_span","pattern_amplitude","pattern_speed"];
        case "gb_pinwheel":return ["position","orbit","physics","aim_motion","orbit_radius_x","orbit_radius_y"];
        case "bone_wall":return ["position","orbit","physics","aim_motion","wall_extent"];
    }
    return base;
}

function BattleEditor_ControlPropertyCategoriesForStep(step) {
    var all_properties=BattleEditor_ControlPropertiesAllForStep(step);
    var result=[];
    for(var i=0;i<array_length(all_properties);i++){
        var category=BattleEditor_ControlPropertyCategory(all_properties[i],step.target_type);
        var exists=false;
        for(var j=0;j<array_length(result);j++) if(result[j]==category){exists=true;break;}
        if(!exists) array_push(result,category);
    }
    return result;
}

function BattleEditor_ControlPropertiesForStep(step,category="") {
    var all_properties=BattleEditor_ControlPropertiesAllForStep(step);
    if(string_length(string(category))<=0) return all_properties;
    var result=[];
    for(var i=0;i<array_length(all_properties);i++) if(BattleEditor_ControlPropertyCategory(all_properties[i],step.target_type)==category) array_push(result,all_properties[i]);
    return result;
}

function BattleEditor_FindScriptList(project,list_uid) {
    for(var i=0;i<array_length(project.script_lists);i++) if(project.script_lists[i].uid==list_uid) return project.script_lists[i];
    return undefined;
}

function BattleEditor_RuntimeNumber(controller,source,fallback=0) {
    var literal=BattleEditor_TryNumberLiteral(source);
    if(literal.valid) return literal.value;
    var parsed=BattleEditor_EvaluateNumberExpression(source,BattleEditor_ExpressionVariables(controller));
    return parsed.valid?parsed.value:fallback;
}

function BattleEditor_RuntimeCondition(controller,step) {
    var left=BattleEditor_RuntimeNumber(controller,step.condition_left,0);
    var right=BattleEditor_RuntimeNumber(controller,step.condition_right,0);
    switch(step.condition_operator){
        case "==":return left==right;
        case "!=":return left!=right;
        case ">":return left>right;
        case ">=":return left>=right;
        case "<":return left<right;
        case "<=":return left<=right;
    }
    return false;
}

function BattleEditor_RuntimeSetVariable(controller,step) {
    var name=string_trim(string(step.variable_name));
    if(name=="") return false;
    var variables=BattleEditor_ExpressionVariables(controller);
    var old_value=variable_struct_exists(variables,name)?variable_struct_get(variables,name):0;
    var input_value=BattleEditor_RuntimeNumber(controller,step.expression,0);
    switch(step.variable_operation){
        case "add":old_value+=input_value;break;
        case "subtract":old_value-=input_value;break;
        case "multiply":old_value*=input_value;break;
        case "divide":if(abs(input_value)>0.0000001) old_value/=input_value;break;
        default:old_value=input_value;break;
    }
    variable_struct_set(variables,name,old_value);
    controller.runtime_variables=variables;
    return true;
}

function BattleEditor_StartScriptList(controller,list_uid,inherited_previous_end=-1,ancestry=undefined) {
    var list_data=BattleEditor_FindScriptList(controller.project,list_uid);
    if(is_undefined(list_data)) return false;
    if(!BattleEditor_WorkspaceHasHeader(list_data)) return false;
    // Number of active lists is not a useful hang detector: ten expensive
    // actions can stall while ten thousand cheap assignments can be valid.
    // Reject only an actual recursive start-list cycle in this call chain and
    // otherwise preserve the authored amount of parallel work.
    var parent_ancestry=is_array(ancestry)?ancestry:[];
    for(var ancestry_index=0;ancestry_index<array_length(parent_ancestry);ancestry_index++) if(parent_ancestry[ancestry_index]==list_uid) return false;
    var next_ancestry=BattleEditor_StorageClone(parent_ancestry);
    array_push(next_ancestry,list_uid);
    array_push(controller.script_runtime_states,{list_uid:list_uid,index:0,wait_until:-1,dialogue_waiters:[],loops:[],inherited_previous_end:inherited_previous_end,ancestry:next_ancestry});
    return true;
}

function BattleEditor_TriggerEntry(controller,entry_kind,entry_value="") {
    if(!instance_exists(controller)) return 0;
    var started=0;
    for(var i=0;i<array_length(controller.project.script_lists);i++){
        var list_data=controller.project.script_lists[i];
        if(list_data.entry_kind!=entry_kind) continue;
        var matches=true;
        if(entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.MONSTER_TURN||entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.TIMER_VALUE||entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED||entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION) matches=string(list_data.entry_value)==string(entry_value);
        if(matches&&BattleEditor_StartScriptList(controller,list_data.uid)) started+=1;
    }
    return started;
}

function BattleEditor_NotifyPlayerHurt(damage) {
    if(damage<=0||!variable_global_exists("battle_editor_runtime_controller")) return false;
    var controller=global.battle_editor_runtime_controller;
    if(!instance_exists(controller)||!controller.playing) return false;
    BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.PLAYER_HURT,damage);
    return true;
}

function BattleEditor_NotifyItemUsed(item_uid) {
    // During a monster turn, the turn host owns script execution. Items are
    // normally consumed in the player menu after that host has stopped and
    // been destroyed, so item-entry lists need a battle-lifetime host instead
    // of being silently discarded merely because no attack timeline is live.
    var runtime_project=variable_global_exists("battle_editor_project_runtime")
        ? BattleEditor_ProjectNormalize(global.battle_editor_project_runtime)
        : BattleEditor_NewProject();
    var item_data=BattleEditor_ItemByUid(runtime_project,item_uid);
    var after_use_mode=is_undefined(item_data)?BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE:item_data.after_use_mode;
    var has_matching_list=false;
    for(var list_index=0;list_index<array_length(runtime_project.script_lists);list_index++){
        var item_list=runtime_project.script_lists[list_index];
        if(item_list.entry_kind==BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED&&string(item_list.entry_value)==string(item_uid)){has_matching_list=true;break;}
    }
    if(!has_matching_list) return false;

    if(after_use_mode!=BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE){
        if(!instance_exists(battle)) return false;
        battle._battle_editor_pending_item_uid=string(item_uid);
        battle._battle_editor_pending_item_mode=after_use_mode;
        return true;
    }

    if(variable_global_exists("battle_editor_runtime_controller")){
        var turn_controller=global.battle_editor_runtime_controller;
        if(instance_exists(turn_controller)&&turn_controller.playing){
            return BattleEditor_TriggerEntry(turn_controller,BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED,item_uid)>0;
        }
    }
    if(!instance_exists(battle)) return false;
    var controller=instance_find(battle,0);
    if(!variable_instance_exists(controller,"battle_editor_entry_active")||!controller.battle_editor_entry_active){
        controller.project=runtime_project;
        if(!BattleEditor_RuntimeEnsureController(controller)) return false;
        controller.playhead=0;
        controller.runtime_instances=[];
        controller.preview_frames=[];
        controller.script_runtime_states=[];
        controller.script_scheduled_sounds=[];
        controller.script_timer_fired=[];
        controller.script_vertex_animations=[];
        controller.script_patterns=[];
        controller.runtime_variables=BattleEditor_ExpressionVariables(controller.project);
    }
    var started=BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.ITEM_USED,item_uid);
    if(started>0) controller.battle_editor_entry_active=true;
    return started>0;
}

function BattleEditor_NotifyActionUsed(action_uid) {
    if(variable_global_exists("battle_editor_runtime_controller")){
        var turn_controller=global.battle_editor_runtime_controller;
        if(instance_exists(turn_controller)&&turn_controller.playing){
            return BattleEditor_TriggerEntry(turn_controller,BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION,action_uid)>0;
        }
    }
    if(!instance_exists(battle)) return false;
    var controller=instance_find(battle,0);
    var runtime_project=variable_global_exists("battle_editor_project_runtime")
        ? global.battle_editor_project_runtime
        : BattleEditor_NewProject();
    if(!variable_instance_exists(controller,"battle_editor_entry_active")||!controller.battle_editor_entry_active){
        controller.project=BattleEditor_ProjectNormalize(runtime_project);
        if(!BattleEditor_RuntimeEnsureController(controller)) return false;
        controller.playhead=0;
        controller.runtime_instances=[];
        controller.preview_frames=[];
        controller.script_runtime_states=[];
        controller.script_scheduled_sounds=[];
        controller.script_timer_fired=[];
        controller.script_vertex_animations=[];
        controller.script_patterns=[];
        controller.runtime_variables=BattleEditor_ExpressionVariables(controller.project);
    }
    var started=BattleEditor_TriggerEntry(controller,BATTLE_EDITOR_SCRIPT_ENTRY.ACT_ACTION,action_uid);
    if(started>0) controller.battle_editor_entry_active=true;
    return started>0;
}

/// Advances entry-point scripts that are fired while the attack timeline is
/// not running, most importantly the authorable "玩家使用物品" entry.
function BattleEditor_BattleEntryStep(controller) {
    if(!instance_exists(controller)
        ||!variable_instance_exists(controller,"battle_editor_entry_active")
        ||!controller.battle_editor_entry_active) return false;
    controller.playhead+=global.delta_time_factor;
    BattleEditor_RuntimeScriptStep(controller);
    BattleEditor_RuntimeVertexStep(controller);
    BattleEditor_RuntimePatternStep(controller);
    if(array_length(controller.script_runtime_states)<=0
        &&array_length(controller.script_scheduled_sounds)<=0
        &&array_length(controller.script_vertex_animations)<=0
        &&array_length(controller.script_patterns)<=0){
        controller.battle_editor_entry_active=false;
    }
    return true;
}

function BattleEditor_RuntimeTargetMatches(target,step) {
    // Empty group names and the sentinel UID are configuration states, not
    // wildcards. A half-filled command must never move an unrelated object.
    if(step.target_mode=="uid"&&step.target_uid<0) return false;
    if(step.target_mode!="uid"&&(string_length(string(step.target))<=0||string_length(string(step.target_type))<=0)) return false;
    if(is_struct(target)){
        if(step.target_mode=="uid") return variable_struct_exists(target,"editor_uid")&&target.editor_uid==step.target_uid;
        if(struct_exists(step,"target_group_uid")&&step.target_group_uid>=0){
            var struct_control_uid=variable_struct_exists(target,"editor_control_uid")?target.editor_control_uid:(variable_struct_exists(target,"control_uid")?target.control_uid:-1);
            return struct_control_uid==step.target_group_uid&&variable_struct_exists(target,"editor_target_type")&&target.editor_target_type==step.target_type;
        }
        return variable_struct_exists(target,"control_id")&&variable_struct_exists(target,"editor_target_type")&&string(target.control_id)==string(step.target)&&target.editor_target_type==step.target_type;
    }
    if(!instance_exists(target)) return false;
    if(step.target_mode=="uid") return variable_instance_exists(target,"editor_uid")&&target.editor_uid==step.target_uid;
    if(struct_exists(step,"target_group_uid")&&step.target_group_uid>=0){
        var instance_control_uid=variable_instance_exists(target,"editor_control_uid")?target.editor_control_uid:(variable_instance_exists(target,"control_uid")?target.control_uid:-1);
        return instance_control_uid==step.target_group_uid&&variable_instance_exists(target,"editor_target_type")&&target.editor_target_type==step.target_type;
    }
    return variable_instance_exists(target,"control_id")&&variable_instance_exists(target,"editor_target_type")&&string(target.control_id)==string(step.target)&&target.editor_target_type==step.target_type;
}

function BattleEditor_RuntimeControlPosition(controller,target,step) {
    var has_x=string_length(string(step.position_x))>0;
    var has_y=string_length(string(step.position_y))>0;
    var has_angle=struct_exists(step,"position_angle")&&string_length(string(step.position_angle))>0;
    if(!has_x&&!has_y&&!has_angle) return false;
    var changed=false;
    if(has_x){
        var old_x=is_struct(target)?variable_struct_get(target,"x"):variable_instance_get(target,"x");
        var input_x=BattleEditor_RuntimeNumber(controller,step.position_x,0);
        var final_x=step.coordinate_mode=="relative"?old_x+input_x:input_x;
        changed=BattleEditor_RuntimeSetProperty(target,"x",final_x,step.duration,step.tween,step.ease)||changed;
    }
    if(has_y){
        var old_y=is_struct(target)?variable_struct_get(target,"y"):variable_instance_get(target,"y");
        var input_y=BattleEditor_RuntimeNumber(controller,step.position_y,0);
        var final_y=step.coordinate_mode=="relative"?old_y+input_y:input_y;
        changed=BattleEditor_RuntimeSetProperty(target,"y",final_y,step.duration,step.tween,step.ease)||changed;
    }
    if(has_angle){
        var input_angle=BattleEditor_RuntimeNumber(controller,step.position_angle,0);
        var old_angle=0;
        var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:""):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:"");
        var angle_property="angle";
        if(!is_struct(target)&&target_type=="bone"&&variable_instance_exists(target,"follow")&&target.follow) angle_property="_angle";
        else if(target_type=="decoration"||target_type=="sprite_hazard"||target_type=="slash"||target_type=="true_knife") angle_property="image_angle";
        else if(target_type=="bone_3d"||target_type=="bone_4d") angle_property="anglez";
        else if(target_type=="typewriter") angle_property="_angle";
        var angle_exists=is_struct(target)?variable_struct_exists(target,angle_property):(instance_exists(target)&&variable_instance_exists(target,angle_property));
        if(angle_exists){
            old_angle=is_struct(target)?variable_struct_get(target,angle_property):variable_instance_get(target,angle_property);
            var final_angle=step.coordinate_mode=="relative"?old_angle+input_angle:input_angle;
            changed=BattleEditor_RuntimeSetProperty(target,"angle",final_angle,step.duration,step.tween,step.ease)||changed;
        }
    }
    return changed;
}

/// Battle-frame position, angle and full dimensions are one transform.  Size
/// is morphed once so setting width and height together cannot start two
/// competing contour animations; position/angle then animate on the resulting
/// frame struct. Empty components are intentionally ignored.
function BattleEditor_RuntimeControlBoardTransform(controller,board,step) {
    if(!is_struct(board)||board._destroyed) return false;
    var has_width=struct_exists(step,"board_transform_width")&&string_length(string(step.board_transform_width))>0;
    var has_height=struct_exists(step,"board_transform_height")&&string_length(string(step.board_transform_height))>0;
    var transformed_board=board;
    var changed=false;
    if(has_width||has_height){
        var bounds=BattleEditor_RuntimeBoardBounds(board);
        var target_width=bounds[0],target_height=bounds[1];
        if(has_width){
            var width_input=BattleEditor_RuntimeNumber(controller,step.board_transform_width,0);
            target_width=step.coordinate_mode=="relative"?bounds[0]+width_input:width_input;
        }
        if(has_height){
            var height_input=BattleEditor_RuntimeNumber(controller,step.board_transform_height,0);
            target_height=step.coordinate_mode=="relative"?bounds[1]+height_input:height_input;
        }
        target_width=max(1,target_width);target_height=max(1,target_height);
        if(abs(target_width-bounds[0])>0.0001||abs(target_height-bounds[1])>0.0001){
            var shape_index=BattleEditor_RuntimeBoardShapeIndex(board);
            var explicit_target=undefined;
            if(shape_index==3){
                var source_contour=BattleEditor_RuntimeBoardSourceContour(board);
                explicit_target=[];
                var width_scale=target_width/max(0.0001,bounds[0]);
                var height_scale=target_height/max(0.0001,bounds[1]);
                for(var point_index=0;point_index<array_length(source_contour);point_index++) array_push(explicit_target,[source_contour[point_index][0]*width_scale,source_contour[point_index][1]*height_scale]);
            }
            transformed_board=BattleEditor_RuntimeStartBoardMorph(controller,board,shape_index,step.duration,step.tween,step.ease,{width:target_width,height:target_height},explicit_target);
            if(is_undefined(transformed_board)) return false;
            changed=true;
        }
    }
    return BattleEditor_RuntimeControlPosition(controller,transformed_board,step)||changed;
}

function BattleEditor_RuntimeSetProperty(target,property_name,value,duration,tween,ease) {
    var actual_property=property_name;
    var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:""):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:"");
    // GB scale uses editor-friendly units: value 1 is the former visual 2x.
    // Keep the public field decimal-friendly while converting only at runtime.
    if(target_type=="gb"&&(property_name=="scale_x"||property_name=="scale_y")) value*=2;
    // A followed bone keeps its authored motion in local coordinates. Moving
    // x/y must therefore animate _x/_y instead of overwriting the world-space
    // result calculated from the board every frame.
    if(!is_struct(target)&&target_type=="bone"&&variable_instance_exists(target,"follow")&&target.follow){
        if(property_name=="x") actual_property="_x";
        else if(property_name=="y") actual_property="_y";
        else if(property_name=="angle") actual_property="_angle";
        else if(property_name=="hspeed") actual_property="_hspeed";
        else if(property_name=="vspeed") actual_property="_vspeed";
    }
    if(property_name=="layer_mode"&&!is_struct(target)){
        if(target_type=="decoration"){
            target.layer_mode=clamp(round(value),0,2);
            target.depth=target.layer_mode==BATTLE_EDITOR_LAYER.OUTSIDE?DEPTH_BATTLE.BULLET_OUTSIDE_LOW:DEPTH_BATTLE.BULLET;
        }else Battle_SetAttackLayer(target,round(value));
        return true;
    }
    if(!is_struct(target)&&property_name=="follow_board"&&value){
        target.follow=true;
        target.follow_board=true;
        target.follow_target=battle_board;
    }
    if((target_type=="bone_3d"||target_type=="bone_4d")&&(property_name=="angle_x"||property_name=="angle_y"||property_name=="angle_z"||property_name=="angle_xw"||property_name=="angle_yw"||property_name=="angle_zw"||property_name=="rotate_x"||property_name=="rotate_y"||property_name=="rotate_z"||property_name=="rotate_xw"||property_name=="rotate_yw"||property_name=="rotate_zw"||property_name=="size_x"||property_name=="size_y"||property_name=="size_z"||property_name=="size_w")){
        switch(property_name){
            case "angle_x":actual_property="anglex";break;
            case "angle_y":actual_property="angley";break;
            case "angle_z":actual_property="anglez";break;
            case "angle_xw":actual_property="anglexw";break;
            case "angle_yw":actual_property="angleyw";break;
            case "angle_zw":actual_property="anglezw";break;
            case "rotate_x":actual_property="angxs";break;
            case "rotate_y":actual_property="angys";break;
            case "rotate_z":actual_property="angzs";break;
            case "rotate_xw":actual_property="angxws";break;
            case "rotate_yw":actual_property="angyws";break;
            case "rotate_zw":actual_property="angzws";break;
            case "size_x":actual_property="scalex";break;
            case "size_y":actual_property="scaley";break;
            case "size_z":actual_property="scalez";break;
            case "size_w":actual_property="scalew";break;
        }
    }
    else if(property_name=="scale_x") actual_property=target_type=="typewriter"?"_scale_x":((target_type=="gb"||target_type=="enemy")?"scale_x":"image_xscale");
    else if(property_name=="scale_y") actual_property=target_type=="typewriter"?"_scale_y":((target_type=="gb"||target_type=="enemy")?"scale_y":"image_yscale");
    else if(property_name=="angle"&&(target_type=="decoration"||target_type=="sprite_hazard"||target_type=="slash"||target_type=="true_knife")) actual_property="image_angle";
    else if(property_name=="angle"&&(target_type=="bone_3d"||target_type=="bone_4d")) actual_property="anglez";
    else if(property_name=="alpha"&&(target_type=="decoration"||target_type=="sprite_hazard")) actual_property="image_alpha";
    else if(property_name=="angle"&&target_type=="typewriter") actual_property="_angle";
    else if(property_name=="alpha"&&target_type=="typewriter") actual_property="_alpha";
    else if(property_name=="font_id"&&target_type=="typewriter"){
        TextTyper_FontEnsureGroup(target,value);
        actual_property="_font";
    }
    else if(target_type=="platform"&&property_name=="platform_sticky") actual_property="sticky";
    else if(target_type=="platform"&&property_name=="platform_bounce") actual_property="bounce";
    else if((property_name=="damage_type"||property_name=="damage"||property_name=="heal_amount")&&target_type=="sprite_hazard"&&!is_struct(target)&&variable_instance_exists(target,"data")&&is_struct(target.data)){
        if(!struct_exists(target.data,"damage_profile")) return false;
        var profile_property=property_name=="damage_type"?"type":property_name;
        variable_struct_set(target.data.damage_profile,profile_property,value);
        if(property_name=="damage_type") target.type=value;
        return true;
    }
    else if(property_name=="damage_type") actual_property="type";
    else if(property_name=="damage"&&(target_type=="bone"||target_type=="gb"||target_type=="slash"||target_type=="true_knife"||target_type=="bone_3d"||target_type=="bone_4d")) actual_property="hp_damage";
    else if(property_name=="charge_time") actual_property="time_release_delay";
    else if(property_name=="beam_time") actual_property="time_beam_end_delay";
    else if(property_name=="move_time") actual_property="time_move";
    else if(property_name=="aim_x") actual_property="x_target";
    else if(property_name=="aim_y") actual_property="y_target";
    else if(property_name=="target_angle") actual_property="angle_target";
    else if(target_type=="bone"&&property_name=="aim_enabled") actual_property="editor_aim_enabled";
    else if(target_type=="bone"&&property_name=="aim_target_uid") actual_property="editor_aim_target_uid";
    else if(target_type=="bone"&&property_name=="aim_continuous") actual_property="editor_aim_continuous";
    else if(target_type=="bone"&&property_name=="aim_move_enabled") actual_property="editor_aim_move_enabled";
    else if(target_type=="bone"&&property_name=="aim_move_speed") actual_property="editor_aim_move_speed";
    else if(property_name=="color") actual_property="image_blend";
    property_name=actual_property;
    var exists=is_struct(target)?variable_struct_exists(target,property_name):(instance_exists(target)&&variable_instance_exists(target,property_name));
    if(!exists) return false;
    var old_value=is_struct(target)?variable_struct_get(target,property_name):variable_instance_get(target,property_name);
    if(duration>0&&is_real(old_value)&&is_real(value)) Anim_Create(target,property_name,tween,ease,old_value,value-old_value,duration);
    else if(is_struct(target)){
        variable_struct_set(target,property_name,value);
        if(variable_struct_exists(target,"update")&&(property_name=="up"||property_name=="down"||property_name=="left"||property_name=="right")) target.update();
        else if(variable_struct_exists(target,"updateDivide")&&property_name=="color_frame") target.updateDivide();
    }else variable_instance_set(target,property_name,value);
    return true;
}

function BattleEditor_RuntimeSetVertices(target,points) {
    if(!is_struct(target)||!variable_struct_exists(target,"listVertex")) return false;
    target.listVertex=[];
    for(var i=0;i<array_length(points);i++) array_push(target.listVertex,[points[i][0],points[i][1]]);
    if(variable_struct_exists(target,"updateDivide")) target.updateDivide();
    return true;
}

function BattleEditor_RuntimeSetRawInstanceProperty(target,property_name,value,duration,tween,ease) {
    if(!instance_exists(target)||!variable_instance_exists(target,property_name)) return false;
    var old_value=variable_instance_get(target,property_name);
    if(duration>0&&is_real(old_value)&&is_real(value)) Anim_Create(target,property_name,tween,ease,old_value,value-old_value,duration);
    else variable_instance_set(target,property_name,value);
    return true;
}

/// Applies an independent visual tint without changing damage colour/type.
/// Runtime objects expose this capability through different storage fields;
/// this adapter keeps Control Object on the existing render paths instead of
/// creating a second recolour system.
function BattleEditor_RuntimeSetVisualColor(target,value,duration,tween,ease) {
    if(!instance_exists(target)) return false;
    var target_type=variable_instance_exists(target,"editor_target_type")?target.editor_target_type:"";
    var actual_property="";
    if(target_type=="bone"||target_type=="gb"||target_type=="sprite_hazard"||target_type=="bone_3d"||target_type=="bone_4d"){
        if(!variable_instance_exists(target,"editor_visual_override")||!variable_instance_exists(target,"editor_visual_color")) return false;
        target.editor_visual_override=true;
        actual_property="editor_visual_color";
    }else if(target_type=="slash"||target_type=="true_knife") actual_property="wave_color";
    else if(target_type=="decoration") actual_property="image_blend";
    else return false;
    if(!variable_instance_exists(target,actual_property)) return false;
    var old_value=variable_instance_get(target,actual_property);
    if(duration>0&&is_real(old_value)&&is_real(value)) Anim_Create(target,actual_property,tween,ease,old_value,value-old_value,duration);
    else variable_instance_set(target,actual_property,value);
    return true;
}

function BattleEditor_RuntimeSetDamageType(target,value,change_visual=true) {
    if(!instance_exists(target)) return false;
    var target_type=variable_instance_exists(target,"editor_target_type")?target.editor_target_type:"";
    var old_damage_type=variable_instance_exists(target,"type")?target.type:0;
    var old_visual=BattleEditor_ColorForType(old_damage_type);
    var uses_override=target_type=="bone"||target_type=="gb"||target_type=="sprite_hazard"||target_type=="bone_3d"||target_type=="bone_4d";
    var uses_wave_color=target_type=="slash"||target_type=="true_knife";
    if(uses_override&&variable_instance_exists(target,"editor_visual_override")&&target.editor_visual_override&&variable_instance_exists(target,"editor_visual_color")) old_visual=target.editor_visual_color;
    else if(uses_wave_color&&variable_instance_exists(target,"wave_color")) old_visual=target.wave_color;
    if(!BattleEditor_RuntimeSetProperty(target,"damage_type",clamp(round(real(value)),0,8),0,0,0)) return false;
    if(uses_override&&variable_instance_exists(target,"editor_visual_override")&&variable_instance_exists(target,"editor_visual_color")){
        target.editor_visual_override=!change_visual;
        target.editor_visual_color=change_visual?BattleEditor_ColorForType(value):old_visual;
    }else if(uses_wave_color&&change_visual&&variable_instance_exists(target,"wave_color")) target.wave_color=BattleEditor_ColorForType(value);
    return true;
}

function BattleEditor_RuntimeControlOffsetPosition(controller,target,step,x_property,y_property,base_x,base_y) {
    if(!instance_exists(target)) return false;
    var has_x=string_length(string(step.position_x))>0;
    var has_y=string_length(string(step.position_y))>0;
    var changed=false;
    if(has_x){
        var input_x=BattleEditor_RuntimeNumber(controller,step.position_x,0);
        var current_x=variable_instance_get(target,x_property);
        var final_x=step.coordinate_mode=="relative"?current_x+input_x:input_x-base_x;
        changed=BattleEditor_RuntimeSetRawInstanceProperty(target,x_property,final_x,step.duration,step.tween,step.ease)||changed;
    }
    if(has_y){
        var input_y=BattleEditor_RuntimeNumber(controller,step.position_y,0);
        var current_y=variable_instance_get(target,y_property);
        var final_y=step.coordinate_mode=="relative"?current_y+input_y:input_y-base_y;
        changed=BattleEditor_RuntimeSetRawInstanceProperty(target,y_property,final_y,step.duration,step.tween,step.ease)||changed;
    }
    return changed;
}

function BattleEditor_RuntimeControlPlayerData(controller,step,runtime_value) {
    if(step.target_type!="player_data"||step.target!="player") return 0;
    switch(step.property){
        case "player_name":Player_SetName(step.text_value);break;
        case "player_lv":Player_SetLv(max(1,round(runtime_value)));break;
        case "player_hp":Player_SetHp(clamp(round(runtime_value),1,Player_GetHpMax()));break;
        case "player_max_hp":Player_SetHpMax(max(1,round(runtime_value)));Player_SetHp(min(Player_GetHp(),Player_GetHpMax()));break;
        case "player_natural_max_hp":
            var natural_hp_max=max(1,round(runtime_value));
            Player_SetNaturalHpMax(natural_hp_max);
            // Lowering the original cap must be visible immediately. Raising it
            // does not silently restore max HP lost to green attacks.
            if(Player_GetHpMax()>natural_hp_max) Player_SetHpMax(natural_hp_max);
            Player_SetHp(min(Player_GetHp(),Player_GetHpMax()));
            break;
        case "player_atk":Player_SetAtk(runtime_value);break;
        case "player_def":Player_SetDef(runtime_value);break;
        case "shield_value":if(instance_exists(battle)) battle._shield=clamp(runtime_value,0,battle._shield_max);break;
        case "shield_max":if(instance_exists(battle)){battle._shield_max=clamp(runtime_value,0,battle._shield_natural_max);battle._shield=min(battle._shield,battle._shield_max);}break;
        case "shield_natural_max":if(instance_exists(battle)){battle._shield_natural_max=max(0,runtime_value);battle._shield_max=min(battle._shield_max,battle._shield_natural_max);battle._shield=min(battle._shield,battle._shield_max);}break;
        default:return 0;
    }
    return 1;
}

function BattleEditor_RuntimeControlSoul(controller,step,runtime_value) {
    if(step.target_type!="soul"||step.target!="soul") return 0;
    switch(step.property){
        case "soul_mode":
            var mode=clamp(round(runtime_value),0,6);
            if(mode==1){
                var blue_choice=struct_exists(step,"soul_blue_direction")?step.soul_blue_direction:1;
                var apply_throw=struct_exists(step,"blue_gravity_throw")&&step.blue_gravity_throw;
                return BattleEditor_SetBlueSoulDirection(blue_choice,apply_throw)?1:0;
            }
            return BattleEditor_SetSoulMode(mode)?1:0;
        case "blue_direction":
            var apply_throw=struct_exists(step,"blue_gravity_throw")&&step.blue_gravity_throw;
            return BattleEditor_SetBlueSoulDirection(runtime_value,apply_throw)?1:0;
    }
    return 0;
}

function BattleEditor_RuntimeControlHud(controller,step,runtime_value) {
    if(step.target!="hud"||!instance_exists(battle_ui)) return 0;
    var ui=instance_find(battle_ui,0);
    if(!instance_exists(ui)) return 0;
    if(step.target_type=="hud_all"){
        if(step.property!="position") return 0;
        return BattleEditor_RuntimeControlPosition(controller,ui,step)?1:0;
    }
    if(step.target_type=="hud_name"){
        if(step.property!="position") return 0;
        return BattleEditor_RuntimeControlOffsetPosition(controller,ui,step,"name_offset_x","name_offset_y",ui.x,ui.y)?1:0;
    }
    if(step.target_type=="hud_lv"){
        if(step.property!="position") return 0;
        return BattleEditor_RuntimeControlOffsetPosition(controller,ui,step,"lv_offset_x","lv_offset_y",ui.x+126,ui.y)?1:0;
    }
    if(step.target_type!="hud_vitals") return 0;
    if(step.property=="position") return BattleEditor_RuntimeControlOffsetPosition(controller,ui,step,"vitals_offset_x","vitals_offset_y",ui.x,ui.y)?1:0;
    switch(step.property){
        case "show_hp_label":ui.show_hp_label=runtime_value!=0;break;
        case "show_bar":ui.show_bar=runtime_value!=0;break;
        case "show_kr":ui.show_kr=runtime_value!=0;break;
        case "show_numbers":ui.show_numbers=runtime_value!=0;break;
        case "show_shield":ui.show_shield=runtime_value!=0;break;
        case "show_overhead":ui.show_overhead=runtime_value!=0;break;
        case "shield_hud_mode":if(instance_exists(battle)) battle._shield_hud_mode=clamp(round(runtime_value),0,1);break;
        default:return 0;
    }
    return 1;
}

function BattleEditor_RuntimeButtonTypesForTarget(target_type) {
    switch(target_type){
        case "battle_buttons":return [battle_button_fight,battle_button_act,battle_button_item,battle_button_mercy];
        case "button_fight":return [battle_button_fight];
        case "button_act":return [battle_button_act];
        case "button_item":return [battle_button_item];
        case "button_mercy":return [battle_button_mercy];
    }
    return [];
}

function BattleEditor_RuntimeControlButtons(controller,step,runtime_value) {
    if(step.target!="battle_buttons") return 0;
    var button_types=BattleEditor_RuntimeButtonTypesForTarget(step.target_type);
    if(array_length(button_types)<=0) return 0;
    var instances=[];
    for(var type_index=0;type_index<array_length(button_types);type_index++){
        var button_count=instance_number(button_types[type_index]);
        for(var button_index=0;button_index<button_count;button_index++) array_push(instances,instance_find(button_types[type_index],button_index));
    }
    if(array_length(instances)<=0) return 0;
    if(step.property=="position"){
        var has_x=string_length(string(step.position_x))>0;
        var has_y=string_length(string(step.position_y))>0;
        var has_angle=struct_exists(step,"position_angle")&&string_length(string(step.position_angle))>0;
        var anchor=instances[0];
        var dx=has_x?(step.coordinate_mode=="relative"?BattleEditor_RuntimeNumber(controller,step.position_x,0):BattleEditor_RuntimeNumber(controller,step.position_x,anchor.x)-anchor.x):0;
        var dy=has_y?(step.coordinate_mode=="relative"?BattleEditor_RuntimeNumber(controller,step.position_y,0):BattleEditor_RuntimeNumber(controller,step.position_y,anchor.y)-anchor.y):0;
        for(var position_index=0;position_index<array_length(instances);position_index++){
            var position_button=instances[position_index];
            if(has_x) BattleEditor_RuntimeSetRawInstanceProperty(position_button,"x",position_button.x+dx,step.duration,step.tween,step.ease);
            if(has_y) BattleEditor_RuntimeSetRawInstanceProperty(position_button,"y",position_button.y+dy,step.duration,step.tween,step.ease);
            if(has_angle){
                var button_angle_input=BattleEditor_RuntimeNumber(controller,step.position_angle,0);
                var button_angle_target=step.coordinate_mode=="relative"?position_button.image_angle+button_angle_input:button_angle_input;
                BattleEditor_RuntimeSetRawInstanceProperty(position_button,"image_angle",button_angle_target,step.duration,step.tween,step.ease);
            }
        }
        return (has_x||has_y||has_angle)?array_length(instances):0;
    }
    var raw_property=step.property=="angle"?"image_angle":(step.property=="scale_x"?"image_xscale":(step.property=="scale_y"?"image_yscale":""));
    if(raw_property=="") return 0;
    for(var property_index=0;property_index<array_length(instances);property_index++) BattleEditor_RuntimeSetRawInstanceProperty(instances[property_index],raw_property,runtime_value,step.duration,step.tween,step.ease);
    return array_length(instances);
}

function BattleEditor_RuntimeBoardBounds(board) {
    if(variable_struct_exists(board,"radius_x")) return [max(0,board.radius_x)*2,max(0,board.radius_y)*2];
    if(variable_struct_exists(board,"up")&&variable_struct_exists(board,"down")&&variable_struct_exists(board,"left")&&variable_struct_exists(board,"right")) return [max(0,board.left+board.right),max(0,board.up+board.down)];
    if(!variable_struct_exists(board,"listVertex")||array_length(board.listVertex)<=0) return [60,60];
    var min_x=1000000,max_x=-1000000,min_y=1000000,max_y=-1000000;
    for(var i=0;i<array_length(board.listVertex);i++){
        var point=board.listVertex[i];
        min_x=min(min_x,point[0]);max_x=max(max_x,point[0]);
        min_y=min(min_y,point[1]);max_y=max(max_y,point[1]);
    }
    return [max(0,max_x-min_x),max(0,max_y-min_y)];
}

function BattleEditor_RuntimeConvertBoard(controller,old_board,shape_index) {
    if(!is_struct(old_board)||old_board._destroyed) return undefined;
    shape_index=clamp(round(shape_index),0,3);
    var bounds=BattleEditor_RuntimeBoardBounds(old_board);
    var half_width=max(0,bounds[0]*0.5),half_height=max(0,bounds[1]*0.5);
    var next_board;
    if(shape_index==0){
        next_board=Battle_CreateBoardRect(old_board.x,old_board.y,half_height,half_height,half_width,half_width,old_board.board_depth,old_board.angle,old_board.rotate,old_board.cover);
        next_board.editor_shape="rect";
    }else if(shape_index==1){
        next_board=Battle_CreateBoardEllipse(old_board.x,old_board.y,half_width,half_height,old_board.board_depth,old_board.angle,old_board.rotate,old_board.cover);
        next_board.editor_shape="circle";
    }else{
        next_board=Battle_CreateBoardPoints(old_board.x,old_board.y,old_board.board_depth,old_board.angle,old_board.rotate,old_board.cover);
        if(shape_index==2){
            var triangle_size=max(half_width,half_height);
            Battle_AddBoardVertex(next_board,0,-triangle_size);
            Battle_AddBoardVertex(next_board,triangle_size*0.866,triangle_size*0.5);
            Battle_AddBoardVertex(next_board,-triangle_size*0.866,triangle_size*0.5);
            next_board.editor_triangle_size=triangle_size;
            next_board.editor_shape="triangle";
        }else{
            if(variable_struct_exists(old_board,"listVertex")&&array_length(old_board.listVertex)>=3){
                for(var vertex_index=0;vertex_index<array_length(old_board.listVertex);vertex_index++) Battle_AddBoardVertex(next_board,old_board.listVertex[vertex_index][0],old_board.listVertex[vertex_index][1]);
            }else{
                Battle_AddBoardVertex(next_board,-half_width,-half_height);
                Battle_AddBoardVertex(next_board,half_width,-half_height);
                Battle_AddBoardVertex(next_board,half_width,half_height);
                Battle_AddBoardVertex(next_board,-half_width,half_height);
            }
            next_board.editor_shape="polygon";
        }
    }
    next_board.color_frame=old_board.color_frame;
    var metadata=["editor_uid","editor_name","control_id","editor_control_uid","editor_target_type","editor_preview_board","editor_preview_owner","editor_vertex_uids"];
    for(var metadata_index=0;metadata_index<array_length(metadata);metadata_index++){
        var metadata_name=metadata[metadata_index];
        if(variable_struct_exists(old_board,metadata_name)) variable_struct_set(next_board,metadata_name,variable_struct_get(old_board,metadata_name));
    }
    if(instance_exists(battle_board)&&battle_board.mainboard==old_board){
        battle_board.mainboard=next_board;
        battle_board.custom_mainboard=shape_index!=0;
    }
    for(var preview_index=0;preview_index<array_length(controller.preview_frames);preview_index++) if(controller.preview_frames[preview_index]==old_board) controller.preview_frames[preview_index]=next_board;
    BattleEditor_ForceDestroyBoard(old_board);
    return next_board;
}

function BattleEditor_RuntimeBoardShapeIndex(board) {
    if(!is_struct(board)) return 0;
    if(variable_struct_exists(board,"editor_shape")){
        switch(board.editor_shape){
            case "circle":return 1;
            case "triangle":return 2;
            case "polygon":return 3;
        }
    }
    if(variable_struct_exists(board,"radius_x")) return 1;
    if(variable_struct_exists(board,"listVertex")&&array_length(board.listVertex)==3) return 2;
    return 0;
}

function BattleEditor_RuntimeBoardShapeName(shape_index) {
    return ["rect","circle","triangle","polygon"][clamp(round(shape_index),0,3)];
}

function BattleEditor_RuntimeCopyBoardPoints(points) {
    var result=[];
    for(var i=0;i<array_length(points);i++) array_push(result,[real(points[i][0]),real(points[i][1])]);
    return result;
}

/// Produces a clockwise, top-starting perimeter with a stable point count.
/// Matching topology keeps every pair of supported board shapes morphable.
function BattleEditor_RuntimeResampleBoardContour(points,sample_count=64) {
    var clean=BattleEditor_RuntimeCopyBoardPoints(points);
    if(array_length(clean)<3) clean=[[-30,-30],[30,-30],[30,30],[-30,30]];

    var signed_area=0;
    for(var area_index=0;area_index<array_length(clean);area_index++){
        var area_a=clean[area_index],area_b=clean[(area_index+1) mod array_length(clean)];
        signed_area+=area_a[0]*area_b[1]-area_b[0]*area_a[1];
    }
    if(signed_area<0){
        var reversed=[clean[0]];
        for(var reverse_index=array_length(clean)-1;reverse_index>=1;reverse_index--) array_push(reversed,clean[reverse_index]);
        clean=reversed;
    }

    var start_index=0;
    for(var start_candidate=1;start_candidate<array_length(clean);start_candidate++){
        var candidate=clean[start_candidate],current=clean[start_index];
        if(candidate[1]<current[1]-0.001||(abs(candidate[1]-current[1])<=0.001&&abs(candidate[0])<abs(current[0]))) start_index=start_candidate;
    }
    if(start_index!=0){
        var rotated=[];
        for(var rotate_index=0;rotate_index<array_length(clean);rotate_index++) array_push(rotated,clean[(start_index+rotate_index) mod array_length(clean)]);
        clean=rotated;
    }

    var edge_lengths=[],perimeter=0;
    for(var edge_index=0;edge_index<array_length(clean);edge_index++){
        var edge_a=clean[edge_index],edge_b=clean[(edge_index+1) mod array_length(clean)];
        var edge_length=point_distance(edge_a[0],edge_a[1],edge_b[0],edge_b[1]);
        array_push(edge_lengths,edge_length);perimeter+=edge_length;
    }
    sample_count=max(3,round(sample_count));
    if(perimeter<=0.0001){
        var degenerate=[];
        for(var degenerate_index=0;degenerate_index<sample_count;degenerate_index++) array_push(degenerate,[clean[0][0],clean[0][1]]);
        return degenerate;
    }

    var result=[],walk_edge=0,walk_start=0;
    for(var sample_index=0;sample_index<sample_count;sample_index++){
        var sample_distance=perimeter*sample_index/sample_count;
        while(walk_edge<array_length(clean)-1&&sample_distance>walk_start+edge_lengths[walk_edge]){
            walk_start+=edge_lengths[walk_edge];walk_edge+=1;
        }
        var sample_a=clean[walk_edge],sample_b=clean[(walk_edge+1) mod array_length(clean)];
        var edge_amount=edge_lengths[walk_edge]<=0.0001?0:(sample_distance-walk_start)/edge_lengths[walk_edge];
        array_push(result,[lerp(sample_a[0],sample_b[0],edge_amount),lerp(sample_a[1],sample_b[1],edge_amount)]);
    }
    return result;
}

function BattleEditor_RuntimeBoardSourceContour(board) {
    if(variable_struct_exists(board,"radius_x")){
        var ellipse=[];
        for(var ellipse_index=0;ellipse_index<64;ellipse_index++){
            var ellipse_angle=ellipse_index*360/64;
            array_push(ellipse,[dsin(ellipse_angle)*board.radius_x,-dcos(ellipse_angle)*board.radius_y]);
        }
        return ellipse;
    }
    if(variable_struct_exists(board,"up")&&variable_struct_exists(board,"down")&&variable_struct_exists(board,"left")&&variable_struct_exists(board,"right")){
        var top_center=(board.right-board.left)*0.5;
        return [[top_center,-board.up],[board.right,-board.up],[board.right,board.down],[-board.left,board.down],[-board.left,-board.up]];
    }
    if(variable_struct_exists(board,"listVertex")&&array_length(board.listVertex)>=3) return BattleEditor_RuntimeCopyBoardPoints(board.listVertex);
    return [[0,-30],[30,30],[-30,30]];
}

function BattleEditor_RuntimeBoardTargetContour(board,shape_index,dimensions=undefined) {
    var bounds=BattleEditor_RuntimeBoardBounds(board);
    var target_width=is_struct(dimensions)&&struct_exists(dimensions,"width")?max(1,real(dimensions.width)):max(1,bounds[0]);
    var target_height=is_struct(dimensions)&&struct_exists(dimensions,"height")?max(1,real(dimensions.height)):max(1,bounds[1]);
    var half_width=target_width*0.5,half_height=target_height*0.5;
    if(shape_index==0) return [[0,-half_height],[half_width,-half_height],[half_width,half_height],[-half_width,half_height],[-half_width,-half_height]];
    if(shape_index==1){
        if(is_struct(dimensions)&&struct_exists(dimensions,"radius_x")) half_width=max(1,real(dimensions.radius_x));
        if(is_struct(dimensions)&&struct_exists(dimensions,"radius_y")) half_height=max(1,real(dimensions.radius_y));
        var ellipse=[];
        for(var ellipse_index=0;ellipse_index<64;ellipse_index++){
            var ellipse_angle=ellipse_index*360/64;
            array_push(ellipse,[dsin(ellipse_angle)*half_width,-dcos(ellipse_angle)*half_height]);
        }
        return ellipse;
    }
    if(shape_index==2){
        return [[0,-half_height],[half_width,half_height],[-half_width,half_height]];
    }
    // Switching to polygon means preserving the current visible outline while
    // changing it into an editable arbitrary-point board.
    return BattleEditor_RuntimeBoardSourceContour(board);
}

/// Shape morphs normalize both contours to the same convex topology before
/// playback. Re-running the general polygon validator, outline miters and fan
/// allocation for every interpolated frame was unnecessary, and the duplicate
/// work was especially visible on the first square-to-circle frame.
function BattleEditor_RuntimeUpdateConvexMorphGeometry(board) {
    if(!is_struct(board)||board._destroyed||!is_array(board.listVertex)) return false;
    var vertex_count=array_length(board.listVertex);
    board._geometry_revision+=1;
    if(vertex_count<3){
        board.listDivideIndex=[];
        board._triangulation_exact=false;
        board._convex=false;
        return false;
    }

    var first=board.listVertex[0];
    board._local_min_x=first[0];board._local_max_x=first[0];
    board._local_min_y=first[1];board._local_max_y=first[1];
    for(var bounds_index=1;bounds_index<vertex_count;bounds_index++){
        var point=board.listVertex[bounds_index];
        board._local_min_x=min(board._local_min_x,point[0]);
        board._local_max_x=max(board._local_max_x,point[0]);
        board._local_min_y=min(board._local_min_y,point[1]);
        board._local_max_y=max(board._local_max_y,point[1]);
    }
    board._convex=true;
    board._triangulation_exact=true;
    if(array_length(board.listDivideIndex)!=vertex_count-2){
        board.listDivideIndex=[];
        for(var fan_index=1;fan_index<vertex_count-1;fan_index++) array_push(board.listDivideIndex,[0,fan_index,fan_index+1]);
    }
    return true;
}

function BattleEditor_RuntimeRetargetBoardReferences(controller,old_board,next_board) {
    if(instance_exists(battle_board)&&battle_board.mainboard==old_board){
        battle_board.mainboard=next_board;
        battle_board.custom_mainboard=true;
    }
    for(var preview_index=0;preview_index<array_length(controller.preview_frames);preview_index++) if(controller.preview_frames[preview_index]==old_board) controller.preview_frames[preview_index]=next_board;
    for(var vertex_index=0;vertex_index<array_length(controller.script_vertex_animations);vertex_index++) if(controller.script_vertex_animations[vertex_index].target==old_board) controller.script_vertex_animations[vertex_index].target=next_board;
    for(var pattern_index=0;pattern_index<array_length(controller.script_patterns);pattern_index++){
        var pattern=controller.script_patterns[pattern_index];
        if(variable_struct_exists(pattern,"target")&&pattern.target==old_board) pattern.target=next_board;
        if(variable_struct_exists(pattern,"follow_board")&&pattern.follow_board==old_board) pattern.follow_board=next_board;
        if(variable_struct_exists(pattern,"entries")) for(var entry_index=0;entry_index<array_length(pattern.entries);entry_index++) if(pattern.entries[entry_index].target==old_board) pattern.entries[entry_index].target=next_board;
    }
}

function BattleEditor_RuntimeStartBoardMorph(controller,old_board,shape_index,duration,tween,ease,dimensions=undefined,explicit_target=undefined) {
    if(!is_struct(old_board)||old_board._destroyed) return undefined;
    shape_index=clamp(round(shape_index),0,3);
    var source_shape=BattleEditor_RuntimeBoardShapeIndex(old_board);
    if(source_shape==shape_index&&is_undefined(dimensions)&&is_undefined(explicit_target)&&(!variable_struct_exists(old_board,"editor_morphing")||!old_board.editor_morphing)) return old_board;

    for(var old_pattern_index=array_length(controller.script_patterns)-1;old_pattern_index>=0;old_pattern_index--){
        var old_pattern=controller.script_patterns[old_pattern_index];
        if(old_pattern.kind=="board_shape_morph"&&old_pattern.target==old_board) array_delete(controller.script_patterns,old_pattern_index,1);
    }

    // 32 points are already sub-pixel smooth at the editor's 640x480 render
    // scale and quarter the composite-boundary work of the former 64x64 path.
    var source_points=BattleEditor_RuntimeResampleBoardContour(BattleEditor_RuntimeBoardSourceContour(old_board),32);
    var target_contour=is_array(explicit_target)?explicit_target:BattleEditor_RuntimeBoardTargetContour(old_board,shape_index,dimensions);
    var target_points=BattleEditor_RuntimeResampleBoardContour(target_contour,32);
    var morph_bounds=BattleEditor_RuntimeBoardBounds(old_board);
    var target_triangle_size=shape_index==2?(is_struct(dimensions)&&struct_exists(dimensions,"height")?real(dimensions.height)*0.5:max(morph_bounds[0],morph_bounds[1])*0.5):0;
    var morph_board=old_board;
    if(variable_struct_exists(old_board,"radius_x")){
        morph_board=Battle_CreateBoardPoints(old_board.x,old_board.y,old_board.board_depth,old_board.angle,old_board.rotate,old_board.cover);
        morph_board.color_frame=old_board.color_frame;
        var metadata=["editor_uid","editor_name","control_id","editor_control_uid","editor_target_type","editor_preview_board","editor_preview_owner","editor_vertex_uids"];
        for(var metadata_index=0;metadata_index<array_length(metadata);metadata_index++){
            var metadata_name=metadata[metadata_index];
            if(variable_struct_exists(old_board,metadata_name)) variable_struct_set(morph_board,metadata_name,variable_struct_get(old_board,metadata_name));
        }
        BattleEditor_RuntimeRetargetBoardReferences(controller,old_board,morph_board);
        BattleEditor_ForceDestroyBoard(old_board);
    }else{
        if(variable_struct_exists(morph_board,"up")) variable_struct_remove(morph_board,"up");
        if(variable_struct_exists(morph_board,"down")) variable_struct_remove(morph_board,"down");
        if(variable_struct_exists(morph_board,"left")) variable_struct_remove(morph_board,"left");
        if(variable_struct_exists(morph_board,"right")) variable_struct_remove(morph_board,"right");
        morph_board.rect=0;
        morph_board.update=method(morph_board,function(){self.angle+=self.rotate;});
        if(instance_exists(battle_board)&&battle_board.mainboard==morph_board) battle_board.custom_mainboard=true;
    }
    if(duration<=0){
        morph_board.listVertex=BattleEditor_RuntimeCopyBoardPoints(target_points);
        morph_board.updateDivide();
        morph_board.editor_morphing=false;
        morph_board.editor_shape=BattleEditor_RuntimeBoardShapeName(shape_index);
        if(shape_index==2) morph_board.editor_triangle_size=target_triangle_size;
        return morph_board;
    }
    morph_board.listVertex=BattleEditor_RuntimeCopyBoardPoints(source_points);
    // RuntimePatternStep runs later in this same Step event and establishes the
    // first visible interpolated frame. Do not triangulate this hidden source
    // pose here and then immediately triangulate it again.
    morph_board.editor_morphing=true;
    morph_board.editor_shape=BattleEditor_RuntimeBoardShapeName(source_shape);
    array_push(controller.script_patterns,{kind:"board_shape_morph",age:0,duration:max(1,abs(duration)),target:morph_board,start_points:source_points,target_points:target_points,target_shape:BattleEditor_RuntimeBoardShapeName(shape_index),target_triangle_size:target_triangle_size,tween:tween,ease:ease});
    return morph_board;
}

function BattleEditor_RuntimeStartBoardMorphByControlId(controller,control_id,shape_index,duration,tween,ease) {
    control_id=string(control_id);
    var targets=[];
    if(instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed&&variable_struct_exists(battle_board.mainboard,"control_id")&&string(battle_board.mainboard.control_id)==control_id) array_push(targets,battle_board.mainboard);
    for(var preview_index=0;preview_index<array_length(controller.preview_frames);preview_index++){
        var candidate=controller.preview_frames[preview_index],already_added=false;
        for(var target_index=0;target_index<array_length(targets);target_index++) if(targets[target_index]==candidate){already_added=true;break;}
        if(!already_added&&is_struct(candidate)&&!candidate._destroyed&&variable_struct_exists(candidate,"control_id")&&string(candidate.control_id)==control_id) array_push(targets,candidate);
    }
    for(var target_index=0;target_index<array_length(targets);target_index++) BattleEditor_RuntimeStartBoardMorph(controller,targets[target_index],shape_index,duration,tween,ease);
    return array_length(targets);
}

function BattleEditor_RuntimeSetBoardDimension(controller,board,property_name,value,duration,tween,ease) {
    if(!is_struct(board)||board._destroyed) return false;
    value=max(0,value);
    var source_contour=BattleEditor_RuntimeBoardSourceContour(board);
    if(array_length(source_contour)<3) return false;
    var min_x=source_contour[0][0],max_x=min_x,min_y=source_contour[0][1],max_y=min_y;
    for(var source_index=1;source_index<array_length(source_contour);source_index++){
        min_x=min(min_x,source_contour[source_index][0]);max_x=max(max_x,source_contour[source_index][0]);
        min_y=min(min_y,source_contour[source_index][1]);max_y=max(max_y,source_contour[source_index][1]);
    }
    var old_width=max(0.0001,max_x-min_x),old_height=max(0.0001,max_y-min_y);
    var next_min_x=min_x,next_max_x=max_x,next_min_y=min_y,next_max_y=max_y;
    if(property_name=="width"){next_min_x=-value*0.5;next_max_x=value*0.5;}
    else if(property_name=="height"){next_min_y=-value*0.5;next_max_y=value*0.5;}
    else if(property_name=="radius_x"){next_min_x=-value;next_max_x=value;}
    else if(property_name=="radius_y"){next_min_y=-value;next_max_y=value;}
    else if(property_name=="triangle_size"){
        var size_scale=value/max(0.0001,max(old_width,old_height)*0.5);
        next_min_x=min_x*size_scale;next_max_x=max_x*size_scale;next_min_y=min_y*size_scale;next_max_y=max_y*size_scale;
    }else if(property_name=="up") next_min_y=-value;
    else if(property_name=="down") next_max_y=value;
    else if(property_name=="left") next_min_x=-value;
    else if(property_name=="right") next_max_x=value;
    else return false;
    var target_contour=[];
    for(var point_index=0;point_index<array_length(source_contour);point_index++){
        var source_point=source_contour[point_index];
        var px=lerp(next_min_x,next_max_x,(source_point[0]-min_x)/old_width);
        var py=lerp(next_min_y,next_max_y,(source_point[1]-min_y)/old_height);
        array_push(target_contour,[px,py]);
    }
    var shape_index=BattleEditor_RuntimeBoardShapeIndex(board);
    return !is_undefined(BattleEditor_RuntimeStartBoardMorph(controller,board,shape_index,duration,tween,ease,undefined,target_contour));
}

function BattleEditor_RuntimeControlSystemTargets(controller,step,runtime_value) {
    var changed=0;
    changed+=BattleEditor_RuntimeControlPlayerData(controller,step,runtime_value);
    changed+=BattleEditor_RuntimeControlSoul(controller,step,runtime_value);
    changed+=BattleEditor_RuntimeControlHud(controller,step,runtime_value);
    changed+=BattleEditor_RuntimeControlButtons(controller,step,runtime_value);
    if(step.target_type=="enemy"){
        var enemies=controller.project.initialization.enemies;
        for(var enemy_index=0;enemy_index<array_length(enemies);enemy_index++){
            var enemy=enemies[enemy_index];
            if(!BattleEditor_RuntimeTargetMatches(enemy,step)) continue;
            if(step.property=="position"?BattleEditor_RuntimeControlPosition(controller,enemy,step):BattleEditor_RuntimeSetProperty(enemy,step.property,runtime_value,step.duration,step.tween,step.ease)) changed+=1;
        }
    }
    return changed;
}

function BattleEditor_RuntimeApplyObjectControl(controller,target,step,runtime_value) {
    var applied_duration=BattleEditor_ControlStepUsesDuration(step)?step.duration:0;
    if(step.target_type=="board"&&is_struct(target)){
        if(step.property=="shape"){
            var shape_dimensions={
                width:BattleEditor_RuntimeNumber(controller,runtime_value==2?step.board_shape_triangle_width:step.board_shape_width,80),
                height:BattleEditor_RuntimeNumber(controller,runtime_value==2?step.board_shape_triangle_height:step.board_shape_height,80),
                radius_x:BattleEditor_RuntimeNumber(controller,step.board_shape_radius_x,40),
                radius_y:BattleEditor_RuntimeNumber(controller,step.board_shape_radius_y,40)
            };
            return !is_undefined(BattleEditor_RuntimeStartBoardMorph(controller,target,runtime_value,applied_duration,step.tween,step.ease,shape_dimensions));
        }
        if(step.property=="width"||step.property=="height"||step.property=="radius_x"||step.property=="radius_y"||step.property=="triangle_size"||step.property=="up"||step.property=="down"||step.property=="left"||step.property=="right") return BattleEditor_RuntimeSetBoardDimension(controller,target,step.property,runtime_value,applied_duration,step.tween,step.ease);
    }
    if(step.property=="text"&&instance_exists(target)&&variable_instance_exists(target,"ChangeText")){target.ChangeText(TextTyper_CompileMarkup(step.text_value).text);return true;}
    if(step.property=="position"){
        if(step.target_type=="board"&&is_struct(target)) return BattleEditor_RuntimeControlBoardTransform(controller,target,step);
        return BattleEditor_RuntimeControlPosition(controller,target,step);
    }
    if(step.property=="damage_type") return BattleEditor_RuntimeSetDamageType(target,runtime_value,struct_exists(step,"damage_change_visual")?step.damage_change_visual:true);
    if(step.property=="visual_color") return BattleEditor_RuntimeSetVisualColor(target,runtime_value,applied_duration,step.tween,step.ease);
    if(step.property=="control_vertex") return BattleEditor_RuntimeControlVertices(controller,target,step);
    if(step.property=="vertices") return BattleEditor_RuntimeSetVertices(target,step.points);
    return BattleEditor_RuntimeSetProperty(target,step.property,runtime_value,applied_duration,step.tween,step.ease);
}

function BattleEditor_LengthAnchorName(anchor) {
    switch(clamp(round(real(anchor)),0,2)){
        case 1:return "头端固定";
        case 2:return "尾端固定";
    }
    return "中心（两端）";
}

function BattleEditor_LengthAnchorDescription(anchor) {
    switch(clamp(round(real(anchor)),0,2)){
        case 1:return "头端固定（向尾端伸缩）";
        case 2:return "尾端固定（向头端伸缩）";
    }
    return "中心（两端一起伸缩）";
}

function BattleEditor_RuntimeApplyBoneLengthEntry(entry,new_length) {
    var target=entry.target;
    if(!instance_exists(target)) return false;
    target.length=new_length;
    if(entry.anchor==0) return true;
    var angle_property=entry.followed?"_angle":"angle";
    var current_angle=variable_instance_exists(target,angle_property)?variable_instance_get(target,angle_property):entry.start_angle;
    var visual_length=max(0,new_length)+10;
    var axis_x=lengthdir_x(visual_length,current_angle),axis_y=lengthdir_y(visual_length,current_angle);
    var next_x,next_y;
    if(entry.anchor==1){
        // Head is the endpoint-origin used by point=1 and the negative local
        // endpoint used by the centre-origin sprite.
        if(entry.point_mode==1){next_x=entry.fixed_x;next_y=entry.fixed_y;}
        else{next_x=entry.fixed_x+axis_x*0.5;next_y=entry.fixed_y+axis_y*0.5;}
    }else{
        if(entry.point_mode==1){next_x=entry.fixed_x-axis_x;next_y=entry.fixed_y-axis_y;}
        else{next_x=entry.fixed_x-axis_x*0.5;next_y=entry.fixed_y-axis_y*0.5;}
    }
    if(entry.followed){target._x=next_x;target._y=next_y;}
    else{target.x=next_x;target.y=next_y;}
    return true;
}

function BattleEditor_RuntimeStartBoneLengthControl(controller,step,target_length) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    var entries=[];
    var anchor=clamp(round(real(step.length_anchor)),0,2);
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        if(!instance_exists(target)||!variable_instance_exists(target,"length")) continue;
        var followed=variable_instance_exists(target,"follow")&&target.follow;
        var px=followed&&variable_instance_exists(target,"_x")?target._x:target.x;
        var py=followed&&variable_instance_exists(target,"_y")?target._y:target.y;
        var local_angle=followed&&variable_instance_exists(target,"_angle")?target._angle:target.angle;
        var start_length=real(target.length),visual_length=max(0,start_length)+10;
        var axis_x=lengthdir_x(visual_length,local_angle),axis_y=lengthdir_y(visual_length,local_angle);
        var point_mode=variable_instance_exists(target,"point")?round(real(target.point)):0;
        var head_x=point_mode==1?px:px-axis_x*0.5;
        var head_y=point_mode==1?py:py-axis_y*0.5;
        var tail_x=point_mode==1?px+axis_x:px+axis_x*0.5;
        var tail_y=point_mode==1?py+axis_y:py+axis_y*0.5;
        array_push(entries,{target:target,anchor:anchor,point_mode:point_mode,followed:followed,start_angle:local_angle,start_length:start_length,target_length:target_length,fixed_x:anchor==2?tail_x:head_x,fixed_y:anchor==2?tail_y:head_y});
    }
    if(step.duration<=0){
        for(var i=0;i<array_length(entries);i++) BattleEditor_RuntimeApplyBoneLengthEntry(entries[i],target_length);
    }else if(array_length(entries)>0){
        array_push(controller.script_patterns,{kind:"control_bone_length",age:0,duration:max(1,step.duration),tween:step.tween,ease:step.ease,entries:entries});
    }
    return array_length(entries);
}

function BattleEditor_RuntimeOrbitAngleProperty(target,target_type) {
    if(target_type=="typewriter") return "_angle";
    if(target_type=="decoration"||target_type=="sprite_hazard"||target_type=="slash"||target_type=="true_knife") return "image_angle";
    if(target_type=="bone_3d"||target_type=="bone_4d") return "anglez";
    return "angle";
}

function BattleEditor_RuntimeTargetHasPosition(target) {
    if(is_struct(target)) return variable_struct_exists(target,"x")&&variable_struct_exists(target,"y");
    return instance_exists(target)&&variable_instance_exists(target,"x")&&variable_instance_exists(target,"y");
}

function BattleEditor_RuntimeTargetAlreadyCollected(targets,candidate) {
    for(var i=0;i<array_length(targets);i++) if(targets[i]==candidate) return true;
    return false;
}

function BattleEditor_RuntimeCollectPositionTarget(targets,candidate) {
    if(!BattleEditor_RuntimeTargetHasPosition(candidate)||BattleEditor_RuntimeTargetAlreadyCollected(targets,candidate)) return false;
    array_push(targets,candidate);
    return true;
}

function BattleEditor_RuntimePatternControllerKind(pattern) {
    if(!is_struct(pattern)) return "";
    if(struct_exists(pattern,"controller_kind")) return string(pattern.controller_kind);
    if(pattern.kind=="bone_orbit"||pattern.kind=="bone_wave"||pattern.kind=="bone_wall"||pattern.kind=="bone_function_path") return string(pattern.kind);
    if(pattern.kind=="gb_pinwheel_sequence") return "gb_pinwheel";
    return "";
}

function BattleEditor_RuntimePatternControllerMatches(pattern,step) {
    if(!is_struct(pattern)||!struct_exists(pattern,"anchor")||!is_struct(pattern.anchor)) return false;
    if(string(pattern.anchor.control_id)!=string(step.target)) return false;
    var wanted_kind=struct_exists(step,"target_group_kind")?string(step.target_group_kind):"";
    return wanted_kind==""||BattleEditor_RuntimePatternControllerKind(pattern)==wanted_kind;
}

function BattleEditor_RuntimePatternHasMember(pattern,step) {
    if(!is_struct(pattern)||step.target_type=="path_point") return false;
    if(struct_exists(pattern,"bones")&&is_array(pattern.bones)){
        for(var i=0;i<array_length(pattern.bones);i++) if(BattleEditor_RuntimeTargetMatches(pattern.bones[i],step)) return true;
    }
    if(struct_exists(pattern,"members")&&is_array(pattern.members)){
        for(var i=0;i<array_length(pattern.members);i++) if(BattleEditor_RuntimeTargetMatches(pattern.members[i],step)) return true;
    }
    if(struct_exists(pattern,"entries")&&is_array(pattern.entries)){
        for(var i=0;i<array_length(pattern.entries);i++) if(struct_exists(pattern.entries[i],"target")&&BattleEditor_RuntimeTargetMatches(pattern.entries[i].target,step)) return true;
    }
    return false;
}

function BattleEditor_RuntimeGeneratedGroupAnchors(controller,step) {
    var result=[];
    for(var pattern_index=0;pattern_index<array_length(controller.script_patterns);pattern_index++){
        var pattern=controller.script_patterns[pattern_index];
        if(BattleEditor_RuntimePatternHasMember(pattern,step)&&struct_exists(pattern,"anchor")&&is_struct(pattern.anchor)) BattleEditor_RuntimeCollectPositionTarget(result,pattern.anchor);
    }
    return result;
}

function BattleEditor_RuntimeCollectControlTargets(controller,step) {
    var result=[];
    if(step.target_type=="path_point"){
        for(var controller_index=0;controller_index<array_length(controller.script_patterns);controller_index++){
            var controller_pattern=controller.script_patterns[controller_index];
            if(BattleEditor_RuntimePatternControllerMatches(controller_pattern,step)) BattleEditor_RuntimeCollectPositionTarget(result,controller_pattern.anchor);
        }
        return result;
    }
    if(step.property=="orbit"||step.property=="physics"||step.property=="aim_motion"){
        var generated_anchors=BattleEditor_RuntimeGeneratedGroupAnchors(controller,step);
        if(array_length(generated_anchors)>0) return generated_anchors;
    }
    for(var i=0;i<array_length(controller.runtime_instances);i++){
        var candidate=controller.runtime_instances[i];
        // runtime_instances is already unique by its owner marker. Running a
        // second growing-array duplicate scan here made selecting a large
        // generated Control ID quadratic before the control even started.
        if(BattleEditor_RuntimeTargetMatches(candidate,step)&&BattleEditor_RuntimeTargetHasPosition(candidate)) array_push(result,candidate);
    }
    if(instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&BattleEditor_RuntimeTargetMatches(battle_board.mainboard,step)) BattleEditor_RuntimeCollectPositionTarget(result,battle_board.mainboard);
    for(var i=0;i<array_length(controller.preview_frames);i++) if(BattleEditor_RuntimeTargetMatches(controller.preview_frames[i],step)) BattleEditor_RuntimeCollectPositionTarget(result,controller.preview_frames[i]);
    if(step.target_type=="soul"&&step.target=="soul"&&instance_exists(battle_soul)) BattleEditor_RuntimeCollectPositionTarget(result,instance_find(battle_soul,0));
    if(step.target_type=="hud_all"&&step.target=="hud"&&instance_exists(battle_ui)) BattleEditor_RuntimeCollectPositionTarget(result,instance_find(battle_ui,0));
    if(step.target=="battle_buttons"){
        var button_types=BattleEditor_RuntimeButtonTypesForTarget(step.target_type);
        for(var type_index=0;type_index<array_length(button_types);type_index++) for(var button_index=0;button_index<instance_number(button_types[type_index]);button_index++) BattleEditor_RuntimeCollectPositionTarget(result,instance_find(button_types[type_index],button_index));
    }
    if(step.target_type=="enemy"){
        for(var enemy_index=0;enemy_index<array_length(controller.project.initialization.enemies);enemy_index++){
            var enemy_data=controller.project.initialization.enemies[enemy_index];
            if(BattleEditor_RuntimeTargetMatches(enemy_data,step)) BattleEditor_RuntimeCollectPositionTarget(result,enemy_data);
        }
    }
    // Arrangement centres are lightweight runtime targets, not hidden object
    // instances. They still participate in the exact same position/orbit/
    // physics operators as ordinary objects.
    for(var pattern_index=0;pattern_index<array_length(controller.script_patterns);pattern_index++){
        var pattern=controller.script_patterns[pattern_index];
        if(is_struct(pattern)&&struct_exists(pattern,"anchor")&&is_struct(pattern.anchor)&&BattleEditor_RuntimeTargetMatches(pattern.anchor,step)) BattleEditor_RuntimeCollectPositionTarget(result,pattern.anchor);
    }
    return result;
}

function BattleEditor_RuntimeApplyOrbitEntry(entry,amount,turn_self) {
    var target=entry.target;
    if(is_struct(target)){
        if(variable_struct_exists(target,"_destroyed")&&target._destroyed) return false;
    }else if(!instance_exists(target)) return false;
    var rotated=RotateAround(entry.center_x,entry.center_y,entry.start_x,entry.start_y,entry.center_x,entry.center_y,amount);
    if(is_struct(target)){
        variable_struct_set(target,"x",rotated[0]);variable_struct_set(target,"y",rotated[1]);
        if(turn_self&&variable_struct_exists(target,entry.angle_property)) variable_struct_set(target,entry.angle_property,entry.start_angle+amount);
    }else{
        target.x=rotated[0];target.y=rotated[1];
        if(turn_self&&variable_instance_exists(target,entry.angle_property)) variable_instance_set(target,entry.angle_property,entry.start_angle+amount);
    }
    return true;
}

function BattleEditor_RuntimeStartOrbitControl(controller,step) {
    // GB has its own spawn/target/beam coordinate system and is intentionally
    // kept out of this generic world-space operator.
    if(step.target_type=="gb") return 0;
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    if(array_length(targets)<=0) return 0;
    var center_x=0,center_y=0;
    for(var i=0;i<array_length(targets);i++){
        center_x+=is_struct(targets[i])?variable_struct_get(targets[i],"x"):targets[i].x;
        center_y+=is_struct(targets[i])?variable_struct_get(targets[i],"y"):targets[i].y;
    }
    center_x/=array_length(targets);center_y/=array_length(targets);
    if(!step.orbit_use_group_center){
        center_x=BattleEditor_RuntimeNumber(controller,step.orbit_center_x,center_x);
        center_y=BattleEditor_RuntimeNumber(controller,step.orbit_center_y,center_y);
    }
    var entries=[];
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:step.target_type):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:step.target_type);
        var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
        var start_angle=0;
        if(is_struct(target)){if(variable_struct_exists(target,angle_property)) start_angle=variable_struct_get(target,angle_property);}
        else if(variable_instance_exists(target,angle_property)) start_angle=variable_instance_get(target,angle_property);
        array_push(entries,{target:target,start_x:is_struct(target)?variable_struct_get(target,"x"):target.x,start_y:is_struct(target)?variable_struct_get(target,"y"):target.y,start_angle:start_angle,angle_property:angle_property,center_x:center_x,center_y:center_y});
    }
    var degrees=BattleEditor_RuntimeNumber(controller,step.value,0);
    // An orbit is a complete world-space rotation. Leaving the target's own
    // angle unchanged produced a sideways-moving object and was never useful
    // as the editor's rotation operation.
    var turn_self=true;
    if(step.duration<=0){for(var i=0;i<array_length(entries);i++) BattleEditor_RuntimeApplyOrbitEntry(entries[i],degrees,turn_self);}
    else array_push(controller.script_patterns,{kind:"control_orbit",age:0,duration:max(1,step.duration),degrees:degrees,turn_self:turn_self,tween:step.tween,ease:step.ease,entries:entries});
    return array_length(entries);
}

function BattleEditor_RuntimeApplyPhysicsEntry(entry,delta) {
    var target=entry.target;
    if(is_struct(target)){
        if(variable_struct_exists(target,"_destroyed")&&target._destroyed) return false;
    }else if(!instance_exists(target)) return false;
    entry.direction+=entry.curve_speed*delta;
    entry.speed+=entry.acceleration*delta;
    var dx=lengthdir_x(entry.speed*delta,entry.direction),dy=lengthdir_y(entry.speed*delta,entry.direction);
    if(is_struct(target)){
        variable_struct_set(target,"x",variable_struct_get(target,"x")+dx);
        variable_struct_set(target,"y",variable_struct_get(target,"y")+dy);
        if(entry.rotation_speed!=0&&variable_struct_exists(target,entry.angle_property)) variable_struct_set(target,entry.angle_property,variable_struct_get(target,entry.angle_property)+entry.rotation_speed*delta);
    }else{
        target.x+=dx;target.y+=dy;
        if(entry.rotation_speed!=0&&variable_instance_exists(target,entry.angle_property)) variable_instance_set(target,entry.angle_property,variable_instance_get(target,entry.angle_property)+entry.rotation_speed*delta);
    }
    return true;
}

function BattleEditor_RuntimeStartPhysicsControl(controller,step) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    if(array_length(targets)<=0) return 0;
    var move_direction=BattleEditor_RuntimeNumber(controller,step.physics_direction,0);
    var move_speed=BattleEditor_RuntimeNumber(controller,step.physics_speed,0);
    var move_acceleration=BattleEditor_RuntimeNumber(controller,step.physics_acceleration,0);
    var move_curve_speed=BattleEditor_RuntimeNumber(controller,step.physics_curve_speed,0);
    var body_rotation_speed=BattleEditor_RuntimeNumber(controller,step.physics_rotation_speed,0);
    var entries=[];
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:step.target_type):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:step.target_type);
        if(!is_struct(target)&&target_type=="bone"&&variable_instance_exists(target,"follow")&&target.follow){target.follow=false;target.follow_board=false;}
        array_push(entries,{target:target,direction:move_direction,speed:move_speed,acceleration:move_acceleration,curve_speed:move_curve_speed,rotation_speed:body_rotation_speed,angle_property:BattleEditor_RuntimeOrbitAngleProperty(target,target_type)});
    }
    array_push(controller.script_patterns,{kind:"control_physics",age:0,duration:max(1,step.duration),entries:entries});
    return array_length(entries);
}

function BattleEditor_RuntimeSetAimFacing(target,angle_property,aim_angle) {
    if(is_struct(target)){
        if(variable_struct_exists(target,"_destroyed")&&target._destroyed) return false;
        if(!variable_struct_exists(target,angle_property)) return false;
        variable_struct_set(target,angle_property,aim_angle);
        return true;
    }
    if(!instance_exists(target)||!variable_instance_exists(target,angle_property)) return false;
    variable_instance_set(target,angle_property,aim_angle);
    return true;
}

/// Capture-and-fire and homing use one generic control path. Locked mode keeps
/// the direction sampled on this exact execution frame and therefore passes
/// the player's old position instead of steering back toward it. Continuous
/// mode is the explicitly selected homing behaviour.
function BattleEditor_RuntimeStartAimMotion(controller,step) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    if(array_length(targets)<=0) return 0;
    var aim_point=BattleEditor_RuntimePointTarget(controller,step.aim_target_uid);
    if(!aim_point[0]) return 0;
    var aim_behavior=struct_exists(step,"aim_behavior")?clamp(round(real(step.aim_behavior)),0,2):BattleEditor_AimBehaviorFromLegacy(step.aim_move_speed,step.aim_face_target);
    var aim_faces=aim_behavior!=2;
    var entries=[];
    for(var target_index=0;target_index<array_length(targets);target_index++){
        var target=targets[target_index];
        if(!BattleEditor_RuntimeTargetHasPosition(target)) continue;
        var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:step.target_type):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:step.target_type);
        // Native Bone follow and its old event-level aim would otherwise
        // overwrite this generic world-space operation on the following Step.
        if(!is_struct(target)&&variable_instance_exists(target,"follow")&&target.follow){target.follow=false;target.follow_board=false;}
        if(!is_struct(target)&&variable_instance_exists(target,"editor_aim_enabled")) target.editor_aim_enabled=false;
        var aim_direction=point_direction(target.x,target.y,aim_point[1],aim_point[2]);
        var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
        if(aim_faces) BattleEditor_RuntimeSetAimFacing(target,angle_property,aim_direction);
        array_push(entries,{target:target,target_type:target_type,direction:aim_direction,angle_property:angle_property});
    }
    if(array_length(entries)<=0) return 0;
    array_push(controller.script_patterns,{
        kind:"control_aim_motion",age:0,duration:max(1,step.duration),entries:entries,
        target_uid:step.aim_target_uid,continuous:step.aim_continuous,
        speed:aim_behavior==0?0:BattleEditor_RuntimeNumber(controller,step.aim_move_speed,0),face_target:aim_faces
    });
    return array_length(entries);
}

function BattleEditor_RuntimeGBSetHold(controller,step,play_move_sound=false) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step),changed=0;
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        if(!instance_exists(target)||!variable_instance_exists(target,"editor_gb_released")||target.editor_gb_released) continue;
        target.editor_gb_force_release=false;
        target.time_release_delay=max(999,target.time_release_delay);
        target.alarm[1]=max(target.alarm[1],ceil(999/max(0.0001,global.delta_time_factor))+1);
        changed+=1;
    }
    if(changed>0&&play_move_sound&&step.gb_move_sound) BattleEditor_RuntimePlaySound(snd_gb_charge,0,false);
    return changed;
}

function BattleEditor_RuntimeGBRelease(controller,step) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step),changed=0;
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        if(!instance_exists(target)||!variable_instance_exists(target,"editor_gb_released")||target.editor_gb_released) continue;
        target.editor_gb_force_release=true;
        target.time_release_delay=0;
        // Before Alarm 0 the ordinary entrance still runs once. Afterwards
        // this starts the existing squeeze/release sequence on the next step.
        if(target.alarm[0]<0) target.alarm[1]=1;
        changed+=1;
    }
    return changed;
}

function BattleEditor_RuntimeEnemySpeak(controller,step) {
    controller.last_enemy_speech_bubbles=[];
    if(string_length(string(step.text_value))<=0) return 0;
    var changed=0;
    var requires_confirm=round(real(step.dialogue_mode))==1;
    for(var enemy_index=0;enemy_index<array_length(controller.project.initialization.enemies);enemy_index++){
        var enemy=controller.project.initialization.enemies[enemy_index];
        if(!BattleEditor_RuntimeTargetMatches(enemy,step)) continue;
        var bubble_x=enemy.x+BattleEditor_RuntimeNumber(controller,step.dialogue_offset_x,92);
        var bubble_y=enemy.y+BattleEditor_RuntimeNumber(controller,step.dialogue_offset_y,-34);
        var bubble=Battle_Dialog_Enemy_Add(
            bubble_x,bubble_y,DEPTH_BATTLE.UI_HIGH,
            "{font "+string(round(real(step.dialogue_font)))+"}{voice "+string(round(real(step.dialogue_voice)))+"}"+TextTyper_CompileMarkup(step.text_value).text,
            clamp(round(real(step.dialogue_template)),0,4),
            requires_confirm
        );
        if(instance_exists(bubble)) array_push(controller.last_enemy_speech_bubbles,bubble);
        changed+=1;
    }
    return changed;
}

function BattleEditor_RuntimeWarningAngle(target,target_type) {
    var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
    if(!is_struct(target)&&target_type=="bone"&&variable_instance_exists(target,"follow")&&target.follow) angle_property="_angle";
    if(is_struct(target)) return variable_struct_exists(target,angle_property)?variable_struct_get(target,angle_property):0;
    return instance_exists(target)&&variable_instance_exists(target,angle_property)?variable_instance_get(target,angle_property):0;
}

function BattleEditor_RuntimeSpawnControlWarning(controller,target,step) {
    if(!BattleEditor_RuntimeTargetHasPosition(target)) return noone;
    var target_type=is_struct(target)?(variable_struct_exists(target,"editor_target_type")?target.editor_target_type:step.target_type):(variable_instance_exists(target,"editor_target_type")?target.editor_target_type:step.target_type);
    var warning_angle=round(real(step.warning_angle_mode))==0?BattleEditor_RuntimeWarningAngle(target,target_type):BattleEditor_RuntimeNumber(controller,step.warning_angle,0);
    if(step.property=="aim_motion"&&round(real(step.warning_angle_mode))==0){
        var warning_aim_point=BattleEditor_RuntimePointTarget(controller,step.aim_target_uid);
        if(warning_aim_point[0]) warning_angle=point_direction(target.x,target.y,warning_aim_point[1],warning_aim_point[2]);
    }
    var warning=instance_create_depth(0,0,DEPTH_BATTLE.WARNING,battle_editor_decoration);
    warning.Setup({warning_kind:"line",warning_target:target,warning_angle:warning_angle,duration:max(1,step.warning_duration),layer_mode:BATTLE_EDITOR_LAYER.OUTSIDE});
    BattleEditor_RuntimeTrack(controller,warning);
    return warning;
}

function BattleEditor_RuntimeStartControlWarning(controller,step) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    if(array_length(targets)<=0) return 0;
    for(var i=0;i<array_length(targets);i++) BattleEditor_RuntimeSpawnControlWarning(controller,targets[i],step);
    var delayed_step=json_parse(json_stringify(step));
    delayed_step.warning_enabled=false;
    array_push(controller.script_patterns,{kind:"deferred_control_warning",age:0,duration:max(1,step.warning_duration),step:delayed_step});
    return array_length(targets);
}

function BattleEditor_RuntimeRetagControlTargets(targets,control_id) {
    var changed=0;
    for(var i=0;i<array_length(targets);i++){
        var target=targets[i];
        if(!instance_exists(target)) continue;
        target.control_id=control_id;
        changed+=1;
    }
    return changed;
}

/// Clone one authored scene group through the established event spawn path.
/// A private batch ID isolates this step's initial movement from older copies
/// that already share the public output ID. The public ID is restored as soon
/// as the operation has captured direct instance references.
function BattleEditor_RuntimeCloneControlBatch(controller,step) {
    if(!variable_instance_exists(controller,"runtime_copy_serial")) controller.runtime_copy_serial=0;
    controller.runtime_copy_serial+=1;
    var batch_id="__copy_"+string(step.uid)+"_"+string(controller.runtime_copy_serial);
    var output_id=string(step.copy_control_id);
    if(string_length(output_id)<=0) output_id=BattleEditor_NextCopiedControlId(controller.project,step.target);
    var targets=[];
    for(var event_index=0;event_index<array_length(controller.project.events);event_index++){
        var source=controller.project.events[event_index];
        if(!BattleEditor_EventBelongsToTurn(source,controller.script_monster_turn)) continue;
        var clone_identity_matches=struct_exists(step,"target_group_uid")&&step.target_group_uid>=0
            ?(struct_exists(source,"control_uid")&&source.control_uid==step.target_group_uid)
            :(struct_exists(source,"control_id")&&string(source.control_id)==string(step.target));
        if(!clone_identity_matches||BattleEditor_DataTargetType(source)!=step.target_type) continue;
        var copy_data=json_parse(json_stringify(source));
        copy_data.uid=-(100000000+controller.runtime_copy_serial*10000+event_index);
        copy_data.control_id=batch_id;
        copy_data.time=controller.playhead;
        var copy_instance=BattleEditor_RuntimeTrack(controller,BattleEditor_SpawnEvent(copy_data,controller.project.initialization,controller));
        if(instance_exists(copy_instance)) array_push(targets,copy_instance);
    }
    var isolated_step=json_parse(json_stringify(step));
    isolated_step.control_source_mode=0;
    isolated_step.target_mode="control_id";
    isolated_step.target=batch_id;
    return {targets:targets,batch_id:batch_id,output_id:output_id,step:isolated_step};
}

function BattleEditor_RuntimeControlObjectNow(controller,step) {
    if(step.property=="follow") return BattleEditor_RuntimeControlFollow(controller,step,real(step.value)!=0);
    if(step.property=="position"&&step.target_type!="path_point"){
        var generated_anchors=BattleEditor_RuntimeGeneratedGroupAnchors(controller,step);
        if(array_length(generated_anchors)>0){
            var generated_changed=0;
            for(var generated_anchor_index=0;generated_anchor_index<array_length(generated_anchors);generated_anchor_index++) if(BattleEditor_RuntimeControlPosition(controller,generated_anchors[generated_anchor_index],step)) generated_changed+=1;
            return generated_changed;
        }
    }
    if(step.target_type=="path_point"&&(step.property=="orbit_radius_x"||step.property=="orbit_radius_y"||step.property=="pattern_span"||step.property=="pattern_amplitude"||step.property=="pattern_speed"||step.property=="wall_extent")){
        var controller_changed=0;
        var controller_value=BattleEditor_RuntimeNumber(controller,step.value,0);
        for(var controller_index=0;controller_index<array_length(controller.script_patterns);controller_index++){
            var controller_pattern=controller.script_patterns[controller_index];
            if(!BattleEditor_RuntimePatternControllerMatches(controller_pattern,step)) continue;
            var controller_property="";
            if(step.property=="orbit_radius_x") controller_property="rx";
            else if(step.property=="orbit_radius_y") controller_property="ry";
            else if(step.property=="pattern_span") controller_property="span";
            else if(step.property=="pattern_amplitude") controller_property="wave_radius";
            else if(step.property=="pattern_speed") controller_property="pattern_speed";
            else if(step.property=="wall_extent") controller_property="distance";
            if(controller_property!=""&&struct_exists(controller_pattern,controller_property)){
                var final_controller_value=(step.property=="pattern_speed")?controller_value:max(0,controller_value);
                if(BattleEditor_RuntimeSetProperty(controller_pattern,controller_property,final_controller_value,step.duration,step.tween,step.ease)) controller_changed+=1;
            }
        }
        return controller_changed;
    }
    if(step.target_type=="gb"&&step.property=="gb_hold") return BattleEditor_RuntimeGBSetHold(controller,step,true);
    if(step.target_type=="gb"&&step.property=="gb_release") return BattleEditor_RuntimeGBRelease(controller,step);
    if(step.target_type=="enemy"&&step.property=="speak") return BattleEditor_RuntimeEnemySpeak(controller,step);
    if(step.target_type=="board"&&step.property=="mask_color"){
        if(!instance_exists(battle_board)) return 0;
        var mask_board=instance_find(battle_board,0);
        var mask_color=BattleEditor_MaskColorValue(BattleEditor_RuntimeNumber(controller,step.value,0));
        // A palette choice is a discrete state switch. Interpolating a packed
        // colour through the hidden legacy duration both lies to the timeline
        // and produces unrelated intermediate colours.
        return BattleEditor_RuntimeSetRawInstanceProperty(mask_board,"color_bg",mask_color,0,step.tween,step.ease)?1:0;
    }
    if(step.property=="orbit") return BattleEditor_RuntimeStartOrbitControl(controller,step);
    if(step.property=="physics") return BattleEditor_RuntimeStartPhysicsControl(controller,step);
    if(step.property=="aim_motion") return BattleEditor_RuntimeStartAimMotion(controller,step);
    if(step.target_type=="bone"&&step.property=="length") return BattleEditor_RuntimeStartBoneLengthControl(controller,step,BattleEditor_RuntimeNumber(controller,step.value,0));
    var changed=0;
    var runtime_value=BattleEditor_RuntimeNumber(controller,step.value,0);
    changed+=BattleEditor_RuntimeControlSystemTargets(controller,step,runtime_value);
    for(var pattern_index=0;pattern_index<array_length(controller.script_patterns);pattern_index++){
        var pattern=controller.script_patterns[pattern_index];
        if(!is_struct(pattern)||!struct_exists(pattern,"anchor")||!is_struct(pattern.anchor)||!BattleEditor_RuntimeTargetMatches(pattern.anchor,step)) continue;
        if(BattleEditor_RuntimeApplyObjectControl(controller,pattern.anchor,step,runtime_value)) changed+=1;
    }
    for(var i=0;i<array_length(controller.runtime_instances);i++){
        var target=controller.runtime_instances[i];
        if(BattleEditor_RuntimeTargetMatches(target,step)){
            if(BattleEditor_RuntimeApplyObjectControl(controller,target,step,runtime_value)) changed+=1;
        }
    }
    if(instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&BattleEditor_RuntimeTargetMatches(battle_board.mainboard,step)){
        if(BattleEditor_RuntimeApplyObjectControl(controller,battle_board.mainboard,step,runtime_value)) changed+=1;
    }
    for(var i=0;i<array_length(controller.preview_frames);i++){
        var frame_target=controller.preview_frames[i];
        if(BattleEditor_RuntimeTargetMatches(frame_target,step)){
            if(BattleEditor_RuntimeApplyObjectControl(controller,frame_target,step,runtime_value)) changed+=1;
        }
    }
    return changed;
}

/// Toggle persistent frame-following on the concrete instances selected by a
/// Control-ID.  The same adapter is used for fireballs, sprites, platforms,
/// GBs, knives and solids; capability comes from having a world position, not
/// from a hard-coded Bone-only branch.
function BattleEditor_RuntimeControlFollow(controller,step,enabled) {
    var targets=BattleEditor_RuntimeCollectControlTargets(controller,step);
    var changed=0;
    for(var target_index=0;target_index<array_length(targets);target_index++){
        var target=targets[target_index];
        if(!instance_exists(target)) continue;
        for(var pattern_index=array_length(controller.script_patterns)-1;pattern_index>=0;pattern_index--){
            var old_pattern=controller.script_patterns[pattern_index];
            if(is_struct(old_pattern)&&old_pattern.kind=="control_follow_instance"&&old_pattern.target==target){
                array_delete(controller.script_patterns,pattern_index,1);
            }
        }
        // A Bone may already use the old native follow implementation. Turn
        // that path off before attaching the shared world-transform follower,
        // otherwise the same frame rotation would be applied twice.
        if(variable_instance_exists(target,"follow")) target.follow=false;
        if(variable_instance_exists(target,"follow_board")) target.follow_board=false;
        target.editor_follow_enabled=enabled;
        target.editor_follow_target_uid=step.follow_target_uid;
        if(enabled){
            var follow_frame=BattleEditor_RuntimeBoardByUid(controller,step.follow_target_uid);
            if(is_struct(follow_frame)){
                var follow_pattern=BattleEditor_RuntimeFollowAttach({kind:"control_follow_instance",age:0,duration:2147483647,target:target,target_type:step.target_type,keep_objects:true},follow_frame);
                array_push(controller.script_patterns,follow_pattern);
            }
        }
        changed+=1;
    }
    return changed;
}

function BattleEditor_RuntimeControlObject(controller,step) {
    if(struct_exists(step,"control_source_mode")&&round(real(step.control_source_mode))==1){
        var copy_batch=BattleEditor_RuntimeCloneControlBatch(controller,step);
        if(array_length(copy_batch.targets)<=0) return 0;
        var copy_step=copy_batch.step;
        var copy_is_move=copy_step.property=="position"||copy_step.property=="orbit"||copy_step.property=="physics"||copy_step.property=="aim_motion";
        if(copy_step.target_type=="gb"&&copy_is_move&&copy_step.gb_hold_while_moving) BattleEditor_RuntimeGBSetHold(controller,copy_step,false);
        if(copy_is_move&&copy_step.warning_enabled&&copy_step.warning_duration>0){
            for(var warning_index=0;warning_index<array_length(copy_batch.targets);warning_index++) BattleEditor_RuntimeSpawnControlWarning(controller,copy_batch.targets[warning_index],copy_step);
            var delayed_copy_step=json_parse(json_stringify(copy_step));
            delayed_copy_step.warning_enabled=false;
            BattleEditor_RuntimeRetagControlTargets(copy_batch.targets,copy_batch.output_id);
            array_push(controller.script_patterns,{kind:"deferred_control_warning",age:0,duration:max(1,copy_step.warning_duration),step:delayed_copy_step,retag_targets:copy_batch.targets,temporary_control_id:copy_batch.batch_id,final_control_id:copy_batch.output_id});
            return array_length(copy_batch.targets);
        }
        var copy_changed=BattleEditor_RuntimeControlObjectNow(controller,copy_step);
        BattleEditor_RuntimeRetagControlTargets(copy_batch.targets,copy_batch.output_id);
        return copy_changed;
    }
    var is_move=step.property=="position"||step.property=="orbit"||step.property=="physics"||step.property=="aim_motion";
    if(step.target_type=="gb"&&is_move&&step.gb_hold_while_moving) BattleEditor_RuntimeGBSetHold(controller,step,false);
    if(is_move&&step.warning_enabled&&step.warning_duration>0) return BattleEditor_RuntimeStartControlWarning(controller,step);
    return BattleEditor_RuntimeControlObjectNow(controller,step);
}

function BattleEditor_RuntimeControlVertices(controller,target,step) {
    if(!is_struct(target)||!variable_struct_exists(target,"listVertex")||!variable_struct_exists(target,"editor_vertex_uids")) return false;
    var started=false;
    for(var uid_index=0;uid_index<array_length(step.vertex_uids);uid_index++){
        var vertex_index=-1;
        for(var i=0;i<array_length(target.editor_vertex_uids);i++) if(target.editor_vertex_uids[i]==step.vertex_uids[uid_index]){vertex_index=i;break;}
        if(vertex_index<0||vertex_index>=array_length(target.listVertex)) continue;
        var start_x=target.listVertex[vertex_index][0];
        var start_y=target.listVertex[vertex_index][1];
        var target_x=step.coordinate_mode=="relative"?start_x+step.vertex_target_x:step.vertex_target_x;
        var target_y=step.coordinate_mode=="relative"?start_y+step.vertex_target_y:step.vertex_target_y;
        if(step.duration<=0){target.listVertex[vertex_index]=[target_x,target_y];target.updateDivide();}
        else array_push(controller.script_vertex_animations,{target:target,vertex_uid:step.vertex_uids[uid_index],start_x:start_x,start_y:start_y,target_x:target_x,target_y:target_y,elapsed:0,duration:max(1,step.duration),tween:step.tween,ease:step.ease});
        started=true;
    }
    return started;
}

function BattleEditor_RuntimeVertexStep(controller) {
    for(var anim_index=array_length(controller.script_vertex_animations)-1;anim_index>=0;anim_index--){
        var vertex_anim=controller.script_vertex_animations[anim_index];
        var target=vertex_anim.target;
        if(!is_struct(target)||target._destroyed){array_delete(controller.script_vertex_animations,anim_index,1);continue;}
        var vertex_index=-1;
        for(var i=0;i<array_length(target.editor_vertex_uids);i++) if(target.editor_vertex_uids[i]==vertex_anim.vertex_uid){vertex_index=i;break;}
        if(vertex_index<0||vertex_index>=array_length(target.listVertex)){array_delete(controller.script_vertex_animations,anim_index,1);continue;}
        vertex_anim.elapsed=min(vertex_anim.duration,vertex_anim.elapsed+global.delta_time_factor);
        var amount=Anim_GetValue(vertex_anim.tween,vertex_anim.ease,vertex_anim.elapsed/vertex_anim.duration);
        target.listVertex[vertex_index]=[lerp(vertex_anim.start_x,vertex_anim.target_x,amount),lerp(vertex_anim.start_y,vertex_anim.target_y,amount)];
        target.updateDivide();
        if(vertex_anim.elapsed>=vertex_anim.duration) array_delete(controller.script_vertex_animations,anim_index,1);
    }
}

function BattleEditor_ControlPropertyName(property_name,target_type="") {
    switch(property_name){
        case "position":return target_type=="board"?"变换":"移动位置";
        case "orbit":return "绕中心旋转";
        case "physics":return "通用物理移动";
        case "aim_motion":return "朝向 / 追踪目标";
        case "angle":return "角度";
        case "rotate":return "持续旋转速度";
        case "angle_x":return "X 轴角度";
        case "angle_y":return "Y 轴角度";
        case "angle_z":return "Z 轴角度";
        case "angle_xw":return "XW 平面角度";
        case "angle_yw":return "YW 平面角度";
        case "angle_zw":return "ZW 平面角度";
        case "rotate_x":return "X 轴转速";
        case "rotate_y":return "Y 轴转速";
        case "rotate_z":return "Z 轴转速";
        case "rotate_xw":return "XW 平面转速";
        case "rotate_yw":return "YW 平面转速";
        case "rotate_zw":return "ZW 平面转速";
        case "size_x":return "X 尺寸";
        case "size_y":return "Y 尺寸";
        case "size_z":return "Z 尺寸";
        case "size_w":return "W 尺寸";
        case "world_z":return "世界 Z";
        case "perspective_distance":return "3D 透视距离";
        case "perspective4d_distance":return "4D 透视距离";
        case "edge_trim":return "边缘留白";
        case "length":return "骨头长度";
        case "bone_style":return "骨头类型";
        case "platform_sticky":return "平台类型";
        case "platform_bounce":return "碰框反弹";
        case "hspeed":return "水平速度";
        case "vspeed":return "垂直速度";
        case "scale_x":return "横向缩放";
        case "scale_y":return "纵向缩放";
        case "move_time":return "入场时间";
        case "charge_time":return "发射前等待";
        case "beam_time":return "发射时间";
        case "gb_hold":return "GB 延长等待";
        case "gb_release":return "GB 立即发射";
        case "speak":return "敌人说话";
        case "aim_x":return "瞄准目标 X";
        case "aim_y":return "瞄准目标 Y";
        case "target_angle":return "目标角度";
        case "fake_mode":return "真假 GB 模式";
        case "offset_direction":return "GB 退出方向";
        case "offset_speed":return "GB 偏移初始速度";
        case "offset_acceleration":return "GB 每帧速度变化";
        case "offset_rotation_speed":return "GB 本体旋转速度";
        case "warning_time":return "警告时间";
        case "active_time":return "攻击时间";
        case "warning_width":return "警告宽度";
        case "visual_min_width":return "宽度";
        case "visual_max_width":return "刀波最宽宽";
        case "pre_direction":return "攻击前移动方向";
        case "pre_speed":return "攻击前初速";
        case "pre_acceleration":return "攻击前加速度";
        case "pre_curve_speed":return "攻击前弯曲角速";
        case "pre_rotation_mode":return "攻击前旋转模式";
        case "pre_rotation_speed":return "攻击前旋转速度";
        case "pre_rotation_target":return "攻击前目标角";
        case "pre_rotation_time":return "攻击前转角用时";
        case "post_direction":return "攻击后移动方向";
        case "post_speed":return "攻击后初速";
        case "post_acceleration":return "攻击后加速度";
        case "post_curve_speed":return "攻击后弯曲角速";
        case "post_rotation_mode":return "攻击后旋转模式";
        case "post_rotation_speed":return "攻击后旋转速度";
        case "post_rotation_target":return "攻击后目标角";
        case "post_rotation_time":return "攻击后转角用时";
        case "duration":return "存活时间";
        case "follow":return "启用跟随";
        case "follow_board":return "跟随战斗框";
        case "follow_angle":return "跟随角度";
        case "point":return "贴边模式";
        case "point_at":return "骨头朝向目标";
        case "aim_enabled":return "启用指向";
        case "aim_target_uid":return "指向对象";
        case "aim_continuous":return "持续指向";
        case "aim_move_enabled":return "向目标移动";
        case "aim_move_speed":return "追踪移动速度";
        case "green_guard_blockable":return "绿盾可格挡";
        case "green_guard_destroy_on_block":return "格挡后销毁";
        case "damage_type":return "伤害类型";
        case "damage":return "伤害数值";
        case "invincibility_frames":return "真刀无敌时间";
        case "heal_amount":return "回血数值";
        case "alpha":return "透明度";
        case "color":case "visual_color":return "视觉颜色";
        case "layer_mode":return "攻击层级";
        case "color_frame":return "框颜色数值";
        case "mask_color":return "框内遮罩颜色";
        case "shape":return "框形状";
        case "width":return "框宽度";
        case "height":return "框高度";
        case "radius_x":return "椭圆半径 X";
        case "radius_y":return "椭圆半径 Y";
        case "orbit_radius_x":return "轨迹半径 X";
        case "orbit_radius_y":return "轨迹半径 Y";
        case "pattern_span":return "排列范围";
        case "pattern_amplitude":return "摆动范围";
        case "pattern_speed":return "轨迹速度";
        case "wall_extent":return "墙体目标距离";
        case "triangle_size":return "三角形尺寸";
        case "cover":return "设为减框";
        case "up":return "框上半径";
        case "down":return "框下半径";
        case "left":return "框左半径";
        case "right":return "框右半径";
        case "control_vertex":return "控制顶点";
        case "text":return "更换打字文本";
        case "font_id":return "字体";
        case "player_name":return "玩家名字";
        case "player_lv":return "玩家 LV";
        case "player_hp":return "当前 HP";
        case "player_max_hp":return "当前 HP 上限";
        case "player_natural_max_hp":return "原始 HP 上限";
        case "player_atk":return "玩家 ATK";
        case "player_def":return "玩家 DEF";
        case "shield_value":return "当前护盾";
        case "shield_max":return "当前护盾上限";
        case "shield_natural_max":return "原始护盾上限";
        case "soul_mode":return "灵魂模式";
        case "blue_direction":return "蓝魂方向";
        case "show_hp_label":return "显示 HP 图标";
        case "show_bar":return "显示血条";
        case "show_kr":return "显示 KR";
        case "show_numbers":return "显示血量数字";
        case "show_shield":return "显示护盾";
        case "show_overhead":return "灵魂上方数字";
        case "shield_hud_mode":return "护盾位置模式";
    }
    return property_name;
}

function BattleEditor_IsBooleanControlProperty(property_name) {
    return property_name=="follow"||property_name=="follow_board"
        ||property_name=="aim_enabled"||property_name=="aim_continuous"||property_name=="aim_move_enabled"
        ||property_name=="green_guard_blockable"||property_name=="green_guard_destroy_on_block"
        ||property_name=="show_hp_label"||property_name=="show_bar"||property_name=="show_kr"
        ||property_name=="show_numbers"||property_name=="show_shield"||property_name=="show_overhead"||property_name=="cover"
        ||property_name=="platform_bounce";
}

function BattleEditor_IsChoiceControlProperty(property_name) {
    return property_name=="damage_type"||property_name=="layer_mode"||property_name=="fake_mode"
        ||property_name=="pre_rotation_mode"||property_name=="post_rotation_mode"||property_name=="shield_hud_mode"||property_name=="shape"
        ||property_name=="soul_mode"||property_name=="blue_direction"||property_name=="bone_style"||property_name=="platform_sticky"||property_name=="mask_color";
}

function BattleEditor_MaskColorName(value) {
    var names=["默认黑色","灵魂·红","灵魂·蓝","灵魂·绿","灵魂·紫","灵魂·黄","灵魂·橙","灵魂·青","攻击·白","攻击·蓝","攻击·橙","攻击·亮绿","攻击·黄","攻击·深绿","攻击·红","攻击·紫","攻击·深蓝"];
    return names[clamp(round(real(value)),0,array_length(names)-1)];
}

function BattleEditor_MaskColorValue(value) {
    switch(clamp(round(real(value)),0,16)){
        case 0:return c_black;
        case 1:return c_red;
        case 2:return c_blue;
        case 3:return make_color_rgb(0,255,0);
        case 4:return make_color_rgb(128,0,128);
        case 5:return c_yellow;
        case 6:return make_color_rgb(248,148,29);
        case 7:return c_aqua;
    }
    return BattleEditor_ColorForType(clamp(round(real(value))-8,0,8));
}

function BattleEditor_ControlChoiceCaption(property_name,value) {
    var selected=round(real(value));
    if(property_name=="mask_color") return BattleEditor_MaskColorName(selected);
    if(property_name=="layer_mode") return BattleEditor_LayerName(clamp(selected,0,2));
    if(property_name=="fake_mode") return ["真实 GB","假 GB 动画","假 GB 掉落"][clamp(selected,0,2)];
    if(property_name=="pre_rotation_mode"||property_name=="post_rotation_mode") return BattleEditor_WaveRotationModeName(clamp(selected,0,2));
    if(property_name=="shield_hud_mode") return selected==0?"护盾在血条下":"护盾在右侧";
    if(property_name=="shape") return ["矩形","椭圆","正三角形","多边形"][clamp(selected,0,3)];
    if(property_name=="soul_mode") return BattleEditor_SoulModeName(selected);
    if(property_name=="blue_direction") return BattleEditor_BlueDirectionName(selected);
    if(property_name=="bone_style") return BattleEditor_BoneStyleName(selected);
    if(property_name=="platform_sticky") return selected==0?"紫色（不带玩家）":"绿色（带着玩家）";
    if(property_name=="damage_type") return ["白色","蓝色","橙色","亮绿回血","黄色","深绿减上限","红色秒杀","紫色占用","深蓝·X防伤"][clamp(selected,0,8)];
    return string(selected);
}

function BattleEditor_CycleControlChoice(property_name,value,direction=1) {
    var count=BattleEditor_ControlChoiceCount(property_name);
    return ((round(real(value))+direction) mod count+count) mod count;
}

function BattleEditor_ControlChoiceCount(property_name) {
    if(property_name=="mask_color") return 17;
    if(property_name=="damage_type") return 9;
    if(property_name=="soul_mode") return 7;
    if(property_name=="blue_direction"||property_name=="shape") return 4;
    if(property_name=="shield_hud_mode"||property_name=="bone_style"||property_name=="platform_sticky") return 2;
    return 3;
}

function BattleEditor_EditorChoiceCount(choice_kind) {
    switch(choice_kind){
        case "layer":return 3;
        case "gb_fake":return 3;
        case "gb_offset_direction":return 2;
        case "tween":return 11;
        case "ease":return 3;
        case "wave_rotation":return 3;
        case "shield_mode":return 2;
        case "soul_mode":return 7;
        case "dialogue_template":return 5;
        case "dialogue_mode":return 2;
        case "enemy_part":return array_length(BattleEditor_EnemyPartKeys());
        case "voice":return 5;
        case "platform_type":return 2;
        case "bone_style":return 2;
        case "aim_behavior":return 3;
        case "bone_aim_behavior":return 3;
        case "aim_update":return 2;
        case "solid_shape":return 6;
        case "item_after_use":return 3;
        case "visual_color_mode":return 3;
        case "visual_color_preset":return 9;
    }
    return 0;
}

function BattleEditor_EditorChoiceCaption(choice_kind,value) {
    value=round(real(value));
    switch(choice_kind){
        case "layer":return BattleEditor_LayerName(clamp(value,0,2));
        case "gb_fake":return ["真实 GB","假 GB 动画","假 GB 掉落"][clamp(value,0,2)];
        case "gb_offset_direction":return value==0?"自动：沿 GB 后方":"自定义：绝对角度";
        case "tween":return BattleEditor_TweenName(clamp(value,0,10));
        case "ease":return BattleEditor_EaseName(clamp(value,0,2));
        case "wave_rotation":return BattleEditor_WaveRotationModeName(clamp(value,0,2));
        case "shield_mode":return value==BATTLE_SHIELD_HUD_MODE.SIDE?"护盾在右侧":"护盾在血条下";
        case "soul_mode":return BattleEditor_SoulModeName(value);
        case "dialogue_template":return BattleEditor_DialogueTemplateName(clamp(value,0,4));
        case "dialogue_mode":return value==0?"自动打字并继续":"Z / X 手动推进";
        case "voice":return BattleEditor_VoiceName(BattleEditor_VoiceChoiceToId(value));
        case "platform_type":return value==0?"紫色（不带玩家）":"绿色（带着玩家）";
        case "bone_style":return BattleEditor_BoneStyleName(value);
        case "aim_behavior":return BattleEditor_AimBehaviorName(value);
        case "bone_aim_behavior":return BattleEditor_BoneAimBehaviorName(value);
        case "aim_update":return value==0?"执行时锁定一次":"持续追踪目标";
        case "solid_shape":return BattleEditor_SolidBoneShapeName(value>=5?6:value);
        case "item_after_use":return BattleEditor_ItemAfterUseModeName(value);
        case "visual_color_mode":return BattleEditor_VisualColorModeName(value);
        case "visual_color_preset":return BattleEditor_VisualColorPresetName(value);
        case "enemy_part":
            var keys=BattleEditor_EnemyPartKeys();
            return BattleEditor_EnemyPartName(keys[clamp(value,0,array_length(keys)-1)]);
    }
    return string(value);
}

function BattleEditor_CycleControlProperty(property_name,direction=1) {
    var properties=["position","angle","rotate","length","alpha","scale_x","scale_y","layer_mode","color_frame","up","down","left","right","control_vertex"];
    var index=0;
    for(var i=0;i<array_length(properties);i++) if(properties[i]==property_name){index=i;break;}
    return properties[(index+direction+array_length(properties)) mod array_length(properties)];
}

function BattleEditor_FindFrameDataByUid(project,frame_uid) {
    if(project.initialization.board.uid==frame_uid) return project.initialization.board;
    for(var i=0;i<array_length(project.initialization.frames);i++) if(project.initialization.frames[i].uid==frame_uid) return project.initialization.frames[i];
    return undefined;
}

function BattleEditor_VertexIndexByUid(frame,vertex_uid) {
    if(!struct_exists(frame,"vertex_uids")) return -1;
    for(var i=0;i<array_length(frame.vertex_uids);i++) if(frame.vertex_uids[i]==vertex_uid) return i;
    return -1;
}

function BattleEditor_EffectsEnsure() {
    if(!variable_global_exists("battle_editor_effects")||!is_struct(global.battle_editor_effects)){
        global.battle_editor_effects={hue:0,saturation:1,brightness:0,contrast:1,grayscale:0,invert:0,glitch:0,chromatic:0,scanline:0,wave:0,vignette:0,pixel_size:1};
    }
    return global.battle_editor_effects;
}

function BattleEditor_EffectsReset() {
    var fx=BattleEditor_EffectsEnsure();
    fx.hue=0;fx.saturation=1;fx.brightness=0;fx.contrast=1;fx.grayscale=0;fx.invert=0;
    fx.glitch=0;fx.chromatic=0;fx.scanline=0;fx.wave=0;fx.vignette=0;fx.pixel_size=1;
    if(variable_global_exists("blur_amount")) global.blur_amount=0;
    if(variable_global_exists("blur_strength")) global.blur_strength=[0,0];
}

function BattleEditor_EffectsActive() {
    var fx=BattleEditor_EffectsEnsure();
    return abs(fx.hue)>0.001||abs(fx.saturation-1)>0.001||abs(fx.brightness)>0.001||abs(fx.contrast-1)>0.001
        ||fx.grayscale>0.001||fx.invert>0.001||fx.glitch>0.001||fx.chromatic>0.001||fx.scanline>0.001
        ||abs(fx.wave)>0.001||fx.vignette>0.001||fx.pixel_size>1.001;
}

/// Final application-surface blit used by border. All authorable post effects
/// are combined so color, glitch and vignette can be used together.
function BattleEditor_DrawFinalSurface(source,x,y,scale_x,scale_y,angle=0,color=c_white,alpha=1) {
    if(!surface_exists(source)) return false;
    if(!BattleEditor_EffectsActive()){
        draw_surface_ext(source,x,y,scale_x,scale_y,angle,color,alpha);
        return true;
    }
    var fx=BattleEditor_EffectsEnsure();
    shader_set(shd_battle_editor_effects);
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_effects,"u_texel"),1/max(1,surface_get_width(source)),1/max(1,surface_get_height(source)));
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_effects,"u_time"),current_time/1000);
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_effects,"u_color_adjust"),fx.hue,fx.saturation,fx.brightness,fx.contrast);
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_effects,"u_mix_adjust"),fx.grayscale,fx.invert,fx.vignette,fx.pixel_size);
    shader_set_uniform_f(shader_get_uniform(shd_battle_editor_effects,"u_glitch_adjust"),fx.glitch,fx.chromatic,fx.scanline,fx.wave);
    draw_surface_ext(source,x,y,scale_x,scale_y,angle,color,alpha);
    shader_reset();
    return true;
}

function BattleEditor_RuntimeCaptureScreen(controller) {
    if(!instance_exists(controller)||!instance_exists(camera)) return false;
    controller.screen_original={x:camera.x,y:camera.y,scale_x:camera.scale_x,scale_y:camera.scale_y,angle:camera.angle,target:camera.target};
    camera.editor_center_enabled=true;
    camera.editor_center_x=camera.x+camera.width/max(0.01,camera.scale_x)*0.5;
    camera.editor_center_y=camera.y+camera.height/max(0.01,camera.scale_y)*0.5;
    BattleEditor_EffectsReset();
    return true;
}

function BattleEditor_RuntimeRestoreScreen(controller) {
    BattleEditor_EffectsReset();
    if(!instance_exists(controller)||!instance_exists(camera)||!variable_instance_exists(controller,"screen_original")||is_undefined(controller.screen_original)) return false;
    var original=controller.screen_original;
    camera.editor_center_enabled=false;
    camera.x=original.x;camera.y=original.y;camera.scale_x=original.scale_x;camera.scale_y=original.scale_y;camera.angle=original.angle;camera.target=original.target;
    controller.screen_original=undefined;
    return true;
}

function BattleEditor_ActionParts(source) {
    if(string_length(string_trim(string(source)))<=0) return [];
    return string_split(string(source),";");
}

/// Fast path for ordinary numeric fields. Formula parsing is still used for
/// every non-literal value, but plain numbers do not need a complete symbol
/// table merely to become reals.
function BattleEditor_TryNumberLiteral(value) {
    if(is_real(value)) return {valid:true,value:value};
    var source=string_trim(string(value));
    var length=string_length(source);
    if(length<=0) return {valid:false,value:0};
    var digits=0,dots=0;
    for(var i=1;i<=length;i++){
        var ch=string_char_at(source,i);
        if(ch>="0"&&ch<="9"){digits+=1;continue;}
        if(ch=="."&&dots==0){dots+=1;continue;}
        if((ch=="+"||ch=="-")&&i==1) continue;
        return {valid:false,value:0};
    }
    if(digits<=0) return {valid:false,value:0};
    return {valid:true,value:real(source)};
}

function BattleEditor_ActionNumber(controller,parts,index,fallback=0) {
    if(index<0||index>=array_length(parts)) return fallback;
    var source=string_trim(parts[index]);
    var literal=BattleEditor_TryNumberLiteral(source);
    if(literal.valid) return literal.value;
    // One built-in action can expose dozens of formula fields. Building the
    // complete Workspace/object variable table separately for every field made
    // a single corridor invocation scan the whole project fourteen times.
    // The public wrapper below creates one snapshot for the action; parsing of
    // every individual formula remains independent and in authored order.
    if(!is_struct(controller)&&instance_exists(controller)
    &&variable_instance_exists(controller,"_runtime_action_expression_scope_active")
    &&controller._runtime_action_expression_scope_active){
        if(!variable_instance_exists(controller,"_runtime_action_expression_scope_ready")
        ||!controller._runtime_action_expression_scope_ready){
            controller._runtime_action_expression_variables=BattleEditor_ExpressionVariables(controller);
            controller._runtime_action_expression_scope_ready=true;
        }
        var parsed=BattleEditor_EvaluateNumberExpression(source,controller._runtime_action_expression_variables);
        return parsed.valid?parsed.value:fallback;
    }
    return BattleEditor_RuntimeNumber(controller,source,fallback);
}

/// Range precision is author-controlled. Integer endpoints produce integer
/// samples; otherwise the greatest number of typed decimal places is used.
/// This intentionally has no arbitrary editor-side precision cap.
function BattleEditor_NumberTextDecimalPlaces(source) {
    source=string(source);
    var best=0,current=-1;
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch=="."){current=0;continue;}
        if(current>=0&&ch>="0"&&ch<="9"){current+=1;best=max(best,current);}
        else if(current>=0) current=-1;
    }
    return best;
}

function BattleEditor_ActionRange(controller,parts,min_index,max_index,fallback_min=0,fallback_max=0) {
    var low=BattleEditor_ActionNumber(controller,parts,min_index,fallback_min);
    var high=BattleEditor_ActionNumber(controller,parts,max_index,fallback_max);
    if(low>high){var swap=low;low=high;high=swap;}
    var min_text=min_index>=0&&min_index<array_length(parts)?string_trim(parts[min_index]):string(fallback_min);
    var max_text=max_index>=0&&max_index<array_length(parts)?string_trim(parts[max_index]):string(fallback_max);
    var places=max(BattleEditor_NumberTextDecimalPlaces(min_text),BattleEditor_NumberTextDecimalPlaces(max_text));
    if(places<=0) return irandom_range(round(low),round(high));
    var scale=power(10,places);
    return irandom_range(round(low*scale),round(high*scale))/scale;
}

function BattleEditor_RuntimeTrack(controller,inst) {
    if(instance_exists(inst)){
        // Every runtime member already carries its owner. Re-scanning the
        // complete runtime array for every newly-created member made an N-item
        // constructor perform quadratic bookkeeping in its invocation frame.
        // The owner marker is the same identity guarantee in constant time.
        var already_tracked=variable_instance_exists(inst,"_battle_editor_runtime_controller")&&inst._battle_editor_runtime_controller==controller;
        if(!already_tracked) array_push(controller.runtime_instances,inst);
        inst._battle_editor_runtime_controller=controller;
        inst._battle_editor_runtime_frozen=false;
    }
    return inst;
}

/// Workspace creation is instantaneous. It builds the same event-data structs
/// as the scene editor and uses the existing spawn path; there is no canvas
/// placement state and no second projectile runtime.
function BattleEditor_ExecuteCreateObject(controller,step) {
    var create_x=BattleEditor_RuntimeNumber(controller,step.create_x,320);
    var create_y=BattleEditor_RuntimeNumber(controller,step.create_y,240);
    var create_angle=BattleEditor_RuntimeNumber(controller,step.create_angle,0);
    var create_lifetime=BattleEditor_RuntimeNumber(controller,step.create_lifetime,-1);
    create_lifetime=create_lifetime<0?-1:max(1,create_lifetime);
    var create_size=max(0.01,BattleEditor_RuntimeNumber(controller,step.create_size,1));
    var create_preset=string(step.create_preset);
    var create_id=string(step.create_control_id);
    if(string_length(create_id)<=0) create_id="created_"+string(step.uid);
    var runtime_uid=-(max(1,step.uid)*10000+array_length(controller.runtime_instances)+1);

    if(create_preset=="board_add"||create_preset=="board_subtract"){
        var create_board_rotate=BattleEditor_RuntimeNumber(controller,step.create_board_rotate,0);
        var create_board_depth=BattleEditor_RuntimeNumber(controller,step.create_board_depth,create_preset=="board_subtract"?-10:10);
        var frame=BattleEditor_NewFrame(create_x,create_y,create_preset=="board_subtract");
        frame.uid=runtime_uid;
        frame.control_id=create_id;
        frame.name=BattleEditor_WorkspaceCreatePresetName(create_preset);
        frame.angle=create_angle;
        frame.rotate=create_board_rotate;
        frame.board_depth=create_board_depth;
        var create_board_shape=clamp(round(real(step.create_board_shape)),0,3);
        if(create_board_shape==1){
            frame.shape="circle";
            frame.radius_x=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_radius_x,30));
            frame.radius_y=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_radius_y,30));
        }else if(create_board_shape==2){
            frame.shape="triangle";
            frame.triangle_size=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_triangle_size,40));
        }else if(create_board_shape==3){
            frame.shape="polygon";
            frame.vertices=[];
            for(var create_vertex_index=0;create_vertex_index<array_length(step.points);create_vertex_index++){
                var create_vertex=step.points[create_vertex_index];
                array_push(frame.vertices,[BattleEditor_RuntimeNumber(controller,create_vertex[0],0),BattleEditor_RuntimeNumber(controller,create_vertex[1],0)]);
            }
            if(array_length(frame.vertices)<3) frame.vertices=[[-40,-40],[40,-40],[40,40],[-40,40]];
            frame.vertex_uids=[];
        }else{
            frame.shape="rect";
            frame.up=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_up,30));
            frame.down=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_down,30));
            frame.left=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_left,30));
            frame.right=max(1,BattleEditor_RuntimeNumber(controller,step.create_board_right,30));
        }
        // Match frames created on the scene canvas: their initial colour is
        // the project-wide frame colour, not BattleEditor_NewFrame's white
        // structural fallback.
        frame.color_frame=controller.project.initialization.board_color_default;
        var frame_preview=BattleEditor_CreateFramePreview(frame,controller);
        array_push(controller.preview_frames,frame_preview);
        if(create_lifetime>=0) array_push(controller.script_patterns,{kind:"lifetime_members",age:0,duration:create_lifetime,keep_objects:false,members:[frame_preview]});
        return instance_exists(frame_preview);
    }

    // The Workspace edits the same complete event data as the scene editor.
    // Clone it once, resolve formula-capable numeric fields, then use the one
    // established spawn path; there is no reduced create-object runtime.
    var template=BattleEditor_WorkspaceCreateNormalizeTemplate(step);
    var data=json_parse(json_stringify(template));
    var create_follow=struct_exists(data,"follow")&&data.follow;
    var create_follow_target_uid=struct_exists(data,"follow_target_uid")?data.follow_target_uid:-1;
    var create_fields=BattleEditor_WorkspaceCreateFields(create_preset);
    for(var create_field_index=0;create_field_index<array_length(create_fields);create_field_index++){
        var create_field=create_fields[create_field_index];
        if(create_field.kind=="number"||create_field.kind=="lifetime"){
            var create_field_source=BattleEditor_WorkspaceTemplateGet(data,create_field.path);
            BattleEditor_WorkspaceTemplateSet(data,create_field.path,BattleEditor_RuntimeNumber(controller,create_field_source,0));
        }else if(create_field.kind=="color"){
            // Typewriter defaults may still use readable named colours such
            // as "white"; visual tint fields normally store a real colour.
            // A colour picker must not turn the former into numeric zero.
            var create_color_source=BattleEditor_WorkspaceTemplateGet(data,create_field.path);
            var create_color_value=is_real(create_color_source)?create_color_source:GetColorFromString(create_color_source);
            BattleEditor_WorkspaceTemplateSet(data,create_field.path,create_color_value);
        }else if(create_field.kind=="choice"&&create_field.choice!="clip_mode"){
            BattleEditor_WorkspaceTemplateSet(data,create_field.path,round(real(BattleEditor_WorkspaceTemplateGet(data,create_field.path))));
        }else if(create_field.kind=="bool"){
            BattleEditor_WorkspaceTemplateSet(data,create_field.path,real(BattleEditor_WorkspaceTemplateGet(data,create_field.path))!=0);
        }
    }
    data.uid=runtime_uid;
    data.control_id=create_id;
    data.name=BattleEditor_WorkspaceCreatePresetName(create_preset);
    data.time=controller.playhead;
    data.layer_mode=clamp(round(real(data.layer_mode)),0,2);
    if(struct_exists(data,"layer_user_set")) data.layer_user_set=true;
    // Workspace creation uses the shared follower below. Prevent the legacy
    // Bone constructor from also applying its private follow transform.
    if(create_follow&&create_preset=="bone") data.follow=false;
    var created=BattleEditor_RuntimeTrack(controller,BattleEditor_SpawnEvent(data,controller.project.initialization,controller));
    if(instance_exists(created)&&create_follow){
        var create_follow_frame=BattleEditor_RuntimeBoardByUid(controller,create_follow_target_uid);
        if(is_struct(create_follow_frame)){
            created.editor_follow_enabled=true;
            created.editor_follow_target_uid=create_follow_target_uid;
            array_push(controller.script_patterns,BattleEditor_RuntimeFollowAttach({kind:"control_follow_instance",age:0,duration:2147483647,target:created,target_type:BattleEditor_DataTargetType(data),keep_objects:true},create_follow_frame));
        }
    }
    return instance_exists(created);
}

function BattleEditor_RuntimeBone(controller,x,y,length,hspeed,vspeed,color,angle,rotate,duration,layer_mode=1) {
    var actual_duration=duration<0?-1:max(1,duration);
    var damage_type=clamp(round(color),0,8);
    var bone=BattleEditor_RuntimeTrack(controller,Battle_MakeBone(x,y,max(1,length),hspeed,vspeed,damage_type,clamp(round(layer_mode),0,2),angle,rotate,false,actual_duration));
    // Built-in default Bones are editor-authored attacks too. Without this
    // flag they fell back to legacy Player_HurtKr(), so purple constructors
    // never created their occupancy segment and other colour rules diverged.
    bone.editor_damage_enabled=true;
    bone.hp_damage=max(0,BattleEditor_DefaultDamageForType(damage_type));
    bone.kr_damage=bone.hp_damage;
    var bone_damage_profile=Player_AllScriptDamageProfile(damage_type);
    bone.heal_amount=bone_damage_profile.heal;
    return bone;
}

function BattleEditor_FindEventDataByUid(project,event_uid) {
    for(var i=0;i<array_length(project.events);i++) if(project.events[i].uid==event_uid) return project.events[i];
    return undefined;
}

function BattleEditor_RuntimePatternSource(controller,step) {
    var source_uid=struct_exists(step,"action_source_uid")?step.action_source_uid:-1;
    return source_uid>=0?BattleEditor_FindEventDataByUid(controller.project,source_uid):undefined;
}

function BattleEditor_RuntimePatternSetPose(target,target_type,x,y,angle=undefined) {
    if(!instance_exists(target)) return false;
    target.x=x;target.y=y;
    if(!is_undefined(angle)){
        var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
        if(variable_instance_exists(target,angle_property)) variable_instance_set(target,angle_property,angle);
    }
    return true;
}

/// Adds the built-in action's independent "follow main frame" contract to a
/// runtime pattern. The authored coordinates remain world coordinates; the
/// current board transform is applied around the board pose captured at start.
function BattleEditor_RuntimeFollowAttach(pattern,follow_frame) {
    pattern.follow_enabled=is_struct(follow_frame)&&!follow_frame._destroyed;
    if(!pattern.follow_enabled) return pattern;
    pattern.follow_board=follow_frame;
    pattern.follow_origin_x=follow_frame.x;
    pattern.follow_origin_y=follow_frame.y;
    pattern.follow_origin_angle=follow_frame.angle;
    pattern.follow_last_x=follow_frame.x;
    pattern.follow_last_y=follow_frame.y;
    pattern.follow_last_angle=follow_frame.angle;
    return pattern;
}

function BattleEditor_RuntimeBuiltinFollowAttach(pattern,step) {
    var can_follow=struct_exists(step,"action_follow")&&step.action_follow&&BattleEditor_BuiltinActionCanFollow(step.action_name);
    var follow_frame=can_follow&&instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed?battle_board.mainboard:undefined;
    return BattleEditor_RuntimeFollowAttach(pattern,follow_frame);
}

function BattleEditor_RuntimeBuiltinFollowBoard(pattern) {
    if(!struct_exists(pattern,"follow_enabled")||!pattern.follow_enabled) return undefined;
    if(struct_exists(pattern,"follow_board")&&is_struct(pattern.follow_board)&&!pattern.follow_board._destroyed) return pattern.follow_board;
    if(instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed){
        pattern.follow_board=battle_board.mainboard;
        return pattern.follow_board;
    }
    return undefined;
}

function BattleEditor_RuntimeBuiltinFollowPose(pattern,x,y,angle=undefined) {
    var follow_frame=BattleEditor_RuntimeBuiltinFollowBoard(pattern);
    if(is_undefined(follow_frame)) return [x,y,angle];
    var delta_angle=follow_frame.angle-pattern.follow_origin_angle;
    var rotated=RotateAround(pattern.follow_origin_x,pattern.follow_origin_y,x,y,pattern.follow_origin_x,pattern.follow_origin_y,delta_angle);
    return [rotated[0]+follow_frame.x-pattern.follow_origin_x,rotated[1]+follow_frame.y-pattern.follow_origin_y,is_undefined(angle)?angle:angle+delta_angle];
}

/// Converts an authored local-frame motion vector into the board's current
/// world orientation. This is needed for members born after the frame started
/// rotating: they did not exist when the incremental follow delta rotated the
/// older members' velocity.
function BattleEditor_RuntimeBuiltinFollowVector(pattern,vx,vy) {
    var follow_frame=BattleEditor_RuntimeBuiltinFollowBoard(pattern);
    if(is_undefined(follow_frame)) return [vx,vy];
    return RotateAround(0,0,vx,vy,0,0,follow_frame.angle-pattern.follow_origin_angle);
}

function BattleEditor_RuntimePatternSetFollowPose(pattern,target,target_type,x,y,angle=undefined) {
    var followed=BattleEditor_RuntimeBuiltinFollowPose(pattern,x,y,angle);
    return BattleEditor_RuntimePatternSetPose(target,target_type,followed[0],followed[1],followed[2]);
}

/// Incremental rigid transform for built-ins whose members run their own
/// movement rather than receiving an absolute pose from PatternStep.
function BattleEditor_RuntimeBuiltinFollowDelta(pattern) {
    var follow_frame=BattleEditor_RuntimeBuiltinFollowBoard(pattern);
    if(is_undefined(follow_frame)) return {active:false,old_x:0,old_y:0,new_x:0,new_y:0,angle:0};
    var result={active:true,old_x:pattern.follow_last_x,old_y:pattern.follow_last_y,new_x:follow_frame.x,new_y:follow_frame.y,angle:follow_frame.angle-pattern.follow_last_angle};
    pattern.follow_last_x=follow_frame.x;
    pattern.follow_last_y=follow_frame.y;
    pattern.follow_last_angle=follow_frame.angle;
    return result;
}

function BattleEditor_RuntimeApplyBuiltinFollowDelta(target,target_type,delta,rotate_motion=true) {
    if(!delta.active||!instance_exists(target)) return false;
    // Every member derives its own world offset from the frame centre. Control
    // ID only groups authoring/selection; it is never used as a shared pivot.
    var moved=RotateAround(delta.old_x,delta.old_y,target.x,target.y,delta.old_x,delta.old_y,delta.angle);
    target.x=moved[0]+delta.new_x-delta.old_x;
    target.y=moved[1]+delta.new_y-delta.old_y;
    var angle_property=BattleEditor_RuntimeOrbitAngleProperty(target,target_type);
    if(variable_instance_exists(target,angle_property)) variable_instance_set(target,angle_property,variable_instance_get(target,angle_property)+delta.angle);
    // GB keeps both a visible position and private/target coordinates.
    if(variable_instance_exists(target,"_x")&&variable_instance_exists(target,"_y")){
        var private_moved=RotateAround(delta.old_x,delta.old_y,target._x,target._y,delta.old_x,delta.old_y,delta.angle);
        target._x=private_moved[0]+delta.new_x-delta.old_x;
        target._y=private_moved[1]+delta.new_y-delta.old_y;
    }
    if(variable_instance_exists(target,"x_target")&&variable_instance_exists(target,"y_target")){
        var target_moved=RotateAround(delta.old_x,delta.old_y,target.x_target,target.y_target,delta.old_x,delta.old_y,delta.angle);
        target.x_target=target_moved[0]+delta.new_x-delta.old_x;
        target.y_target=target_moved[1]+delta.new_y-delta.old_y;
    }
    if(rotate_motion){
        // Following the frame is a world-coordinate transform, not merely a
        // positional orbit. Rotate every motion representation the target
        // actually exposes so a left-moving member travels downward after a
        // +90 degree frame turn. Do not add direction after rotating h/v speed:
        // GameMaker couples those built-ins, so doing both rotates it twice.
        if(variable_instance_exists(target,"hspeed")&&variable_instance_exists(target,"vspeed")){
            var motion=RotateAround(0,0,target.hspeed,target.vspeed,0,0,delta.angle);
            target.hspeed=motion[0];target.vspeed=motion[1];
        }else if(variable_instance_exists(target,"direction")) target.direction+=delta.angle;
        // battle_bullet keeps private motion while its own follow mode is on.
        if(variable_instance_exists(target,"_hspeed")&&variable_instance_exists(target,"_vspeed")){
            var private_motion=RotateAround(0,0,target._hspeed,target._vspeed,0,0,delta.angle);
            target._hspeed=private_motion[0];target._vspeed=private_motion[1];
        }
        if(variable_instance_exists(target,"_direction")) target._direction+=delta.angle;
        // Scripted attack motion uses direction/speed fields instead of native
        // hspeed/vspeed. Rotate the latent directions too, including while the
        // corresponding speed is zero, so later acceleration stays local.
        if(variable_instance_exists(target,"pre_direction")) target.pre_direction+=delta.angle;
        if(variable_instance_exists(target,"post_direction")) target.post_direction+=delta.angle;
        if(variable_instance_exists(target,"offset_direction")) target.offset_direction+=delta.angle;
        if(variable_instance_exists(target,"offset_path")&&is_array(target.offset_path)){
            for(var follow_segment_index=0;follow_segment_index<array_length(target.offset_path);follow_segment_index++){
                var follow_segment=target.offset_path[follow_segment_index];
                if(is_struct(follow_segment)&&struct_exists(follow_segment,"direction")) follow_segment.direction+=delta.angle;
            }
        }
        // Pending orientation tweens are world-space targets as well. Rotating
        // only the current sprite would let the next tween step pull it back to
        // its pre-transform heading.
        var follow_angle_fields=["angle_start","angle_target","pre_angle_from","pre_rotation_target","post_angle_from","post_rotation_target"];
        for(var follow_angle_index=0;follow_angle_index<array_length(follow_angle_fields);follow_angle_index++){
            var follow_angle_field=follow_angle_fields[follow_angle_index];
            if(variable_instance_exists(target,follow_angle_field)) variable_instance_set(target,follow_angle_field,variable_instance_get(target,follow_angle_field)+delta.angle);
        }
        if(variable_instance_exists(target,"_fake_drop_vx")&&variable_instance_exists(target,"_fake_drop_vy")){
            var fake_motion=RotateAround(0,0,target._fake_drop_vx,target._fake_drop_vy,0,0,delta.angle);
            target._fake_drop_vx=fake_motion[0];target._fake_drop_vy=fake_motion[1];
        }
    }
    return true;
}

function BattleEditor_RuntimePatternMemberResolved(controller,step,source,x,y,angle,bone_length,color,duration,layer_mode,index,keep_objects=false) {
    var member;
    var target_type="bone";
    var change_visual=struct_exists(step,"action_damage_change_visual")?step.action_damage_change_visual:true;
    if(!is_undefined(source)&&BattleEditor_DataTargetType(source)!="gb"){
        // A generated arrangement owns the lifetime of its copies. Clone only
        // the authored data, then extend whichever public lifetime capability
        // that object already exposes; the original timeline object is never
        // modified and no second object runtime is introduced.
        var generated_source=json_parse(json_stringify(source));
        var generated_lifetime=keep_objects?-1:max(1,duration+2);
        if(struct_exists(generated_source,"duration")) generated_source.duration=generated_lifetime;
        if(struct_exists(generated_source,"active_time")){
            var generated_warning=struct_exists(generated_source,"warning_time")?max(0,real(generated_source.warning_time)):0;
            generated_source.active_time=keep_objects?2147483647:max(real(generated_source.active_time),generated_lifetime-generated_warning);
        }
        if(struct_exists(generated_source,"damage_profile")){
            generated_source.damage_profile.type=clamp(round(real(color)),0,8);
            generated_source.damage_profile.change_visual=change_visual;
            if(change_visual&&struct_exists(generated_source,"visual_tint")) BattleEditor_SetVisualTintMode(generated_source,0);
        }
        member=BattleEditor_RuntimeTrack(controller,BattleEditor_SpawnEvent(generated_source,controller.project.initialization,controller));
        target_type=BattleEditor_DataTargetType(source);
        if(target_type=="bone"&&variable_instance_exists(member,"follow")){member.follow=false;member.follow_board=false;}
        // The constructor's layer is authoritative even when its template is a
        // copied scene object. Otherwise duration would be measured against the
        // requested clipping mode while the copy still rendered on its old one.
        if(instance_exists(member)&&variable_instance_exists(member,"out")) Battle_SetAttackLayer(member,layer_mode);
        BattleEditor_RuntimePatternSetPose(member,target_type,x,y,angle);
    }else{
        member=BattleEditor_RuntimeBone(controller,x,y,bone_length,0,0,color,angle,0,keep_objects?-1:duration+2,layer_mode);
        if(!change_visual&&instance_exists(member)&&variable_instance_exists(member,"editor_visual_override")){
            member.editor_visual_override=true;
            member.editor_visual_color=c_white;
        }
    }
    BattleEditor_RuntimeAssignActionIdentity(member,step,target_type,index);
    if(keep_objects&&instance_exists(member)) member._battle_editor_runtime_hold_until_destroy=false;
    return member;
}

function BattleEditor_RuntimePatternMember(controller,step,x,y,angle,bone_length,color,duration,layer_mode,index,keep_objects=false) {
    return BattleEditor_RuntimePatternMemberResolved(controller,step,BattleEditor_RuntimePatternSource(controller,step),x,y,angle,bone_length,color,duration,layer_mode,index,keep_objects);
}

function BattleEditor_RuntimeFunctionPathOffset(controller,pattern,sample_t,progress,variables=undefined) {
    if(is_undefined(variables)) variables=BattleEditor_ExpressionVariables(controller);
    var parameter_name=BattleEditor_FunctionPathVariableName(pattern);
    var parameter_existed=variable_struct_exists(variables,parameter_name);
    var parameter_previous=parameter_existed?variable_struct_get(variables,parameter_name):0;
    var progress_existed=variable_struct_exists(variables,"progress");
    var progress_previous=progress_existed?variable_struct_get(variables,"progress"):0;
    variable_struct_set(variables,parameter_name,sample_t);
    variable_struct_set(variables,"progress",progress);
    var x_result=BattleEditor_EvaluateNumberExpression(pattern.formula_x,variables);
    var y_result=BattleEditor_EvaluateNumberExpression(pattern.formula_y,variables);
    // Restore, do not reset: a local A may deliberately shadow an existing A,
    // and the outer script must see its exact previous value afterwards.
    if(parameter_existed) variable_struct_set(variables,parameter_name,parameter_previous);
    else variable_struct_remove(variables,parameter_name);
    if(progress_existed) variable_struct_set(variables,"progress",progress_previous);
    else variable_struct_remove(variables,"progress");
    return [x_result.valid?x_result.value:0,y_result.valid?y_result.value:0,x_result.valid&&y_result.valid];
}

function BattleEditor_RuntimeFunctionPathPoint(controller,pattern,sample_t,progress,variables=undefined) {
    var offset=BattleEditor_RuntimeFunctionPathOffset(controller,pattern,sample_t,progress,variables);
    var origin_x=struct_exists(pattern,"formula_origin_x")?pattern.formula_origin_x:0;
    var origin_y=struct_exists(pattern,"formula_origin_y")?pattern.formula_origin_y:0;
    return [pattern.base_x+offset[0]-origin_x,pattern.base_y+offset[1]-origin_y,offset[2]];
}

function BattleEditor_FunctionPathResolveBase(project_or_controller,expression,current_x,current_y,fallback) {
    var variables=BattleEditor_ExpressionVariables(project_or_controller);
    variable_struct_set(variables,"X",current_x);
    variable_struct_set(variables,"Y",current_y);
    var result=BattleEditor_EvaluateNumberExpression(expression,variables);
    return result.valid?result.value:fallback;
}

function BattleEditor_FunctionPathDefinition(project_or_controller,step) {
    var p=BattleEditor_ActionParts(step.action_arguments);
    var base_x_expression=BattleEditor_ActionArgumentText(step.action_arguments,0,BattleEditor_BuiltinActionDefaults("bone_function_path"));
    var base_y_expression=BattleEditor_ActionArgumentText(step.action_arguments,1,BattleEditor_BuiltinActionDefaults("bone_function_path"));
    var definition={
        duration:max(1,BattleEditor_ActionNumber(project_or_controller,p,6,180)),
        base_x_expression:base_x_expression,
        base_y_expression:base_y_expression,
        base_x:BattleEditor_FunctionPathResolveBase(project_or_controller,base_x_expression,320,240,140),
        base_y:BattleEditor_FunctionPathResolveBase(project_or_controller,base_y_expression,320,240,240),
        formula_x:BattleEditor_ActionArgumentText(step.action_arguments,2,BattleEditor_BuiltinActionDefaults("bone_function_path")),
        formula_y:BattleEditor_ActionArgumentText(step.action_arguments,3,BattleEditor_BuiltinActionDefaults("bone_function_path")),
        t0:BattleEditor_ActionNumber(project_or_controller,p,4,0),
        t1:BattleEditor_ActionNumber(project_or_controller,p,5,360),
        fixed_angle:BattleEditor_ActionNumber(project_or_controller,p,8,0),
        follow_tangent:round(BattleEditor_ActionNumber(project_or_controller,p,9,1))!=0,
        parameter_name:BattleEditor_FunctionPathVariableName(step),
        formula_origin_x:0,
        formula_origin_y:0
    };
    // “起始点” is exact. Formula values are displacement from their t0
    // sample, so X/Y can mean the current group centre even when the author's
    // curve does not happen to evaluate to zero at its first sample.
    var origin=BattleEditor_RuntimeFunctionPathOffset(project_or_controller,definition,definition.t0,0);
    definition.formula_origin_x=origin[0];
    definition.formula_origin_y=origin[1];
    return definition;
}

/// Editor preview deliberately uses the runtime definition and evaluator. It
/// is cached by the editor controller, so this function runs only after an
/// authoring change instead of parsing two formulas every Draw frame.
function BattleEditor_FunctionPathPreviewData(project,step,sample_count=96) {
    var definition=BattleEditor_FunctionPathDefinition(project,step);
    var variables=BattleEditor_ExpressionVariables(project);
    var points=[];
    var valid=true;
    sample_count=max(8,round(sample_count));
    for(var sample_index=0;sample_index<=sample_count;sample_index++){
        var sample_progress=sample_index/sample_count;
        var sample_parameter=lerp(definition.t0,definition.t1,sample_progress);
        var point=BattleEditor_RuntimeFunctionPathPoint(project,definition,sample_parameter,sample_progress,variables);
        valid=valid&&point[2];
        array_push(points,[point[0],point[1]]);
    }
    return {valid:valid,points:points,parameter_name:definition.parameter_name};
}

function BattleEditor_RuntimeAssignActionIdentity(inst,step,target_type,index=0) {
    if(!instance_exists(inst)) return inst;
    var group_id=struct_exists(step,"action_control_id")?string(step.action_control_id):("builtin_"+string(step.uid));
    inst.editor_uid=step.uid*1000+index;
    inst.editor_name=BattleEditor_BuiltinActionName(step.action_name)+"_"+string(index+1);
    inst.control_id=group_id;
    inst.editor_target_type=target_type;
    // A constructor's list item may finish immediately, but the things it
    // created still own a real finite lifetime. Runtime completion must wait
    // for those instances instead of tearing the whole group down next frame.
    inst._battle_editor_runtime_hold_until_destroy=true;
    return inst;
}

function BattleEditor_RuntimeApplyGeneratedPhysicsEntry(entry,delta) {
    var target=entry.target;
    if(!instance_exists(target)) return false;
    // Match the source object's deterministic physics loop: move and rotate by
    // current momentum, then apply fixed gravity and damping toward zero.
    target.x+=entry.vx*delta;
    target.y+=entry.vy*delta;
    if(variable_instance_exists(target,entry.angle_property)) variable_instance_set(target,entry.angle_property,variable_instance_get(target,entry.angle_property)+entry.angular_velocity*delta);
    entry.vy+=0.3*delta;
    var x_drag=0.01*delta;
    entry.vx=abs(entry.vx)<=x_drag?0:entry.vx-sign(entry.vx)*x_drag;
    var angular_drag=0.05*delta;
    entry.angular_velocity=abs(entry.angular_velocity)<=angular_drag?0:entry.angular_velocity-sign(entry.angular_velocity)*angular_drag;
    return true;
}

function BattleEditor_CorridorStaticClipBounds(controller,axis,layer_mode) {
    var axis_horizontal=round(axis)==0;
    var result=[0,axis_horizontal?640:480];
    if(round(layer_mode)!=BATTLE_EDITOR_LAYER.IN_BOARD) return result;
    // Duration is queried both with the live controller and directly with a
    // project while building the timeline cache. The old instance-only gate
    // silently used the whole 640x480 screen in the latter path, so the value
    // shown beside the timeline disagreed with "wait for previous completion".
    var corridor_project=undefined;
    if(instance_exists(controller)&&variable_instance_exists(controller,"project")) corridor_project=controller.project;
    else if(is_struct(controller)&&struct_exists(controller,"initialization")) corridor_project=controller;
    if(is_undefined(corridor_project)||!is_struct(corridor_project.initialization)) return result;
    var init=corridor_project.initialization;
    var frames=[];
    if(struct_exists(init,"board")&&is_struct(init.board)) array_push(frames,init.board);
    if(struct_exists(init,"frames")&&is_array(init.frames)) for(var frame_index=0;frame_index<array_length(init.frames);frame_index++) array_push(frames,init.frames[frame_index]);
    var found=false,minimum=1000000,maximum=-1000000;
    for(var board_index=0;board_index<array_length(frames);board_index++){
        var board=frames[board_index];
        if(!is_struct(board)||(struct_exists(board,"cover")&&board.cover)) continue;
        var contour=BattleEditor_RuntimeBoardSourceContour(board);
        var board_x=struct_exists(board,"x")?real(board.x):320;
        var board_y=struct_exists(board,"y")?real(board.y):320;
        var board_angle=struct_exists(board,"angle")?real(board.angle):0;
        for(var point_index=0;point_index<array_length(contour);point_index++){
            var contour_point=contour[point_index];
            var world_point=RotateAround(board_x,board_y,board_x+contour_point[0],board_y+contour_point[1],board_x,board_y,board_angle);
            var coordinate=axis_horizontal?world_point[0]:world_point[1];
            minimum=min(minimum,coordinate);maximum=max(maximum,coordinate);found=true;
        }
    }
    if(found) return [minimum,maximum];
    return result;
}

/// Static timeline estimate for a lifetime -1 corridor. There is no arbitrary
/// safety margin: a default corridor Bone is ten pixels thick along its travel
/// axis, so five pixels is the exact longitudinal half-extent. Runtime performs
/// the final check against the actual copied sprites and current frame shapes.
function BattleEditor_CorridorAutomaticDuration(controller,axis,start_x,start_y,item_count,spacing,corridor_velocity,layer_mode=0,longitudinal_half_extent=5) {
    item_count=max(1,round(item_count));
    var first_coordinate=round(axis)==0?start_x:start_y;
    var last_coordinate=first_coordinate+(item_count-1)*spacing;
    var minimum_coordinate=min(first_coordinate,last_coordinate);
    var maximum_coordinate=max(first_coordinate,last_coordinate);
    var travel_velocity=real(corridor_velocity);
    if(abs(travel_velocity)<=0.0001) return 0;
    var clip_bounds=BattleEditor_CorridorStaticClipBounds(controller,axis,layer_mode);
    var half_extent=max(0,real(longitudinal_half_extent));
    var distance=travel_velocity>0?(clip_bounds[1]+half_extent-minimum_coordinate):(maximum_coordinate+half_extent-clip_bounds[0]);
    return max(1,ceil(max(0,distance)/abs(travel_velocity)));
}

function BattleEditor_CorridorSegmentsIntersect(ax,ay,bx,by,cx,cy,dx,dy) {
    var abx=bx-ax,aby=by-ay,cdx=dx-cx,cdy=dy-cy;
    var denominator=abx*cdy-aby*cdx;
    if(abs(denominator)<=0.000001){
        var cross=(cx-ax)*aby-(cy-ay)*abx;
        if(abs(cross)>0.000001) return false;
        return max(min(ax,bx),min(cx,dx))<=min(max(ax,bx),max(cx,dx))+0.000001
            &&max(min(ay,by),min(cy,dy))<=min(max(ay,by),max(cy,dy))+0.000001;
    }
    var t=((cx-ax)*cdy-(cy-ay)*cdx)/denominator;
    var u=((cx-ax)*aby-(cy-ay)*abx)/denominator;
    return t>=0&&t<=1&&u>=0&&u<=1;
}

function BattleEditor_CorridorBoardIntersectsRect(board,left,top,right,bottom) {
    if(!is_struct(board)||board._destroyed) return false;
    if(board.contains(left,top)||board.contains(right,top)||board.contains(right,bottom)||board.contains(left,bottom)) return true;
    var contour=BattleEditor_RuntimeBoardSourceContour(board);
    var world_points=[];
    for(var point_index=0;point_index<array_length(contour);point_index++){
        var contour_point=contour[point_index];
        var world_point=RotateAround(board.x,board.y,board.x+contour_point[0],board.y+contour_point[1],board.x,board.y,board.angle);
        array_push(world_points,world_point);
        if(world_point[0]>=left&&world_point[0]<=right&&world_point[1]>=top&&world_point[1]<=bottom) return true;
    }
    for(var edge_index=0;edge_index<array_length(world_points);edge_index++){
        var edge_a=world_points[edge_index],edge_b=world_points[(edge_index+1) mod array_length(world_points)];
        if(BattleEditor_CorridorSegmentsIntersect(edge_a[0],edge_a[1],edge_b[0],edge_b[1],left,top,right,top)
        ||BattleEditor_CorridorSegmentsIntersect(edge_a[0],edge_a[1],edge_b[0],edge_b[1],right,top,right,bottom)
        ||BattleEditor_CorridorSegmentsIntersect(edge_a[0],edge_a[1],edge_b[0],edge_b[1],right,bottom,left,bottom)
        ||BattleEditor_CorridorSegmentsIntersect(edge_a[0],edge_a[1],edge_b[0],edge_b[1],left,bottom,left,top)) return true;
    }
    return false;
}

function BattleEditor_RuntimeCorridorClipBoards(target) {
    if(instance_exists(target)&&variable_instance_exists(target,"editor_clip_mode")&&target.editor_clip_mode=="selected") return BattleEditor_RuntimeClipBoards(target);
    var result=[];
    if(!variable_global_exists("boards_array")) return result;
    for(var board_index=0;board_index<array_length(global.boards_array);board_index++){
        var board=global.boards_array[board_index];
        if(is_struct(board)&&!board._destroyed) array_push(result,board);
    }
    return result;
}

/// Visibility is judged using the generated member's actual rotated collision
/// bounds. OUTSIDE/BELOW members remain alive until their entire bounds leave
/// 640x480; IN_BOARD members remain alive only while an additive clipping frame
/// can still draw any part of those bounds.
function BattleEditor_RuntimeCorridorMemberVisible(target,layer_mode) {
    if(!instance_exists(target)||!target.visible||target.image_alpha<=0) return false;
    var left=target.bbox_left,top=target.bbox_top,right=target.bbox_right,bottom=target.bbox_bottom;
    if(round(layer_mode)!=BATTLE_EDITOR_LAYER.IN_BOARD) return right>0&&left<640&&bottom>0&&top<480;
    var boards=BattleEditor_RuntimeCorridorClipBoards(target);
    for(var board_index=0;board_index<array_length(boards);board_index++){
        var board=boards[board_index];
        if(!board.cover&&BattleEditor_CorridorBoardIntersectsRect(board,left,top,right,bottom)) return true;
    }
    return false;
}

/// Retire a corridor member only after it has crossed the real viewport in its
/// current movement direction. Lifetime -1 previously kept every old pair
/// alive until the whole turn stopped, even after it could no longer be drawn.
function BattleEditor_RuntimeCorridorMemberPastViewport(target) {
    if(!instance_exists(target)) return true;
    var vx=variable_instance_exists(target,"hspeed")?target.hspeed:0;
    var vy=variable_instance_exists(target,"vspeed")?target.vspeed:0;
    return (vx<0&&target.bbox_right<=0)||(vx>0&&target.bbox_left>=640)
        ||(vy<0&&target.bbox_bottom<=0)||(vy>0&&target.bbox_top>=480);
}

/// Create one member of a corridor pair at its exact point in the generator
/// clock. A corridor repeats one pair at a time; it is not a prebuilt array.
function BattleEditor_RuntimeSpawnCorridorMember(controller,pattern,descriptor) {
    var elapsed=max(0,pattern.age-descriptor.spawn_time);
    var spawn_x=descriptor.x+(pattern.axis==0?pattern.move_speed*elapsed:0);
    var spawn_y=descriptor.y+(pattern.axis==0?0:pattern.move_speed*elapsed);
    spawn_x+=pattern.anchor.x-pattern.anchor_origin_x;
    spawn_y+=pattern.anchor.y-pattern.anchor_origin_y;
    var followed=BattleEditor_RuntimeBuiltinFollowPose(pattern,spawn_x,spawn_y,descriptor.angle);
    var remaining=pattern.keep_objects?-1:max(1,pattern.member_duration-elapsed);
    var member=BattleEditor_RuntimePatternMemberResolved(controller,pattern.step,pattern.source,followed[0],followed[1],followed[2],descriptor.length,pattern.color,remaining,pattern.layer_mode,descriptor.index,pattern.keep_objects);
    if(!instance_exists(member)) return noone;
    // A corridor is generated over time. Existing members receive each frame's
    // incremental rigid transform, while a newly born member must immediately
    // inherit the cumulative frame rotation. Otherwise its sprite/position is
    // followed but it still travels along the original horizontal/vertical
    // world axis.
    var authored_velocity_x=pattern.axis==0?pattern.move_speed:0;
    var authored_velocity_y=pattern.axis==0?0:pattern.move_speed;
    var followed_velocity=BattleEditor_RuntimeBuiltinFollowVector(pattern,authored_velocity_x,authored_velocity_y);
    member.hspeed=followed_velocity[0]*global.delta_time_factor;
    member.vspeed=followed_velocity[1]*global.delta_time_factor;
    // The final member count is known up front. Fill the reserved slot instead
    // of occasionally reallocating a growing array on a generation frame.
    pattern.members[descriptor.index]=member;
    return member;
}

function BattleEditor_RuntimeSpawnCorridorPair(controller,pattern,index) {
    var corridor_center=pattern.center_mid+sin(degtorad(index*pattern.center_step))*pattern.center_radius;
    var spawn_time=index*pattern.spawn_interval;
    if(pattern.axis==0){
        BattleEditor_RuntimeSpawnCorridorMember(controller,pattern,{x:pattern.start_x,y:corridor_center-pattern.gap-pattern.bone_length*0.5,angle:90,length:pattern.bone_length,index:index*2,spawn_time:spawn_time});
        BattleEditor_RuntimeSpawnCorridorMember(controller,pattern,{x:pattern.start_x,y:corridor_center+pattern.gap+pattern.bone_length*0.5,angle:90,length:pattern.bone_length,index:index*2+1,spawn_time:spawn_time});
    }else{
        BattleEditor_RuntimeSpawnCorridorMember(controller,pattern,{x:corridor_center-pattern.gap-pattern.bone_length*0.5,y:pattern.start_y,angle:0,length:pattern.bone_length,index:index*2,spawn_time:spawn_time});
        BattleEditor_RuntimeSpawnCorridorMember(controller,pattern,{x:corridor_center+pattern.gap+pattern.bone_length*0.5,y:pattern.start_y,angle:0,length:pattern.bone_length,index:index*2+1,spawn_time:spawn_time});
    }
}

function BattleEditor_RuntimeSpawnPinwheelMember(controller,pattern,index) {
    var a=pattern.phase+index*pattern.angle_step;
    var gx=pattern.cx+sin(degtorad(a))*pattern.rx;
    var gy=pattern.cy+cos(degtorad(a))*pattern.ry;
    // Zero offset means exactly inward, including an elliptical radius where
    // the angular phase itself is not the direction back to the centre.
    var target_angle=point_direction(gx,gy,pattern.cx,pattern.cy)+pattern.facing_offset;
    var spawn_x=gx+lengthdir_x(140,target_angle+180);
    var spawn_y=gy+lengthdir_y(140,target_angle+180);
    var followed_target=BattleEditor_RuntimeBuiltinFollowPose(pattern,gx,gy,target_angle);
    var followed_spawn=BattleEditor_RuntimeBuiltinFollowPose(pattern,spawn_x,spawn_y,target_angle);
    gx=followed_target[0];gy=followed_target[1];target_angle=followed_target[2];
    spawn_x=followed_spawn[0];spawn_y=followed_spawn[1];
    // Creation and firing have independent intervals. Every GB still needs its
    // ordinary entrance plus authored pre-fire wait. If generation is slower
    // than the requested fire cadence, delay the whole firing sequence just
    // enough for the final member to exist; never add generation_interval to
    // every firing gap. Thus an authored fire interval of 5 always produces an
    // actual 5-frame release gap, including when generation uses 0, 2 or 10.
    var desired_release_time=pattern.move+pattern.wait+pattern.fire_schedule_shift+index*pattern.fire_interval;
    var member_wait=max(0,desired_release_time-pattern.age-pattern.move);
    var pinwheel_gb=BattleEditor_RuntimeTrack(controller,Battle_MakeGB(spawn_x,spawn_y,gx,gy,target_angle,target_angle,2,2,pattern.color,member_wait,pattern.beam,pattern.move,false,0,ANIM_TWEEN.EXPO,ANIM_EASE.OUT,1));
    // A pinwheel is only a staggered batch creator. Each member must still use
    // the exact same six-frame head and damage-colour beam definition as a
    // normally created built-in GB; bypassing ApplyGBStyle left this path on
    // spr_gb's old four frames and on the uncoloured fallback beam.
    BattleEditor_ApplyGBStyle(pinwheel_gb,BattleEditor_BuiltinGBStyle(),controller);
    pinwheel_gb.editor_gb_builtin_style=true;
    pinwheel_gb.editor_damage_enabled=true;
    pinwheel_gb.hp_damage=max(0,BattleEditor_DefaultDamageForType(pattern.color));
    pinwheel_gb.kr_damage=pinwheel_gb.hp_damage;
    var pinwheel_damage_profile=Player_AllScriptDamageProfile(pattern.color);
    pinwheel_gb.heal_amount=pinwheel_damage_profile.heal;
    if(struct_exists(pattern.step,"action_damage_change_visual")&&!pattern.step.action_damage_change_visual){
        pinwheel_gb.editor_visual_override=true;
        pinwheel_gb.editor_visual_color=c_white;
    }
    BattleEditor_RuntimeAssignActionIdentity(pinwheel_gb,pattern.step,"gb",index);
    if(struct_exists(pattern,"members")) array_push(pattern.members,pinwheel_gb);
    return pinwheel_gb;
}

function BattleEditor_BuiltinActionDisplayColor(controller,step,damage_type) {
    if(!struct_exists(step,"action_damage_change_visual")||step.action_damage_change_visual) return BattleEditor_ColorForType(damage_type);
    var source=BattleEditor_RuntimePatternSource(controller,step);
    if(!is_undefined(source)&&struct_exists(source,"visual_tint")){
        return source.visual_tint.follow_damage_profile&&struct_exists(source,"damage_profile")
            ?BattleEditor_ColorForType(source.damage_profile.type)
            :source.visual_tint.color;
    }
    return c_white;
}

function BattleEditor_RuntimeStartWallWarning(controller,step) {
    var p=BattleEditor_ActionParts(step.action_arguments);
    var center_x=BattleEditor_ActionNumber(controller,p,0,320),center_y=BattleEditor_ActionNumber(controller,p,1,240);
    var wall_direction=struct_exists(step,"action_direction")?clamp(round(step.action_direction),1,7):1;
    var count=max(1,round(BattleEditor_ActionNumber(controller,p,2,24)));
    var spacing=abs(BattleEditor_ActionNumber(controller,p,3,14));
    var extent=max(1,abs(BattleEditor_ActionNumber(controller,p,4,70)));
    var member_length=max(1,abs(BattleEditor_ActionNumber(controller,p,5,640)));
    var warning_damage_type=clamp(round(BattleEditor_ActionNumber(controller,p,8,0)),0,8);
    var color=BattleEditor_BuiltinActionDisplayColor(controller,step,warning_damage_type);
    var side_count=wall_direction==7?4:(wall_direction>=5?2:1);
    for(var side_index=0;side_index<side_count;side_index++){
        var side=wall_direction==7?side_index+1:(wall_direction==5?side_index+1:(wall_direction==6?side_index+3:wall_direction));
        var warning_x=center_x,warning_y=center_y;
        if(wall_direction>=5){
            if(side==1) warning_y-=extent;
            else if(side==2) warning_y+=extent;
            else if(side==3) warning_x-=extent;
            else warning_x+=extent;
        }
        var row_span=max(12,(count-1)*spacing+12);
        var warning_width=side<=2?row_span:member_length;
        var warning_height=side<=2?member_length:row_span;
        var warning=instance_create_depth(warning_x,warning_y,DEPTH_BATTLE.WARNING,battle_editor_decoration);
        warning.Setup({warning_kind:"box",warning_x:warning_x,warning_y:warning_y,warning_width:warning_width,warning_height:warning_height,warning_color:color,duration:max(1,step.warning_duration),layer_mode:BATTLE_EDITOR_LAYER.OUTSIDE});
        BattleEditor_RuntimeTrack(controller,warning);
    }
    var delayed_step=json_parse(json_stringify(step));
    delayed_step.warning_enabled=false;
    array_push(controller.script_patterns,{kind:"deferred_builtin_warning",age:0,duration:max(1,step.warning_duration),step:delayed_step});
    return true;
}

function BattleEditor_ExecuteBuiltinActionResolved(controller,step) {
    var p=BattleEditor_ActionParts(step.action_arguments);
    var action=step.action_name;
    var keep_objects=false;
    if(action=="bone_wall"&&step.warning_enabled&&step.warning_duration>0) return BattleEditor_RuntimeStartWallWarning(controller,step);
    if(action=="board_shape"){
        var board_shape=clamp(round(BattleEditor_ActionNumber(controller,p,0,1)),0,3);
        var board_shape_duration=max(2,abs(BattleEditor_ActionNumber(controller,p,1,30)));
        return BattleEditor_RuntimeStartBoardMorphByControlId(controller,step.action_control_id,board_shape,board_shape_duration,step.tween,step.ease)>0;
    }
    if(action=="bone_3d"){
        var shape_choice=round(BattleEditor_ActionNumber(controller,p,2,0));
        var shape_3d=shape_choice>=5?6:clamp(shape_choice,0,4);
        var duration=BattleEditor_ActionNumber(controller,p,14,180);
        keep_objects=duration<0;
        var runtime_duration=duration;
        var solid_3d=BattleEditor_RuntimeTrack(controller,Battle_MakeBone3D(
            BattleEditor_ActionNumber(controller,p,0,320),BattleEditor_ActionNumber(controller,p,1,240),
            BattleEditor_ActionNumber(controller,p,3,20),BattleEditor_ActionNumber(controller,p,4,25),BattleEditor_ActionNumber(controller,p,5,0),
            BattleEditor_ActionNumber(controller,p,6,0.5),BattleEditor_ActionNumber(controller,p,7,0.8),BattleEditor_ActionNumber(controller,p,8,0.25),
            BattleEditor_ActionNumber(controller,p,9,40),BattleEditor_ActionNumber(controller,p,10,40),BattleEditor_ActionNumber(controller,p,11,40),
            BattleEditor_ActionNumber(controller,p,13,0),BattleEditor_ActionNumber(controller,p,12,0),shape_3d,
            clamp(round(BattleEditor_ActionNumber(controller,p,18,0)),0,8),clamp(round(BattleEditor_ActionNumber(controller,p,20,1)),0,2),
            runtime_duration,max(0,BattleEditor_ActionNumber(controller,p,15,8)),BattleEditor_ActionNumber(controller,p,16,0),true,max(32,BattleEditor_ActionNumber(controller,p,17,420))));
        solid_3d.editor_damage_enabled=true;solid_3d.hp_damage=max(0,BattleEditor_ActionNumber(controller,p,19,2));
        if(struct_exists(step,"action_damage_change_visual")&&!step.action_damage_change_visual){solid_3d.editor_visual_override=true;solid_3d.editor_visual_color=c_white;}
        BattleEditor_RuntimeAssignActionIdentity(solid_3d,step,"bone_3d",0);
        if(keep_objects) solid_3d._battle_editor_runtime_hold_until_destroy=false;
        if(!keep_objects&&duration>=0) array_push(controller.script_patterns,{kind:"lifetime",age:0,duration:max(1,duration)});
        if(struct_exists(step,"action_follow")&&step.action_follow){
            var solid_3d_follow=BattleEditor_RuntimeBuiltinFollowAttach({kind:"builtin_follow_instance",age:0,duration:keep_objects?max(1,controller.runtime_effective_duration-controller.playhead+1):max(1,duration),target:solid_3d,target_type:"bone_3d"},step);
            array_push(controller.script_patterns,solid_3d_follow);
        }
        return true;
    }
    if(action=="bone_4d"){
        var duration=BattleEditor_ActionNumber(controller,p,19,180);
        keep_objects=duration<0;
        var runtime_duration=duration;
        var solid_4d=BattleEditor_RuntimeTrack(controller,Battle_MakeBone4D(
            BattleEditor_ActionNumber(controller,p,0,320),BattleEditor_ActionNumber(controller,p,1,240),BattleEditor_ActionNumber(controller,p,2,0),
            [BattleEditor_ActionNumber(controller,p,3,20),BattleEditor_ActionNumber(controller,p,4,25),BattleEditor_ActionNumber(controller,p,5,0)],
            [BattleEditor_ActionNumber(controller,p,6,0),BattleEditor_ActionNumber(controller,p,7,0),BattleEditor_ActionNumber(controller,p,8,0)],
            [BattleEditor_ActionNumber(controller,p,9,0.5),BattleEditor_ActionNumber(controller,p,10,0.8),BattleEditor_ActionNumber(controller,p,11,0.25)],
            [BattleEditor_ActionNumber(controller,p,12,0.4),BattleEditor_ActionNumber(controller,p,13,0.6),BattleEditor_ActionNumber(controller,p,14,0.3)],
            [BattleEditor_ActionNumber(controller,p,15,40),BattleEditor_ActionNumber(controller,p,16,40),BattleEditor_ActionNumber(controller,p,17,40),BattleEditor_ActionNumber(controller,p,18,40)],
            clamp(round(BattleEditor_ActionNumber(controller,p,23,0)),0,8),clamp(round(BattleEditor_ActionNumber(controller,p,25,1)),0,2),runtime_duration,max(0,BattleEditor_ActionNumber(controller,p,20,8))));
        solid_4d.perspective_distance=max(32,BattleEditor_ActionNumber(controller,p,21,420));
        solid_4d.perspective4d_distance=max(32,BattleEditor_ActionNumber(controller,p,22,260));
        solid_4d.editor_damage_enabled=true;solid_4d.hp_damage=max(0,BattleEditor_ActionNumber(controller,p,24,2));
        if(struct_exists(step,"action_damage_change_visual")&&!step.action_damage_change_visual){solid_4d.editor_visual_override=true;solid_4d.editor_visual_color=c_white;}
        BattleEditor_RuntimeAssignActionIdentity(solid_4d,step,"bone_4d",0);
        if(keep_objects) solid_4d._battle_editor_runtime_hold_until_destroy=false;
        if(!keep_objects&&duration>=0) array_push(controller.script_patterns,{kind:"lifetime",age:0,duration:max(1,duration)});
        if(struct_exists(step,"action_follow")&&step.action_follow){
            var solid_4d_follow=BattleEditor_RuntimeBuiltinFollowAttach({kind:"builtin_follow_instance",age:0,duration:keep_objects?max(1,controller.runtime_effective_duration-controller.playhead+1):max(1,duration),target:solid_4d,target_type:"bone_4d"},step);
            array_push(controller.script_patterns,solid_4d_follow);
        }
        return true;
    }
    if(action=="bone_orbit"){
        var cx=BattleEditor_ActionNumber(controller,p,0,320),cy=BattleEditor_ActionNumber(controller,p,1,240);
        var rx=BattleEditor_ActionNumber(controller,p,2,110),ry=BattleEditor_ActionNumber(controller,p,3,70);
        var item_count=max(1,round(BattleEditor_ActionNumber(controller,p,4,12)));
        var phase=BattleEditor_ActionNumber(controller,p,5,0),pattern_speed=BattleEditor_ActionNumber(controller,p,6,1.5),facing_offset=BattleEditor_ActionNumber(controller,p,7,0);
        var bone_length=BattleEditor_ActionNumber(controller,p,8,44),enter_value=BattleEditor_ActionNumber(controller,p,9,20);
        var hold_value=BattleEditor_ActionNumber(controller,p,10,120),hold=max(0,hold_value),leave_value=BattleEditor_ActionNumber(controller,p,11,20);
        keep_objects=hold_value<0;
        var enter=abs(enter_value),leave=keep_objects?0:abs(leave_value);
        var color=BattleEditor_ActionNumber(controller,p,12,0),layer_mode=BattleEditor_ActionNumber(controller,p,13,1),bones=[];
        var orbit_duration=max(1,enter+hold+leave);
        // A kept orbit has no exit phase and continues rotating for the rest of
        // the authored turn. It is frozen/cleaned by the ordinary turn owner,
        // not by a second persistent runtime.
        if(keep_objects) orbit_duration=max(orbit_duration,controller.runtime_effective_duration-controller.playhead+1);
        var orbit_source=BattleEditor_RuntimePatternSource(controller,step);
        for(var i=0;i<item_count;i++){
            var orbit_bone=BattleEditor_RuntimePatternMemberResolved(controller,step,orbit_source,cx,cy,0,bone_length,color,orbit_duration,layer_mode,i,keep_objects);
            // The authored ellipse is the visual inner-end path. PatternStep
            // offsets endpoint-origin Bones outward by their visible length,
            // so changing length cannot change the empty inner ellipse. Other
            // templates retain their own origin and capability semantics.
            if(instance_exists(orbit_bone)&&orbit_bone.editor_target_type=="bone"){
                if(variable_instance_exists(orbit_bone,"point")) orbit_bone.point=1;
                if(variable_instance_exists(orbit_bone,"length")) orbit_bone.length=bone_length;
            }
            array_push(bones,orbit_bone);
        }
        var outside_distance=max(room_width,room_height)+max(abs(rx),abs(ry))+max(1,abs(bone_length));
        var orbit_anchor={x:cx,y:cy,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_orbit"};
        var orbit_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"bone_orbit",controller_kind:"bone_orbit",age:0,duration:orbit_duration,enter:enter,hold:keep_objects?max(hold,orbit_duration-enter):hold,leave:leave,enter_inward:enter_value>=0,leave_outward:leave_value>=0,outside_distance:outside_distance,anchor:orbit_anchor,rx:rx,ry:ry,phase:phase,pattern_speed:pattern_speed,facing_offset:facing_offset,enter_tween:step.tween,enter_ease:step.ease,exit_tween:step.action_exit_tween,exit_ease:step.action_exit_ease,keep_objects:keep_objects,bones:bones},step);
        array_push(controller.script_patterns,orbit_pattern);
        return true;
    }
    if(action=="bone_wave"){
        var cx=BattleEditor_ActionNumber(controller,p,0,320),cy=BattleEditor_ActionNumber(controller,p,1,240);
        var axis=clamp(round(BattleEditor_ActionNumber(controller,p,2,0)),0,1),span=BattleEditor_ActionNumber(controller,p,3,260);
        var item_count=max(1,round(BattleEditor_ActionNumber(controller,p,4,12))),bone_length=max(1,BattleEditor_ActionNumber(controller,p,5,120));
        var wave_radius=abs(BattleEditor_ActionNumber(controller,p,6,65)),pattern_speed=BattleEditor_ActionNumber(controller,p,7,4);
        var duration_value=BattleEditor_ActionNumber(controller,p,8,180);
        keep_objects=duration_value<0;
        var duration=keep_objects?max(1,controller.runtime_effective_duration-controller.playhead+1):max(1,duration_value);
        var color=BattleEditor_ActionNumber(controller,p,9,0),layer_mode=BattleEditor_ActionNumber(controller,p,10,0),bones=[];
        var wave_source=BattleEditor_RuntimePatternSource(controller,step);
        for(var i=0;i<item_count;i++){
            var wave_base=-span*0.5+(item_count==1?0:i*span/(item_count-1));
            var wave_x=axis==0?cx+wave_base:cx;
            var wave_y=axis==0?cy:cy+wave_base;
            var wave_bone=BattleEditor_RuntimePatternMemberResolved(controller,step,wave_source,wave_x,wave_y,axis==0?90:0,bone_length,color,duration,layer_mode,i,keep_objects);
            array_push(bones,wave_bone);
        }
        var wave_anchor={x:cx,y:cy,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_wave"};
        var wave_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"bone_wave",controller_kind:"bone_wave",age:0,duration:duration,anchor:wave_anchor,cx:cx,cy:cy,axis:axis,span:span,wave_radius:wave_radius,pattern_speed:pattern_speed,keep_objects:keep_objects,bones:bones},step);
        array_push(controller.script_patterns,wave_pattern);
        return true;
    }
    if(action=="bone_corridor"){
        var axis=round(BattleEditor_ActionNumber(controller,p,0,0)),start_x=BattleEditor_ActionNumber(controller,p,1,-40),start_y=BattleEditor_ActionNumber(controller,p,2,240);
        var item_count=max(1,round(BattleEditor_ActionNumber(controller,p,3,12))),spacing=BattleEditor_ActionNumber(controller,p,4,60);
        var gap=BattleEditor_ActionNumber(controller,p,5,55),bone_length=BattleEditor_ActionNumber(controller,p,6,120);
        var center_min=BattleEditor_ActionNumber(controller,p,7,axis==0?190:270),center_max=BattleEditor_ActionNumber(controller,p,8,axis==0?290:370);
        var center_step=BattleEditor_ActionNumber(controller,p,9,30),move_speed=BattleEditor_ActionNumber(controller,p,10,3);
        var duration_value=BattleEditor_ActionNumber(controller,p,11,260);keep_objects=duration_value<0;
        var color=BattleEditor_ActionNumber(controller,p,12,0),layer_mode=BattleEditor_ActionNumber(controller,p,13,0),corridor_members=array_create(item_count*2,noone);
        var corridor_source=BattleEditor_RuntimePatternSource(controller,step);
        var corridor_spawn_interval=abs(move_speed)>0.0001?abs(spacing/move_speed):1;
        var corridor_generation_duration=max(0,(item_count-1)*corridor_spawn_interval);
        var automatic_member_duration=BattleEditor_CorridorAutomaticDuration(controller,axis,start_x,start_y,1,0,move_speed,layer_mode,5);
        var automatic_corridor_duration=automatic_member_duration>0?corridor_generation_duration+automatic_member_duration:0;
        var authored_remaining=max(1,controller.runtime_effective_duration-controller.playhead+1);
        var member_duration=keep_objects?(automatic_member_duration>0?automatic_member_duration:authored_remaining):max(1,duration_value);
        var duration=keep_objects?(automatic_corridor_duration>0?max(authored_remaining,automatic_corridor_duration):authored_remaining):corridor_generation_duration+member_duration;
        var center_mid=(center_min+center_max)*0.5,center_radius=abs(center_max-center_min)*0.5;
        var corridor_anchor={x:start_x,y:start_y,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_corridor"};
        var corridor_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"lifetime_members",controller_kind:"bone_corridor",age:0,duration:duration,member_duration:member_duration,keep_objects:keep_objects,corridor_auto:keep_objects&&automatic_corridor_duration>0,corridor_seen_visible:false,retire_index:0,layer_mode:layer_mode,axis:axis,move_speed:move_speed,color:color,source:corridor_source,step:step,anchor:corridor_anchor,anchor_origin_x:start_x,anchor_origin_y:start_y,anchor_last_x:start_x,anchor_last_y:start_y,members:corridor_members,start_x:start_x,start_y:start_y,gap:gap,bone_length:bone_length,center_mid:center_mid,center_radius:center_radius,center_step:center_step,spawn_interval:corridor_spawn_interval,count:item_count,next_index:0},step);
        BattleEditor_RuntimeSpawnCorridorPair(controller,corridor_pattern,0);
        corridor_pattern.next_index=1;
        array_push(controller.script_patterns,corridor_pattern);
        return true;
    }
    if(action=="bone_physics"){
        var scatter_x=BattleEditor_ActionNumber(controller,p,0,320),scatter_y=BattleEditor_ActionNumber(controller,p,1,240),item_count=max(1,round(BattleEditor_ActionNumber(controller,p,2,18)));
        var duration_value=BattleEditor_ActionNumber(controller,p,11,180);keep_objects=duration_value<0;
        var duration=keep_objects?max(1,controller.runtime_effective_duration-controller.playhead+1):max(1,duration_value),color=BattleEditor_ActionNumber(controller,p,12,0),layer_mode=BattleEditor_ActionNumber(controller,p,13,1),physics_entries=[];
        var physics_source=BattleEditor_RuntimePatternSource(controller,step);
        for(var i=0;i<item_count;i++){
            // Every random value comes from a visible min/max pair. Identical
            // endpoints are the explicit fixed-value form.
            var physics_member=BattleEditor_RuntimePatternMemberResolved(controller,step,physics_source,scatter_x,scatter_y,0,BattleEditor_ActionRange(controller,p,9,10,20,70),color,duration,layer_mode,i,keep_objects);
            var physics_angle_property=BattleEditor_RuntimeOrbitAngleProperty(physics_member,physics_member.editor_target_type);
            array_push(physics_entries,{target:physics_member,vx:BattleEditor_ActionRange(controller,p,3,4,-3,3),vy:BattleEditor_ActionRange(controller,p,5,6,-5,-2),angular_velocity:BattleEditor_ActionRange(controller,p,7,8,-8,8),angle_property:physics_angle_property});
        }
        var physics_anchor={x:scatter_x,y:scatter_y,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_physics"};
        var physics_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"generated_physics",controller_kind:"bone_physics",age:0,duration:duration,keep_objects:keep_objects,anchor:physics_anchor,anchor_last_x:scatter_x,anchor_last_y:scatter_y,entries:physics_entries},step);
        array_push(controller.script_patterns,physics_pattern);
        return true;
    }
    if(action=="bone_function_path"){
        var path_pattern=BattleEditor_FunctionPathDefinition(controller,step);
        var path_duration_value=BattleEditor_ActionNumber(controller,p,6,180);keep_objects=path_duration_value<0;
        if(keep_objects) path_pattern.duration=max(1,controller.runtime_effective_duration-controller.playhead+1);
        path_pattern.kind="bone_function_path";
        path_pattern.age=0;
        path_pattern.keep_objects=keep_objects;
        path_pattern.owns_members=round(real(step.action_path_mode))==0;
        path_pattern.entries=[];
        var path_duration=path_pattern.duration;
        if(path_pattern.owns_members){
            var path_source_uid=struct_exists(step,"action_source_uid")?real(step.action_source_uid):-1;
            var path_source=path_source_uid>=0?BattleEditor_FindEventDataByUid(controller.project,path_source_uid):undefined;
            var path_legacy_default=struct_exists(step,"action_path_legacy_default")&&step.action_path_legacy_default;
            if((is_undefined(path_source)||BattleEditor_DataTargetType(path_source)=="gb")&&!path_legacy_default) return false;
            var path_source_x=320,path_source_y=240;
            if(!is_undefined(path_source)){
                var path_runtime_source=BattleEditor_FindRuntimeValueTarget(controller,path_source_uid);
                if(!is_undefined(path_runtime_source)){
                    path_source_x=BattleEditor_ReadNumericProperty(path_runtime_source,BattleEditor_DataTargetType(path_source),"x",320);
                    path_source_y=BattleEditor_ReadNumericProperty(path_runtime_source,BattleEditor_DataTargetType(path_source),"y",240);
                }else{
                    var path_source_pose=BattleEditor_EventWorldPose(path_source,controller.project,variable_instance_exists(controller,"main_board_preview")?controller.main_board_preview:undefined);
                    path_source_x=path_source_pose.x;
                    path_source_y=path_source_pose.y;
                }
            }
            path_pattern.base_x=BattleEditor_FunctionPathResolveBase(controller,path_pattern.base_x_expression,path_source_x,path_source_y,path_source_x);
            path_pattern.base_y=BattleEditor_FunctionPathResolveBase(controller,path_pattern.base_y_expression,path_source_x,path_source_y,path_source_y);
            var path_initial_position=BattleEditor_RuntimeFunctionPathPoint(controller,path_pattern,path_pattern.t0,0);
            var path_member=BattleEditor_RuntimePatternMember(controller,step,path_initial_position[0],path_initial_position[1],path_pattern.fixed_angle,BattleEditor_ActionNumber(controller,p,7,44),BattleEditor_ActionNumber(controller,p,10,0),path_duration,BattleEditor_ActionNumber(controller,p,11,1),0,keep_objects);
            if(instance_exists(path_member)) array_push(path_pattern.entries,{target:path_member,target_type:path_member.editor_target_type,offset_x:0,offset_y:0});
        }else{
            var path_selector={target_mode:"control_id",target_uid:-1,target:string(step.action_control_id),target_type:string(step.action_path_target_type)};
            var path_targets=BattleEditor_RuntimeCollectControlTargets(controller,path_selector);
            if(array_length(path_targets)<=0) return false;
            var path_group_x=0,path_group_y=0;
            for(var path_target_index=0;path_target_index<array_length(path_targets);path_target_index++){
                var path_target=path_targets[path_target_index];
                path_group_x+=is_struct(path_target)?variable_struct_get(path_target,"x"):path_target.x;
                path_group_y+=is_struct(path_target)?variable_struct_get(path_target,"y"):path_target.y;
            }
            path_group_x/=array_length(path_targets);path_group_y/=array_length(path_targets);
            path_pattern.base_x=BattleEditor_FunctionPathResolveBase(controller,path_pattern.base_x_expression,path_group_x,path_group_y,path_group_x);
            path_pattern.base_y=BattleEditor_FunctionPathResolveBase(controller,path_pattern.base_y_expression,path_group_x,path_group_y,path_group_y);
            for(var path_target_index=0;path_target_index<array_length(path_targets);path_target_index++){
                var path_target=path_targets[path_target_index];
                var path_target_x=is_struct(path_target)?variable_struct_get(path_target,"x"):path_target.x;
                var path_target_y=is_struct(path_target)?variable_struct_get(path_target,"y"):path_target.y;
                array_push(path_pattern.entries,{target:path_target,target_type:string(step.action_path_target_type),offset_x:path_target_x-path_group_x,offset_y:path_target_y-path_group_y});
            }
        }
        path_pattern.controller_kind="bone_function_path";
        path_pattern.anchor={x:path_pattern.base_x,y:path_pattern.base_y,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_function_path"};
        path_pattern=BattleEditor_RuntimeBuiltinFollowAttach(path_pattern,step);
        array_push(controller.script_patterns,path_pattern);
        return true;
    }
    if(action=="gb_pinwheel"){
        var cx=BattleEditor_ActionNumber(controller,p,0,320),cy=BattleEditor_ActionNumber(controller,p,1,240),rx=BattleEditor_ActionNumber(controller,p,2,130),ry=BattleEditor_ActionNumber(controller,p,3,90);
        var item_count=max(1,round(BattleEditor_ActionNumber(controller,p,4,8))),phase=BattleEditor_ActionNumber(controller,p,5,0),angle_step=BattleEditor_ActionNumber(controller,p,6,45),facing_offset=BattleEditor_ActionNumber(controller,p,7,0);
        var generation_interval=max(0,BattleEditor_ActionNumber(controller,p,8,0)),fire_interval=max(0,BattleEditor_ActionNumber(controller,p,9,0));
        var wait=max(0,BattleEditor_ActionNumber(controller,p,10,35)),beam=max(1,BattleEditor_ActionNumber(controller,p,11,50)),move=max(0,BattleEditor_ActionNumber(controller,p,12,35)),color=clamp(round(BattleEditor_ActionNumber(controller,p,13,0)),0,8);
        // This is a finite sequence generator, not a maintained rotating ring.
        // A zero interval is the simultaneous shortcut; positive values expose
        // independent creation and firing order.
        var pinwheel_last_generation=(item_count-1)*generation_interval;
        var pinwheel_last_fire_offset=(item_count-1)*fire_interval;
        var pinwheel_fire_schedule_shift=max(0,pinwheel_last_generation-pinwheel_last_fire_offset);
        var pinwheel_last_release=move+wait+pinwheel_fire_schedule_shift+pinwheel_last_fire_offset;
        var pinwheel_duration=max(1,pinwheel_last_release+beam+90);
        var pinwheel_anchor={x:cx,y:cy,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"gb_pinwheel"};
        var pinwheel_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"gb_pinwheel_sequence",controller_kind:"gb_pinwheel",age:0,duration:pinwheel_duration,anchor:pinwheel_anchor,next_index:0,count:item_count,cx:cx,cy:cy,rx:rx,ry:ry,phase:phase,angle_step:angle_step,facing_offset:facing_offset,generation_interval:generation_interval,fire_interval:fire_interval,wait:wait,fire_schedule_shift:pinwheel_fire_schedule_shift,beam:beam,move:move,color:color,step:step,members:[]},step);
        while(pinwheel_pattern.next_index<pinwheel_pattern.count&&pinwheel_pattern.next_index*generation_interval<=0){
            BattleEditor_RuntimeSpawnPinwheelMember(controller,pinwheel_pattern,pinwheel_pattern.next_index);
            pinwheel_pattern.next_index+=1;
        }
        array_push(controller.script_patterns,pinwheel_pattern);
        return true;
    }
    if(action=="bone_wall"){
        var wall_center_x=BattleEditor_ActionNumber(controller,p,0,320),wall_center_y=BattleEditor_ActionNumber(controller,p,1,240);
        var wall_direction=struct_exists(step,"action_direction")?clamp(round(step.action_direction),1,7):1;
        var wall_count=max(1,round(BattleEditor_ActionNumber(controller,p,2,24)));
        var wall_spacing=BattleEditor_ActionNumber(controller,p,3,14),wall_extent=max(1,BattleEditor_ActionNumber(controller,p,4,70));
        var wall_bone_length=max(1,BattleEditor_ActionNumber(controller,p,5,640));
        var wall_speed=BattleEditor_ActionNumber(controller,p,6,7),wall_hold_value=BattleEditor_ActionNumber(controller,p,7,90),wall_hold=max(0,wall_hold_value);
        keep_objects=wall_hold_value<0;
        var wall_color=BattleEditor_ActionNumber(controller,p,8,0),wall_layer=BattleEditor_ActionNumber(controller,p,9,0);
        var wall_travel=max(1,wall_extent/max(0.001,abs(wall_speed))),wall_duration=wall_travel+(keep_objects?0:wall_travel)+wall_hold;
        if(keep_objects){wall_duration=max(wall_travel,controller.runtime_effective_duration-controller.playhead+1);wall_hold=max(0,wall_duration-wall_travel);}
        var wall_side_count=wall_direction==7?4:(wall_direction>=5?2:1);
        var wall_source=BattleEditor_RuntimePatternSource(controller,step);
        for(var wall_side_index=0;wall_side_index<wall_side_count;wall_side_index++){
            var wall_side_direction=wall_direction==7?wall_side_index+1:(wall_direction==5?wall_side_index+1:(wall_direction==6?wall_side_index+3:wall_direction));
            var wall_dx=0,wall_dy=0,wall_target_dx=0,wall_target_dy=0,wall_angle=0;
            if(wall_side_direction==1){wall_dy=1;wall_target_dy=-1;wall_angle=-90;}
            else if(wall_side_direction==2){wall_dy=-1;wall_target_dy=1;wall_angle=90;}
            // dx/dy is the outside spawn offset, hence it points opposite the
            // named travel direction. Target-side placement stays independent.
            else if(wall_side_direction==3){wall_dx=1;wall_target_dx=-1;wall_angle=0;}
            else{wall_dx=-1;wall_target_dx=1;wall_angle=180;}
            var wall_bones=[],wall_base_x=[],wall_base_y=[];
            for(var wall_index=0;wall_index<wall_count;wall_index++){
                var wall_center_offset=(wall_index-(wall_count-1)*0.5)*wall_spacing;
                var wall_x=wall_center_x+(wall_side_direction<=2?wall_center_offset:0);
                var wall_y=wall_center_y+(wall_side_direction>=3?wall_center_offset:0);
                // In the paired/four-side shortcuts X/Y is the square centre
                // and this value is its centre radius. A single side keeps X/Y
                // as the exact authored target position.
                if(wall_direction>=5){
                    // Target-side placement and runtime motion are separate:
                    // a shortcut's Left member always belongs on the left edge
                    // even when its visible movement mapping changes.
                    wall_x+=wall_target_dx*wall_extent;
                    wall_y+=wall_target_dy*wall_extent;
                }
                var wall_bone=BattleEditor_RuntimePatternMemberResolved(controller,step,wall_source,wall_x,wall_y,wall_angle,wall_bone_length,wall_color,wall_duration,wall_layer,wall_side_index*wall_count+wall_index,keep_objects);
                // Bone's normal sprite is centre-origin. A wall's authored
                // target is its head, so reuse the engine's endpoint-origin
                // mode. Other template object types keep their own origin.
                if(instance_exists(wall_bone)&&wall_bone.editor_target_type=="bone"){
                    if(variable_instance_exists(wall_bone,"point")) wall_bone.point=1;
                    if(variable_instance_exists(wall_bone,"length")) wall_bone.length=wall_bone_length;
                }
                array_push(wall_bones,wall_bone);array_push(wall_base_x,wall_x);array_push(wall_base_y,wall_y);
            }
            // One invocation may create one wall or the four sides of a square.
            // Every bone still shares the same author-facing control ID.
            var wall_anchor={x:wall_center_x,y:wall_center_y,control_id:string(step.action_control_id),editor_target_type:"path_point",editor_group_kind:"bone_wall"};
            var wall_pattern=BattleEditor_RuntimeBuiltinFollowAttach({kind:"bone_wall",controller_kind:"bone_wall",age:0,duration:wall_duration,travel:wall_travel,hold:wall_hold,distance:wall_extent,dx:wall_dx,dy:wall_dy,enter_tween:step.tween,enter_ease:step.ease,exit_tween:step.action_exit_tween,exit_ease:step.action_exit_ease,keep_objects:keep_objects,anchor:wall_anchor,anchor_last_x:wall_center_x,anchor_last_y:wall_center_y,bones:wall_bones,base_x:wall_base_x,base_y:wall_base_y},step);
            array_push(controller.script_patterns,wall_pattern);
        }
        return true;
    }
    return false;
}

/// Resolve the complete formula-variable scope once per action invocation.
/// The resolved implementation may return from many action branches, so this
/// wrapper also restores an outer scope when a deferred action invokes another
/// built-in action synchronously.
function BattleEditor_ExecuteBuiltinAction(controller,step) {
    var had_active=variable_instance_exists(controller,"_runtime_action_expression_scope_active");
    var previous_active=had_active?controller._runtime_action_expression_scope_active:false;
    var had_ready=variable_instance_exists(controller,"_runtime_action_expression_scope_ready");
    var previous_ready=had_ready?controller._runtime_action_expression_scope_ready:false;
    var had_variables=variable_instance_exists(controller,"_runtime_action_expression_variables");
    var previous_variables=had_variables?controller._runtime_action_expression_variables:{};
    controller._runtime_action_expression_scope_active=true;
    controller._runtime_action_expression_scope_ready=false;
    var result=BattleEditor_ExecuteBuiltinActionResolved(controller,step);
    controller._runtime_action_expression_scope_active=previous_active;
    controller._runtime_action_expression_scope_ready=previous_ready;
    controller._runtime_action_expression_variables=previous_variables;
    return result;
}

function BattleEditor_ExecuteScreenAction(controller,step) {
    var p=BattleEditor_ActionParts(step.screen_arguments),action=step.screen_action;
    if(!instance_exists(camera)) return false;
    if(action=="camera_set"){
        var tx=BattleEditor_ActionNumber(controller,p,0,320),ty=BattleEditor_ActionNumber(controller,p,1,240),tsx=max(0.01,BattleEditor_ActionNumber(controller,p,2,1)),tsy=max(0.01,BattleEditor_ActionNumber(controller,p,3,1));
        var ta=BattleEditor_ActionNumber(controller,p,4,0),duration=max(0,BattleEditor_ActionNumber(controller,p,5,30));
        camera.editor_center_enabled=true;
        if(duration<=0){camera.editor_center_x=tx;camera.editor_center_y=ty;camera.scale_x=tsx;camera.scale_y=tsy;camera.angle=ta;}
        else array_push(controller.script_patterns,{kind:"camera_tween",age:0,duration:duration,x0:camera.editor_center_x,y0:camera.editor_center_y,sx0:camera.scale_x,sy0:camera.scale_y,a0:camera.angle,x1:tx,y1:ty,sx1:tsx,sy1:tsy,a1:ta,tween:step.tween,ease:step.ease});
        return true;
    }
    if(action=="camera_sine"){
        camera.editor_center_enabled=true;
        array_push(controller.script_patterns,{kind:"camera_sine",age:0,duration:max(1,BattleEditor_ActionNumber(controller,p,4,180)),base_x:camera.editor_center_x,base_y:camera.editor_center_y,base_angle:camera.angle,amp_x:BattleEditor_ActionNumber(controller,p,0,8),amp_y:BattleEditor_ActionNumber(controller,p,1,4),amp_angle:BattleEditor_ActionNumber(controller,p,2,3),speed:BattleEditor_ActionNumber(controller,p,3,6)});
        return true;
    }
    if(action=="camera_shake"){
        var random_mode=BattleEditor_ActionNumber(controller,p,4,1)!=0;
        Camera_Shake(BattleEditor_ActionNumber(controller,p,0,8),BattleEditor_ActionNumber(controller,p,1,8),BattleEditor_ActionNumber(controller,p,2,1),BattleEditor_ActionNumber(controller,p,3,1),random_mode,random_mode,BattleEditor_ActionNumber(controller,p,5,0.35),BattleEditor_ActionNumber(controller,p,6,0.35),BattleEditor_ActionNumber(controller,p,7,0)!=0);
        return true;
    }
    var fx=BattleEditor_EffectsEnsure();
    if(action=="effect_hue"){fx.hue=BattleEditor_ActionNumber(controller,p,0,0);return true;}
    if(action=="effect_saturation"){fx.saturation=max(0,BattleEditor_ActionNumber(controller,p,0,1));return true;}
    if(action=="effect_brightness"){fx.brightness=BattleEditor_ActionNumber(controller,p,0,0);return true;}
    if(action=="effect_contrast"){fx.contrast=max(0,BattleEditor_ActionNumber(controller,p,0,1));return true;}
    if(action=="effect_grayscale"){fx.grayscale=clamp(BattleEditor_ActionNumber(controller,p,0,0),0,1);return true;}
    if(action=="effect_invert"){fx.invert=clamp(BattleEditor_ActionNumber(controller,p,0,0),0,1);return true;}
    if(action=="effect_glitch_amount"){fx.glitch=max(0,BattleEditor_ActionNumber(controller,p,0,0.35));return true;}
    if(action=="effect_chromatic"){fx.chromatic=max(0,BattleEditor_ActionNumber(controller,p,0,3));return true;}
    if(action=="effect_scanline"){fx.scanline=clamp(BattleEditor_ActionNumber(controller,p,0,0.15),0,1);return true;}
    if(action=="effect_wave"){fx.wave=BattleEditor_ActionNumber(controller,p,0,1.5);return true;}
    if(action=="effect_vignette_amount"){fx.vignette=clamp(BattleEditor_ActionNumber(controller,p,0,0.35),0,1);return true;}
    if(action=="effect_pixelate"){fx.pixel_size=max(1,BattleEditor_ActionNumber(controller,p,0,1));return true;}
    // Legacy combined actions remain executable only for pre-v14 files while
    // normalization splits them into independent author-facing steps.
    if(action=="effect_color"){
        fx.hue=BattleEditor_ActionNumber(controller,p,0,0);fx.saturation=max(0,BattleEditor_ActionNumber(controller,p,1,1));fx.brightness=BattleEditor_ActionNumber(controller,p,2,0);fx.contrast=max(0,BattleEditor_ActionNumber(controller,p,3,1));fx.grayscale=clamp(BattleEditor_ActionNumber(controller,p,4,0),0,1);fx.invert=clamp(BattleEditor_ActionNumber(controller,p,5,0),0,1);return true;
    }
    if(action=="effect_glitch"){
        fx.glitch=max(0,BattleEditor_ActionNumber(controller,p,0,0.35));fx.chromatic=max(0,BattleEditor_ActionNumber(controller,p,1,3));fx.scanline=clamp(BattleEditor_ActionNumber(controller,p,2,0.15),0,1);fx.wave=BattleEditor_ActionNumber(controller,p,3,1.5);return true;
    }
    if(action=="effect_vignette"){
        fx.vignette=clamp(BattleEditor_ActionNumber(controller,p,0,0.35),0,1);fx.pixel_size=max(1,BattleEditor_ActionNumber(controller,p,1,1));return true;
    }
    if(action=="effect_blur"){
        global.blur_amount=clamp(round(BattleEditor_ActionNumber(controller,p,0,3)),0,12);global.blur_strength=[BattleEditor_ActionNumber(controller,p,1,1),BattleEditor_ActionNumber(controller,p,2,1)];return true;
    }
    if(action=="screen_reset"){
        BattleEditor_EffectsReset();
        if(variable_instance_exists(controller,"screen_original")&&!is_undefined(controller.screen_original)){
            var original=controller.screen_original;camera.editor_center_enabled=false;camera.x=original.x;camera.y=original.y;camera.scale_x=original.scale_x;camera.scale_y=original.scale_y;camera.angle=original.angle;
        }
        return true;
    }
    return false;
}

function BattleEditor_RuntimePatternStep(controller) {
    for(var pattern_index=array_length(controller.script_patterns)-1;pattern_index>=0;pattern_index--){
        var pattern=controller.script_patterns[pattern_index];
        pattern.age+=global.delta_time_factor;
        var done=pattern.age>=pattern.duration;
        if(pattern.kind=="deferred_control_warning"){
            if(done){
                if(struct_exists(pattern,"retag_targets")) BattleEditor_RuntimeRetagControlTargets(pattern.retag_targets,pattern.temporary_control_id);
                BattleEditor_RuntimeControlObjectNow(controller,pattern.step);
                if(struct_exists(pattern,"retag_targets")) BattleEditor_RuntimeRetagControlTargets(pattern.retag_targets,pattern.final_control_id);
            }
        }else if(pattern.kind=="deferred_builtin_warning"){
            if(done) BattleEditor_ExecuteBuiltinAction(controller,pattern.step);
        }else if(pattern.kind=="builtin_follow_instance"){
            var instance_follow_delta=BattleEditor_RuntimeBuiltinFollowDelta(pattern);
            BattleEditor_RuntimeApplyBuiltinFollowDelta(pattern.target,pattern.target_type,instance_follow_delta,true);
        }else if(pattern.kind=="control_follow_instance"){
            // Control Object can attach this relationship to any concrete
            // movable instance. It follows the selected frame's world-space
            // translation and rotation until disabled or runtime teardown.
            if(!instance_exists(pattern.target)) done=true;
            else{
                done=false;
                var control_follow_delta=BattleEditor_RuntimeBuiltinFollowDelta(pattern);
                BattleEditor_RuntimeApplyBuiltinFollowDelta(pattern.target,pattern.target_type,control_follow_delta,true);
            }
        }else if(pattern.kind=="lifetime_members"&&struct_exists(pattern,"anchor")){
            var member_follow_delta=BattleEditor_RuntimeBuiltinFollowDelta(pattern);
            var member_follow_limit=struct_exists(pattern,"controller_kind")&&pattern.controller_kind=="bone_corridor"?min(array_length(pattern.members),pattern.next_index*2):array_length(pattern.members);
            if(member_follow_delta.active) for(var member_follow_index=0;member_follow_index<member_follow_limit;member_follow_index++){
                var member_follow_target=pattern.members[member_follow_index];
                if(instance_exists(member_follow_target)) BattleEditor_RuntimeApplyBuiltinFollowDelta(member_follow_target,member_follow_target.editor_target_type,member_follow_delta,true);
            }
            var member_shift_x=pattern.anchor.x-pattern.anchor_last_x;
            var member_shift_y=pattern.anchor.y-pattern.anchor_last_y;
            if(member_shift_x!=0||member_shift_y!=0){
                for(var shifted_member_index=0;shifted_member_index<member_follow_limit;shifted_member_index++) if(instance_exists(pattern.members[shifted_member_index])){
                    pattern.members[shifted_member_index].x+=member_shift_x;
                    pattern.members[shifted_member_index].y+=member_shift_y;
                }
                pattern.anchor_last_x=pattern.anchor.x;pattern.anchor_last_y=pattern.anchor.y;
            }
        }else if(pattern.kind=="bone_orbit"){
            var radius_factor=1,radial_offset=0;
            if(pattern.enter>0&&pattern.age<pattern.enter){
                var enter_amount=Anim_GetValue(pattern.enter_tween,pattern.enter_ease,clamp(pattern.age/pattern.enter,0,1));
                if(pattern.enter_inward) radial_offset=lerp(pattern.outside_distance,0,enter_amount);
                else radius_factor=enter_amount;
            }else if(pattern.leave>0&&pattern.age>pattern.enter+pattern.hold){
                var leave_amount=Anim_GetValue(pattern.exit_tween,pattern.exit_ease,clamp((pattern.age-pattern.enter-pattern.hold)/pattern.leave,0,1));
                if(pattern.leave_outward) radial_offset=lerp(0,pattern.outside_distance,leave_amount);
                else radius_factor=1-leave_amount;
            }
            var orbit_cx=pattern.anchor.x,orbit_cy=pattern.anchor.y;
            for(var i=0;i<array_length(pattern.bones);i++) if(instance_exists(pattern.bones[i])){
                var a=pattern.phase+pattern.pattern_speed*pattern.age+i*360/array_length(pattern.bones),bone=pattern.bones[i];
                var radial_x=cos(degtorad(a)),radial_y=sin(degtorad(a));
                var orbit_x=orbit_cx+radial_x*(pattern.rx*radius_factor+radial_offset);
                var orbit_y=orbit_cy+radial_y*(pattern.ry*radius_factor+radial_offset);
                var orbit_facing=point_direction(orbit_x,orbit_y,orbit_cx,orbit_cy)+pattern.facing_offset;
                var orbit_pose_x=orbit_x,orbit_pose_y=orbit_y;
                if(bone.editor_target_type=="bone"&&variable_instance_exists(bone,"point")&&round(real(bone.point))==1){
                    // spr_bone_1's instance origin is one end of the stretched
                    // sprite. The authored radius describes the inner visual
                    // end (the edge of the empty centre circle), so place the
                    // instance origin one complete visible Bone length farther
                    // outward. Changing length can no longer change the ring.
                    var orbit_visible_length=max(1,real(bone.length)+10);
                    orbit_pose_x=orbit_x-lengthdir_x(orbit_visible_length,orbit_facing);
                    orbit_pose_y=orbit_y-lengthdir_y(orbit_visible_length,orbit_facing);
                }
                BattleEditor_RuntimePatternSetFollowPose(pattern,bone,bone.editor_target_type,orbit_pose_x,orbit_pose_y,orbit_facing);
            }
        }else if(pattern.kind=="bone_wall"){
            var wall_shift_x=pattern.anchor.x-pattern.anchor_last_x;
            var wall_shift_y=pattern.anchor.y-pattern.anchor_last_y;
            if(wall_shift_x!=0||wall_shift_y!=0){
                for(var wall_shift_index=0;wall_shift_index<array_length(pattern.base_x);wall_shift_index++){
                    pattern.base_x[wall_shift_index]+=wall_shift_x;
                    pattern.base_y[wall_shift_index]+=wall_shift_y;
                }
                pattern.anchor_last_x=pattern.anchor.x;pattern.anchor_last_y=pattern.anchor.y;
            }
            var wall_amount=1;
            if(pattern.age<pattern.travel){
                wall_amount=Anim_GetValue(pattern.enter_tween,pattern.enter_ease,clamp(pattern.age/pattern.travel,0,1));
            }else if(pattern.age>pattern.travel+pattern.hold){
                var wall_exit=clamp((pattern.age-pattern.travel-pattern.hold)/pattern.travel,0,1);
                wall_amount=1-Anim_GetValue(pattern.exit_tween,pattern.exit_ease,wall_exit);
            }
            for(var wall_index=0;wall_index<array_length(pattern.bones);wall_index++) if(instance_exists(pattern.bones[wall_index])){
                // base_x/base_y is the single-side target, or the selected
                // side's target after the paired/four-side centre-radius
                // offset. Spawn one target-height farther outside, enter to
                // that target, then leave back outward.
                var wall_outside_amount=1-wall_amount;
                BattleEditor_RuntimePatternSetFollowPose(pattern,pattern.bones[wall_index],pattern.bones[wall_index].editor_target_type,pattern.base_x[wall_index]+pattern.dx*pattern.distance*wall_outside_amount,pattern.base_y[wall_index]+pattern.dy*pattern.distance*wall_outside_amount);
            }
        }else if(pattern.kind=="bone_wave"){
            pattern.cx=pattern.anchor.x;pattern.cy=pattern.anchor.y;
            var item_count=max(1,array_length(pattern.bones));
            for(var i=0;i<item_count;i++){
                var base=-pattern.span*0.5+(item_count==1?0:i*pattern.span/(item_count-1));
                var wave_offset=sin(degtorad(pattern.age*pattern.pattern_speed+i*360/item_count))*pattern.wave_radius;
                var wave_bone=pattern.bones[i];
                if(pattern.axis==0){
                    if(instance_exists(wave_bone)) BattleEditor_RuntimePatternSetFollowPose(pattern,wave_bone,wave_bone.editor_target_type,pattern.cx+base,pattern.cy+wave_offset);
                }else{
                    if(instance_exists(wave_bone)) BattleEditor_RuntimePatternSetFollowPose(pattern,wave_bone,wave_bone.editor_target_type,pattern.cx+wave_offset,pattern.cy+base);
                }
            }
        }else if(pattern.kind=="control_bone_length"){
            var length_t=clamp(pattern.age/max(1,pattern.duration),0,1);
            var length_amount=Anim_GetValue(pattern.tween,pattern.ease,length_t);
            for(var length_index=0;length_index<array_length(pattern.entries);length_index++){
                var length_entry=pattern.entries[length_index];
                BattleEditor_RuntimeApplyBoneLengthEntry(length_entry,lerp(length_entry.start_length,length_entry.target_length,length_amount));
            }
        }else if(pattern.kind=="control_orbit"){
            var orbit_t=clamp(pattern.age/max(1,pattern.duration),0,1);
            var orbit_amount=pattern.degrees*Anim_GetValue(pattern.tween,pattern.ease,orbit_t);
            for(var orbit_index=0;orbit_index<array_length(pattern.entries);orbit_index++) BattleEditor_RuntimeApplyOrbitEntry(pattern.entries[orbit_index],orbit_amount,pattern.turn_self);
        }else if(pattern.kind=="control_physics"){
            for(var physics_index=0;physics_index<array_length(pattern.entries);physics_index++) BattleEditor_RuntimeApplyPhysicsEntry(pattern.entries[physics_index],global.delta_time_factor);
        }else if(pattern.kind=="control_aim_motion"){
            var live_aim_point=BattleEditor_RuntimePointTarget(controller,pattern.target_uid);
            for(var aim_entry_index=0;aim_entry_index<array_length(pattern.entries);aim_entry_index++){
                var aim_entry=pattern.entries[aim_entry_index];
                var aim_target=aim_entry.target;
                var aim_target_alive=is_struct(aim_target)?!(variable_struct_exists(aim_target,"_destroyed")&&aim_target._destroyed):instance_exists(aim_target);
                if(!aim_target_alive) continue;
                if(pattern.continuous&&live_aim_point[0]) aim_entry.direction=point_direction(aim_target.x,aim_target.y,live_aim_point[1],live_aim_point[2]);
                if(pattern.face_target) BattleEditor_RuntimeSetAimFacing(aim_target,aim_entry.angle_property,aim_entry.direction);
                var aim_distance=abs(pattern.speed)*global.delta_time_factor;
                if(pattern.continuous&&pattern.speed>0&&live_aim_point[0]) aim_distance=min(aim_distance,point_distance(aim_target.x,aim_target.y,live_aim_point[1],live_aim_point[2]));
                var aim_move_direction=aim_entry.direction+(pattern.speed<0?180:0);
                aim_target.x+=lengthdir_x(aim_distance,aim_move_direction);
                aim_target.y+=lengthdir_y(aim_distance,aim_move_direction);
            }
        }else if(pattern.kind=="generated_physics"){
            var physics_follow_delta=BattleEditor_RuntimeBuiltinFollowDelta(pattern);
            if(physics_follow_delta.active) for(var physics_follow_index=0;physics_follow_index<array_length(pattern.entries);physics_follow_index++){
                var physics_follow_entry=pattern.entries[physics_follow_index];
                if(instance_exists(physics_follow_entry.target)) BattleEditor_RuntimeApplyBuiltinFollowDelta(physics_follow_entry.target,physics_follow_entry.target.editor_target_type,physics_follow_delta,false);
                var physics_follow_velocity=RotateAround(0,0,physics_follow_entry.vx,physics_follow_entry.vy,0,0,physics_follow_delta.angle);
                physics_follow_entry.vx=physics_follow_velocity[0];physics_follow_entry.vy=physics_follow_velocity[1];
            }
            var physics_shift_x=pattern.anchor.x-pattern.anchor_last_x;
            var physics_shift_y=pattern.anchor.y-pattern.anchor_last_y;
            if(physics_shift_x!=0||physics_shift_y!=0){
                for(var physics_shift_index=0;physics_shift_index<array_length(pattern.entries);physics_shift_index++) if(instance_exists(pattern.entries[physics_shift_index].target)){
                    pattern.entries[physics_shift_index].target.x+=physics_shift_x;
                    pattern.entries[physics_shift_index].target.y+=physics_shift_y;
                }
                pattern.anchor_last_x=pattern.anchor.x;pattern.anchor_last_y=pattern.anchor.y;
            }
            for(var generated_physics_index=0;generated_physics_index<array_length(pattern.entries);generated_physics_index++) BattleEditor_RuntimeApplyGeneratedPhysicsEntry(pattern.entries[generated_physics_index],global.delta_time_factor);
        }else if(pattern.kind=="bone_function_path"){
            if(array_length(pattern.entries)>0){
                pattern.base_x=pattern.anchor.x;pattern.base_y=pattern.anchor.y;
                var curve_progress=clamp(pattern.age/max(1,pattern.duration),0,1);
                var curve_parameter=lerp(pattern.t0,pattern.t1,curve_progress);
                var curve_variables=BattleEditor_ExpressionVariables(controller);
                var curve_xy=BattleEditor_RuntimeFunctionPathPoint(controller,pattern,curve_parameter,curve_progress,curve_variables);
                var curve_angle=pattern.fixed_angle;
                if(pattern.follow_tangent){
                    var tangent_progress=curve_progress<1?min(1,curve_progress+1/max(1,pattern.duration)):max(0,curve_progress-1/max(1,pattern.duration));
                    var tangent_t=lerp(pattern.t0,pattern.t1,tangent_progress);
                    var tangent_position=BattleEditor_RuntimeFunctionPathPoint(controller,pattern,tangent_t,tangent_progress,curve_variables);
                    curve_angle=curve_progress<1?point_direction(curve_xy[0],curve_xy[1],tangent_position[0],tangent_position[1]):point_direction(tangent_position[0],tangent_position[1],curve_xy[0],curve_xy[1]);
                }
                for(var curve_entry_index=0;curve_entry_index<array_length(pattern.entries);curve_entry_index++){
                    var curve_entry=pattern.entries[curve_entry_index];
                    BattleEditor_RuntimePatternSetFollowPose(pattern,curve_entry.target,curve_entry.target_type,curve_xy[0]+curve_entry.offset_x,curve_xy[1]+curve_entry.offset_y,curve_angle);
                }
            }
        }else if(pattern.kind=="gb_pinwheel_sequence"){
            var pinwheel_follow_delta=BattleEditor_RuntimeBuiltinFollowDelta(pattern);
            if(pinwheel_follow_delta.active) for(var pinwheel_follow_index=0;pinwheel_follow_index<array_length(pattern.members);pinwheel_follow_index++){
                BattleEditor_RuntimeApplyBuiltinFollowDelta(pattern.members[pinwheel_follow_index],"gb",pinwheel_follow_delta,true);
            }
            pattern.cx=pattern.anchor.x;pattern.cy=pattern.anchor.y;
            while(pattern.next_index<pattern.count&&pattern.next_index*pattern.generation_interval<=pattern.age){
                BattleEditor_RuntimeSpawnPinwheelMember(controller,pattern,pattern.next_index);
                pattern.next_index+=1;
            }
        }else if(pattern.kind=="camera_tween"){
            var t=clamp(pattern.age/max(1,pattern.duration),0,1),eased=Anim_GetValue(pattern.tween,pattern.ease,t);
            camera.editor_center_enabled=true;camera.editor_center_x=lerp(pattern.x0,pattern.x1,eased);camera.editor_center_y=lerp(pattern.y0,pattern.y1,eased);camera.scale_x=lerp(pattern.sx0,pattern.sx1,eased);camera.scale_y=lerp(pattern.sy0,pattern.sy1,eased);camera.angle=lerp(pattern.a0,pattern.a1,eased);
        }else if(pattern.kind=="board_shape_morph"){
            var morph_board=pattern.target;
            if(!is_struct(morph_board)||morph_board._destroyed) done=true;
            else{
                if(done) morph_board.listVertex=BattleEditor_RuntimeCopyBoardPoints(pattern.target_points);
                else{
                    var morph_t=clamp(pattern.age/max(1,pattern.duration),0,1);
                    var morph_amount=Anim_GetValue(pattern.tween,pattern.ease,morph_t);
                    for(var morph_index=0;morph_index<array_length(pattern.start_points);morph_index++){
                        // Topology is normalized before the morph starts, so
                        // mutate the existing point arrays instead of creating
                        // 32 new arrays plus a new vertex list every frame.
                        morph_board.listVertex[morph_index][0]=lerp(pattern.start_points[morph_index][0],pattern.target_points[morph_index][0],morph_amount);
                        morph_board.listVertex[morph_index][1]=lerp(pattern.start_points[morph_index][1],pattern.target_points[morph_index][1],morph_amount);
                    }
                }
                BattleEditor_RuntimeUpdateConvexMorphGeometry(morph_board);
                if(done){
                    morph_board.editor_shape=pattern.target_shape;
                    morph_board.editor_morphing=false;
                    if(pattern.target_shape=="triangle") morph_board.editor_triangle_size=pattern.target_triangle_size;
                }
            }
        }else if(pattern.kind=="camera_sine"){
            var wave=sin(degtorad(pattern.age*pattern.speed));camera.editor_center_enabled=true;camera.editor_center_x=pattern.base_x+wave*pattern.amp_x;camera.editor_center_y=pattern.base_y+wave*pattern.amp_y;camera.angle=pattern.base_angle+wave*pattern.amp_angle;
            if(done){camera.editor_center_x=pattern.base_x;camera.editor_center_y=pattern.base_y;camera.angle=pattern.base_angle;}
        }
        if(pattern.kind=="lifetime_members"&&struct_exists(pattern,"controller_kind")&&pattern.controller_kind=="bone_corridor"
        &&pattern.next_index<pattern.count&&pattern.age+0.0001>=pattern.next_index*pattern.spawn_interval){
            // A long corridor is repeated pair generation. Even when a very
            // small interval falls behind the render clock, create at most the
            // next pair in this Step instead of turning it back into a burst.
            BattleEditor_RuntimeSpawnCorridorPair(controller,pattern,pattern.next_index);
            pattern.next_index+=1;
        }
        if(pattern.kind=="lifetime_members"&&struct_exists(pattern,"controller_kind")&&pattern.controller_kind=="bone_corridor"){
            var corridor_spawned_limit=min(array_length(pattern.members),pattern.next_index*2);
            // Corridor members are generated in travel order. Retire only the
            // completed prefix, so normal frames do not rescan all 128 pairs.
            while(pattern.retire_index<corridor_spawned_limit){
                var corridor_retire_member=pattern.members[pattern.retire_index];
                if(instance_exists(corridor_retire_member)){
                    if(!BattleEditor_RuntimeCorridorMemberPastViewport(corridor_retire_member)) break;
                    instance_destroy(corridor_retire_member);
                }
                pattern.retire_index+=1;
            }
        }
        if(pattern.kind=="lifetime_members"&&struct_exists(pattern,"controller_kind")&&pattern.controller_kind=="bone_corridor"
        &&struct_exists(pattern,"corridor_auto")&&pattern.corridor_auto){
            var corridor_any_visible=false;
            var corridor_visibility_limit=min(array_length(pattern.members),pattern.next_index*2);
            for(var corridor_visibility_index=pattern.retire_index;corridor_visibility_index<corridor_visibility_limit;corridor_visibility_index++){
                if(BattleEditor_RuntimeCorridorMemberVisible(pattern.members[corridor_visibility_index],pattern.layer_mode)){
                    corridor_any_visible=true;
                    break;
                }
            }
            if(corridor_any_visible) pattern.corridor_seen_visible=true;
            // Once the corridor has appeared, its actual current visibility is
            // the sole finish condition. The static estimate is only a fallback
            // for a corridor that starts outside and moves farther away.
            done=pattern.next_index>=pattern.count&&!corridor_any_visible&&(pattern.corridor_seen_visible||pattern.age>=pattern.duration);
        }
        if(done){
            var keep_pattern_objects=struct_exists(pattern,"keep_objects")&&pattern.keep_objects;
            if(!keep_pattern_objects&&(pattern.kind=="bone_orbit"||pattern.kind=="bone_wave"||pattern.kind=="bone_wall")) for(var i=0;i<array_length(pattern.bones);i++) if(instance_exists(pattern.bones[i])) instance_destroy(pattern.bones[i]);
            if(!keep_pattern_objects&&pattern.kind=="lifetime_members") for(var member_index=0;member_index<array_length(pattern.members);member_index++) if(instance_exists(pattern.members[member_index])) instance_destroy(pattern.members[member_index]);
            if(!keep_pattern_objects&&pattern.kind=="generated_physics") for(var generated_member_index=0;generated_member_index<array_length(pattern.entries);generated_member_index++) if(instance_exists(pattern.entries[generated_member_index].target)) instance_destroy(pattern.entries[generated_member_index].target);
            if(!keep_pattern_objects&&pattern.kind=="bone_function_path"&&pattern.owns_members) for(var path_member_index=0;path_member_index<array_length(pattern.entries);path_member_index++) if(instance_exists(pattern.entries[path_member_index].target)) instance_destroy(pattern.entries[path_member_index].target);
            array_delete(controller.script_patterns,pattern_index,1);
        }
    }
}

/// Return whether the runtime path actually consumes the control step's
/// duration. Several system/discrete controls bypass Anim_Create and apply in
/// the same frame; counting their editor default of 60 fabricated whole extra
/// seconds in the automatic timeline.
function BattleEditor_ControlStepUsesDuration(step) {
    if(!is_struct(step)||step.kind!="control_object") return false;
    // This is deliberately a transition-capability allow-list. Configuration
    // values such as damage, velocity, lifetime, follow mode, GB timings and
    // attack behaviour are assignments completed on the current frame; their
    // legacy default duration must not create an invisible 60-frame action or
    // inflate "wait for previous completion". Only values whose runtime path
    // genuinely interpolates/moves over time appear here.
    switch(step.property){
        case "position":case "orbit":case "physics":case "aim_motion":
        case "scale_x":case "scale_y":case "alpha":case "visual_color":
        case "length":case "control_vertex":
        case "shape":case "width":case "height":case "radius_x":case "radius_y":case "triangle_size":
        case "up":case "down":case "left":case "right":case "color_frame":
        case "orbit_radius_x":case "orbit_radius_y":case "pattern_span":case "pattern_amplitude":case "pattern_speed":case "wall_extent":
        case "angle_x":case "angle_y":case "angle_z":case "angle_xw":case "angle_yw":case "angle_zw":
        case "size_x":case "size_y":case "size_z":case "size_w":
        case "world_z":case "perspective_distance":case "perspective4d_distance":case "edge_trim":
            return true;
    }
    return false;
}

function BattleEditor_ScriptStepDurationHint(controller,step) {
    if(is_undefined(step)||!is_struct(step)) return 0;
    if(step.kind=="wait") return struct_exists(step,"wait_mode")&&round(real(step.wait_mode))==1?0:max(0,step.duration);
    if(step.kind=="control_object"){
        var control_duration=BattleEditor_ControlStepUsesDuration(step)?max(0,step.duration):0;
        var control_move=step.property=="position"||step.property=="orbit"||step.property=="physics"||step.property=="aim_motion";
        if(control_move&&step.warning_enabled) control_duration+=max(0,step.warning_duration);
        return control_duration;
    }
    if(step.kind=="create_object"){
        var create_lifetime_source=step.create_lifetime;
        if(step.create_preset!="board_add"&&step.create_preset!="board_subtract"){
            var create_hint_template=BattleEditor_WorkspaceCreateNormalizeTemplate(step);
            if(struct_exists(create_hint_template,"duration")) create_lifetime_source=create_hint_template.duration;
        }
        var create_lifetime_hint=BattleEditor_RuntimeNumber(controller,create_lifetime_source,-1);
        if(create_lifetime_hint>=0) return create_lifetime_hint;
        if(step.create_preset=="gb") return 150;
        if(step.create_preset=="true_knife") return 30;
        if(step.create_preset=="slash") return 130;
        return 0;
    }
    if(step.kind=="builtin_action"){
        var p=BattleEditor_ActionParts(step.action_arguments);
        switch(step.action_name){
            case "bone_orbit":
                var orbit_hold_hint=BattleEditor_ActionNumber(controller,p,10,120);
                return abs(BattleEditor_ActionNumber(controller,p,9,20))+max(0,orbit_hold_hint)+(orbit_hold_hint<0?0:abs(BattleEditor_ActionNumber(controller,p,11,20)));
            case "bone_wave":return max(0,BattleEditor_ActionNumber(controller,p,8,180));
            case "bone_corridor":
                var corridor_lifetime=BattleEditor_ActionNumber(controller,p,11,260);
                var corridor_axis=round(BattleEditor_ActionNumber(controller,p,0,0));
                var corridor_count=max(1,round(BattleEditor_ActionNumber(controller,p,3,12)));
                var corridor_spacing=BattleEditor_ActionNumber(controller,p,4,60);
                var corridor_speed=BattleEditor_ActionNumber(controller,p,10,3);
                var corridor_interval=abs(corridor_speed)>0.0001?abs(corridor_spacing/corridor_speed):1;
                var corridor_generation=max(0,(corridor_count-1)*corridor_interval);
                if(corridor_lifetime>=0) return corridor_generation+max(0,corridor_lifetime);
                return corridor_generation+BattleEditor_CorridorAutomaticDuration(
                    controller,
                    corridor_axis,
                    BattleEditor_ActionNumber(controller,p,1,-40),
                    BattleEditor_ActionNumber(controller,p,2,240),
                    1,
                    0,
                    corridor_speed,
                    BattleEditor_ActionNumber(controller,p,13,0),
                    5
                );
            case "bone_physics":return max(0,BattleEditor_ActionNumber(controller,p,11,180));
            case "bone_3d":return max(0,BattleEditor_ActionNumber(controller,p,14,180));
            case "bone_4d":return max(0,BattleEditor_ActionNumber(controller,p,19,180));
            case "bone_function_path":return max(0,BattleEditor_ActionNumber(controller,p,6,180));
            case "gb_pinwheel":
                var pinwheel_count=max(1,round(BattleEditor_ActionNumber(controller,p,4,8)));
                var pinwheel_generation_end=(pinwheel_count-1)*max(0,BattleEditor_ActionNumber(controller,p,8,0));
                var pinwheel_fire_offset=(pinwheel_count-1)*max(0,BattleEditor_ActionNumber(controller,p,9,0));
                var pinwheel_schedule_shift=max(0,pinwheel_generation_end-pinwheel_fire_offset);
                return max(0,BattleEditor_ActionNumber(controller,p,12,35))+max(0,BattleEditor_ActionNumber(controller,p,10,35))+pinwheel_schedule_shift+pinwheel_fire_offset+max(0,BattleEditor_ActionNumber(controller,p,11,50))+90;
            case "bone_wall":
                var wall_height=max(1,BattleEditor_ActionNumber(controller,p,4,70));
                var wall_speed=max(0.001,abs(BattleEditor_ActionNumber(controller,p,6,7)));
                var wall_hold_hint=BattleEditor_ActionNumber(controller,p,7,90);
                return (step.warning_enabled?max(0,step.warning_duration):0)+wall_height/wall_speed*(wall_hold_hint<0?1:2)+max(0,wall_hold_hint);
            // Zero is a valid instant contour replacement; do not fabricate a
            // two-frame operation merely because the same function can tween.
            case "board_shape":return max(0,abs(BattleEditor_ActionNumber(controller,p,1,30)));
        }
    }
    if(step.kind=="screen_control"){
        var p=BattleEditor_ActionParts(step.screen_arguments);
        if(step.screen_action=="camera_set") return max(0,BattleEditor_ActionNumber(controller,p,5,30));
        if(step.screen_action=="camera_sine") return max(0,BattleEditor_ActionNumber(controller,p,4,120));
    }
    return 0;
}

function BattleEditor_RuntimePlayNamedSound(sound_name) {
    sound_name=string_trim(string(sound_name));
    var sound_asset=BattleEditor_ResolveSoundAsset(sound_name);
    if(!audio_exists(sound_asset)) return false;
    BattleEditor_RuntimePlaySound(sound_asset,0,false);
    return true;
}

function BattleEditor_RuntimeSetEnemyAppearance(controller,step) {
    var resource=BattleEditor_FindEnemyTextureResource(controller.project,step.enemy_resource_uid);
    if(is_undefined(resource)||resource.enemy_uid!=step.enemy_uid) return false;
    var changed=false;
    for(var host_index=0;host_index<instance_number(battle_enemy_test);host_index++){
        var host=instance_find(battle_enemy_test,host_index);
        if(instance_exists(host)&&variable_instance_exists(host,"_set_editor_enemy_part")&&is_callable(host._set_editor_enemy_part)){
            changed=host._set_editor_enemy_part(step.enemy_uid,step.enemy_part_key,resource)||changed;
        }
    }
    return changed;
}

function BattleEditor_RuntimeStepSoundEnabled(step) {
    return is_struct(step)&&step.kind!="play_sound"
        &&struct_exists(step,"step_sound_enabled")&&step.step_sound_enabled
        &&struct_exists(step,"sound_name")&&string_length(string_trim(string(step.sound_name)))>0;
}

function BattleEditor_RuntimeStepSoundBegin(controller,step) {
    if(!BattleEditor_RuntimeStepSoundEnabled(step)||round(real(step.sound_timing))!=0) return false;
    return BattleEditor_RuntimePlayNamedSound(step.sound_name);
}

/// End sounds follow the public duration of the action without blocking the
/// next list item. A Wait has already elapsed when it reaches this function;
/// instantaneous actions play immediately after their own operation.
function BattleEditor_RuntimeStepSoundFinish(controller,step,duration_already_elapsed=false) {
    if(!BattleEditor_RuntimeStepSoundEnabled(step)||round(real(step.sound_timing))!=1) return false;
    var sound_delay=duration_already_elapsed?0:BattleEditor_ScriptStepDurationHint(controller,step);
    if(sound_delay<=0) return BattleEditor_RuntimePlayNamedSound(step.sound_name);
    array_push(controller.script_scheduled_sounds,{time:controller.playhead+sound_delay,sound_name:step.sound_name});
    return true;
}

function BattleEditor_RuntimeScheduledSoundStep(controller) {
    for(var sound_index=array_length(controller.script_scheduled_sounds)-1;sound_index>=0;sound_index--){
        var scheduled_sound=controller.script_scheduled_sounds[sound_index];
        if(controller.playhead<scheduled_sound.time) continue;
        BattleEditor_RuntimePlayNamedSound(scheduled_sound.sound_name);
        array_delete(controller.script_scheduled_sounds,sound_index,1);
    }
}

function BattleEditor_RuntimePreviousStepDuration(controller,list_data,step_index) {
    var longest_duration=0;
    for(var previous_index=step_index-1;previous_index>=0;previous_index--){
        var previous_step=list_data.steps[previous_index];
        if(struct_exists(previous_step,"enabled")&&!previous_step.enabled) continue;
        // Everything since the preceding Wait began on the same list cursor.
        // "Wait for previous completion" therefore waits for the longest item
        // in that parallel block, not merely the adjacent row.
        if(previous_step.kind=="wait") break;
        // A node connection transfers control context but is not itself an
        // action. Waiting after it still refers to the preceding real action.
        if(previous_step.kind!="start_list"&&previous_step.kind!="repeat") longest_duration=max(longest_duration,max(0,BattleEditor_ScriptStepDurationHint(controller,previous_step)));
    }
    return longest_duration;
}

function BattleEditor_RuntimeScriptStep(controller) {
    BattleEditor_RuntimeScheduledSoundStep(controller);
    var state_count=array_length(controller.script_runtime_states);
    // A node connection may intentionally point back to its own list head.
    // Newly started lists are processed on the next frame, never recursively
    // in the same call, so finite repeat ranges need no artificial per-frame
    // throttle. Instantaneous rows therefore really are simultaneous.
    controller.script_budget_hit=false;
    for(var state_index=state_count-1;state_index>=0;state_index--){
        if(state_index>=array_length(controller.script_runtime_states)) continue;
        var state=controller.script_runtime_states[state_index];
        var list_data=BattleEditor_FindScriptList(controller.project,state.list_uid);
        if(is_undefined(list_data)||!BattleEditor_WorkspaceHasHeader(list_data)){array_delete(controller.script_runtime_states,state_index,1);continue;}
        if(!struct_exists(state,"loops")||!is_array(state.loops)) state.loops=[];
        if(!struct_exists(state,"dialogue_waiters")||!is_array(state.dialogue_waiters)) state.dialogue_waiters=[];
        if(!struct_exists(state,"inherited_previous_end")) state.inherited_previous_end=-1;
        if(state.index>=array_length(list_data.steps)&&array_length(state.loops)<=0){array_delete(controller.script_runtime_states,state_index,1);continue;}
        while(true){
            // Blocking speech waits for every matching bubble to close. The
            // bubble keeps the original controls: X accelerates and Z confirms.
            for(var dialogue_waiter_index=array_length(state.dialogue_waiters)-1;dialogue_waiter_index>=0;dialogue_waiter_index--){
                if(!instance_exists(state.dialogue_waiters[dialogue_waiter_index])) array_delete(state.dialogue_waiters,dialogue_waiter_index,1);
            }
            if(array_length(state.dialogue_waiters)>0) break;
            // A repeat block owns the following N list items. Reaching its end
            // jumps back without recursion. It pauses only for a real Wait in
            // the range or the Repeat item's own per-iteration interval.
            if(array_length(state.loops)>0){
                var loop_top=state.loops[array_length(state.loops)-1];
                if(state.index>=loop_top.end_index){
                    if(struct_exists(loop_top,"resume_at")&&loop_top.resume_at>=0){
                        if(controller.playhead+0.0001<loop_top.resume_at) break;
                        loop_top.resume_at=-1;
                        state.index=loop_top.start_index;
                    }else if(loop_top.remaining>1){
                        loop_top.remaining-=1;
                        if(loop_top.interval>0){loop_top.resume_at=controller.playhead+loop_top.interval;break;}
                        state.index=loop_top.start_index;
                    }
                    else array_delete(state.loops,array_length(state.loops)-1,1);
                    continue;
                }
            }
            if(state.index>=array_length(list_data.steps)) break;
            var step=list_data.steps[state.index];
            if(!step.enabled){state.index+=1;continue;}
            var sound_step_index=state.index;
            var sound_step_started=step.kind!="wait"||state.wait_until<0;
            if(sound_step_started) BattleEditor_RuntimeStepSoundBegin(controller,step);
            var runtime_step_end=controller.playhead;
            if(step.kind=="wait"){
                if(state.wait_until<0){
                    var waits_for_previous=struct_exists(step,"wait_mode")&&round(real(step.wait_mode))==1;
                    var wait_extra=waits_for_previous&&struct_exists(step,"wait_extra_duration")?max(0,real(step.wait_extra_duration)):0;
                    if(waits_for_previous){
                        var local_previous_end=controller.playhead+BattleEditor_RuntimePreviousStepDuration(controller,list_data,state.index);
                        var wait_inherited_end=max(controller.playhead,state.inherited_previous_end);
                        state.wait_until=max(local_previous_end,wait_inherited_end)+wait_extra;
                    }else state.wait_until=controller.playhead+max(0,step.duration);
                }
                runtime_step_end=state.wait_until;
                if(controller.playhead<state.wait_until) break;
                state.wait_until=-1;state.inherited_previous_end=-1;state.index+=1;
            }else if(step.kind=="start_list"){
                if(step.target_list_uid>=0){
                    var local_previous_duration=BattleEditor_RuntimePreviousStepDuration(controller,list_data,state.index);
                    var link_inherited_end=max(controller.playhead,state.inherited_previous_end);
                    var connected_previous_end=max(controller.playhead+local_previous_duration,link_inherited_end);
                    BattleEditor_StartScriptList(controller,step.target_list_uid,connected_previous_end,struct_exists(state,"ancestry")?state.ancestry:[state.list_uid]);
                }
                state.index+=1;
            }else if(step.kind=="builtin_action"){
                BattleEditor_ExecuteBuiltinAction(controller,step);
                state.index+=1;
            }else if(step.kind=="create_object"){
                BattleEditor_ExecuteCreateObject(controller,step);
                state.index+=1;
            }else if(step.kind=="screen_control"){
                BattleEditor_ExecuteScreenAction(controller,step);
                state.index+=1;
            }else if(step.kind=="play_sound"){
                if(round(real(step.sound_timing))==1&&state.wait_until<0){
                    var previous_step=state.index>0?list_data.steps[state.index-1]:undefined;
                    var sound_delay=BattleEditor_ScriptStepDurationHint(controller,previous_step);
                    if(sound_delay>0){state.wait_until=controller.playhead+sound_delay;break;}
                }
                if(state.wait_until>=0&&controller.playhead<state.wait_until) break;
                state.wait_until=-1;
                BattleEditor_RuntimePlayNamedSound(step.sound_name);
                state.index+=1;
            }else if(step.kind=="enemy_appearance"){
                BattleEditor_RuntimeSetEnemyAppearance(controller,step);
                state.index+=1;
            }else if(step.kind=="run_script"){
                // Legacy project data is deliberately inert. Runtime GML asset
                // lookup was an unsafe escape hatch and is not a built-in API.
                state.index+=1;
            }else if(step.kind=="set_variable"){
                BattleEditor_RuntimeSetVariable(controller,step);
                state.index+=1;
            }else if(step.kind=="get_value"){
                BattleEditor_RuntimeGetValue(controller,step);
                state.index+=1;
            }else if(step.kind=="condition"){
                if(BattleEditor_RuntimeCondition(controller,step)) state.index+=1;
                else state.index+=1+max(0,round(BattleEditor_RuntimeNumber(controller,step.skip_count,1)));
            }else if(step.kind=="repeat"){
                var repeat_amount=max(0,round(BattleEditor_RuntimeNumber(controller,step.repeat_count,0)));
                var repeat_length=max(0,round(BattleEditor_RuntimeNumber(controller,step.repeat_length,0)));
                var repeat_interval=struct_exists(step,"repeat_interval")?max(0,BattleEditor_RuntimeNumber(controller,step.repeat_interval,0)):0;
                var repeat_start=state.index+1;
                var repeat_end=min(array_length(list_data.steps),repeat_start+repeat_length);
                if(repeat_amount>0&&repeat_end>repeat_start){array_push(state.loops,{start_index:repeat_start,end_index:repeat_end,remaining:repeat_amount,interval:repeat_interval,resume_at:-1});state.index=repeat_start;}
                else state.index=repeat_end;
            }else{
                var blocks_for_speech=step.kind=="control_object"&&step.target_type=="enemy"&&step.property=="speak"&&step.dialogue_block_battle;
                BattleEditor_RuntimeControlObject(controller,step);
                state.index+=1;
                if(blocks_for_speech&&variable_instance_exists(controller,"last_enemy_speech_bubbles")&&array_length(controller.last_enemy_speech_bubbles)>0){
                    state.dialogue_waiters=array_create(array_length(controller.last_enemy_speech_bubbles),noone);
                    array_copy(state.dialogue_waiters,0,controller.last_enemy_speech_bubbles,0,array_length(controller.last_enemy_speech_bubbles));
                }
            }
            if(step.kind!="wait"&&step.kind!="repeat"){
                runtime_step_end=controller.playhead+max(0,BattleEditor_ScriptStepDurationHint(controller,step));
            }
            if(state.index!=sound_step_index) BattleEditor_RuntimeStepSoundFinish(controller,step,step.kind=="wait");
            if(array_length(state.dialogue_waiters)>0) break;
        }
        if(state.index>=array_length(list_data.steps)&&array_length(state.loops)<=0) array_delete(controller.script_runtime_states,state_index,1);
    }
    controller.script_budget_hit=false;
}

function BattleEditor_PointInRect(px, py, x1, y1, x2, y2) {
    return px >= x1 && px <= x2 && py >= y1 && py <= y2;
}

/// Hit-tests the complete rectangle actually drawn by draw_sprite_ext,
/// including transparent sprite margins. This makes the visible asset itself
/// the drag handle instead of requiring a click near an invisible centre.
function BattleEditor_SpriteHit(sprite_id,x,y,scale_x,scale_y,angle,px,py,min_size=12,padding=3) {
    if(!sprite_exists(sprite_id)) return point_distance(px,py,x,y)<=max(min_size,padding);
    var safe_scale_x=abs(scale_x)<0.0001?(scale_x<0?-0.0001:0.0001):scale_x;
    var safe_scale_y=abs(scale_y)<0.0001?(scale_y<0?-0.0001:0.0001):scale_y;
    var local_point=RotateAround(x,y,px,py,x,y,-angle);
    var local_x=(local_point[0]-x)/safe_scale_x+sprite_get_xoffset(sprite_id);
    var local_y=(local_point[1]-y)/safe_scale_y+sprite_get_yoffset(sprite_id);
    var world_width=sprite_get_width(sprite_id)*abs(safe_scale_x);
    var world_height=sprite_get_height(sprite_id)*abs(safe_scale_y);
    var local_padding_x=max(padding,(min_size-world_width)*0.5)/abs(safe_scale_x);
    var local_padding_y=max(padding,(min_size-world_height)*0.5)/abs(safe_scale_y);
    return local_x>=-local_padding_x&&local_x<=sprite_get_width(sprite_id)+local_padding_x
        &&local_y>=-local_padding_y&&local_y<=sprite_get_height(sprite_id)+local_padding_y;
}

function BattleEditor_EventHit(event_data, px, py, project=undefined, main_preview=undefined, controller=undefined) {
    var track=event_data.transform;
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(event_data.preset=="bone_3d"||event_data.preset=="bone_4d")){
        return point_distance(px,py,track.x,track.y)<=max(18,max(abs(event_data.size_x),abs(event_data.size_y))+abs(event_data.size_z)*0.35);
    }
    if (event_data.kind == BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="gb") {
        // A GB is authored at its destination. Its generated position belongs
        // to initialization/preset data and is intentionally not a scene gizmo.
        var gb_hit_x=struct_exists(event_data,"target_x")?event_data.target_x:track.x;
        var gb_hit_y=struct_exists(event_data,"target_y")?event_data.target_y:track.y;
        var gb_hit_sprite=(!is_undefined(controller)&&!is_undefined(project))?BattleEditor_GBStylePreviewSprite(controller,project,event_data.gb_style_uid):spr_gb;
        var gb_hit_style=is_undefined(project)?undefined:BattleEditor_GBStyleDefinition(project,event_data.gb_style_uid);
        var gb_hit_angle=event_data.angle_target-(is_undefined(gb_hit_style)?0:gb_hit_style.source_direction);
        return BattleEditor_SpriteHit(gb_hit_sprite,gb_hit_x,gb_hit_y,track.scale_x*2,track.scale_y*2,gb_hit_angle,px,py,16,4);
    }
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&(event_data.preset=="slash"||event_data.preset=="true_knife")){
        var wave_dx=px-track.x;
        var wave_dy=py-track.y;
        var wave_along=wave_dx*dcos(track.angle)-wave_dy*dsin(track.angle);
        // GameMaker's direction vector is (cos(a), -sin(a)); its perpendicular
        // is therefore (sin(a), cos(a)).  Using (-sin, cos) only worked for
        // horizontal/vertical strips and missed rotated True Knives.
        var wave_perpendicular=abs(wave_dx*dsin(track.angle)+wave_dy*dcos(track.angle));
        // The complete strip shown in the scene is the drag handle. It is not
        // represented by a tiny hidden centre point.
        return abs(wave_along)<=900&&wave_perpendicular<=max(12,event_data.visual_max_width*0.6);
    }
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.TYPEWRITER){
        var text_scale_x=abs(track.scale_x)<0.0001?0.0001:track.scale_x;
        var text_scale_y=abs(track.scale_y)<0.0001?0.0001:track.scale_y;
        var typewriter_local=RotateAround(track.x,track.y,px,py,track.x,track.y,-track.angle);
        var typewriter_x=(typewriter_local[0]-track.x)/text_scale_x;
        var typewriter_y=(typewriter_local[1]-track.y)/text_scale_y;
        var preview_width=max(28,TextTyper_StringWidthFallback(TextTyper_MarkupPlain(event_data.text)));
        return typewriter_x>=-4&&typewriter_x<=preview_width+4&&typewriter_y>=-4&&typewriter_y<=24;
    }
    if(event_data.kind==BATTLE_EDITOR_OBJECT_KIND.MECHANIC_HAZARD&&event_data.preset=="platform"){
        var platform_sprite=event_data.sticky?spr_battle_platform_green:spr_battle_platform_purple;
        return BattleEditor_SpriteHit(platform_sprite,track.x,track.y,max(4,event_data.width)/sprite_get_width(platform_sprite),1,track.angle,px,py,12,3);
    }
    if(event_data.kind == BATTLE_EDITOR_OBJECT_KIND.DECORATION||event_data.preset!="bone"){
        var event_sprite=struct_exists(event_data,"sprite_source")?asset_get_index(event_data.sprite_source):-1;
        if(sprite_exists(event_sprite)) return BattleEditor_SpriteHit(event_sprite,track.x,track.y,track.scale_x,track.scale_y,track.angle,px,py,14,3);
        return point_distance(px,py,track.x,track.y)<=24;
    }
    var hit_x=track.x,hit_y=track.y,hit_angle=track.angle;
    if(event_data.follow&&!is_undefined(project)){
        var followed_hit=BattleEditor_BoneWorldTransform(event_data,project,main_preview);
        hit_x=followed_hit.x;hit_y=followed_hit.y;hit_angle=followed_hit.angle;
    }
    return BattleEditor_SpriteHit(spr_bone,hit_x,hit_y,(event_data.length+10)/14,1,hit_angle,px,py,14,3);
}

function BattleEditor_FrameHit(frame, px, py) {
    var local_point=RotateAround(frame.x,frame.y,px,py,frame.x,frame.y,-frame.angle);
    var lx=local_point[0]-frame.x;
    var ly=local_point[1]-frame.y;
    if(frame.shape=="circle") return sqr(lx/max(1,frame.radius_x))+sqr(ly/max(1,frame.radius_y))<=1;
    if(frame.shape=="polygon"&&array_length(frame.vertices)>=3){
        var inside=false;
        for(var i=0,j=array_length(frame.vertices)-1;i<array_length(frame.vertices);j=i++){
            var a=frame.vertices[i],b=frame.vertices[j];
            var edge_dy=b[1]-a[1];
            if(abs(edge_dy)<0.00001) edge_dy=0.00001;
            if(((a[1]>ly)!=(b[1]>ly))&&(lx<(b[0]-a[0])*(ly-a[1])/edge_dy+a[0])) inside=!inside;
        }
        return inside;
    }
    return lx>=-frame.left&&lx<=frame.right&&ly>=-frame.up&&ly<=frame.down;
}

function BattleEditor_ColorForType(type) {
    switch (type) {
        case 1: return make_color_rgb(20,196,255);
        case 2: return make_color_rgb(248,148,29);
        case 3: return make_color_rgb(0,255,0);
        case 4: return c_yellow;
        case 5: return make_color_rgb(0,96,32);
        case 6: return c_red;
        case 7: return make_color_rgb(75,0,130);
        case 8: return make_color_rgb(20,32,160);
    }
    return c_white;
}

function BattleEditor_VisualColorModeName(mode) {
    switch(clamp(round(real(mode)),0,2)){
        case 0:return "跟随伤害机制";
        case 1:return "固定颜色模板";
        case 2:return "自由颜色";
    }
    return "跟随伤害机制";
}

function BattleEditor_VisualColorPresetName(type) {
    switch(clamp(round(real(type)),0,8)){
        case 1:return "电蓝色";
        case 2:return "橙色";
        case 3:return "亮绿色";
        case 4:return "黄色";
        case 5:return "深绿色";
        case 6:return "红色";
        case 7:return "紫色";
        case 8:return "深蓝色";
    }
    return "白色";
}

/// Display colour has three independent modes. Damage mechanics always remain
/// in damage_profile.type; choosing a visual preset never changes them.
function BattleEditor_SetVisualTintMode(event_data,mode) {
    if(!is_struct(event_data)||!struct_exists(event_data,"visual_tint")) return false;
    var tint=event_data.visual_tint;
    mode=clamp(round(real(mode)),0,2);
    if(!struct_exists(tint,"preset_type")) tint.preset_type=struct_exists(event_data,"damage_profile")?clamp(round(real(event_data.damage_profile.type)),0,8):0;
    if(!struct_exists(tint,"custom_color")) tint.custom_color=struct_exists(tint,"color")?tint.color:c_white;
    tint.mode=mode;
    tint.follow_damage_profile=mode==0;
    if(mode==0&&struct_exists(event_data,"damage_profile")) tint.color=BattleEditor_ColorForType(event_data.damage_profile.type);
    else if(mode==1) tint.color=BattleEditor_ColorForType(tint.preset_type);
    else tint.color=tint.custom_color;
    return true;
}

function BattleEditor_SetVisualTintPreset(event_data,preset_type) {
    if(!is_struct(event_data)||!struct_exists(event_data,"visual_tint")) return false;
    event_data.visual_tint.preset_type=clamp(round(real(preset_type)),0,8);
    return BattleEditor_SetVisualTintMode(event_data,1);
}

/// Configure what a future damage-palette edit does without collapsing the
/// independent follow / fixed-palette / custom visual modes into two states.
/// Disabling while currently following freezes the colour that is on screen.
function BattleEditor_SetDamageChangeVisual(event_data,enabled) {
    if(!is_struct(event_data)||!struct_exists(event_data,"damage_profile")) return false;
    enabled=real(enabled)!=0;
    if(!struct_exists(event_data.damage_profile,"change_visual")) event_data.damage_profile.change_visual=true;
    if(!enabled&&struct_exists(event_data,"visual_tint")){
        var tint=event_data.visual_tint;
        var current_color=clamp(round(real(tint.mode)),0,2)==0
            ?BattleEditor_ColorForType(event_data.damage_profile.type)
            :(struct_exists(tint,"color")?tint.color:c_white);
        tint.custom_color=current_color;
        tint.color=current_color;
        tint.mode=2;
        tint.follow_damage_profile=false;
    }
    event_data.damage_profile.change_visual=enabled;
    return true;
}

function BattleEditor_ApplyDamageTypeToEvent(event_data,damage_type) {
    if(!is_struct(event_data)||!struct_exists(event_data,"damage_profile")) return false;
    event_data.damage_profile.type=clamp(round(real(damage_type)),0,8);
    if(!struct_exists(event_data.damage_profile,"change_visual")) event_data.damage_profile.change_visual=true;
    if(event_data.damage_profile.change_visual&&struct_exists(event_data,"visual_tint")) BattleEditor_SetVisualTintMode(event_data,0);
    return true;
}

function BattleEditor_DamageTypeName(type) {
    switch(type){
        case 1: return "蓝色";
        case 2: return "橙色";
        case 3: return "亮绿色";
        case 4: return "黄色";
        case 5: return "深绿色";
        case 6: return "红色";
        case 7: return "紫色占用";
        case 8: return "深蓝·X防伤";
    }
    return "白色";
}

function BattleEditor_DamageValueName(type) {
    switch(round(real(type))){
        case 3:return "回血数值";
        case 7:return "每次紫色占用值";
        case 8:return "未按 X 时伤害";
    }
    return "伤害数值";
}

/// Default authored HP values follow ScratchUndertaleAnalysis/output.1/
/// all_scripts.md.  Bright green heals, dark green removes one point of the
/// current maximum, and pure red is the editor's explicit instant-kill rule.
function BattleEditor_DefaultDamageForType(type) {
    var profile=Player_AllScriptDamageProfile(type);
    if(profile.heal>0) return profile.heal;
    if(profile.max_hp>0) return profile.max_hp;
    if(profile.instant) return 1; // instant kill ignores the authored number
    return profile.hp;
}
