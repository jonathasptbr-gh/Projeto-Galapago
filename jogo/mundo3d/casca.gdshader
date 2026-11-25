// Casca invertida — contorno escuro desenhado como passe extra (next_pass) ou
// como malha própria (a casca do terreno já vem inflada: espessura = 0).
// Contrato:
//   cor_contorno   source_color — cor da linha
//   espessura      unidades 3D que a casca cresce para fora
//   forma          0 = pela normal (malhas lisas: esfera, cápsula)
//                  1 = caixa centrada na origem (VERTEX += sign(VERTEX)·esp:
//                      cresce a caixa inteira, sem rachar nos cantos)
//                  2 = cilindro centrado (raio em xz + sign(y) em y)
// cull_front: só as faces de trás aparecem, e só onde passam da silhueta.
// Mobile (Vulkan) e Compatibility (OpenGL 3): nada além de vertex/fragment.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 cor_contorno : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float espessura = 0.05;
uniform int forma = 0;

void vertex() {
	if (forma == 1) {
		VERTEX += sign(VERTEX) * espessura;
	} else if (forma == 2) {
		vec2 r = VERTEX.xz;
		float l = length(r);
		if (l > 0.0001) {
			VERTEX.xz += r / l * espessura;
		}
		VERTEX.y += sign(VERTEX.y) * espessura;
	} else {
		VERTEX += NORMAL * espessura;
	}
}

void fragment() {
	ALBEDO = cor_contorno.rgb;
}
