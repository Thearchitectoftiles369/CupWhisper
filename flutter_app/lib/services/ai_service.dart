import 'ai_models.dart';

abstract class AIService {
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
  });
}

class MockAIService implements AIService {
  static const Map<Storyteller, String> _mockStories = {
    Storyteller.bulgarian:
        'The grounds settle like whispers from the old mountains. '
        'A path opens before you — unexpected, but not unwelcome. '
        'Someone from your past may reach out soon. Stay open to it, '
        'for the cup rarely lies about matters of the heart.',
    Storyteller.turkish:
        'The shapes in your cup speak of a journey yet to begin. '
        'A bird near the rim suggests good news traveling toward you. '
        'Patience will be rewarded before the next full moon. '
        'Trust what your instincts have been telling you.',
  };

  @override
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    return ReadingResult(
      storyteller: storyteller,
      story: _mockStories[storyteller] ?? 'The cup remains silent for now.',
    );
  }
}
