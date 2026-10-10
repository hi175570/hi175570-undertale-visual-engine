varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texel;
uniform float u_time;
uniform vec4 u_color_adjust;  // hue degrees, saturation, brightness, contrast
uniform vec4 u_mix_adjust;    // grayscale, invert, vignette, pixel size
uniform vec4 u_glitch_adjust; // intensity, chromatic pixels, scanline, wave

vec3 hue_rotate(vec3 color, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    mat3 m = mat3(
        0.299 + 0.701*c + 0.168*s, 0.587 - 0.587*c + 0.330*s, 0.114 - 0.114*c - 0.497*s,
        0.299 - 0.299*c - 0.328*s, 0.587 + 0.413*c + 0.035*s, 0.114 - 0.114*c + 0.292*s,
        0.299 - 0.300*c + 1.250*s, 0.587 - 0.588*c - 1.050*s, 0.114 + 0.886*c - 0.203*s
    );
    return clamp(m * color, 0.0, 1.0);
}

void main()
{
    vec2 uv = v_vTexcoord;
    float pixel_size = max(1.0, u_mix_adjust.w);
    if (pixel_size > 1.001) uv = (floor(uv / (u_texel * pixel_size)) + 0.5) * u_texel * pixel_size;

    float line_noise = sin(floor(uv.y / max(u_texel.y, 0.000001)) * 12.9898 + floor(u_time * 24.0) * 7.13);
    float gate = step(0.82, fract(line_noise * 43758.5453));
    float shift = gate * line_noise * u_glitch_adjust.x * 0.035;
    uv.x += shift + sin(uv.y * 90.0 + u_time * 8.0) * u_texel.x * u_glitch_adjust.w;

    vec2 chroma = vec2(u_texel.x * u_glitch_adjust.y, 0.0);
    vec4 base = texture2D(gm_BaseTexture, uv);
    base.r = texture2D(gm_BaseTexture, uv + chroma).r;
    base.b = texture2D(gm_BaseTexture, uv - chroma).b;

    vec3 color = hue_rotate(base.rgb, radians(u_color_adjust.x));
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luminance), color, u_color_adjust.y);
    color = (color - 0.5) * u_color_adjust.w + 0.5 + u_color_adjust.z;
    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), u_mix_adjust.x);
    color = mix(color, vec3(1.0) - color, u_mix_adjust.y);

    float scan = 1.0 - u_glitch_adjust.z * (0.5 + 0.5 * sin(uv.y / max(u_texel.y, 0.000001) * 3.14159265));
    vec2 centered = uv - 0.5;
    float vignette = 1.0 - smoothstep(0.25, 0.72, length(centered)) * u_mix_adjust.z;
    gl_FragColor = vec4(clamp(color * scan * vignette, 0.0, 1.0), base.a) * v_vColour;
}
