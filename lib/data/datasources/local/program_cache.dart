import 'package:hive_flutter/hive_flutter.dart';
import '../../models/program_model.dart';

/// Local cache for user programs using Hive.
///
/// Programs are per-user, so the cache is scoped by userId. When the user
/// logs out or switches accounts, call [clear] to wipe stale data.
class ProgramCache {
  static const String _programsBoxName = 'programs';
  static const String _metaBoxName = 'programs_meta';
  static const String _userIdKey = 'userId';
  static const String _lastSyncKey = 'lastSync';

  late final Box<Map> _programsBox;
  late final Box<dynamic> _metaBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _programsBox = await Hive.openBox<Map>(_programsBoxName);
    _metaBox = await Hive.openBox(_metaBoxName);
    _initialized = true;
  }

  String? get cachedUserId => _metaBox.get(_userIdKey) as String?;

  DateTime? get lastSync {
    final raw = _metaBox.get(_lastSyncKey);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Returns true if the cache belongs to a different user.
  bool isStaleForUser(String userId) => cachedUserId != userId;

  bool get isEmpty => _programsBox.isEmpty;

  /// All cached programs, sorted by createdAt descending.
  List<ProgramModel> getAll() {
    final values = _programsBox.values.toList();
    final programs = values
        .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    programs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return programs;
  }

  ProgramModel? getById(String id) {
    final raw = _programsBox.get(id);
    if (raw == null) return null;
    return ProgramModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> replaceAll(String userId, List<ProgramModel> programs) async {
    await _programsBox.clear();
    final entries = <String, Map>{
      for (final p in programs) p.id: _toCacheMap(p),
    };
    await _programsBox.putAll(entries);
    await _metaBox.put(_userIdKey, userId);
    await _metaBox.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<void> upsert(ProgramModel program) async {
    await _programsBox.put(program.id, _toCacheMap(program));
  }

  Future<void> remove(String id) async {
    await _programsBox.delete(id);
  }

  Future<void> clear() async {
    await _programsBox.clear();
    await _metaBox.delete(_userIdKey);
    await _metaBox.delete(_lastSyncKey);
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
}
