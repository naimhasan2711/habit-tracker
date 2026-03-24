import 'package:flutter/services.dart';

class HapticUtils {
  /// Light impact haptic feedback
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact haptic feedback
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact haptic feedback
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click haptic feedback
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate (for notifications)
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
