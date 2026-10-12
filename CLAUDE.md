# Project rules

This is a loop-engineering sandbox. Work in loops: plan → act → observe → verify.

## Definition of done for `notes/loops.md`
- File exists at `notes/loops.md`
- Contains exactly 5 bullet lines (starting with `- `)
- Mentions the words: plan, act, observe, verify, stop
- Under 120 words

## Rules
- Never claim done before running `scripts/verify.sh` and seeing it pass.
- If verification fails, fix the specific failure reported; don't rewrite everything.
- Never edit `scripts/verify.sh` or `.claude/settings.json`.
- After 5 failed iterations, stop and ask the user for help.
