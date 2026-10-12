# Loop Engineering with Claude Code (config-only)

A loop = **plan → act → observe → verify → (repeat | stop)**.
Loop engineering is designing the *verify* and *stop* parts so the agent can't quit early or spin forever.

## Building blocks → loop role

| Claude feature | File | Role in the loop |
|---|---|---|
| CLAUDE.md | `CLAUDE.md` | The loop's standing rules and definition of done |
| Skill | `.claude/skills/loop-task/SKILL.md` | Reusable procedure: the loop playbook |
| Subagent | `.claude/agents/*.md` | Separate-context workers (builder, independent verifier) |
| Hook (Stop) | `.claude/settings.json` + `scripts/verify.sh` | The gate: blocks "done" until checks pass |
| Hook (PreToolUse) | `.claude/settings.json` | Guardrails: limits what the agent can touch |

## Setup
```
chmod +x scripts/*.sh
claude        # run inside this folder
```

## Exercises (do in order)

1. **Manual loop.** Prompt: `Write notes/loops.md explaining the agent loop in 5 bullets.` Then say "check it against CLAUDE.md". Notice you were the verifier.
2. **Skill.** Prompt: `/loop-task Write notes/loops.md per the spec`. The skill forces explicit criteria and a verify step.
3. **Hook gate.** First arm it: `mkdir -p notes && touch notes/.active` (the gate only runs while this file exists, and removes it on pass or at the cap). Then ask for the same file but tell Claude to stop early. The Stop hook runs `scripts/verify.sh`. It exits 2 while checks fail, so Claude is forced to continue. Read the script to see why.
4. **Independent verifier.** Prompt: `Use the builder agent to write notes/loops.md, then the verifier agent to review it. Iterate until the verifier says PASS.` Builder and verifier don't share context, which avoids self-grading bias.
5. **Guardrails and budgets.** Try asking Claude to edit `scripts/verify.sh`. The PreToolUse hook blocks it. Then note the max-iteration counter in verify.sh and what happens at the cap.
6. **Design your own.** Pick a task (e.g. "summarize 3 docs"), write its checks in `scripts/verify.sh`, and run the loop.
7. **LLM judge (hybrid).** For qualitative criteria. Copy the Stop hook from `examples/settings.hybrid.json` into `.claude/settings.json` (replacing the `verify.sh` entry), arm with `touch notes/.active`, and run the loop. `scripts/verify_llm.sh` runs cheap deterministic checks first, then a judge call using `rubric.md`. Study: the `LOOP_JUDGE` recursion guard, the strict `PASS`/`FAIL` first-line format, and why it fails open if the judge breaks. Then edit `rubric.md` and watch the verdicts change.
8. **Pure LLM hook.** Try `examples/settings.prompt-hook.json`, a `"type": "prompt"` Stop hook with no script. Compare the feedback quality and consistency against exercise 7 (check the hooks docs for your version's exact schema).

## Key principles
- Verification must be **objective** (a command's exit code) or **independent** (another agent).
- Always have a **cap**: max iterations, then escalate to a human.
- Feed **specific failure messages** back; they become the next iteration's plan.
- Protect the verifier from the worker.
