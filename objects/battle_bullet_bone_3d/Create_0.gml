enum SHAPE {
    CUBE = 0,
    REGULAR_TETRAHEDRON = 1,
    REGULAR_OCTAHEDRON = 2,
    REGULAR_DODECAHEDRON = 3,
    REGULAR_ICOSAHEDRON = 4,
    TESSERACT = 5,
    SQUARE_PYRAMID = 6
}

event_inherited();

depth = DEPTH_BATTLE.BULLET_OUTSIDE_LOW;
enable = 0;
vert_list = [];          // 创建一个空数组
vert_list_draw = [];    // 创建一个空数组
edge_list = [];         // 创建一个空数组
anglex = 0;
angley = 0;
anglez = 0;
angxs = 0;
angys = 0;
angzs = 0;
scalex = 0;
scaley = 0;
scalez = 0;
scalew = 0;
world_z = 0;
anglexw = 0;
angleyw = 0;
anglezw = 0;
angxws = 0;
angyws = 0;
angzws = 0;
perspective3d = true;
perspective4d = true;
perspective_distance = 420;
perspective4d_distance = 260;
shape = 0;
out = 0;
type = 0;
gap = 40;
edge_trim = 8;
editor_damage_enabled = false;
hp_damage = 2;
heal_amount = 10;
editor_visual_override = false;
editor_visual_color = c_white;
_solid_lifetime_age = 0;

#region
add_vert = function(argument0, argument1, argument2, argument3) { // 添加顶点坐标
    if (argument3 == undefined)
        argument3 = vert_list; // 默认使用 vert_list

    var _prop = [argument0, argument1, argument2]; // 创建顶点数组
    array_push(argument3, _prop); // 将顶点数组添加到指定的顶点列表
    return;
}

add_vert4 = function(argument0, argument1, argument2, argument3, argument4) {
    if (argument4 == undefined) argument4 = vert_list;
    array_push(argument4, [argument0, argument1, argument2, argument3]);
}

update_vert = function() {
    vert_list_draw = []; // 清空 vert_list_draw
    for (var i = 0; i < array_length(vert_list); i++) {
        var _prop = vert_list[i];
        var X = _prop[0];
        var Y = _prop[1];
        var Z = _prop[2];
        var W = array_length(_prop)>3 ? _prop[3] : 0;

        X *= scalex;
        Y *= scaley;
        Z *= scalez;
        W *= scalew;

        // Additional 4D plane rotations. XYZ rotations remain below and are
        // shared by both 3D and projected 4D shapes.
        if(array_length(_prop)>3){
            var XX4=(X*dcos(anglexw))-(W*dsin(anglexw));
            var WW4=(X*dsin(anglexw))+(W*dcos(anglexw));
            X=XX4;
            W=WW4;
            var YY4=(Y*dcos(angleyw))-(W*dsin(angleyw));
            WW4=(Y*dsin(angleyw))+(W*dcos(angleyw));
            Y=YY4;
            W=WW4;
            var ZZ4=(Z*dcos(anglezw))-(W*dsin(anglezw));
            WW4=(Z*dsin(anglezw))+(W*dcos(anglezw));
            Z=ZZ4;
            W=WW4;
        }

        var YY = ((Y * dcos(anglex)) - (Z * dsin(anglex)));
        var ZZ = ((Y * dsin(anglex)) + (Z * dcos(anglex)));
        Y = YY;
        Z = ZZ;

        ZZ = ((Z * dcos(angley)) - (X * dsin(angley)));
        var XX = ((Z * dsin(angley)) + (X * dcos(angley)));
        Z = ZZ;
        X = XX;

        XX = ((X * dcos(anglez)) - (Y * dsin(anglez)));
        YY = ((X * dsin(anglez)) + (Y * dcos(anglez)));
        X = XX;
        Y = YY;

        if(array_length(_prop)>3 && perspective4d){
            var factor4=perspective4d_distance/max(8,perspective4d_distance+W);
            X*=factor4;
            Y*=factor4;
            Z*=factor4;
        }

        self.add_vert(X, Y, Z, vert_list_draw);
    }
    return;
}

add_edge = function(argument0, argument1) { // 用一根普通骨头连接两个投影端点
    // The controller itself never draws a 3D model. Every visible edge is an
    // ordinary battle bone whose position, angle and length are updated each
    // frame. Spawn it on-screen so no outside-room behaviour can discard it
    // before its first projected update.
    var _bone = Battle_MakeBone(x, y, 16, 0, 0, type, out, 0, 0, 0, -1);
    _bone.visible = true;
    var _prop = [argument0, argument1, _bone];
    array_push(edge_list, _prop); // 将边压入 edge_list
    return;
}
#endregion
