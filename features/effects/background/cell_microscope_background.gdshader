shader_type canvas_item;

uniform vec2 resolution = vec2(1920.0, 1080.0);
uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform float scroll_scale : hint_range(0.0, 1.0) = 0.2;
uniform float time_scale : hint_range(0.0, 2.0) = 0.2;

// === SIMPLEX NOISE (Stefan Gustavson) ===
vec3 mod289(vec3 x){ return x - floor(x*(1.0/289.0))*289.0; }
vec2 mod289(vec2 x){ return x - floor(x*(1.0/289.0))*289.0; }
vec3 permute(vec3 x){ return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v){
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,-0.577350269189626,0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz; x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y+vec3(0.0,i1.y,1.0))+i.x+vec3(0.0,i1.x,1.0));
    vec3 m = max(0.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    vec3 x = 2.0*fract(p*C.www)-1.0;
    vec3 h = abs(x)-0.5;
    vec3 ox = floor(x+0.5);
    vec3 a0 = x-ox;
    m *= 1.79284291400159-0.85373472095314*(a0*a0+h*h);
    vec3 g; g.x = a0.x*x0.x + h.x*x0.y; g.yz = a0.yz*x12.xz + h.yz*x12.yw;
    return 130.0*dot(m,g);
}

// Single-octave large smooth plasm with minimal second pass for organic variation
float big_plasm(vec2 p){
    float n = snoise(p*0.35) * 0.5 + 0.5;               // Huge slow waves
    n += (snoise(p*0.65 + vec2(5.2,3.1)) * 0.5 + 0.5) * 0.30; // One soft overlay
    return n / 1.30;
}

void fragment(){
    vec2 uv = UV;
    vec2 parallax = camera_offset * scroll_scale / resolution;
    vec2 p = (uv + parallax) * 8.0;  // Very low spatial freq
    float t = TIME * time_scale;

    // === Slow big plasm ===
    float plasm = big_plasm(p + vec2(t * 0.02, t * 0.015));

    // === Colour: bright warm pink plasma ===
    vec3 deep   = vec3(0.25, 0.08, 0.14);  // Deep dark rose
    vec3 mid    = vec3(0.68, 0.30, 0.42);  // Warm mid pink
    vec3 bright = vec3(0.95, 0.65, 0.72);  // Bright creamy pink

    vec3 col = mix(deep, mid, plasm);
    col = mix(col, bright, pow(plasm, 2.5) * 0.22);

    COLOR = vec4(col, 1.0);
}
