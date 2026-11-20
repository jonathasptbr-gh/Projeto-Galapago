#!/usr/bin/env bash
# Referência OFICIAL da API do Godot desta versão, sem internet: o próprio
# binário a despeja (--doctool, 1076 classes) num cache, e este script resume
# uma classe (herança, descrição curta, propriedades, métodos, sinais).
#   tools/godot-api.sh AnimatedSprite2D          # resumo da classe
#   tools/godot-api.sh AnimatedSprite2D play     # só membros que casam
#   tools/godot-api.sh --buscar normal_texture   # que classes têm este membro
set -euo pipefail
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
VER=$("$G" --version 2>/dev/null | tail -1 | cut -d. -f1-3)
CACHE="$HOME/.cache/galapago/godot-api-$VER"
if [ ! -d "$CACHE/doc/classes" ]; then
  mkdir -p "$CACHE"
  (cd "$CACHE" && GODOT_SILENCE_ROOT_WARNING=1 "$G" --headless --doctool . >/dev/null 2>&1) || true
fi
[ -d "$CACHE/doc/classes" ] || { echo "falhou gerar a referência em $CACHE" >&2; exit 1; }

python3 - "$CACHE" "$VER" "$@" <<'EOF'
import sys, glob, os, re, urllib.request, xml.etree.ElementTree as ET
cache, ver, args = sys.argv[1], sys.argv[2], sys.argv[3:]
# O binário de distribuição despeja a ESTRUTURA sem os textos; os textos
# oficiais desta versão exata vêm do repositório do Godot (tag <ver>-stable)
# e ficam em cache em <cache>/texto/.
def com_texto(caminho, nome):
    alvo = os.path.join(cache, "texto", nome + ".xml")
    if not os.path.exists(alvo):
        rel = os.path.relpath(caminho, cache)  # doc/classes/X.xml ou modules/m/doc_classes/X.xml
        url = f"https://raw.githubusercontent.com/godotengine/godot/{ver}-stable/{rel}"
        try:
            dados = urllib.request.urlopen(url, timeout=20).read()
            os.makedirs(os.path.dirname(alvo), exist_ok=True)
            open(alvo, "wb").write(dados)
        except Exception:
            return caminho
    return alvo
arquivos = glob.glob(f"{cache}/**/*.xml", recursive=True)
def limpa(t):
    t = t or ""
    t = re.sub(r"\[(?:param|member|method|signal|constant|enum|annotation|theme_item|constructor|operator) ([^\]]+)\]", r"`\1`", t)
    t = re.sub(r"\[code\](.*?)\[/code\]", r"`\1`", t, flags=re.S)
    t = re.sub(r"\[codeblocks?\].*?\[/codeblocks?\]", " (exemplo de código na doc) ", t, flags=re.S)
    t = re.sub(r"\[url=[^\]]*\](.*?)\[/url\]", r"\1", t)
    t = re.sub(r"\[([A-Z][A-Za-z0-9_.]*)\]", r"\1", t)
    t = re.sub(r"\[/?[a-z_]+[^\]]*\]", "", t)
    return re.sub(r"\s+", " ", t).strip()
if not args:
    print("uso: godot-api.sh <Classe> [filtro] | --buscar <membro>"); sys.exit(2)
if args[0] == "--buscar":
    alvo = args[1].lower()
    for f in sorted(arquivos):
        r = ET.parse(f).getroot()
        for m in r.iter():
            if m.tag in ("method", "member", "signal", "constant") and m.get("name", "").lower() == alvo:
                print(f"{r.get('name')}.{m.get('name')} ({m.tag})"); break
    sys.exit(0)
nome, filtro = args[0], (args[1].lower() if len(args) > 1 else None)
f = next((a for a in arquivos if os.path.basename(a) == nome + ".xml"), None)
if not f:
    sug = [os.path.basename(a)[:-4] for a in arquivos if nome.lower() in os.path.basename(a).lower()]
    print(f"classe '{nome}' não existe nesta versão. Parecidas: {', '.join(sorted(sug)[:15])}"); sys.exit(1)
r = ET.parse(com_texto(f, nome)).getroot()
if not filtro:
    print(f"{r.get('name')} < {r.get('inherits')}\n  {limpa(r.findtext('brief_description'))}\n")
def ok(n): return not filtro or filtro in n.lower()
props = [m for m in r.findall("members/member") if ok(m.get("name"))]
if props:
    print("PROPRIEDADES")
    for m in props: print(f"  {m.get('name')}: {m.get('type')} = {m.get('default')}  — {limpa(m.text)[:110]}")
mets = [m for m in r.findall("methods/method") if ok(m.get("name"))]
if mets:
    print("MÉTODOS")
    for m in mets:
        ret = m.find("return").get("type") if m.find("return") is not None else "void"
        ps = ", ".join(f"{a.get('name')}: {a.get('type')}" + (f" = {a.get('default')}" if a.get('default') else "") for a in m.findall("param"))
        print(f"  {m.get('name')}({ps}) -> {ret}  — {limpa(m.findtext('description'))[:110]}")
sins = [m for m in r.findall("signals/signal") if ok(m.get("name"))]
if sins:
    print("SINAIS")
    for m in sins: print(f"  {m.get('name')}({', '.join(a.get('name') for a in m.findall('param'))})  — {limpa(m.findtext('description'))[:110]}")
EOF
