shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_add,
	cull_back,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : hint_color;
uniform float scale : hint_range(0.0, 5.0, 5e-4) = 1.0;
uniform float attenuation : hint_range(0.01, 2.0, 5e-4) = 0.5;
uniform float flare_distance : hint_range(0.0, 100.0, 5e-2) = 5.0;
uniform float flare_size : hint_range(1.0, 10.0, 5e-4) = 2.0;
uniform float intensity : hint_range(0.0, 1.0, 5e-4) = 0.5;
uniform float exponent : hint_range(0.0, 50.0, 5e-4) = 5.0;
uniform float pulse_factor : hint_range(0.5, 1.0, 5e-4) = 1.0;
uniform float pulse_rate : hint_range(0.0, 100.0, 5e-2) = 10;
uniform float phase : hint_range(0.0, 3.14, 5e-4) = 0.0;
uniform float distance_fade_max = 1e3;


void vertex() {
	float abs_scale = length(vec3(WORLD_MATRIX[0][0],WORLD_MATRIX[1][1],WORLD_MATRIX[2][2]));
	float z_dist = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z / abs_scale;
	float b = flare_distance/(z_dist + flare_distance);
	float scale_mod = clamp(pow(abs(b), attenuation), 0.0, flare_size);
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
	if (PROJECTION_MATRIX[3][3] != 0.0) {
		float h = abs(1.0 / (2.0 * PROJECTION_MATRIX[1][1]));
		float sc = (h * 2.0)*scale*scale_mod; //consistent with Y-fov
		MODELVIEW_MATRIX[0]*=sc;
		MODELVIEW_MATRIX[1]*=sc;
		MODELVIEW_MATRIX[2]*=sc;
	} else {
		float sc = -(MODELVIEW_MATRIX)[3].z*scale*scale_mod;
		MODELVIEW_MATRIX[0]*=sc;
		MODELVIEW_MATRIX[1]*=sc;
		MODELVIEW_MATRIX[2]*=sc;
	}

}

void fragment() {
	float pulse = (pulse_factor - sin(TIME * pulse_rate + phase) * (1.0 - pulse_factor));
	ALBEDO = albedo.rgb
	* pow(COLOR.r, exponent / pulse)
	* intensity
	* pulse;
	
	ALBEDO *= clamp(smoothstep(0.0, distance_fade_max, length(VERTEX)), 1e-6, 1.0);
}
