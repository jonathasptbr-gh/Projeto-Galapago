// Material NATURAL da mata (jogo/mundo3d/natureza): luz padrão do Godot
// (contínua, sem as faixas do toon), cor por vértice (× cor da instância da
// MultiMesh), sem textura de imagem.
// Contrato:
//   rugosidade / especular   — resposta ao sol (chão e casca: ásperos)
//   usar_chao / chao / chao_ret — o MAPA DO CHÃO (jogo/mundo3d/chao.gd), como no
//                  toon.gdshader: RGBA8 PREMULTIPLICADA e sRGB, uv = (XZ do
//                  mundo − ret.xy) × ret.zw, só em face voltada para cima, ANTES
//                  da luz (a sombra cai sobre o caminho). Só o solo liga.
//   usar_foco / foco / raio_foco / folga_foco — COPA VAZADA: o que está entre
//                  a câmera e o foco (a criatura), dentro de `raio_foco` na
//                  tela e mais de `folga_foco` à frente dele, some por dither
//                  ordenado 4×4 — a criatura nunca some sob a mata. Fora do
//                  passe de sombra (a sombra continua inteira).
// A cor por vértice vem em sRGB: convertida a linear só quando a saída não é
// sRGB (Mobile), como o toon. Compila no Mobile e no Compatibility.
shader_type spatial;
render_mode cull_back;

uniform float rugosidade = 0.92;
uniform float especular = 0.2;
uniform bool usar_chao = false;
uniform sampler2D chao : filter_linear, repeat_disable;
uniform vec4 chao_ret = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool usar_foco = false;
uniform vec3 foco = vec3(0.0);
uniform float raio_foco = 2.6;
uniform float folga_foco = 0.9;
// CHÃO MOLHADO (água de grade, P27; o ensaio está no commit 64f0d2f): o canal A do campo
// da água é a umidade da célula; o chão escurece e brilha um pouco onde está
// molhado. Desligado por padrão (a mata do jogo não muda).
uniform bool usar_umidade = false;
uniform sampler2D campo_agua : filter_linear, repeat_disable;
uniform vec4 campo_ret = vec4(0.0, 0.0, 1.0, 1.0);

const float BAYER[16] = float[16](0.0, 0.5, 0.125, 0.625, 0.75, 0.25, 0.875, 0.375,
	0.1875, 0.6875, 0.0625, 0.5625, 0.9375, 0.4375, 0.8125, 0.3125);

vec3 srgb_para_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	if (usar_foco && !IN_SHADOW_PASS) {
		vec3 fv = (VIEW_MATRIX * vec4(foco, 1.0)).xyz;
		float dentro = 1.0 - smoothstep(raio_foco * 0.55, raio_foco, length(VERTEX.xy - fv.xy));
		float frente = smoothstep(folga_foco, folga_foco + 0.6, VERTEX.z - fv.z);
		ivec2 q = ivec2(FRAGCOORD.xy) % 4;
		if (dentro * frente * 0.9 > BAYER[q.y * 4 + q.x]) {
			discard;
		}
	}
	vec3 base = COLOR.rgb;
	if (!OUTPUT_IS_SRGB) {
		base = srgb_para_linear(base);
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
	float rug = rugosidade;
	if (usar_umidade) {
		vec3 m = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float u = texture(campo_agua, (m.xz - campo_ret.xy) * campo_ret.zw).a;
		base *= mix(1.0, 0.6, u);
		rug = mix(rugosidade, 0.35, u);
	}
	ALBEDO = base;
	ROUGHNESS = rug;
	SPECULAR = especular;
}
