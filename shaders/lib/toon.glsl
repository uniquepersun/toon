#ifndef TOON_GLSL
#define TOON_GLSL

#include "/lib/settings.glsl"
#include "/lib/crayon.glsl"
#include "/lib/shadow.glsl"

uniform sampler2D shadowtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 fogColor;
uniform float sunAngle;
uniform float rainStrength;
uniform float fogStart;
uniform float fogEnd;
uniform float viewHeight;
uniform float frameTimeCounter;

const vec3 NOON_SUN = vec3(0.72, 0.66, 0.52);
const vec3 SUNSET_SUN = vec3(0.85, 0.52, 0.32);
const vec3 MOON = vec3(0.16, 0.2, 0.32);
const vec3 DAY_AMBIENT = vec3(0.46, 0.5, 0.66);
const vec3 NIGHT_AMBIENT = vec3(0.1, 0.12, 0.22);
const vec3 TORCH = vec3(1.0, 0.72, 0.42);
const float MIN_LIGHT = 0.07;

float sampleSunShadow(vec3 viewPos, vec3 viewNormal, vec2 wobble) {
	vec3 feetPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	float dist = length(feetPos);
	feetPos += mat3(gbufferModelViewInverse) * viewNormal * (0.04 + dist * 0.0015);

	vec4 shadowClip = shadowProjection * (shadowModelView * vec4(feetPos, 1.0));
	vec3 shadowPos = distortShadowClip(shadowClip.xyz) * 0.5 + 0.5;
	shadowPos.xy += wobble * (2.0 / float(shadowMapResolution));

	if (any(lessThan(shadowPos.xy, vec2(0.0))) || any(greaterThan(shadowPos.xy, vec2(1.0)))) {
		return 1.0;
	}
	float lit = step(shadowPos.z - 0.0002, texture(shadowtex0, shadowPos.xy).r);
	return mix(lit, 1.0, smoothstep(shadowDistance * 0.85, shadowDistance, dist));
}

float crayonHatch(vec2 p, vec2 boil) {
	const float spacing = 7.0;
	float across = dot(p, vec2(0.7071, 0.7071)) + (valueNoise(p * 0.05 + boil) - 0.5) * 6.0;
	float lines = smoothstep(0.2, 0.7, sin(across * 6.2832 / spacing));
	return lines * (0.5 + 0.5 * valueNoise(p * 0.25 + boil));
}

vec3 flattenAlbedo(vec3 albedo, vec3 averaged) {
	vec3 flattened = mix(albedo, averaged, TEXTURE_FLATTEN);
	float luma = dot(flattened, vec3(0.299, 0.587, 0.114));
	return clamp(mix(vec3(luma), flattened, SATURATION), 0.0, 1.0);
}

// With hasNormal false (particles) surfaces get a flat share of sunlight and no cast shadow.
vec3 toonShade(vec3 albedo, vec3 viewPos, vec3 viewNormal, vec2 lightmap, bool hasNormal) {
	vec2 p = drawingCoord(gl_FragCoord.xy, viewHeight);
	vec2 boil = boilOffset(frameTimeCounter);
	float jitter = (valueNoise(p * 0.12 + boil) - 0.5) * 0.4;

	vec2 lm = clamp((lightmap - 0.03125) / 0.9375, 0.0, 1.0);
	float skyLight = roughBand(lm.y, LIGHT_BANDS, jitter);
	float blockLight = roughBand(pow(lm.x, 1.5), LIGHT_BANDS, jitter);

	float sunHeight = sin(sunAngle * 6.2832);
	float day = smoothstep(-0.05, 0.15, sunHeight);
	float sunset = 1.0 - smoothstep(0.0, 0.35, abs(sunHeight));

	float direct = 0.65;
	if (hasNormal) {
		float facing = dot(viewNormal, normalize(shadowLightPosition));
		direct = facing <= 0.0 ? 0.0 : (facing + jitter * 0.2 < 0.35 ? 0.65 : 1.0);
		if (direct > 0.0) {
			vec2 wobble = vec2(valueNoise(p * 0.08 + boil), valueNoise(p * 0.08 + boil + 19.0)) - 0.5;
			direct *= sampleSunShadow(viewPos, viewNormal, wobble);
		}
	}
	// Fades out the swap between sun and moon at the horizon, and blocks sunlight underground.
	direct *= smoothstep(0.0, 0.08, abs(sunHeight)) * smoothstep(0.2, 0.5, lm.y);
	direct *= 1.0 - rainStrength * 0.7;

	vec3 sunColor = mix(MOON, mix(NOON_SUN, SUNSET_SUN, sunset), day);
	vec3 ambient = mix(NIGHT_AMBIENT, DAY_AMBIENT, day);

	vec3 light = vec3(MIN_LIGHT) + ambient * skyLight + sunColor * direct + TORCH * blockLight;
	if (hasNormal) {
		float shaded = (1.0 - direct) * skyLight;
		light *= 1.0 - crayonHatch(p, boil) * shaded * HATCH_STRENGTH;
	}
	return albedo * light;
}

vec3 toonFog(vec3 color, vec3 viewPos) {
	vec2 p = drawingCoord(gl_FragCoord.xy, viewHeight);
	float jitter = (valueNoise(p * 0.12 + boilOffset(frameTimeCounter)) - 0.5) * 0.4;
	float depth = (length(viewPos) - fogStart) / max(fogEnd - fogStart, 0.001);
	return mix(color, fogColor, roughBand(clamp(depth, 0.0, 1.0), LIGHT_BANDS, jitter));
}

#endif
