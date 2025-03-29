shader_type spatial;

// *** IMPORTANT: Changed render_mode ***
// Remove vertex_lighting, diffuse_lambert, specular_disabled
// We will calculate lighting manually in the light() function.
render_mode
    blend_mix,
    cull_back,
    depth_draw_opaque;
    // We could add diffuse_toon here, but let's calculate manually
    // We could add specular_schlick_ggx if we wanted PBR specular

// Material properties (Inputs for fragment and light functions)
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float specular : hint_range(0.0, 5.0) = 0.5; // Can be used in light() if needed
uniform float metallic : hint_range(-5.0, 5.0) = 0.0; // Can be used in light() if needed
uniform float roughness : hint_range(-5.0, 5.0) = 0.5; // Can be used in light() if needed

uniform sampler2D texture_normal : hint_albedo;
uniform sampler2D texture_albedo : hint_albedo;

uniform float normal_strength = 0.0;
uniform float albedo_detail_strength = 0.0;
uniform float albedo_detail_power = 1.0;

uniform float rim_strength = 1.0;
uniform float rim_exponent = 0.5;
uniform float rim_intensity = 0.3;

// Fade start and end distances (for alpha dithering)
uniform float fade_start = 3e4;
uniform float fade_end_mul = 5;
uniform float fade_power = 2.0;

// Dither threshold for the ALPHA/discard dithering effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

// --- Uniforms for Lighting Effects ---
uniform float light_dither_strength : hint_range(0.0, 1.0) = 0.25; // How much to apply NoL dithering
uniform float posterization_levels : hint_range(1.0, 16.0) = 4.0; // Steps for posterization (min 1)

varying vec3 uv_triplanar_pos;
uniform float uv_blend_sharpness : hint_range(0.0, 100.0) = 10.0;
varying vec3 uv_power_normal;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

uniform float normal_scale = 1.0;
uniform float albedo_detail_scale = 1.0;

// --- Constants ---
const float PI = 3.14159265359;

// --- Helper Functions ---

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
    vec4 samp=vec4(0.0);
    samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
    samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
    samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
    return samp;
}

// Function to calculate Bayer matrix value dynamically for an 8x8 matrix (GLES2 Compatible)
float bayer8x8(int x, int y) {
    float bayer[64];
    bayer[0] = 0.0;  bayer[1] = 32.0; bayer[2] = 8.0;  bayer[3] = 40.0; bayer[4] = 2.0;  bayer[5] = 34.0; bayer[6] = 10.0; bayer[7] = 42.0;
    bayer[8] = 48.0; bayer[9] = 16.0; bayer[10] = 56.0; bayer[11] = 24.0; bayer[12] = 50.0; bayer[13] = 18.0; bayer[14] = 58.0; bayer[15] = 26.0;
    bayer[16] = 12.0; bayer[17] = 44.0; bayer[18] = 4.0;  bayer[19] = 36.0; bayer[20] = 14.0; bayer[21] = 46.0; bayer[22] = 6.0;  bayer[23] = 38.0;
    bayer[24] = 60.0; bayer[25] = 28.0; bayer[26] = 52.0; bayer[27] = 20.0; bayer[28] = 62.0; bayer[29] = 30.0; bayer[30] = 54.0; bayer[31] = 22.0;
    bayer[32] = 3.0;  bayer[33] = 35.0; bayer[34] = 11.0; bayer[35] = 43.0; bayer[36] = 1.0;  bayer[37] = 33.0; bayer[38] = 9.0;  bayer[39] = 41.0;
    bayer[40] = 51.0; bayer[41] = 19.0; bayer[42] = 59.0; bayer[43] = 27.0; bayer[44] = 49.0; bayer[45] = 17.0; bayer[46] = 57.0; bayer[47] = 25.0;
    bayer[48] = 15.0; bayer[49] = 47.0; bayer[50] = 7.0;  bayer[51] = 39.0; bayer[52] = 13.0; bayer[53] = 45.0; bayer[54] = 5.0;  bayer[55] = 37.0;
    bayer[56] = 63.0; bayer[57] = 31.0; bayer[58] = 55.0; bayer[59] = 23.0; bayer[60] = 61.0; bayer[61] = 29.0; bayer[62] = 53.0; bayer[63] = 21.0;

    int ix = int(mod(float(x), 8.0));
    int iy = int(mod(float(y), 8.0));
    int index = ix + iy * 8;
    if (index < 0 || index > 63) { return 0.0; }
    return bayer[index] / 64.0;
}

// Posterization function
vec3 posterize(vec3 color, float levels) {
    levels = max(1.0, levels);
    return floor(color * levels) / levels;
}

