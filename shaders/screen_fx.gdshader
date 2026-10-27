shader_type canvas_item;
// Post-process for the game world: brightness, contrast, invert, high contrast and glitch.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float invert = 0.0;
uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float high_contrast = 0.0;
uniform float glitch = 0.0;
uniform float time_s = 0.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	if (glitch > 0.0) {
		float band = floor(uv.y * 45.0);
		float n = hash(band + floor(time_s * 24.0) * 7.31);
		if (n < glitch * 0.45) {
			uv.x += (n - 0.2) * 0.12 * glitch;
		}
	}
	vec3 c = texture(screen_tex, uv).rgb;
	if (glitch > 0.0) {
		c.r = texture(screen_tex, uv + vec2(0.005 * glitch, 0.0)).r;
		c.b = texture(screen_tex, uv - vec2(0.005 * glitch, 0.0)).b;
	}
	c = (c - 0.5) * contrast + 0.5;
	c *= brightness;
	if (high_contrast > 0.5) {
		float l = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, vec3(step(0.3, l)), 0.55);
	}
	c = clamp(c, 0.0, 1.0);
	c = mix(c, 1.0 - c, invert);
	COLOR = vec4(c, 1.0);
}
