///@desc Menu Switch
if (_menu == 0) {
    var s = Storage_GetInfo();
    _mode = s.IsFileExists();
    _inst_begin = instance_create_depth(144, 120, 0, text_typer);
    // The initial selection is Start, so it must already be yellow before the
    // first input event rebuilds the menu colors.
    _inst_begin.text = _prefix + "{font 0}{color `yellow`}开始";
    _inst_settings = instance_create_depth(144, 150, 0, text_typer);
    _inst_settings.text = _prefix + "{font 0}{color `white`}设置";
    _inst_exit = instance_create_depth(144, 180, 0, text_typer);
    _inst_exit.text = _prefix + "{font 0}{color `white`}退出";
    with(text_typer) event_user(15);
    event_user(2);
} else {
    if (instance_exists(_inst_instruction)) instance_destroy(_inst_instruction);
    if (instance_exists(_inst_begin)) instance_destroy(_inst_begin);
    if (instance_exists(_inst_settings)) instance_destroy(_inst_settings);
    if (instance_exists(_inst_exit)) instance_destroy(_inst_exit);
    if (instance_exists(_inst_name)) instance_destroy(_inst_name);
    if (instance_exists(_inst_lv)) instance_destroy(_inst_lv);
    if (instance_exists(_inst_time)) instance_destroy(_inst_time);
    if (instance_exists(_inst_room)) instance_destroy(_inst_room);
    if (instance_exists(_inst_continue)) instance_destroy(_inst_continue);
    if (instance_exists(_inst_reset)) instance_destroy(_inst_reset);
}

if (_menu == 1) {
    _inst_naming_title = instance_create_depth(90, 30, 0, text_typer);
    _inst_naming_title.text = _prefix + "{color `white`}Name the fallen human.";
    _inst_naming_letters = instance_create_depth(60, 76, 0, text_typer);
    _inst_naming_letters.text = _prefix + "{font 0}{effect 0}{space_x 24}{space_y -2}ABCDEFG&HIJKLMN&OPQRSTU&VWXYZ{space_y -7}&&{space_y -2}abcdefg&hijklmn&opqrstu&vwxyz";
    _inst_naming_quit = instance_create_depth(60, 200, 0, text_typer);
    _inst_naming_quit.text = _prefix + "Quit";
    _inst_naming_backspace = instance_create_depth(120, 200, 0, text_typer);
    _inst_naming_backspace.text = _prefix + "Backspace";
    _inst_naming_done = instance_create_depth(220, 200, 0, text_typer);
    _inst_naming_done.text = _prefix + "Done";
    with(text_typer) {
        event_user(15);
    }
    event_user(3);
} else {
    if (instance_exists(_inst_naming_title)) instance_destroy(_inst_naming_title);
    if (instance_exists(_inst_naming_letters)) instance_destroy(_inst_naming_letters);
    if (instance_exists(_inst_naming_quit)) instance_destroy(_inst_naming_quit);
    if (instance_exists(_inst_naming_backspace)) instance_destroy(_inst_naming_backspace);
    if (instance_exists(_inst_naming_done)) instance_destroy(_inst_naming_done);
}

if (_menu == 2) {
    _inst_confirm_title = instance_create_depth(90, 30, 0, text_typer);
    _inst_confirm_title.text = _prefix + _confirm_title;
    _inst_confirm_no = instance_create_depth(73, 200, 0, text_typer);
    _inst_confirm_no.text = _prefix + "No";
    _inst_confirm_yes = instance_create_depth(230, 200, 0, text_typer);
    _inst_confirm_yes.text = _prefix + "Yes";
    _confirm_name_x = 280;
    _confirm_name_y = 110;
    _confirm_name_scale = 2;
    Anim_Destroy(id, "_confirm_name_x");
    Anim_Destroy(id, "_confirm_name_y");
    Anim_Destroy(id, "_confirm_name_scale");
    Anim_Create(id, "_confirm_name_x", 0, 0, 280, -80, 270);
    Anim_Create(id, "_confirm_name_y", 0, 0, 110, 120, 270);
    Anim_Create(id, "_confirm_name_scale", 0, 0, 2, 5, 270);
    _choice_confirm = 0;
    with(text_typer) {
        event_user(15);
    }
    event_user(5);
} else {
    if (instance_exists(_inst_confirm_title)) instance_destroy(_inst_confirm_title);
    if (instance_exists(_inst_confirm_no)) instance_destroy(_inst_confirm_no);
    if (instance_exists(_inst_confirm_yes)) instance_destroy(_inst_confirm_yes);
}

if (_menu == 3) {
    fader.color = c_white;
    Fader_Fade(-1, 1, 240);
    alarm[0] = 240 / global.delta_time_factor;
}
