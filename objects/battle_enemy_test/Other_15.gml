/// @desc Menu End - resolve the authorable ACT entry and its Workspace hook.
if(Battle_GetMenuChoiceButton()==BATTLE_MENU_CHOICE_BUTTON.ACT){
    var selected_enemy_slot=Battle_ConvertMenuChoiceEnemyToEnemySlot(Battle_GetMenuChoiceEnemy());
    if(_enemy_slot!=selected_enemy_slot) exit;
    var action_index=Battle_GetMenuChoiceAction();
    if(variable_global_exists("battle_editor_project_runtime")){
        var action_project=BattleEditor_ProjectNormalize(global.battle_editor_project_runtime);
        if(selected_enemy_slot>=0&&selected_enemy_slot<array_length(action_project.initialization.enemies)){
            var action_enemy=action_project.initialization.enemies[selected_enemy_slot];
            if(action_index>=0&&action_index<array_length(action_enemy.actions)){
                var selected_action=action_enemy.actions[action_index];
                if(string_length(selected_action.text)>0){Dialog_Add(TextTyper_CompileMarkup(selected_action.text).text);Dialog_Start();}
                BattleEditor_NotifyActionUsed(selected_action.uid);
            }
        }
    }else{
        switch(action_index){
            case 0:Dialog_Add("* 三个方框盯着你。&* 其中至少两个并不存在。");break;
            case 1:Dialog_Add("* 这是机制测试对象。&* 它拒绝提供任何背景故事。");break;
            case 2:Dialog_Add("* 你要求进入下一回合。&* 攻击测试照常开始。");break;
        }
        Dialog_Start();
    }
}
