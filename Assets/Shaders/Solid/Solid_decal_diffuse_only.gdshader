shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_back,
	
	//unshaded,
	diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha : hint_range(0,1) = 1.0;
uniform float contrast_diffuse : hint_range(0,5) = 1.0;


uniform sampler2D texture_alpha : hint_normal;
uniform sampler2D texture_diffuse : hint_normal;


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
	ALBEDO = albedo.rgb*COLOR.rgb*pow(texture(texture_diffuse, UV).r, contrast_diffuse);
	ALPHA = alpha*texture(texture_alpha, UV).r;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
