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

uniform vec4 albedo : hint_color;
uniform sampler2D major_detail_noise : hint_normal;
uniform float inner_mask_size : hint_range(0.0, 1.0) = 0.4;
uniform float feathering_inner : hint_range(0.0, 1.0) = 0.02;
uniform float feathering_outer : hint_range(0.0, 1.0) = 0.02;
uniform float detail_decay_distance = 1e7;


// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
varying float gl_Position_z;

// https://godotshaders.com/snippet/circle/
// https://godotshaders.com/snippet/polar-coordinates/
vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}

// Add this to your vertex shader.
void vertex()
{
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;
}

void fragment(){
	vec2 polar_uv = polar_coordinates(UV.xy, vec2(0.5), 0.3, 1.0);
	float mask_outer = (1.0-vec3(circle(UV, 0.5-feathering_outer, feathering_outer))).r;
	float mask_inner = vec3(circle(UV, inner_mask_size, feathering_inner)).r;
	float ring_mask = texture(major_detail_noise, polar_uv).r;
	float fade = clamp(smoothstep(0.0, detail_decay_distance, length(VERTEX)), 0.0, 1.0);
	ALBEDO = ring_mask * COLOR.rgb * albedo.rgb;
	ALPHA = mask_outer * mask_inner * ring_mask * fade;
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
