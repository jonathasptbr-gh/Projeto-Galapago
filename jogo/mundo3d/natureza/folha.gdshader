// Material das FOLHAS da mata (jogo/mundo3d/natureza): o mesmo contrato de
// natural.gdshader (cor por vértice × instância, luz padrão, COPA VAZADA em
// volta do foco), mas com as duas faces desenhadas e um pouco de luz
// atravessando a folha (BACKLIGHT) — a copa contra o sol fica verde-viva, não
// preta. Sem mapa do chão. Compila no Mobile e no Compatibility.
shader_type spatial;
render_mode cull_disabled;

uniform float rugosidade = 0.85;
uniform float especular = 0.25;
uniform vec3 translucidez = vec3(0.18, 0.26, 0.08);
uniform bool usar_foco = false;
uniform vec3 foco = vec3(0.0);
uniform float raio_foco = 1.9;
uniform float folga_foco = 0.9;

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
	ALBEDO = base;
	ROUGHNESS = rugosidade;
	SPECULAR = especular;
	BACKLIGHT = translucidez;
}
