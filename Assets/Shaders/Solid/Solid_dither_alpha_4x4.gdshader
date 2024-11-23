shader_type spatial;

render_mode
    //vertex_lighting,
    blend_mix,
    cull_back,
    diffuse_burley, 
    specular_schlick_ggx,
    depth_draw_opaque;

// Material properties
uniform float specular = 0.5;
uniform float metallic = 0.5;
uniform float roughness = 0.5;

// Fade start and end distances
uniform float fade_start = 0.0;
uniform float fade_end = 5e4;
uniform float fade_power = 2.0;

// Dither threshold for the dithering effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

// Function to calculate Bayer matrix value dynamically for a 4x4 matrix
float bayer4x4(int x, int y) {
    // Flattened 4x4 Bayer matrix
    float bayer[16];
    bayer[0] = 0.0; bayer[1] = 8.0; bayer[2] = 2.0; bayer[3] = 10.0;
    bayer[4] = 12.0; bayer[5] = 4.0; bayer[6] = 14.0; bayer[7] = 6.0;
    bayer[8] = 3.0; bayer[9] = 11.0; bayer[10] = 1.0; bayer[11] = 9.0;
    bayer[12] = 15.0; bayer[13] = 7.0; bayer[14] = 13.0; bayer[15] = 5.0;

    return bayer[x + y * 4] / 16.0;
}

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance) / (fade_end - fade_start), 0.0, 1.0), fade_power);

    // Get Bayer matrix value based on screen position
    int x = int(mod(FRAGCOORD.x, 4.0));
    int y = int(mod(FRAGCOORD.y, 4.0));
    float dither_value = bayer4x4(x, y);

    // Discard pixel based on the fade factor and Bayer matrix value
    if (fade_factor <= dither_value * dither_threshold) {
        discard;
    }

    // Set the material properties
    ALBEDO = vec3(1.0); // Example: white color
    SPECULAR = specular;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
