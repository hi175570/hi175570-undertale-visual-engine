Battle_CallSoulEventHurt();
// Legacy green-soul arrows still use their authored one-point strength, but
// must pass through the same AllScript endpoint/DEF/shield pipeline as every
// editor hazard.  Direct Player_Hurt() bypassed KR locking at one HP.
Player_HurtColor(type,1,false)
instance_destroy()

