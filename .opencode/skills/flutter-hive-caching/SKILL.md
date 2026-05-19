---
name: flutter-hive-caching
description: Use when implementing local caching with Hive in a Flutter app. Covers TTL-based cache invalidation, per-user cache scoping, background sync strategies, and cache initialization in main().
---

# Flutter Hive Caching

Patterns for local caching with Hive in Flutter apps. Covers TTL-based invalidation, per-user scoping, and background sync.

## Cache Initialization

Initialize Hive in `main()` before `runApp`, then pass cache instances via Riverpod overrides:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final exerciseCache = ExerciseLibraryCache();
  await exerciseCache.init();

  final programCache = ProgramCache();
  await programCache.init();

  runApp(
    ProviderScope(
      overrides: [
        exerciseLibraryCacheProvider.overrideWithValue(exerciseCache),
        programCacheProvider.overrideWithValue(programCache),
      ],
      child: const MyApp(),
    ),
  );
}
```

Provider definition (throws if not overridden — forces initialization):

```dart
@Riverpod(keepAlive: true)
ExerciseLibraryCache exerciseLibraryCache(ExerciseLibraryCacheRef ref) {
  throw UnimplementedError(
    'exerciseLibraryCacheProvider must be overridden in main()',
  );
}
```

## TTL-Based Cache (Global Data)

For shared data that changes infrequently (e.g., exercise library):

```dart
class ExerciseLibraryCache {
  static const _boxName = 'exercise_library';
  static const _metaBoxName = 'exercise_library_meta';
  static const _ttlDays = 7;

  late Box<Map> _box;
  late Box<dynamic> _metaBox;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _metaBox = await Hive.openBox(_metaBoxName);
  }

  bool get isEmpty => _box.isEmpty;

  bool get isStale {
    final lastSync = _metaBox.get('lastSync') as DateTime?;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inDays >= _ttlDays;
  }

  List<ExerciseModel> getAll() {
    return _box.values
        .map((m) => ExerciseModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> replaceAll(List<ExerciseModel> items) async {
    await _box.clear();
    for (final item in items) {
      await _box.put(item.id, item.toJson());
    }
    await _metaBox.put('lastSync', DateTime.now());
  }

  Future<void> upsert(ExerciseModel item) async {
    await _box.put(item.id, item.toJson());
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
```

Strategy: return cache immediately if not empty, sync from remote in background if stale.

## Per-User Cache (User-Owned Data)

For data scoped to a user (e.g., programs):

```dart
class ProgramCache {
  static const _boxName = 'programs';
  static const _metaBoxName = 'programs_meta';

  late Box<Map> _box;
  late Box<dynamic> _metaBox;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _metaBox = await Hive.openBox(_metaBoxName);
  }

  bool get isEmpty => _box.isEmpty;

  bool isStaleForUser(String userId) {
    final cachedUserId = _metaBox.get('userId') as String?;
    if (cachedUserId != userId) return true;
    final lastSync = _metaBox.get('lastSync') as DateTime?;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inDays >= 1;
  }

  List<ProgramModel> getAll() {
    return _box.values
        .map((m) => ProgramModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> replaceAll(String userId, List<ProgramModel> items) async {
    await _box.clear();
    for (final item in items) {
      await _box.put(item.id, item.toJson());
    }
    await _metaBox.put('userId', userId);
    await _metaBox.put('lastSync', DateTime.now());
  }

  Future<void> clearOnLogout() async {
    await _box.clear();
    await _metaBox.clear();
  }
}
```

Key differences from global cache:
- Tracks `userId` in meta — if user changes, cache is stale
- `clearOnLogout()` wipes data when user signs out
- Mutation-driven: update cache immediately on create/update/delete, don't wait for next sync

## Background Sync Pattern

In the datasource, return cache immediately and fire-and-forget a background sync:

```dart
Future<List<ProgramModel>> getPrograms() async {
  final cache = _programCache;
  final userId = _userId;

  // Return cache if fresh
  if (cache != null && !cache.isStaleForUser(userId) && !cache.isEmpty) {
    _syncToCache(cache, userId); // fire-and-forget
    return cache.getAll();
  }

  // Cache miss or stale: fetch from remote
  try {
    final programs = await _fetchFromFirestore();
    if (cache != null) await cache.replaceAll(userId, programs);
    return programs;
  } catch (e) {
    // Fallback to cache on network error
    if (cache != null && !cache.isEmpty) return cache.getAll();
    throw ServerException(message: 'Failed to get programs: $e');
  }
}

void _syncToCache(ProgramCache cache, String userId) {
  _fetchFromFirestore().then((programs) {
    cache.replaceAll(userId, programs);
  }).catchError((_) {}); // silent fail
}
```

## Mutation-Driven Cache Updates

When the user creates/updates/deletes, update cache immediately without waiting for a full re-fetch:

```dart
Future<ProgramModel> createProgram(ProgramModel program) async {
  final docRef = await _ref.add(program.toJson());
  final doc = await docRef.get();
  final created = ProgramModel.fromJson({...doc.data()!, 'id': doc.id});
  await _programCache?.upsert(created); // immediate cache update
  return created;
}

Future<void> deleteProgram(String id) async {
  await _ref.doc(id).delete();
  await _programCache?.remove(id); // immediate cache removal
}
```

## Cache Fallback on Network Error

Always try to return cached data when the network fails:

```dart
try {
  final data = await _fetchFromRemote();
  await cache.replaceAll(data);
  return data;
} catch (e) {
  if (cache != null && !cache.isEmpty) {
    return cache.getAll(); // offline fallback
  }
  throw ServerException(message: 'Failed and no cache: $e');
}
```

## Clearing Cache on Logout

In the auth viewmodel or logout handler, clear per-user caches:

```dart
Future<void> signOut() async {
  await _authDataSource.signOut();
  await ref.read(programCacheProvider).clearOnLogout();
}
```

Global caches (exercise library) don't need clearing — they're shared across users.
