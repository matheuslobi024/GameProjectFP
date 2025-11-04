shader_type spatial;
render_mode unshaded, fog_disabled;

uniform float lineHighlight = 0.2;
uniform float lineShadow = 0.55;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D normal_texture: hint_normal_roughness_texture, filter_nearest;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float normal_edge_indicator(vec3 normalEdgeBias, vec3 normal, vec3 neighborNormal, float depthDifference){
	float normalDifference = dot(normal - neighborNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDifference), 0.0, 1.0);
	float depthIndicator = clamp(sign(depthDifference * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
}

vec3 get_normal(vec2 uv, sampler2D normalTexture) {
    vec3 normal = texture(normalTexture, uv).rgb;
	normal = normal * 2.0 - 1.0;
	return normal;
}

float get_linear_depth(vec2 sUV, sampler2D depthTexture, mat4 inv_proj_mat) {
    float depth = texture(depthTexture, sUV).x;
    vec3 ndc = vec3(sUV * 2.0 - 1.0, depth);
    vec4 view = inv_proj_mat * vec4(ndc, 1.0);
    view.xyz /= view.w;
    return -view.z;
}

void fragment() {
	vec2 texelSize = 1.0 / VIEWPORT_SIZE.xy;
	
	vec2 UVOffsets[4];
	UVOffsets[0] = SCREEN_UV + vec2(0.0, -1.0) * texelSize;
	UVOffsets[1] = SCREEN_UV + vec2(0.0, 1.0) * texelSize;
	UVOffsets[2] = SCREEN_UV + vec2(1.0, 0.0) * texelSize;
	UVOffsets[3] = SCREEN_UV + vec2(-1.0, 0.0) * texelSize;
	
	float depthDifference = 0.0;
	float depth = get_linear_depth(SCREEN_UV, depth_texture, INV_PROJECTION_MATRIX);
	float invDepthDifference = 0.5;
float normalDifference = 0.0;
	vec3 normalEdgeBias = (vec3(1.0, 1.0, 1.0));
	vec3 normal = get_normal(SCREEN_UV, normal_texture);
	for (int i = 0; i < UVOffsets.length(); i++){
		float dOff = get_linear_depth(UVOffsets[i], depth_texture, INV_PROJECTION_MATRIX);
		depthDifference += clamp(dOff - depth, 0.0, 1.0);
		invDepthDifference += depth - dOff;
		vec3 nOff = get_normal(UVOffsets[i], normal_texture);
		normalDifference += normal_edge_indicator(normalEdgeBias, normal, nOff, depthDifference);
	}
	
	invDepthDifference = clamp(invDepthDifference, 0.0, 1.0);
	invDepthDifference = clamp(smoothstep(0.9, 0.9, invDepthDifference) * 10.0, 0.0, 1.0);
	depthDifference = smoothstep(0.25, 0.3, depthDifference);
	normalDifference = smoothstep(0.2, 0.2, normalDifference);
	normalDifference = clamp(normalDifference - invDepthDifference, 0.0, 1.0);
	
	float innerLines = clamp(normalDifference - depthDifference, 0.0, 1.0);
	float finalEdge = clamp(normalDifference + invDepthDifference, 0.0, 1.0);
	
	innerLines = clamp(normalDifference - depthDifference, 0.0, 1.0) * (1.0 - invDepthDifference);
	
	ALBEDO = texture(screen_texture, SCREEN_UV).rgb;
	
	ALBEDO += innerLines * lineHighlight;
	ALBEDO -= ALBEDO * invDepthDifference * lineShadow;
}
