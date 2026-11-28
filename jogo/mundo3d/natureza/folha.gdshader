// Material das FOLHAS da mata (jogo/mundo3d/natureza): o mesmo contrato de
// natural.gdshader (cor por vértice × instância, luz padrão, COPA VAZADA em
// volta do foco), mas com as duas faces desenhadas e um pouco de luz
// atravessando a folha (BACKLIGHT) — a copa contra o sol fica verde-viva, não
// preta. Sem mapa do chão. Compila no Mobile e no Compatibility.
//
// VENTO (docs/gdd/vento.md): balanço de VÉRTICE barato, por instância. O
// `mapa.gd` define `vento_amplitude` (> 0 só nas folhas) e `vento_altura` (a
// altura da família) e, a cada quadro, entrega o pacote de
// `sim/vento.gd`.uniformizar(): direção, força, banda da rajada (em MUNDO),
// turbulência e tempo. A base da planta fica parada; o topo anda em METROS.
// Sem `inverse()`, compute shader, textura nem loop: dois renderizadores.
shader_type spatial;
render_mode cull_disabled;

uniform float rugosidade = 0.85;
uniform float especular = 0.25;
uniform vec3 translucidez = vec3(0.18, 0.26, 0.08);
uniform bool usar_foco = false;
uniform vec3 foco = vec3(0.0);
uniform float raio_foco = 2.6;
uniform float folga_foco = 0.9;

// VENTO (docs/gdd/vento.md): balanço de vértice. `vento_amplitude` = 0 desliga
// (só as folhas da mata ligam; madeira, solo e pedra não balançam).
uniform float vento_amplitude = 0.0;
uniform float vento_altura = 9.0;
uniform vec2 vento_direcao = vec2(1.0, 0.0);
uniform float vento_forca = 0.0;
uniform vec2 vento_frente = vec2(0.0);
uniform float vento_frente_forca = 0.0;
uniform float vento_frente_largura = 7.5;
uniform float vento_turbulencia = 0.0;
uniform float vento_tempo = 0.0;

const float BAYER[16] = float[16](0.0, 0.5, 0.125, 0.625, 0.75, 0.25, 0.875, 0.375,
	0.1875, 0.6875, 0.0625, 0.5625, 0.9375, 0.4375, 0.8125, 0.3125);

vec3 srgb_para_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// Ruído barato por instância: tira as plantas da sincronia (cada uma com sua
// fase), sem buffer nem textura.
float vento_ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	if (vento_amplitude > 0.0) {
		// Origem da instância no MUNDO (MultiMesh: MODEL_MATRIX já a inclui).
		vec3 origem = MODEL_MATRIX[3].xyz;
		float fase = vento_ruido(origem.xz) * 6.2831853;
		// Quanto mais alto o vértice na planta, mais ele anda (base parada).
		float peso = pow(clamp(VERTEX.y / max(vento_altura, 0.01), 0.0, 1.0), 1.6);
		// Banda da rajada: gaussiana em volta da frente que o `mapa.gd` entrega.
		float d = dot(origem.xz - vento_frente, vento_direcao);
		float banda = vento_frente_forca * exp(-pow(d / max(vento_frente_largura, 0.01), 2.0));
		float forca = vento_forca + banda;
		float respira = 0.8 + 0.2 * sin(vento_tempo * 1.13 + fase);
		float tremor = vento_turbulencia * sin(vento_tempo * 2.7 + fase * 1.7);
		float balanco = vento_amplitude * peso * (forca * respira + tremor);
		// Um pouco de abertura/fechamento da folha, perpendicular ao vento.
		float travesso = 0.35 * balanco * sin(vento_tempo * 1.9 + fase * 2.3);
		vec2 lateral = vec2(-vento_direcao.y, vento_direcao.x);
		vec3 mundo = vec3(vento_direcao.x * balanco + lateral.x * travesso, 0.0,
			vento_direcao.y * balanco + lateral.y * travesso);
		// Mundo → local: eixos do modelo normalizados (instância só gira em Y e
		// escala uniforme). Divide pela escala: o deslocamento é em METROS.
		vec3 eixo_x = normalize(MODEL_MATRIX[0].xyz);
		vec3 eixo_z = normalize(MODEL_MATRIX[2].xyz);
		float escala = max(length(MODEL_MATRIX[0].xyz), 0.0001);
		VERTEX.x += dot(mundo, eixo_x) / escala;
		VERTEX.z += dot(mundo, eixo_z) / escala;
	}
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
