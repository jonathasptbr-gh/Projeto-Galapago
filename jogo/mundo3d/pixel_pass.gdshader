// Pixel Pass — pós da imagem interna (canvas_item no Sprite2D ampliado nearest).
// Contrato (a vista.gd preenche):
//   tam            px da imagem interna (com margem) — UV → px interno
//   celula_trama   deslocamento da trama: px interno p usa Bayer(p + celula_trama)
//                  (y para baixo), ancorando a trama no mundo (sim/camera3d.snap)
//   niveis         níveis por canal da quantização (2..256)
//   forca          força do dither Bayer 4×4 (0 = sem dither; ~1 = um degrau)
//   usar_lut / lut  OPCIONAL, desligado (P6): depois de quantizar, troca a cor
//                  pela da LUT. Formato: faixa (N·N)×N, N = niveis; fatia azul b
//                  em x ∈ [b·N, b·N+N), vermelho em x dentro da fatia, verde em y.
// Mobile (Vulkan) e Compatibility (OpenGL 3): GLSL ES 3.0 simples.
shader_type canvas_item;

uniform vec2 tam = vec2(360.0, 640.0);
uniform vec2 celula_trama = vec2(0.0);
uniform float niveis = 6.0;
uniform float forca = 0.7;
uniform bool usar_lut = false;
uniform sampler2D lut : filter_nearest;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// mod em float: índice certo também com celula_trama negativa
	vec2 p = mod(floor(UV * tam + celula_trama), 4.0);
	int i = int(p.x) + int(p.y) * 4;
	float b = BAYER[i] / 16.0 - 0.46875;
	float n = max(niveis, 2.0) - 1.0;
	vec3 q = clamp(floor(c.rgb * n + 0.5 + b * forca) / n, 0.0, 1.0);
	if (usar_lut) {
		float N = n + 1.0;
		vec3 k = floor(q * n + 0.5);
		vec2 uv_lut = vec2((k.b * N + k.r + 0.5) / (N * N), (k.g + 0.5) / N);
		q = texture(lut, uv_lut).rgb;
	}
	COLOR = vec4(q, 1.0);
}
