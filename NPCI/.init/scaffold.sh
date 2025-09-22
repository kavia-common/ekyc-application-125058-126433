#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126433/NPCI"
TARGET_DIR="${SCAFFOLD_TARGET_DIR:-}"
[ -n "$TARGET_DIR" ] && WORK_DIR="$TARGET_DIR" || WORK_DIR="$WORKSPACE"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
# If package.json exists, validate and ensure scripts and .env (do not overwrite .env)
if [ -f package.json ]; then
  node -e "JSON.parse(require('fs').readFileSync('package.json','utf8'))" >/dev/null 2>&1 || { echo 'existing package.json invalid' >&2; exit 6; }
  node -e "let fs=require('fs'),p=JSON.parse(fs.readFileSync('package.json','utf8'));p.scripts=p.scripts||{};p.scripts.start=p.scripts.start||'react-scripts start';p.scripts.build=p.scripts.build||'react-scripts build';fs.writeFileSync('package.json',JSON.stringify(p,null,2));" || { echo 'failed to ensure package.json scripts' >&2; exit 9; }
  if [ ! -f .env ]; then cat > .env <<'EOF'
HOST=0.0.0.0
PORT=3000
EOF
  fi
  exit 0
fi
# Workspace empty/safe check
SAFE_OK=true
shopt -s dotglob nullglob
for f in *; do
  case "$f" in
    .|..) continue;;
    .git|.gitignore|README.md|README|LICENSE|LICENSE.md|.env.example) continue;;
    '') continue;;
    *) SAFE_OK=false; break;;
  esac
done
if [ "$SAFE_OK" != true ]; then
  if [ "${ALLOW_SCAFFOLD_OVERWRITE:-false}" = "true" ]; then
    TS=$(date -u +%Y%m%dT%H%M%SZ)
    BAKDIR="$WORK_DIR/.npcibak/$TS"
    mkdir -p "$BAKDIR"
    # move non-whitelisted files to backup
    for f in *; do
      case "$f" in
        .|..) continue;;
        .git|.gitignore|README.md|README|LICENSE|LICENSE.md|.env.example) continue;;
        '') continue;;
        *) mv -T "$f" "$BAKDIR/" 2>/dev/null || mv "$f" "$BAKDIR/" 2>/dev/null || true;;
      esac
    done
  else
    echo 'workspace non-empty and not in safe state; aborting scaffold. To force in-place scaffold set ALLOW_SCAFFOLD_OVERWRITE=true (script will backup non-whitelisted files), or set SCAFFOLD_TARGET_DIR to an alternate clean path.' >&2
    exit 7
  fi
fi
# require global create-react-app to avoid network fetch during automation
if command -v create-react-app >/dev/null 2>&1; then
  create-react-app . --use-npm --silent || { echo 'create-react-app failed' >&2; exit 8; }
else
  echo 'create-react-app is not installed globally in the image; automated scaffold will not perform network fetch. Install create-react-app globally or run scaffold manually with network access.' >&2
  exit 10
fi
# ensure package.json scripts and only create .env if absent
node -e "let fs=require('fs'),p=JSON.parse(fs.readFileSync('package.json','utf8'));p.scripts=p.scripts||{};p.scripts.start=p.scripts.start||'react-scripts start';p.scripts.build=p.scripts.build||'react-scripts build';fs.writeFileSync('package.json',JSON.stringify(p,null,2));" || { echo 'failed to ensure package.json scripts' >&2; exit 9; }
if [ ! -f .env ]; then cat > .env <<'EOF'
HOST=0.0.0.0
PORT=3000
EOF
fi
