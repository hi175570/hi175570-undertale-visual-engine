enum BATTLE_SHIELD_HUD_MODE {
    BELOW_HP,
    SIDE
}

/// Enables the separate green-soul directional guard for one attack instance.
function Battle_GreenGuardConfigure(_attack, _blockable=true, _destroy_on_block=true) {
    if(!instance_exists(_attack)) return _attack;
    _attack.green_guard_blockable=_blockable;
    _attack.green_guard_destroy_on_block=_destroy_on_block;
    _attack.green_guard_blocked=false;
    return _attack;
}

/// Applies one guard reaction. Persistent attacks such as GB beams are marked
/// immune per instance; disposable attacks are removed after the reaction.
function Battle_GreenGuardBlock(_attack, _guard) {
    if(!instance_exists(_attack) || !instance_exists(_guard)) return false;
    if(!_attack.green_guard_blockable) return false;
    if(_attack.green_guard_blocked) return true;

    _attack.green_guard_blocked=true;
    var _dx=_guard.x-_attack.x;
    var _dy=_guard.y-_attack.y;
    // GameMaker's lengthdir_y uses -sin, so the forward-axis dot product must
    // use the same sign or angled shields crop the wrong side of the beam.
    _attack.green_guard_block_distance=max(0,_dx*dcos(_attack.image_angle)-_dy*dsin(_attack.image_angle));
    _guard.image_index=1;
    Anim_Create(_guard,"image_index",0,0,1,-1,1,4);
    audio_play_sound(snd_ding,0,false);

    if(_attack.green_guard_destroy_on_block) instance_destroy(_attack);
    return true;
}

function Player_GetNaturalHpMax() {
    return Storage_GetStaticGeneral().Get(FLAG_STATIC_HP_MAX_NATURAL, Player_GetHpMax());
}

function Player_SetNaturalHpMax(value) {
    Storage_GetStaticGeneral().Set(FLAG_STATIC_HP_MAX_NATURAL, max(1, value));
}

function Player_ReduceMaxHp(amount) {
    var old_max = Player_GetHpMax();
    var new_max = max(1, old_max - max(0, amount));
    Player_SetHpMax(new_max);
    Player_SetHp(min(Player_GetHp(), new_max));
    Player_SetKr(min(Player_GetKr(), max(0, new_max - Player_GetHp())));
    return old_max - new_max;
}

/// Purple damage reserves a dark-purple section over the right-hand end of the
/// player's yellow HP and grows leftward. It is not HP, KR or max-HP loss: only
/// a later, genuinely successful non-purple hit converts it into damage.
function Player_GetPurpleOccupancyCap() {
    if(instance_exists(battle)&&variable_instance_exists(battle,"_purple_occupancy_cap")) return max(0,battle._purple_occupancy_cap);
    return 40;
}

function Player_GetPurpleOccupancy() {
    if(!instance_exists(battle)||!variable_instance_exists(battle,"_purple_occupancy")) return 0;
    return clamp(battle._purple_occupancy,0,Player_GetPurpleOccupancyCap());
}

function Player_BeginPurpleOccupancyDrop(amount) {
    if(amount<=0||!instance_exists(battle_ui)) return false;
    var ui=instance_find(battle_ui,0);
    var hp=max(0,Player_GetHp());
    var natural_max=max(1,max(Player_GetHpMax(),Player_GetNaturalHpMax()));
    var bar_width=natural_max<=92?natural_max*1.25:92*1.25;
    var hp_width=bar_width*hp/natural_max;
    var reserve_width=max(1,bar_width*amount/natural_max);
    var visible_width=min(hp_width,reserve_width);
    if(visible_width<=0) return false;
    var bar_x=ui.x+ui.vitals_offset_x+245;
    var bar_y=ui.y+ui.vitals_offset_y-1;
    ui.purple_drop_active=true;
    ui.purple_drop_x=bar_x+hp_width-visible_width*0.5;
    ui.purple_drop_y=bar_y+10;
    ui.purple_drop_width=visible_width;
    ui.purple_drop_height=20;
    // Detach with a small randomized upward impulse, then fall under gravity.
    // Horizontal drift and angular velocity vary independently so consecutive
    // consumed blocks do not replay the same mechanical-looking motion.
    ui.purple_drop_vx=random_range(-0.75,0.75);
    ui.purple_drop_vy=-random_range(1.7,2.5);
    ui.purple_drop_gravity=random_range(0.14,0.19);
    ui.purple_drop_angle=0;
    ui.purple_drop_spin=choose(-1,1)*random_range(2,5);
    ui.purple_drop_age=0;
    ui.purple_drop_alpha=1;
    return true;
}

