import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/program_model.dart';
import '../../models/workout_session_model.dart';
import '../../models/exercise_log_model.dart';
import '../../models/exercise_library_model.dart';
import '../../seed/default_exercises.dart';
import '../local/exercise_library_cache.dart';
import '../local/program_cache.dart';

class FirebaseWorkoutDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ExerciseLibraryCache? _libraryCache;
  final ProgramCache? _programCache;

  FirebaseWorkoutDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    ExerciseLibraryCache? libraryCache,
    ProgramCache? programCache,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _libraryCache = libraryCache,
        _programCache = programCache;

  String get _userId {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw AuthException(message: 'No authenticated user');
    return uid;
  }

  // ========== Program Operations ==========
  // Programs are per-user. Cache strategy:
  // - Return cache immediately if it belongs to the current user and is not empty
  // - Background sync from Firestore to pick up changes from other devices
  // - Fall back to cache when offline / Firestore fails

  CollectionReference<Map<String, dynamic>> get _programsRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('programs');

  Future<List<ProgramModel>> getPrograms() async {
    final cache = _programCache;
    final userId = _userId;

    if (cache != null &&
        !cache.isStaleForUser(userId) &&
        !cache.isEmpty) {
      _syncProgramsToCache(cache, userId);
      return cache.getAll();
    }

    try {
      final programs = await _fetchProgramsFromFirestore();
      if (cache != null) {
        await cache.replaceAll(userId, programs);
      }
      return programs;
    } catch (e) {
      if (cache != null &&
          !cache.isStaleForUser(userId) &&
          !cache.isEmpty) {
        return cache.getAll();
      }
      throw ServerException(message: 'Failed to get programs: $e');
    }
  }

  Future<List<ProgramModel>> _fetchProgramsFromFirestore() async {
    final snapshot =
        await _programsRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => ProgramModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  void _syncProgramsToCache(ProgramCache cache, String userId) {
    _fetchProgramsFromFirestore().then((programs) {
      cache.replaceAll(userId, programs);
    }).catchError((_) {});
  }

  Future<ProgramModel?> getProgramById(String programId) async {
    final cache = _programCache;
    final userId = _userId;

    if (cache != null && !cache.isStaleForUser(userId)) {
      final cached = cache.getById(programId);
      if (cached != null) return cached;
    }

    try {
      final doc = await _programsRef.doc(programId).get();
      if (!doc.exists) return null;
      final program =
          ProgramModel.fromJson({...doc.data()!, 'id': doc.id});
      await cache?.upsert(program);
      return program;
    } catch (e) {
      throw ServerException(message: 'Failed to get program: $e');
    }
  }

  Future<ProgramModel> createProgram(ProgramModel program) async {
    try {
      final docRef = await _programsRef.add(program.toJson());
      final doc = await docRef.get();
      final created =
          ProgramModel.fromJson({...doc.data()!, 'id': doc.id});
      await _programCache?.upsert(created);
      return created;
    } catch (e) {
      throw ServerException(message: 'Failed to create program: $e');
    }
  }

  Future<ProgramModel> updateProgram(ProgramModel program) async {
    try {
      await _programsRef.doc(program.id).update(program.toJson());
      await _programCache?.upsert(program);
      return program;
    } catch (e) {
      throw ServerException(message: 'Failed to update program: $e');
    }
  }

  Future<void> deleteProgram(String programId) async {
    try {
      await _programsRef.doc(programId).delete();
      await _programCache?.remove(programId);
    } catch (e) {
      throw ServerException(message: 'Failed to delete program: $e');
    }
  }

  Stream<List<ProgramModel>> watchPrograms() {
    return _programsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgramModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  // ========== Workout Session Operations ==========

  Future<WorkoutSessionModel?> getActiveWorkoutSession() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return WorkoutSessionModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to get active session: $e');
    }
  }

  Future<WorkoutSessionModel> startWorkoutSession({
    required String programId,
    required String programName,
    bool useRestTimer = false,
    int restTimerDuration = 90,
  }) async {
    try {
      final session = WorkoutSessionModel(
        id: '',
        userId: _userId,
        programId: programId,
        programName: programName,
        startTime: DateTime.now(),
        exerciseLogs: [],
        isCompleted: false,
        useRestTimer: useRestTimer,
        restTimerDuration: restTimerDuration,
      );
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .add(session.toJson());
      final doc = await docRef.get();
      return WorkoutSessionModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to start session: $e');
    }
  }

  Future<WorkoutSessionModel> updateWorkoutSession(
    WorkoutSessionModel session,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(session.id)
          .update(session.toJson());
      return session;
    } catch (e) {
      throw ServerException(message: 'Failed to update session: $e');
    }
  }

  Future<WorkoutSessionModel> completeWorkoutSession(String sessionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'endTime': DateTime.now().toIso8601String(),
        'isCompleted': true,
      });
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(sessionId)
          .get();
      return WorkoutSessionModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to complete session: $e');
    }
  }

  Future<void> cancelWorkoutSession(String sessionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw ServerException(message: 'Failed to cancel session: $e');
    }
  }

  Future<WorkoutSessionModel?> getWorkoutSessionById(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(sessionId)
          .get();
      if (!doc.exists) return null;
      return WorkoutSessionModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to get session: $e');
    }
  }

  // ========== History Operations ==========

  Future<List<WorkoutSessionModel>> getWorkoutHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .where('isCompleted', isEqualTo: true)
          .orderBy('startTime', descending: true);

      if (limit != null) query = query.limit(limit);
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              WorkoutSessionModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get history: $e');
    }
  }

  Future<List<ExerciseLogModel>> getExerciseHistory(
    String exerciseName, {
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .where('isCompleted', isEqualTo: true)
          .orderBy('startTime', descending: true);

      if (limit != null) query = query.limit(limit);
      final snapshot = await query.get();

      final exerciseLogs = <ExerciseLogModel>[];
      for (final doc in snapshot.docs) {
        final session = WorkoutSessionModel.fromJson(
          {...doc.data(), 'id': doc.id},
        );
        final logs = session.exerciseLogs
            .where((log) => log.exerciseName == exerciseName)
            .cast<ExerciseLogModel>();
        exerciseLogs.addAll(logs);
      }
      return exerciseLogs;
    } catch (e) {
      throw ServerException(message: 'Failed to get exercise history: $e');
    }
  }

  Future<List<String>> getAllExerciseNames() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .where('isCompleted', isEqualTo: true)
          .get();

      final exerciseNames = <String>{};
      for (final doc in snapshot.docs) {
        final session = WorkoutSessionModel.fromJson(
          {...doc.data(), 'id': doc.id},
        );
        for (final log in session.exerciseLogs) {
          exerciseNames.add(log.exerciseName);
        }
      }
      return exerciseNames.toList()..sort();
    } catch (e) {
      throw ServerException(message: 'Failed to get exercise names: $e');
    }
  }

  // ========== Exercise Library Operations ==========
  // The exercise library is a *global* root-level collection shared across
  // all users. Default exercises are seeded once globally; users can also
  // add their own custom exercises (with `userId` set).
  //
  // Cache strategy (Hive):
  // - Return cache immediately if not empty (fast, offline-capable)
  // - Sync from Firestore in background if cache is stale (TTL: 7 days)
  // - Force sync if cache is empty

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _firestore.collection('exercises');

  Future<List<ExerciseLibraryModel>> getExerciseLibrary() async {
    try {
      final cache = _libraryCache;

      if (cache != null) {
        if (!cache.isEmpty) {
          if (cache.isStale) {
            _syncLibraryToCache(cache);
          }
          return cache.getAll();
        }
      }

      await _seedDefaultExercisesIfNeeded();
      final exercises = await _fetchLibraryFromFirestore();

      if (cache != null) {
        await cache.replaceAll(exercises);
      }

      return exercises;
    } catch (e) {
      final cache = _libraryCache;
      if (cache != null && !cache.isEmpty) {
        return cache.getAll();
      }
      throw ServerException(message: 'Failed to get exercise library: $e');
    }
  }

  Future<List<ExerciseLibraryModel>> _fetchLibraryFromFirestore() async {
    final snapshot = await _libraryRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) =>
            ExerciseLibraryModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  void _syncLibraryToCache(ExerciseLibraryCache cache) {
    _fetchLibraryFromFirestore().then((exercises) {
      cache.replaceAll(exercises);
    }).catchError((_) {});
  }

  /// Seeds the default exercise list into the *global* exercises collection
  /// on first access. Uses a marker doc at `exercises_meta/seed` so seeding
  /// happens only once across all users.
  Future<void> _seedDefaultExercisesIfNeeded() async {
    try {
      final metaRef =
          _firestore.collection('exercises_meta').doc('seed');

      final metaSnap = await metaRef.get();
      if (metaSnap.exists && metaSnap.data()?['seeded'] == true) {
        return;
      }

      final existing = await _libraryRef.limit(1).get();
      if (existing.docs.isNotEmpty) {
        await metaRef.set({
          'seeded': true,
          'seededAt': DateTime.now().toIso8601String(),
        });
        return;
      }

      final now = DateTime.now().toIso8601String();
      const batchSize = 400;
      for (var i = 0; i < DefaultExercises.all.length; i += batchSize) {
        final end = (i + batchSize < DefaultExercises.all.length)
            ? i + batchSize
            : DefaultExercises.all.length;
        final batch = _firestore.batch();
        for (final exercise in DefaultExercises.all.sublist(i, end)) {
          final docRef = _libraryRef.doc();
          batch.set(docRef, {
            'name': exercise.name,
            'muscleGroup': exercise.muscleGroup,
            'description': null,
            'createdAt': now,
            'updatedAt': null,
          });
        }
        await batch.commit();
      }

      await metaRef.set({'seeded': true, 'seededAt': now});
    } catch (_) {
      // Seeding is best-effort; do not block library access if it fails.
    }
  }

  Future<ExerciseLibraryModel?> getExerciseLibraryById(
    String exerciseId,
  ) async {
    try {
      final cache = _libraryCache;
      if (cache != null && !cache.isEmpty) {
        final cached = cache.getAll().where((e) => e.id == exerciseId);
        if (cached.isNotEmpty) return cached.first;
      }
      final doc = await _libraryRef.doc(exerciseId).get();
      if (!doc.exists) return null;
      return ExerciseLibraryModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to get library exercise: $e');
    }
  }

  Future<ExerciseLibraryModel> createLibraryExercise(
    ExerciseLibraryModel exercise,
  ) async {
    try {
      final data = exercise.toJson();
      data['userId'] = _userId;
      final docRef = await _libraryRef.add(data);
      final doc = await docRef.get();
      final created =
          ExerciseLibraryModel.fromJson({...doc.data()!, 'id': doc.id});
      await _libraryCache?.upsert(created);
      return created;
    } catch (e) {
      throw ServerException(message: 'Failed to create library exercise: $e');
    }
  }

  Future<ExerciseLibraryModel> updateLibraryExercise(
    ExerciseLibraryModel exercise,
  ) async {
    try {
      await _libraryRef.doc(exercise.id).update(exercise.toJson());
      await _libraryCache?.upsert(exercise);
      return exercise;
    } catch (e) {
      throw ServerException(message: 'Failed to update library exercise: $e');
    }
  }

  Future<void> deleteLibraryExercise(String exerciseId) async {
    try {
      await _libraryRef.doc(exerciseId).delete();
      await _libraryCache?.remove(exerciseId);
    } catch (e) {
      throw ServerException(message: 'Failed to delete library exercise: $e');
    }
  }

  Stream<List<ExerciseLibraryModel>> watchExerciseLibrary() {
    return _libraryRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ExerciseLibraryModel.fromJson(
                  {...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
