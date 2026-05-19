import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/data/datasources/local/exercise_library_cache.dart';
import 'package:workout_tracker/data/models/exercise_library_model.dart';

@GenerateNiceMocks([MockSpec<Box<Map>>(as: #MockMapBox), MockSpec<Box<dynamic>>(as: #MockDynamicBox)])
import 'exercise_library_cache_test.mocks.dart';

ExerciseLibraryModel _makeExercise(String id, String name) =>
    ExerciseLibraryModel(
      id: id,
      name: name,
      muscleGroup: 'Legs',
      createdAt: DateTime(2026, 5, 1),
    );

ExerciseLibraryCache _cacheWithBoxes(MockMapBox exercisesBox, MockDynamicBox metaBox) {
  final cache = ExerciseLibraryCache();
  cache.injectBoxesForTest(exercisesBox, metaBox);
  return cache;
}

void main() {
  late MockMapBox mockExercisesBox;
  late MockDynamicBox mockMetaBox;
  late ExerciseLibraryCache cache;

  setUp(() {
    mockExercisesBox = MockMapBox();
    mockMetaBox = MockDynamicBox();
    cache = _cacheWithBoxes(mockExercisesBox, mockMetaBox);
  });

  group('ExerciseLibraryCache.lastSync', () {
    test('returns null when no lastSync stored', () {
      when(mockMetaBox.get('lastSync')).thenReturn(null);
      expect(cache.lastSync, isNull);
    });

    test('parses ISO string from meta box', () {
      final dt = DateTime(2026, 5, 1);
      when(mockMetaBox.get('lastSync')).thenReturn(dt.toIso8601String());
      expect(cache.lastSync, dt);
    });
  });

  group('ExerciseLibraryCache.isStale', () {
    test('returns true when lastSync is null', () {
      when(mockMetaBox.get('lastSync')).thenReturn(null);
      expect(cache.isStale, true);
    });

    test('returns false when synced recently', () {
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      when(mockMetaBox.get('lastSync')).thenReturn(recent.toIso8601String());
      expect(cache.isStale, false);
    });

    test('returns true when synced more than 7 days ago', () {
      final old = DateTime.now().subtract(const Duration(days: 8));
      when(mockMetaBox.get('lastSync')).thenReturn(old.toIso8601String());
      expect(cache.isStale, true);
    });
  });

  group('ExerciseLibraryCache.isEmpty', () {
    test('delegates to exercises box', () {
      when(mockExercisesBox.isEmpty).thenReturn(true);
      expect(cache.isEmpty, true);

      when(mockExercisesBox.isEmpty).thenReturn(false);
      expect(cache.isEmpty, false);
    });
  });

  group('ExerciseLibraryCache.getAll', () {
    test('returns empty list when box is empty', () {
      when(mockExercisesBox.values).thenReturn([]);
      expect(cache.getAll(), isEmpty);
    });

    test('returns sorted exercises by name', () {
      final squat = _makeExercise('1', 'Squat');
      final bench = _makeExercise('2', 'Bench Press');
      final deadlift = _makeExercise('3', 'Deadlift');

      when(mockExercisesBox.values).thenReturn([
        squat.toJson()..['id'] = squat.id,
        bench.toJson()..['id'] = bench.id,
        deadlift.toJson()..['id'] = deadlift.id,
      ]);

      final result = cache.getAll();
      expect(result.map((e) => e.name).toList(),
          ['Bench Press', 'Deadlift', 'Squat']);
    });
  });

  group('ExerciseLibraryCache.replaceAll', () {
    test('clears box, puts all entries, updates meta', () async {
      when(mockExercisesBox.clear()).thenAnswer((_) async => 0);
      when(mockExercisesBox.putAll(any)).thenAnswer((_) async {});
      when(mockMetaBox.put(any, any)).thenAnswer((_) async {});

      final exercises = [_makeExercise('1', 'Squat'), _makeExercise('2', 'Bench')];
      await cache.replaceAll(exercises);

      verify(mockExercisesBox.clear()).called(1);
      verify(mockExercisesBox.putAll(any)).called(1);
      verify(mockMetaBox.put('lastSync', any)).called(1);
    });
  });

  group('ExerciseLibraryCache.upsert', () {
    test('puts exercise into box', () async {
      when(mockExercisesBox.put(any, any)).thenAnswer((_) async {});
      final ex = _makeExercise('1', 'Squat');
      await cache.upsert(ex);
      verify(mockExercisesBox.put('1', any)).called(1);
    });
  });

  group('ExerciseLibraryCache.remove', () {
    test('deletes exercise from box', () async {
      when(mockExercisesBox.delete(any)).thenAnswer((_) async {});
      await cache.remove('1');
      verify(mockExercisesBox.delete('1')).called(1);
    });
  });

  group('ExerciseLibraryCache.clear', () {
    test('clears exercises box and deletes lastSync meta', () async {
      when(mockExercisesBox.clear()).thenAnswer((_) async => 0);
      when(mockMetaBox.delete(any)).thenAnswer((_) async {});

      await cache.clear();

      verify(mockExercisesBox.clear()).called(1);
      verify(mockMetaBox.delete('lastSync')).called(1);
    });
  });
}
