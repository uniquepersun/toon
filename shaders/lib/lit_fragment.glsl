#include "/lib/toon.glsl"

uniform sampler2D gtexture;
#ifdef USE_ENTITY_COLOR
uniform vec4 entityColor;
#endif

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 viewNormal;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normalData;

void main() {
	vec4 albedo = texture(gtexture, texcoord);
	albedo.rgb = flattenAlbedo(albedo.rgb, textureLod(gtexture, texcoord, 3.0).rgb);
	albedo *= glcolor;
#ifdef USE_ENTITY_COLOR
	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif
	if (albedo.a < alphaTestRef) {
		discard;
	}

#ifdef NO_SURFACE_NORMAL
	vec3 normal = vec3(0.0, 0.0, 1.0);
	color.rgb = toonShade(albedo.rgb, viewPos, normal, lmcoord, false);
#else
	vec3 normal = normalize(viewNormal);
	color.rgb = toonShade(albedo.rgb, viewPos, normal, lmcoord, true);
#endif
	color.rgb = toonFog(color.rgb, viewPos);
	color.a = albedo.a;
	normalData = vec4(normal * 0.5 + 0.5, 1.0);
}
