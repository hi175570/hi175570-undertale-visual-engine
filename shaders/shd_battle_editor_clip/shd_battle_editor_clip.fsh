varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_clip_mask;
uniform vec2 u_target_size;

void main()
{
    vec4 base = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    vec2 mask_uv = vec2(gl_FragCoord.x / u_target_size.x, 1.0 - gl_FragCoord.y / u_target_size.y);
    float mask_alpha = texture2D(u_clip_mask, mask_uv).a;
    gl_FragColor = vec4(base.rgb, base.a * mask_alpha);
}
