---
name: loop-task
description: Run a task as a verified loop with explicit success criteria and an iteration cap. Use when the user wants work done "until it passes" or invokes /loop-task.
---

# Loop playbook

1. **Define done.** Restate the task as checkable criteria (prefer commands/exit codes). If CLAUDE.md has a definition of done, use it.
2. **Plan.** List the smallest steps to reach it.
3. **Act.** Do one step.
4. **Observe.** Run `scripts/verify.sh` and read the full output.
5. **Verify.** Pass → report and stop. Fail → name the exact failing criterion, then go to step 3 with a targeted fix.
6. **Cap.** Keep a counter. After 5 iterations, stop and report: what passes, what fails, your hypothesis.

Output each iteration as: `Iteration N | change | verify result`.
