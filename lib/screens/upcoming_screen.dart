import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../widgets/task_card.dart';

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<Box<Task>>(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final today = _dayStart(now);

        final upcomingTasks = box.values
            .where((t) => _dayStart(t.dueDate ?? today).isAfter(today))
            .toList()
          ..sort((a, b) => (a.dueDate ?? today).compareTo(b.dueDate ?? today));

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.upcoming),
            centerTitle: false,
          ),
          body: upcomingTasks.isEmpty
              ? Center(child: Text(l10n.noUpcomingTasks))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingTasks.length,
            itemBuilder: (context, index) {
              final task = upcomingTasks[index];
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
