import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

Color _getCategoryColor(String cat) {
  switch (cat.toLowerCase()) {
    case 'personal':
      return Colors.blue;
    case 'health':
      return Colors.red;
    case 'work':
      return Colors.purple;
    case 'shopping':
      return Colors.orange;
    case 'learning':
      return Colors.indigo;
    case 'home':
      return Colors.teal;
    default:
      return Colors.grey.shade700;
  }
}

String _categoryLabel(AppLocalizations l10n, String key) {
  switch (key.toLowerCase()) {
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

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;

  const TaskCard({super.key, required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categoryColor = _getCategoryColor(task.category);
    final priorityColor = task.priorityIndex == 0
        ? Colors.green
        : task.priorityIndex == 1
        ? Colors.orange
        : Colors.red;

    final now = DateTime.now();
    final today = _dayStart(now);
    final tomorrow = today.add(const Duration(days: 1));

    // ✅ dueDate nullable bo‘lgani uchun safeDueDate ishlatamiz
    final safeDue = task.dueDate ?? DateTime.now();
    final due = _dayStart(safeDue);

    final dueText = due.isAtSameMomentAs(today)
        ? l10n.today
        : due.isAtSameMomentAs(tomorrow)
        ? l10n.tomorrow
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(safeDue); // ✅ aniq sana

    final categoryText = _categoryLabel(l10n, task.category);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: task.isCompleted
                ? Colors.green
                : (task.isOverdue ? Colors.grey : categoryColor),
            size: 28,
          ),
          onPressed: () async {
            if (task.isOverdue) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.taskOverdueCannotComplete)),
              );
              return;
            }

            task.isCompleted = !task.isCompleted;
            task.completedAt = task.isCompleted ? DateTime.now() : null;
            await task.save();

            try {
              if (task.isCompleted) {
                await NotificationService.cancelForKey(task.key);
              } else {
                await NotificationService.scheduleForTask(
                  task: task,
                  hiveKey: task.key,
                  reminderTitle: l10n.taskReminderTitle,
                );
              }
            } catch (_) {}
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: task.description?.isNotEmpty == true
            ? Text(task.description!)
            : null,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categoryText,
                style: TextStyle(color: categoryColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  dueText,
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey,
                    fontWeight: task.isOverdue
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
