function Player_CustomInitialData(){
	Player_SetName("hi175570");
	Player_SetLv(25);
	Player_SetHpMax(128);
	Player_SetNaturalHpMax(128);
	Player_SetHp(128);
	Player_SetAtk(10);
	Player_SetDef(10);
	Player_SetSpd(2);
	Player_SetInv(40);
	Player_SetKr(0);
	Player_SetBattleFightMenuObj(battle_menu_fight_knife);
	
	var items=Item_GetInventoryItems();
	items.Add(ITEM_TEST_CANDY);
	items.Add(ITEM_TEST_CANDY);
	items.Add(ITEM_TEST_NOODLES);
	items.Add(ITEM_TEST_NOODLES);
	items.Add(ITEM_TEST_STEAK);
	items.Add(ITEM_TEST_STEAK);
	items.Add(ITEM_TEST_PIE);
	items.Add(ITEM_TEST_PIE);
	var phones=Item_GetInventoryPhones();
	phones.Add(ITEM_PHONE_TML);
	
	Player_SetItemWeapon(ITEM_STICK);
	Player_SetItemArmor(ITEM_BANDAGE);
}
