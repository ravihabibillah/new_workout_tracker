---
name: flutter-build-runner-codegen
description: Use when working with Flutter projects that depend on build_runner code generation (riverpod_annotation, freezed, json_serializable, mockito). Covers when to run, common errors, gitignore conventions, and CI considerations.
---

# Flutter build_runner & Code Generation

`build_runner` powers code generation for `riverpod_annotation`, `freezed`, `json_serializable`, `mockito`, and others in Flutter/Dart projects.

## When to Run

Run after any of these changes:

- Adding/modifying a `@riverpod` annotated class or function
- Adding/modifying `@freezed` data classes
- Adding/modifying `@JsonSerializable` models
- Adding/modifying `@GenerateMocks` annotations in test files
- Pulling new code that includes new generated dependencies
- After `flutter clean` or first clone

```bash
dart run build_runner build --delete-conflicting-outputs
```

`--delete-conflicting-outputs` removes stale generated files that conflict with new ones — without it, the build often fails with "conflicting outputs" errors.

For active development, watch mode regenerates on save:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## What Gets Generated

| Source File | Generated File | Purpose |
|------------|----------------|---------|
| `*.dart` with `@riverpod` | `*.g.dart` | Riverpod provider boilerplate |
| `*.dart` with `@freezed` | `*.freezed.dart` | Freezed unions, copyWith |
| `*.dart` with `@JsonSerializable` | `*.g.dart` | toJson/fromJson |
| `*_test.dart` with `@GenerateMocks` | `*.mocks.dart` | Mockito test mocks |

## Gitignore Conventions

Most Flutter projects gitignore generated files because they're reproducible:

```
*.g.dart
*.freezed.dart
*.mocks.dart
```

After cloning such a project, **always run `build_runner` before `flutter run`** or you'll get "URI doesn't exist" errors for the generated imports.

Exception: some teams commit generated files to keep CI fast. Check the `.gitignore` to see the convention.

## Common Errors

### "Conflicting outputs were detected"

A previous build wrote files that conflict with the new build. Fix:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### "URI doesn't exist: 'foo.g.dart'"

The generated file doesn't exist. Run build_runner to create it.

### "<Name>Ref is deprecated"

Newer riverpod versions deprecate the typedef pattern (`MyProviderRef` → `Ref`). Update gradually:

```dart
// Old
@riverpod
String myValue(MyValueRef ref) => '...';

// New
@riverpod
String myValue(Ref ref) => '...';
```

### Build hangs

Try clearing the build cache:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## CI Considerations

If `*.g.dart` files are gitignored, CI must run `build_runner` before tests:

```yaml
# Example CI step
- run: flutter pub get
- run: dart run build_runner build --delete-conflicting-outputs
- run: flutter test
- run: flutter analyze
```

Run `build_runner` AFTER `pub get` (it needs dependencies installed).

## Mockito Mocks Workflow

For test files that mock dependencies:

```dart
import 'package:mockito/annotations.dart';
import 'foo_test.mocks.dart';

@GenerateMocks([IFooRepository, FirebaseAuth])
void main() {
  late MockIFooRepository mockRepo;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockRepo = MockIFooRepository();
    mockAuth = MockFirebaseAuth();
  });
  // ...
}
```

After adding `@GenerateMocks`, run build_runner to generate `foo_test.mocks.dart`.

## Verifying Generated Code

After running `build_runner`, run `flutter analyze` to catch any issues:

```bash
flutter analyze lib/ test/
```

Generated files often have analyzer warnings (e.g., `info` lint suggestions) that are safe to ignore. Focus on errors only.
