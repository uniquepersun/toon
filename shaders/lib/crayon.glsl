#ifndef CRAYON_GLSL
#define CRAYON_GLSL

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash12(cell), hash12(cell + vec2(1.0, 0.0)), u.x),
		mix(hash12(cell + vec2(0.0, 1.0)), hash12(cell + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	return valueNoise(p) * 0.55 + valueNoise(p * 2.1 + 7.3) * 0.3 + valueNoise(p * 4.3 + 3.1) * 0.15;
}

// Offset that jumps a few times per second, which is what makes the drawing "boil".
vec2 boilOffset(float time) {
	float frame = mod(floor(time * BOIL_FPS), 16.0);
	return vec2(frame * 13.7, frame * 7.3);
}

// Pixel coordinates normalised to 1080p, so grain stays the same size at any resolution.
vec2 drawingCoord(vec2 fragCoord, float height) {
	return fragCoord * (1080.0 / height);
}

// Long, thin noise running along a diagonal, like the direction of a crayon stroke.
float crayonStroke(vec2 p, vec2 boil) {
	const mat2 strokeAngle = mat2(0.82, 0.57, -0.57, 0.82);
	return fbm((strokeAngle * p) * vec2(0.03, 0.3) + boil);
}

// Fine bumps of the paper surface.
float paperTooth(vec2 p, vec2 boil) {
	return fbm(p * 0.5 + boil);
}

float roughBand(float x, float steps, float jitter) {
	return clamp(floor(x * steps + jitter + 0.5) / steps, 0.0, 1.0);
}

#endif
