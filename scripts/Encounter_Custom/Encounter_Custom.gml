function Encounter_Custom() {
	// The editor's first authored enemy is slot 0. Starting the bootstrap
	// instance in slot 1 made a one-enemy project remove that instance during
	// initialization without destroying it, leaving an overlapping orphan draw.
	Encounter_Set(0,battle_enemy_test,-1,-1,"* 第一回合",-1);

}
