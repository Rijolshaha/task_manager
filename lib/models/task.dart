import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  int priorityIndex; // 0 low, 1 medium, 2 high

  // ✅ category endi KEY bo'ladi: work/personal/...
  @HiveField(3)
  String category;

  // ✅ dueIndex qoladi (bugun/ertaga/next week)
  @HiveField(4)
  int dueIndex;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime? completedAt;

  // ✅ MUHIM: nullable bo'lsin, eski tasklarda null bo'lishi mumkin
  @HiveField(7)
  DateTime? dueDate;

  Task({
    required this.title,
    this.description,
    this.priorityIndex = 1,
    required this.category,
    this.dueIndex = 0,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
  });

  // ✅ Null bo'lsa dueIndex bo'yicha hisoblab beradi
  DateTime get safeDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dueDate != null) {
      final d = dueDate!;
      return DateTime(d.year, d.month, d.day);
    }

    if (dueIndex == 0) return today;
    if (dueIndex == 1) return today.add(const Duration(days: 1));
    return today.add(const Duration(days: 7));
  }

  // ✅ muddat o'tib ketganmi? (bugun tugagan task bugun ichida o'tmagan hisoblanadi)
  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return safeDueDate.isBefore(today) && !isCompleted;
  }
}
