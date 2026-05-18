import '../../domain/entities/set_log_entity.dart';

/// Set log model with JSON serialization
class SetLogModel extends SetLogEntity {
  const SetLogModel({
    required super.setNumber,
    required super.weight,
    required super.reps,
    required super.unit,
    super.completedAt,
    super.isCompleted,
  });

  factory SetLogModel.fromEntity(SetLogEntity entity) {
    return SetLogModel(
      setNumber: entity.setNumber,
      weight: entity.weight,
      reps: entity.reps,
      unit: entity.unit,
      completedAt: entity.completedAt,
      isCompleted: entity.isCompleted,
    );
  }

  factory SetLogModel.fromJson(Map<String, dynamic> json) {
    return SetLogModel(
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      unit: json['unit'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'unit': unit,
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  SetLogEntity toEntity() {
    return SetLogEntity(
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      unit: unit,
      completedAt: completedAt,
      isCompleted: isCompleted,
    );
  }
}
