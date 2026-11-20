# Pipeline de arte

## Ferramenta: PixelLab (MCP)

PixelLab gera pixel art de jogo: personagens 4/8 direções (com *templates* de
quadrúpede: `dog`, `cat`, `horse`, `lion`, `bear`, ou `custom` sem esqueleto),
animações, **estados/variantes de um mesmo personagem**
(`create_character_state`, mantém identidade e proporções), tilesets, mapas,
objetos, edição/inpaint, efeitos sonoros e música. Referência das ferramentas:
<https://api.pixellab.ai/mcp/docs>. Tudo é **assíncrono** (job → ~2–5 min →
`get_*`) e **cobrado em gerações** — o custo de cada chamada está na doc; as
ferramentas `get_*_capabilities` cotam de graça antes de gastar.

### Conexão (pacote P1)

- Chave: <https://api.pixellab.ai/mcp> (conta do operador). Vai para o cofre do
  harness (`~/.dsh/.credentials.yaml`, `refs`), **nunca** para chat, commit ou
  documento.
- Servidor MCP HTTP `https://api.pixellab.ai/mcp`, cabeçalho
  `Authorization: Bearer <chave>`, como entrada `@deepseek-ai/dsh-mcp-client`
  (`transport: streamable-http`) no perfil do DSH. As ferramentas aparecem como
  `mcp__pixellab__*` numa **sessão nova**.

## Regras de produção

1. **Uma âncora de estilo por projeto.** Paleta-mestra fixa (`arte/paleta.json`,
   a criar no P6) passada em `palette` em toda geração; uma imagem de estilo
   aprovada pelo operador reutilizada em `style_image`/`style_character_id`.
   Consistência entre evoluções é o problema difícil — ela se COMPRA com âncora
   fixa, não se espera da IA.
2. **Evolução = variante + peças.** Forma-base gerada uma vez; as evoluções
   saem como `create_character_state` da base (identidade preservada) e/ou
   peças trocáveis (asas, galhada, cauda) compostas na `jogo/`.
   Envelhecimento, elemento e aura saem de **shader de paleta** e partículas,
   não de sprite novo.
3. **Câmera única:** decidir no P6 entre `side` e `low top-down` para a arena
   2,5D, e não misturar.
4. **Todo asset entra por script de validação** (`tools/`, a criar no P6):
   tamanho múltiplo de 4, cores ⊂ paleta-mestra, fundo transparente, nome no
   padrão. A IA erra em silêncio; o script não.
5. **O operador aprova a âncora** (prévia em `/sdcard/Download/DSH-Go/`),
   o agente produz as variações.

## Pastas

```
arte/
  fonte/       # saídas brutas da IA (PNG + json do job), versionadas
  criaturas/   # sprites aprovados e validados, prontos para o Godot
  cenarios/
```
