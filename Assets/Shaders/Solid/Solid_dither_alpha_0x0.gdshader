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

// Rim
uniform float rim_strength = 1.0;
uniform float rim_exponent = 0.5;
uniform float rim_intensity = 0.3;

// Fade start and end distances
uniform float fade_start = 2e4;
uniform float fade_end = 6e4;
uniform float fade_power = 2.0;

// Dither threshold for the dithering effect
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.0;

// Near-field highlight
uniform float highlight_end = 1e3;
uniform float highlight_power = 2.0;
uniform float highlight_strength = 1.0;

uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_detail_alb : hint_albedo;
uniform sampler2D texture_detail_smr : hint_albedo;
uniform sampler2D microtexture_normal : hint_normal;

uniform float normal_strength = 1.0;
uniform float microtexture_strength = 1.0;
uniform float microtexture_blend : hint_range(0.0, 1.0) = 0.5;

uniform float detail_alb_strength = 1.0;
uniform float detail_smr_strength = 1.0;

varying vec3 uv_triplanar_pos;
uniform float uv_blend_sharpness : hint_range(0.0, 10.0) = 10.0;
varying vec3 uv_power_normal;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

uniform float texture_normal_scale = 1.0;
uniform float texture_detail_alb_scale = 1.0;
uniform float texture_detail_smr_scale = 1.0;
uniform float microtexture_normal_scale = 1.0;

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
	uv_power_normal=pow(abs(NORMAL),vec3(uv_blend_sharpness));
	uv_power_normal/=dot(uv_power_normal,vec3(1.0));
	uv_triplanar_pos = VERTEX * uv_scale + uv_offset;
	uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
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
	float rim = clamp(pow(abs(dot(NORMAL, VIEW)), rim_exponent)*rim_strength, 0.0, 1.0);
	
	// Load textures.
	vec3 normal = triplanar_texture(texture_normal,uv_power_normal,uv_triplanar_pos * texture_normal_scale).rgb;
	vec3 detail_alb = triplanar_texture(texture_detail_alb,uv_power_normal,uv_triplanar_pos * texture_detail_alb_scale).rgb;
	vec3 detail_smr = triplanar_texture(texture_detail_smr,uv_power_normal,uv_triplanar_pos * texture_detail_smr_scale).rgb;
	vec3 microtexture = triplanar_texture(microtexture_normal,uv_power_normal,uv_triplanar_pos * microtexture_normal_scale).rgb;
	
	// Set the material properties
	ALBEDO = albedo.rgb * COLOR.rgb;
	
	// Near-field highlight and microtexture
	ALBEDO += highlight_factor * highlight_strength;
	ALBEDO += detail_alb * detail_alb_strength;
	ALBEDO += (1.0-rim) * rim_intensity;
	
    EMISSION = emission.rgb * COLOR.rgb;
	
	// SMR
	SPECULAR = specular * detail_smr.r * detail_smr_strength;// * (1.0-rim) * rim_intensity;
    METALLIC = metallic * detail_smr.r * detail_smr_strength;// * (1.0-rim) * rim_intensity;
    ROUGHNESS = roughness * detail_smr.r * detail_smr_strength;// * (1.0-rim) * rim_intensity;
	
	// Switch between global and microtexture.
	NORMALMAP = mix(normal, microtexture * microtexture_strength, highlight_factor * microtexture_blend);
	NORMALMAP_DEPTH = normal_strength;
}