function Player_ClearPurpleOccupancy(play_drop=false) {
    if(!instance_exists(battle)) return 0;
    var reserved=Player_GetPurpleOccupancy();
    if(play_drop&&reserved>0) Player_BeginPurpleOccupancyDrop(reserved);
    battle._purple_occupancy=0;
    return reserved;
}

/// Healing covers purple occupancy as well as restoring ordinary HP, but the
/// reserve is deliberately punitive: two points of healing power remove only
/// one point of purple occupancy. This is not damage settlement, so the
/// removed portion does not spawn the detached falling block.
function Player_HealPurpleOccupancy(heal_amount) {
    if(!instance_exists(battle)||heal_amount<=0) return 0;
    var old_reserved=Player_GetPurpleOccupancy();
    var removed=min(old_reserved,floor(max(0,real(heal_amount))/2));
    battle._purple_occupancy=max(0,old_reserved-removed);
    return removed;
}

/// Starts one visual HP/purple coverage tween without delaying the real heal.
/// A second heal continues from the currently displayed values instead of
/// snapping back to the first animation's old endpoint.
function BattleUI_StartHealTween(old_hp,new_hp,old_purple,new_purple,duration=18) {
    if(!instance_exists(battle_ui)) return false;
    var ui=instance_find(battle_ui,0);
    var visual_hp=old_hp;
    var visual_purple=old_purple;
    if(ui.heal_tween_active){
        var current_amount=Anim_GetValue(ANIM_TWEEN.SINE,ANIM_EASE.OUT,clamp(ui.heal_tween_age/max(1,ui.heal_tween_duration),0,1));
        visual_hp=lerp(ui.heal_tween_start_hp,ui.heal_tween_target_hp,current_amount);
        visual_purple=lerp(ui.heal_tween_start_purple,ui.heal_tween_target_purple,current_amount);
    }
    ui.heal_tween_start_hp=visual_hp;
    ui.heal_tween_target_hp=new_hp;
    ui.heal_tween_start_purple=visual_purple;
    ui.heal_tween_target_purple=new_purple;
    ui.heal_tween_age=0;
    ui.heal_tween_duration=max(1,duration);
    ui.heal_tween_active=(visual_hp!=new_hp||visual_purple!=new_purple);
    return ui.heal_tween_active;
}

function Player_AddPurpleOccupancy(authored_damage=-1) {
    if(!instance_exists(battle)) return false;
    // The ordinary shield and normal judgement lock must be resolved before
    // reserving anything. A blocked contact is not a purple hit.
    if(Battle_ShieldAbsorb()) return false;
    if(battle._typed_hurt_cooldown>0) return false;
    var authored=authored_damage<0?1:max(0,real(authored_damage));
    if(authored<=0) return false;
    var amount=Player_CalculateBulletDamage(authored,1);
    var old_reserved=Player_GetPurpleOccupancy();
    var new_reserved=min(Player_GetPurpleOccupancyCap(),old_reserved+amount);
    if(new_reserved<=old_reserved) return false;
    battle._purple_occupancy=new_reserved;
    battle._typed_hurt_cooldown=6;
    audio_play_sound(snd_hurt,0,false);
    return true;
}

/// Applies the useful part of the original UTE damage formula to authored
/// bullet damage.  The original HP-based bonus is intentionally excluded:
/// editor battles may use very large HP totals (114514 in the test project),
/// and HP must never turn a 2-point bone into an 11k hit. DEF/5 is applied
/// once to the HP endpoint; Player_HurtTyped preserves the authored gap to
/// the KR endpoint instead of independently defending both values.
function Player_CalculateBulletDamage(base_damage, min_damage=1) {
    base_damage=max(0,real(base_damage));
    if(base_damage<=0) return 0;
    return max(min_damage,round(base_damage-Player_GetDefTotal()/5));
}

