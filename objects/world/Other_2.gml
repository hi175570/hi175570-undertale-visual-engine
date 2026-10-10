Anim_Init();

Shop_Init()


Input_Init();
// This is a keyboard-controlled game, so Windows IME composition/candidate
// overlays must not appear in a corner when the user's active layout is Chinese.
if(os_type==os_windows){
	keyboard_virtual_hide();
	keyboard_string="";
}
Input_Bind(INPUT.CONFIRM,INPUT_TYPE.KEYBOARD,0,vk_enter);
Input_Bind(INPUT.CONFIRM,INPUT_TYPE.KEYBOARD,0,ord("Z"));
Input_Bind(INPUT.CANCEL,INPUT_TYPE.KEYBOARD,0,vk_shift);
Input_Bind(INPUT.CANCEL,INPUT_TYPE.KEYBOARD,0,ord("X"));
Input_Bind(INPUT.MENU,INPUT_TYPE.KEYBOARD,0,vk_control);
Input_Bind(INPUT.MENU,INPUT_TYPE.KEYBOARD,0,ord("C"));
Input_Bind(INPUT.UP,INPUT_TYPE.KEYBOARD,0,vk_up);
Input_Bind(INPUT.DOWN,INPUT_TYPE.KEYBOARD,0,vk_down);
Input_Bind(INPUT.LEFT,INPUT_TYPE.KEYBOARD,0,vk_left);
Input_Bind(INPUT.RIGHT,INPUT_TYPE.KEYBOARD,0,vk_right);
Item_Init();

Storage_Init();
var settings_storage=Storage_GetSettings();
if(settings_storage.IsFileExists()) settings_storage.LoadFromFile();
var settings_general=settings_storage.Get("general");
global.show_fps=settings_general.Get(FLAG_SETTINGS_SHOW_FPS,false);
global.window_scale=settings_general.Get("window_scale",1);
var window_scale_options=Window_ScaleOptions(),window_scale_valid=false;
for(var scale_i=0;scale_i<array_length(window_scale_options);scale_i++) if(global.window_scale==window_scale_options[scale_i]) window_scale_valid=true;
if(!window_scale_valid) global.window_scale=1;

Encounter_Init();

BGM_Init();

Dialog_Init();

Demo_Init();

instance_create_depth(0,0,0,camera);
instance_create_depth(0,0,0,fader);
instance_create_depth(0,0,0,border);
instance_create_depth(0,0,0,closed_captions);
if(!instance_exists(game_cursor)) instance_create_depth(0,0,-1000000,game_cursor);

application_surface_draw_enable(false);

// Keep the original Undertale 640x480 (4:3) presentation.
Border_SetEnabled(false,false);





randomize();

room_goto_next();
