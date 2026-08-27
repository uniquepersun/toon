#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	// color = 1.0 - texture(colortex0, texcoord);
	color = vec4(
		texture(colortex0, texcoord).r,
		texture(colortex0, texcoord + 0.01).g,
		texture(colortex0, texcoord - 0.01).b,
		1.0
	);
	// Flips it
	// color = texture(colortex0, 1 - texcoord);
	// coloring
	// color = vec4(texture(colortex0, texcoord).r, 0.0,0.0,0.0);
	// less make the toon
}