/// One source of truth for the colour rules recovered from
/// ScratchUndertaleAnalysis/output.1/all_scripts.md ("伤害判定").
///
/// The Scratch project stores two absolute endpoints:
///   血量 -= hp, Kr -= kr
/// UTEU stores HP plus only the visible purple overhang. Player_HurtTyped()
/// performs that representation conversion; callers must not add KR directly.
function Player_AllScriptDamageProfile(type) {
    switch(round(real(type))){
        case 3:return {hp:0, kr:0, heal:10, max_hp:0, instant:false}; // bright green: editor healing extension
        case 4:return {hp:5, kr:3, heal:0, max_hp:0, instant:false}; // yellow
        case 5:return {hp:0, kr:0, heal:0, max_hp:1, instant:false}; // dark green
        case 6:return {hp:0, kr:0, heal:0, max_hp:0, instant:true};  // pure red
        case 7:return {hp:1,kr:0,heal:0,max_hp:0,instant:false}; // purple occupancy; applied later
        case 8:return {hp:2,kr:1,heal:0,max_hp:0,instant:false}; // deep blue; X can guard the contact
    }
    return {hp:2,kr:1,heal:0,max_hp:0,instant:false}; // white, blue, orange
}

/// The editor may override authored HP damage, while the selected AllScript
/// colour profile keeps its original KR-to-HP ratio.
function Player_DamagePacketForType(type, authored_damage=-1) {
    var profile=Player_AllScriptDamageProfile(type);
    var default_hp=profile.hp;
    var default_kr=profile.kr;
    if(profile.instant) return {hp:Player_GetHpMax(),kr:Player_GetHpMax()};
    var hp_base=authored_damage<0?default_hp:max(0,authored_damage);
    var ratio=default_kr/max(1,default_hp);
    var kr_base=max(0,round(hp_base*ratio));
    return {hp:hp_base,kr:kr_base};
}

/// Applies one old-project-style HP/KR packet.  Player_GetKr stores only the
/// purple overhang, while the Scratch project stores the absolute purple end;
/// converting through total = HP + pending keeps both models equivalent.
function Player_HurtTyped(hp_damage, kr_damage=0, instant=false, cooldown_channel="normal") {
    if(Battle_ShieldAbsorb()) return false;
    var cooldown_field=cooldown_channel=="blue"?"_blue_hurt_cooldown":(cooldown_channel=="orange"?"_orange_hurt_cooldown":"_typed_hurt_cooldown");
    if(instance_exists(battle)&&variable_instance_get(battle,cooldown_field)>0) return false;
    if(instant) {
        Player_ClearPurpleOccupancy(true);
        Player_SetHp(1);
        Player_SetKr(0);
        BattleEditor_NotifyPlayerHurt(max(1,hp_damage));
        if(instance_exists(battle)) variable_instance_set(battle,cooldown_field,6);
        BattleEditor_StartGameOver(battle_soul);
        return true;
    }
    // The source stores HP and KR as two absolute endpoints. Applying DEF to
    // both numbers independently destroys their authored difference: the
    // common 2/1 packet became 1/1 at DEF 10 and therefore produced no purple
    // segment at all. Defend HP once, then scale and preserve the signed gap.
    var authored_hp=max(0,real(hp_damage));
    var authored_kr=max(0,real(kr_damage));
    if(authored_hp>0){
        var effective_hp=Player_CalculateBulletDamage(authored_hp,1);
        var authored_gap=authored_hp-authored_kr;
        var effective_gap=round(authored_gap*effective_hp/max(1,authored_hp));
        if(authored_gap!=0&&effective_gap==0) effective_gap=sign(authored_gap);
        hp_damage=effective_hp;
        kr_damage=max(0,effective_hp-effective_gap);
    }else{
        hp_damage=0;
        kr_damage=Player_CalculateBulletDamage(authored_kr,1);
    }
    if(hp_damage<=0&&kr_damage<=0) return false;
    // Reaching this point means the triggering attack passed its shield,
    // colour condition and cooldown and will really deal damage. Only now may
    // it consume the purple reserve. Adding the same amount to both absolute
    // endpoints makes the reserve direct damage without manufacturing KR.
    var purple_reserved=Player_ClearPurpleOccupancy(true);
    hp_damage+=purple_reserved;
    kr_damage+=purple_reserved;
    if(global.kr){
        var old_hp=max(1,Player_GetHp());
        var old_total=old_hp+max(0,Player_GetKr());
        if(old_hp>1){
            // Ordinary KR-style damage keeps the historical one-HP floor.
            // A consumed purple reserve is different: it may occupy and remove
            // that final point, so a real settlement can reach zero HP.
            var new_hp=purple_reserved>0?max(0,old_hp-hp_damage):max(1,old_hp-hp_damage);
            var new_total=max(0,old_total-kr_damage);
            Player_SetHp(new_hp);
            Player_SetKr(max(0,new_total-new_hp));
            // In AllScript, Kr is an absolute endpoint and the outer damage
            // loop treats Kr <= 0 as death even when the yellow HP endpoint
            // has not reached one first (a heavy indigo/yellow hit can do
            // exactly that).  Do not lose that condition while converting the
            // endpoint into UTEU's visible pending-overhang representation.
            if(new_hp<=0||new_total<=0) BattleEditor_StartGameOver(battle_soul);
        }else{
            // Once yellow HP reaches one, later hits consume the remaining KR
            // instead of adding a fresh purple segment.
            var last_hp_kr=max(hp_damage,kr_damage);
            var last_total=max(0,old_total-last_hp_kr);
            var last_hp=purple_reserved>0?0:1;
            Player_SetHp(last_hp);
            Player_SetKr(max(0,last_total-last_hp));
            if(last_hp<=0||last_total<=0) BattleEditor_StartGameOver(battle_soul);
        }
        BattleEditor_NotifyPlayerHurt(max(1,hp_damage));
    }else{
        Player_Hurt(hp_damage);
        if(Player_GetHp()<=0) BattleEditor_StartGameOver(battle_soul);
    }
    if(instance_exists(battle)) variable_instance_set(battle,cooldown_field,6);
    audio_play_sound(snd_hurt,0,false);
    return true;
}

