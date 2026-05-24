shader_type canvas_item;

uniform float width : hint_range(0.0, 0.5) = 0.02;
uniform vec4 border_color : source_color = vec4(0.176, 0.831, 0.749, 1.0);
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    float dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    float border_alpha = smoothstep(width, width * 0.5, dist) * pulse;
    
    vec4 glow = border_color * border_alpha * glow_strength;
    
    COLOR = vec4(glow.rgb, border_alpha * glow.a);
}
