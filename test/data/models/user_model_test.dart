import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/user_model.dart';
import 'package:workout_tracker/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    const json = {
      'id': 'u1',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'photoUrl': 'https://example.com/photo.jpg',
      'preferredUnit': 'lbs',
      'defaultRestTime': 120,
    };

    test('fromJson parses all fields', () {
      final model = UserModel.fromJson(json);
      expect(model.id, 'u1');
      expect(model.email, 'test@example.com');
      expect(model.displayName, 'Test User');
      expect(model.photoUrl, 'https://example.com/photo.jpg');
      expect(model.preferredUnit, 'lbs');
      expect(model.defaultRestTime, 120);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final model = UserModel.fromJson(const {
        'id': 'u1',
        'email': 'test@example.com',
      });
      expect(model.displayName, isNull);
      expect(model.photoUrl, isNull);
      expect(model.preferredUnit, 'kg');
      expect(model.defaultRestTime, 90);
    });

    test('toJson produces correct map', () {
      const model = UserModel(
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Test',
        photoUrl: 'url',
        preferredUnit: 'kg',
        defaultRestTime: 90,
      );
      final result = model.toJson();
      expect(result['id'], 'u1');
      expect(result['email'], 'test@example.com');
      expect(result['displayName'], 'Test');
      expect(result['photoUrl'], 'url');
      expect(result['preferredUnit'], 'kg');
      expect(result['defaultRestTime'], 90);
    });

    test('fromEntity creates model from entity', () {
      const entity = UserEntity(
        id: 'u1',
        email: 'a@b.c',
        displayName: 'Alice',
      );
      final model = UserModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.email, entity.email);
      expect(model.displayName, entity.displayName);
    });

    test('toEntity creates entity from model', () {
      const model = UserModel(id: 'u1', email: 'a@b.c');
      final entity = model.toEntity();
      expect(entity, isA<UserEntity>());
      expect(entity.id, 'u1');
      expect(entity.email, 'a@b.c');
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      const original = UserEntity(
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Test',
        preferredUnit: 'lbs',
        defaultRestTime: 60,
      );
      final model = UserModel.fromEntity(original);
      final json = model.toJson();
      final restored = UserModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.id, original.id);
      expect(entity.email, original.email);
      expect(entity.displayName, original.displayName);
      expect(entity.preferredUnit, original.preferredUnit);
      expect(entity.defaultRestTime, original.defaultRestTime);
    });
  });
}
