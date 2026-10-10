event_inherited();

if (Battle_GetState() == BATTLE_STATE.IN_TURN && moveable) {
    if (Input_IsHeld(INPUT.UP) && Input_IsHeld(INPUT.RIGHT))
        dir = 45;
    else if (Input_IsHeld(INPUT.UP) && Input_IsHeld(INPUT.LEFT))
        dir = 135;
    else if (Input_IsHeld(INPUT.DOWN) && Input_IsHeld(INPUT.LEFT))
        dir = 225;
    else if (Input_IsHeld(INPUT.DOWN) && Input_IsHeld(INPUT.RIGHT))
        dir = -45;
    else if Input_IsHeld(INPUT.DOWN)
		dir = -90;
    else if Input_IsHeld(INPUT.UP)
		dir = 90;
    else if Input_IsHeld(INPUT.LEFT)
		dir = 180;
    else if Input_IsHeld(INPUT.RIGHT)
		dir = 0;

    var SPD = Player_GetSpdTotal()
    var SPD = (Input_IsHeld(INPUT.CANCEL) ? SPD / 2 : SPD);
    repeat(SPD * 15) {
        if ((!(position_meeting(x, (y - (sprite_height / 2)), block))) && (!(position_meeting(x, (y + (sprite_height / 2)), block))) && (!(position_meeting((x - (sprite_width / 2)), y, block))) && (!(position_meeting((x + (sprite_width / 2)), y, block)))) {
            x += lengthdir_x(0.1*global.delta_time_factor, dir)
            y += lengthdir_y(0.1*global.delta_time_factor, dir)
        }
    }
}
