# Feature Docs

Purpose
Maintain per-feature documentation that stays aligned with `docs/feature_backlog.md`.
Every new feature pulled from the backlog must have a matching folder here before
implementation starts.

Folder naming
Use the exact backlog ID as the folder prefix and add a short slug.
Example: `docs/features/IDEA-014-disable-task-weight/`

Required files
- `brief.md`
- `scope.md`
- `acceptance_criteria.md`
- `ux_notes.md`
- `testing.md`

Backlog reference
Each feature folder must include a "Backlog reference" section with:
- Backlog file: `docs/feature_backlog.md`
- Backlog ID and title (copy exactly)
- Status at time of extraction

Template
Start from `docs/features/feature_template.md`.
