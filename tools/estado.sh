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

CI=0; METRICAS=0
for arg in "$@"; do
  case "$arg" in
    --ci) CI=1 ;;
    --metricas) METRICAS=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
  esac
done

if [ "$CI" -eq 1 ]; then
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
const r = await fetch('https://api.github.com/repos/jonathasptbr-gh/Projeto-Galapago/actions/runs?per_page=10',
  { headers: { Authorization: 'Bearer ' + T, 'User-Agent': 'estado', Accept: 'application/vnd.github+json' } });
const j = await r.json();
const runs = j.workflow_runs || [];
// o run de `baseline` (workflow_dispatch) não é o CI do main: mostre o push.
const run = runs.find((x) => x.event !== 'workflow_dispatch');
const disp = runs.find((x) => x.event === 'workflow_dispatch' && (!run || x.created_at > run.created_at));
console.log(run ? `CI: ${run.name} #${run.run_number} ${run.status}/${run.conclusion ?? '-'} em ${run.head_sha.slice(0, 7)} — ${run.html_url}`
                : `CI: nenhum run (${r.status} ${j.message ?? ''})`);
if (disp) console.log(`baseline: #${disp.run_number} ${disp.status}/${disp.conclusion ?? '-'} — ${disp.html_url}`);
EOF
fi

if [ "$METRICAS" -eq 1 ]; then
  echo "== métricas (medidas agora)"
  echo "commits: $(git -c safe.directory='*' rev-list --count HEAD) · versões no HISTORICO: $(grep -c '^## v' docs/HISTORICO.md) · desde: $(git -c safe.directory='*' log --reverse --format=%ad --date=short | head -1)"
  node --input-type=module - <<'EOF'
import fs from 'fs';
const home = process.env.HOME;
let T = '';
try {
  const y = fs.readFileSync(home + '/.dsh/.credentials.yaml', 'utf8');
  const m = y.match(/GITHUB_TOKEN:\s*['"]?([^'"\s]+)/); if (m) T = m[1];
} catch {}
if (!T) try { T = fs.readFileSync(home + '/.dsh-github/token', 'utf8').trim(); } catch {}
if (!T) { console.log('CI: sem credencial — só o que o script local mediu'); process.exit(0); }
const r = await fetch('https://api.github.com/repos/jonathasptbr-gh/Projeto-Galapago/actions/runs?per_page=20',
  { headers: { Authorization: 'Bearer ' + T, 'User-Agent': 'estado', Accept: 'application/vnd.github+json' } });
const j = await r.json();
const runs = (j.workflow_runs || []).filter((x) => x.status === 'completed');
if (runs.length === 0) { console.log('CI: nenhum run concluído'); process.exit(0); }
const verdes = runs.filter((x) => x.conclusion === 'success').length;
const dur = runs.map((x) => Math.round((new Date(x.updated_at) - new Date(x.run_started_at)) / 1000)).sort((a, b) => a - b);
const mediana = dur[Math.floor(dur.length / 2)];
console.log(`CI (últimos ${runs.length}): ${verdes} verde(s), ${runs.length - verdes} vermelho(s) (${Math.round(100 * (runs.length - verdes) / runs.length)}%) · mediana ${mediana} s`);
for (const x of runs.slice(0, 5)) {
  const s = Math.round((new Date(x.updated_at) - new Date(x.run_started_at)) / 1000);
  console.log(`  #${x.run_number} ${x.conclusion === 'success' ? 'ok    ' : 'falhou'} ${String(s).padStart(4)} s · ${x.head_sha.slice(0, 7)} · ${x.event}`);
}
EOF
  if [ -f "$HOME/.dsh-github/uso.mjs" ]; then
    echo "custo da sessão: node ~/.dsh-github/uso.mjs"
  fi
fi
