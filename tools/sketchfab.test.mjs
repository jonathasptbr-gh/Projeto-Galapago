// Testes offline do kit Sketchfab (sem rede, sem chave): veredito de licença e crédito.
import test from 'node:test';
import assert from 'node:assert/strict';
import { avaliarLicenca, linhaCredito } from './sketchfab.mjs';

const m = (label, extra = {}) => ({ license: { label }, ...extra });

test('aceita CC0, CC-BY (com crédito) e Free Standard', () => {
  assert.deepEqual(avaliarLicenca(m('CC0 Public Domain')), { aceita: true, credito: false, motivo: 'CC0' });
  assert.equal(avaliarLicenca(m('CC Attribution')).aceita, true);
  assert.equal(avaliarLicenca(m('CC Attribution')).credito, true);
  assert.equal(avaliarLicenca(m('Free Standard')).aceita, true);
});

test('recusa NC, ND, SA, pagas e desconhecidas', () => {
  for (const l of ['CC Attribution-NonCommercial', 'CC Attribution-NonCommercial-ShareAlike',
    'CC Attribution-NoDerivs', 'CC Attribution-ShareAlike', 'Standard', 'Editorial', '']) {
    assert.equal(avaliarLicenca(m(l)).aceita, false, l);
  }
});

test('recusa marcado como gerado por IA, mesmo com licença aceita', () => {
  assert.equal(avaliarLicenca(m('CC0 Public Domain', { tags: [{ slug: 'ai-generated' }] })).aceita, false);
  assert.equal(avaliarLicenca(m('CC Attribution', { name: 'Dog (AI generated)' })).aceita, false);
  assert.equal(avaliarLicenca(m('CC Attribution', { tags: [{ slug: 'noai' }] })).aceita, true);
});

test('crédito: primeira linha é o texto do jogo, segunda o rastreio', () => {
  const t = linhaCredito({
    uid: 'abc', name: 'Pinguim', user: { username: 'autor' }, license: { label: 'CC Attribution' },
    viewerUrl: 'https://sketchfab.com/3d-models/pinguim-abc',
  }, '2026-11-26');
  assert.equal(t, '"Pinguim" por autor — CC Attribution — https://sketchfab.com/3d-models/pinguim-abc\n' +
    'fonte: sketchfab abc · baixado em 2026-11-26\n');
});