/// True Knife treats its authored value as one total damage budget. Its purple
/// KR endpoint initially stays where it was before the hit: 100 HP hit for 55
/// therefore becomes 45 HP with a purple endpoint of 100. If the one-HP floor
/// prevents part of the direct loss, that unused part extends the KR endpoint;
/// at 10 HP, 9 is spent on HP and the remaining 46 is added to KR.
function Player_HurtOverflowKr(total_damage, invincibility_frames=30) {
    // True Knives share one lock with each other, but this lock is independent
    // from bones and the other judgement channels, so a knife can overlap a
    // bone without several knives multiplying the same-frame hit.
    if(instance_exists(battle)&&battle._true_knife_hurt_cooldown>0) return false;
    var total=max(0,round(real(total_damage)));
    var inv_frames=max(0,round(real(invincibility_frames)));
    if(total<=0) return false;
    // Twenty-five shield points absorb the whole True Knife packet. A weaker
    // shield is consumed completely and only blocks the matching proportion:
    // 10 shield blocks 10/25, leaving 15/25 of 55 = 33 damage.
    if(Battle_ShieldIsActive()){
        var shield_spent=min(25,Battle_ShieldGet());
        Battle_ShieldAbsorb(shield_spent);
        total=max(0,round(total*(1-shield_spent/25)));
        if(total<=0){
            // A full block still consumes this True-Knife contact window, so
            // several knives touching on the same frame cannot stack shield
            // costs any more than they can stack HP/KR damage.
            if(instance_exists(battle)) battle._true_knife_hurt_cooldown=inv_frames;
            return false;
        }
    }
    // A full shield returned above. Any remaining knife damage is a genuine
    // hit and therefore also releases the purple reserve in this same packet.
    var purple_reserved=Player_ClearPurpleOccupancy(true);
    total+=purple_reserved;
    var old_hp=max(1,Player_GetHp());
    var old_total=old_hp+(global.kr?max(0,Player_GetKr()):0);
    var hp_floor=purple_reserved>0?0:1;
    var hp_damage=min(max(0,old_hp-hp_floor),total);
    var overflow=max(0,total-hp_damage);
    var new_hp=old_hp-hp_damage;
    Player_SetHp(new_hp);
    if(global.kr){
        // Player_GetKr stores only the purple overhang. Preserve the old
        // absolute endpoint while HP falls, then append damage that could not
        // be spent before the one-HP floor.
        var new_total=old_total+overflow;
        Player_SetKr(max(0,new_total-new_hp));
    }
    BattleEditor_NotifyPlayerHurt(total);
    if(instance_exists(battle)) battle._true_knife_hurt_cooldown=inv_frames;
    // True Knife keeps its independent collision channel, so this visual
    // flash does not stop a bone from overlapping the same hit.  It only
    // communicates the knife's own configurable contact lock.
    if(instance_exists(battle_soul)){
        battle_soul._inv=max(battle_soul._inv,inv_frames);
        battle_soul.true_knife_hit_fx=max(battle_soul.true_knife_hit_fx,14);
        battle_soul.true_knife_hit_angle=random(360);
    }
    Camera_Shake(8,6,1,1,true,true,0.8,0.6);
    audio_play_sound(snd_hurt,0,false);
    if(new_hp<=0) BattleEditor_StartGameOver(battle_soul);
    return true;
}

