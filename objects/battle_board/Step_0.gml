if (!is_struct(mainboard) || mainboard._destroyed) {
    mainboard = Battle_CreateBoardRect(x, y, 65, 65, 283, 283);
    custom_mainboard = false;
}
if(!custom_mainboard){
    // A rectangular main frame normally mirrors battle_board's legacy scalar
    // fields. During an editor/runtime script, however, Control Object writes
    // the preview struct itself. Mirroring the old scalar angle back on the
    // following Step made a completed rotation visibly snap to zero (and did
    // the same to scripted position changes). While that preview is actively
    // playing or intentionally frozen, commit its pose to the legacy owner so
    // both representations keep the same final state.
    var runtime_owns_mainboard=false;
    if(struct_exists(mainboard,"editor_preview_board")&&mainboard.editor_preview_board
    &&struct_exists(mainboard,"editor_preview_owner")&&instance_exists(mainboard.editor_preview_owner)){
        var preview_owner=mainboard.editor_preview_owner;
        runtime_owns_mainboard=(variable_instance_exists(preview_owner,"playing")&&preview_owner.playing)
            ||(variable_instance_exists(preview_owner,"timeline_half_play")&&preview_owner.timeline_half_play)
            ||(variable_instance_exists(preview_owner,"preserve_paused_board")&&preview_owner.preserve_paused_board);
    }
    if(runtime_owns_mainboard){
        x=mainboard.x;
        y=mainboard.y;
        angle=mainboard.angle;
        left=mainboard.left;
        right=mainboard.right;
        up=mainboard.up;
        down=mainboard.down;
    }else{
        mainboard.x = x;
        mainboard.y = y;
        mainboard.angle = angle;
        mainboard.left = left;
        mainboard.right = right;
        mainboard.up = up;
        mainboard.down = down;
    }
}

for (var i = array_length(global.boards_controller_array) - 1; i >= 0; i--) {
	var controller = global.boards_controller_array[i];
	if (!is_struct(controller) || controller._destroyed) {
		array_delete(global.boards_controller_array, i, 1);
		continue;
	}
	controller.update();
}

for (var i = array_length(global.boards_array) - 1; i >= 0; i--) {
	var board = global.boards_array[i];
	if (!is_struct(board) || board._destroyed) {
		array_delete(global.boards_array, i, 1);
		continue;
	}
	board.update();
}

// Depth/order almost never changes, especially while authoring. Avoid invoking
// GameMaker's callback sort every Step when the current order is identical.
var next_sort_signature=string(array_length(global.boards_array));
for(var sort_index=0;sort_index<array_length(global.boards_array);sort_index++){
    var sort_board=global.boards_array[sort_index];
    next_sort_signature+="|"+string(sort_board.board_number)+":"+string(sort_board.board_depth);
}
if(next_sort_signature!=_board_sort_signature){
    array_sort(global.boards_array, func_boardsort);
    _board_sort_signature=string(array_length(global.boards_array));
    for(var sorted_index=0;sorted_index<array_length(global.boards_array);sorted_index++){
        var sorted_board=global.boards_array[sorted_index];
        _board_sort_signature+="|"+string(sorted_board.board_number)+":"+string(sorted_board.board_depth);
    }
}
