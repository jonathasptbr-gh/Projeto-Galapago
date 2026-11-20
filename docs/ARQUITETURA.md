# Arquitetura

## As duas camadas (a regra que mais se paga)

| camada | pasta | pode | não pode |
|---|---|---|---|
| **simulação** | `sim/` | dados, matemática, sorteio com semente | nó, cena, `Input`, `_process`, tempo real, `randf()` global |
| **apresentação** | `jogo/` | ler toque, desenhar, animar, tocar som, chamar a `sim/` | decidir regra de jogo |

Por quê: tudo o que define o jogo (trajetória, gestos, afinidade,
personalidade, evolução por vivência) fica **testável headless e
reproduzível**. Isso permite:

- testes unitários no CI e aqui (`tools/testes.sh`);
- **simulação em massa** — rodar milhares de "vidas" de criatura com sementes
  diferentes e medir a distribuição dos ramos de evolução (balanceamento por
  estatística, não por palpite). Previsto no pacote P5.

`sim/` usa `RandomNumberGenerator` com semente explícita, passado como
argumento — nunca o sorteio global.

## Dados de design

Espécies-base, traços, gatilhos de vivência e ramos de evolução moram em
**dados** (`dados/*.json` ou `Resource` `.tres`, decisão do pacote P4/P5), não
em código: mudar o design não exige mexer na lógica.

## Pipeline previsto da criatura (pacotes P3–P6)

```
toque → gesto/trajetória (sim/gestos, sim/trajetoria)
      → INTENÇÃO
      → decisão da criatura (sim/afinidade: afinidade × temperamento × humor)
        → obedece | hesita | reinterpreta | desobedece
      → ação na arena (jogo/)
vivência acumulada (sim/vivencia) → perfil de traços → evolução → troca de PEÇAS
```

Sincronia e Autonomia Mestra são **modos do mesmo pipeline**, não sistemas
separados.

## Renderização

`gl_compatibility` (OpenGL 3.3 / GLES 3): roda em celular modesto e é o único
que o oráculo de quadros renderiza sem GPU. Resolução interna 320×180,
ampliação por inteiro, filtro *nearest*, *snap* de pixel ligado.
