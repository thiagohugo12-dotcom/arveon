shader_type canvas_item;

// Chão do Andar 3 composto em tempo real: a máscara (derivada do mapa aprovado)
// diz onde há terra, trilha e água; as superfícies vêm das amostras do tileset
// aprovado. Barrancos de terra aparecem no lado sul das ilhas, como no mapa.
uniform sampler2D mask_cells : filter_nearest;
uniform sampler2D mask_soft : filter_linear;
uniform vec2 cells = vec2(362.0, 271.0);
uniform float cell_size = 6.0;
uniform sampler2D grass_a : repeat_enable, filter_nearest;
uniform sampler2D grass_b : repeat_enable, filter_nearest;
uniform sampler2D dirt : repeat_enable, filter_nearest;
uniform sampler2D water : repeat_enable, filter_nearest;
uniform sampler2D bank : repeat_enable, filter_nearest;
uniform float bank_height = 18.0;
uniform float pixel = 2.0;

varying vec2 world;

void vertex() {
	world = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 soft(vec2 p) {
	return texture(mask_soft, p / (cells * cell_size));
}

// Terra com borda orgânica: máscara suavizada + ruído fino, sempre em pixels inteiros.
bool land(vec2 p) {
	return soft(p).r + (noise(p * 0.11) - 0.5) * 0.22 > 0.5;
}

bool path(vec2 p) {
	return soft(p).g + (noise(p * 0.09 + 7.0) - 0.5) * 0.30 > 0.5;
}

// Repetição com variação: cada ladrilho espelha de forma diferente para quebrar o padrão.
vec4 tiled(sampler2D tex, vec2 p, float salt) {
	vec2 side = vec2(textureSize(tex, 0));
	vec2 tile = floor(p / side);
	vec2 uv = fract(p / side);
	float h = hash(tile + salt);
	if (h > 0.5) uv.x = 1.0 - uv.x;
	if (fract(h * 7.0) > 0.5) uv.y = 1.0 - uv.y;
	return texture(tex, uv);
}

void fragment() {
	vec2 p = floor(world / pixel) * pixel + pixel * 0.5;
	vec4 color;
	if (land(p)) {
		float variation = noise(p / 190.0);
		color = variation > 0.52 ? tiled(grass_b, p, 3.0) : tiled(grass_a, p, 1.0);
		if (path(p)) {
			color = tiled(dirt, p, 5.0);
			// Borda da trilha: tufos de grama avançando sobre a terra.
			if (!path(p + vec2(0.0, -4.0)) || !path(p + vec2(0.0, 4.0)) || !path(p + vec2(-4.0, 0.0)) || !path(p + vec2(4.0, 0.0)))
				color.rgb = mix(color.rgb, vec3(0.42, 0.52, 0.20), 0.45);
		}
		// Contorno escuro da ilha onde ela encontra a água.
		if (!land(p + vec2(0.0, pixel * 2.0)) || !land(p + vec2(pixel * 2.0, 0.0)) || !land(p + vec2(-pixel * 2.0, 0.0)) || !land(p + vec2(0.0, -pixel * 2.0)))
			color.rgb = mix(color.rgb, vec3(0.13, 0.24, 0.10), 0.55);
	} else {
		color = tiled(water, p, 9.0);
		// Barranco: a terra logo acima desce em um paredão de raízes e lama.
		float above = 0.0;
		for (float d = pixel; d <= 18.0; d += pixel) {
			if (land(p - vec2(0.0, d))) { above = d; break; }
		}
		if (above > 0.0) {
			vec2 bank_uv = vec2(fract(p.x / 64.0), clamp(above / bank_height, 0.0, 1.0) * 0.95);
			color = texture(bank, bank_uv);
			color.rgb *= 1.0 - 0.35 * (above / bank_height);
		} else {
			// Reflexo escuro sob o barranco e espuma clara junto às margens.
			bool shadow = false;
			for (float d = 20.0; d <= 30.0; d += pixel * 2.0) {
				if (land(p - vec2(0.0, d))) { shadow = true; break; }
			}
			if (shadow) color.rgb *= 0.72;
			if (land(p + vec2(0.0, -pixel * 2.0)) || land(p + vec2(pixel * 2.0, 0.0)) || land(p + vec2(-pixel * 2.0, 0.0)) || land(p + vec2(0.0, pixel * 2.0)))
				color.rgb = mix(color.rgb, vec3(0.45, 0.70, 0.62), 0.35);
		}
	}
	COLOR = vec4(color.rgb, 1.0);
}
