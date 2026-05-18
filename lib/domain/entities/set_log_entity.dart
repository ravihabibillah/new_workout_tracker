/// Set log entity - represents a single set in a workout
class SetLogEntity {
  final int setNumber;
  final double weight;
  final int reps;
  final String unit; // 'kg' or 'lbs'
  final DateTime? completedAt;
  final bool isCompleted;

  const SetLogEntity({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.unit,
    this.completedAt,
    this.isCompleted = false,
  });

  SetLogEntity copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    String? unit,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return SetLogEntity(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      unit: unit ?? this.unit,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Calculate volume (weight × reps)
  double get volume => weight * reps;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetLogEntity &&
        other.setNumber == setNumber &&
        other.weight == weight &&
        other.reps == reps;
  }

  @override
  int get hashCode => setNumber.hashCode ^ weight.hashCode ^ reps.hashCode;

  @override
  String toString() {
    return 'SetLogEntity(set: $setNumber, weight: $weight$unit, reps: $reps)';
  }
}
