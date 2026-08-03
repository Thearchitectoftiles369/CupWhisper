import 'dart:ui' show Offset;

enum Storyteller {
  bulgarian(
    id: 'bulgarian',
    displayName: 'Bulgarian Fortune Teller',
    flag: '🇧🇬',
  ),
  turkish(
    id: 'turkish',
    displayName: 'Turkish Fortune Teller',
    flag: '🇹🇷',
  );

  const Storyteller({
    required this.id,
    required this.displayName,
    required this.flag,
  });

  final String id;
  final String displayName;
  final String flag;
}

class ReadingSymbol {
  const ReadingSymbol({
    required this.phrase,
    required this.points,
    required this.audioBase64,
  });

  final String phrase;
  final List<Offset> points;
  final String audioBase64;

  factory ReadingSymbol.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['x'] as num?)?.toDouble() ?? 0.0,
        (map['y'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return ReadingSymbol(
      phrase: json['phrase'] as String? ?? '',
      points: points,
      audioBase64: json['audio'] as String? ?? '',
    );
  }
}

class ReadingResult {
  const ReadingResult({
    required this.storyteller,
    required this.imagePath,
    required this.symbols,
    required this.conclusion,
    required this.conclusionAudioBase64,
  });

  final Storyteller storyteller;
  final String imagePath;
  final List<ReadingSymbol> symbols;
  final String conclusion;
  final String conclusionAudioBase64;
}
