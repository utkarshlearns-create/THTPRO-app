import 'package:tht_app/core/utils/json_x.dart';

/// Why the server rates a teacher's chances on one lead.
///
/// Six weighted pillars, each with its own ceiling — subject match counts for
/// far more than salary fit. The weights come from the server, so a teacher is
/// shown what actually drove the number rather than an even split invented
/// here.
class ChanceDetail {
  const ChanceDetail({this.percentage, this.pillars = const []});

  /// The headline figure, 0–100. Null when the server has not scored this yet.
  final double? percentage;

  final List<ChancePillar> pillars;

  bool get hasBreakdown => pillars.isNotEmpty;

  /// The pillar costing the teacher the most, for a single line of advice.
  ///
  /// Measured by points *lost*, not by score: falling 4 short on a 10-point
  /// pillar matters more than falling 2 short on a 2-point one.
  ChancePillar? get weakest {
    if (pillars.isEmpty) return null;
    final sorted = [...pillars]..sort((a, b) => b.lost.compareTo(a.lost));
    return sorted.first.lost > 0 ? sorted.first : null;
  }

  factory ChanceDetail.fromJson(Map<String, dynamic> json) {
    final labels = asMapOrNull(json, 'compatibility_labels') ?? const {};
    return ChanceDetail(
      percentage: asDoubleOrNull(json, 'chance_percentage') ??
          asDoubleOrNull(json, 'percentage'),
      pillars: labels.entries
          .map((e) {
            final v = e.value;
            if (v is! Map) return null;
            return ChancePillar.fromJson(v.cast<String, dynamic>());
          })
          .whereType<ChancePillar>()
          .toList()
        // Heaviest pillar first: what matters most should read first.
        ..sort((a, b) => b.max.compareTo(a.max)),
    );
  }
}

class ChancePillar {
  const ChancePillar({this.label = '', this.score = 0, this.max = 0});

  final String label;
  final double score;
  final double max;

  /// Points not earned here.
  double get lost => (max - score).clamp(0, max);

  /// 0–1, for a bar. Guards the divide: a zero-weight pillar is complete, not
  /// a crash.
  double get fraction => max <= 0 ? 1 : (score / max).clamp(0, 1);

  bool get isFull => score >= max;

  factory ChancePillar.fromJson(Map<String, dynamic> json) => ChancePillar(
        label: asString(json, 'label'),
        score: asDouble(json, 'score'),
        max: asDouble(json, 'max'),
      );
}
