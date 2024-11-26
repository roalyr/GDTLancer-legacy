shader_type spatial;

render_mode
	//vertex_lighting,
    blend_mix,
    cull_back,
    diffuse_oren_nayar,
    specular_schlick_ggx,
    depth_draw_always; // Ensures depth testing with alpha support

// Material properties
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float specular : hint_range(0.0, 5.0) = 0.5;
uniform float metallic : hint_range(-5.0, 5.0) = 1.0;
uniform float roughness : hint_range(-5.0, 5.0) = 0.5;

// Fade start and end distances
uniform float fade_start = 2e4;
uniform float fade_end = 4e4;
uniform float fade_power = 2.0;

// Dither threshold for the dithering effect
uniform float dither_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.0;

uniform float highlight_end = 1e3;
uniform float highlight_power = 2.0;
uniform float highlight_strength = 0.0; 

// 4x4 Bayer matrix values
float bayer4x4(int x, int y) {
    float bayer[16];
    bayer[0] = 0.0; bayer[1] = 8.0;  bayer[2] = 2.0;  bayer[3] = 10.0;
    bayer[4] = 12.0; bayer[5] = 4.0; bayer[6] = 14.0; bayer[7] = 6.0;
    bayer[8] = 3.0;  bayer[9] = 11.0; bayer[10] = 1.0; bayer[11] = 9.0;
    bayer[12] = 15.0; bayer[13] = 7.0; bayer[14] = 13.0; bayer[15] = 5.0;

    return bayer[x + y * 4] / 16.0;
}

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance_vert = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);

    // Get Bayer matrix value based on screen position
    int x = int(mod(FRAGCOORD.x, 4.0));
    int y = int(mod(FRAGCOORD.y, 4.0));
    float dither_value = bayer4x4(x, y);

	// Set a threshold below which fragments are fully transparent
	if (fade_factor < alpha_threshold && fade_factor > 0.01) {
	    ALPHA = alpha_threshold;
	} else if (fade_factor < 0.01) {
		ALPHA = 0.0;
	} else {
	    // Calculate final alpha blending
		float dither_alpha = step(dither_value, fade_factor);
		ALPHA = mix(fade_factor, dither_alpha, dither_threshold);
	}
	
	float highlight_factor = pow(clamp((highlight_end - distance_vert) / highlight_end, 0.0, 1.0), highlight_power); 
	
    // Set the material properties
    ALBEDO = albedo.rgb * COLOR.rgb;
	ALBEDO += highlight_factor * highlight_strength;
    EMISSION = emission.rgb * COLOR.rgb;
    SPECULAR = specular;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
