import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

class NewTaskBottomSheet extends StatefulWidget {
  const NewTaskBottomSheet({super.key});

  @override
  State<NewTaskBottomSheet> createState() => _NewTaskBottomSheetState();
}

class _NewTaskBottomSheetState extends State<NewTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _categoryKey = 'personal';
  int _priorityIndex = 1;
  int _dueIndex = 0;

  DateTime? _dueDate;
  bool _customDatePicked = false;

  bool _saving = false;

  final List<String> _categoryKeys = const [
    'work',
    'personal',
    'shopping',
    'health',
    'learning',
    'home',
  ];

  @override
  void initState() {
    super.initState();
    _syncDueDateFromDueIndex();
  }

  void _syncDueDateFromDueIndex() {
    final today = _dayStart(DateTime.now());
    if (_customDatePicked) return;

    if (_dueIndex == 0) {
      _dueDate = today;
    } else if (_dueIndex == 1) {
      _dueDate = today.add(const Duration(days: 1));
    } else {
      _dueDate = today.add(const Duration(days: 7));
    }
  }

  DateTime _withDefaultTime(DateTime date) =>
      DateTime(date.year, date.month, date.day, 9, 0);

  String _priorityLabel(AppLocalizations l10n, int idx) {
    if (idx == 0) return l10n.low;
    if (idx == 1) return l10n.medium;
    return l10n.high;
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'work':
        return l10n.work;
      case 'personal':
        return l10n.personal;
      case 'shopping':
        return l10n.shopping;
      case 'health':
        return l10n.health;
      case 'learning':
        return l10n.learning;
      case 'home':
        return l10n.home;
      default:
        return key;
    }
  }

  Future<void> _pickDueDate() async {
    final l10n = AppLocalizations.of(context)!;
    final today = _dayStart(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _dueDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
      helpText: l10n.selectDate,
    );

    if (picked != null) {
      final normalized = _dayStart(picked);
      setState(() {
        _dueDate = normalized;
        _customDatePicked = true;

        final tomorrow = today.add(const Duration(days: 1));
        if (normalized.isAtSameMomentAs(today)) {
          _dueIndex = 0;
        } else if (normalized.isAtSameMomentAs(tomorrow)) {
          _dueIndex = 1;
        } else {
          _dueIndex = 2;
        }
      });
    }
  }

  String _dueLabel(AppLocalizations l10n) {
    final today = _dayStart(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    if (_dueDate == null) return l10n.notSelected;

    final d = _dayStart(_dueDate!);
    if (d.isAtSameMomentAs(today)) return l10n.today;
    if (d.isAtSameMomentAs(tomorrow)) return l10n.tomorrow;

    return MaterialLocalizations.of(context).formatShortDate(_dueDate!);
  }

  Future<void> _createTask() async {
    final l10n = AppLocalizations.of(context)!;

    if (_saving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterTaskTitle)),
      );
      return;
    }

    setState(() => _saving = true);

    final today = _dayStart(DateTime.now());
    final dueBase = _dayStart(_dueDate ?? today);
    final notifyAt = _withDefaultTime(dueBase);

    final newTask = Task(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      priorityIndex: _priorityIndex,
      category: _categoryKey,
      dueIndex: _dueIndex,
      dueDate: dueBase,
      isCompleted: false,
      completedAt: null,
    );

    final box = Hive.box<Task>('tasks');
    final hiveKey = await box.add(newTask);
    final int notifId = hiveKey is int ? hiveKey : hiveKey.hashCode;

    // ✅ 1) UI ni darrov yopamiz (notification xatosi UI ni buzmasin)
    final messenger = ScaffoldMessenger.of(context);
    if (mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskAdded)));

    // ✅ 2) Notification alohida try/catch bilan
    try {
      await NotificationService.requestPermissionIfNeeded();
      await NotificationService.schedule(
        id: notifId,
        title: 'Task reminder',
        body: newTask.title,
        dateTime: notifyAt,
      );
    } catch (_) {
      // xato bo‘lsa ham task saqlangan, UI yopilgan bo‘ladi
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.newTaskTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.taskTitleLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.taskDescLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Text(l10n.priority, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0, 1, 2].map((i) {
                return ChoiceChip(
                  label: Text(_priorityLabel(l10n, i)),
                  selected: _priorityIndex == i,
                  onSelected: (_) => setState(() => _priorityIndex = i),
                  selectedColor: const Color(0xFF0DCA9F),
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(l10n.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryKeys.map((k) {
                return FilterChip(
                  label: Text(_categoryLabel(l10n, k)),
                  selected: _categoryKey == k,
                  onSelected: (_) => setState(() => _categoryKey = k),
                  selectedColor: const Color(0xFF0DCA9F),
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(l10n.dueDate, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.today),
                  selected: _dueIndex == 0,
                  onSelected: (_) => setState(() {
                    _dueIndex = 0;
                    _customDatePicked = false;
                    _syncDueDateFromDueIndex();
                  }),
                  selectedColor: const Color(0xFF0DCA9F),
                  backgroundColor: Colors.grey.shade200,
                ),
                ChoiceChip(
                  label: Text(l10n.tomorrow),
                  selected: _dueIndex == 1,
                  onSelected: (_) => setState(() {
                    _dueIndex = 1;
                    _customDatePicked = false;
                    _syncDueDateFromDueIndex();
                  }),
                  selectedColor: const Color(0xFF0DCA9F),
                  backgroundColor: Colors.grey.shade200,
                ),
                ChoiceChip(
                  label: Text(l10n.nextWeek),
                  selected: _dueIndex == 2,
                  onSelected: (_) => setState(() {
                    _dueIndex = 2;
                    _customDatePicked = false;
                    _syncDueDateFromDueIndex();
                  }),
                  selectedColor: const Color(0xFF0DCA9F),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n.selectDate),
              subtitle: Text(_dueLabel(l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDueDate,
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _saving ? null : _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0DCA9F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _saving ? '...' : l10n.add,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
