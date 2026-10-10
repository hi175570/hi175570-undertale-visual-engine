/// Human-readable markup API for text_typer.
/// Store the readable source and call TextTyper_CompileMarkup before passing it
/// to TextTyper_Add, Battle_SetMenuDialog or Battle_Dialog_Enemy_Add.

function TextTyper_MarkupIsNumber(value) {
    var source=string(value);
    if(source==""||source=="-"||source=="."||source=="-.") return false;
    var filtered="";
    var has_dot=false;
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch>="0"&&ch<="9") filtered+=ch;
        else if(ch=="-"&&string_length(filtered)==0) filtered+=ch;
        else if(ch=="."&&!has_dot){filtered+=ch;has_dot=true;}
    }
    return filtered==source;
}

function TextTyper_HexNibble(ch) {
    return string_pos(string_upper(ch),"0123456789ABCDEF")-1;
}

/// Returns {color,alpha} or undefined. Accepted formats: #RRGGBB, #RRGGBBAA.
function TextTyper_ParseHexColor(value) {
    var source=string_upper(string(value));
    if(string_char_at(source,1)=="#") source=string_delete(source,1,1);
    if(string_length(source)!=6&&string_length(source)!=8) return undefined;
    for(var i=1;i<=string_length(source);i++) if(TextTyper_HexNibble(string_char_at(source,i))<0) return undefined;
    var r=TextTyper_HexNibble(string_char_at(source,1))*16+TextTyper_HexNibble(string_char_at(source,2));
    var g=TextTyper_HexNibble(string_char_at(source,3))*16+TextTyper_HexNibble(string_char_at(source,4));
    var b=TextTyper_HexNibble(string_char_at(source,5))*16+TextTyper_HexNibble(string_char_at(source,6));
    var a=255;
    if(string_length(source)==8) a=TextTyper_HexNibble(string_char_at(source,7))*16+TextTyper_HexNibble(string_char_at(source,8));
    return {color:make_color_rgb(r,g,b),alpha:a/255};
}

/// @returns {text,error,error_index}. wait is expressed in seconds.
function TextTyper_CompileMarkup(source) {
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
        }else if(tag=="page"){
            // The native typer already implements this interaction: pause waits
            // for CONFIRM (Z/Enter), then clear begins the next page.
            command="{pause}{clear}";self_closing=true;
        }else if(string_pos("wait=",tag)==1){
            var wait_text=string_copy(tag,6,string_length(tag)-5);
            if(!TextTyper_MarkupIsNumber(wait_text)||real(wait_text)<0){error="wait 必须是非负秒数";error_index=cursor;break;}
            command="{sleep "+string(real(wait_text)*room_speed)+"}";self_closing=true;
        }else if(string_pos("color=",tag)==1){
            var color_text=string_copy(raw,7,string_length(raw)-6);
            var parsed_color=TextTyper_ParseHexColor(color_text);
            if(is_undefined(parsed_color)){error="color 必须是 #RRGGBB 或 #RRGGBBAA";error_index=cursor;break;}
            command="{color_text "+string(parsed_color.color)+"}{alpha "+string(parsed_color.alpha)+"}";
            close_command="{color_text "+string(c_white)+"}{alpha 1}";tag_name="color";
        }else if(string_pos("gradient=",tag)==1){
            var gradient_text=string_copy(raw,10,string_length(raw)-9);
            var comma=string_pos(",",gradient_text);
            if(comma<=0){error="gradient 需要两个 Hex 颜色";error_index=cursor;break;}
            var color_a=TextTyper_ParseHexColor(string_copy(gradient_text,1,comma-1));
            var color_b=TextTyper_ParseHexColor(string_copy(gradient_text,comma+1,string_length(gradient_text)-comma));
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
            if(!TextTyper_MarkupIsNumber(angle_text)){error="rotate 必须是角度数字";error_index=cursor;break;}
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

function TextTyper_ValidateMarkup(source) {
    var result=TextTyper_CompileMarkup(source);
    return {valid:result.error=="",error:result.error,error_index:result.error_index};
}

function TextTyper_MarkupErrorLocation(source,error_index) {
    var line=1;
    var column=1;
    source=string(source);
    for(var i=1;i<error_index&&i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch=="\n"||ch=="&"){line+=1;column=1;}
        else column+=1;
    }
    return {line:line,column:column};
}

function TextTyper_MarkupPlain(source) {
    source=string(source);
    if(!variable_global_exists("text_typer_markup_plain_cache")||!is_struct(global.text_typer_markup_plain_cache)){
        global.text_typer_markup_plain_cache={};
        global.text_typer_markup_plain_cache_count=0;
    }
    var cacheable=string_length(source)<=4096;
    var cache_key="m|"+source;
    if(cacheable&&struct_exists(global.text_typer_markup_plain_cache,cache_key)) return global.text_typer_markup_plain_cache[$ cache_key];
    var result="";
    var inside=false;
    for(var i=1;i<=string_length(source);i++){
        var ch=string_char_at(source,i);
        if(ch=="<"){inside=true;continue;}
        if(ch==">"){inside=false;continue;}
        if(!inside) result+=ch;
    }
    result=string_replace_all(result,"&","#");
    if(cacheable){
        if(global.text_typer_markup_plain_cache_count>=1024){global.text_typer_markup_plain_cache={};global.text_typer_markup_plain_cache_count=0;}
        global.text_typer_markup_plain_cache[$ cache_key]=result;
        global.text_typer_markup_plain_cache_count+=1;
    }
    return result;
}

function TextTyper_MarkupHelp() {
    return [
        {name:"换行",syntax:"<br>",example:"第一行<br>第二行"},
        {name:"下一句",syntax:"<page>",example:"第一句<page>按 Z 后显示第二句"},
        {name:"等待",syntax:"<wait=秒>",example:"等等<wait=0.5>继续"},
        {name:"颜色",syntax:"<color=#RRGGBB[AA]>...</color>",example:"<color=#FF6060>红色</color>"},
        {name:"渐变",syntax:"<gradient=#RRGGBB,#RRGGBB>...</gradient>",example:"<gradient=#FF0000,#0000FF>渐变</gradient>"},
        {name:"震动",syntax:"<shake>...</shake>",example:"<shake>危险</shake>"},
        {name:"色散",syntax:"<glitch>...</glitch>",example:"<glitch>错误</glitch>"},
        {name:"漂浮",syntax:"<float>...</float>",example:"<float>漂浮</float>"},
        {name:"旋转",syntax:"<rotate=角度>...</rotate>",example:"<rotate=15>倾斜</rotate>"},
        {name:"循环色",syntax:"<cycle>...</cycle>",example:"<cycle>彩虹</cycle>"}
    ];
}
