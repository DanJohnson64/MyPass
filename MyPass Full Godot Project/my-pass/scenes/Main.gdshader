shader_type canvas_item;

uniform float speed = 1.0;
uniform float size = 20.0;

void fragment() {
    // UV from 0–1
    vec2 uv = UV;

    // Convert to centered coordinates like Shadertoy
    uv -= 0.5;
    uv *= 2.0;

    // Get screen resolution using SCREEN_PIXEL_SIZE
    vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
    float aspect = screen_res.x / screen_res.y;

    // Apply aspect ratio correction
    uv.x *= 0.6;

    float range = TIME * speed;

    float x = sin(uv.x * size + range);
    float y = sin(uv.y * size + range);

    float d;

    if (x > 0.0) {
        d = (y > 0.0) ? 1.0 : 0.0;
    } else {
        d = (y < 0.0) ? 1.0 : 0.0;
    }

    vec4 dark_color  = vec4(0.278, 0.694, 0.631, 1.0);
    vec4 light_color = vec4(0.686, 0.913, 0.709, 1.0);

    COLOR = (d == 0.0) ? dark_color : light_color;
}