function Player_HurtColor(type, authored_damage=-1, instant=false) {
    type=clamp(round(real(type)),0,8);
    if(type==7) return Player_AddPurpleOccupancy(authored_damage);
    // X is INPUT.CANCEL in the engine. Holding it at the moment a deep-blue
    // contact is judged cancels that contact before shields, cooldowns or the
    // purple reserve are touched.
    if(type==8&&Input_IsHeld(INPUT.CANCEL)) return false;
    if(instant||type==6) return Player_HurtTyped(Player_GetHpMax(),Player_GetHpMax(),true);
    var packet=Player_DamagePacketForType(type,authored_damage);
    var cooldown_channel=type==1?"blue":(type==2?"orange":"normal");
    return Player_HurtTyped(packet.hp,packet.kr,false,cooldown_channel);
}

/// Yellow colour does not imply one fixed mechanic. Configure shootability
/// and heavy damage independently on any battle_bullet descendant.
function Battle_SetYellowBehavior(inst,shootable=true,heavy=false,hp_damage=5,kr_damage=3) {
    if(!instance_exists(inst)) return inst;
    inst.yellow_shootable=shootable;
    inst.yellow_heavy=heavy;
    inst.yellow_hp_damage=max(0,hp_damage);
    inst.yellow_kr_damage=max(0,kr_damage);
    return inst;
}

/// Heals HP while spending part of the item's power to repair max HP.
/// Returns { healed, max_restored, power_spent } for UI/test reporting.
function Player_HealWithMaxHpRecovery(heal_power, max_recovery_ratio=0.25, heal_cost_per_max_hp=1) {
    var heal_value = max(0, heal_power);
    var natural_max = max(Player_GetNaturalHpMax(), Player_GetHpMax());
    var missing_max = max(0, natural_max - Player_GetHpMax());
    var recovery_budget = floor(heal_value * clamp(max_recovery_ratio, 0, 1));
    var restored = min(missing_max, floor(recovery_budget / max(0.0001, heal_cost_per_max_hp)));
    var spent = restored * heal_cost_per_max_hp;
    if(restored > 0) Player_SetHpMax(Player_GetHpMax() + restored);
    var old_hp = Player_GetHp();
    Player_Heal(max(0, heal_value - spent));
    return { healed: Player_GetHp() - old_hp, max_restored: restored, power_spent: spent };
}

function Battle_ShieldConfigure(capacity=100, drain_per_second=35, hud_mode=BATTLE_SHIELD_HUD_MODE.BELOW_HP, enabled=true, recover_per_second=15, recover_delay_seconds=0) {
    if(!instance_exists(battle)) return false;
    battle._shield_enabled = enabled;
    battle._shield_natural_max = max(0, capacity);
    battle._shield_max = battle._shield_natural_max;
    battle._shield = clamp(battle._shield, 0, battle._shield_max);
    if(battle._shield <= 0 && battle._shield_max > 0) battle._shield = battle._shield_max;
    battle._shield_drain_per_second = max(0, drain_per_second);
    battle._shield_recover_per_second = max(0, recover_per_second);
    battle._shield_recover_delay_seconds = max(0, recover_delay_seconds);
    battle._shield_recover_timer = 0;
    battle._shield_hud_mode = hud_mode;
    return true;
}

function Battle_ShieldGetNaturalMax() {
    return instance_exists(battle) ? battle._shield_natural_max : 0;
}

function Battle_ShieldGetMax() {
    return instance_exists(battle) ? battle._shield_max : 0;
}

function Battle_ShieldSetNaturalMax(value) {
    if(!instance_exists(battle)) return false;
    battle._shield_natural_max = max(0, value);
    battle._shield_max = min(battle._shield_max, battle._shield_natural_max);
    battle._shield = min(battle._shield, battle._shield_max);
    return true;
}

