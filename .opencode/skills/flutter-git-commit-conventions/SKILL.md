---
name: flutter-git-commit-conventions
description: Use when committing code in a Flutter project. Covers conventional commit format, staging rules, when to run build_runner before committing, and how to split changes into logical commits.
---

# Git Commit Conventions for Flutter

Conventions for clean, meaningful commits in Flutter projects.

## Commit Message Format

Conventional commits format:

```
type: short description (max 72 chars)
```

Types:
- `feat` — new feature
- `fix` — bug fix
- `refactor` — code change that neither fixes a bug nor adds a feature
- `chore` — build process, dependency updates, tooling
- `docs` — documentation only
- `test` — adding or updating tests
- `style` — formatting, colors, UI-only changes (no logic change)
- `perf` — performance improvement

Examples:
```
feat: add quick workout mode with save as program option
fix: prevent TextEditingController disposed error in save as program dialog
refactor: replace Material Icons with Font Awesome icons across all screens
chore: move documentation files to docs directory
docs: update skill with learnings from project history
test: add unit tests for entities, models, repositories, and validators
style: use green background for success snackbar
```

## Staging Rules

- **Never `git add .`** — always stage specific files.
- Stage only files relevant to the change.
- Don't commit unrelated files (e.g., `.opencode/`, screenshots, temp files).
- `*.g.dart` files are typically gitignored — don't force-add them.

```bash
# Good
git add lib/presentation/views/workout/active_workout_screen.dart
git add lib/presentation/viewmodels/workout_viewmodel.dart

# Bad
git add .
```

## When to Run build_runner Before Committing

Run `build_runner` if you modified any `@riverpod`, `@freezed`, or `@GenerateMocks` annotated code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If `*.g.dart` files are gitignored, you don't need to stage them. If they're tracked, include them in the same commit as the feature that triggered them.

## Splitting Changes into Logical Commits

When multiple unrelated changes are in the working tree, split them into separate commits. Use `git add -p` for partial staging — but note that interactive `git add -p` doesn't work in non-interactive shells.

Alternative: stage files explicitly per commit:

```bash
# Commit 1: feature A
git add lib/feature_a.dart
git commit -m "feat: add feature A"

# Commit 2: feature B
git add lib/feature_b.dart
git commit -m "feat: add feature B"
```

If both features touch the same file, use a temporary revert approach:
1. Save the full file content
2. Revert to intermediate state (only feature A changes)
3. Commit feature A
4. Restore full content
5. Commit feature B

## Pre-Commit Checklist

Before committing:

1. Run `flutter analyze lib/` — fix any `error` or `warning` level issues.
2. Run `flutter test` — ensure no regressions.
3. Run `build_runner` if `@riverpod`/`@freezed`/`@GenerateMocks` changed.
4. Check `git diff --stat` — confirm only intended files are staged.
5. Check for secrets: no API keys, `.env` files, or credentials in staged files.

```bash
flutter analyze lib/
flutter test
git diff --stat --cached
```

## Files to Never Commit

- `google-services.json` — Firebase Android config (contains API keys)
- `GoogleService-Info.plist` — Firebase iOS config (contains API keys)
- `lib/firebase_options.dart` — generated Firebase config (contains API keys)
- `.env` files — environment variables with secrets
- `*.keystore`, `*.jks`, `*.p12` — signing keys
- `.opencode/` — AI assistant config (unless intentionally shared)

These should be in `.gitignore`. If accidentally committed, use `git rm --cached <file>` to untrack without deleting.

## Checking for Sensitive Files

```bash
# Check if sensitive files are tracked
git ls-files | grep -iE "google-services|GoogleService-Info|firebase_options|\.env|\.keystore"

# Check if API keys are in tracked files
git ls-files | xargs grep -l "AIza" 2>/dev/null
```

## Commit History Hygiene

- Prefer new commits over `--amend` (except for your own unpushed commits).
- Don't force-push to shared branches.
- Don't use `git add .` — it's too easy to accidentally commit generated files, screenshots, or secrets.
- Keep commits atomic: one logical change per commit.

## Branch Strategy

- Never push directly to `main`/`master` unless explicitly asked.
- Create feature branches for non-trivial changes.
- Use `git push -u origin <branch>` to set up remote tracking on first push.
