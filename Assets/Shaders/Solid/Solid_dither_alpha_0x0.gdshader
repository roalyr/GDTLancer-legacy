shader_type spatial;

render_mode
	//vertex_lighting,
    blend_mix,
    cull_back,
    diffuse_oren_nayar,
    specular_schlick_ggx,
    depth_draw_always; // Ensures depth testing with alpha support

// Material properties
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float specular : hint_range(0.0, 5.0) = 0.5;
uniform float metallic : hint_range(-5.0, 5.0) = 1.0;
uniform float roughness : hint_range(-5.0, 5.0) = 0.5;
uniform float smr_multiplier : hint_range(-10.0, 10.0) = 1.0;

// Fade start and end distances
uniform float fade_start = 2e4;
uniform float fade_end = 4e4;
uniform float fade_power = 2.0;

// Dither threshold for the dithering effect
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.0;

uniform float highlight_end = 1e3;
uniform float highlight_power = 2.0;
uniform float highlight_strength = 0.0;

uniform sampler2D texture_normal_1 : hint_normal;
uniform sampler2D texture_normal_2 : hint_normal;

uniform sampler2D texture_detail_1 : hint_albedo;
uniform sampler2D texture_detail_2 : hint_albedo;

uniform float detail_blend_factor : hint_range(0.0, 1.0) = 0.5;

uniform float normal_scale : hint_range(-16,16) = 0.0;
uniform float normal_blend_factor : hint_range(0.0, 1.0) = 0.5;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 10.0) = 10.0;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale = vec3(0.5);
uniform vec3 uv1_offset = vec3(0.0);

varying vec3 uv2_triplanar_pos;
uniform float uv2_blend_sharpness : hint_range(0.0, 10.0) = 10.0;
varying vec3 uv2_power_normal;
uniform vec3 uv2_scale = vec3(1.0);
uniform vec3 uv2_offset = vec3(0.0);

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv2_power_normal=pow(abs(NORMAL),vec3(uv2_blend_sharpness));
	uv2_power_normal/=dot(uv2_power_normal,vec3(1.0));
	uv2_triplanar_pos = VERTEX * uv2_scale + uv2_offset;
	uv2_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

void fragment() {
    // Calculate the distance from the camera to the current fragment
    float distance_vert = length(VERTEX);

    // Calculate fade factor based on distance
    float fade_factor = pow(clamp((fade_end - distance_vert) / (fade_end - fade_start), 0.0, 1.0), fade_power);

	// Set a threshold below which fragments are fully transparent
	if (fade_factor < alpha_threshold && fade_factor > 0.01) {
	    ALPHA = alpha_threshold;
	} else if (fade_factor < 0.01) {
		ALPHA = 0.0;
	} else {
		ALPHA = fade_factor;
	}
	
	float highlight_factor = pow(clamp((highlight_end - distance_vert) / highlight_end, 0.0, 1.0), highlight_power); 
	
    // Set the material properties
    ALBEDO = albedo.rgb * COLOR.rgb;
	ALBEDO += highlight_factor * highlight_strength;
    EMISSION = emission.rgb * COLOR.rgb;

	vec3 normal_1 = triplanar_texture(texture_normal_1,uv1_power_normal,uv1_triplanar_pos).rgb;
	vec3 normal_2 = triplanar_texture(texture_normal_2,uv2_power_normal,uv2_triplanar_pos).rgb;
	
	vec3 detail_1 = triplanar_texture(texture_detail_1,uv1_power_normal,uv1_triplanar_pos).rgb;
	vec3 detail_2 = triplanar_texture(texture_detail_2,uv2_power_normal,uv2_triplanar_pos).rgb;
	vec3 details = mix(detail_1, detail_2, detail_blend_factor) * smr_multiplier;
	
	SPECULAR = specular * details.r;
    METALLIC = metallic * details.g;
    ROUGHNESS = roughness * details.b;
	
	NORMALMAP = mix(normal_1, normal_2, normal_blend_factor);
	NORMALMAP_DEPTH = normal_scale;
}
