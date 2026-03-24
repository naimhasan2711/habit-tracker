import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/models.dart';
import '../core/utils/icon_utils.dart';
import '../features/settings/settings_provider.dart';
import '../core/utils/haptic_utils.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final bool isCompleted;
  final Streak? streak;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;
  final int index;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    this.streak,
    this.onTap,
    this.onLongPress,
    this.onToggle,
    this.index = 0,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final habitColor = widget.habit.colorValue;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: widget.isCompleted
              ? Border.all(
                  color: habitColor.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : habitColor)
                  .withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: BorderRadius.circular(20),
            splashColor: habitColor.withValues(alpha: 0.1),
            highlightColor: habitColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Completion checkbox with ripple effect
                  _CompletionButton(
                    isCompleted: widget.isCompleted,
                    habitColor: habitColor,
                    icon: widget.habit.icon,
                    onToggle: () {
                      if (settings.hapticFeedback) {
                        HapticUtils.mediumImpact();
                      }
                      widget.onToggle?.call();
                    },
                  ),
                  const SizedBox(width: 16),
                  // Habit info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.habit.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: widget.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: habitColor,
                            decorationThickness: 2,
                            color: widget.isCompleted
                                ? theme.textTheme.titleMedium?.color
                                    ?.withValues(alpha: 0.5)
                                : null,
                          ),
                        ),
                        if (widget.habit.description != null &&
                            widget.habit.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.habit.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Streak indicator with animation
                  if (widget.streak != null && widget.streak!.currentStreak > 0)
                    _StreakBadge(
                      streak: widget.streak!.currentStreak,
                      color: habitColor,
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionButton extends StatefulWidget {
  final bool isCompleted;
  final Color habitColor;
  final String icon;
  final VoidCallback onToggle;

  const _CompletionButton({
    required this.isCompleted,
    required this.habitColor,
    required this.icon,
    required this.onToggle,
  });

  @override
  State<_CompletionButton> createState() => _CompletionButtonState();
}

class _CompletionButtonState extends State<_CompletionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CompletionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted && widget.isCompleted) {
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isCompleted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.habitColor,
                      widget.habitColor.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: widget.isCompleted
                ? null
                : widget.habitColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.habitColor
                  .withValues(alpha: widget.isCompleted ? 0 : 0.5),
              width: 2,
            ),
            boxShadow: widget.isCompleted
                ? [
                    BoxShadow(
                      color: widget.habitColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: widget.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                      key: ValueKey('check'),
                    )
                  : Icon(
                      IconUtils.getIcon(widget.icon),
                      color: widget.habitColor,
                      size: 24,
                      key: ValueKey('icon'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final Color color;

  const _StreakBadge({
    required this.streak,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.deepOrange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
            ).createShader(bounds),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
