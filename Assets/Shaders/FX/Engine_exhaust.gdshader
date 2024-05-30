shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_add,
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


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

void vertex()
{
	// Add this to your vertex shader.
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

	float a = ((cos(TIME*pulse_frequency)+1.0)*0.5);
	VERTEX.y = VERTEX.y*(a*pulse_amount + (1.0 - pulse_amount));
}

void fragment()
{
	ALBEDO = albedo.rgb * pow(COLOR.r, power);
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
