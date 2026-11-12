shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 water_color : source_color = vec4(0.24, 0.46, 0.40, 1.0);
void fragment() {
    float ripples = sin(UV.x * 42.0 + TIME * 0.9 + sin(UV.y * 14.0)) * sin(UV.y * 29.0 - TIME * 0.5);
    ALBEDO = water_color.rgb + vec3(0.012, 0.018, 0.015) * ripples;
    ROUGHNESS = 0.28;
    METALLIC = 0.1;
    NORMAL = normalize(vec3(ripples * 0.018, cos(UV.x * 86.0 + TIME) * 0.012, 1.0));
}
