class Streak {
  final String id;
  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final bool freezeUsed;

  Streak({
    required this.id,
    required this.habitId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.freezeUsed = false,
  });

  /// Create Streak from Map (database row)
  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      lastCompletedDate: map['last_completed_date'] != null
          ? DateTime.parse(map['last_completed_date'] as String)
          : null,
      freezeUsed: (map['freeze_used'] as int? ?? 0) == 1,
    );
  }

  /// Convert Streak to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date': lastCompletedDate?.toIso8601String().split('T')[0],
      'freeze_used': freezeUsed ? 1 : 0,
    };
  }

  /// Check if streak is active (not broken)
  bool isActive(DateTime today) {
    if (lastCompletedDate == null) return false;
    final daysSinceLastCompletion = today.difference(lastCompletedDate!).inDays;
    // Streak is active if completed today or yesterday (allowing for one day grace)
    return daysSinceLastCompletion <= 1;
  }

  /// Copy with modifications
  Streak copyWith({
    String? id,
    String? habitId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    bool? freezeUsed,
  }) {
    return Streak(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      freezeUsed: freezeUsed ?? this.freezeUsed,
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'freezeUsed': freezeUsed,
    };
  }

  /// Create from JSON (for import)
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'] as String)
          : null,
      freezeUsed: json['freezeUsed'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Streak && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Streak(id: $id, habitId: $habitId, current: $currentStreak, longest: $longestStreak)';
  }
}
