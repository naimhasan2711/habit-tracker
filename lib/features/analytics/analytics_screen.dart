import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/repositories.dart';
import '../habits/habit_provider.dart';
import '../../widgets/widgets.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final HabitRepository _repository = HabitRepository();

  double _overallCompletionRate = 0;
  List<Map<String, dynamic>> _weeklyStats = [];
  Map<String, double> _habitCompletionRates = {};
  bool _isLoading = true;
  int _selectedPeriod = 7; // days

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    _overallCompletionRate =
        await _repository.getOverallCompletionRate(days: _selectedPeriod);
    _weeklyStats =
        await _repository.getDailyCompletionStats(days: _selectedPeriod);

    // Load individual habit completion rates
    final habitProvider = context.read<HabitProvider>();
    for (final habit in habitProvider.habits) {
      _habitCompletionRates[habit.id] =
          await _repository.getCompletionRate(habit.id, days: _selectedPeriod);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period indicator
                  Text(
                    'Last $_selectedPeriod days',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overall completion rate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Overall Completion Rate',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ProgressRing(
                            progress: _overallCompletionRate / 100,
                            size: 120,
                            strokeWidth: 12,
                            progressColor:
                                _getCompletionColor(_overallCompletionRate),
                            child: Text(
                              '${_overallCompletionRate.round()}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    _getCompletionColor(_overallCompletionRate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getCompletionMessage(_overallCompletionRate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                          value: '${habitProvider.habits.length}',
                          label: 'Active Habits',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orange,
                          value: '${_getBestStreak(habitProvider)}',
                          label: 'Best Streak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Daily completion chart
                  if (_weeklyStats.isNotEmpty) ...[
                    Text(
                      'Daily Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${rod.toY.round()}%',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >=
                                          _weeklyStats.length) {
                                        return const SizedBox();
                                      }
                                      final date = DateTime.parse(
                                        _weeklyStats[value.toInt()]['date']
                                            as String,
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          app_date_utils.DateTimeUtils
                                              .getDayName(
                                            date.weekday,
                                            short: true,
                                          ).substring(0, 1),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 25,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${value.toInt()}%',
                                        style: theme.textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 25,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: theme.dividerColor.withOpacity(0.3),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups:
                                  _weeklyStats.asMap().entries.map((entry) {
                                final total = entry.value['total'] as int? ?? 0;
                                final completed =
                                    entry.value['completed'] as int? ?? 0;
                                final percentage =
                                    total > 0 ? (completed / total) * 100 : 0.0;

                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: percentage,
                                      color: _getCompletionColor(percentage),
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Individual habit stats
                  Text(
                    'Habit Performance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...habitProvider.habits.map((habit) {
                    final completionRate = _habitCompletionRates[habit.id] ?? 0;
                    final streak = habitProvider.getStreak(habit.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: habit.colorValue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconUtils.getIcon(habit.icon),
                            color: habit.colorValue,
                          ),
                        ),
                        title: Text(
                          habit.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text('${streak?.currentStreak ?? 0} day streak'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${completionRate.round()}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getCompletionColor(completionRate),
                              ),
                            ),
                            Text(
                              'completion',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    if (rate >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getCompletionMessage(double rate) {
    if (rate >= 90) return 'Outstanding! Keep up the amazing work!';
    if (rate >= 75) return 'Great job! You\'re on track!';
    if (rate >= 50) return 'Good progress! Room for improvement.';
    if (rate >= 25) return 'Keep going! Every day counts.';
    return 'Let\'s build some momentum!';
  }

  int _getBestStreak(HabitProvider provider) {
    int best = 0;
    for (final streak in provider.streaks.values) {
      if (streak.longestStreak > best) {
        best = streak.longestStreak;
      }
    }
    return best;
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
          children: [
            Icon(icon, color: iconColor, size: 32),
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
