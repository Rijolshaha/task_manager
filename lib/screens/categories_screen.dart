import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/new_task_bottom_sheet.dart';
import '../widgets/edit_task_bottom_sheet.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // value -> DB/Hive ichidagi category qiymati (o'zgarmaydi)
  // label -> ekranga chiqadigan tarjima
  final List<Map<String, dynamic>> tabs = [
    {'value': 'All', 'icon': Icons.all_inclusive},
    {'value': 'Work', 'icon': Icons.work},
    {'value': 'Personal', 'icon': Icons.person},
    {'value': 'Shopping', 'icon': Icons.shopping_cart},
    {'value': 'Health', 'icon': Icons.favorite},
    {'value': 'Learning', 'icon': Icons.school},
    {'value': 'Home', 'icon': Icons.home},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tabLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'All':
        return l10n.all;
      case 'Work':
        return l10n.work;
      case 'Personal':
        return l10n.personal;
      case 'Shopping':
        return l10n.shopping;
      case 'Health':
        return l10n.health;
      case 'Learning':
        return l10n.learning;
      case 'Home':
        return l10n.home;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabs.map((tab) {
            final value = tab['value'] as String;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'], size: 18),
                  const SizedBox(width: 8),
                  Text(_tabLabel(context, value)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: Hive.box<Task>('tasks').listenable(),
        builder: (context, box, _) {
          final allTasks = box.values.toList();

          return TabBarView(
            controller: _tabController,
            children: tabs.map((tab) {
              final value = tab['value'] as String;

              final filteredTasks = value == 'All'
                  ? allTasks
                  : allTasks.where((t) => t.category == value).toList();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noTasksInCategory,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
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
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0DCA9F),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const NewTaskBottomSheet(),
        ),
      ),
    );
  }
}
