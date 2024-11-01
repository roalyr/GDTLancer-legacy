shader_type spatial;

// Fade start and end distances
uniform float fade_start = 0.0;
uniform float fade_end = 2000.0;

// Dither threshold for the dithering effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Define a 4x4 Bayer matrix using individual assignments
    float bayer_matrix[16];
    bayer_matrix[0] = 0.0;
    bayer_matrix[1] = 8.0;
    bayer_matrix[2] = 2.0;
    bayer_matrix[3] = 10.0;
    bayer_matrix[4] = 12.0;
    bayer_matrix[5] = 4.0;
    bayer_matrix[6] = 14.0;
    bayer_matrix[7] = 6.0;
    bayer_matrix[8] = 3.0;
    bayer_matrix[9] = 11.0;
    bayer_matrix[10] = 1.0;
    bayer_matrix[11] = 9.0;
    bayer_matrix[12] = 15.0;
    bayer_matrix[13] = 7.0;
    bayer_matrix[14] = 13.0;
    bayer_matrix[15] = 5.0;

    // Calculate the distance from the camera to the current fragment
    float distance = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = clamp((fade_end - distance) / (fade_end - fade_start), 0.0, 1.0);

    // Get screen position in a 4x4 grid and map to the Bayer matrix
    int index = int(mod(FRAGCOORD.x, 4.0)) + int(mod(FRAGCOORD.y, 4.0)) * 4;
    float dither_value = bayer_matrix[index] / 16.0;

    // Discard pixel based on the fade factor and Bayer matrix value
    if (fade_factor <= dither_value * dither_threshold) {
        discard;
    }

    // Set the color without affecting the alpha channel
    ALBEDO = vec3(1.0); // White color as an example
	ALPHA = fade_factor;
}
