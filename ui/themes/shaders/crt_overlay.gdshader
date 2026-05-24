shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(100.0, 2000.0) = 800.0;
uniform float curvature : hint_range(0.0, 0.1) = 0.02;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float flicker_speed : hint_range(0.0, 10.0) = 2.0;
uniform float aberration : hint_range(0.0, 5.0) = 0.8;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // 屏幕曲面效果
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    uv = uv + centered * dist * curvature;
    
    // 色彩偏移 (Chromatic Aberration)
    float r = texture(screen_texture, uv + vec2(aberration * 0.001, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(aberration * 0.001, 0.0)).b;
    vec3 color = vec3(r, g, b);
    
    // 扫描线
    float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
    scanline = pow(scanline, 1.5);
    color *= 1.0 - (scanline * scanline_intensity);
    
    // 扫描线滚动
    float roll = sin(TIME * 0.5 + uv.y * 500.0) * 0.02;
    color += roll;
    
    // 暗角
    float vignette = 1.0 - dist * vignette_intensity * 2.0;
    vignette = smoothstep(0.0, 1.0, vignette);
    color *= vignette;
    
    // 噪声
    float noise = random(uv + mod(TIME, 1.0)) * noise_intensity;
    color += noise;
    
    // 闪烁
    float flicker = sin(TIME * flicker_speed) * 0.01 + 0.99;
    color *= flicker;
    
    // 暗角颜色染色 (微微偏青)
    vec3 tint = vec3(0.95, 1.0, 0.98);
    color *= tint;
    
    COLOR = vec4(color, 1.0);
}
