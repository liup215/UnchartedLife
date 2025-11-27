shader_type canvas_item;

// 这是一个噪点图，我们在Godot界面里把刚才那个NoiseTexture拖进来
uniform sampler2D noise_texture : repeat_enable;
// 流动速度
uniform vec2 speed = vec2(0.001, 0.002);
// 扭曲强度
uniform float distortion_strength = 0.02;
// 摄像机偏移（用于跟随玩家移动）
uniform vec2 camera_offset = vec2(0.0, 0.0);
// 滚动比例（控制背景移动速度，越小越慢，产生视差感）
uniform vec2 scroll_scale = vec2(0.0005, 0.0005);

void fragment() {
    // 让UV坐标随着时间移动，产生“水流”感，并加上摄像机偏移
    vec2 flowing_uv = UV + TIME * speed + camera_offset * scroll_scale;
    
    // 从噪点图中采样颜色
    vec4 noise_color = texture(noise_texture, flowing_uv);
    
    // 如果你想让背景图片本身也扭曲（像透过水看东西）
    // vec4 screen_color = texture(TEXTURE, UV + noise_color.rg * distortion_strength);
    
    // 直接输出噪点的颜色作为背景
    COLOR = noise_color;
}
