// Editor-authored sprite hazards own image_angle directly. The legacy parent
// bullet renderer treats `angle` as movement-facing state and otherwise
// overwrites image_angle before drawing, which made Trident and other sprites
// snap away from the angle shown in the editor as soon as playback began.
angle=image_angle;
event_inherited();
