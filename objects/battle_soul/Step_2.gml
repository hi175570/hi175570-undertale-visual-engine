if (Player_GetHp() <= 0) {
    BattleEditor_StartGameOver(id);
    exit;
}
var STATE = Battle_GetState();
if (STATE == BATTLE_STATE.TURN_PREPARATION || STATE == BATTLE_STATE.IN_TURN) {
    var isInside = [array_create(4, false), array_create(4, false)];
    var limit_index = array_create(4, 0);
    var distance = -1;
    var boardcount = array_length(global.boards_array);
    for (var i = 0; i < boardcount; i++) { //遍历所有框,判断是否出框
        global.boards_array[i].isCollide[0] = global.boards_array[i].contains(x - sprite_width / 2, y);
        global.boards_array[i].isCollide[1] = global.boards_array[i].contains(x + sprite_width / 2, y);
        global.boards_array[i].isCollide[2] = global.boards_array[i].contains(x, y - sprite_height / 2);
        global.boards_array[i].isCollide[3] = global.boards_array[i].contains(x, y + sprite_height / 2);
        if (global.boards_array[i].isCollide[0]) {
            if (!global.boards_array[i].cover) isInside[1][0] = false;
            else if (!isInside[1][0]) limit_index[0] = i;
            isInside[global.boards_array[i].cover][0] = true;
        }
        if (global.boards_array[i].isCollide[1]) {
            if (!global.boards_array[i].cover) isInside[1][1] = false;
            else if (!isInside[1][1]) limit_index[1] = i;
            isInside[global.boards_array[i].cover][1] = true;
        }
        if (global.boards_array[i].isCollide[2]) {
            if (!global.boards_array[i].cover) isInside[1][2] = false;
            else if (!isInside[1][2]) limit_index[2] = i;
            isInside[global.boards_array[i].cover][2] = true;
        }
        if (global.boards_array[i].isCollide[3]) {
            if (!global.boards_array[i].cover) isInside[1][3] = false;
            else if (!isInside[1][3]) limit_index[3] = i;
            isInside[global.boards_array[i].cover][3] = true;
        }
    }

    if (isInside[1][0]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = limit_index[0]; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (global.boards_array[i].cover && !global.boards_array[i].isCollide[0]) continue;
            var pos = global.boards_array[i].limit(x - sprite_width / 2, y);
            var dis = point_distance(x - sprite_width / 2, y, pos[0], pos[1]);
            if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                nearestPos = pos;
                nearestDis = dis;
            }

        }
        if(is_array(nearestPos)){
            x = nearestPos[0] + sprite_width / 2;
            y = nearestPos[1];
            distance = nearestDis;
        }
    }

    if (isInside[1][1]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = limit_index[1]; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (global.boards_array[i].cover && !global.boards_array[i].isCollide[1]) continue;
            var pos = global.boards_array[i].limit(x + sprite_width / 2, y);
            var dis = point_distance(x + sprite_width / 2, y, pos[0], pos[1]);

            if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                nearestPos = pos;
                nearestDis = dis;
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0] - sprite_width / 2;
            y = nearestPos[1];
            distance = nearestDis;
        }
    }

    if (isInside[1][2]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = limit_index[2]; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (global.boards_array[i].cover && !global.boards_array[i].isCollide[2]) continue;
            var pos = global.boards_array[i].limit(x, y - sprite_height / 2);
            var dis = point_distance(x, y - sprite_height / 2, pos[0], pos[1]);
            if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                nearestPos = pos;
                nearestDis = dis;
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0];
            y = nearestPos[1] + sprite_height / 2;
            distance = nearestDis;
        }
    }

    if (isInside[1][3]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = limit_index[3]; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (global.boards_array[i].cover && !global.boards_array[i].isCollide[3]) continue;
            var pos = global.boards_array[i].limit(x, y + sprite_height / 2);
            var dis = point_distance(x, y + sprite_height / 2, pos[0], pos[1]);

            if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                nearestPos = pos;
                nearestDis = dis;
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0];
            y = nearestPos[1] - sprite_height / 2;
        }
    }

    distance = -1;
    if (!isInside[0][0]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = 0; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (!global.boards_array[i].cover) {
                var pos = global.boards_array[i].limit(x - sprite_width / 2, y);
                var dis = point_distance(x - sprite_width / 2, y, pos[0], pos[1]);

                if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                    nearestPos = pos;
                    nearestDis = dis;
                }
            }
        }
        if(is_array(nearestPos)){
            x = nearestPos[0] + sprite_width / 2;
            y = nearestPos[1];
            distance = nearestDis;
        }
    }

    if (!isInside[0][1]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = 0; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (!global.boards_array[i].cover) {
                var pos = global.boards_array[i].limit(x + sprite_width / 2, y);
                var dis = point_distance(x + sprite_width / 2, y, pos[0], pos[1]);

                if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                    nearestPos = pos;
                    nearestDis = dis;
                }
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0] - sprite_width / 2;
            y = nearestPos[1];
            distance = nearestDis;
        }

    }

    if (!isInside[0][2]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = 0; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (!global.boards_array[i].cover) {
                var pos = global.boards_array[i].limit(x, y - sprite_height / 2);
                var dis = point_distance(x, y - sprite_height / 2, pos[0], pos[1]);

                if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                    nearestPos = pos;
                    nearestDis = dis;
                }
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0];
            y = nearestPos[1] + sprite_height / 2;
            distance = nearestDis;
        }
    }

    if (!isInside[0][3]) {
        var nearestPos=undefined, nearestDis = -1; // 最近位置和最近距离
        for (var i = 0; i < boardcount; i++) { // 遍历所有框
            // 得到限制位置和距离
            if (!global.boards_array[i].cover) {
                var pos = global.boards_array[i].limit(x, y + sprite_height / 2);
                var dis = point_distance(x, y + sprite_height / 2, pos[0], pos[1]);

                if (dis < nearestDis || nearestDis == -1) { // 如果比其他更近
                    nearestPos = pos;
                    nearestDis = dis;
                }
            }
        }
        if (is_array(nearestPos)&&(distance <= nearestDis||distance<0)) {
            x = nearestPos[0];
            y = nearestPos[1] - sprite_height / 2;
        }
    }

}

// Blue/orange hazards use the player's input state, not the previous frame's
// position.  Position deltas misclassify held input while blocked by a wall,
// gravity-only motion, teleports and the frame on which a key is released.
global.moving = Battle_GetState() == BATTLE_STATE.IN_TURN && moveable
    && (Input_IsHeld(INPUT.UP) || Input_IsHeld(INPUT.DOWN)
        || Input_IsHeld(INPUT.LEFT) || Input_IsHeld(INPUT.RIGHT));
