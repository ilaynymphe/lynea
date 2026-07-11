import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../localization/app_strings.dart';

final ValueNotifier<bool> onboardingComplete = ValueNotifier(false);

Future<void> loadOnboardingStatus() async {
  final settingsBox = Hive.box('settingsBox');
  onboardingComplete.value = settingsBox.get('onboardingComplete', defaultValue: false);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {'icon': Icons.checkroom, 'titleKey': 'onboard_title1', 'descKey': 'onboard_desc1'},
    {'icon': Icons.auto_awesome, 'titleKey': 'onboard_title2', 'descKey': 'onboard_desc2'},
    {'icon': Icons.cloud_sync, 'titleKey': 'onboard_title3', 'descKey': 'onboard_desc3'},
  ];

  void _finish() {
    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('onboardingComplete', true);
    onboardingComplete.value = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(tr('onboard_skip'), style: const TextStyle(color: Colors.grey)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'] as IconData, size: 64, color: const Color(0xFFB185A7)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          tr(page['titleKey'] as String),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(page['descKey'] as String),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFB185A7) : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB185A7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? tr('onboard_start') : tr('onboard_next'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}