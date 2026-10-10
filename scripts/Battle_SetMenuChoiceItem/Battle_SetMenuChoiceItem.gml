function Battle_SetMenuChoiceItem(slot, call = true) {
    var items = Item_GetInventoryItems();
    var count = items.GetCount();
    if (slot < count) {
        battle._menu_choice_item = slot;
        while (slot >= battle._menu_choice_item_first + 3) {
            battle._menu_choice_item_first += 1;
        }
        while (slot < battle._menu_choice_item_first) {
            battle._menu_choice_item_first -= 1;
        }

        //更新文字
        var text = global.classic_ui ? "": "{depth " + string(DEPTH_BATTLE.BULLET) + "}{show_item true}";;
        var proc = 0;
        // Create every inventory label (the inventory itself is capped at
        // 114). The battle-board clip reveals only the visible rows while the
        // typer moves, so truncating this text to eight made item 9 selectable
        // but permanently nameless.
        repeat(count) {
            text += "* " + items.GetItemName(proc) + "&";
            proc += 1;
        }
        Battle_SetDialog(text, true);
        if (call) {
            Battle_CallEnemyEvent(BATTLE_ENEMY_EVENT.MENU_CHOICE_SWITCH);
        }

        return true;
    } else {
        return false;
    }

}
