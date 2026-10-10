event_inherited();
// 弹幕由通用编辑器时间轴执行；这里故意没有第一回合攻击代码。
// Space/Escape are editor-preview controls, never encounter controls. A
// normal game started from the title screen also uses turn_test, so leaving
// this unguarded let players end a real monster turn with Space.
if(BattleEditor_IsEditorBattle()&&(keyboard_check_pressed(vk_space)||keyboard_check_pressed(vk_escape))
&&instance_exists(battle)&&(Battle_GetState()==BATTLE_STATE.TURN_PREPARATION||Battle_GetState()==BATTLE_STATE.IN_TURN)){
    BattleEditor_ForceExitMonsterTurn(id);
    exit;
}
if(playing) BattleEditor_RuntimeStep(id);
