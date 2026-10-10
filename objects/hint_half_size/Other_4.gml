// room_menu is persistent. Its original one-shot Alarm has already fired
// when the player returns from battle/editor, while the persistent camera's
// Room Start event resets scale to 1. Reapply this room's existing 2x setup
// on every return; do not change the camera view dimensions.
camera.scale_x=2;
camera.scale_y=2;