// Toon Diffuse BRDF function (similar to Godot 4 example)
vec3 diffuse_toon(vec3 albedo_val, float NoL_val, float levels) {
    levels = max(1.0, levels);
    float intensity = floor(NoL_val * levels) / levels; // Quantize the light intensity
    return albedo_val * intensity; // Return albedo scaled by quantized intensity
}


// --- Vertex Function ---
void vertex() {
    // Keep existing vertex logic for triplanar and TBN
    TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
    TANGENT = normalize(TANGENT);
    BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
    BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
    BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
    BINORMAL = normalize(BINORMAL);
    uv_power_normal=pow(abs(NORMAL),vec3(uv_blend_sharpness));
    uv_power_normal/=dot(uv_power_normal,vec3(1.0));
    uv_triplanar_pos = VERTEX * uv_scale + uv_offset;
    uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

// --- Fragment Function ---
// Sets up material properties used by light() and handles alpha dithering.
void fragment() {
    // --- Alpha Dithering (based on distance) ---
    float distance_vert = length(VERTEX);
    float fade_factor = pow(clamp((fade_end_mul*fade_start - distance_vert) / (fade_end_mul*fade_start - fade_start), 0.0, 1.0), fade_power);

    // Get Bayer matrix value based on screen coordinates
    // Used for BOTH alpha dithering and potentially light dithering
    int x = int(mod(FRAGCOORD.x, 8.0));
    int y = int(mod(FRAGCOORD.y, 8.0));
    float bayer_value = bayer8x8(x, y);

    // Original alpha dithering
    if (fade_factor < bayer_value * dither_threshold) {
        discard;
    }

    // --- Material Setup ---
    // Calculate properties needed for the light() function
    float rim = clamp(pow(abs(dot(NORMAL, VIEW)), rim_exponent)*rim_strength, 0.0, 1.0);
    vec3 normal_tex = triplanar_texture(texture_normal,uv_power_normal,uv_triplanar_pos * normal_scale).rgb;
    vec3 albedo_detail = triplanar_texture(texture_albedo, uv_power_normal, uv_triplanar_pos * albedo_detail_scale).rgb;

    float albedo_detail_val = albedo_detail_strength * pow(albedo_detail.r, albedo_detail_power);

    // Set base material properties. ALBEDO and NORMALMAP are read by light().
    ALBEDO = albedo.rgb + albedo_detail_val;
    ALBEDO += (1.0-rim) * rim_intensity; // Apply rim effect to albedo

    EMISSION = emission.rgb * COLOR.rgb; // Emission is handled separately

    NORMALMAP = normal_tex;
    NORMALMAP_DEPTH = normal_strength;

    // Set other properties (ROUGHNESS, METALLIC, SPECULAR).
    // These are available in light() if you choose to implement specular.
    // ROUGHNESS = roughness; // Example if needed
    // METALLIC = metallic; // Example if needed
    // SPECULAR = specular; // Example if needed
}


// --- Light Function ---
// Calculates lighting per-light, per-pixel.
void light() {
    // --- Dithering Setup ---
    // Get screen coords and Bayer threshold (FRAGCOORD is available here)
    int x = int(mod(FRAGCOORD.x, 8.0));
    int y = int(mod(FRAGCOORD.y, 8.0));
    float threshold = bayer8x8(x, y);

    // --- Lighting Vectors & Base Calculation ---
    // NORMAL, VIEW, LIGHT (direction), ALBEDO, etc. are available here.
    float NoL = max(0.0, dot(NORMAL, LIGHT)); // Basic Lambertian factor

    // --- Dithered NoL ---
    // Apply dithering based on screen pattern, modifying NoL
    // Mix between original NoL and a stepped version based on the threshold
    float dithered_NoL = mix(NoL, step(threshold, NoL) * NoL, light_dither_strength);
    dithered_NoL = max(0.0, dithered_NoL); // Ensure it doesn't go negative

    // --- Diffuse Calculation ---
    // Use the Toon diffuse model with the dithered NoL and posterization levels for steps
    vec3 diffuse_term = diffuse_toon(ALBEDO, dithered_NoL, posterization_levels);

    // --- Combine Light ---
    // Apply light color and attenuation to the calculated diffuse term
    // Note: We multiply by ATTENUATION and LIGHT_COLOR here.
    //       The G4 example multiplied the BRDF by dithered_NoL again, which might
    //       be redundant depending on the BRDF; diffuse_toon already includes intensity.
    vec3 current_light = diffuse_term * ATTENUATION * LIGHT_COLOR;

    // --- Final Posterization ---
    // Apply posterization to the final combined light color for this light source
    current_light = posterize(current_light, posterization_levels);

    // --- Output ---
    // Add the contribution of this light to the total diffuse light
    DIFFUSE_LIGHT += current_light;

    // We are not calculating specular light in this version.
    SPECULAR_LIGHT += vec3(0.0);
}