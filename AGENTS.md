# Heft - Workout Tracker

## Project Overview
Flutter app (Heft) - weightlifting progress tracker using Firebase, Riverpod, and GoRouter.

## Tech Stack
- Flutter 3.27.1 / Dart 3.6.0
- State management: Riverpod (riverpod_annotation + code generation)
- Navigation: GoRouter
- Backend: Firebase (Firestore, Auth, Google Sign-In)
- Local cache: Hive
- Charts: fl_chart

## Commands
- Build: `flutter build apk --debug`
- Analyze: `dart analyze lib/`
- Code generation: `dart run build_runner build --delete-conflicting-outputs`
- Deploy Firestore rules: `firebase deploy --only firestore:rules`

## Commit Rules
- **Always ask the user before committing.**
- **Always suggest a commit message** before asking for confirmation.
- Stage only files relevant to the change — never `git add .`
- Do not commit unrelated files (e.g., `.opencode/`, generated `.g.dart` unless changed)
- After any code generation (`build_runner`), include the updated `.g.dart` files in the same commit as the feature that triggered them
- Commit message format: `type: short description` (conventional commits)
  - Types: `feat`, `fix`, `refactor`, `chore`, `docs`
  - Example: `feat: add Hive-based local caching for user programs`

## Architecture
Clean Architecture with 3 layers:
- `lib/domain/` - entities, repository interfaces, use cases
- `lib/data/` - models, remote datasources (Firebase), local datasources (Hive cache)
- `lib/presentation/` - viewmodels (Riverpod), views/screens

## Firestore Structure
```
exercises/{exerciseId}          ← global exercise library (shared all users)
exercises_meta/seed             ← seed marker (seeded once globally)
users/{userId}/programs/        ← per-user programs
users/{userId}/sessions/        ← per-user workout sessions
```

## Local Cache (Hive)
| Cache | Box | Scope | Strategy |
|-------|-----|-------|----------|
| Exercise library | `exercise_library` | Global | TTL 7 days, background sync |
| Programs | `programs` | Per user | Mutation-driven, clear on logout |

## Code Generation
After adding/modifying any `@riverpod` annotated class or function, always run:
```
dart run build_runner build --delete-conflicting-outputs
```
