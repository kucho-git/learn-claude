#!/usr/bin/env bash
# Stop-hook gate. Exit 0 = allow stop. Exit 2 = block stop; stderr is fed back to Claude.
# Skips gating if no task is active (notes/.active absent), so normal chats aren't blocked.
cd "$(dirname "$0")/.." || exit 0
[ -f notes/.active ] || exit 0

MAX=5
COUNT_FILE=notes/.iterations
n=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
n=$((n+1)); echo "$n" > "$COUNT_FILE"

errs=()
f=notes/loops.md
if [ ! -f "$f" ]; then
  errs+=("$f does not exist")
else
  bullets=$(grep -c '^- ' "$f")
  [ "$bullets" -eq 5 ] || errs+=("expected 5 bullets, found $bullets")
  words=$(wc -w < "$f" | tr -d ' ')
  [ "$words" -lt 120 ] || errs+=("too long: $words words (limit 120)")
  for w in plan act observe verify stop; do
    grep -qi "$w" "$f" || errs+=("missing keyword: $w")
  done
fi

if [ ${#errs[@]} -eq 0 ]; then
  rm -f notes/.active "$COUNT_FILE"
  echo "verify: PASS" >&2
  exit 0
fi

if [ "$n" -ge "$MAX" ]; then
  rm -f notes/.active "$COUNT_FILE"
  echo "Iteration cap ($MAX) reached. Stop and report to the user what still fails: ${errs[*]}" >&2
  exit 0
fi

echo "verify: FAIL (iteration $n/$MAX)" >&2
printf ' - %s\n' "${errs[@]}" >&2
exit 2
