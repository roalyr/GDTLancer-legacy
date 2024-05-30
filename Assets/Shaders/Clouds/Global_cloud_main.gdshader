shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_disabled,
	
	unshaded,
	diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform vec4 albedo_outer : hint_color;
uniform vec4 albedo_detail : hint_color;

uniform sampler2D major_detail_noise;
uniform float major_detail_scale = 1.0;
uniform float major_detail_phase = 1.0;
uniform float factor = 1.0;

uniform float distance_fade_detail = 0;
uniform float distance_fade_outer_rim = 1e19;

uniform float rim_strength = 1.0;
uniform float rim_exponent : hint_range(0.0, 10.0) = 1.0;

uniform float color_power_r = 1.0;
uniform float color_power_g = 1.0;
uniform float color_power_b = 1.0;
uniform float color_multiplier_r = 1.0;
uniform float color_multiplier_g = 1.0;
uniform float color_multiplier_b = 1.0;


const float pi = 3.1415926535;

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
	vec2 p = texture(major_detail_noise, -UV * 2.0 * major_detail_scale).yx;
	
	float detail_major = sin(texture(major_detail_noise, UV*major_detail_scale).r*pi+major_detail_phase);
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, 1.0);
	float dist = length(VERTEX);
	
	ALBEDO = albedo.rgb*rim;
	ALBEDO += (1.0-rim)*albedo_outer.rgb*(1.0-clamp(smoothstep(0.0, distance_fade_outer_rim, dist), 1e-6, 1.0));
	ALBEDO *= COLOR.rgb;
	ALBEDO += clamp(pow((1.0-rim), factor)*albedo_detail.rgb*detail_major*clamp(smoothstep(0.0, distance_fade_detail, dist), 1e-6, 1.0), 0.0, 1.0);

	
	ALBEDO = vec3(
		pow(ALBEDO.r, color_power_r)*color_multiplier_r,
		pow(ALBEDO.g, color_power_g)*color_multiplier_g,
		pow(ALBEDO.b, color_power_b)*color_multiplier_b
	);
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
