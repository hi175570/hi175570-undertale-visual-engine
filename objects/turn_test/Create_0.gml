event_inherited();

// 第一回合不含任何硬编码弹幕，只保留战斗系统进入回合所需的初始化。
var editor_project = variable_global_exists("battle_editor_project_runtime")
    ? global.battle_editor_project_runtime
    : BattleEditor_NewProject();
project=BattleEditor_ProjectNormalize(editor_project);
// _turn_number counts completed monster turns, so the next playable one is +1.
script_monster_turn=BattleEditor_ResolveMonsterTurn(project,max(1,Battle_GetTurnNumber()+1));
var init = project.initialization;
var board = init.board;
if(project.settings.developer_force_default_board){
    board={x:320,y:320,up:65,down:65,left:65,right:65,angle:0};
}

var editor_turn_duration=BattleEditor_EffectiveDuration(project,script_monster_turn);
// No authored event means "manual/unknown length", not a one-frame turn.
// Space/Escape in turn_test remains the explicit way back to the editor.
Battle_SetTurnInfo(BATTLE_TURN.TIME, editor_turn_duration>0?editor_turn_duration:1000000000);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_X, board.x);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_Y, board.y);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_UP, board.up);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_DOWN, board.down);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_LEFT, board.left);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_RIGHT, board.right);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_ANGLE, board.angle);
Battle_SetTurnInfo(BATTLE_TURN.BOARD_RESET_ANGLE, 0);
Battle_SetTurnInfo(BATTLE_TURN.SOUL_X, 0);
Battle_SetTurnInfo(BATTLE_TURN.SOUL_Y, 0);

// The saved editor project is also the real battle timeline. This lightweight
// host runs only the scene events and timer lists owned by the active turn.
playing=false;
playhead=0;
fired=[];
runtime_instances=[];
preview_frames=[];
board_preview_active=false;
keep_board_on_stop=false;
script_runtime_states=[];
script_timer_fired=[];
script_vertex_animations=[];
BattleEditor_ApplyTurnPresentation(project,script_monster_turn);
// Wait for TURN_START. Enemy speech and board movement happen during
// TURN_PREPARATION and must finish before the attack timeline advances.
