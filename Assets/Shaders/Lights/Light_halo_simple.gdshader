shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_add,
	cull_front,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform float rim_strength = 5.0;
uniform float rim_exponent = 30.0;
uniform float rim_power  = 1.0;

uniform float rim_floor  = 0.1;
uniform float rim_outer_strength = 3.0;
uniform float rim_outer_exponent = 3.0;

// Fade start and end distances
uniform float fade_start = 2e4;
uniform float fade_end = 4e4;
uniform float fade_power = 2.0;

uniform float alpha_clip :  hint_range(0.0, 1.0, 5e-4) = 1.0;

void fragment()
{
	float dt = clamp(abs(dot(NORMAL, VIEW)), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	float rim_outer = clamp(pow(dt, rim_outer_exponent)*rim_outer_strength, 1e-6, 1.0);
	
	// Calculate fade factor based on distance
	float distance_vert = length(VERTEX);
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);
	ALPHA = fade_factor;
	
	ALBEDO = albedo.rgb;
	ALBEDO *= rim_floor * rim_outer +  pow(rim, rim_power);

}
