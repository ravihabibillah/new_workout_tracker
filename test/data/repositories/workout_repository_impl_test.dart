import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/exceptions.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/data/datasources/remote/firebase_workout_datasource.dart';
import 'package:workout_tracker/data/models/exercise_library_model.dart';
import 'package:workout_tracker/data/models/exercise_log_model.dart';
import 'package:workout_tracker/data/models/exercise_model.dart';
import 'package:workout_tracker/data/models/program_model.dart';
import 'package:workout_tracker/data/models/set_log_model.dart';
import 'package:workout_tracker/data/models/workout_session_model.dart';
import 'package:workout_tracker/data/repositories/workout_repository_impl.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';
import 'package:workout_tracker/domain/entities/exercise_library_entity.dart';
import 'package:workout_tracker/domain/entities/program_entity.dart';
import 'package:workout_tracker/domain/entities/workout_session_entity.dart';

@GenerateNiceMocks([MockSpec<FirebaseWorkoutDataSource>()])
import 'workout_repository_impl_test.mocks.dart';

void main() {
  late MockFirebaseWorkoutDataSource mockDataSource;
  late WorkoutRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockFirebaseWorkoutDataSource();
    repository = WorkoutRepositoryImpl(dataSource: mockDataSource);
  });

  final createdAt = DateTime(2026, 5, 1);
  final startTime = DateTime(2026, 5, 1, 9, 0);

  ProgramModel makeProgram(String id) => ProgramModel(
        id: id,
        userId: 'u1',
        name: 'Program $id',
        exercises: const [],
        createdAt: DateTime(2026, 5, 1),
      );

  ExerciseLibraryModel makeLibraryEx(String id) => ExerciseLibraryModel(
        id: id,
        name: 'Exercise $id',
        muscleGroup: 'Legs',
        createdAt: createdAt,
      );

  WorkoutSessionModel makeSession({
    required String id,
    String programId = 'p1',
    DateTime? sessionStart,
    List<ExerciseLogModel> logs = const [],
  }) =>
      WorkoutSessionModel(
        id: id,
        userId: 'u1',
        programId: programId,
        programName: 'Program',
        startTime: sessionStart ?? startTime,
        exerciseLogs: logs,
      );

  group('Exercise library operations', () {
    test('getExerciseLibrary returns mapped entities', () async {
      when(mockDataSource.getExerciseLibrary())
          .thenAnswer((_) async => [makeLibraryEx('1'), makeLibraryEx('2')]);

      final result = await repository.getExerciseLibrary();

      expect(result, hasLength(2));
      expect(result, everyElement(isA<ExerciseLibraryEntity>()));
      expect(result[0].id, '1');
    });

    test('getExerciseLibrary throws ServerFailure on ServerException', () {
      when(mockDataSource.getExerciseLibrary())
          .thenThrow(const ServerException(message: 'oops', code: 'E1'));

      expect(
        () => repository.getExerciseLibrary(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('getExerciseLibraryById returns entity when found', () async {
      when(mockDataSource.getExerciseLibraryById('ex1'))
          .thenAnswer((_) async => makeLibraryEx('ex1'));

      final result = await repository.getExerciseLibraryById('ex1');

      expect(result, isA<ExerciseLibraryEntity>());
      expect(result?.id, 'ex1');
    });

    test('getExerciseLibraryById returns null when not found', () async {
      when(mockDataSource.getExerciseLibraryById('missing'))
          .thenAnswer((_) async => null);

      final result = await repository.getExerciseLibraryById('missing');

      expect(result, isNull);
    });

    test('createLibraryExercise returns mapped entity', () async {
      final entity = ExerciseLibraryEntity(
        id: 'ex1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: createdAt,
      );
      when(mockDataSource.createLibraryExercise(any))
          .thenAnswer((_) async => makeLibraryEx('ex1'));

      final result = await repository.createLibraryExercise(entity);

      expect(result, isA<ExerciseLibraryEntity>());
      verify(mockDataSource.createLibraryExercise(any)).called(1);
    });

    test('deleteLibraryExercise delegates to datasource', () async {
      when(mockDataSource.deleteLibraryExercise('ex1'))
          .thenAnswer((_) async {});

      await repository.deleteLibraryExercise('ex1');

      verify(mockDataSource.deleteLibraryExercise('ex1')).called(1);
    });

    test('watchExerciseLibrary maps stream of models to entities', () {
      when(mockDataSource.watchExerciseLibrary())
          .thenAnswer((_) => Stream.value([makeLibraryEx('1')]));

      final stream = repository.watchExerciseLibrary();

      expect(
        stream,
        emits(
          allOf(
            isA<List<ExerciseLibraryEntity>>(),
            hasLength(1),
          ),
        ),
      );
    });
  });

  group('Program operations', () {
    test('getPrograms returns mapped entities', () async {
      when(mockDataSource.getPrograms())
          .thenAnswer((_) async => [makeProgram('p1'), makeProgram('p2')]);

      final result = await repository.getPrograms();

      expect(result, hasLength(2));
      expect(result, everyElement(isA<ProgramEntity>()));
    });

    test('getPrograms throws ServerFailure on ServerException', () {
      when(mockDataSource.getPrograms())
          .thenThrow(const ServerException(message: 'fail'));

      expect(() => repository.getPrograms(), throwsA(isA<ServerFailure>()));
    });

    test('getProgramById returns null when not found', () async {
      when(mockDataSource.getProgramById('missing'))
          .thenAnswer((_) async => null);

      final result = await repository.getProgramById('missing');

      expect(result, isNull);
    });

    test('createProgram passes a ProgramModel and returns entity', () async {
      final entity = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'New',
        exercises: const [
          ExerciseEntity(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
        ],
        createdAt: createdAt,
      );
      when(mockDataSource.createProgram(any))
          .thenAnswer((_) async => makeProgram('p1'));

      final result = await repository.createProgram(entity);

      expect(result, isA<ProgramEntity>());
      verify(mockDataSource.createProgram(argThat(isA<ProgramModel>())))
          .called(1);
    });

    test('deleteProgram delegates to datasource', () async {
      when(mockDataSource.deleteProgram('p1')).thenAnswer((_) async {});

      await repository.deleteProgram('p1');

      verify(mockDataSource.deleteProgram('p1')).called(1);
    });
  });

  group('Workout session operations', () {
    test('getActiveWorkoutSession returns null when no active session',
        () async {
      when(mockDataSource.getActiveWorkoutSession())
          .thenAnswer((_) async => null);

      final result = await repository.getActiveWorkoutSession();

      expect(result, isNull);
    });

    test('startWorkoutSession returns mapped entity', () async {
      when(mockDataSource.startWorkoutSession(
        programId: 'p1',
        programName: 'Push',
        useRestTimer: true,
        restTimerDuration: 60,
      )).thenAnswer((_) async => makeSession(id: 's1'));

      final result = await repository.startWorkoutSession(
        programId: 'p1',
        programName: 'Push',
        useRestTimer: true,
        restTimerDuration: 60,
      );

      expect(result, isA<WorkoutSessionEntity>());
      expect(result.id, 's1');
    });

    test('startQuickWorkoutSession returns mapped entity with isQuickWorkout true', () async {
      final quickSession = WorkoutSessionModel(
        id: 'qs1',
        userId: 'u1',
        programId: null,
        programName: 'Quick Workout',
        startTime: startTime,
        exerciseLogs: const [],
        isQuickWorkout: true,
      );
      when(mockDataSource.startQuickWorkoutSession(
        programName: 'Quick Workout',
        useRestTimer: false,
        restTimerDuration: 90,
      )).thenAnswer((_) async => quickSession);

      final result = await repository.startQuickWorkoutSession();

      expect(result, isA<WorkoutSessionEntity>());
      expect(result.id, 'qs1');
      expect(result.programId, isNull);
      expect(result.isQuickWorkout, true);
    });

    test('startQuickWorkoutSession with custom params', () async {
      final quickSession = WorkoutSessionModel(
        id: 'qs2',
        userId: 'u1',
        programId: null,
        programName: 'My Quick',
        startTime: startTime,
        exerciseLogs: const [],
        isQuickWorkout: true,
        useRestTimer: true,
        restTimerDuration: 60,
      );
      when(mockDataSource.startQuickWorkoutSession(
        programName: 'My Quick',
        useRestTimer: true,
        restTimerDuration: 60,
      )).thenAnswer((_) async => quickSession);

      final result = await repository.startQuickWorkoutSession(
        programName: 'My Quick',
        useRestTimer: true,
        restTimerDuration: 60,
      );

      expect(result.programName, 'My Quick');
      expect(result.useRestTimer, true);
      expect(result.restTimerDuration, 60);
    });

    test('startQuickWorkoutSession throws ServerFailure on ServerException', () {
      when(mockDataSource.startQuickWorkoutSession(
        programName: anyNamed('programName'),
        useRestTimer: anyNamed('useRestTimer'),
        restTimerDuration: anyNamed('restTimerDuration'),
      )).thenThrow(const ServerException(message: 'quick start failed'));

      expect(
        () => repository.startQuickWorkoutSession(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('completeWorkoutSession delegates to datasource', () async {
      when(mockDataSource.completeWorkoutSession('s1'))
          .thenAnswer((_) async => makeSession(id: 's1'));

      final result = await repository.completeWorkoutSession('s1');

      expect(result.id, 's1');
    });

    test('cancelWorkoutSession throws ServerFailure on ServerException', () {
      when(mockDataSource.cancelWorkoutSession('s1'))
          .thenThrow(const ServerException(message: 'cancel fail'));

      expect(
        () => repository.cancelWorkoutSession('s1'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('History operations', () {
    test('getWorkoutHistory passes through limit, startDate, endDate',
        () async {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 12, 31);
      when(mockDataSource.getWorkoutHistory(
        limit: 10,
        startDate: start,
        endDate: end,
      )).thenAnswer((_) async => [makeSession(id: 's1')]);

      final result = await repository.getWorkoutHistory(
        limit: 10,
        startDate: start,
        endDate: end,
      );

      expect(result, hasLength(1));
    });

    test('getWorkoutHistoryByProgram filters by programId', () async {
      when(mockDataSource.getWorkoutHistory(limit: anyNamed('limit')))
          .thenAnswer((_) async => [
                makeSession(id: 's1', programId: 'p1'),
                makeSession(id: 's2', programId: 'p2'),
                makeSession(id: 's3', programId: 'p1'),
              ]);

      final result = await repository.getWorkoutHistoryByProgram('p1');

      expect(result, hasLength(2));
      expect(result.every((s) => s.programId == 'p1'), true);
    });
  });

  group('Progress operations', () {
    test('getExercisePersonalRecords returns zeros when no logs', () async {
      when(mockDataSource.getExerciseHistory('Squat',
              limit: anyNamed('limit')))
          .thenAnswer((_) async => []);

      final result = await repository.getExercisePersonalRecords('Squat');

      expect(result['maxWeight'], 0.0);
      expect(result['maxReps'], 0);
      expect(result['maxVolume'], 0.0);
      expect(result['lastTrained'], isNull);
    });

    test('getExercisePersonalRecords computes max values across logs',
        () async {
      const logs = [
        ExerciseLogModel(
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: [
            SetLogModel(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
            SetLogModel(setNumber: 2, weight: 60, reps: 8, unit: 'kg'),
          ],
        ),
        ExerciseLogModel(
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: [
            SetLogModel(setNumber: 1, weight: 80, reps: 5, unit: 'kg'),
            SetLogModel(setNumber: 2, weight: 70, reps: 12, unit: 'kg'),
          ],
        ),
      ];
      when(mockDataSource.getExerciseHistory('Squat',
              limit: anyNamed('limit')))
          .thenAnswer((_) async => logs);

      final result = await repository.getExercisePersonalRecords('Squat');

      expect(result['maxWeight'], 80.0);
      expect(result['maxReps'], 12);
      // log1 volume = 50*10 + 60*8 = 980; log2 volume = 80*5 + 70*12 = 1240.
      expect(result['maxVolume'], 1240.0);
      expect(result['lastTrained'], 'Squat');
    });

    test('getExerciseProgressData filters logs and sorts by date', () async {
      final later = DateTime(2026, 6, 1);
      final earlier = DateTime(2026, 5, 1);

      when(mockDataSource.getWorkoutHistory()).thenAnswer((_) async => [
            makeSession(
              id: 's1',
              sessionStart: later,
              logs: const [
                ExerciseLogModel(
                  exerciseId: 'ex1',
                  exerciseName: 'Squat',
                  muscleGroup: 'Legs',
                  sets: [
                    SetLogModel(setNumber: 1, weight: 60, reps: 10, unit: 'kg'),
                  ],
                ),
                ExerciseLogModel(
                  exerciseId: 'ex2',
                  exerciseName: 'Bench',
                  muscleGroup: 'Chest',
                  sets: [
                    SetLogModel(setNumber: 1, weight: 40, reps: 10, unit: 'kg'),
                  ],
                ),
              ],
            ),
            makeSession(
              id: 's2',
              sessionStart: earlier,
              logs: const [
                ExerciseLogModel(
                  exerciseId: 'ex1',
                  exerciseName: 'Squat',
                  muscleGroup: 'Legs',
                  sets: [
                    SetLogModel(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
                  ],
                ),
              ],
            ),
          ]);

      final result = await repository.getExerciseProgressData('Squat');

      expect(result, hasLength(2));
      // sorted ascending by date
      expect(result[0]['date'], earlier);
      expect(result[1]['date'], later);
      // only Squat entries kept
      expect(result.every((m) => m['maxWeight'] is double), true);
      expect(result[0]['maxWeight'], 50.0);
      expect(result[1]['maxWeight'], 60.0);
    });
  });

  group('Statistics operations', () {
    test('getTotalWorkoutCount returns session count', () async {
      when(mockDataSource.getWorkoutHistory()).thenAnswer((_) async => [
            makeSession(id: 's1'),
            makeSession(id: 's2'),
            makeSession(id: 's3'),
          ]);

      expect(await repository.getTotalWorkoutCount(), 3);
    });

    test('getTotalVolume sums across sessions', () async {
      when(mockDataSource.getWorkoutHistory()).thenAnswer((_) async => [
            makeSession(id: 's1', logs: const [
              ExerciseLogModel(
                exerciseId: 'a',
                exerciseName: 'A',
                muscleGroup: 'X',
                sets: [
                  SetLogModel(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
                ],
              ),
            ]),
            makeSession(id: 's2', logs: const [
              ExerciseLogModel(
                exerciseId: 'b',
                exerciseName: 'B',
                muscleGroup: 'Y',
                sets: [
                  SetLogModel(setNumber: 1, weight: 40, reps: 10, unit: 'kg'),
                ],
              ),
            ]),
          ]);

      expect(await repository.getTotalVolume(), 500 + 400);
    });

    test('getCurrentStreak is 0 when no sessions', () async {
      when(mockDataSource.getWorkoutHistory()).thenAnswer((_) async => []);
      expect(await repository.getCurrentStreak(), 0);
    });

    test('getCurrentStreak counts consecutive days', () async {
      // Datasource returns history sorted by startTime desc.
      final today = DateTime(2026, 5, 19);
      final yesterday = DateTime(2026, 5, 18);
      final twoDaysAgo = DateTime(2026, 5, 17);
      final fourDaysAgo = DateTime(2026, 5, 15);

      when(mockDataSource.getWorkoutHistory()).thenAnswer((_) async => [
            makeSession(id: 's1', sessionStart: today),
            makeSession(id: 's2', sessionStart: yesterday),
            makeSession(id: 's3', sessionStart: twoDaysAgo),
            // gap of 2 days breaks the streak
            makeSession(id: 's4', sessionStart: fourDaysAgo),
          ]);

      expect(await repository.getCurrentStreak(), 3);
    });
  });
}
