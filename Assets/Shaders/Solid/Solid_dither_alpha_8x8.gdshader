shader_type spatial;

render_mode
    //vertex_lighting,
    blend_mix,
    cull_back,
    diffuse_burley, 
    specular_schlick_ggx,
    depth_draw_opaque;

// Material properties
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0,0.0,0.0,1.0);
uniform float specular : hint_range(0.0, 10.0) = 0.5;
uniform float metallic = 1.0;
uniform float roughness = 0.5;

// Fade start and end distances
uniform float fade_start = 0.0;
uniform float fade_end = 4e4;
uniform float fade_power = 2.0;

uniform float highlight_end = 1e3;
uniform float highlight_power = 2.0;
uniform float highlight_strength = 0.0;

// Dither threshold for the dithering effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

// Function to calculate Bayer matrix value dynamically for an 8x8 matrix
float bayer8x8(int x, int y) {
    // Flattened 8x8 Bayer matrix
    float bayer[64];
    bayer[0] = 0.0;  bayer[1] = 32.0; bayer[2] = 8.0;  bayer[3] = 40.0; bayer[4] = 2.0;  bayer[5] = 34.0; bayer[6] = 10.0; bayer[7] = 42.0;
    bayer[8] = 48.0; bayer[9] = 16.0; bayer[10] = 56.0; bayer[11] = 24.0; bayer[12] = 50.0; bayer[13] = 18.0; bayer[14] = 58.0; bayer[15] = 26.0;
    bayer[16] = 12.0; bayer[17] = 44.0; bayer[18] = 4.0;  bayer[19] = 36.0; bayer[20] = 14.0; bayer[21] = 46.0; bayer[22] = 6.0;  bayer[23] = 38.0;
    bayer[24] = 60.0; bayer[25] = 28.0; bayer[26] = 52.0; bayer[27] = 20.0; bayer[28] = 62.0; bayer[29] = 30.0; bayer[30] = 54.0; bayer[31] = 22.0;
    bayer[32] = 3.0;  bayer[33] = 35.0; bayer[34] = 11.0; bayer[35] = 43.0; bayer[36] = 1.0;  bayer[37] = 33.0; bayer[38] = 9.0;  bayer[39] = 41.0;
    bayer[40] = 51.0; bayer[41] = 19.0; bayer[42] = 59.0; bayer[43] = 27.0; bayer[44] = 49.0; bayer[45] = 17.0; bayer[46] = 57.0; bayer[47] = 25.0;
    bayer[48] = 15.0; bayer[49] = 47.0; bayer[50] = 7.0;  bayer[51] = 39.0; bayer[52] = 13.0; bayer[53] = 45.0; bayer[54] = 5.0;  bayer[55] = 37.0;
    bayer[56] = 63.0; bayer[57] = 31.0; bayer[58] = 55.0; bayer[59] = 23.0; bayer[60] = 61.0; bayer[61] = 29.0; bayer[62] = 53.0; bayer[63] = 21.0;

    return bayer[x + y * 8] / 64.0;
}

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance_vert = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);

    // Get Bayer matrix value based on screen position
    int x = int(mod(FRAGCOORD.x, 8.0));
    int y = int(mod(FRAGCOORD.y, 8.0));
    float dither_value = bayer8x8(x, y);

    // Discard pixel based on the fade factor and Bayer matrix value
    if (fade_factor <= dither_value * dither_threshold) {
        discard;
    }
	
    float highlight_factor = pow(clamp((highlight_end - distance_vert) / highlight_end, 0.0, 1.0), highlight_power);

    // Set the material properties
    ALBEDO = albedo.rgb*COLOR.rgb;
	ALBEDO += highlight_factor * highlight_strength;
	EMISSION = emission.rgb*COLOR.rgb ;
    SPECULAR = specular;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
