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
uniform float scale : hint_range(0.0, 5.0) = 0.1;
uniform float flare_distance = 1e11;
uniform float flare_size : hint_range(1.0, 10.0) = 3.0;
uniform float attenuation : hint_range(0.01, 2.0) = 0.2;
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float exponent : hint_range(0.0, 50.0, 0.1) = 5.0;
uniform float pulse_factor : hint_range(0.5, 1.0) = 1.0;
uniform float pulse_rate = 10.0;
uniform float phase : hint_range(0.0, 3.14) = 0.0;


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

void vertex() {
	// Add this to your vertex shader.
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

	    // get the vector from the object to the camera
    vec3 to_camera = normalize(CAMERA_MATRIX[3].xyz - WORLD_MATRIX[3].xyz);

    // get the forward vector of the camera
    vec3 camera_forward = -normalize(CAMERA_MATRIX[2].xyz);

    // calculate the dot product between the two vectors
    float dot_product = dot(to_camera, camera_forward);

    // map the dot product from the range [-1, 1] to [0, 1]
    float t = (dot_product + 1.0) / 2.0;

    // calculate the new scale based on the mapped value
    float angle_scale = pow(2.0 - mix(1.0, 2.0, t), 4.0);
	
	float z_dist = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
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
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
