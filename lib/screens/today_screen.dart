import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../utils/helpers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ Drawer qo'shildi — hamburger icon avtomatik chiqadi
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.today),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                getFormattedDate(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: Hive.box<Task>('tasks').listenable(),
        builder: (context, box, _) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final todayTasks = box.values
              .where((t) => _isSameDay(t.dueDate ?? today, today))
              .toList();

          // ✅ Completed va pending bo'yicha ajratib ko'rsatish
          final pending = todayTasks.where((t) => !t.isCompleted).toList();
          final completed = todayTasks.where((t) => t.isCompleted).toList();

          if (todayTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTasksToday,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createTaskToStart,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Bajarilmaganlar ───
              if (pending.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${l10n.pending} (${pending.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ...pending.map(
                  (task) => TaskCard(
                    task: task,
                    onEdit: () => _openEdit(context, task),
                  ),
                ),
              ],

              // ─── Bajarilganlar ───
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${l10n.completed} (${completed.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ...completed.map(
                  (task) => TaskCard(
                    task: task,
                    onEdit: () => _openEdit(context, task),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTaskBottomSheet(task: task),
    );
  }
}
