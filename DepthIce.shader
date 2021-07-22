// Saw a few of these in Unreal Engine and Unity but no Godot :(
// So I made one, check other comments for free textures and more info on the shader
shader_type spatial;

uniform sampler2D over_texture : hint_albedo;
uniform sampler2D under_texture : hint_albedo;
uniform sampler2D surface_normalmap : hint_normal;
// Here's a free CC0 ice texture -> https://ambientcg.com/view?id=Ice003
// You can use that for the over_texture and surface_normalmap
// Here's another CC0 ice texture -> https://ambientcg.com/view?id=Ice002
// You can use the displacement map of this texture as the under_texture

uniform vec4 top_color : hint_color = vec4(0.6764, 0.980092, 1.0, 1.0);
uniform float depth = 0.1;
uniform float normal_depth = 2.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform int method : hint_range(0, 3) = 1;
uniform float refractive_angle = 0.4;
uniform float refractive_index_1 = 0.4;
uniform float refractive_index_2 = 0.7;

// ========↓↓↓THIS PART OF THE CODE IS MIT LICENSED↓↓↓========
// GLSL Blend Overlay taken from https://github.com/jamieowen/glsl-blend/blob/master/overlay.glsl
float blendOverlay_f(float base, float blend) {
	return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}

vec3 blendOverlay(vec3 base, vec3 blend) {
	return vec3(blendOverlay_f(base.r,blend.r),blendOverlay_f(base.g,blend.g),blendOverlay_f(base.b,blend.b));
}
// ========↑↑↑THIS PART OF THE CODE IS MIT LICENSED↑↑↑========

varying vec3 vertex_normal;
void vertex(){
	vertex_normal = NORMAL;
}

void fragment(){
	// Camera vector from https://godotengine.org/qa/84799/beginner-help-with-simple-marching-shader-deformation-cube
	// Get camera position in World space coordinates
	vec3 ro = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	// Get fragment position in world space coordinates
	vec3 p = ((CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz);
	// Get the camera direction by subtracting the camera position from the fragment position
	vec3 rd = normalize(p - ro) * depth;
	
	vec3 normal = texture(surface_normalmap, UV).xyz;
	NORMALMAP = normal;
	NORMALMAP_DEPTH = normal_depth;
	
	vec3 refraction;
	if (method == 1){
		refraction = refract(rd, normal, refractive_angle);
	}else if (method == 2){
		float r = refractive_index_1 / refractive_index_2;
		vec3 n_rd = normalize(rd);
		float c = dot(-normal, n_rd);
		float rc = r * c;
		float root = sqrt( (1.0 - pow(r, 2.0)) * (1.0 - pow(c, 2.0)) );
		refraction = r * n_rd + (rc - root) * normal;
	}else if (method == 3){
		rd = normalize(p - ro - normal * refractive_index_1) * depth;
	}
	
	vec3 over_color = texture(over_texture, UV).rgb;
	vec3 color = blendOverlay(over_color, top_color.rgb);
	vec2 offset = rd.xz;
	vec3 under_color = texture(under_texture, UV + offset + refraction.xz).rgb;
	ALBEDO = blendOverlay(color, under_color);
	ROUGHNESS = roughness;
	METALLIC = metallic;
}

