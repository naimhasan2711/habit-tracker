import 'package:flutter/material.dart';
import 'dart:convert';

class Habit {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final int color;
  final String? categoryId;
  final String frequency; // 'daily', 'weekly', 'custom'
  final List<int>? customDays; // 1-7 for Mon-Sun when frequency is 'custom'
  final String? reminderTime; // HH:mm format
  final DateTime createdAt;
  final bool archived;
  final int sortOrder;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    this.categoryId,
    required this.frequency,
    this.customDays,
    this.reminderTime,
    required this.createdAt,
    this.archived = false,
    this.sortOrder = 0,
  });

  /// Create Habit from Map (database row)
  factory Habit.fromMap(Map<String, dynamic> map) {
    List<int>? customDays;
    if (map['custom_days'] != null &&
        (map['custom_days'] as String).isNotEmpty) {
      customDays =
          (jsonDecode(map['custom_days'] as String) as List).cast<int>();
    }

    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String,
      color: map['color'] as int,
      categoryId: map['category_id'] as String?,
      frequency: map['frequency'] as String,
      customDays: customDays,
      reminderTime: map['reminder_time'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      archived: (map['archived'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// Convert Habit to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'category_id': categoryId,
      'frequency': frequency,
      'custom_days': customDays != null ? jsonEncode(customDays) : null,
      'reminder_time': reminderTime,
      'created_at': createdAt.toIso8601String(),
      'archived': archived ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// Get Color object
  Color get colorValue => Color(color);

  /// Check if habit should be active on a given day
  bool isActiveOnDay(DateTime date) {
    if (archived) return false;

    switch (frequency) {
      case 'daily':
        return true;
      case 'weekly':
        return date.weekday == DateTime.monday; // Default to Monday for weekly
      case 'custom':
        return customDays?.contains(date.weekday) ?? false;
      default:
        return true;
    }
  }

  /// Get reminder TimeOfDay
  TimeOfDay? get reminderTimeOfDay {
    if (reminderTime == null || reminderTime!.isEmpty) return null;
    try {
      final parts = reminderTime!.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  /// Copy with modifications
  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? color,
    String? categoryId,
    String? frequency,
    List<int>? customDays,
    String? reminderTime,
    DateTime? createdAt,
    bool? archived,
    int? sortOrder,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'categoryId': categoryId,
      'frequency': frequency,
      'customDays': customDays,
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'archived': archived,
      'sortOrder': sortOrder,
    };
  }

  /// Create from JSON (for import)
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as int,
      categoryId: json['categoryId'] as String?,
      frequency: json['frequency'] as String,
      customDays: json['customDays'] != null
          ? (json['customDays'] as List).cast<int>()
          : null,
      reminderTime: json['reminderTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      archived: json['archived'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, frequency: $frequency, archived: $archived)';
  }
}
