event_inherited();

global.moving = Battle_GetState() == BATTLE_STATE.IN_TURN && moveable
    && (Input_IsHeld(INPUT.UP) || Input_IsHeld(INPUT.DOWN)
        || Input_IsHeld(INPUT.LEFT) || Input_IsHeld(INPUT.RIGHT));
