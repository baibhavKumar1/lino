import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../jev_classification_service.dart';
import 'openrouter_client.dart';

class ScannedReceiptItem {
  final String name;
  final int quantity;
  final String unit;
  String categoryKey;

  ScannedReceiptItem({
    required this.name,
    this.quantity = 1,
    this.unit = '1 kg',
    this.categoryKey = 'kitchenStaples',
  });

  factory ScannedReceiptItem.fromJson(Map<String, dynamic> json) {
    return ScannedReceiptItem(
      name: json['name'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? '1 kg',
      categoryKey: json['categoryKey'] as String? ?? 'kitchenStaples',
    );
  }
}

class ReceiptOcrService {
  static const List<String> visionModels = [
    'google/gemini-2.0-flash-001',
    'google/gemini-flash-1.5',
    'meta-llama/llama-3.2-11b-vision-instruct:free',
    'qwen/qwen-2-vl-72b-instruct',
  ];

  static Future<List<ScannedReceiptItem>> analyzeReceiptImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    for (final model in visionModels) {
      try {
        final response = await http.post(
          Uri.parse(OpenRouterClient.baseUrl),
          headers: {
            'Authorization': 'Bearer ${OpenRouterClient.apiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://lino.app',
            'X-Title': 'Lino Receipt OCR',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text': '''You are a supermarket receipt OCR extractor.
Examine this grocery receipt image and extract all purchased items with their EXACT weight, unit, and quantity printed on the bill.
Map categoryKey to one of:
- "readyToCook" (for Oats, Maggie, Noodles, Soup, Pasta, Ready Mix, Instant food)
- "singleSpices" (for Jeera, Haldi, Mirch, Cumin, Mustard, Pepper, etc.)
- "masalaBlends" (for Garam Masala, Sambhar Masala, Pav Bhaji Masala, etc.)
- "freshProduce" (for Tomatoes, Onions, Potatoes, Ginger, Coriander, Garlic, etc.)
- "riceGrains" (for Basmati Rice, Poha, Millets, Quinoa, etc.)
- "pulsesLentils" (for Toor Dal, Moong, Chana, Rajma, Urad, etc.)
- "dryFruitsNuts" (for Badam, Cashews, Almonds, Walnuts, etc.)
- "floursBaking" (for Atta, Besan, Maida, Sooji, etc.)
- "kitchenStaples" (for Milk, Ghee, Butter, Paneer, Curd, Oil, Salt, Sugar, Tea, etc.)

Return ONLY valid JSON in this exact schema:
{
  "items": [
    {
      "name": "Masala Oats",
      "quantity": 1,
      "unit": "500 g",
      "categoryKey": "readyToCook"
    },
    {
      "name": "Maggi 2-Minute Noodles",
      "quantity": 2,
      "unit": "560 g",
      "categoryKey": "readyToCook"
    }
  ]
}''',
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image',
                    },
                  },
                ],
              },
            ],
            'temperature': 0.1,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final content = body['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
            if (jsonMatch != null) {
              final jsonStr = jsonMatch.group(0)!;
              final jsonMap = jsonDecode(jsonStr);
              if (jsonMap is Map && jsonMap.containsKey('items')) {
                final rawList = List<dynamic>.from(jsonMap['items']);
                final items = <ScannedReceiptItem>[];
                for (var e in rawList) {
                  if (e is Map<String, dynamic>) {
                    items.add(ScannedReceiptItem.fromJson(e));
                  } else if (e is String && e.trim().isNotEmpty) {
                    items.add(ScannedReceiptItem(name: e.trim()));
                  }
                }
                if (items.isNotEmpty) {
                  // Enhance categorized items with Jev System One classifier in parallel
                  await Future.wait(
                    items.map((item) async {
                      if (item.categoryKey == 'kitchenStaples' || item.categoryKey.isEmpty) {
                        try {
                          final classified = await JevClassificationService.classifyGroceryCategory(item.name);
                          // Assign precise categoryKey
                          item.categoryKey = classified.name;
                        } catch (_) {
                          // Fallback to existing
                        }
                      }
                    }),
                  );
                  return items;
                }
              }
            }
          }
        }
      } catch (e) {
        // Try next vision model fallback
        continue;
      }
    }

    return [];
  }
}
