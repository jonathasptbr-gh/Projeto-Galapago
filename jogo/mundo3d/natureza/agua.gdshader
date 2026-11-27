// ÁGUA DE GRADE (ensaio do P27) — a superfície desenhada a partir de
// sim/agua.gd. A regra é por célula; o desenho NÃO é cúbico:
//   campo      textura com 1 texel por célula (RGBA8), lida com filtro LINEAR:
//              R = profundidade × escala_prof, G/B = fluxo x/z (0,5 = parado),
//              A = umidade do chão (lida pelo natural.gdshader, não aqui)
//   campo_ret  (origem X, origem Z, 1/largura, 1/altura): uv = (XZ − ret.xy) × ret.zw
// A malha é uma lâmina fina que já segue o chão (o GDScript põe y = chão); o
// vértice sobe a profundidade interpolada. O fragmento some onde a água é
// mais rasa que um limiar com ruído — a borda da poça fica orgânica, não um
// quadrado —, ganha espuma clara na beirada, escurece com a profundidade e
// mostra filetes correndo na direção do fluxo. Compila no Mobile e no
// Compatibility (sem textura de tela, sem transparência: a borda é recorte).
shader_type spatial;
render_mode cull_back;

uniform sampler2D campo : filter_linear, repeat_disable;
uniform vec4 campo_ret = vec4(0.0, 0.0, 1.0, 1.0);
uniform float escala_prof = 2.0;
uniform float limiar = 0.012;
uniform vec3 raso : source_color = vec3(0.42, 0.84, 0.78);
uniform vec3 fundo : source_color = vec3(0.06, 0.48, 0.55);
uniform vec3 espuma : source_color = vec3(0.88, 0.98, 0.94);

varying float prof;
varying vec2 fluxo;
varying vec3 mundo;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 srgb_para_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 c = textureLod(campo, (mundo.xz - campo_ret.xy) * campo_ret.zw, 0.0);
	prof = c.r / escala_prof;
	fluxo = (c.gb - 0.5) * 2.0;
	// ondulação leve só onde há lâmina de verdade (low poly: facetas)
	float onda = sin(mundo.x * 3.1 + TIME * 2.2) * sin(mundo.z * 2.7 - TIME * 1.7);
	VERTEX.y += prof + 0.012 + onda * 0.012 * smoothstep(0.04, 0.15, prof);
}

void fragment() {
	float n = ruido(mundo.xz * 2.6) * 0.65 + ruido(mundo.xz * 7.0) * 0.35;
	float lim = limiar + (n - 0.5) * 0.03;
	if (prof < max(lim, 0.003)) {
		discard;
	}
	vec3 cor = mix(raso, fundo, smoothstep(0.02, 0.3, prof));
	// filetes: faixas finas correndo na direção do fluxo
	float vel = length(fluxo);
	if (vel > 0.01) {
		vec2 d = fluxo / vel;
		vec2 lado = vec2(-d.y, d.x);
		float faixa = fract(dot(mundo.xz, d) * 1.8 - TIME * 1.4 + ruido(mundo.xz * 1.7) * 1.2);
		float fio = step(0.9, faixa) * step(0.68, ruido(vec2(dot(mundo.xz, lado) * 5.0, 0.0)));
		cor = mix(cor, espuma, fio * smoothstep(0.01, 0.12, vel) * 0.7);
	}
	// espuma na beirada (onde a lâmina afina até sumir)
	float borda = 1.0 - smoothstep(lim, lim + 0.022, prof);
	cor = mix(cor, espuma, borda * 0.85);
	if (!OUTPUT_IS_SRGB) {
		cor = srgb_para_linear(cor);
	}
	ALBEDO = cor;
	ROUGHNESS = 0.18;
	SPECULAR = 0.65;
}
