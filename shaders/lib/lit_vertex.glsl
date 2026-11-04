#include "/lib/settings.glsl"

#ifdef USE_BLOCK_IDS
in vec2 mc_Entity;
uniform mat4 gbufferModelView;
#endif

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 viewNormal;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewNormal = normalize(gl_NormalMatrix * gl_Normal);
#ifdef USE_BLOCK_IDS
	// Cross-shaped plants have sideways normals, which would split them into light and dark halves.
	if (int(mc_Entity.x + 0.5) == BLOCK_PLANT) {
		viewNormal = gbufferModelView[1].xyz;
	}
#endif
}
