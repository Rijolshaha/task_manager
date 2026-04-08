import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../widgets/app_drawer.dart';

String _getCategoryLocalized(AppLocalizations l10n, String key) {
  switch (key.toLowerCase()) {
    case 'work':     return l10n.work;
    case 'personal': return l10n.personal;
    case 'shopping': return l10n.shopping;
    case 'health':   return l10n.health;
    case 'learning': return l10n.learning;
    case 'home':     return l10n.home;
    default:         return key;
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.statistics),
        centerTitle: false,
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: Hive.box<Task>('tasks').listenable(),
        builder: (context, box, _) {
          final tasks = box.values.toList();

          final totalTasks = tasks.length;
          final completedTasks = tasks.where((t) => t.isCompleted).length;
          final pendingTasks = totalTasks - completedTasks;
          final progress =
              totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

          final high = tasks.where((t) => t.priorityIndex == 2).length;
          final medium = tasks.where((t) => t.priorityIndex == 1).length;
          final low = tasks.where((t) => t.priorityIndex == 0).length;

          final categoryMap = <String, (int total, int done)>{};
          for (var t in tasks) {
            categoryMap.update(
              t.category,
              (v) => (v.$1 + 1, v.$2 + (t.isCompleted ? 1 : 0)),
              ifAbsent: () => (1, t.isCompleted ? 1 : 0),
            );
          }

          final now = DateTime.now();

          final todayCompleted = tasks.where((t) {
            if (t.completedAt == null) return false;
            final d = t.completedAt!;
            return d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          }).length;

          // ✅ Tuzatildi: Dushanba = 1, Yakshanba = 7
          // weekday - 1 → Dushanba uchun 0 kun olib tashlanadi (haqiqiy hafta boshi)
          final weekStart = DateTime(now.year, now.month,
              now.day - (now.weekday - 1));

          final weekCompleted = tasks.where((t) {
            if (t.completedAt == null) return false;
            return !t.completedAt!.isBefore(weekStart);
          }).length;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Umumiy progress ───
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Text(
                        l10n.overallProgress,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0DCA9F),
                              ),
                            ),
                            Text(
                              l10n.complete,
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF0DCA9F)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.check_circle, l10n.completed,
                              completedTasks, Colors.green),
                          _buildStatItem(Icons.hourglass_empty, l10n.pending,
                              pendingTasks, Colors.orange),
                          _buildStatItem(Icons.list_alt, l10n.totalTasks,
                              totalTasks, Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── So'nggi faollik ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.recentActivity,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildRecentItem(Icons.check_circle, l10n.today,
                          l10n.completedCount(todayCompleted)),
                      const SizedBox(height: 12),
                      _buildRecentItem(Icons.trending_up, l10n.thisWeek,
                          l10n.completedCount(weekCompleted)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Prioritet ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.priorityBreakdown,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildPriorityRow(Colors.red, l10n.highPriority, high),
                      const SizedBox(height: 12),
                      _buildPriorityRow(
                          Colors.orange, l10n.mediumPriority, medium),
                      const SizedBox(height: 12),
                      _buildPriorityRow(
                          Colors.green, l10n.lowPriority, low),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Kategoriya ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.categoryOverview,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (categoryMap.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(l10n.noTasksYet,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ),
                        )
                      else
                        ...categoryMap.entries.map((entry) {
                          final cat = entry.key;
                          final (total, done) = entry.value;
                          final catProgress =
                              total == 0 ? 0.0 : done / total;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getCategoryLocalized(l10n, cat),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _getCategoryColor(cat),
                                        )),
                                    Text('$done/$total'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: catProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                      _getCategoryColor(cat)),
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildStatItem(
      IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text('$value',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPriorityRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text('$count',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildRecentItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0DCA9F), size: 30),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'personal': return Colors.blue;
      case 'health':   return Colors.red;
      case 'work':     return Colors.purple;
      case 'shopping': return Colors.orange;
      case 'learning': return Colors.indigo;
      case 'home':     return Colors.teal;
      default:         return Colors.grey.shade700;
    }
  }
}
