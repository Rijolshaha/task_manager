import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../services/session_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = '';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await SessionService.getUser();
    final imgPath = await SessionService.getProfileImagePath();

    File? img;
    if (imgPath != null && imgPath.isNotEmpty) {
      final f = File(imgPath);
      if (await f.exists()) img = f;
    }

    if (!mounted) return;
    setState(() {
      _userName = user['name'] ?? '';
      _profileImage = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _userName.isNotEmpty ? _userName : l10n.profile;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0DCA9F)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 35, color: Color(0xFF0DCA9F))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF0DCA9F)),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) {
                // Return qaytganda profil rasmi va ism yangilanishi ehtimolini inobatga olamiz
                _loadProfile();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF0DCA9F)),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          _buildNavTile(context, Icons.check_circle_outline, l10n.today, 0),
          _buildNavTile(context, Icons.calendar_today_outlined, l10n.upcoming, 1),
          _buildNavTile(context, Icons.folder_outlined, l10n.categories, 2),
          _buildNavTile(context, Icons.bar_chart_outlined, l10n.statistics, 3),
          _buildNavTile(context, Icons.smart_toy_outlined, l10n.ai_assistant, 4),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, l10n);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0DCA9F)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(initialIndex: index),
            transitionDuration: Duration.zero,
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () async {
              await SessionService.clearAll();
              await SessionService.setLoggedIn(false);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
