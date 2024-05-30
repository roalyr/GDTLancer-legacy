shader_type spatial;


render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_back,
	
	unshaded,
	diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_alpha_prepass;

uniform vec4 albedo : hint_color;

uniform float rim_strength = 1.0;
uniform float rim_exponent : hint_range(0.0, 500.0, 0.1) = 5.0;

uniform float alpha_clip : hint_range(0,1) = 1.0;

uniform float distance_fade_min = 0.0;
uniform float distance_fade_max = 5.0;


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

// Add this to your vertex shader.
void vertex()
{
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;
}

void fragment()
{
	
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	
	ALBEDO = albedo.rgb*COLOR.rgb;
	ALPHA = rim;
	ALPHA *= clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 1e-6, alpha_clip);
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
