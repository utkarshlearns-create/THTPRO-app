import 'package:tht_app/core/network/api_config.dart';

/// One page of a DRF `PageNumberPagination` response.
///
/// Some endpoints on this backend are paginated and some return a bare list,
/// so [fromJson] accepts either and treats a bare list as a single full page.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.totalCount,
    required this.page,
    this.hasNext = false,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final bool hasNext;

  static Paginated<T> empty<T>() =>
      const Paginated(items: [], totalCount: 0, page: 1);

  int get totalPages => totalCount == 0
      ? 1
      : ((totalCount + ApiConfig.pageSize - 1) ~/ ApiConfig.pageSize);

  bool get isEmpty => items.isEmpty;

  /// Appends the next page to this one, for infinite-scroll lists.
  Paginated<T> merge(Paginated<T> next) => Paginated(
        items: [...items, ...next.items],
        totalCount: next.totalCount,
        page: next.page,
        hasNext: next.hasNext,
      );

  factory Paginated.fromJson(
    dynamic data,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
  }) {
    if (data is List) {
      final items = data
          .whereType<Map>()
          .map((e) => parse(e.cast<String, dynamic>()))
          .toList();
      return Paginated(items: items, totalCount: items.length, page: page);
    }

    if (data is Map) {
      final map = data.cast<String, dynamic>();
      final raw = map['results'];
      final items = (raw is List ? raw : const [])
          .whereType<Map>()
          .map((e) => parse(e.cast<String, dynamic>()))
          .toList();
      final count = map['count'];
      return Paginated(
        items: items,
        totalCount: count is num ? count.toInt() : items.length,
        page: page,
        hasNext: map['next'] != null,
      );
    }

    return Paginated(items: const [], totalCount: 0, page: page);
  }
}
