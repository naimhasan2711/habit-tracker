import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../habits/habit_provider.dart';
import '../habits/category_provider.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final HabitRepository _repository = HabitRepository();
  List<HabitLog> _recentLogs = [];
  double _completionRate = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _recentLogs = await _repository.getHabitLogsInDateRange(
      widget.habitId,
      thirtyDaysAgo,
      now,
    );
    _completionRate = await _repository.getCompletionRate(widget.habitId);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final habit = habitProvider.getHabitById(widget.habitId);
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Habit not found')),
      );
    }

    final streak = habitProvider.getStreak(habit.id);
    final category = categoryProvider.getCategoryById(habit.categoryId);
    final isCompletedToday = habitProvider.isCompletedToday(habit.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with habit info
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editHabit(habit),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, habit),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: habit.archived ? 'unarchive' : 'archive',
                    child: Row(
                      children: [
                        Icon(habit.archived ? Icons.unarchive : Icons.archive),
                        const SizedBox(width: 8),
                        Text(habit.archived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: habit.colorValue,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                IconUtils.getIcon(habit.icon),
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.name,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (category != null)
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's status
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCompletedToday
                              ? habit.colorValue
                              : habit.colorValue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompletedToday ? Icons.check : Icons.close,
                          color: isCompletedToday
                              ? Colors.white
                              : habit.colorValue,
                        ),
                      ),
                      title: Text(
                        isCompletedToday
                            ? 'Completed Today'
                            : 'Not Completed Yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isCompletedToday
                            ? 'Great job!'
                            : 'Tap to mark as complete',
                      ),
                      trailing: isCompletedToday
                          ? null
                          : ElevatedButton(
                              onPressed: () => _toggleToday(habit.id),
                              child: const Text('Complete'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orange,
                          value: '${streak?.currentStreak ?? 0}',
                          label: 'Current Streak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events,
                          iconColor: Colors.amber,
                          value: '${streak?.longestStreak ?? 0}',
                          label: 'Best Streak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.percent,
                          iconColor: theme.colorScheme.primary,
                          value: '${_completionRate.round()}%',
                          label: 'Completion Rate',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today,
                          iconColor: Colors.teal,
                          value: _getFrequencyText(habit),
                          label: 'Frequency',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (habit.description != null &&
                      habit.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(habit.description!),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity
                  Text(
                    'Last 30 Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityGrid(habit),
                  const SizedBox(height: 24),

                  // Reminder info
                  if (habit.reminderTime != null) ...[
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.alarm,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Daily Reminder'),
                        subtitle:
                            Text(_formatReminderTime(habit.reminderTime!)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Created date
                  Text(
                    'Created ${app_date_utils.DateTimeUtils.formatDate(habit.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(Habit habit) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    final completedDates = Set<String>.from(
      _recentLogs
          .where((log) => log.completed)
          .map((log) => log.date.toIso8601String().split('T')[0]),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((date) {
        final dateStr = date.toIso8601String().split('T')[0];
        final isCompleted = completedDates.contains(dateStr);
        final isToday = app_date_utils.DateTimeUtils.isToday(date);

        return Tooltip(
          message: app_date_utils.DateTimeUtils.formatDateShort(date),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? habit.colorValue
                  : theme.dividerColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getFrequencyText(Habit habit) {
    switch (habit.frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'custom':
        return '${habit.customDays?.length ?? 0} days';
      default:
        return 'Daily';
    }
  }

  String _formatReminderTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _editHabit(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHabitScreen(habitToEdit: habit),
      ),
    ).then((_) => _loadData());
  }

  void _toggleToday(String habitId) {
    context.read<HabitProvider>().toggleHabitCompletion(habitId);
    _loadData();
  }

  Future<void> _handleMenuAction(String action, Habit habit) async {
    final habitProvider = context.read<HabitProvider>();

    switch (action) {
      case 'archive':
      case 'unarchive':
        await habitProvider.archiveHabit(habit.id, action == 'archive');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Habit ${action == 'archive' ? 'archived' : 'unarchived'}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Habit'),
            content: const Text(
              'Are you sure you want to delete this habit? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await habitProvider.deleteHabit(habit.id);
          Navigator.pop(context);
        }
        break;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
