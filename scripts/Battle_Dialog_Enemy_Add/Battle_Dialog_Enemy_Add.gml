function Battle_Dialog_Enemy_Add(x, y, depth=-1000, text, template=0, requires_confirm=true) {
    var inst = instance_create_depth(x, y, depth, battle_dialog_enemy);
	inst.text = TextTyper_NormalizeSupplementaryUnicode(text);
	inst.template=template;
	inst.requires_confirm=requires_confirm;
    return inst;
}
