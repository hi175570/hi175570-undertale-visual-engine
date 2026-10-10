/// @desc Turn End - prepare the next player-menu description.
if(variable_global_exists("battle_editor_project_runtime")){
    var next_editor_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
    BattleEditor_ApplyTurnPresentation(next_editor_project,BattleEditor_ResolveMonsterTurn(next_editor_project,max(1,Battle_GetTurnNumber()+1)));
}else{
    Battle_SetMenuDialog(_round_menu_texts[0]);
}
