import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/clothing_item.dart';

class AiService {
  static Future<String> suggestOutfit(List<ClothingItem> items, String occasion) async {
    if (items.isEmpty) {
      return 'Add some clothing items to your wardrobe first!';
    }

    final itemsDescription = items.map((item) {
      return '- ${item.name} (${item.category}, ${item.color}, ${item.season})';
    }).join('\n');

    final prompt = '''
You are a helpful fashion assistant. Here is the user's wardrobe:

$itemsDescription

The occasion is: $occasion

Suggest one complete outfit using only items from this wardrobe. Explain briefly why it works. Keep the response short and friendly, maximum 4-5 sentences.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No suggestion received.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error getting suggestion: $e';
    }
  }
}