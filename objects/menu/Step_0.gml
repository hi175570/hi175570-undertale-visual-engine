// The persistent start-menu room must never receive a confirm press while the
// battle editor owns the screen (especially when Enter finishes text input).
if(instance_exists(battle_editor)) exit;

if (_menu == 0) {
    var _editor_room=asset_get_index("room_battle_editor");
    if(_editor_room>=0){
        if(keyboard_check(ord("E"))){
            _editor_hold_us+=delta_time;
            if(!_editor_hold_triggered&&_editor_hold_us>=1000000){
                _editor_hold_triggered=true;
                Storage_GetTempGeneral().Set(FLAG_TEMP_ENCOUNTER,0);
                Storage_GetTempGeneral().Set(FLAG_TEMP_BATTLE_ROOM_RETURN,room);
                room_persistent=true;
				display_set_gui_size(640,480);
				if(surface_exists(application_surface)) surface_resize(application_surface,640,480);
                room_goto(_editor_room);
                exit;
            }
        }else{
            _editor_hold_us=0;
            _editor_hold_triggered=false;
        }
    }
    _selector_y=lerp(_selector_y,_selector_target_y,0.28);
    if(abs(_selector_y-_selector_target_y)<0.1) _selector_y=_selector_target_y;
    if (Input_IsPressed(INPUT.DOWN)) {
        _choice=min(_choice+1,2);
        event_user(2);
    } else if (Input_IsPressed(INPUT.UP)) {
        _choice=max(_choice-1,0);
        event_user(2);
    } else if (Input_IsPressed(INPUT.CONFIRM)) {
        if (_choice == 0) {
            Storage_GetStatic().ClearData();
            var sDynamic=Storage_GetDynamic();
            sDynamic.ClearData();
            sDynamic.LoadFromFile();
            Player_CustomInitialData();
            Player_SetName("hi175570");
            Encounter_Start(0,true,false);
        } else if (_choice == 1) {
            room_goto(room_settings);
        } else {
            game_end();
        }
    }
} else if (_menu == 1) {
    if (_choice_naming == 0) {
        if (Input_IsPressed(INPUT.RIGHT)) {
            if (_choice_naming_letter < 51) {
                _choice_naming_letter += 1;
                event_user(3);
            }
        } else if (Input_IsPressed(INPUT.LEFT)) {
            if (_choice_naming_letter > 0) {
                _choice_naming_letter -= 1;
                event_user(3);
            }
        } else if (Input_IsPressed(INPUT.UP)) {
            if (_choice_naming_letter >= 0 && _choice_naming_letter <= 1) {
                _choice_naming = 1;
                _choice_naming_command = 0;
            } else if (_choice_naming_letter >= 2 && _choice_naming_letter <= 4) {
                _choice_naming = 1;
                _choice_naming_command = 1;
            } else if (_choice_naming_letter >= 5 && _choice_naming_letter <= 6) {
                _choice_naming = 1;
                _choice_naming_command = 2;
            } else if (_choice_naming_letter >= 26 && _choice_naming_letter <= 30) {
                _choice_naming_letter -= 5;
            } else if (_choice_naming_letter >= 31 && _choice_naming_letter <= 32) {
                _choice_naming_letter -= 12;
            } else {
                _choice_naming_letter -= 7;
            }
            event_user(3);
        } else if (Input_IsPressed(INPUT.DOWN)) {
            if (_choice_naming_letter >= 21 && _choice_naming_letter <= 25) {
                _choice_naming_letter += 5;
            } else if (_choice_naming_letter >= 19 && _choice_naming_letter <= 20) {
                _choice_naming_letter += 12;
            } else if (_choice_naming_letter >= 45 && _choice_naming_letter <= 46) {
                _choice_naming = 1;
                _choice_naming_command = 2;
            } else if (_choice_naming_letter >= 47 && _choice_naming_letter <= 48) {
                _choice_naming = 1;
                _choice_naming_command = 0;
            } else if (_choice_naming_letter >= 49 && _choice_naming_letter <= 51) {
                _choice_naming = 1;
                _choice_naming_command = 1;
            } else {
                _choice_naming_letter += 7;
            }
            event_user(3);
        } else if (Input_IsPressed(INPUT.CONFIRM)) {
            if (string_length(_naming_name) < 6) {
                var inst = _inst_naming_letters._char_data_list[_choice_naming_letter];
                _naming_name += inst.text;
            }
        } else if (Input_IsPressed(INPUT.CANCEL)) {
            if (string_length(_naming_name) > 0) {
                _naming_name = string_delete(_naming_name, string_length(_naming_name), 1);
            }
        }
    } else {
        if (Input_IsPressed(INPUT.RIGHT)) {
            if (_choice_naming_command < 2) {
                _choice_naming_command += 1;
                event_user(3);
            }
        } else if (Input_IsPressed(INPUT.LEFT)) {
            if (_choice_naming_command > 0) {
                _choice_naming_command -= 1;
                event_user(3);
            }
        } else if (Input_IsPressed(INPUT.UP)) {
            if (_choice_naming_command == 0) {
                _choice_naming = 0;
                _choice_naming_letter = 47;
            } else if (_choice_naming_command == 1) {
                _choice_naming = 0;
                _choice_naming_letter = 49;
            } else if (_choice_naming_command == 2) {
                _choice_naming = 0;
                _choice_naming_letter = 45;
            }
            event_user(3);
        } else if (Input_IsPressed(INPUT.DOWN)) {
            if (_choice_naming_command == 0) {
                _choice_naming = 0;
                _choice_naming_letter = 0;
            } else if (_choice_naming_command == 1) {
                _choice_naming = 0;
                _choice_naming_letter = 2;
            } else if (_choice_naming_command == 2) {
                _choice_naming = 0;
                _choice_naming_letter = 5;
            }
            event_user(3);
        } else if (Input_IsPressed(INPUT.CONFIRM)) {
            if (_choice_naming_command == 0) {
                _menu = 0;
                event_user(0);
            }
            if (_choice_naming_command == 1) {
                if (string_length(_naming_name) > 0) {
                    _naming_name = string_delete(_naming_name, string_length(_naming_name), 1);
                }
            }
            if (_choice_naming_command == 2) {
                if (_naming_name != "") {
                    event_user(4);
                    _menu = 2;
                    event_user(0);
                }
            }
        } else if (Input_IsPressed(INPUT.CANCEL)) {
            if (string_length(_naming_name) > 0) {
                _naming_name = string_delete(_naming_name, string_length(_naming_name), 1);
            }
        }
    }
} else if (_menu == 2) {
    if (Input_IsPressed(INPUT.LEFT)) {
        if (_choice_confirm > 0) {
            _choice_confirm = 0;
            event_user(5);
        }
    } else if (Input_IsPressed(INPUT.RIGHT)) {
        if (_choice_confirm < 1 && _confirm_valid) {
            _choice_confirm = 1;
            event_user(5);
        }
    } else if (Input_IsPressed(INPUT.CONFIRM)) {
        if (_choice_confirm == 0) {
            _menu = (_mode == 0 ? 1 : 0);
            event_user(0);
        } else {
            _menu = 3;
            event_user(0);
        }
    }
}

if (_menu == 2 || _menu == 3) {
    if (_confirm_name_update) {
        _confirm_name_offset_x = random_range( - 1, 1);
        _confirm_name_offset_y = random_range( - 1, 1);
        _confirm_name_angle = random_range( - 1, 1);
    }
    _confirm_name_update = !_confirm_name_update;
}
