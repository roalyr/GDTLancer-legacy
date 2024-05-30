shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_front,
	
	unshaded,
	//diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform float rim_strength = 0.05;
uniform float rim_exponent : hint_range(0.0, 50.0, 0.1) = 15.0;
uniform float alpha_clip : hint_range(0,1) = 1.0;

uniform sampler2D displacement_texture;
uniform float displacement_scale = 0.02;
uniform float displacement_velocity = 0.01;

// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

void vertex() {
	// Add this to your vertex shader.
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

	
	vec2 tex_position_x = VERTEX.yz / 1.0 - TIME*displacement_velocity;
	vec2 tex_position_y = VERTEX.xz / 1.0 + TIME*displacement_velocity;
	vec2 tex_position_z = VERTEX.xy / 1.0 - TIME*displacement_velocity;
	
	float displacement_x = 2.0*texture(displacement_texture, tex_position_x).r-1.0;
	float displacement_y = 2.0*texture(displacement_texture, tex_position_y).r-1.0;
	float displacement_z = 2.0*texture(displacement_texture, tex_position_z).r-1.0;
	
	VERTEX.z += displacement_z * displacement_scale;
	VERTEX.x += displacement_x * displacement_scale;
	VERTEX.y += displacement_y * displacement_scale;
}

void fragment()
{
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	ALBEDO = albedo.rgb*COLOR.rgb;
	ALPHA = rim;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
