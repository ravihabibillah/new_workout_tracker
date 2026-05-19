---
name: firebase-firestore-flutter
description: Use when working with Cloud Firestore in a Flutter app. Covers schema conventions for per-user data, composite indexes workflow, fromJson/toJson model patterns, seeding global collections, and handling network/permission errors gracefully.
---

# Firebase Firestore for Flutter

Patterns for using Cloud Firestore in a Flutter app with per-user data and shared global collections.

## Schema Conventions

Per-user data lives under `users/{userId}/`:

```
users/{userId}/
  ├── sessions/{sessionId}        # User's workout sessions, orders, etc.
  ├── programs/{programId}        # User-owned content
  └── ...
```

Global shared data lives at the root:

```
exercises/{exerciseId}            # Shared library across users
exercises_meta/seed               # Seed marker (seeded once globally)
```

Use root collections only for data that is genuinely shared. Per-user data should always be nested to simplify security rules.

## Models with fromJson/toJson

Models extend the entity and add serialization. Always handle missing fields with sensible defaults so old documents still load:

```dart
class WorkoutSessionModel extends WorkoutSessionEntity {
  const WorkoutSessionModel({
    required super.id,
    required super.userId,
    super.programId,
    super.programName = 'Quick Workout',
    required super.startTime,
    super.endTime,
    super.isCompleted = false,
    super.useRestTimer = false,
    super.restTimerDuration = 90,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      programId: json['programId'] as String?,
      programName: json['programName'] as String? ?? 'Quick Workout',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      useRestTimer: json['useRestTimer'] as bool? ?? false,
      restTimerDuration: json['restTimerDuration'] as int? ?? 90,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'programId': programId,
        'programName': programName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isCompleted': isCompleted,
        'useRestTimer': useRestTimer,
        'restTimerDuration': restTimerDuration,
      };
}
```

Standard idioms:

- Read missing booleans as `json['x'] as bool? ?? false`
- Read missing ints with default: `json['x'] as int? ?? 0`
- Read DateTime from ISO 8601 string: `DateTime.parse(json['x'] as String)`
- Write DateTime as `value.toIso8601String()`

## Document ID from doc.id

Firestore document IDs aren't part of the document data. Spread them in when reading:

```dart
final snapshot = await ref.get();
final model = MyModel.fromJson({...doc.data()!, 'id': doc.id});
```

For lists:

```dart
final list = snapshot.docs
    .map((doc) => MyModel.fromJson({...doc.data(), 'id': doc.id}))
    .toList();
```

## Composite Indexes

Any query that combines `where(field1)` with `orderBy(field2)` needs a composite index. Firestore prints a console URL on first run, but better: declare them in `firestore.indexes.json` and deploy.

Example `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isCompleted", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy:

```bash
firebase deploy --only firestore:indexes --project <project-id>
```

When adding a new query that combines `where` + `orderBy` on different fields, **add the index first**, deploy, then ship the code.

## One-Time Global Seeding

For shared data like an exercise library, seed once on first access using a marker doc:

```dart
Future<void> _seedDefaultsIfNeeded() async {
  final metaRef = _firestore.collection('exercises_meta').doc('seed');
  final metaSnap = await metaRef.get();
  if (metaSnap.exists && metaSnap.data()?['seeded'] == true) return;

  // Check if collection has any docs (defensive)
  final existing = await _libraryRef.limit(1).get();
  if (existing.docs.isNotEmpty) {
    await metaRef.set({'seeded': true, 'seededAt': DateTime.now().toIso8601String()});
    return;
  }

  // Batch write defaults
  const batchSize = 400;
  for (var i = 0; i < defaultItems.length; i += batchSize) {
    final end = (i + batchSize).clamp(0, defaultItems.length);
    final batch = _firestore.batch();
    for (final item in defaultItems.sublist(i, end)) {
      batch.set(_libraryRef.doc(), item.toJson());
    }
    await batch.commit();
  }

  await metaRef.set({'seeded': true, 'seededAt': DateTime.now().toIso8601String()});
}
```

Wrap the whole thing in `try { ... } catch (_) {}` — seeding is best-effort. Don't block reads on seeding failure.

## Active vs Completed Records Pattern

For "one active session at a time" use a boolean flag and a query:

```dart
Future<SessionModel?> getActive() async {
  final snap = await _ref
      .where('isCompleted', isEqualTo: false)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return SessionModel.fromJson({...snap.docs.first.data(), 'id': snap.docs.first.id});
}
```

Don't try to maintain a separate "active" doc — the flag-based query is simpler and atomic.

## Network Errors

Firestore SDK auto-retries when offline if persistence is enabled (default on mobile). Common log:

```
W/Firestore: Stream closed with status: UNAVAILABLE, Unable to resolve host firestore.googleapis.com
```

This is **not a bug** — it's the SDK reporting a transient network failure. Writes are queued and synced when online. Don't add aggressive retry logic in app code.

## Datasource Error Handling

```dart
Future<List<MyModel>> getThings() async {
  try {
    final snap = await _ref.get();
    return snap.docs.map((d) => MyModel.fromJson({...d.data(), 'id': d.id})).toList();
  } catch (e) {
    throw ServerException(message: 'Failed to get things: $e');
  }
}
```

Repository catches `ServerException` and re-throws as `ServerFailure` for the UI layer.

## Auth Guard

Get `userId` from `FirebaseAuth.instance.currentUser?.uid` and throw `AuthException` if null:

```dart
String get _userId {
  final uid = _firebaseAuth.currentUser?.uid;
  if (uid == null) throw AuthException(message: 'No authenticated user');
  return uid;
}
```

This way every per-user query naturally fails fast if called pre-auth, and the viewmodel can render a login prompt instead.
