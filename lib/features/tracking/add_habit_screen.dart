import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../habits/habit_provider.dart';
import '../habits/category_provider.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/icon_utils.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habitToEdit;

  const AddHabitScreen({super.key, this.habitToEdit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = 'favorite';
  int _selectedColor = HabitColors.colors.first;
  String? _selectedCategoryId;
  String _frequency = 'daily';
  List<int> _customDays = [];
  TimeOfDay? _reminderTime;

  bool _isLoading = false;

  bool get _isEditing => widget.habitToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final habit = widget.habitToEdit!;
      _nameController.text = habit.name;
      _descriptionController.text = habit.description ?? '';
      _selectedIcon = habit.icon;
      _selectedColor = habit.color;
      _selectedCategoryId = habit.categoryId;
      _frequency = habit.frequency;
      _customDays = habit.customDays ?? [];
      _reminderTime = habit.reminderTimeOfDay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteHabit,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Habit Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconUtils.getIcon(_selectedIcon),
                        color: Color(_selectedColor),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Habit Name'
                                : _nameController.text,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _nameController.text.isEmpty
                                  ? theme.hintColor
                                  : null,
                            ),
                          ),
                          if (_descriptionController.text.isNotEmpty)
                            Text(
                              _descriptionController.text,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            Text(
              'Name',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter habit name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Description Field
            Text(
              'Description (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Add a description',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Icon Selection
            Text(
              'Icon',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectIcon,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconUtils.getIcon(_selectedIcon),
                        color: Color(_selectedColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Tap to change icon')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color Selection
            Text(
              'Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ColorPicker(
              selectedColor: _selectedColor,
              onColorSelected: (color) =>
                  setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => setState(() => _selectedCategoryId = null),
                ),
                ...categoryProvider.categories.map((category) {
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = category.id),
                    avatar: Icon(
                      IconUtils.getIcon(category.icon),
                      size: 18,
                      color: _selectedCategoryId == category.id
                          ? theme.colorScheme.onPrimary
                          : category.colorValue,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Frequency Selection
            Text(
              'Frequency',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'custom', label: Text('Custom')),
              ],
              selected: {_frequency},
              onSelectionChanged: (selection) {
                setState(() {
                  _frequency = selection.first;
                  if (_frequency == 'custom' && _customDays.isEmpty) {
                    _customDays = [DateTime.now().weekday];
                  }
                });
              },
            ),

            // Custom Days Selector
            if (_frequency == 'custom') ...[
              const SizedBox(height: 16),
              Text(
                'Select Days',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              WeekDaySelector(
                selectedDays: _customDays,
                onChanged: (days) => setState(() => _customDays = days),
              ),
            ],
            const SizedBox(height: 24),

            // Reminder
            Text(
              'Reminder',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectReminderTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color: _reminderTime != null
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _reminderTime != null
                            ? _formatTimeOfDay(_reminderTime!)
                            : 'Add reminder',
                        style: TextStyle(
                          color: _reminderTime != null ? null : theme.hintColor,
                        ),
                      ),
                    ),
                    if (_reminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _reminderTime = null),
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveHabit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Habit'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _selectIcon() async {
    final icon = await IconPicker.show(context, selectedIcon: _selectedIcon);
    if (icon != null) {
      setState(() => _selectedIcon = icon);
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final habitProvider = context.read<HabitProvider>();
    final reminderTimeStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    bool success;
    if (_isEditing) {
      final updatedHabit = widget.habitToEdit!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        categoryId: _selectedCategoryId,
        frequency: _frequency,
        customDays: _frequency == 'custom' ? _customDays : null,
        reminderTime: reminderTimeStr,
      );
      success = await habitProvider.updateHabit(updatedHabit);
    } else {
      final habit = await habitProvider.createHabit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        categoryId: _selectedCategoryId,
        frequency: _frequency,
        customDays: _frequency == 'custom' ? _customDays : null,
        reminderTime: reminderTimeStr,
      );
      success = habit != null;
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Habit updated' : 'Habit created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      // Only reset loading state if operation failed, so user can retry
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEditing ? 'Failed to update habit' : 'Failed to create habit'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteHabit() async {
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
      await context.read<HabitProvider>().deleteHabit(widget.habitToEdit!.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
