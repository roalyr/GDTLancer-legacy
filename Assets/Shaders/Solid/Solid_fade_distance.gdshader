shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	//vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_back,
	
	//unshaded,
	diffuse_lambert, 
	specular_schlick_ggx,
	
	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform float distance_fade_max = 5.0;


void fragment()
{
	ALBEDO = albedo.rgb;
	ALBEDO *= clamp(smoothstep(distance_fade_max, 0.0, length(VERTEX)), 1e-6, 1.0);
	METALLIC = 0.4;
	ROUGHNESS = 0.6;
}
