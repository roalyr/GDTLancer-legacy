shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	//use_debanding,

	// Blending and culling.
	blend_add,
	cull_back,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 rim_color : hint_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 overlay_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 surface_color : hint_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec4 fade_color : hint_color = vec4(1.0, 1.0, 0.0, 1.0);

uniform float major_phase : hint_range(0, 3.14) = 1.1;

uniform float major_detail_intensity = 0.5;
uniform float major_detail_level  = 1.0;
uniform float detail_decay_distance = 1e12;
uniform float detail_decay_power : hint_range(0.0, 5.0, 5e-4) = 2.0;

uniform sampler2D major_detail_noise : hint_albedo;

uniform float major_detail_scale : hint_range(1.0, 10.0, 1.0) = 1;

uniform float major_detail_flow = 0.01;

uniform float rim_strength = 1.0;
uniform float rim_exponent = 0.5;
uniform float rim_intensity = 0.3;

// Fade start and end distances
uniform float fade_start = 0;
uniform float fade_end = 1e6;
uniform float fade_power = 1.0;

const float pi = 3.1415926535;
const vec3 WHITE = vec3(1.0,1.0,1.0);


void fragment()
{
	vec2 p = texture(major_detail_noise, -UV*2.0*major_detail_scale).xy -TIME*major_detail_flow;
	float detail_major = sin(pow(texture(major_detail_noise, p).r, major_detail_level)*pi+major_phase);
	float rim = clamp(pow(abs(dot(NORMAL, VIEW)), rim_exponent)*rim_strength, 1e-6, 1.0);

	float distance_factor = clamp(pow(length(VERTEX)/detail_decay_distance, detail_decay_power), 0.0, 1.0);
	

	ALBEDO = abs(detail_major * major_detail_intensity * WHITE) * (1.0 - distance_factor);
	ALBEDO += overlay_color.rgb ;
	ALBEDO *= surface_color.rgb ;
	ALBEDO += fade_color.rgb * distance_factor;
	ALBEDO += (1.0-rim) * rim_color.rgb * rim_intensity * (1.0 - distance_factor);

	// Calculate the distance from the camera to the current fragment
    float distance_vert = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);
	ALPHA = fade_factor;

}