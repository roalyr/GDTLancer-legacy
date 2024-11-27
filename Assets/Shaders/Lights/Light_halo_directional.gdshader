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
	depth_draw_never;

uniform vec4 albedo : hint_color;
uniform float rim_strength = 5.0;
uniform float rim_exponent = 30.0;
uniform float rim_power  = 0.5;

uniform float rim_floor  = 0.5;
uniform float rim_outer_strength = 3.0;
uniform float rim_outer_exponent = 3.0;
uniform float alpha_clip :   hint_range(0.0, 1.0, 5e-4) = 1.0;

uniform float scale:  hint_range(0.0, 100.0, 5e-4) = 1.0;
uniform float scale_max:  hint_range(0.0, 100.0, 5e-4) = 2.0;
uniform float beam_width_power :  hint_range(0.0, 2.0, 5e-4) = 1.0;
uniform float beam_width_focus :  hint_range(0.0, 10.0, 5e-4) = 0.8;
uniform float beam_dist_power :  hint_range(0.0, 1.0, 5e-4) = 0.4;

uniform float fade = 1.0;
uniform float fade_power:  hint_range(0.0, 10.0, 5e-4) = 1.0;



void vertex() {
	// Model absolute scale.
	float abs_scale = length(vec3(WORLD_MATRIX[0][0],WORLD_MATRIX[1][1],WORLD_MATRIX[2][2]));

	// Transform the vertex position to view space
	vec4 vertex_view_space = INV_CAMERA_MATRIX * WORLD_MATRIX * vec4(VERTEX, 1.0);

	// Calculate the distance from the vertex to the camera relative to object size
	float dist = length(vertex_view_space.xyz)/abs_scale;



    // Transform the vertex position to clip space
    vec4 clip_position = PROJECTION_MATRIX * INV_CAMERA_MATRIX * WORLD_MATRIX * vec4(VERTEX, 1.0);
	float x_offset = abs(clip_position.x / clip_position.w);

	float ratio = VIEWPORT_SIZE.x/VIEWPORT_SIZE.y;
	float distance_to_center_x = pow(x_offset, beam_width_power)*beam_width_focus;

	VERTEX *= pow(clamp(1.0/distance_to_center_x, 0.0, scale_max), 2.0);
	VERTEX *= pow(dist , beam_dist_power);
	VERTEX *= scale;

}

void fragment()
{
	float dist = length(VERTEX)/scale;
	float fd = pow(clamp(smoothstep(0.0, fade, dist), 1e-6, 1.0), fade_power); // fades out

	float dt = clamp(abs(dot(NORMAL, VIEW)), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	float rim_outer = clamp(pow(dt, rim_outer_exponent)*rim_outer_strength, 1e-6, 1.0);

	ALBEDO = albedo.rgb;
	ALBEDO *= rim_floor * rim_outer +  pow(rim, rim_power);
	ALBEDO *= fd;
	
}
