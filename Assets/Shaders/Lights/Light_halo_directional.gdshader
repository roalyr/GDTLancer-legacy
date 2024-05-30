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

uniform vec4 albedo : hint_color;
uniform float rim_strength = 0.05;
uniform float rim_exponent : hint_range(0.0, 50.0, 0.1) = 15.0;
uniform float alpha_clip : hint_range(0,1) = 1.0;
uniform float absolute_scale = 1.0;
uniform float directional_scale : hint_range(0,1) = 1.0;
uniform float scale_power = 1.0;
uniform float threshold : hint_range(0,1) = 1.0;


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

void vertex() {
	
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

	
	VERTEX *= absolute_scale;
	
    // get the vector from the object to the camera
    vec3 to_camera = normalize(CAMERA_MATRIX[3].xyz - WORLD_MATRIX[3].xyz);

    // get the forward vector of the camera
    vec3 camera_forward = -normalize(CAMERA_MATRIX[2].xyz);

    // calculate the dot product between the two vectors
    float dot_product = dot(to_camera, camera_forward);

    // map the dot product from the range [-1, 1] to [0, 1]
	float t = 1.0;
	if (dot_product < 0.0 - threshold){
		t = 0.0;
	} else {
		t = (dot_product + 1.0) / 2.0;
	}
    // calculate the new scale based on the mapped value
    float new_scale = pow(mix(directional_scale, 1.0, t), scale_power);

    // apply the new scale to the vertex position
    VERTEX /= new_scale;
}

void fragment()
{
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	ALBEDO = albedo.rgb*COLOR.rgb;
	ALPHA = rim;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
