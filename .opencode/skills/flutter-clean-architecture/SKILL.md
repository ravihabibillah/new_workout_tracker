---
name: flutter-clean-architecture
description: Use when structuring or scaling a Flutter project with Clean Architecture (domain, data, presentation layers). Covers folder layout, entity/model/repository/viewmodel separation, and the standard workflow for adding a feature end-to-end.
---

# Flutter Clean Architecture

Standard three-layer Clean Architecture for Flutter apps. Domain is pure Dart, data wraps external sources (Firebase, REST, local DB), and presentation handles state and UI. Each layer has clear ownership, and dependencies flow inward toward `domain`.

## Folder Layout

```
lib/
├── core/                    # Shared utilities, constants, errors, router
│   ├── constants/           # AppColors, AppStrings, AppSizes
│   ├── errors/              # Failure (UI-facing), Exception (data-layer)
│   ├── extensions/          # context_extensions.dart, etc.
│   ├── router/              # Router configuration
│   └── utils/               # Validators, global keys, formatters
├── data/                    # Data layer (concrete implementation)
│   ├── datasources/remote/  # Firebase, REST, GraphQL clients
│   ├── datasources/local/   # Hive, SQLite, SharedPreferences caches
│   ├── models/              # Entity subclasses with fromJson/toJson
│   └── repositories/        # *_repository_impl.dart
├── domain/                  # Pure business logic, no Flutter or Firebase
│   ├── entities/            # Immutable data classes
│   ├── repositories/        # Abstract interfaces (i_*_repository.dart)
│   └── usecases/            # Single-responsibility business operations
└── presentation/
    ├── viewmodels/          # State holders (Riverpod, Bloc, etc.)
    ├── views/               # Screens organized by feature
    └── widgets/              # Shared widgets
```

## Layer Boundaries

- **Domain** has zero imports from `data` or `presentation`. No `package:cloud_firestore`, no `package:flutter`. Pure Dart.
- **Data** imports `domain` (to implement interfaces, return entities). Models extend entities and add serialization.
- **Presentation** imports `domain` (entities, usecases) but never touches `data` directly.

## Adding a New Feature End-to-End

1. **Entity** in `domain/entities/<thing>_entity.dart`
   ```dart
   class ThingEntity {
     final String id;
     final String name;
     const ThingEntity({required this.id, required this.name});
     ThingEntity copyWith({String? id, String? name}) => ...;
   }
   ```

2. **Repository interface** in `domain/repositories/i_thing_repository.dart`
   ```dart
   abstract class IThingRepository {
     Future<List<ThingEntity>> getThings();
     Future<ThingEntity> createThing(ThingEntity thing);
   }
   ```

3. **Model** in `data/models/<thing>_model.dart` extending the entity
   ```dart
   class ThingModel extends ThingEntity {
     const ThingModel({required super.id, required super.name});
     factory ThingModel.fromJson(Map<String, dynamic> json) => ...;
     factory ThingModel.fromEntity(ThingEntity e) => ...;
     Map<String, dynamic> toJson() => ...;
     ThingEntity toEntity() => ThingEntity(id: id, name: name);
   }
   ```

4. **Datasource** in `data/datasources/remote/<source>_thing_datasource.dart` — wraps the external API and throws `ServerException` on failure.

5. **Repository impl** in `data/repositories/thing_repository_impl.dart` — catches `ServerException`, throws `ServerFailure`.

6. **Usecase** (optional) in `domain/usecases/<verb>_thing_usecase.dart` for non-trivial logic. Skip if the call is a thin pass-through.

7. **ViewModel** in `presentation/viewmodels/thing_viewmodel.dart`.

8. **Screen** in `presentation/views/<feature>/thing_screen.dart`.

9. **Route** in `core/router/app_router.dart`.

## Errors: Exception vs Failure

Two-tier error model:

- `ServerException` (and friends like `AuthException`, `CacheException`) live in `core/errors/exceptions.dart`. Datasources throw these.
- `Failure` subclasses (e.g., `ServerFailure`, `CacheFailure`) live in `core/errors/failure.dart`. Repositories convert exceptions to failures and re-throw.
- ViewModels catch `Failure` to populate user-facing error state.

```dart
// In repository impl
try {
  final result = await _dataSource.getThings();
  return result.map((m) => m.toEntity()).toList();
} on ServerException catch (e) {
  throw ServerFailure(message: e.message, code: e.code);
} catch (e) {
  throw ServerFailure(message: 'Failed to get things: $e');
}
```

## When to Add a Usecase

Only when there is logic beyond a thin repository call: chaining multiple repository calls, mapping results, validation, or business rules. For trivial CRUD, the viewmodel can call the repository directly to avoid noise.

## Verify

After every feature addition:

```bash
flutter analyze lib/
flutter test
```
