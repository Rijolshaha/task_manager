import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../repositories/message_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale _selectedLocale = const Locale('en');
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final code = await SessionService.getLocaleCode();
    final prefs = await SharedPreferences.getInstance();
    final notif = prefs.getBool('notifications_enabled') ?? true;
    
    if (mounted) {
      setState(() {
        _selectedLocale = Locale(code ?? 'en');
        _notificationsEnabled = notif;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    // Yoqilmasa — barcha rejalashtirilgan bildirishnomalarni bekor qilamiz
    if (!value) {
      await NotificationService.cancelAll();
    }
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _changeLanguage() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l10n.selectLanguage),
        children: [
          _langOption(const Locale('uz'), l10n.uzbek),
          _langOption(const Locale('en'), l10n.english),
          _langOption(const Locale('ru'), l10n.russian),
        ],
      ),
    );
  }

  Widget _langOption(Locale locale, String label) {
    return SimpleDialogOption(
      onPressed: () async {
        MyApp.setLocale(context, locale);
        await SessionService.saveLocaleCode(locale.languageCode);
        if (!mounted) return;
        setState(() => _selectedLocale = locale);
        Navigator.pop(context);
      },
      child: Text(label),
    );
  }

  String _languageLabel(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'uz': return l10n.uzbek;
      case 'ru': return l10n.russian;
      default: return l10n.english;
    }
  }

  void _clearAIChat() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diqqat'),
        content: const Text('Barcha AI suhbatlari o\'chib ketadi. Davom etasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = MessageRepository();
      await repo.init();
      await repo.clearMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AI suhbatlar arxivlari tozalandi!'), backgroundColor: Color(0xFF0DCA9F)),
        );
      }
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Task Manager AI',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.check_circle, size: 50, color: Color(0xFF0DCA9F)),
      children: [
        const Text('\nBu ilova zamonaviy AI yordamichisi bilan birga vazifalarni boshqarish uchun yaratilgan.')
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // Language Setting
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF0DCA9F)),
            title: Text(l10n.language),
            subtitle: Text(_languageLabel(context, _selectedLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLanguage,
          ),
          const Divider(),
          // Notifications
          SwitchListTile(
            activeColor: const Color(0xFF0DCA9F),
            secondary: const Icon(Icons.notifications_active, color: Color(0xFF0DCA9F)),
            title: const Text('Bildirishnomalar'),
            subtitle: const Text('Vazifalar eslatmalarini yoqish'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const Divider(),
          // Clear Chat Cache
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.orange),
            title: const Text('AI Suhbatni tozalash'),
            subtitle: const Text('Barcha xabarlar tarixini o\'chirish'),
            onTap: _clearAIChat,
          ),
          const Divider(),
          // About
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('Ilova haqida'),
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}
