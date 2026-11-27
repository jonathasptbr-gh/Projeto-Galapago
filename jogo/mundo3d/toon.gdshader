// Toon (luz em faixas) — material das superfícies do mundo 3D (jogo/mundo3d).
// Contrato:
//   cor            source_color — cor base
//   textura        opcional (usar_textura = true): multiplica a cor, filtro nearest
//   limiar_alto / limiar_baixo   — onde N·L × sombra troca de faixa
//   nivel_alto / nivel_medio / nivel_baixo — brilho de cada faixa, PERCEPTUAL:
//                  a cor na tela ≈ cor × nível (sRGB), nos dois renderizadores
// A sombra do sol entra por ATTENUATION ANTES do limiar: sombra vira faixa,
// sem gradiente. Cada troca de faixa é um smoothstep de meia-largura
// fwidth(n) × `suavidade` (AA analítico: ~1 px de rampa na tela, em qualquer
// resolução), limitada a `largura_max` para a faixa não virar degradê.
// A faixa mais baixa É a luz ambiente: a vista desliga o ambiente e o
// reflexo do WorldEnvironment, e o sol tem energia 1 e cor branca
// (LIGHT_COLOR / PI = 1). Isso porque o Compatibility (prévia, fallback) soma a
// luz em sRGB e o Mobile em linear (medido no oráculo, 2026-11-25): com o
// nível convertido por OUTPUT_IS_SRGB, a mesma faixa dá o mesmo brilho nos
// dois. Só um DirectionalLight3D é previsto (outras luzes somariam faixas).
// MAPA DO CHÃO (S5b, era do material do TERRENO da ilha da Fundação, removida em 2026-11-27; reserva):
//   usar_chao      liga a amostragem (padrão desligado: os outros materiais
//                  não mudam)
//   chao           a textura do SubViewport `jogo/mundo3d/chao.gd` (RGBA8
//                  PREMULTIPLICADA, sRGB), linear, sem mipmap, sem repetir
//   chao_ret       (origem X, origem Z em unidades, escala X, escala Z):
//                  uv = (XZ do mundo − ret.xy) × ret.zw
// A cor do chão entra no ALBEDO (antes da luz: a sombra cai sobre o caminho),
// só em face voltada para CIMA (normal do mundo y > ~0,7: não escorre pelas
// paredes). Convertida sRGB → linear só quando a saída não é sRGB (Mobile).
// Compila no Mobile (Vulkan) e no Compatibility (OpenGL 3): só light(),
// uniforms comuns, fwidth, INV_VIEW_MATRIX e OUTPUT_IS_SRGB — nada de textura
// de tela nem Forward+.
shader_type spatial;

uniform vec4 cor : source_color = vec4(1.0);
uniform bool usar_textura = false;
uniform sampler2D textura : source_color, filter_nearest, repeat_enable;
uniform float limiar_alto = 0.55;
uniform float limiar_baixo = 0.15;
uniform float nivel_alto = 1.0;
uniform float nivel_medio = 0.74;
uniform float nivel_baixo = 0.52;
uniform float suavidade = 0.75;
uniform float largura_max = 0.08;
uniform bool usar_chao = false;
uniform sampler2D chao : filter_linear, repeat_disable;
uniform vec4 chao_ret = vec4(0.0, 0.0, 1.0, 1.0);

vec3 srgb_para_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	vec3 base = cor.rgb;
	if (usar_textura) {
		base *= texture(textura, UV).rgb;
	}
	if (usar_chao) {
		vec3 mundo = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float cima = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
		vec4 marca = texture(chao, (mundo.xz - chao_ret.xy) * chao_ret.zw);
		float a = marca.a * smoothstep(0.6, 0.8, cima);
		if (a > 0.001) {
			vec3 c = clamp(marca.rgb / max(marca.a, 0.001), 0.0, 1.0);
			if (!OUTPUT_IS_SRGB) {
				c = srgb_para_linear(c);
			}
			base = mix(base, c, a);
		}
	}
	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float n = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float w = clamp(fwidth(n) * suavidade, 0.0001, largura_max);
	float alto = smoothstep(limiar_alto - w, limiar_alto + w, n);
	float medio = smoothstep(limiar_baixo - w, limiar_baixo + w, n);
	float f = mix(nivel_baixo, mix(nivel_medio, nivel_alto, alto), medio);
	if (!OUTPUT_IS_SRGB) {
		f = pow(f, 2.2);  // multiplicador perceptual → linear
	}
	DIFFUSE_LIGHT += f * LIGHT_COLOR / PI;
}
