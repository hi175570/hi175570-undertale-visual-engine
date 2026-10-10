///@arg text*
///@arg choice*
///@arg line2*
function Battle_SetDialog() {
	var TEXT="";
	var CHOICE=false;
	var LINE2=false;
	if(argument_count>=1){
		TEXT=argument[0];
	}
	if(argument_count>=2){
		CHOICE=argument[1];
	}
	if(argument_count>=3){
		LINE2=argument[2];
	}

	//销毁原实例
	if(instance_exists(battle._dialog[LINE2])){
		instance_destroy(battle._dialog[LINE2]);
	}

	if(TEXT!=""){
		//创建实例
		var tx=battle_board.x-battle_board.left-5+28;
		var ty=battle_board.y-battle_board.up-5+20;
		// Editor round text uses fixed battle-screen coordinates; moving the
		// monster-turn board must not drag this menu sentence with it.
		if(variable_global_exists("battle_editor_project_runtime")&&!CHOICE&&!LINE2){
			var editor_init=global.battle_editor_project_runtime.initialization;
			if(struct_exists(editor_init,"turn_text_x")) tx=editor_init.turn_text_x;
			if(struct_exists(editor_init,"turn_text_y")) ty=editor_init.turn_text_y;
		}
		if(CHOICE){
			tx+=40
		}
		if(LINE2){
			tx+=256;
		}
		battle._dialog[LINE2]=instance_create_depth(tx,ty,0,text_typer);
	
		//更改文字
		var text_prefix="{scale 2}{voice 1}{speed 2}{shadow true}{color `white`}{gui false}{depth "+string(DEPTH_BATTLE.UI_HIGH)+"}";
		if(CHOICE){
			text_prefix+="{instant true}";
		}
		battle._dialog[LINE2].text=text_prefix+TEXT;
		return battle._dialog[LINE2];
	}else{
		return noone;
	}


}
