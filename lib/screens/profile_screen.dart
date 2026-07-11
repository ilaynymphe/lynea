import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/clothing_item.dart';
import '../models/makeup_item.dart';
import '../models/skincare_item.dart';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  String? _profileImagePath;
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box('settingsBox');
    _nameController = TextEditingController(text: settingsBox.get('userName', defaultValue: ''));
    _profileImagePath = settingsBox.get('profileImagePath');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName(String value) {
    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('userName', value.trim());
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImagePath = picked.path;
      });
      final settingsBox = Hive.box('settingsBox');
      settingsBox.put('profileImagePath', picked.path);
    }
  }
  void _removeProfileImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('change_photo')),
        content: Text(tr('delete_item_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _profileImagePath = null;
              });
              final settingsBox = Hive.box('settingsBox');
              settingsBox.delete('profileImagePath');
              Navigator.pop(context);
            },
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });
    final user = await _authService.signInWithGoogle();
    setState(() {
      _isSigningIn = false;
    });
    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('sign_in_failed'))),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('signed_out_message'))),
      );
    }
  }

  Future<void> _handleManualSync() async {
    setState(() {
      _isSyncing = true;
    });
    try {
      await SyncService().syncAll();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('sync_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _exportWardrobe() async {
    final box = Hive.box<ClothingItem>('clothingBox');
    final rows = <List<String>>[
      ['Name', 'Category', 'Color', 'Season', 'Brand', 'Price', 'Purchased From', 'Condition', 'Note', 'Date Added'],
    ];
    for (final item in box.values) {
      rows.add([
        item.name,
        item.category,
        item.color,
        item.season,
        item.brand ?? '',
        item.purchasePrice?.toString() ?? '',
        item.purchasedFrom ?? '',
        item.condition ?? '',
        item.note ?? '',
        item.dateAdded.toString(),
      ]);
    }
    final csvData = const ListToCsvConverter().convert(rows);
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(csvData.codeUnits), name: 'wardrobe.csv', mimeType: 'text/csv')],
    );
  }

  Future<void> _exportBeauty() async {
    final box = Hive.box<MakeupItem>('makeupBox');
    final rows = <List<String>>[
      ['Name', 'Category', 'Brand', 'Shade', 'Price', 'Expiry Date', 'Note', 'Date Added'],
    ];
    for (final item in box.values) {
      rows.add([
        item.name,
        item.category,
        item.brand,
        item.shade,
        item.purchasePrice?.toString() ?? '',
        item.expiryDate?.toString() ?? '',
        item.note ?? '',
        item.dateAdded.toString(),
      ]);
    }
    final csvData = const ListToCsvConverter().convert(rows);
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(csvData.codeUnits), name: 'beauty.csv', mimeType: 'text/csv')],
    );
  }

  Future<void> _exportSkincare() async {
    final box = Hive.box<SkincareItem>('skincareBox');
    final rows = <List<String>>[
      ['Name', 'Category', 'Brand', 'Skin Type', 'Price', 'Expiry Date', 'Note', 'Date Added'],
    ];
    for (final item in box.values) {
      rows.add([
        item.name,
        item.category,
        item.brand,
        item.skinType,
        item.purchasePrice?.toString() ?? '',
        item.expiryDate?.toString() ?? '',
        item.note ?? '',
        item.dateAdded.toString(),
      ]);
    }
    final csvData = const ListToCsvConverter().convert(rows);
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(csvData.codeUnits), name: 'skincare.csv', mimeType: 'text/csv')],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('nav_profile'))),
      body: AnimatedBuilder(
        animation: currentLanguage,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  onLongPress: _profileImagePath != null ? _removeProfileImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFF3E5F5),
                        child: _profileImagePath == null
                            ? const Icon(Icons.person, size: 48, color: Color(0xFFB185A7))
                            : ClipOval(
                                child: Image.network(
                                  _profileImagePath!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFB185A7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: tr('profile_name_hint'),
                  border: InputBorder.none,
                ),
                onChanged: _saveName,
              ),
              const SizedBox(height: 24),
              Text(
                tr('account'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              StreamBuilder<User?>(
                stream: _authService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null) {
                    return Column(
                      children: [
                        Card(
                          child: ListTile(
                            leading: user.photoURL != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user.photoURL!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user.displayName ?? tr('nav_profile')),
                            subtitle: Text(user.email ?? ''),
                            trailing: TextButton(
                              onPressed: _handleSignOut,
                              child: Text(tr('sign_out'), style: const TextStyle(color: Colors.red)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: _isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync, color: Color(0xFFB185A7)),
                            title: Text(tr('sync_now')),
                            subtitle: Text(tr('sync_now_subtitle')),
                            onTap: _isSyncing ? null : _handleManualSync,
                          ),
                        ),
                      ],
                    );
                  }
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.login, color: Color(0xFFB185A7)),
                      title: Text(tr('sign_in_google')),
                      subtitle: Text(tr('sign_in_google_subtitle')),
                      trailing: _isSigningIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _isSigningIn ? null : _handleGoogleSignIn,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                tr('profile_language'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: 'English',
                code: 'en',
                isSelected: currentLanguage.value == 'en',
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                label: 'Türkçe',
                code: 'tr',
                isSelected: currentLanguage.value == 'tr',
              ),
              const SizedBox(height: 24),
              Text(
                tr('profile_theme'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: isDarkMode,
                builder: (context, dark, _) {
                  return Column(
                    children: [
                      _ThemeOption(
                        label: tr('theme_light'),
                        icon: Icons.light_mode_outlined,
                        isSelected: !dark,
                        onTap: () => toggleTheme(false),
                      ),
                      const SizedBox(height: 8),
                      _ThemeOption(
                        label: tr('theme_dark'),
                        icon: Icons.dark_mode_outlined,
                        isSelected: dark,
                        onTap: () => toggleTheme(true),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                tr('export_data'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.checkroom, color: Color(0xFFB185A7)),
                  title: Text(tr('export_wardrobe')),
                  trailing: const Icon(Icons.download),
                  onTap: _exportWardrobe,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.brush, color: Color(0xFFB185A7)),
                  title: Text(tr('export_beauty')),
                  trailing: const Icon(Icons.download),
                  onTap: _exportBeauty,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.spa, color: Color(0xFFB185A7)),
                  title: Text(tr('export_skincare')),
                  trailing: const Icon(Icons.download),
                  onTap: _exportSkincare,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? const Color(0xFFF3E5F5) : null,
      child: ListTile(
        title: Text(label),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFB185A7))
            : null,
        onTap: () {
          changeLanguage(code);
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? const Color(0xFFF3E5F5) : null,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFB185A7))
            : null,
        onTap: onTap,
      ),
    );
  }
}