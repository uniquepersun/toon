#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// Read by Iris from the source text, so these must stay plain literals.
const int shadowMapResolution = 2048; // [1024 2048 4096]
const float shadowDistance = 96.0; // [64.0 96.0 128.0 192.0]
const float sunPathRotation = 25.0; // [0.0 15.0 25.0 40.0]

#define LINE_WIDTH 1.0 // [0.5 1.0 1.5 2.0]
#define LINE_OPACITY 0.8 // [0.4 0.6 0.8 1.0]
#define LINE_DARKEN 0.45 // [0.25 0.35 0.45 0.55 0.65]
#define LINE_WOBBLE 0.6 // [0.0 0.3 0.6 1.0]

#define CRAYON_STRENGTH 0.5 // [0.0 0.25 0.5 0.75 1.0]
#define HATCH_STRENGTH 0.16 // [0.0 0.08 0.16 0.24]
#define BOIL_FPS 6.0 // [0.0 4.0 6.0 8.0 12.0]

#define LIGHT_BANDS 4.0 // [3.0 4.0 5.0 6.0]
#define TEXTURE_FLATTEN 0.55 // [0.0 0.3 0.55 0.8]
#define SATURATION 1.2 // [1.0 1.1 1.2 1.3 1.4]

#define BLOCK_PLANT 10001

#endif
