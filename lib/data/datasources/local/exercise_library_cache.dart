import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/exercise_library_model.dart';

/// Local cache for the global exercise library using Hive.
///
/// Stores each exercise as a JSON Map (no code generation needed) keyed
/// by the exercise document id. A small `_meta` box tracks the last sync
/// timestamp so the data source can decide when to refresh from Firestore.
class ExerciseLibraryCache {
  static const String _exercisesBoxName = 'exercise_library';
  static const String _metaBoxName = 'exercise_library_meta';
  static const String _lastSyncKey = 'lastSync';

  /// How long the cache is considered fresh before triggering a remote sync.
  static const Duration cacheTtl = Duration(days: 7);

  late Box<Map> _exercisesBox;
  late Box<dynamic> _metaBox;
  bool _initialized = false;

  @visibleForTesting
  void injectBoxesForTest(Box<Map> exercisesBox, Box<dynamic> metaBox) {
    _exercisesBox = exercisesBox;
    _metaBox = metaBox;
    _initialized = true;
  }

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _exercisesBox = await Hive.openBox<Map>(_exercisesBoxName);
    _metaBox = await Hive.openBox(_metaBoxName);
    _initialized = true;
  }

  /// All cached exercises, sorted by name.
  List<ExerciseLibraryModel> getAll() {
    final values = _exercisesBox.values.toList();
    final exercises = values
        .map((e) => ExerciseLibraryModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
    exercises.sort((a, b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return exercises;
  }

  bool get isEmpty => _exercisesBox.isEmpty;

  DateTime? get lastSync {
    final raw = _metaBox.get(_lastSyncKey);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool get isStale {
    final last = lastSync;
    if (last == null) return true;
    return DateTime.now().difference(last) > cacheTtl;
  }

  Future<void> replaceAll(List<ExerciseLibraryModel> exercises) async {
    await _exercisesBox.clear();
    final entries = <String, Map>{
      for (final e in exercises) e.id: _toCacheMap(e),
    };
    await _exercisesBox.putAll(entries);
    await _metaBox.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<void> upsert(ExerciseLibraryModel exercise) async {
    await _exercisesBox.put(exercise.id, _toCacheMap(exercise));
  }

  Future<void> remove(String id) async {
    await _exercisesBox.delete(id);
  }

  Future<void> clear() async {
    await _exercisesBox.clear();
    await _metaBox.delete(_lastSyncKey);
  }

  Map<String, dynamic> _toCacheMap(ExerciseLibraryModel exercise) {
    return {
      'id': exercise.id,
      if (exercise.userId != null) 'userId': exercise.userId,
      'name': exercise.name,
      'muscleGroup': exercise.muscleGroup,
      'description': exercise.description,
      'createdAt': exercise.createdAt.toIso8601String(),
      'updatedAt': exercise.updatedAt?.toIso8601String(),
    };
  }
}
