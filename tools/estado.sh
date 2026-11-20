#!/usr/bin/env bash
# Estado MEDIDO do projeto: o que este script não imprimiu nesta sessão não se
# cita. Uso: tools/estado.sh [--ci]   (--ci consulta o último run no GitHub)
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"

echo "== Projeto Galápago"
echo "versão (HISTORICO): $(grep -m1 -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' docs/HISTORICO.md | cut -c4-)"
echo "HEAD: $(git -c safe.directory='*' log -1 --format='%h %s' 2>/dev/null || echo '(sem commit)')"
sujos=$(git -c safe.directory='*' status --porcelain 2>/dev/null | wc -l)
echo "árvore: $sujos arquivo(s) alterado(s)"
echo "godot: $("$G" --version 2>/dev/null | tail -1 || echo 'AUSENTE — ver docs/AMBIENTE.md')"
echo "xvfb-run: $(command -v xvfb-run >/dev/null && echo ok || echo 'AUSENTE — oráculo de quadros não roda')"

if [ "${1:-}" = "--ci" ]; then
  node --input-type=module - <<'EOF'
import fs from 'fs';
const home = process.env.HOME;
let T = '';
try {
  const y = fs.readFileSync(home + '/.dsh/.credentials.yaml', 'utf8');
  const m = y.match(/GITHUB_TOKEN:\s*['"]?([^'"\s]+)/); if (m) T = m[1];
} catch {}
if (!T) try { T = fs.readFileSync(home + '/.dsh-github/token', 'utf8').trim(); } catch {}
if (!T) { console.log('CI: sem credencial (cofre ou ~/.dsh-github/token)'); process.exit(0); }
const r = await fetch('https://api.github.com/repos/jonathasptbr-gh/Projeto-Galapago/actions/runs?per_page=1',
  { headers: { Authorization: 'Bearer ' + T, 'User-Agent': 'estado', Accept: 'application/vnd.github+json' } });
const j = await r.json();
const run = j.workflow_runs?.[0];
console.log(run ? `CI: ${run.name} #${run.run_number} ${run.status}/${run.conclusion ?? '-'} em ${run.head_sha.slice(0, 7)} — ${run.html_url}`
                : `CI: nenhum run (${r.status} ${j.message ?? ''})`);
EOF
fi
