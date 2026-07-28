import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'ai_models.dart';
import 'app_language.dart';

abstract class AIService {
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  });
}

class BackendAIService implements AIService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  @override
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  }) async {
    final uri = Uri.parse('$_baseUrl/reading');
    final request = http.MultipartRequest('POST', uri)
      ..fields['storyteller'] = storyteller.id
      ..fields['language'] = language.code
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'AI backend error: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final story =
        body['story'] as String? ?? 'The cup remains silent for now.';

    return ReadingResult(
      storyteller: storyteller,
      story: story,
    );
  }
}
