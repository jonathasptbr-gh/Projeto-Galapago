// Teste offline do preview (sem rede, sem token): `--site` monta a página com
// os quadros-chave e recusa um run sem quadros. O CI chama `--site` na publicação.
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
// PNG 1×1 válido (para o GIF, se houver Pillow; sem ele o script segue sem GIF).
const PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  'base64',
);

function rodar(quadros, site) {
  return spawnSync(process.execPath, ['tools/preview.mjs', '--site', '--quadros', quadros, '--site-dir', site], {
    cwd: RAIZ,
    encoding: 'utf8',
    env: { ...process.env, GITHUB_RUN_ID: 'teste', GITHUB_SHA: 'abc1234def', GH_TOKEN: 'x' },
  });
}

test('--site copia início, meio e fim e escreve a página', () => {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), 'preview-'));
  const quadros = path.join(base, 'quadros');
  const site = path.join(base, 'site');
  fs.mkdirSync(quadros);
  for (let i = 1; i <= 5; i++) fs.writeFileSync(path.join(quadros, `q${String(i).padStart(8, '0')}.png`), PNG);
  fs.writeFileSync(path.join(quadros, 'outro.png'), PNG);
  const r = rodar(quadros, site);
  assert.equal(r.status, 0, r.stderr);
  const copiados = fs.readdirSync(path.join(site, 'teste')).filter((f) => f.endsWith('.png')).sort();
  assert.deepEqual(copiados, ['q00000001.png', 'q00000003.png', 'q00000005.png']);
  const html = fs.readFileSync(path.join(site, 'index.html'), 'utf8');
  assert.match(html, /teste\/q00000003\.png/);
  assert.match(html, /abc1234/);
  fs.rmSync(base, { recursive: true, force: true });
});

test('--site sem quadros falha e não monta a página', () => {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), 'preview-'));
  const site = path.join(base, 'site');
  const r = rodar(path.join(base, 'vazio'), site);
  assert.equal(r.status, 1);
  assert.equal(fs.existsSync(path.join(site, 'index.html')), false);
  fs.rmSync(base, { recursive: true, force: true });
});
