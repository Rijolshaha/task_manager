import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'ai_screen.dart';
import 'categories_screen.dart';
import 'statistics_screen.dart';
import 'today_screen.dart';
import 'upcoming_screen.dart';
import '../widgets/new_task_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // ✅ Har bir ekran o'z Scaffold + AppBar + Drawer'iga ega
  // HomeScreen faqat BottomNav va FAB ni boshqaradi
  final List<Widget> _screens = const [
    TodayScreen(),
    UpcomingScreen(),
    CategoriesScreen(),
    StatisticsScreen(),
    AiScreen(),
  ];

  // ✅ FAB faqat bugun/upcoming/kategoriya tablarida ko'rinadi
  bool get _showFab => _selectedIndex < 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ AppBar YO'Q — har bir ekran o'zini boshqaradi
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0DCA9F),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.check_circle_outline),
            activeIcon: const Icon(Icons.check_circle),
            label: l10n.today,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: l10n.upcoming,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: l10n.categories,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.statistics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy_outlined),
            activeIcon: const Icon(Icons.smart_toy),
            label: l10n.ai_assistant,
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => const NewTaskBottomSheet(),
                );
              },
              backgroundColor: const Color(0xFF0DCA9F),
              foregroundColor: Colors.white,
              elevation: 6,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }
}
