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
uniform float rim_strength = 5.0;
uniform float rim_exponent = 30.0;
uniform float rim_power  = 1.0;

uniform float rim_floor  = 0.1;
uniform float rim_outer_strength = 3.0;
uniform float rim_outer_exponent = 3.0;


uniform float alpha_clip :  hint_range(0.0, 1.0, 5e-4) = 1.0;


uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;

// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
const float Fcoef = 0.001;
varying float gl_Position_z;


vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}

void vertex() {
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

}

void fragment()
{
	float dt = clamp(abs(dot(NORMAL, VIEW)), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, alpha_clip);
	float rim_outer = clamp(pow(dt, rim_outer_exponent)*rim_outer_strength, 1e-6, 1.0);
	ALBEDO = albedo.rgb;
	ALBEDO *= rim_floor * rim_outer +  pow(rim, rim_power);

}
