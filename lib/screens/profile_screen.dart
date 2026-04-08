import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _username = '';
  String _email = '';
  Locale _selectedLocale = const Locale('en');

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = await SessionService.getUser();
    final imgPath = await SessionService.getProfileImagePath();
    final code = await SessionService.getLocaleCode();

    File? img;
    if (imgPath != null && imgPath.isNotEmpty) {
      final f = File(imgPath);
      if (await f.exists()) img = f;
    }

    if (!mounted) return;
    setState(() {
      _username = user['name'] ?? '';
      _email = user['email'] ?? '';
      _profileImage = img;
      _selectedLocale = Locale(code ?? 'en');
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      await SessionService.saveProfileImagePath(pickedFile.path);
      if (!mounted) return;
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  String _languageLabel(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'uz':
        return l10n.uzbek;
      case 'ru':
        return l10n.russian;
      default:
        return l10n.english;
    }
  }

  void _editName() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _username);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.changeName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.newName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                setState(() => _username = v);
                final old = await SessionService.getUser();
                await SessionService.saveUser(
                  name: v,
                  email: old['email'] ?? _email,
                  password: old['password'] ?? '',
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _editEmail() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.changeEmail),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.newEmail,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                setState(() => _email = v);
                final old = await SessionService.getUser();
                await SessionService.saveUser(
                  name: old['name'] ?? _username,
                  email: v,
                  password: old['password'] ?? '',
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
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

  void _logout() {
    final l10n = AppLocalizations.of(context)!;

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

              if (!mounted) return;
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

  // ✅ uzun email/ism UI buzmasin (1 qator + ellipsis)
  Widget _trailingOneLine(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0DCA9F),
                    const Color(0xFF0DCA9F).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF0DCA9F),
                                )
                              : null,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Color(0xFF0DCA9F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ headerdagi ism ham uzun bo'lsa buzilmasin
                  GestureDetector(
                    onTap: _editName,
                    child: Text(
                      _username.isEmpty ? '---' : _username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // ✅ headerdagi email ham uzun bo'lsa buzilmasin
                  GestureDetector(
                    onTap: _editEmail,
                    child: Text(
                      _email.isEmpty ? '---' : _email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountInformation,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(l10n.email),
                    trailing: _trailingOneLine(_email.isEmpty ? '---' : _email),
                    onTap: _editEmail,
                  ),

                  const Divider(),
                  const SizedBox(height: 24),

                  Text(
                    l10n.settings,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_languageLabel(context, _selectedLocale)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _changeLanguage,
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
