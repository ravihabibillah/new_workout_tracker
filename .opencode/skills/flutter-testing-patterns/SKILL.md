---
name: flutter-testing-patterns
description: Use when writing unit tests or widget tests in a Flutter project. Covers Riverpod ProviderContainer testing, mockito mock generation, entity/model tests, repository tests, viewmodel tests, and Hive cache tests.
---

# Flutter Testing Patterns

Patterns for unit testing Flutter apps with Riverpod, mockito, and Hive.

## Project Test Structure

```
test/
├── core/
│   ├── errors/          # Exception and Failure tests
│   └── utils/           # Validator tests
├── data/
│   ├── datasources/
│   │   └── local/       # Hive cache tests
│   ├── models/          # fromJson/toJson serialization tests
│   └── repositories/    # Repository impl tests with mocks
├── domain/
│   └── entities/        # Entity copyWith, computed properties
└── presentation/
    └── viewmodels/      # Viewmodel tests with ProviderContainer
```

## Entity Tests

Test `copyWith`, computed properties, and equality:

```dart
void main() {
  group('WorkoutSessionEntity', () {
    final entity = WorkoutSessionEntity(
      id: '1',
      userId: 'user1',
      programName: 'Push Day',
      startTime: DateTime(2026, 1, 1, 10, 0),
      exerciseLogs: [],
    );

    test('copyWith updates fields', () {
      final updated = entity.copyWith(programName: 'Pull Day');
      expect(updated.programName, 'Pull Day');
      expect(updated.id, entity.id); // unchanged
    });

    test('copyWith can set nullable field to null', () {
      final withEnd = entity.copyWith(endTime: DateTime(2026, 1, 1, 11, 0));
      // sentinel pattern allows setting back to null
      final cleared = withEnd.copyWith(endTime: null);
      expect(cleared.endTime, isNull);
    });

    test('duration returns null when endTime is null', () {
      expect(entity.duration, isNull);
    });

    test('duration calculates correctly', () {
      final withEnd = entity.copyWith(endTime: DateTime(2026, 1, 1, 11, 0));
      expect(withEnd.duration?.inMinutes, 60);
    });

    test('equality based on id', () {
      final same = entity.copyWith(programName: 'Different');
      expect(entity, equals(same));
    });
  });
}
```

## Model Serialization Tests

Test `fromJson` handles missing/null fields gracefully:

```dart
void main() {
  group('ProgramModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '1',
        'userId': 'user1',
        'name': 'Push Day',
        'exercises': [],
        'createdAt': '2026-01-01T00:00:00.000',
        'useRestTimer': true,
        'restTimerDuration': 120,
      };
      final model = ProgramModel.fromJson(json);
      expect(model.name, 'Push Day');
      expect(model.useRestTimer, true);
      expect(model.restTimerDuration, 120);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'id': '1',
        'userId': 'user1',
        'name': 'Push Day',
        'exercises': [],
        'createdAt': '2026-01-01T00:00:00.000',
        // useRestTimer and restTimerDuration missing
      };
      final model = ProgramModel.fromJson(json);
      expect(model.useRestTimer, false);   // default
      expect(model.restTimerDuration, 90); // default
    });

    test('toJson round-trips correctly', () {
      final model = ProgramModel(
        id: '1',
        userId: 'user1',
        name: 'Push Day',
        exercises: [],
        createdAt: DateTime(2026, 1, 1),
      );
      final json = model.toJson();
      final restored = ProgramModel.fromJson({...json, 'id': '1'});
      expect(restored.name, model.name);
    });
  });
}
```

## Repository Tests with Mockito

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'workout_repository_impl_test.mocks.dart';

@GenerateMocks([FirebaseWorkoutDataSource])
void main() {
  late WorkoutRepositoryImpl repository;
  late MockFirebaseWorkoutDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockFirebaseWorkoutDataSource();
    repository = WorkoutRepositoryImpl(dataSource: mockDataSource);
  });

  group('getPrograms', () {
    test('returns entities from datasource', () async {
      final models = [
        ProgramModel(id: '1', userId: 'u1', name: 'Push', exercises: [], createdAt: DateTime.now()),
      ];
      when(mockDataSource.getPrograms()).thenAnswer((_) async => models);

      final result = await repository.getPrograms();

      expect(result.length, 1);
      expect(result.first.name, 'Push');
      verify(mockDataSource.getPrograms()).called(1);
    });

    test('throws ServerFailure on ServerException', () async {
      when(mockDataSource.getPrograms())
          .thenThrow(ServerException(message: 'Network error'));

      expect(
        () => repository.getPrograms(),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
```

After adding `@GenerateMocks`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Viewmodel Tests with ProviderContainer

```dart
void main() {
  late ProviderContainer container;
  late MockIWorkoutRepository mockRepo;

  setUp(() {
    mockRepo = MockIWorkoutRepository();
    container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('startQuickWorkout creates session', () async {
    final session = WorkoutSessionEntity(
      id: '1',
      userId: 'u1',
      programName: 'Quick Workout',
      startTime: DateTime.now(),
      exerciseLogs: [],
      isQuickWorkout: true,
    );
    when(mockRepo.startQuickWorkoutSession())
        .thenAnswer((_) async => session);

    final notifier = container.read(workoutViewModelProvider.notifier);
    await notifier.startQuickWorkout();

    final state = container.read(workoutViewModelProvider);
    expect(state.activeSession?.isQuickWorkout, true);
    expect(state.isLoading, false);
  });
}
```

## Hive Cache Tests

Use `hive_test` or a temp directory for isolation:

```dart
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('replaceAll stores and retrieves items', () async {
    final cache = ExerciseLibraryCache();
    await cache.init();

    final items = [
      ExerciseLibraryModel(id: '1', name: 'Bench Press', muscleGroup: 'Chest'),
    ];
    await cache.replaceAll(items);

    expect(cache.isEmpty, false);
    expect(cache.getAll().first.name, 'Bench Press');
  });

  test('isStale returns true when cache is empty', () async {
    final cache = ExerciseLibraryCache();
    await cache.init();
    expect(cache.isStale, true);
  });
}
```

## Running Tests

```bash
# All tests
flutter test

# Specific directory
flutter test test/data/

# Specific file
flutter test test/domain/entities/workout_session_entity_test.dart

# With coverage
flutter test --coverage
```

## Analyze Before Committing

```bash
flutter analyze lib/ test/
```

Generated mock files often have `info`-level warnings — these are safe to ignore. Focus on `error` and `warning` level issues.
