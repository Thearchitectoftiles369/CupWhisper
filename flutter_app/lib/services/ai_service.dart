import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'ai_models.dart';
import 'app_language.dart';

abstract class AIService {
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  });

  Future<ReadingResult> generateFreeReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  });
}

class NoCreditsException implements Exception {
  const NoCreditsException();
}

class FreeReadingUsedException implements Exception {
  const FreeReadingUsedException();
}

class BackendAIService implements AIService {
  static const String _baseUrl = 'https://cupwhisper-backend-180766156374.europe-west1.run.app';

  Future<List<int>> _compressImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = decoded.width > 1280
        ? img.copyResize(decoded, width: 1280)
        : decoded;
    return img.encodeJpg(resized, quality: 85);
  }

  @override
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final idToken = await user.getIdToken();
    final compressedBytes = await _compressImage(imagePath);

    final uri = Uri.parse('$_baseUrl/reading');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['storyteller'] = storyteller.id
      ..fields['language'] = language.code
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          compressedBytes,
          filename: 'cup.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 402) {
      throw const NoCreditsException();
    }
    if (response.statusCode != 200) {
      throw Exception(
        'AI backend error: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final symbolsJson = body['symbols'] as List<dynamic>? ?? [];
    final symbols = symbolsJson
        .map((s) => ReadingSymbol.fromJson(s as Map<String, dynamic>))
        .toList();
    final conclusion = body['conclusion'] as String? ?? '';
    final conclusionAudio = body['conclusion_audio'] as String? ?? '';

    return ReadingResult(
      storyteller: storyteller,
      imagePath: imagePath,
      symbols: symbols,
      conclusion: conclusion,
      conclusionAudioBase64: conclusionAudio,
    );
  }

  @override
  Future<ReadingResult> generateFreeReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final idToken = await user.getIdToken();

    final uri = Uri.parse('$_baseUrl/free-reading');
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
      body: {
        'storyteller': storyteller.id,
        'language': language.code,
      },
    );

    if (response.statusCode == 409) {
      throw const FreeReadingUsedException();
    }
    if (response.statusCode != 200) {
      throw Exception(
        'AI backend error: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final symbolsJson = body['symbols'] as List<dynamic>? ?? [];
    final symbols = symbolsJson
        .map((s) => ReadingSymbol.fromJson(s as Map<String, dynamic>))
        .toList();
    final conclusion = body['conclusion'] as String? ?? '';
    final conclusionAudio = body['conclusion_audio'] as String? ?? '';

    return ReadingResult(
      storyteller: storyteller,
      imagePath: imagePath,
      symbols: symbols,
      conclusion: conclusion,
      conclusionAudioBase64: conclusionAudio,
    );
  }
}
