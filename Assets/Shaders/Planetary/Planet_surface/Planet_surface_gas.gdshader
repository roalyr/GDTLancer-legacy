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

uniform vec4 rim_color : hint_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 overlay_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 surface_color : hint_color = vec4(1.0, 1.0, 0.0, 1.0);

uniform float major_phase : hint_range(0, 3.14) = 2.0;
uniform float small_phase : hint_range(0, 3.14) = 1.0;
uniform float turbulent_phase : hint_range(0, 3.14) = 1.0;


uniform float major_detail_intensity = 1;
uniform float small_detail_intensity = 1;
uniform float turbulent_detail_intensity = 1;
uniform float detail_decay_distance =  2e8;

uniform sampler2D major_detail_noise : hint_normal;
uniform sampler2D small_detail_noise : hint_normal;
uniform sampler2D turbulent_detail_noise : hint_normal;


uniform float major_detail_scale : hint_range(1.0, 10.0, 1.0) = 1;
uniform float small_detail_scale : hint_range(1.0, 10.0, 1.0) = 1;
uniform float turbulent_detail_scale : hint_range(1.0, 10.0, 1.0) = 1;


uniform float major_detail_flow = 0.01;
uniform float small_detail_flow = 0.02;
uniform float turbulent_detail_flow = 0.02;


uniform float rim_strength = 6.0;
uniform float rim_exponent : hint_range(0.0, 50.0, 0.1) = 3.0;
uniform float rim_intensity = 0.1;

const float pi = 3.1415926535;
const vec3 WHITE = vec3(1.0,1.0,1.0);


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
	vec2 p = texture(major_detail_noise, -vec2(UV.x*1.0-TIME*major_detail_flow, UV.y*major_detail_scale)).xy;
	vec2 p2 = texture(small_detail_noise, -vec2(UV.x*1.0+TIME*small_detail_flow, UV.y*small_detail_scale)).xy;
	vec2 p3 = texture(turbulent_detail_noise, 
		-vec2(UV.x*turbulent_detail_scale, UV.y*(small_detail_scale - 1.0)*turbulent_detail_scale)).xy 
		- TIME*turbulent_detail_flow;
		
	float fade = clamp(smoothstep(0.0, detail_decay_distance, length(VERTEX)), 0.0, 1.0);
	
	float detail_major = sin(texture(major_detail_noise, p).r*pi+major_phase);
	float detail_small = sin(texture(small_detail_noise, p2).r*pi+small_phase);
	float detail_turbulent = (1.0-fade)*sin(texture(turbulent_detail_noise, p3).r*pi+turbulent_phase);
	
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, 1.0);
	
	ALBEDO = 
		+ detail_major * WHITE * major_detail_intensity
		+ detail_small * WHITE * small_detail_intensity
		+ detail_turbulent * WHITE * turbulent_detail_intensity;
		
		
	ALBEDO += overlay_color.rgb;
	ALBEDO *= surface_color.rgb;
	ALBEDO += (1.0-rim)*rim_color.rgb*rim_intensity;
	ROUGHNESS = 1.0;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}