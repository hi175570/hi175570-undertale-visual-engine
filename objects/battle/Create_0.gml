_encounter=Storage_GetTempFlag(FLAG_TEMP_ENCOUNTER);
_enemy_object[0]=Encounter_GetEnemy(_encounter,0);
_enemy_object[1]=Encounter_GetEnemy(_encounter,1);
_enemy_object[2]=Encounter_GetEnemy(_encounter,2);
//敌人实例
_heal=0;
_hp=0;
_kr=0;
damage=0;
_enemy[0]=noone;
_enemy[1]=noone;
_enemy[2]=noone;
// Editor projects may display up to fifteen authored enemies. Only the stock
// first three are registered as FIGHT/ACT targets; the rest live here as
// visual/script-controlled enemy instances.
_battle_editor_extra_enemies=[];
//敌人名字
_enemy_name[0]="";
_enemy_name[1]="";
_enemy_name[2]="";
//敌人可饶恕状�?
_enemy_spareable[0]=false;
_enemy_spareable[1]=false;
_enemy_spareable[2]=false;
//敌人行动列表
_enemy_action_number[0]=0;
_enemy_action_number[1]=0;
_enemy_action_number[2]=0;
_enemy_action_name[0,0]="";
_enemy_action_name[0,1]="";
_enemy_action_name[0,2]="";
_enemy_action_name[0,3]="";
_enemy_action_name[0,4]="";
_enemy_action_name[0,5]="";
_enemy_action_name[1,0]="";
_enemy_action_name[1,1]="";
_enemy_action_name[1,2]="";
_enemy_action_name[1,3]="";
_enemy_action_name[1,4]="";
_enemy_action_name[1,5]="";
_enemy_action_name[2,0]="";
_enemy_action_name[2,1]="";
_enemy_action_name[2,2]="";
_enemy_action_name[2,3]="";
_enemy_action_name[2,4]="";
_enemy_action_name[2,5]="";
//敌人中心位置
_enemy_center_pos_x[0]=0;
_enemy_center_pos_y[0]=0;
_enemy_center_pos_x[1]=0;
_enemy_center_pos_y[1]=0;
_enemy_center_pos_x[2]=0;
_enemy_center_pos_y[2]=0;
//敌人属�?
_enemy_def[0]=0;
_enemy_def[1]=0;
_enemy_def[2]=0;

//状�?
_state=-1;
_state_next=-1;
//菜单
_menu=-1;
_menu_choice_button=0;
_menu_choice_enemy=0;
_menu_choice_action=0;
_menu_choice_item=0;
_menu_choice_item_first=0;
_menu_choice_mercy=0;
_menu_choice_mercy_override=false;
_menu_choice_mercy_override_number=1;
_menu_choice_mercy_override_name[0]="";
_menu_choice_mercy_override_name[1]="";
_menu_choice_mercy_override_name[2]="";
_menu_fleeable=false;
_menu_mercy_flee_enabled=Encounter_IsMenuMercyFleeEnabled(_encounter);
_menu_dialog=Encounter_GetMenuDialog(_encounter);

_menu_fight_damage=0;
_menu_fight_anim_time=0;
_menu_fight_damage_time=0;

_menu_item_used_last=-1;
battle_editor_entry_active=false;
// Deferred item-use Workspace lists are consumed by the next turn_test host
// after enemy dialogue. The mode decides whether that list accompanies or
// replaces the ordinary monster-turn entry.
_battle_editor_pending_item_uid="";
_battle_editor_pending_item_mode=BATTLE_EDITOR_ITEM_AFTER_USE.IMMEDIATE;

_turn_number=0;
_turn_info=ds_map_create();

_dialog[0]=noone;
_dialog[1]=noone;
_dialog_auto_end=true;
_dialog_enemy_auto_end=true;

_reward_gold=0;
_reward_exp=0;

_player_temp_atk=0;
_player_temp_def=0;
_player_temp_spd=0;
_player_temp_inv=0;

kr_timer=0;
hurt_timer=0;
_typed_hurt_cooldown=0;
// Damage judgements which are explicitly allowed to overlap use independent
// locks. Each channel still prevents several hazards of its own kind from
// applying in the same contact window.
_true_knife_hurt_cooldown=0;
_blue_hurt_cooldown=0;
_orange_hurt_cooldown=0;
// Purple attacks reserve delayed damage without changing HP or either HP
// limit. The next non-purple attack that really deals damage consumes it.
_purple_occupancy=0;
_purple_occupancy_cap=40;

// Optional general-purpose battle extensions. Encounters opt in as needed.
_shield_enabled=false;
_shield_active=false;
_shield_natural_max=100;
_shield_max=100;
_shield=100;
_shield_drain_per_second=35;
_shield_recover_per_second=15;
_shield_recover_delay_seconds=0;
_shield_recover_timer=0;
_shield_hud_mode=BATTLE_SHIELD_HUD_MODE.BELOW_HP;
_survival_item_enabled=false;
_survival_item_heals=[];
_survival_item_slot=0;
_survival_item_cooldown=0;
_survival_item_last_result=undefined;
_survival_item_full_heal=false;

