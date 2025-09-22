#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126433/NPCI"
cd "$WORKSPACE"
mkdir -p src
if [ ! -f src/__smoke_test__.test.js ] && [ ! -f src/__smoke_test__.test.ts ]; then
  cat > src/__smoke_test__.test.js <<'EOF'
test('smoke: runner ok', () => { expect(true).toBe(true); });
EOF
fi
node -e "try{require.resolve('react-scripts');process.exit(0)}catch(e){console.error('react-scripts not available; run deps-003');process.exit(2)}" || exit 16
CI=true npm test --silent -- --watchAll=false
