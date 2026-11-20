# Ambiente de trabalho (o celular do operador, DSH em proot)

Medido em 2026-11-20. O `tools/estado.sh` confere o que importa.

| item | valor |
|---|---|
| sistema | Ubuntu 24.04 em proot, aarch64, root |
| clone | `~/workspaces/Projeto-Galapago` |
| Godot | 4.7.2 arm64 em `~/.local/share/godot/`, link `~/.local/bin/godot` (o `$GODOT` sobrepõe) |
| oráculo | `xvfb`, `libgl1-mesa-dri` (apt); driver **softpipe** |
| Android SDK | **não há** — APK só no CI (pacote P2) |
| git | auth por `http.https://github.com/.extraHeader` global (ver o `AGENTS.md` da máquina); `core.trustctime false` no clone |
| temporários | `~/tmp` (não `/tmp`) |
| Pillow | `pip install pillow` (inspeção de PNG em script) |
| PixelLab | MCP `mcp__pixellab__*`; chave em `refs.PIXELLAB_TOKEN`; ver `docs/ARTE.md` |

## Reinstalar o Godot

```bash
# baixar Godot_v4.7.2-stable_linux.arm64.zip da Release 4.7.2-stable
# (github.com/godotengine/godot), descompactar em ~/.local/share/godot/ e:
ln -sf ~/.local/share/godot/Godot_v4.7.2-stable_linux.arm64 ~/.local/bin/godot
apt-get install -y xvfb libgl1-mesa-dri
```

A versão do Godot é a MESMA aqui e no CI (`GODOT_VERSION` no `ci.yml`): subir
uma exige subir a outra no mesmo lote.
