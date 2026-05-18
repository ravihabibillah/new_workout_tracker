import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/program_model.dart';
import '../../models/workout_session_model.dart';
import '../../models/exercise_log_model.dart';

class FirebaseWorkoutDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  FirebaseWorkoutDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth;

  String get _userId {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw AuthException(message: 'No authenticated user');
    return uid;
  }

  // ========== Program Operations ==========

  Future<List<ProgramModel>> getPrograms() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProgramModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get programs: $e');
    }
  }

  Future<ProgramModel?> getProgramById(String programId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .doc(programId)
          .get();
      if (!doc.exists) return null;
      return ProgramModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to get program: $e');
    }
  }

  Future<ProgramModel> createProgram(ProgramModel program) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .add(program.toJson());
      final doc = await docRef.get();
      return ProgramModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw ServerException(message: 'Failed to create program: $e');
    }
  }

  Future<ProgramModel> updateProgram(ProgramModel program) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .doc(program.id)
          .update(program.toJson());
      return program;
    } catch (e) {
      throw ServerException(message: 'Failed to update program: $e');
    }
  }

  Future<void> deleteProgram(String programId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .doc(programId)
          .delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete program: $e');
    }
  }

  Stream<List<ProgramModel>> watchPrograms() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('programs')
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
}
