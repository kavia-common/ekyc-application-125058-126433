#!/usr/bin/env bash
set -euo pipefail
# dependencies - install project dependencies (lockfile-aware, deterministic)
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126433/NPCI"
# validate workspace
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 20; }
cd "$WORKSPACE"
# check node + npm
NODE_BIN=$(command -v node || true)
NPM_BIN=$(command -v npm || true)
if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
  echo "node or npm not available on PATH" >&2
  exit 21
fi
NODE_VER=$($NODE_BIN -v | sed 's/^v//')
# require node >=16
NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
if [ "${NODE_MAJOR:-0}" -lt 16 ]; then
  echo "node >=16 required, found $NODE_VER" >&2
  exit 22
fi
# ensure package.json exists
[ -f package.json ] || { echo 'package.json missing: run scaffold first' >&2; exit 11; }
# skip if node_modules exists and react-scripts resolves locally
if [ -d node_modules ]; then
  if node -e "try{require.resolve('react-scripts');process.exit(0)}catch(e){process.exit(2)}" >/dev/null 2>&1; then
    exit 0
  fi
fi
# choose package manager and perform deterministic install
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  # prefer yarn with frozen lockfile
  yarn install --frozen-lockfile --silent || { echo 'yarn install failed' >&2; exit 12; }
elif [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent || { echo 'npm ci failed' >&2; exit 13; }
else
  npm i --no-audit --no-fund --silent || { echo 'npm install failed' >&2; exit 14; }
fi
# optionally install serve as devDependency
if [ "${INSTALL_SERVE:-false}" = "true" ]; then
  # use npm to add devDependency deterministically; if yarn present and yarn.lock exists, use yarn add --dev --silent --exact
  if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
    yarn add --dev serve --silent || { echo 'yarn add serve devDependency failed' >&2; exit 15; }
  else
    npm i --no-audit --no-fund --save-dev serve --silent || { echo 'install serve devDependency failed' >&2; exit 15; }
  fi
fi
# verify react-scripts available locally
node -e "try{require.resolve('react-scripts');process.exit(0)}catch(e){process.exit(2)}" >/dev/null 2>&1 || { echo 'react-scripts not resolvable after install' >&2; exit 16; }