function Battle_ShieldSetMax(value) {
    if(!instance_exists(battle)) return false;
    battle._shield_max = clamp(value, 0, battle._shield_natural_max);
    battle._shield = min(battle._shield, battle._shield_max);
    return true;
}

function Battle_ShieldReduceMax(amount) {
    if(!instance_exists(battle)) return 0;
    var old_max = battle._shield_max;
    Battle_ShieldSetMax(old_max - max(0, amount));
    return old_max - battle._shield_max;
}

function Battle_ShieldSet(value) {
    if(!instance_exists(battle)) return false;
    battle._shield = clamp(value, 0, battle._shield_max);
    return true;
}

function Battle_ShieldGet() {
    return instance_exists(battle) ? battle._shield : 0;
}

/// Timeline scrubbing repeatedly reconstructs earlier frames. Runtime objects
/// use this wrapper so those hidden calculations cannot replay their sounds.
/// The seek code briefly enables it only while creating an object exactly on
/// the selected frame; ordinary preview and real gameplay are unaffected.
function BattleEditor_RuntimePlaySound(sound,priority=0,loop=false) {
    var seek_silent=variable_global_exists("battle_editor_seek_audio_silent")&&global.battle_editor_seek_audio_silent;
    var exact_birth=variable_global_exists("battle_editor_seek_audio_exact_birth")&&global.battle_editor_seek_audio_exact_birth;
    if(seek_silent&&!exact_birth) return -1;
    return audio_play_sound(sound,priority,loop);
}

function Battle_ShieldIsActive() {
    return instance_exists(battle) && battle._shield_enabled && battle._shield_active && battle._shield > 0;
}

function Battle_ShieldAbsorb(block_cost=0) {
    var blocked = Battle_ShieldIsActive();
    // The original TurboWarp project uses snd_tempbell on every successful
    // block. snd_ding is byte-for-byte the same WAV, so keep the original
    // rapid repeated sound when an attack remains in contact with the shield.
    // Merely holding C never calls this function and therefore stays silent.
    if(blocked){
        if(block_cost>0) Battle_ShieldSet(Battle_ShieldGet()-block_cost);
        audio_play_sound(snd_ding, 0, false);
    }
    return blocked;
}

function Battle_ShieldUpdate() {
    if(!instance_exists(battle)) return;
    // Use actual elapsed seconds so regeneration does not depend on the
    // project's 120 FPS runner or the engine's logical time scale.
    var step_seconds = clamp(delta_time / 1000000, 0, 0.1);
    var shield_requested = battle._shield_enabled
        && Battle_GetState() == BATTLE_STATE.IN_TURN
        && Input_IsHeld(INPUT.MENU);
    battle._shield_active = shield_requested && battle._shield > 0;
    if(battle._shield_active) {
        battle._shield = max(0, battle._shield - battle._shield_drain_per_second * step_seconds);
        battle._shield_recover_timer = battle._shield_recover_delay_seconds;
    } else if(shield_requested) {
        // Holding C at zero shield must not allow it to recharge-and-flicker.
        battle._shield_recover_timer = battle._shield_recover_delay_seconds;
    } else if(battle._shield_enabled && battle._shield < battle._shield_max) {
        battle._shield_recover_timer = max(0, battle._shield_recover_timer - step_seconds);
        if(battle._shield_recover_timer <= 0) {
            battle._shield = min(battle._shield_max, battle._shield + battle._shield_recover_per_second * step_seconds);
        }
    }
}

function Battle_EnableSurvivalItems(heal_powers=[10, 20, 40], heal_to_full=false) {
    if(!instance_exists(battle)) return false;
    battle._survival_item_enabled = true;
    battle._survival_item_heals = heal_powers;
    battle._survival_item_slot = 0;
    battle._survival_item_full_heal = heal_to_full;
    return true;
}

function Battle_SurvivalItemUpdate() {
    if(!instance_exists(battle) || !battle._survival_item_enabled) return;
    if(Battle_GetState() != BATTLE_STATE.IN_TURN) return;
    if(battle._survival_item_cooldown > 0) {
        battle._survival_item_cooldown -= global.delta_time_factor;
        return;
    }
    if(keyboard_check_pressed(ord("V")) && (battle._survival_item_full_heal || battle._survival_item_slot < array_length(battle._survival_item_heals))) {
        if(battle._survival_item_full_heal){
            var old_hp=Player_GetHp();
            Player_SetHp(Player_GetHpMax());
            Player_SetKr(0);
            battle._survival_item_last_result={healed:Player_GetHp()-old_hp,max_restored:0,power_spent:0};
            battle._survival_item_cooldown=10;
            audio_play_sound(snd_item_heal,0,false);
            return;
        }
        var heal_value = battle._survival_item_heals[battle._survival_item_slot];
        var result = Player_HealWithMaxHpRecovery(heal_value);
        battle._survival_item_last_result = result;
        battle._survival_item_slot += 1;
        battle._survival_item_cooldown = 20;
    }
}

