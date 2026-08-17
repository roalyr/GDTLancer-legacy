shader_type spatial;

render_mode
    blend_mix,
    cull_back,
    depth_draw_opaque;

// Material properties
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_albedo : hint_albedo;

uniform float normal_strength : hint_range(0.0, 5.0) = 0.0;
uniform float albedo_detail_strength = 0.0;
uniform float albedo_detail_power = 1.0;

uniform float rim_strength = 1.0;
uniform float rim_exponent = 3.0;
uniform float rim_intensity = 0.3;

// Fade start and end distances (for LOD discard dithering)
uniform float fade_start = 300000.0;
uniform float fade_end_mul = 5.0;
uniform float fade_power = 2.0;

// Dither threshold for distance fade
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

// Uniforms for lighting and toon effects
uniform float light_dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float posterization_levels : hint_range(1.0, 32.0) = 4.0;

// DPI / Resolution-independent virtual pixel scale (1.0 = native 1:1 pixels, 2.0 = 2x2 virtual pixels, etc.)
uniform float dither_pixel_size : hint_range(1.0, 16.0) = 2.0;

varying vec3 uv_triplanar_pos;
varying vec3 uv_power_normal;
uniform float uv_blend_sharpness : hint_range(0.0, 100.0) = 10.0;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

uniform float normal_scale = 1.0;
uniform float albedo_detail_scale = 1.0;

// --- Helper Functions ---

// Triplanar texture sampling
vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    vec4 samp = vec4(0.0);
    samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
    samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
    samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
    return samp;
}

// 2x2 Bayer matrix lookup via arithmetic
float bayer2x2(vec2 p) {
    return p.x * 2.0 + p.y * (3.0 - 4.0 * p.x);
}

// Fast GLES2-compatible 8x8 Bayer matrix calculation without stack array allocations
float bayer8x8(vec2 screen_pos) {
    vec2 p = mod(floor(screen_pos), 8.0);
    vec2 p0 = mod(p, 2.0);
    vec2 p1 = mod(floor(p / 2.0), 2.0);
    vec2 p2 = floor(p / 4.0);
    float val = 16.0 * bayer2x2(p0) + 4.0 * bayer2x2(p1) + bayer2x2(p2);
    return val / 64.0;
}

// --- Vertex Function ---
void vertex() {
    TANGENT = vec3(0.0, 0.0, -1.0) * abs(NORMAL.x);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.y);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.z);
    TANGENT = normalize(TANGENT);
    
    BINORMAL = vec3(0.0, 1.0, 0.0) * abs(NORMAL.x);
    BINORMAL += vec3(0.0, 0.0, -1.0) * abs(NORMAL.y);
    BINORMAL += vec3(0.0, 1.0, 0.0) * abs(NORMAL.z);
    BINORMAL = normalize(BINORMAL);
    
    uv_power_normal = pow(abs(NORMAL), vec3(uv_blend_sharpness));
    uv_power_normal /= dot(uv_power_normal, vec3(1.0));
    
    uv_triplanar_pos = VERTEX * uv_scale + uv_offset;
    uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

// --- Fragment Function ---
void fragment() {
    // Virtual pixel coordinates for DPI-independent dither grid
    vec2 dither_pos = FRAGCOORD.xy / max(1.0, dither_pixel_size);

    // --- Distance-based LOD Discard Dithering ---
    float distance_vert = length(VERTEX);
    float fade_range = fade_end_mul * fade_start - fade_start;
    if (fade_range > 0.0 && distance_vert > fade_start) {
        float fade_factor = pow(clamp((fade_end_mul * fade_start - distance_vert) / fade_range, 0.0, 1.0), fade_power);
        float bayer_val = bayer8x8(dither_pos);
        if (fade_factor < bayer_val * dither_threshold + 1e-6) {
            discard;
        }
    }

    // --- Material Setup ---
    vec3 albedo_detail = triplanar_texture(texture_albedo, uv_power_normal, uv_triplanar_pos * albedo_detail_scale).rgb;
    float albedo_detail_val = albedo_detail_strength * pow(albedo_detail.r, albedo_detail_power);

    ALBEDO = albedo.rgb + albedo_detail_val;

    // Normal mapping
    if (normal_strength > 0.0) {
        vec3 normal_tex = triplanar_texture(texture_normal, uv_power_normal, uv_triplanar_pos * normal_scale).rgb;
        NORMALMAP = normal_tex;
        NORMALMAP_DEPTH = normal_strength;
    }

    EMISSION = emission.rgb * COLOR.rgb;
}

// --- Light Function ---
void light() {
    // Virtual pixel coordinates for DPI-independent dither grid
    vec2 dither_pos = FRAGCOORD.xy / max(1.0, dither_pixel_size);

    // 8x8 Bayer threshold based on scaled screen-space coordinates
    float threshold = bayer8x8(dither_pos);

    // Standard Lambertian intensity
    float NoL = max(0.0, dot(NORMAL, LIGHT));

    // Bi-directional Bayer dithering across quantization steps
    float levels = max(1.0, posterization_levels);
    float step_size = 1.0 / levels;
    float dither_offset = (threshold - 0.5) * step_size * light_dither_strength;
    float dithered_NoL = clamp(NoL + dither_offset, 0.0, 1.0);

    // Quantized toon diffuse intensity
    float quantized_NoL = floor(dithered_NoL * levels) / levels;

    // Grazing angle Fresnel rim lighting (active in light)
    float fresnel = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
    float rim = pow(fresnel, rim_exponent) * rim_strength * rim_intensity;

    // Combined diffuse lighting tinted by albedo
    vec3 current_light = ALBEDO * (quantized_NoL + rim * quantized_NoL) * ATTENUATION * LIGHT_COLOR;

    DIFFUSE_LIGHT += current_light;
    SPECULAR_LIGHT += vec3(0.0);
}