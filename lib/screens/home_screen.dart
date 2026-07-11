import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../models/makeup_item.dart';
import '../models/skincare_item.dart';
import '../localization/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/platform_image.dart';
import 'wardrobe_screen.dart';
import 'ai_suggestion_screen.dart';
import 'outfit_studio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clothingBox = Hive.box<ClothingItem>('clothingBox');
    final makeupBox = Hive.box<MakeupItem>('makeupBox');
    final skincareBox = Hive.box<SkincareItem>('skincareBox');
    final settingsBox = Hive.box('settingsBox');
    final userName = settingsBox.get('userName', defaultValue: '');
    final user = AuthService().currentUser;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          clothingBox.listenable(),
          makeupBox.listenable(),
          skincareBox.listenable(),
          currentLanguage,
        ]),
        builder: (context, _) {
          final now = DateTime.now();

          final expiringMakeup = makeupBox.values.where((item) =>
              item.expiryDate != null &&
              item.expiryDate!.difference(now).inDays <= 30 &&
              item.expiryDate!.difference(now).inDays >= 0).length;

          final expiringSkincare = skincareBox.values.where((item) =>
              item.expiryDate != null &&
              item.expiryDate!.difference(now).inDays <= 30 &&
              item.expiryDate!.difference(now).inDays >= 0).length;

          final totalExpiring = expiringMakeup + expiringSkincare;

          final displayName = (userName as String).isNotEmpty
              ? userName
              : (user?.displayName ?? '');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB185A7), Color(0xFFE7A9C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty
                          ? '${tr('home_welcome')} $displayName'
                          : tr('home_welcome'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('home_slogan'),
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.checkroom,
                      label: tr('home_clothing'),
                      count: clothingBox.values.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.brush,
                      label: tr('home_makeup'),
                      count: makeupBox.values.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.spa,
                      label: tr('home_skincare'),
                      count: skincareBox.values.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (totalExpiring > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$totalExpiring ${tr('home_expiring_warning')}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                tr('home_quick_actions'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.auto_awesome,
                      label: tr('ai_suggestions'),
                      color: const Color(0xFFB185A7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AiSuggestionScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.style,
                      label: tr('outfit_studio_title'),
                      color: const Color(0xFFE7A9C7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OutfitStudioScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('home_recent'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WardrobeScreen()),
                      );
                    },
                    child: Text(tr('home_see_all')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (clothingBox.values.isEmpty &&
                  makeupBox.values.isEmpty &&
                  skincareBox.values.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    tr('home_empty'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._buildRecentItems(clothingBox, makeupBox, skincareBox),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildRecentItems(
    Box<ClothingItem> clothingBox,
    Box<MakeupItem> makeupBox,
    Box<SkincareItem> skincareBox,
  ) {
    final allItems = <_RecentItem>[
      ...clothingBox.values.map((e) => _RecentItem(e.name, e.category, Icons.checkroom, e.dateAdded, e.imagePath)),
      ...makeupBox.values.map((e) => _RecentItem(e.name, e.category, Icons.brush, e.dateAdded, e.imagePath)),
      ...skincareBox.values.map((e) => _RecentItem(e.name, e.category, Icons.spa, e.dateAdded, e.imagePath)),
    ];

    allItems.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final recent = allItems.take(5).toList();

    return recent.map((item) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF3E5F5),
            child: item.imagePath != null
                ? ClipOval(child: buildPickedImage(item.imagePath!))
                : Icon(item.icon, color: const Color(0xFFB185A7)),
          ),
          title: Text(item.name),
          subtitle: Text(item.category),
        ),
      );
    }).toList();
  }
}

class _RecentItem {
  final String name;
  final String category;
  final IconData icon;
  final DateTime dateAdded;
  final String? imagePath;

  _RecentItem(this.name, this.category, this.icon, this.dateAdded, this.imagePath);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _StatCard({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB185A7)),
          const SizedBox(height: 6),
          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}