# Feature Backlog — Focus Interval (MVP 1.2)

Centralized list of feature ideas. Keep entries in chronological order with
newest at the end.

Entry template:
ID:
Title:
Type:
Scope:
Priority:
Status:

Problem / Goal:
Summary:

Design / UX:
Layout / placement:
Visual states:
Animation rules:
Interaction:
Text / typography:

Data & Logic:
Source of truth:
Calculations:
Sync / multi-device:

Edge cases:
Accessibility:
Dependencies:
Risks:
Acceptance criteria:
Notes:

---

## IDEA-001 — Circular group progress ring around timer

ID: IDEA-001
Title: Circular group progress ring around timer
Type: UI/UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
Replace the current linear group progress bar with a circular ring that wraps
the timer, making task segments and progress feel spatially aligned with the clock.

Summary:
A full ring surrounds the timer. Each task occupies a proportional angular
segment. A visual chip sits on each segment and reflects task state.

Design / UX:
Layout / placement:
Full ring around the timer (outer ring). Start point at 12:00 (top center).
Progress advances anti-clockwise, same direction as the timer.

Visual states:
Not started: chip outline uses the task color.
Running: chip outline uses the existing execution animation (same gradient and
motion as the current running progress bar).
Completed: chip outline turns gray regardless of task color.
Progress fill follows the existing specs: segments fill by task order; the
running task segment animates as it advances.

Animation rules:
Reuse the current running progress shader/animation. Transitions between
notStarted -> running -> completed are smooth and consistent with existing
progress animations.

Interaction:
Chips are tappable/clickable and open the task summary/detail (same behavior
as the current group progress bar). Updates live with activeSession changes.

Text / typography:
Task name text is centered within the curved chip area. Orientation rules:
If the segment is mostly in the upper half, text baseline faces the ring.
If mostly in the lower half, text baseline faces away from the ring.
Use ellipsis when the segment is too small; expose full name via tooltip and
accessibility labels.

Data & Logic:
Source of truth:
Use TaskRunGroup + activeSession only. No new authoritative state.

Calculations:
Angular span per task is proportional to task duration relative to the group
total (same as the linear bar spec). Progress sweeps anti-clockwise in order.

Sync / multi-device:
No change to ownership logic; presentation updates atomically from the same
session stream already in use.

Edge cases:
Single task uses full 360 degrees with centered text.
Tiny segments use fallback chip markers when text cannot fit; still render the
segment proportionally. If chips collide, reduce size or collapse to a compact
marker list accessible via interaction.
Responsive sizing must preserve legibility on small screens.

Accessibility:
All chip text rendered on canvas must be mirrored in Semantics labels with the
full task name and progress state.

Dependencies:
Timer screen progress widget and existing running animation shader.

Risks:
Text on curved segments, chip collisions on small screens, and performance if
too many segments are animated simultaneously.

Acceptance criteria:
Ring wraps the timer fully, start at 12:00, progress anti-clockwise.
Each task maps to a proportional segment; chips follow the same order.
Chip outlines reflect task state (color, running animation, gray on completion).
Progress fill advances segment-by-segment with correct colors and animation.
Text is centered and oriented for readability; ellipsis + tooltip when needed.
Chip interaction opens the same detail UI as the current bar.
Uses existing task durations and activeSession data; no logic changes.

Notes:
This is a visual-only change; all execution and sync rules remain unchanged.

---

## IDEA-002 — Simplification of status boxes in Run Mode (visual optimization inside the circle)

ID: IDEA-002
Title: Simplification of status boxes in Run Mode (visual optimization inside the circle)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Reduce visual noise inside the timer circle while keeping state clarity and
consistent visual language.

Summary:
Simplify the Run Mode status chips by trimming text and using stroke thickness
to distinguish short vs long breaks, without changing state logic or colors.

Design / UX:
Layout / placement:
Keep the existing vertical order and placement of the two-line status chip
inside the circle.

Visual states:
Pomodoro: line 1 "Run X of Y"; line 2 time range (HH:mm–HH:mm); remove redundant
"Pomodoro running" text.
Break: line 1 "Break"; line 2 time range (HH:mm–HH:mm); remove "Short break" or
"Long break" labels.
Short vs long break: no text or icons; use chip border thickness (short = thin
stroke, long = thick stroke) following the thin/thick blue ring logic used in
Task List, break duration card, and interval dots.

Animation rules:
No change to existing animations; only text content and break border thickness
change.

Interaction:
No change to Run Mode interaction; chip behavior remains as currently defined.

Text / typography:
Keep current typography and text color (red for pomodoro, blue for break).
Keep dark chip background. Borders: red (#E53935) for pomodoro, blue (#1E88E5)
for breaks.

Data & Logic:
Source of truth:
Use existing Run Mode state (PomodoroMachine + PomodoroViewModel); no new
authoritative state.

Calculations:
Time range formatting and run counts remain unchanged. Break type selects the
stroke thickness only.

Sync / multi-device:
No change; presentation-only update.

Edge cases:
If break type is unavailable, default to short-break stroke thickness. Ensure
the thickness difference remains legible on small screens.

Accessibility:
Expose semantics that include break type (short/long) and time range even when
the visible text is simplified.

Dependencies:
Execution Screen status chip layout and shared thin/thick stroke tokens used in
existing UI elements.

Risks:
Stroke thickness contrast may be too subtle at small sizes; ensure minimum
visibility while preserving base colors.

Acceptance criteria:
Pomodoro chip shows "Run X of Y" + time range; no "Pomodoro running" text
appears.
Break chip shows "Break" + time range; no "Short/Long break" text appears.
Short vs long break is communicated solely by border thickness with the same
thin/thick logic as existing blue ring cues.
Chip background stays dark; text colors remain red/blue; borders use #E53935
(pomodoro) and #1E88E5 (break).
Vertical order, state logic, and base colors remain unchanged.

Notes:
Visual-only optimization for clarity and space inside the circle; no behavior
changes.
