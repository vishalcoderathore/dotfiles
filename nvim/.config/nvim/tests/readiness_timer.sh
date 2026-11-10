#!/usr/bin/env bash
# Checks the readiness bar's timer race with the real config.
# Needs pyright and ruff installed, so a Python file has LSP clients.
# Usage: nvim/.config/nvim/tests/readiness_timer.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
printf 'import os\n\n\ndef main():\n    print(os.getcwd())\n' >"$dir/app.py"
cd "$dir" || exit 1

fail=0
for mode in race quit; do
  echo "== $mode"
  READINESS_CHECK=$mode timeout 120 nvim --headless -c "luafile $here/readiness_timer.lua" app.py 2>"$dir/stderr"
  code=$?
  if grep -q readiness "$dir/stderr"; then
    grep readiness "$dir/stderr" | head -3
    code=1
  fi
  [ "$mode" = quit ] && echo "RESULT: $([ $code -eq 0 ] && echo PASS || echo FAIL)"
  [ $code -eq 0 ] || fail=1
done
exit $fail
