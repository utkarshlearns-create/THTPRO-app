import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/utils/json_x.dart';

/// The platform's reference lists: subjects, boards, classes, locations.
///
/// One fetch of `/api/jobs/master/` shared by everything that needs to offer a
/// controlled vocabulary — the teacher's subject picker and the job filters
/// alike. Typing a subject freehand is how a profile stops matching anything,
/// so these lists are what the UI offers.
class MasterData {
  const MasterData({
    this.subjects = const [],
    this.boards = const [],
    this.classes = const [],
  });

  final List<String> subjects;

  /// Short names — `CBSE`, `ICSE` — which is what jobs are stored against.
  final List<String> boards;

  final List<String> classes;

  bool get isEmpty => subjects.isEmpty && boards.isEmpty && classes.isEmpty;

  factory MasterData.fromJson(Map<String, dynamic> json) => MasterData(
        subjects: _names(json['subjects']),
        // Jobs record the board's short name, so a filter built from full
        // names would match nothing.
        boards: _names(json['boards'], preferKey: 'short_name'),
        classes: _names(json['class_levels']),
      );

  /// Pulls display strings out of a list of master rows, which arrive as
  /// `{id, name, short_name}` objects rather than plain strings.
  static List<String> _names(Object? raw, {String? preferKey}) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final row in raw) {
      String? value;
      if (row is String) {
        value = row.trim();
      } else if (row is Map) {
        final map = row.cast<String, dynamic>();
        if (preferKey != null) {
          final preferred = asString(map, preferKey).trim();
          if (preferred.isNotEmpty) value = preferred;
        }
        value ??= asString(map, 'name').trim();
      }
      if (value != null && value.isNotEmpty && !out.contains(value)) {
        out.add(value);
      }
    }
    return out;
  }
}

/// Cached for the session rather than `autoDispose`: this is fixed reference
/// data, and re-fetching it every time a sheet opens is a visible stall on a
/// picker the teacher is already looking at.
final masterDataProvider = FutureProvider<MasterData>((ref) async {
  final raw = await ref.watch(jobsRepositoryProvider).masterData();
  return MasterData.fromJson(raw);
});