/// Animates position, side lengths, and rotation as one board transition.
function Battle_AnimateBoardRect(cx,cy,up,down,left,right,angle=0,time=24,tween=ANIM_TWEEN.EXPO,ease=ANIM_EASE.IN_OUT) {
    if(!instance_exists(battle_board)) return false;
    Anim_Create(battle_board,"x",tween,ease,battle_board.x,cx-battle_board.x,time);
    Anim_Create(battle_board,"y",tween,ease,battle_board.y,cy-battle_board.y,time);
    Anim_Create(battle_board,"up",tween,ease,battle_board.up,up-battle_board.up,time);
    Anim_Create(battle_board,"down",tween,ease,battle_board.down,down-battle_board.down,time);
    Anim_Create(battle_board,"left",tween,ease,battle_board.left,left-battle_board.left,time);
    Anim_Create(battle_board,"right",tween,ease,battle_board.right,right-battle_board.right,time);
    Anim_Create(battle_board,"angle",tween,ease,battle_board.angle,angle-battle_board.angle,time);
    return true;
}

function Trajectory_Linear(x1, y1, x2, y2, t) {
    return [lerp(x1, x2, t), lerp(y1, y2, t)];
}

function Trajectory_Circle(cx, cy, radius, angle) {
    return [cx + lengthdir_x(radius, angle), cy + lengthdir_y(radius, angle)];
}

function Trajectory_Ellipse(cx, cy, radius_x, radius_y, angle, rotation=0) {
    var lx = lengthdir_x(radius_x, angle);
    var ly = lengthdir_y(radius_y, angle);
    return [cx + lx*dcos(rotation) - ly*dsin(rotation), cy + lx*dsin(rotation) + ly*dcos(rotation)];
}

function Trajectory_Spiral(cx, cy, radius_start, radius_end, turns, t, phase=0) {
    var radius = lerp(radius_start, radius_end, t);
    return Trajectory_Circle(cx, cy, radius, phase + 360*turns*t);
}

function Trajectory_Sine(x1, y1, x2, y2, amplitude, cycles, t, phase=0) {
    var px = lerp(x1, x2, t);
    var py = lerp(y1, y2, t);
    var normal = point_direction(x1, y1, x2, y2) - 90;
    var wave = dsin(phase + 360*cycles*t) * amplitude;
    return [px + lengthdir_x(wave, normal), py + lengthdir_y(wave, normal)];
}

function Trajectory_Lissajous(cx, cy, radius_x, radius_y, freq_x, freq_y, t, phase=0) {
    return [cx + radius_x*dsin(360*freq_x*t + phase), cy + radius_y*dsin(360*freq_y*t)];
}

function Trajectory_Bezier(points, t) {
    var point_count=array_length(points);
    var work=array_create(point_count);
    array_copy(work,0,points,0,point_count);
    for(var level=array_length(work)-1; level>0; level--) {
        for(var i=0; i<level; i++) {
            work[i] = [lerp(work[i][0], work[i+1][0], t), lerp(work[i][1], work[i+1][1], t)];
        }
    }
    return work[0];
}

function Trajectory_Apply(inst, point) {
    if(instance_exists(inst)) {
        inst.x = point[0];
        inst.y = point[1];
        return true;
    }
    return false;
}

