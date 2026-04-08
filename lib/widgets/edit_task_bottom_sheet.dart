import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

class EditTaskBottomSheet extends StatefulWidget {
  final Task task;

  const EditTaskBottomSheet({super.key, required this.task});

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late String _categoryKey;
  late int _priorityIndex;
  late int _dueIndex;

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

    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(
      text: widget.task.description ?? '',
    );

    _categoryKey = _normalizeCategory(widget.task.category);
    _priorityIndex = widget.task.priorityIndex;
    _dueIndex = widget.task.dueIndex;

    if (widget.task.dueDate != null) {
      _dueDate = _dayStart(widget.task.dueDate!);
      _customDatePicked = true;
    } else {
      _dueDate = _dayStart(widget.task.safeDueDate);
      _customDatePicked = false;
    }
  }

  String _normalizeCategory(String value) {
    final v = value.trim().toLowerCase();
    if (_categoryKeys.contains(v)) return v;

    switch (value) {
      case 'Work':
        return 'work';
      case 'Personal':
        return 'personal';
      case 'Shopping':
        return 'shopping';
      case 'Health':
        return 'health';
      case 'Learning':
        return 'learning';
      case 'Home':
        return 'home';
      default:
        return 'personal';
    }
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

  Future<void> _deleteTask() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldDelete != true) return;

    setState(() => _saving = true);

    final key = widget.task.key;
    final int notifId = key is int ? key : key.hashCode;

    // ✅ UI ni yopamiz + snackbar
    final messenger = ScaffoldMessenger.of(context);
    if (mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskDeleted)));

    // ✅ cancel + delete try/catch
    try {
      await NotificationService.cancel(notifId);
    } catch (_) {}

    try {
      await widget.task.delete();
    } catch (_) {}
  }

  Future<void> _updateTask() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterTaskTitle)));
      return;
    }

    setState(() => _saving = true);

    final today = _dayStart(DateTime.now());
    final dueBase = _dayStart(_dueDate ?? today);
    final notifyAt = _withDefaultTime(dueBase);

    widget.task.title = _titleController.text.trim();
    widget.task.description = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : null;
    widget.task.priorityIndex = _priorityIndex;
    widget.task.category = _categoryKey;
    widget.task.dueIndex = _dueIndex;
    widget.task.dueDate = dueBase;

    await widget.task.save();

    if (!mounted) return;

    final key = widget.task.key;
    final int notifId = key is int ? key : key.hashCode;

    // ✅ UI ni darrov yopamiz
    final messenger = ScaffoldMessenger.of(context);
    if (mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskUpdated)));

    // ✅ notification schedule try/catch
    try {
      await NotificationService.requestPermissionIfNeeded();
      await NotificationService.cancel(notifId);
      await NotificationService.schedule(
        id: notifId,
        title: 'Task reminder',
        body: widget.task.title,
        dateTime: notifyAt,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ chip bosilsa dueDate sync bo‘lsin
    _syncDueDateFromDueIndex();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.editTaskTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.taskTitleLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.taskDescLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Text(
              l10n.priority,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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

            Text(
              l10n.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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

            Text(
              l10n.dueDate,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _deleteTask,
                    child: Text(l10n.delete),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0DCA9F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _updateTask,
                    child: Text(l10n.update),
                  ),
                ),
              ],
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
