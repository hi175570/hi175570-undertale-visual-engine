function Macro_Depth() {
	enum DEPTH_UI{
		PANEL=-100,
		TEXT=-200,
		ENCOUNTER_ANIM=-300,
		FADER=-400
	};

	enum DEPTH_BATTLE{
		BG=-100,
		ENEMY=-200,
		UI=-300,
		FADER=-400,
		BULLET=-500,
		BOARD=-600,
		UI_HIGH=-700,
		BULLET_OUTSIDE_LOW=-800,
		BULLET_OUTSIDE_HIGH=-1000,
		SOUL=-1100,
		// Major attacks cover the player; warnings cover absolutely everything.
		BEAM=-1200,
		WARNING=-1300
	};


}
