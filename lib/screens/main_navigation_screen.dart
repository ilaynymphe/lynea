import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'beauty_screen.dart';
import 'skincare_screen.dart';
import 'wishlist_screen.dart';
import 'outfit_studio_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'ai_suggestion_screen.dart';
import '../localization/app_strings.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    WardrobeScreen(),
    BeautyScreen(),
    SkincareScreen(),
    WishlistScreen(),
    AiSuggestionScreen(),
    OutfitStudioScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  List<_NavItem> get _navItems => [
        _NavItem(Icons.home_outlined, Icons.home, tr('nav_home')),
        _NavItem(Icons.checkroom_outlined, Icons.checkroom, tr('nav_wardrobe')),
        _NavItem(Icons.brush_outlined, Icons.brush, tr('nav_beauty')),
        _NavItem(Icons.spa_outlined, Icons.spa, tr('nav_skincare')),
        _NavItem(Icons.favorite_border, Icons.favorite, tr('nav_wishlist')),
        _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, tr('ai_suggestions')),
        _NavItem(Icons.style_outlined, Icons.style, tr('outfit_studio_title')),
        _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, tr('nav_stats')),
        _NavItem(Icons.person_outline, Icons.person, tr('nav_profile')),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: _isExpanded,
                backgroundColor: const Color(0xFFFBF8FA),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                leading: Column(
                  children: [
                    const SizedBox(height: 12),
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.menu_open : Icons.menu,
                        color: const Color(0xFFB185A7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/logo.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFB185A7),
                        size: 28,
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'LYNÉA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB185A7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
                selectedIconTheme: const IconThemeData(color: Color(0xFFB185A7), size: 28),
                unselectedIconTheme: IconThemeData(color: const Color(0xFFB185A7).withValues(alpha: 0.6), size: 24),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFFB185A7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: const Color(0xFFB185A7).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                destinations: _navItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  );
                }).toList(),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEFE6ED)),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _screens[_selectedIndex],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      drawer: Drawer(
        backgroundColor: const Color(0xFFFBF8FA),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 48,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFB185A7),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LYNÉA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB185A7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              ..._navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _selectedIndex;
                return ListTile(
                  leading: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected ? const Color(0xFFB185A7) : const Color(0xFFB185A7).withValues(alpha: 0.6),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFB185A7) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFFF3E5F5),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFB185A7)),
        title: Text(
          _navItems[_selectedIndex].label,
          style: const TextStyle(color: Color(0xFFB185A7), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem(this.icon, this.selectedIcon, this.label);
}