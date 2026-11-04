#ifndef SHADOW_GLSL
#define SHADOW_GLSL

// Spends more shadow map resolution close to the player.
vec3 distortShadowClip(vec3 clip) {
	clip.xy /= length(clip.xy) + 0.1;
	clip.z *= 0.5;
	return clip;
}

#endif
