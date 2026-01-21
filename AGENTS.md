# 🧭 Agent Guide — Focus Interval

- At the start of every session, open this file and follow its instructions.
- Before editing dates in `docs/dev_log.md` or `docs/roadmap.md`, confirm the real date (e.g. run `date`) and use it.
- Check `docs/roadmap.md` and `docs/dev_log.md` before touching code to keep context and consistency.
- Always review the "Reopened phases" section in `docs/roadmap.md` before starting work.
- If any phase is reopened in the future, add it to the "Reopened phases" list in `docs/roadmap.md` and treat it as priority work.
- Before each commit, review whether your work requires updating `docs/roadmap.md` or `docs/dev_log.md`; if so, include those updates in the same commit.
- When editing `docs/dev_log.md` or `docs/roadmap.md`, always use the real date of the workday to preserve traceability.
- If you complete a phase, mark it in `docs/roadmap.md` (global status and that phase) using the real date, and update the CURRENT PHASE if needed.
- Before moving to the next phase, review the roadmap: if earlier phases are done but not marked, mark them with dates and align `docs/dev_log.md` and the global roadmap status.
- Do not commit if there are errors/build breaks or known unresolved bugs; confirm the change works (at least compiles/analyzer) before committing. For incomplete work, use a separate branch or stash instead of main.
- Keep all documentation, UI strings, and code comments in English to maintain a single language across the project.
- If Android release signing is discussed, confirm the release keystore is backed up; remind the user if not.
