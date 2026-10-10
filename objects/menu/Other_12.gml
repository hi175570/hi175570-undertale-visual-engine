///@desc Update Menu 0 Text Color
_change_inst=_inst_begin;
_change_color=(_choice==0 ? c_yellow : c_white);
event_user(1);
_change_inst=_inst_settings;
_change_color=(_choice==1 ? c_yellow : c_white);
event_user(1);
_change_inst=_inst_exit;
_change_color=(_choice==2 ? c_yellow : c_white);
event_user(1);
_selector_target_y=128+30*_choice;
