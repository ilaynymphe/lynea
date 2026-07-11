import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../localization/app_strings.dart';
import '../services/ai_service.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  final _occasionController = TextEditingController();
  String? _suggestion;
  bool _isLoading = false;

  final List<String> _quickOccasions = ['casual day', 'work', 'evening out', 'date night'];

  @override
  void dispose() {
    _occasionController.dispose();
    super.dispose();
  }

  Future<void> _getSuggestion([String? presetOccasion]) async {
    setState(() {
      _isLoading = true;
      _suggestion = null;
    });

    final box = Hive.box<ClothingItem>('clothingBox');
    final items = box.values.toList();
    final occasion = presetOccasion ??
        (_occasionController.text.trim().isEmpty ? 'casual day' : _occasionController.text.trim());

    final result = await AiService.suggestOutfit(items, occasion);

    if (!mounted) return;

    setState(() {
      _suggestion = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('ai_suggestions'))),
      body: AnimatedBuilder(
        animation: currentLanguage,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('ai_intro'),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _occasionController,
                  decoration: InputDecoration(
                    hintText: tr('ai_occasion_hint'),
                    filled: true,
                    fillColor: const Color(0xFFF3E5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickOccasions.map((occ) {
                    return ActionChip(
                      label: Text(occ),
                      backgroundColor: const Color(0xFFF3E5F5),
                      onPressed: _isLoading
                          ? null
                          : () {
                              _occasionController.text = occ;
                              _getSuggestion(occ);
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _getSuggestion(),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(tr('ai_get_suggestion')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFB185A7),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFB185A7)),
                        const SizedBox(height: 12),
                        Text(tr('ai_thinking')),
                      ],
                    ),
                  ),
                if (_suggestion != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB185A7).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFB185A7),
                              radius: 16,
                              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tr('ai_suggestions'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB185A7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _suggestion!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}