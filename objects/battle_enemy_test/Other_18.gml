// Battle_Core broadcasts TURN_PREPARATION_START to every live enemy slot.
// The encounter timeline is shared, so only slot 0 may create its turn host;
// otherwise adding a second target duplicates every board, bullet and script.
if(_enemy_slot!=0) exit;

// Character speech uses the actual enemy speech bubble. TURN_PREPARATION
// already waits until every battle_dialog_enemy instance has finished.
if(variable_global_exists("battle_editor_project_runtime")){
    var editor_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
    var editor_turn=BattleEditor_ResolveMonsterTurn(editor_project,max(1,Battle_GetTurnNumber()+1));
    var editor_turn_data=BattleEditor_GetTurnData(editor_project,editor_turn,true);
    var editor_dialogue=editor_turn_data.dialogue;
    if(string_length(editor_dialogue)>0){
        // Anchor speech to the enemy root, not a swaying body part.  The root
        // follows whole-character movement while the bubble remains visually
        // stable during the idle animation.
        Battle_Dialog_Enemy_Add(
            x+editor_turn_data.dialogue_offset_x,
            y+editor_turn_data.dialogue_offset_y,
            DEPTH_BATTLE.UI_HIGH,
            "{font "+string(editor_turn_data.dialogue_font)+"}{voice "+string(editor_turn_data.dialogue_voice)+"}"+TextTyper_CompileMarkup(editor_dialogue).text,
            editor_turn_data.dialogue_template
        );
    }
}
var test_turn=instance_create_depth(0,0,0,turn_test);
