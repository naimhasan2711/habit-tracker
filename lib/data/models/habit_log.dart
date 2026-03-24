class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final DateTime? completedAt;
  final String? notes;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.completedAt,
    this.notes,
  });

  /// Create HabitLog from Map (database row)
  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Convert HabitLog to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0], // Store only date part
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copy with modifications
  HabitLog copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    DateTime? completedAt,
    String? notes,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create from JSON (for import)
  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HabitLog(id: $id, habitId: $habitId, date: $date, completed: $completed)';
  }
}
