function Battle_IsBoardTransforming() {
	var shape_morphing=instance_exists(battle_board)&&is_struct(battle_board.mainboard)&&!battle_board.mainboard._destroyed
		&&variable_struct_exists(battle_board.mainboard,"editor_morphing")&&battle_board.mainboard.editor_morphing;
	return (shape_morphing || Anim_IsExists(battle_board,"up") || Anim_IsExists(battle_board,"down") || Anim_IsExists(battle_board,"left") || Anim_IsExists(battle_board,"right") || Anim_IsExists(battle_board,"x") || Anim_IsExists(battle_board,"y") || Anim_IsExists(battle_board,"angle"));


}
