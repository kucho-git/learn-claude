#!/usr/bin/env bash
# Hybrid Stop gate: cheap deterministic checks first, then an LLM judge with rubric.md.
# Exit 0 = allow stop. Exit 2 = block; stderr is fed back to Claude.
# Arm with: mkdir -p notes && touch notes/.active

# The judge runs `claude -p`, which would fire this same Stop hook -> infinite recursion.
[ -n "$LOOP_JUDGE" ] && exit 0

cd "$(dirname "$0")/.." || exit 0
[ -f notes/.active ] || exit 0

MAX=5
COUNT_FILE=notes/.iterations
n=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
n=$((n+1)); echo "$n" > "$COUNT_FILE"

done_ok() { rm -f notes/.active "$COUNT_FILE"; }

# Stage 1: deterministic gate (reuse verify.sh logic without its counter)
f=notes/loops.md
errs=()
if [ ! -f "$f" ]; then
  errs+=("$f does not exist")
else
  [ "$(grep -c '^- ' "$f")" -eq 5 ] || errs+=("expected exactly 5 bullets")
  [ "$(wc -w < "$f" | tr -d ' ')" -lt 120 ] || errs+=("over 120 words")
fi

fail() {
  if [ "$n" -ge "$MAX" ]; then
    done_ok
    echo "Iteration cap ($MAX) reached. Stop and tell the user what still fails:" >&2
    printf ' - %s\n' "$@" >&2
    exit 0
  fi
  echo "verify: FAIL (iteration $n/$MAX)" >&2
  printf ' - %s\n' "$@" >&2
  exit 2
}

[ ${#errs[@]} -eq 0 ] || fail "${errs[@]}"

# Stage 2: LLM judge (only reached if cheap checks pass)
prompt="You are a strict, skeptical reviewer. You did not write this text.
Apply the rubric below to the document. Reply in this exact format:
Line 1: PASS or FAIL (nothing else on the line).
Then, for each failed criterion, one bullet: criterion name, the quoted offending text, and the specific fix.

RUBRIC:
$(cat rubric.md)

DOCUMENT:
$(cat "$f")"

verdict=$(LOOP_JUDGE=1 claude -p "$prompt" 2>/dev/null)
first=$(printf '%s\n' "$verdict" | head -n1 | tr -d '[:space:]')

if [ "$first" = "PASS" ]; then
  done_ok
  echo "verify: PASS (deterministic + LLM judge)" >&2
  exit 0
fi

if [ "$first" != "FAIL" ]; then
  # Judge errored or gave an unparseable reply: fail open rather than loop forever on a broken judge.
  done_ok
  echo "Judge returned no verdict; allowing stop. Tell the user the LLM check did not run." >&2
  exit 0
fi

fail "LLM judge verdict:" "$(printf '%s\n' "$verdict" | tail -n +2)"