/// Creates the slow warning-line family. Visual width breathes, while the hit
/// width is fixed slightly inside the narrowest rendered frame.
function Battle_MakeSlash(x,y,angle,warning_time=48,active_time=72,visual_min_width=10,visual_max_width=26,type=0,warning_width=-1,layer_mode=1) {
    var inst=instance_create_depth(x,y,DEPTH_BATTLE.WARNING,battle_bullet_knife_wave);
    inst.wave_kind=0;
    inst.image_angle=angle;
    inst.warning_time=warning_time;
    inst.active_time=active_time;
    inst.visual_min_width=max(1,visual_min_width);
    inst.visual_max_width=max(inst.visual_min_width,visual_max_width);
    // The authored 10px slash uses a crisp 1.5px warning. Wider/slimmer attacks
    // scale that warning proportionally instead of exposing another unrelated
    // width field.
    inst.warning_width=(warning_width<0)?max(0.5,inst.visual_min_width*0.15):max(0.5,warning_width);
    inst.hit_width=max(1,inst.visual_min_width-inst.hit_inset);
    inst.type=type;
    inst.out=layer_mode;
    return inst;
}

/// Creates the fast true-knife family. The cut itself stays fixed; movement,
/// rotation and curves apply only to the released wave.
function Battle_MakeTrueKnife(x,y,angle,cut_time=12,active_time=18,visual_min_width=7,visual_max_width=40,type=0,layer_mode=1,invincibility_frames=30,damage=55) {
    var inst=Battle_MakeSlash(x,y,angle,cut_time,active_time,visual_min_width,visual_max_width,type,-1,layer_mode);
    inst.wave_kind=1;
    inst.hp_damage=max(0,damage);
    inst.kr_damage=0;
    inst.invincibility_frames=max(0,round(invincibility_frames));
    inst.breath_speed=30;
    return inst;
}

/// Configures either the warning path or the post-fire path. Negative starting
/// speed naturally produces the requested reverse-then-accelerate movement.
function Battle_WaveSetMotion(inst,direction,speed,acceleration=0,rotation_speed=0,curve_speed=0,during_warning=false) {
    if(!instance_exists(inst)) return noone;
    if(during_warning){
        inst.pre_direction=direction;
        inst.pre_speed=speed;
        inst.pre_acceleration=acceleration;
        inst.pre_rotation_speed=rotation_speed;
        inst.pre_curve_speed=curve_speed;
    }else{
        inst.post_direction=direction;
        inst.post_speed=speed;
        inst.post_acceleration=acceleration;
        inst.post_rotation_speed=rotation_speed;
        inst.post_curve_speed=curve_speed;
    }
    return inst;
}

/// Rotation is deliberately exclusive per phase: 0 none, 1 continuous speed,
/// 2 curve to a target angle. This keeps the editor from applying both models
/// to the same warning/post-fire phase at once.
function Battle_WaveSetRotation(inst,during_warning,mode=0,target_angle=0,duration=30,tween=ANIM_TWEEN.SINE,ease=ANIM_EASE.IN_OUT) {
    if(!instance_exists(inst)) return noone;
    mode=clamp(round(mode),0,2);
    if(during_warning){
        inst.pre_rotation_mode=mode;
        inst.pre_rotation_target=target_angle;
        inst.pre_rotation_time=max(1,duration);
        inst.pre_rotation_tween=tween;
        inst.pre_rotation_ease=ease;
        inst.pre_angle_from=inst.image_angle;
    }else{
        inst.post_rotation_mode=mode;
        inst.post_rotation_target=target_angle;
        inst.post_rotation_time=max(1,duration);
        inst.post_rotation_tween=tween;
        inst.post_rotation_ease=ease;
        inst.post_angle_from=inst.image_angle;
    }
    return inst;
}

function Battle_WaveSetHitInset(inst,inset=1.5) {
    if(!instance_exists(inst)) return noone;
    inst.hit_inset=max(0,inset);
    inst.hit_width=max(1,inst.visual_min_width-inst.hit_inset);
    return inst;
}

/// Stable wide-line renderer. draw_line_width can disappear or break at large
/// lengths on some Windows GPU drivers; a four-vertex strip stays visible.
function Battle_DrawStrip(cx,cy,angle,half_length,width,color,alpha=1) {
    if(width<=0||alpha<=0) return false;
    var fx=lengthdir_x(half_length,angle);
    var fy=lengthdir_y(half_length,angle);
    var nx=lengthdir_x(width*0.5,angle-90);
    var ny=lengthdir_y(width*0.5,angle-90);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_color(cx-fx+nx,cy-fy+ny,color,alpha);
    draw_vertex_color(cx-fx-nx,cy-fy-ny,color,alpha);
    draw_vertex_color(cx+fx+nx,cy+fy+ny,color,alpha);
    draw_vertex_color(cx+fx-nx,cy+fy-ny,color,alpha);
    draw_primitive_end();
    return true;
}
