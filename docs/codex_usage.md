# 🟣 Codex Usage Guide — Ideal Daily Workflow

To ensure Codex ALWAYS analyzes the real and current version of the project, use this sequence **BEFORE asking about project status** or requesting diagnostics.

---

## 🥇 1. Reset the index

Reset Codex's prior context to ensure there is no leftover memory from previous sessions:

```perl
@codex reset index
```

---

## 🥈 2. Load the full `lib` folder

This allows Codex to see all your real code:

```kotlin
@codex open lib
```

---

## 🥉 3. Ask

Now Codex can analyze the true state of the project.

Examples:

```text
How does the project look?
Any issues?
What is still pending according to the roadmap?
```

Use this sequence EVERY time you need a deep analysis of the project.

---

## 🟪 Personal note

Review this file periodically and update it if the Codex workflow changes or if new tools are added.

---

## 🟧 Android signing reminder

If you work on Android builds or Google Sign-In, read `docs/android_setup.md` first.
Do not store release keystores in the repo; keep them backed up in a secure vault.

---
