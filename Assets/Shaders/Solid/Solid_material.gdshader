shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_back,
	
	//unshaded,
	diffuse_lambert, 
	specular_phong,
	
	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform sampler2D detail_map : hint_normal;
uniform sampler2D specular_map : hint_normal;

uniform vec4 albedo : hint_color;
uniform vec4 albedo_specular : hint_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 albedo_gloss : hint_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec4 emission : hint_color;
uniform float emission_strength : hint_range(0.0, 500.0, 0.1) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

uniform float albedo_exponent : hint_range(0.0, 50.0, 0.1) = 0.0;
uniform float specular_exponent : hint_range(0.0, 100.0, 0.1) = 5.0;
uniform float gloss_exponent : hint_range(0.0, 500.0, 0.1) = 500.0;
uniform float roughness_exponent : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float roughness_sharpness : hint_range(0.0, 100.0, 0.1) = 100.0;

//uniform float specular_clip : hint_range(0,1) = 1.0;
//uniform float gloss_clip : hint_range(0,1) = 1.0;

uniform float scale = 1.0;
uniform float details_power = 1.0;
uniform float specular_power = 1.0;


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
	
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float albedo_rim = clamp(pow(dt, albedo_exponent), 0.0, 1.0);
	float specular_rim = clamp(pow(dt, specular_exponent), 0.0, 1.0);
	float gloss_rim = clamp(pow(dt, gloss_exponent), 0.0, 1.0);
	float roughness_rim = clamp(pow(dt, roughness_exponent), 0.0, 1.0);
	
	float details = texture(detail_map, UV*scale).r;
	float speculars = texture(specular_map, UV*scale).r;

	ALBEDO = albedo.rgb*albedo_rim*pow(details, details_power) 
		+ albedo_specular.rgb*specular_rim*pow(speculars, specular_power)
		+ albedo_gloss.rgb*gloss_rim*pow(speculars, specular_power);
	ALBEDO *= COLOR.rgb ;
	EMISSION = emission.rgb * COLOR.rgb * emission_strength;
	ROUGHNESS =  1.0 - details*roughness * pow((1.0 - roughness_rim), roughness_sharpness);
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
