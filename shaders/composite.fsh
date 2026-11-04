#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/crayon.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

const vec3 PAPER = vec3(0.98, 0.96, 0.9);

float linearDepth(vec2 uv) {
	float ndc = texture(depthtex0, uv).r * 2.0 - 1.0;
	return 2.0 * near * far / (far + near - ndc * (far - near));
}

vec3 sampleNormal(vec2 uv) {
	return texture(colortex1, uv).rgb * 2.0 - 1.0;
}

void main() {
	vec2 p = drawingCoord(gl_FragCoord.xy, viewHeight);
	vec2 boil = boilOffset(frameTimeCounter);
	vec3 base = texture(colortex0, texcoord).rgb;

	vec2 texel = LINE_WIDTH * (viewHeight / 1080.0) / vec2(viewWidth, viewHeight);
	vec2 wobble = vec2(valueNoise(p * 0.03 + boil), valueNoise(p * 0.03 + boil + 31.0)) - 0.5;
	vec2 uv = texcoord + wobble * 2.0 * LINE_WOBBLE * texel;

	vec2 offsets[4] = vec2[4](vec2(-texel.x, 0.0), vec2(texel.x, 0.0), vec2(0.0, -texel.y), vec2(0.0, texel.y));
	float depths[4];
	float center = linearDepth(uv);
	vec3 centerNormal = sampleNormal(uv);

	float nearest = center;
	vec2 nearestUV = uv;
	float normalEdge = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 neighbor = uv + offsets[i];
		depths[i] = linearDepth(neighbor);
		normalEdge = max(normalEdge, 1.0 - dot(centerNormal, sampleNormal(neighbor)));
		if (depths[i] < nearest) {
			nearest = depths[i];
			nearestUV = neighbor;
		}
	}

	// The second difference stays near zero across flat surfaces, even at grazing angles.
	float curve = max(abs(depths[0] + depths[1] - 2.0 * center), abs(depths[2] + depths[3] - 2.0 * center));
	float edge = smoothstep(0.03, 0.08, curve / center);
	if (texture(depthtex0, uv).r < 1.0) {
		edge = max(edge, smoothstep(0.3, 0.6, normalEdge));
	}
	edge *= 1.0 - smoothstep(far * 0.5, far * 0.9, nearest);

	float stroke = crayonStroke(p, boil);
	float tooth = paperTooth(p, boil);

	// Lines take the colour of the closer surface, so they read as a darker shade of the object.
	vec3 lineColor = texture(colortex0, nearestUV).rgb * LINE_DARKEN;
	base = mix(base, lineColor, edge * LINE_OPACITY * (0.65 + 0.35 * stroke));

	// Dark areas are pressed harder, so less paper shows through them.
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	float gaps = smoothstep(0.52, 0.68, tooth * 0.6 + stroke * 0.4) * mix(0.35, 1.0, luma);
	base = mix(base, PAPER, gaps * CRAYON_STRENGTH * 0.6);
	base *= 1.0 + (stroke - 0.5) * 0.25 * CRAYON_STRENGTH;

	color = vec4(base, 1.0);
}
