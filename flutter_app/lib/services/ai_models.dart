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

class ReadingResult {
  const ReadingResult({
    required this.storyteller,
    required this.story,
  });

  final Storyteller storyteller;
  final String story;
}
