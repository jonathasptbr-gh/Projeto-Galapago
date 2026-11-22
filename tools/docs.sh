#!/usr/bin/env bash
# Guardião documental + testes de regressão dele; offline, sem Godot.
set -euo pipefail
cd "$(dirname "$0")/.."
node tools/docs.mjs
exec node --test tools/docs.test.mjs
