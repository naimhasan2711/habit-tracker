import 'package:flutter/material.dart';

class IconUtils {
  /// Map of icon names to IconData
  static final Map<String, IconData> iconMap = {
    'favorite': Icons.favorite,
    'fitness_center': Icons.fitness_center,
    'school': Icons.school,
    'work': Icons.work,
    'self_improvement': Icons.self_improvement,
    'attach_money': Icons.attach_money,
    'people': Icons.people,
    'category': Icons.category,
    'water_drop': Icons.water_drop,
    'bedtime': Icons.bedtime,
    'restaurant': Icons.restaurant,
    'directions_run': Icons.directions_run,
    'menu_book': Icons.menu_book,
    'code': Icons.code,
    'brush': Icons.brush,
    'music_note': Icons.music_note,
    'camera_alt': Icons.camera_alt,
    'local_cafe': Icons.local_cafe,
    'nature': Icons.nature,
    'pets': Icons.pets,
    'sports_soccer': Icons.sports_soccer,
    'psychology': Icons.psychology,
    'savings': Icons.savings,
    'phone': Icons.phone,
    'mail': Icons.mail,
    'cleaning_services': Icons.cleaning_services,
    'medication': Icons.medication,
    'smoking_rooms': Icons.smoking_rooms,
    'no_drinks': Icons.no_drinks,
    'emoji_emotions': Icons.emoji_emotions,
    'check_circle': Icons.check_circle,
    'star': Icons.star,
    'alarm': Icons.alarm,
    'today': Icons.today,
    'home': Icons.home,
    'directions_walk': Icons.directions_walk,
    'local_library': Icons.local_library,
    'headphones': Icons.headphones,
    'edit': Icons.edit,
    'create': Icons.create,
  };

  /// Get IconData from icon name
  static IconData getIcon(String? iconName) {
    if (iconName == null || !iconMap.containsKey(iconName)) {
      return Icons.circle;
    }
    return iconMap[iconName]!;
  }

  /// Get icon name from IconData
  static String? getIconName(IconData icon) {
    for (final entry in iconMap.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get all available icons
  static List<MapEntry<String, IconData>> getAllIcons() {
    return iconMap.entries.toList();
  }
}
