shader_type canvas_item;

uniform float cell_radius : hint_range(20.0, 120.0) = 65.0;
uniform float base_alpha  : hint_range(0.0, 1.0) = 0.45;
uniform vec3  body_tint   : source_color = vec3(0.25, 0.62, 0.95);

// Glow control
uniform float glow_width  : hint_range(0.05, 0.6) = 0.28;   // how far white glow reaches inward
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.1;  // brightness of white inner glow
uniform float center_dark  : hint_range(0.0, 1.0) = 0.82;   // how black the centre gets

// === SIMPLEX NOISE (compact) ===
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

// Organic cell membrane — noise-distorted circle
float organic_cell(vec2 p) {
    float r = length(p);
    float bump1 = snoise(p * 0.10) * 14.0;          // big slow wobbles
    float bump2 = snoise(p * 0.22 + vec2(7.3, 2.1)) * 5.5; // finer detail
    float bump3 = snoise(p * 0.45) * 2.0;            // tiny detail
    return r - cell_radius - bump1 - bump2 - bump3;
}

void fragment() {
    // Pixel-space coordinates: UV 0..1 mapped to [-cell_radius, cell_radius]
    vec2 p = (UV - 0.5) * cell_radius * 2.2;

    // Organic cell SDF
    float dist = organic_cell(p);  // negative = inside cell

    // === Smooth edge mask ===
    float edge_aa = 2.5; // pixel fade for membrane
    float mask = smoothstep(0.0, -edge_aa, dist);
    if (mask < 0.001) discard;

    // === Normalised radial coordinate (0 = centre, 1 = membrane) ===
    float r = length(p);
    float rad = clamp(r / cell_radius, 0.0, 1.0);

    // === White inner glow ===
    // Bell curve peaking just INSIDE the membrane edge
    float glow = exp(-pow((rad - (1.0 - glow_width * 0.5)) / (glow_width * 0.4), 2.0));
    glow *= glow_intensity;

    // === Centre darkening (small dark core, does NOT reach glow region) ===
    float dark = (1.0 - smoothstep(0.0, 0.12, rad)) * center_dark;

    // === Colour build ===
    // Base body is extremely faint tinted glass
    vec3 col = body_tint * 0.12 * mask;
    // Add the white inner glow (semi-transparent luminous layer)
    col += vec3(1.0, 0.98, 0.95) * glow * 0.85;
    // Darken toward centre
    col *= (1.0 - dark);

    // === Alpha: semi-transparent body, edge slightly more opaque ===
    float a = base_alpha * mask;
    a += glow * 0.15; // glow adds a touch more opacity
    a = clamp(a, 0.0, 0.92);

    COLOR = vec4(col, a);
}
