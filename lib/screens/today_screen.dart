import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../utils/helpers.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<Box<Task>>(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final todayTasks = box.values
            .where((t) => _isSameDay(t.dueDate ?? today, today))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.today),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  getFormattedDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          body: todayTasks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  l10n.noTasksToday,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createTaskToStart,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todayTasks.length,
            itemBuilder: (context, index) {
              final task = todayTasks[index];
              return TaskCard(
                task: task,
                onEdit: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => EditTaskBottomSheet(task: task),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
