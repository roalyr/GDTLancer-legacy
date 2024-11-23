shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_disabled,
	
	unshaded,
	//diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.05;
uniform float pulse_frequency = 50;
uniform float power = 1.0;

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

void vertex()
{
	float a = ((cos(TIME*pulse_frequency)+1.0)*0.5);
	VERTEX.y = VERTEX.y*(a*pulse_amount + (1.0 - pulse_amount));
}

void fragment()
{
    // Get Bayer matrix value based on screen position
    int x = int(mod(FRAGCOORD.x, 4.0));
    int y = int(mod(FRAGCOORD.y, 4.0));
    float dither_value = bayer4x4(x, y);
	
	    // Discard pixel based on the fade factor and Bayer matrix value
    if (COLOR.r <= dither_value * dither_threshold) {
        discard;
    }
	
	ALBEDO = albedo.rgb * pow(COLOR.r, power);
}
