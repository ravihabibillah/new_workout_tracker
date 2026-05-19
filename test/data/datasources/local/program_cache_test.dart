import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/data/datasources/local/program_cache.dart';
import 'package:workout_tracker/data/models/program_model.dart';
import 'package:workout_tracker/data/models/exercise_model.dart';

@GenerateNiceMocks([MockSpec<Box<Map>>(as: #MockMapBox), MockSpec<Box<dynamic>>(as: #MockDynamicBox)])
import 'program_cache_test.mocks.dart';

ProgramModel _makeProgram(String id, String name, {DateTime? createdAt}) =>
    ProgramModel(
      id: id,
      userId: 'u1',
      name: name,
      exercises: const [
        ExerciseModel(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
      ],
      createdAt: createdAt ?? DateTime(2026, 5, 1),
    );

ProgramCache _cacheWithBoxes(MockMapBox programsBox, MockDynamicBox metaBox) {
  final cache = ProgramCache();
  cache.injectBoxesForTest(programsBox, metaBox);
  return cache;
}

void main() {
  late MockMapBox mockProgramsBox;
  late MockDynamicBox mockMetaBox;
  late ProgramCache cache;

  setUp(() {
    mockProgramsBox = MockMapBox();
    mockMetaBox = MockDynamicBox();
    cache = _cacheWithBoxes(mockProgramsBox, mockMetaBox);
  });

  group('ProgramCache.cachedUserId', () {
    test('returns null when no userId stored', () {
      when(mockMetaBox.get('userId')).thenReturn(null);
      expect(cache.cachedUserId, isNull);
    });

    test('returns stored userId', () {
      when(mockMetaBox.get('userId')).thenReturn('user123');
      expect(cache.cachedUserId, 'user123');
    });
  });

  group('ProgramCache.lastSync', () {
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

  group('ProgramCache.isStaleForUser', () {
    test('returns true when cached userId differs', () {
      when(mockMetaBox.get('userId')).thenReturn('user1');
      expect(cache.isStaleForUser('user2'), true);
    });

    test('returns false when cached userId matches', () {
      when(mockMetaBox.get('userId')).thenReturn('user1');
      expect(cache.isStaleForUser('user1'), false);
    });

    test('returns true when no cached userId', () {
      when(mockMetaBox.get('userId')).thenReturn(null);
      expect(cache.isStaleForUser('user1'), true);
    });
  });

  group('ProgramCache.isEmpty', () {
    test('delegates to programs box', () {
      when(mockProgramsBox.isEmpty).thenReturn(true);
      expect(cache.isEmpty, true);

      when(mockProgramsBox.isEmpty).thenReturn(false);
      expect(cache.isEmpty, false);
    });
  });

  group('ProgramCache.getAll', () {
    test('returns empty list when box is empty', () {
      when(mockProgramsBox.values).thenReturn([]);
      expect(cache.getAll(), isEmpty);
    });

    test('returns programs sorted by createdAt descending', () {
      final older = _makeProgram('1', 'Old', createdAt: DateTime(2026, 1, 1));
      final newer = _makeProgram('2', 'New', createdAt: DateTime(2026, 5, 1));
      final middle = _makeProgram('3', 'Mid', createdAt: DateTime(2026, 3, 1));

      when(mockProgramsBox.values).thenReturn([
        _toCacheMap(older),
        _toCacheMap(newer),
        _toCacheMap(middle),
      ]);

      final result = cache.getAll();
      expect(result.map((p) => p.name).toList(), ['New', 'Mid', 'Old']);
    });
  });

  group('ProgramCache.getById', () {
    test('returns null when not found', () {
      when(mockProgramsBox.get('missing')).thenReturn(null);
      expect(cache.getById('missing'), isNull);
    });

    test('returns program when found', () {
      final program = _makeProgram('p1', 'Push Day');
      when(mockProgramsBox.get('p1')).thenReturn(_toCacheMap(program));

      final result = cache.getById('p1');
      expect(result, isNotNull);
      expect(result!.name, 'Push Day');
    });
  });

  group('ProgramCache.replaceAll', () {
    test('clears box, puts all entries, updates meta', () async {
      when(mockProgramsBox.clear()).thenAnswer((_) async => 0);
      when(mockProgramsBox.putAll(any)).thenAnswer((_) async {});
      when(mockMetaBox.put(any, any)).thenAnswer((_) async {});

      final programs = [_makeProgram('1', 'A'), _makeProgram('2', 'B')];
      await cache.replaceAll('user1', programs);

      verify(mockProgramsBox.clear()).called(1);
      verify(mockProgramsBox.putAll(any)).called(1);
      verify(mockMetaBox.put('userId', 'user1')).called(1);
      verify(mockMetaBox.put('lastSync', any)).called(1);
    });
  });

  group('ProgramCache.upsert', () {
    test('puts program into box', () async {
      when(mockProgramsBox.put(any, any)).thenAnswer((_) async {});
      final program = _makeProgram('p1', 'Push');
      await cache.upsert(program);
      verify(mockProgramsBox.put('p1', any)).called(1);
    });
  });

  group('ProgramCache.remove', () {
    test('deletes program from box', () async {
      when(mockProgramsBox.delete(any)).thenAnswer((_) async {});
      await cache.remove('p1');
      verify(mockProgramsBox.delete('p1')).called(1);
    });
  });

  group('ProgramCache.clear', () {
    test('clears programs box and deletes meta keys', () async {
      when(mockProgramsBox.clear()).thenAnswer((_) async => 0);
      when(mockMetaBox.delete(any)).thenAnswer((_) async {});

      await cache.clear();

      verify(mockProgramsBox.clear()).called(1);
      verify(mockMetaBox.delete('userId')).called(1);
      verify(mockMetaBox.delete('lastSync')).called(1);
    });
  });
}

Map<String, dynamic> _toCacheMap(ProgramModel program) {
  return {
    'id': program.id,
    'userId': program.userId,
    'name': program.name,
    'description': program.description,
    'exercises': program.exercises
        .map((e) => {
              'id': e.id,
              'name': e.name,
              'muscleGroup': e.muscleGroup,
              'order': e.order,
            })
        .toList(),
    'createdAt': program.createdAt.toIso8601String(),
    'updatedAt': program.updatedAt?.toIso8601String(),
  };
}
