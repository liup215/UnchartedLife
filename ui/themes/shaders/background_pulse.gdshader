shader_type canvas_item;

uniform vec4 bg_color_1 : source_color = vec4(0.02, 0.03, 0.05, 1.0);
uniform vec4 bg_color_2 : source_color = vec4(0.05, 0.07, 0.12, 1.0);
uniform vec4 glow_color : source_color = vec4(0.1, 0.5, 0.45, 0.03);
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 2.0) = 0.15;
uniform float scale : hint_range(1.0, 50.0) = 15.0;
uniform int octaves : hint_range(1, 8) = 4;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(uv);
        uv *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * scale;
    float t = TIME * speed;
    
    // 有机流动噪声
    float n1 = fbm(uv + vec2(t * 0.5, t * 0.3));
    float n2 = fbm(uv * 1.5 - vec2(t * 0.2, t * 0.4));
    
    // 混合两种噪声产生有机质感
    float organic = (n1 + n2 * 0.5) / 1.5;
    
    // 基础背景色混合
    vec3 color = mix(bg_color_1.rgb, bg_color_2.rgb, organic);
    
    // 添加青色荧光脉动
    float pulse = sin(t + uv.x * 0.5 + uv.y * 0.3) * 0.5 + 0.5;
    float glow = n1 * pulse * glow_intensity;
    color += glow_color.rgb * glow;
    
    // 添加细微的细胞网格感
    float grid = sin(uv.x * 3.14159 * 2.0) * sin(uv.y * 3.14159 * 2.0);
    grid = smoothstep(0.8, 1.0, grid) * 0.02;
    color += glow_color.rgb * grid;
    
    COLOR = vec4(color, 1.0);
}
