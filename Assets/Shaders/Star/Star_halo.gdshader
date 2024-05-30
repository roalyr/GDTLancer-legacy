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

uniform vec4 halo_color : hint_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 corona_color : hint_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 core_color : hint_color = vec4(1.0, 0.9, 0.4, 1.0);

uniform float halo_strength : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float halo_exponent : hint_range(0.0, 50.0, 0.1) = 1.0;

uniform float corona_strength : hint_range(0.1, 1000.0, 0.1) = 500.0;
uniform float corona_exponent : hint_range(0.0, 50.0, 0.1) = 25.0;

uniform float core_strength : hint_range(0.1, 100.0, 0.1) = 100.0;
uniform float core_exponent : hint_range(0.0, 100.0, 0.1) = 32.0;

uniform float rim_exponent : hint_range(0.0, 50.0, 0.1) = 6.0;
uniform float alpha_clip : hint_range(0,1) = 1.0;

uniform sampler2D displacement_texture;
uniform float displacement_scale = 0.1;
uniform float displacement_velocity = 0.02;


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

void vertex() {
	
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

	
	vec2 tex_position_x = VERTEX.yz - TIME*displacement_velocity;
	vec2 tex_position_y = VERTEX.xz + TIME*displacement_velocity;
	vec2 tex_position_z = VERTEX.xy - TIME*displacement_velocity;
	
	float displacement_x = 2.0*texture(displacement_texture, tex_position_x).r-1.0;
	float displacement_y = 2.0*texture(displacement_texture, tex_position_y).r-1.0;
	float displacement_z = 2.0*texture(displacement_texture, tex_position_z).r-1.0;
	
	VERTEX.z += displacement_x * displacement_y * displacement_scale;
	VERTEX.x += displacement_y * displacement_z * displacement_scale;
	VERTEX.y += displacement_x * displacement_z * displacement_scale;
}

void fragment()
{
	float dt = clamp(dot(NORMAL,VIEW), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent), 1e-6, alpha_clip);
	float halo = clamp(pow(dt, halo_exponent)*halo_strength, 1e-6, 1.0);
	float corona = clamp(pow(dt, corona_exponent)*corona_strength, 1e-6, 1.0);
	float core = clamp(pow(dt, core_exponent)*core_strength, 1e-6, 1.0);
	
	ALBEDO = 
		+ halo*halo_color.rgb 
		+ corona*corona_color.rgb 
		+ core*core_color.rgb;
		
	ALPHA = rim;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
