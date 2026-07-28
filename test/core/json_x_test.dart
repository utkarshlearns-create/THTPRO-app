import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/utils/json_x.dart';

/// These readers exist because the API is inconsistent about types. The point of
/// testing them is that a wrong value must degrade to a fallback rather than
/// throw — a screen should never die on a field that is merely unexpected.
void main() {
  group('asInt', () {
    test('reads ints, doubles and numeric strings', () {
      expect(asInt({'v': 7}, 'v'), 7);
      expect(asInt({'v': 7.6}, 'v'), 8);
      expect(asInt({'v': '7'}, 'v'), 7);
      expect(asInt({'v': '7.6'}, 'v'), 8);
    });

    test('falls back on null, missing and unparseable values', () {
      expect(asInt({'v': null}, 'v'), 0);
      expect(asInt({}, 'v'), 0);
      expect(asInt({'v': 'not a number'}, 'v', fallback: -1), -1);
    });
  });

  group('asDouble', () {
    test('reads the decimal strings DRF emits for DecimalField', () {
      expect(asDouble({'v': '1500.00'}, 'v'), 1500.0);
      expect(asDouble({'v': 1500}, 'v'), 1500.0);
    });

    test('asDoubleOrNull distinguishes absent from zero', () {
      expect(asDoubleOrNull({}, 'v'), isNull);
      expect(asDoubleOrNull({'v': 0}, 'v'), 0.0);
    });
  });

  group('asBool', () {
    test('accepts the several shapes the API uses for truth', () {
      for (final truthy in [true, 1, '1', 'true', 'True', 'yes']) {
        expect(asBool({'v': truthy}, 'v'), isTrue, reason: '$truthy');
      }
      for (final falsy in [false, 0, '0', 'false', 'no']) {
        expect(asBool({'v': falsy}, 'v'), isFalse, reason: '$falsy');
      }
    });

    test('keeps the caller fallback for values it cannot read', () {
      expect(asBool({'v': 'maybe'}, 'v', fallback: true), isTrue);
    });
  });

  group('asStringList', () {
    test('reads a proper JSON array', () {
      expect(asStringList({'v': ['Maths', 'Science']}, 'v'),
          ['Maths', 'Science']);
    });

    test('recovers a JSONField that was stored as text on older rows', () {
      expect(asStringList({'v': "['Maths', 'Science']"}, 'v'),
          ['Maths', 'Science']);
      expect(asStringList({'v': 'Maths, Science'}, 'v'), ['Maths', 'Science']);
    });

    test('treats empty and absent as an empty list, never null', () {
      expect(asStringList({'v': '[]'}, 'v'), isEmpty);
      expect(asStringList({'v': null}, 'v'), isEmpty);
      expect(asStringList({}, 'v'), isEmpty);
    });

    test('drops nulls inside the array rather than stringifying them', () {
      expect(asStringList({'v': ['Maths', null]}, 'v'), ['Maths']);
    });
  });

  group('asMapList', () {
    test('skips entries that are not objects', () {
      final rows = asMapList({
        'v': [
          {'name': 'Aarav'},
          'garbage',
          null,
        ]
      }, 'v');
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Aarav');
    });
  });

  group('asDateOrNull', () {
    test('reads ISO-8601 and plain dates', () {
      expect(asDateOrNull({'v': '2026-03-12'}, 'v'), isNotNull);
      expect(asDateOrNull({'v': '2026-03-12T10:30:00Z'}, 'v'), isNotNull);
    });

    test('returns null rather than throwing on junk', () {
      expect(asDateOrNull({'v': 'yesterday'}, 'v'), isNull);
      expect(asDateOrNull({}, 'v'), isNull);
    });
  });

  group('asStringOrNull', () {
    test('treats a blank string as absent', () {
      expect(asStringOrNull({'v': '   '}, 'v'), isNull);
      expect(asStringOrNull({'v': 'Lucknow'}, 'v'), 'Lucknow');
    });
  });
}
