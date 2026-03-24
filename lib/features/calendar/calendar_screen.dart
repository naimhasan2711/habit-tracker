import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../habits/habit_provider.dart';
import '../../widgets/widgets.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final HabitRepository _repository = HabitRepository();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<HabitLog>> _events = {};
  List<Habit> _selectedDayHabits = [];
  Map<String, bool> _selectedDayCompletionStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEventsForMonth(_focusedDay);
    _loadSelectedDayData();
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final logs = await _repository.getLogsInDateRange(start, end);

    setState(() {
      _events = {};
      for (final log in logs) {
        final date = DateTime(log.date.year, log.date.month, log.date.day);
        if (_events[date] == null) {
          _events[date] = [];
        }
        _events[date]!.add(log);
      }
    });
  }

  Future<void> _loadSelectedDayData() async {
    setState(() => _isLoading = true);

    _selectedDayHabits = await _repository.getActiveHabitsForDate(_selectedDay);
    _selectedDayCompletionStatus =
        await _repository.getCompletionStatusForDate(_selectedDay);

    setState(() => _isLoading = false);
  }

  List<HabitLog> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadSelectedDayData();
            },
            tooltip: 'Go to today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar<HabitLog>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadSelectedDayData();
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadEventsForMonth(focusedDay);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  final completedCount =
                      events.where((e) => e.completed).length;
                  final totalCount = events.length;
                  final completionRatio =
                      totalCount > 0 ? completedCount / totalCount : 0.0;

                  Color markerColor;
                  if (completionRatio == 1) {
                    markerColor = Colors.green;
                  } else if (completionRatio >= 0.5) {
                    markerColor = Colors.orange;
                  } else if (completionRatio > 0) {
                    markerColor = Colors.red.shade300;
                  } else {
                    markerColor = theme.dividerColor;
                  }

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Selected day header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  app_date_utils.DateTimeUtils.getRelativeDateString(
                      _selectedDay),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedDayHabits.isNotEmpty)
                  Text(
                    '${_selectedDayCompletionStatus.values.where((c) => c).length}/${_selectedDayHabits.length} completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Habits list for selected day
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedDayHabits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: theme.dividerColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No habits for this day',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _selectedDayHabits.length,
                        itemBuilder: (context, index) {
                          final habit = _selectedDayHabits[index];
                          final isCompleted =
                              _selectedDayCompletionStatus[habit.id] ?? false;
                          final streak = habitProvider.getStreak(habit.id);
                          final isToday = app_date_utils.DateTimeUtils.isToday(
                              _selectedDay);

                          return HabitCard(
                            habit: habit,
                            isCompleted: isCompleted,
                            streak: isToday ? streak : null,
                            onToggle: () => _toggleHabitForDay(habit.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHabitForDay(String habitId) async {
    await context.read<HabitProvider>().toggleHabitCompletion(
          habitId,
          date: _selectedDay,
        );
    await _loadSelectedDayData();
    await _loadEventsForMonth(_focusedDay);
  }
}
