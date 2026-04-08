import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../widgets/app_drawer.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../widgets/new_task_bottom_sheet.dart';
import '../widgets/task_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> tabs = const [
    {'value': 'all', 'icon': Icons.all_inclusive},
    {'value': 'work', 'icon': Icons.work},
    {'value': 'personal', 'icon': Icons.person},
    {'value': 'shopping', 'icon': Icons.shopping_cart},
    {'value': 'health', 'icon': Icons.favorite},
    {'value': 'learning', 'icon': Icons.school},
    {'value': 'home', 'icon': Icons.home},
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

  String _normalizeCategory(String value) {
    final v = value.trim().toLowerCase();
    const known = ['all', 'work', 'personal', 'shopping', 'health', 'learning', 'home'];
    if (known.contains(v)) return v;

    // Eski TitleCase qiymatlar
    final map = {
      'All': 'all', 'Work': 'work', 'Personal': 'personal',
      'Shopping': 'shopping', 'Health': 'health', 'Learning': 'learning',
      'Home': 'home',
    };
    return map[value] ?? 'personal';
  }

  String _tabLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'all':      return l10n.all;
      case 'work':     return l10n.work;
      case 'personal': return l10n.personal;
      case 'shopping': return l10n.shopping;
      case 'health':   return l10n.health;
      case 'learning': return l10n.learning;
      case 'home':     return l10n.home;
      default:         return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.categories),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabs.map((tab) {
            final key = tab['value'] as String;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'] as IconData, size: 18),
                  const SizedBox(width: 6),
                  Text(_tabLabel(context, key)),
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
              final key = tab['value'] as String;

              final filteredTasks = key == 'all'
                  ? allTasks
                  : allTasks
                      .where((t) => _normalizeCategory(t.category) == key)
                      .toList();

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
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24)),
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
