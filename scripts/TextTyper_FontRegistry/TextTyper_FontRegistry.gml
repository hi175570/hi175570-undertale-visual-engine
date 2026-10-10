/// Fonts 0..2 are the engine's established groups. The remaining fonts are
/// bundled from UT素材包/字体文件 and loaded only when selected.
function TextTyper_FontDefinitions() {
    return [
        {name:"对话 / Determination Mono",file:"",size:10,last:128,bold:true,cjk:false},
        {name:"菜单 / 游戏字体",file:"",size:10,last:65535,bold:false,cjk:true},
        {name:"Sans / 战斗字体",file:"",size:12,last:65535,bold:false,cjk:true},
        {name:"方正少儿简体",file:"方正少儿简体.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"方正卡通简体",file:"方正卡通简体.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"方正基础像素体",file:"方正基础像素体.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"方正像素12",file:"方正像素12.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"Comic Sans MS",file:"Comic Sans MS.ttf",size:12,last:255,bold:false,cjk:false},
        {name:"Determination Mono (素材包)",file:"Determination Mono.otf",size:10,last:255,bold:true,cjk:false},
        {name:"Hachicro",file:"Hachicro.ttf",size:12,last:255,bold:false,cjk:false},
        {name:"Mars Needs Cunnilingus",file:"Mars Needs Cunnilingus.ttf",size:18,last:255,bold:false,cjk:false},
        {name:"Monster Friend Back",file:"Monster Friend Back.otf",size:12,last:255,bold:false,cjk:false},
        {name:"Monster Friend Fore",file:"Monster Friend Fore.otf",size:12,last:255,bold:false,cjk:false},
        {name:"Papy Chinese",file:"papychinese.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"Papyrus",file:"Papyrus.ttf",size:12,last:255,bold:false,cjk:false},
        {name:"Sans Chinese",file:"sanschinese.ttf",size:12,last:65535,bold:false,cjk:true},
        {name:"Wingdings",file:"Wingdings.ttf",size:12,last:255,bold:false,cjk:false}
    ];
}

function TextTyper_FontCount() {
    return array_length(TextTyper_FontDefinitions());
}

function TextTyper_FontName(font_id) {
    var definitions=TextTyper_FontDefinitions();
    font_id=clamp(round(font_id),0,array_length(definitions)-1);
    return definitions[font_id].name;
}

function TextTyper_FontGet(font_id) {
    font_id=clamp(round(font_id),0,TextTyper_FontCount()-1);
    if(font_id==0) return font_determination_mono;
    if(font_id==1) return font_menu;
    if(font_id==2) return font_sans;
    if(!variable_global_exists("text_typer_dynamic_fonts")) global.text_typer_dynamic_fonts=array_create(TextTyper_FontCount(),-2);
    var cached=global.text_typer_dynamic_fonts[font_id];
    if(cached!=-2) return font_exists(cached)?cached:font_menu;
    var definition=TextTyper_FontDefinitions()[font_id];
    var source_path=working_directory+"editor_fonts/"+definition.file;
    var loaded=-1;
    if(file_exists(source_path)) loaded=font_add(source_path,definition.size,definition.bold,false,32,definition.last);
    global.text_typer_dynamic_fonts[font_id]=loaded;
    return font_exists(loaded)?loaded:font_menu;
}

function TextTyper_FontApplyGroups(typer) {
    if(!instance_exists(typer)) return false;
    var definitions=TextTyper_FontDefinitions();
    for(var font_index=3;font_index<array_length(definitions);font_index++){
        var asset=TextTyper_FontGet(font_index);
        typer._group_font[font_index]=[asset,asset];
        typer._group_font_scale_x[font_index]=[1,1];
        typer._group_font_scale_y[font_index]=[1,1];
        typer._group_font_space_x[font_index]=[0,0];
        typer._group_font_space_y[font_index]=0;
    }
    return true;
}

function TextTyper_FontEnsureGroup(typer,font_id) {
    if(!instance_exists(typer)) return false;
    font_id=clamp(round(font_id),0,TextTyper_FontCount()-1);
    if(font_id<=2) return true;
    var asset=TextTyper_FontGet(font_id);
    typer._group_font[font_id]=[asset,asset];
    typer._group_font_scale_x[font_id]=[1,1];
    typer._group_font_scale_y[font_id]=[1,1];
    typer._group_font_space_x[font_id]=[0,0];
    typer._group_font_space_y[font_id]=0;
    return true;
}

/// Returns a bundled fallback font. These fonts are deliberately not exposed
/// as normal style choices: they only supply a glyph which the chosen game
/// font does not contain.
function TextTyper_FallbackFontGet(fallback_kind) {
    // 0 = the game's own CJK font, 1 = Segoe UI Symbol,
    // 2 = Segoe UI Emoji. The Windows fonts are used directly so fallback
    // text looks like ordinary system text instead of another game font.
    if(fallback_kind==0) return font_exists(font_menu)?font_menu:-1;
    if(!variable_global_exists("text_typer_fallback_fonts")) global.text_typer_fallback_fonts=[-2,-2,-2];
    fallback_kind=clamp(round(fallback_kind),0,2);
    var cached=global.text_typer_fallback_fonts[fallback_kind];
    if(cached!=-2) return font_exists(cached)?cached:-1;

    // File fonts are loaded as complete faces by GameMaker (first/last are
    // ignored for TTF/OTF files). Keep one face alive and reuse it; creating a
    // new dynamic font for every glyph is both wasteful and unreliable for
    // supplementary-plane emoji.
    var source_path="";
    var source_is_system=false;
    // font_add officially accepts TTF/OTF Included Files, and on Windows it
    // also accepts an installed font family name. CJK never reaches this path:
    // the game's own Simplified-Chinese-capable font remains visually primary.
    if(fallback_kind==1){source_path="Segoe UI Symbol";source_is_system=os_type==os_windows;}
    else{
        // GameMaker's Windows font rasterizer does not reliably render the
        // colour-only tables in Segoe UI Emoji. The bundled monochrome Noto
        // outline font contains the same Unicode emoji as ordinary glyphs;
        // use Segoe only as a last-resort platform fallback.
        source_path=working_directory+"editor_fonts/NotoEmoji-Regular.ttf";
        if(!file_exists(source_path)) source_path=working_directory+"editor_fonts/NotoEmoji-VariableFont_wght.ttf";
        if(!file_exists(source_path)) source_path=working_directory+"editor_fonts/Segoe UI Emoji.ttf";
        if(!file_exists(source_path)) source_path="C:/Windows/Fonts/seguiemj.ttf";
    }
    var loaded=-1;
    if(source_is_system||file_exists(source_path)){
        // Build the ranges that are actually expected from each fallback.
        // A 32..255-only font followed by font_cache_glyph() produced tofu on
        // the Windows runner for arrows and supplementary-plane emoji.
        if(fallback_kind==0) loaded=font_add(source_path,12,false,false,32,65535);
        else if(fallback_kind==1) loaded=font_add(source_path,12,false,false,0x2190,0x2BFF);
        else loaded=font_add(source_path,12,false,false,32,65535);
    }
    // Non-Windows exports do not have the Microsoft font path. Keep the
    // bundled Chinese font as a portability fallback without preferring it on
    // this Windows editor build.
    if(!font_exists(loaded)&&fallback_kind==0){
        source_path=working_directory+"editor_fonts/sanschinese.ttf";
        if(file_exists(source_path)) loaded=font_add(source_path,12,false,false,32,255);
    }
    global.text_typer_fallback_fonts[fallback_kind]=loaded;
    return font_exists(loaded)?loaded:-1;
}

/// Load exactly one Unicode codepoint from the fallback face.  On the Windows
/// runner font_cache_glyph() can cache the face's replacement square instead
/// of rasterising a glyph outside the range originally passed to font_add().
/// A one-codepoint dynamic font makes the requested range explicit and is
/// cached for the rest of the process, so each missing character is loaded at
/// most once.
function TextTyper_FallbackGlyphFontGet(fallback_kind,code) {
    fallback_kind=clamp(round(fallback_kind),0,2);
    code=max(0,round(code));
    if(fallback_kind==0) return font_exists(font_menu)?font_menu:-1;
    if(!variable_global_exists("text_typer_fallback_glyph_fonts")) global.text_typer_fallback_glyph_fonts={};
    var cache_key=string(fallback_kind)+"_"+string(code);
    if(struct_exists(global.text_typer_fallback_glyph_fonts,cache_key)){
        var cached=global.text_typer_fallback_glyph_fonts[$ cache_key];
        return font_exists(cached)?cached:-1;
    }

    var source_path="";
    var source_is_system=false;
    if(fallback_kind==1){source_path="Segoe UI Symbol";source_is_system=os_type==os_windows;}
    else{
        source_path=working_directory+"editor_fonts/NotoEmoji-Regular.ttf";
        if(!file_exists(source_path)) source_path=working_directory+"editor_fonts/NotoEmoji-VariableFont_wght.ttf";
        if(!file_exists(source_path)) source_path="C:/Windows/Fonts/seguiemj.ttf";
    }
    if(!source_is_system&&!file_exists(source_path)&&fallback_kind==0) source_path=working_directory+"editor_fonts/sanschinese.ttf";

    var loaded=-1;
    if(source_is_system||file_exists(source_path)) loaded=font_add(source_path,12,false,false,code,code);
    global.text_typer_fallback_glyph_fonts[$ cache_key]=loaded;
    return font_exists(loaded)?loaded:-1;
}

function TextTyper_FontHasGlyph(font_asset,character) {
    if(!font_exists(font_asset)||character=="") return false;
    var code=string_ord_at(character,1);
    if(code<0) return false;
    var info=font_get_info(font_asset);
    if(is_struct(info)&&struct_exists(info,"glyphs")&&is_struct(info.glyphs)){
        if(struct_exists(info.glyphs,string(code))) return true;
        // Some runner builds expose single-character keys instead of numeric
        // strings, so accept both representations.
        if(struct_exists(info.glyphs,character)) return true;
        return false;
    }
    return code>=font_get_first(font_asset)&&code<=font_get_last(font_asset);
}

function TextTyper_IsCjkCode(code) {
    return (code>=0x2E80&&code<=0x9FFF)
        ||(code>=0xAC00&&code<=0xD7AF)
        ||(code>=0xF900&&code<=0xFAFF);
}

function TextTyper_IsSymbolCode(code) {
    // GameMaker may cache the preferred font's replacement-square as if it
    // were the requested glyph. Route arrows, geometric symbols and emoji to
    // the bundled Unicode font before that false-positive can happen.
    return code>=0x2190&&code<=0x2BFF;
}

function TextTyper_IsEmojiCode(code) {
    return code>=0x1F000&&code<=0x1FAFF;
}

/// Windows' direct text input can occasionally deliver a supplementary
/// Unicode character as two UTF-16 surrogate code points.  GameMaker's JSON
/// writer then preserves those two code points as CESU-8, so the colour-emoji
/// atlas never receives the real U+1xxxx character.  Recombine only valid
/// high/low pairs; all ordinary text and intentionally unpaired data pass
/// through unchanged.
function TextTyper_NormalizeSupplementaryUnicode(value) {
    var source=string(value);
    var result="";
    var index=1;
    var count=string_length(source);
    while(index<=count){
        var character=string_char_at(source,index);
        var code=string_ord_at(character,1);
        if(code>=0xD800&&code<=0xDBFF&&index<count){
            var low_character=string_char_at(source,index+1);
            var low_code=string_ord_at(low_character,1);
            if(low_code>=0xDC00&&low_code<=0xDFFF){
                result+=chr(0x10000+(code-0xD800)*0x400+(low_code-0xDC00));
                index+=2;
                continue;
            }
        }
        result+=character;
        index+=1;
    }
    return result;
}

/// The runner does not expose every compiled/dynamic glyph table in the same
/// shape.  Keep an explicit registry for fonts which are known to contain CJK
/// so their own Chinese art always wins before the Windows UI fallback.
function TextTyper_FontOwnsCjk(font_asset) {
    if(font_asset==font_menu||font_asset==font_sans) return true;
    if(!variable_global_exists("text_typer_dynamic_fonts")) return false;
    var definitions=TextTyper_FontDefinitions();
    for(var font_id=3;font_id<array_length(definitions);font_id++){
        if(!definitions[font_id].cjk) continue;
        if(global.text_typer_dynamic_fonts[font_id]==font_asset) return true;
    }
    return false;
}

/// Per-character font choice used by every text_typer instance. Ordinary
/// symbols deliberately stay in the selected game font: substituting Segoe or
/// Noto for arrows/geometric characters made the editor visually inconsistent
/// and still did not cover every symbol. Colour emoji are handled separately
/// by TextTyper_ColorEmojiIndex(); the only text-font fallback retained here is
/// the project's own CJK font when a user explicitly selects a Latin-only face.
function TextTyper_FontResolve(font_asset,character) {
    if(!variable_global_exists("text_typer_fallback_cache")) global.text_typer_fallback_cache={};
    var code=string_ord_at(character,1);
    var cache_key=string(font_asset)+"_"+string(code);
    if(struct_exists(global.text_typer_fallback_cache,cache_key)) return global.text_typer_fallback_cache[$ cache_key];
    // Every registered CJK-capable game font keeps its own Chinese appearance.
    // font_get_info() is not reliable enough on all runner builds to infer this
    // from a dynamically loaded font, hence the explicit registry above.
    if(TextTyper_IsCjkCode(code)&&TextTyper_FontOwnsCjk(font_asset)){
        global.text_typer_fallback_cache[$ cache_key]=font_asset;
        return font_asset;
    }
    // For a selected Latin-only font, CJK has one deterministic fallback:
    // the game's own CJK font. Do not replace Chinese with a Windows UI face:
    // this project already owns the intended Simplified-Chinese glyph art.
    if(TextTyper_IsCjkCode(code)){
        var cjk_fallback=TextTyper_FallbackFontGet(0);
        if(font_exists(cjk_fallback)){
            global.text_typer_fallback_cache[$ cache_key]=cjk_fallback;
            return cjk_fallback;
        }
    }
    // No generic Unicode fallback. Unsupported ordinary symbols remain visible
    // as the selected font's replacement glyph instead of silently changing
    // typeface or disappearing.
    var result=font_exists(font_asset)?font_asset:font_menu;
    global.text_typer_fallback_cache[$ cache_key]=result;
    return result;
}

/// Load the Android/Gboard-style colour emoji atlas generated from Google's
/// Noto Color Emoji. GameMaker stores four-byte Unicode correctly but its font
/// draw path ignores colour-font layers, so emoji use this one external sprite.
function TextTyper_ColorEmojiEnsure() {
    if(variable_global_exists("text_typer_color_emoji_ready")&&global.text_typer_color_emoji_ready){
        if(!variable_global_exists("text_typer_color_emoji_lookup")){
            global.text_typer_color_emoji_lookup={};
            for(var cached_index=0;cached_index<array_length(global.text_typer_color_emoji_codes);cached_index++) global.text_typer_color_emoji_lookup[$ "u_"+string(global.text_typer_color_emoji_codes[cached_index])]=cached_index;
        }
        return true;
    }
    if(variable_global_exists("text_typer_color_emoji_ready")) return false;
    global.text_typer_color_emoji_ready=false;
    global.text_typer_color_emoji_sprite=-1;
    global.text_typer_color_emoji_codes=[];
    global.text_typer_color_emoji_cell=64;
    global.text_typer_color_emoji_columns=64;
    var atlas_path=working_directory+"editor_fonts/AndroidEmojiAtlas.png";
    var map_path=working_directory+"editor_fonts/AndroidEmojiAtlas.json";
    if(!file_exists(atlas_path)||!file_exists(map_path)) return false;
    var map_file=file_text_open_read(map_path);
    if(map_file<0) return false;
    var map_source="";
    while(!file_text_eof(map_file)){
        map_source+=file_text_read_string(map_file);
        file_text_readln(map_file);
    }
    file_text_close(map_file);
    var map_data=json_parse(map_source);
    if(!is_struct(map_data)||!struct_exists(map_data,"codes")||!is_array(map_data.codes)) return false;
    var atlas_sprite=sprite_add(atlas_path,1,false,false,0,0);
    if(!sprite_exists(atlas_sprite)) return false;
    global.text_typer_color_emoji_sprite=atlas_sprite;
    global.text_typer_color_emoji_codes=map_data.codes;
    global.text_typer_color_emoji_lookup={};
    for(var lookup_index=0;lookup_index<array_length(map_data.codes);lookup_index++) global.text_typer_color_emoji_lookup[$ "u_"+string(map_data.codes[lookup_index])]=lookup_index;
    if(struct_exists(map_data,"cell")) global.text_typer_color_emoji_cell=max(1,round(map_data.cell));
    if(struct_exists(map_data,"columns")) global.text_typer_color_emoji_columns=max(1,round(map_data.columns));
    global.text_typer_color_emoji_ready=true;
    return true;
}

function TextTyper_ColorEmojiIndex(character) {
    if(character=="") return -1;
    var code=string_ord_at(character,1);
    // Ordinary ASCII and CJK make up almost all editor text and can never be
    // atlas emoji. Skip atlas loading and lookup entirely for those ranges.
    var emoji_candidate=code==0x00A9||code==0x00AE||(code>=0x2000&&code<=0x33FF)||(code>=0x1F000&&code<=0x1FAFF);
    if(!emoji_candidate||!TextTyper_ColorEmojiEnsure()) return -1;
    var lookup_key="u_"+string(code);
    return struct_exists(global.text_typer_color_emoji_lookup,lookup_key)?global.text_typer_color_emoji_lookup[$ lookup_key]:-1;
}

function TextTyper_ColorEmojiSize(font_asset=draw_get_font()) {
    var previous=draw_get_font();
    if(font_exists(font_asset)) draw_set_font(font_asset);
    var size=max(10,string_height("Ag"));
    draw_set_font(previous);
    return size;
}

/// Draw one atlas cell with the same anchor/alignment/rotation conventions as
/// draw_text_transformed. The texture quad keeps the original emoji colours;
/// text tint/effect colours affect alpha only.
function TextTyper_DrawColorEmojiTransformed(x,y,character,xscale=1,yscale=1,angle=0,alpha=1,font_asset=draw_get_font()) {
    var index=TextTyper_ColorEmojiIndex(character);
    if(index<0) return false;
    var atlas=global.text_typer_color_emoji_sprite;
    var cell=global.text_typer_color_emoji_cell;
    var columns=global.text_typer_color_emoji_columns;
    var atlas_width=sprite_get_width(atlas);
    var atlas_height=sprite_get_height(atlas);
    var source_x=(index mod columns)*cell;
    var source_y=(index div columns)*cell;
    var sprite_uv=sprite_get_uvs(atlas,0);
    var u0=lerp(sprite_uv[0],sprite_uv[2],source_x/atlas_width);
    var v0=lerp(sprite_uv[1],sprite_uv[3],source_y/atlas_height);
    var u1=lerp(sprite_uv[0],sprite_uv[2],(source_x+cell)/atlas_width);
    var v1=lerp(sprite_uv[1],sprite_uv[3],(source_y+cell)/atlas_height);
    var size=TextTyper_ColorEmojiSize(font_asset);
    var left=0;
    var top=0;
    var halign=draw_get_halign();
    var valign=draw_get_valign();
    if(halign==fa_center) left=-size*0.5; else if(halign==fa_right) left=-size;
    if(valign==fa_middle) top=-size*0.5; else if(valign==fa_bottom) top=-size;
    var right=left+size;
    var bottom=top+size;
    var x1=x+lengthdir_x(left*xscale,angle)+lengthdir_x(top*yscale,angle-90);
    var y1=y+lengthdir_y(left*xscale,angle)+lengthdir_y(top*yscale,angle-90);
    var x2=x+lengthdir_x(right*xscale,angle)+lengthdir_x(top*yscale,angle-90);
    var y2=y+lengthdir_y(right*xscale,angle)+lengthdir_y(top*yscale,angle-90);
    var x3=x+lengthdir_x(right*xscale,angle)+lengthdir_x(bottom*yscale,angle-90);
    var y3=y+lengthdir_y(right*xscale,angle)+lengthdir_y(bottom*yscale,angle-90);
    var x4=x+lengthdir_x(left*xscale,angle)+lengthdir_x(bottom*yscale,angle-90);
    var y4=y+lengthdir_y(left*xscale,angle)+lengthdir_y(bottom*yscale,angle-90);
    var texture=sprite_get_texture(atlas,0);
    draw_primitive_begin_texture(pr_trianglefan,texture);
    draw_vertex_texture_color(x1,y1,u0,v0,c_white,alpha);
    draw_vertex_texture_color(x2,y2,u1,v0,c_white,alpha);
    draw_vertex_texture_color(x3,y3,u1,v1,c_white,alpha);
    draw_vertex_texture_color(x4,y4,u0,v1,c_white,alpha);
    draw_primitive_end();
    return true;
}

/// Cache the routing decision for short UI strings. Most editor labels use a
/// CJK-capable game font and contain no colour emoji, so one native draw call
/// is both correct and dramatically cheaper than resolving/drawing every
/// character separately. The bounded cache is cleared as a unit to avoid an
/// editor session accumulating every transient numeric caption forever.
function TextTyper_FallbackLayoutInfo(text_value,font_asset=draw_get_font()) {
    var source=string(text_value);
    if(!variable_global_exists("text_typer_layout_cache")||!is_struct(global.text_typer_layout_cache)){
        global.text_typer_layout_cache={};
        global.text_typer_layout_cache_count=0;
    }
    var cacheable=string_length(source)<=256;
    var cache_key="f_"+string(font_asset)+"|"+source;
    if(cacheable&&struct_exists(global.text_typer_layout_cache,cache_key)) return global.text_typer_layout_cache[$ cache_key];

    var direct=true;
    var owns_cjk=TextTyper_FontOwnsCjk(font_asset);
    for(var char_index=1;char_index<=string_length(source);char_index++){
        var character=string_char_at(source,char_index);
        var code=string_ord_at(character,1);
        if(TextTyper_IsCjkCode(code)&&!owns_cjk){direct=false;break;}
        var emoji_candidate=code==0x00A9||code==0x00AE||(code>=0x2000&&code<=0x33FF)||(code>=0x1F000&&code<=0x1FAFF);
        if(emoji_candidate&&TextTyper_ColorEmojiIndex(character)>=0){direct=false;break;}
    }
    var result={direct:direct,width:-1};
    if(cacheable){
        if(global.text_typer_layout_cache_count>=4096){global.text_typer_layout_cache={};global.text_typer_layout_cache_count=0;}
        global.text_typer_layout_cache[$ cache_key]=result;
        global.text_typer_layout_cache_count+=1;
    }
    return result;
}

function TextTyper_StringWidthFallback(text_value,font_asset=draw_get_font()) {
    var source=string(text_value);
    var layout=TextTyper_FallbackLayoutInfo(source,font_asset);
    if(layout.direct){
        if(layout.width<0){
            var first_break=string_pos("\n",source);
            var first_line=first_break>0?string_copy(source,1,first_break-1):source;
            var previous_font=draw_get_font();
            if(font_exists(font_asset)) draw_set_font(font_asset);
            layout.width=string_width(first_line);
            draw_set_font(previous_font);
        }
        return layout.width;
    }
    var width=0;
    for(var i=1;i<=string_length(source);i++){
        var character=string_char_at(source,i);
        if(character=="\n") break;
        if(TextTyper_ColorEmojiIndex(character)>=0){
            width+=TextTyper_ColorEmojiSize(font_asset);
            continue;
        }
        var resolved=TextTyper_FontResolve(font_asset,character);
        draw_set_font(resolved);
        width+=string_width(character);
    }
    draw_set_font(font_asset);
    return width;
}

/// Drop-in drawing helper for ordinary game/UI text. It keeps the selected
/// font for every glyph it owns and changes font only for missing characters.
function TextTyper_DrawFallback(x,y,text_value) {
    var source=string(text_value);
    var preferred=draw_get_font();
    var old_halign=draw_get_halign();
    var old_valign=draw_get_valign();
    if(old_halign==fa_left&&old_valign==fa_top&&TextTyper_FallbackLayoutInfo(source,preferred).direct){
        draw_text(x,y,source);
        return;
    }
    var lines=string_split(source,"\n");
    var base_height=string_height("Ag");
    var line_count=array_length(lines);
    var total_height=base_height*line_count;
    var start_y=y;
    if(old_valign==fa_middle) start_y-=total_height*0.5;
    else if(old_valign==fa_bottom) start_y-=total_height;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    for(var line_index=0;line_index<line_count;line_index++){
        var line=lines[line_index];
        // Left-aligned UI text does not need a full measurement pass.
        var line_width=old_halign==fa_left?0:TextTyper_StringWidthFallback(line,preferred);
        var cursor_x=x;
        if(old_halign==fa_center) cursor_x-=line_width*0.5;
        else if(old_halign==fa_right) cursor_x-=line_width;
        var run_text="";
        var run_font=-1;
        var run_x=cursor_x;
        for(var char_index=1;char_index<=string_length(line);char_index++){
            var character=string_char_at(line,char_index);
            if(TextTyper_ColorEmojiIndex(character)>=0){
                if(run_text!=""){
                    draw_set_font(run_font);
                    var run_height=string_height(run_text);
                    draw_text(run_x,start_y+line_index*base_height+(base_height-run_height)*0.5,run_text);
                    cursor_x+=string_width(run_text);
                    run_text="";
                }
                TextTyper_DrawColorEmojiTransformed(cursor_x,start_y+line_index*base_height,character,1,1,0,1,preferred);
                cursor_x+=TextTyper_ColorEmojiSize(preferred);
                run_x=cursor_x;
                continue;
            }
            var resolved=TextTyper_FontResolve(preferred,character);
            if(run_text!=""&&resolved!=run_font){
                draw_set_font(run_font);
                var completed_run_height=string_height(run_text);
                draw_text(run_x,start_y+line_index*base_height+(base_height-completed_run_height)*0.5,run_text);
                cursor_x+=string_width(run_text);
                run_text="";
                run_x=cursor_x;
            }
            if(run_text==""){run_font=resolved;run_x=cursor_x;}
            run_text+=character;
        }
        if(run_text!=""){
            draw_set_font(run_font);
            var final_run_height=string_height(run_text);
            draw_text(run_x,start_y+line_index*base_height+(base_height-final_run_height)*0.5,run_text);
        }
    }
    draw_set_font(preferred);
    draw_set_halign(old_halign);
    draw_set_valign(old_valign);
}

/// Wrap once in linear time. The previous implementation measured the whole
/// growing candidate string after every character, making long manuals
/// quadratic before they were even drawn.
function TextTyper_WrapFallbackLines(text_value,line_width,font_asset=draw_get_font()) {
    var source=string(text_value);
    var preferred=font_asset;
    if(!variable_global_exists("text_typer_wrap_cache")||!is_struct(global.text_typer_wrap_cache)){
        global.text_typer_wrap_cache={};
        global.text_typer_wrap_cache_count=0;
    }
    var cacheable=string_length(source)<=4096;
    var cache_key="w|"+string(preferred)+"|"+string(line_width)+"|"+source;
    if(cacheable&&struct_exists(global.text_typer_wrap_cache,cache_key)) return global.text_typer_wrap_cache[$ cache_key];
    var paragraphs=string_split(source,"\n");
    var lines=[];
    for(var paragraph_index=0;paragraph_index<array_length(paragraphs);paragraph_index++){
        var paragraph=paragraphs[paragraph_index];
        var line="";
        var measured_width=0;
        for(var char_index=1;char_index<=string_length(paragraph);char_index++){
            var character=string_char_at(paragraph,char_index);
            var char_width;
            if(TextTyper_ColorEmojiIndex(character)>=0) char_width=TextTyper_ColorEmojiSize(preferred);
            else{
                draw_set_font(TextTyper_FontResolve(preferred,character));
                char_width=string_width(character);
            }
            if(line!=""&&line_width>=0&&measured_width+char_width>line_width){
                array_push(lines,line);
                line=character;
                measured_width=char_width;
            }else{
                line+=character;
                measured_width+=char_width;
            }
        }
        array_push(lines,line);
    }
    draw_set_font(preferred);
    if(cacheable){
        if(global.text_typer_wrap_cache_count>=1024){global.text_typer_wrap_cache={};global.text_typer_wrap_cache_count=0;}
        global.text_typer_wrap_cache[$ cache_key]=lines;
        global.text_typer_wrap_cache_count+=1;
    }
    return lines;
}

/// Return the widest prefix that fits with an ellipsis. Button captions and
/// resource names call this every Draw, so cache the stable layout and use a
/// logarithmic search for new strings instead of deleting one glyph at a time.
function TextTyper_EllipsisFallback(text_value,available_width,font_asset=draw_get_font()) {
    var source=string(text_value);
    var preferred=font_asset;
    if(TextTyper_StringWidthFallback(source,preferred)<=available_width) return source;
    if(!variable_global_exists("text_typer_ellipsis_cache")||!is_struct(global.text_typer_ellipsis_cache)){
        global.text_typer_ellipsis_cache={};
        global.text_typer_ellipsis_cache_count=0;
    }
    var cacheable=string_length(source)<=1024;
    var cache_key="e|"+string(preferred)+"|"+string(available_width)+"|"+source;
    if(cacheable&&struct_exists(global.text_typer_ellipsis_cache,cache_key)) return global.text_typer_ellipsis_cache[$ cache_key];
    var suffix="...";
    var low=0;
    var high=string_length(source);
    while(low<high){
        var middle=ceil((low+high)*0.5);
        var candidate=string_copy(source,1,middle)+suffix;
        if(TextTyper_StringWidthFallback(candidate,preferred)<=available_width) low=middle;
        else high=middle-1;
    }
    var result=string_copy(source,1,low)+suffix;
    if(cacheable){
        if(global.text_typer_ellipsis_cache_count>=2048){global.text_typer_ellipsis_cache={};global.text_typer_ellipsis_cache_count=0;}
        global.text_typer_ellipsis_cache[$ cache_key]=result;
        global.text_typer_ellipsis_cache_count+=1;
    }
    return result;
}

/// Fallback-aware draw_text_ext(). Wrapping is measured with the actual font
/// selected for every glyph, so the visible line and its hit/layout width
/// cannot disagree after a fallback occurs.
function TextTyper_DrawFallbackExt(x,y,text_value,line_sep,line_width) {
    var preferred=draw_get_font();
    var source=string(text_value);
    // Most inspector captions fit on one line. Avoid constructing a wrapped
    // line array and resolving every glyph when native drawing is sufficient.
    if(string_pos("\n",source)==0){
        var layout=TextTyper_FallbackLayoutInfo(source,preferred);
        if(layout.direct&&(line_width<0||TextTyper_StringWidthFallback(source,preferred)<=line_width)){
            draw_text(x,y,source);
            return;
        }
    }
    var lines=TextTyper_WrapFallbackLines(source,line_width,preferred);
    var base_height=string_height("Ag");
    var step_y=line_sep<0?base_height:line_sep;
    for(var line_index=0;line_index<array_length(lines);line_index++) TextTyper_DrawFallback(x,y+line_index*step_y,lines[line_index]);
    draw_set_font(preferred);
}

/// Fallback-aware draw_text_transformed(). Every character uses the same
/// transform but advances by the real fallback glyph width in local space.
function TextTyper_DrawFallbackTransformed(x,y,text_value,xscale,yscale,angle) {
    var source=string(text_value);
    var preferred=draw_get_font();
    if(TextTyper_FallbackLayoutInfo(source,preferred).direct){
        draw_text_transformed(x,y,source,xscale,yscale,angle);
        return;
    }
    var old_halign=draw_get_halign();
    var old_valign=draw_get_valign();
    var width=TextTyper_StringWidthFallback(source,preferred);
    var local_x=old_halign==fa_center?-width*0.5:(old_halign==fa_right?-width:0);
    draw_set_halign(fa_left);
    draw_set_valign(old_valign);
    for(var i=1;i<=string_length(source);i++){
        var character=string_char_at(source,i);
        if(TextTyper_ColorEmojiIndex(character)>=0){
            var emoji_x=x+lengthdir_x(local_x*xscale,angle);
            var emoji_y=y+lengthdir_y(local_x*xscale,angle);
            TextTyper_DrawColorEmojiTransformed(emoji_x,emoji_y,character,xscale,yscale,angle,1,preferred);
            local_x+=TextTyper_ColorEmojiSize(preferred);
            continue;
        }
        var resolved=TextTyper_FontResolve(preferred,character);
        draw_set_font(resolved);
        var char_x=x+lengthdir_x(local_x*xscale,angle);
        var char_y=y+lengthdir_y(local_x*xscale,angle);
        draw_text_transformed(char_x,char_y,character,xscale,yscale,angle);
        local_x+=string_width(character);
    }
    draw_set_font(preferred);
    draw_set_halign(old_halign);
    draw_set_valign(old_valign);
}

function TextTyper_DrawFallbackExtTransformed(x,y,text_value,line_sep,line_width,xscale,yscale,angle) {
    var source=string(text_value);
    var preferred=draw_get_font();
    // Use the same linear wrapper as untransformed text. The old path measured
    // the whole growing line after every character and became quadratic.
    var lines=TextTyper_WrapFallbackLines(source,line_width,preferred);
    var step_y=(line_sep<0?string_height("Ag"):line_sep)*yscale;
    for(var line_index=0;line_index<array_length(lines);line_index++){
        var line_x=x+lengthdir_x(line_index*step_y,angle-90);
        var line_y=y+lengthdir_y(line_index*step_y,angle-90);
        TextTyper_DrawFallbackTransformed(line_x,line_y,lines[line_index],xscale,yscale,angle);
    }
    draw_set_font(preferred);
}
