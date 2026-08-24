/// The emoji a subject wears on a lead card.
///
/// A teacher scanning a feed recognises 🧪 faster than they read the word
/// "Chemistry", and the glyph survives the truncation that a long subject list
/// otherwise suffers.
///
/// Matching is by keyword against a lowercased subject name, most specific
/// first — "Social Science" and "Computer Science" both contain "science" and
/// would otherwise collapse onto the generic microscope.
abstract final class SubjectGlyph {
  static const String fallback = '📘';

  /// Ordered: the first entry whose keyword appears in the name wins.
  static const List<(List<String>, String)> _table = [
    (['social science', 'social studies', 'social'], '🌍'),
    (['computer science', 'computer', 'coding', 'programming', 'informatics'], '💻'),
    (['political science', 'political', 'civics'], '🏛️'),
    (['environmental', 'evs'], '🌱'),
    (['mathematics', 'maths', 'math', 'algebra', 'geometry', 'trigonometry', 'calculus'], '🔢'),
    (['physics'], '⚛️'),
    (['chemistry'], '🧪'),
    (['biology', 'botany', 'zoology'], '🧬'),
    (['science'], '🔬'),
    (['english'], '📖'),
    (['hindi'], '✍️'),
    (['sanskrit'], '🕉️'),
    (['urdu'], '🖋️'),
    (['french', 'german', 'spanish', 'language'], '🗣️'),
    (['history'], '📜'),
    (['geography'], '🗺️'),
    (['accountancy', 'accounts', 'accounting'], '📒'),
    (['economics', 'eco'], '📈'),
    (['business', 'commerce'], '💼'),
    (['reasoning', 'aptitude'], '🧩'),
    (['drawing', 'painting', 'art'], '🎨'),
    (['music', 'singing'], '🎵'),
    (['dance'], '💃'),
    (['sports', 'physical education'], '⚽'),
    (['general knowledge', 'gk'], '🧠'),
    (['neet', 'medical'], '🩺'),
    (['jee', 'iit'], '🎯'),
    (['spoken', 'communication'], '💬'),
  ];

  static String of(String subject) {
    final name = subject.toLowerCase().trim();
    if (name.isEmpty) return fallback;
    for (final (keywords, glyph) in _table) {
      for (final k in keywords) {
        if (name.contains(k)) return glyph;
      }
    }
    return fallback;
  }
}
