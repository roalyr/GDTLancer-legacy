shader_type spatial;

render_mode
	//vertex_lighting,
    blend_mix,
    cull_back,
    diffuse_burley,
    specular_schlick_ggx,
    depth_draw_always; // Ensures depth testing with alpha support

// Material properties
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float specular : hint_range(0.0, 2.0) = 0.5;
uniform float metallic : hint_range(-2.0, 2.0) = 1.0;
uniform float roughness : hint_range(-3.0, 3.0) = 0.5;

// Fade start and end distances
uniform float fade_start = 5e4;
uniform float fade_end = 1e5;
uniform float fade_power = 2.0;

// Dither threshold for the dithering effect
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.0;

uniform float highlight_end = 1e3;
uniform float highlight_power = 2.0;
uniform float highlight_strength = 0.0; 

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance_vert = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);

	// Set a threshold below which fragments are fully transparent
	if (fade_factor < alpha_threshold && fade_factor > 0.01) {
	    ALPHA = alpha_threshold;
	} else if (fade_factor < 0.01) {
		ALPHA = 0.0;
	} else {
		ALPHA = fade_factor;
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
