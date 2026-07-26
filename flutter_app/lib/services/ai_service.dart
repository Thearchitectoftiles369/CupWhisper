import 'ai_models.dart';
import 'app_language.dart';

abstract class AIService {
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  });
}

class MockAIService implements AIService {
  static const Map<Storyteller, Map<String, String>> _mockStories = {
    Storyteller.bulgarian: {
      'en':
          'The grounds settle like whispers from the old mountains. '
          'A path opens before you — unexpected, but not unwelcome. '
          'Someone from your past may reach out soon. Stay open to it, '
          'for the cup rarely lies about matters of the heart.',
      'bg':
          'Утайката се утаява като шепот от старите планини. '
          'Пред теб се отваря път — неочакван, но желан. '
          'Скоро някой от миналото ти може да се свърже с теб. Бъди отворен, '
          'защото чашата рядко лъже за сърдечни въпроси.',
      'tr':
          'Telve, eski dağlardan gelen fısıltılar gibi çöküyor. '
          'Önünde beklenmedik ama hoş bir yol açılıyor. '
          'Geçmişinden biri yakında sana ulaşabilir. Buna açık ol, '
          'çünkü fincan kalp meselelerinde nadiren yalan söyler.',
      'de':
          'Der Kaffeesatz setzt sich wie Flüstern aus den alten Bergen. '
          'Ein Weg öffnet sich vor dir — unerwartet, aber willkommen. '
          'Jemand aus deiner Vergangenheit meldet sich vielleicht bald. Bleib offen dafür, '
          'denn die Tasse lügt selten in Herzensangelegenheiten.',
      'fr':
          'Le marc se dépose comme des murmures venus des vieilles montagnes. '
          "Un chemin s'ouvre devant toi — inattendu, mais bienvenu. "
          'Quelqu\'un de ton passé pourrait bientôt te contacter. Reste ouvert à cela, '
          'car la tasse ment rarement sur les affaires du cœur.',
      'es':
          'Los posos se asientan como susurros de las viejas montañas. '
          'Un camino se abre ante ti — inesperado, pero bienvenido. '
          'Alguien de tu pasado podría contactarte pronto. Mantente abierto a ello, '
          'porque la taza rara vez miente sobre asuntos del corazón.',
    },
    Storyteller.turkish: {
      'en':
          'The shapes in your cup speak of a journey yet to begin. '
          'A bird near the rim suggests good news traveling toward you. '
          'Patience will be rewarded before the next full moon. '
          'Trust what your instincts have been telling you.',
      'bg':
          'Формите в чашата ти говорят за пътуване, което тепърва предстои. '
          'Птица близо до ръба подсказва добри новини по пътя към теб. '
          'Търпението ще бъде възнаградено преди следващото пълнолуние. '
          'Довери се на инстинктите си.',
      'tr':
          'Fincanındaki şekiller henüz başlamamış bir yolculuktan bahsediyor. '
          'Kenara yakın bir kuş, sana doğru gelen iyi haberlere işaret ediyor. '
          'Bir sonraki dolunaydan önce sabrın ödüllendirilecek. '
          'İçgüdülerinin sana söylediklerine güven.',
      'de':
          'Die Formen in deiner Tasse sprechen von einer noch bevorstehenden Reise. '
          'Ein Vogel nahe dem Rand deutet auf gute Nachrichten hin, die zu dir unterwegs sind. '
          'Geduld wird vor dem nächsten Vollmond belohnt. '
          'Vertraue dem, was dein Instinkt dir sagt.',
      'fr':
          "Les formes dans ta tasse parlent d'un voyage qui n'a pas encore commencé. "
          'Un oiseau près du bord suggère de bonnes nouvelles en chemin vers toi. '
          'La patience sera récompensée avant la prochaine pleine lune. '
          'Fais confiance à ce que ton instinct te dit.',
      'es':
          'Las formas en tu taza hablan de un viaje aún por comenzar. '
          'Un pájaro cerca del borde sugiere buenas noticias en camino hacia ti. '
          'La paciencia será recompensada antes de la próxima luna llena. '
          'Confía en lo que tu instinto te ha estado diciendo.',
    },
  };

  @override
  Future<ReadingResult> generateReading({
    required String imagePath,
    required Storyteller storyteller,
    required AppLanguage language,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final stories = _mockStories[storyteller];
    final story = stories?[language.code] ??
        stories?['en'] ??
        'The cup remains silent for now.';

    return ReadingResult(
      storyteller: storyteller,
      story: story,
    );
  }
}
