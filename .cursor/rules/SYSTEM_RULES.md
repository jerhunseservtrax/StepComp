# System Rules

## Required Bug-Fix Memory

- Always consult `.cursor/rules/bug-fixes.md` before implementing related changes.
- Do not remove guardrails documented in `.cursor/rules/bug-fixes.md` without replacing them with an equivalent or stronger protection.
- Any new bug fix must append an entry to `.cursor/rules/bug-fixes.md` with:
  - symptom
  - root cause
  - required guardrails
  - verification checklist
