import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/set_log_model.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';

void main() {
  group('SetLogModel', () {
    final completedAt = DateTime(2026, 5, 1, 10, 30);
    final json = {
      'setNumber': 1,
      'weight': 50.0,
      'reps': 10,
      'unit': 'kg',
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': true,
    };

    test('fromJson parses all fields', () {
      final model = SetLogModel.fromJson(json);
      expect(model.setNumber, 1);
      expect(model.weight, 50.0);
      expect(model.reps, 10);
      expect(model.unit, 'kg');
      expect(model.completedAt, completedAt);
      expect(model.isCompleted, true);
    });

    test('fromJson handles int weight as double', () {
      final model = SetLogModel.fromJson({
        'setNumber': 1,
        'weight': 50,
        'reps': 10,
        'unit': 'kg',
      });
      expect(model.weight, 50.0);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final model = SetLogModel.fromJson(const {
        'setNumber': 1,
        'weight': 50.0,
        'reps': 10,
        'unit': 'kg',
      });
      expect(model.completedAt, isNull);
      expect(model.isCompleted, false);
    });

    test('toJson produces correct map', () {
      final model = SetLogModel(
        setNumber: 1,
        weight: 50.0,
        reps: 10,
        unit: 'kg',
        completedAt: completedAt,
        isCompleted: true,
      );
      final result = model.toJson();
      expect(result['setNumber'], 1);
      expect(result['weight'], 50.0);
      expect(result['reps'], 10);
      expect(result['unit'], 'kg');
      expect(result['completedAt'], completedAt.toIso8601String());
      expect(result['isCompleted'], true);
    });

    test('toJson handles null completedAt', () {
      const model = SetLogModel(
        setNumber: 1,
        weight: 50.0,
        reps: 10,
        unit: 'kg',
      );
      final result = model.toJson();
      expect(result['completedAt'], isNull);
    });

    test('fromEntity creates model from entity', () {
      final entity = SetLogEntity(
        setNumber: 2,
        weight: 60.0,
        reps: 8,
        unit: 'lbs',
        completedAt: completedAt,
        isCompleted: true,
      );
      final model = SetLogModel.fromEntity(entity);
      expect(model.setNumber, entity.setNumber);
      expect(model.weight, entity.weight);
      expect(model.reps, entity.reps);
      expect(model.unit, entity.unit);
      expect(model.completedAt, entity.completedAt);
      expect(model.isCompleted, entity.isCompleted);
    });

    test('toEntity creates entity from model', () {
      const model = SetLogModel(
        setNumber: 1,
        weight: 50.0,
        reps: 10,
        unit: 'kg',
      );
      final entity = model.toEntity();
      expect(entity, isA<SetLogEntity>());
      expect(entity.setNumber, 1);
      expect(entity.volume, 500.0);
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      final original = SetLogEntity(
        setNumber: 3,
        weight: 75.5,
        reps: 6,
        unit: 'kg',
        completedAt: completedAt,
        isCompleted: true,
      );
      final model = SetLogModel.fromEntity(original);
      final json = model.toJson();
      final restored = SetLogModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.setNumber, original.setNumber);
      expect(entity.weight, original.weight);
      expect(entity.reps, original.reps);
      expect(entity.unit, original.unit);
      expect(entity.completedAt, original.completedAt);
      expect(entity.isCompleted, original.isCompleted);
    });
  });
}
