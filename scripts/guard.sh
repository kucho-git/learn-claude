#!/usr/bin/env bash
# PreToolUse guard: blocks edits to the verifier and settings. Exit 2 = block.
input=$(cat)
if echo "$input" | grep -Eq 'scripts/(verify|verify_llm|guard)\.sh|rubric\.md|\.claude/settings\.json'; then
  echo "Blocked: the verifier and its config are off-limits to the worker." >&2
  exit 2
fi
exit 0
