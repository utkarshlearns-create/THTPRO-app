import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// How a parent narrows the teacher list.
class TutorFilters {
  const TutorFilters({
    this.query = '',
    this.subject,
    this.classGrade,
    this.state,
    this.city,
    this.locality,
    this.mode,
    this.verifiedOnly = false,
  });

  final String query;
  final String? subject;
  final String? classGrade;

  /// Narrows the city list, and is a filter in its own right — the search
  /// endpoint has always accepted it and the app never sent one.
  final String? state;

  final String? city;
  final String? locality;
  final String? mode;

  /// Only teachers whose ID has been checked by the THT team.
  final bool verifiedOnly;

  int get activeCount =>
      [subject, classGrade, state, city, locality, mode]
          .where((f) => f != null && f.isNotEmpty)
          .length +
      (verifiedOnly ? 1 : 0);

  bool get isEmpty => activeCount == 0 && query.trim().isEmpty;

  TutorFilters copyWith({
    String? query,
    String? Function()? subject,
    String? Function()? classGrade,
    String? Function()? state,
    String? Function()? city,
    String? Function()? locality,
    String? Function()? mode,
    bool? verifiedOnly,
  }) =>
      TutorFilters(
        query: query ?? this.query,
        subject: subject == null ? this.subject : subject(),
        classGrade: classGrade == null ? this.classGrade : classGrade(),
        state: state == null ? this.state : state(),
        city: city == null ? this.city : city(),
        locality: locality == null ? this.locality : locality(),
        mode: mode == null ? this.mode : mode(),
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      );

  Map<String, dynamic> toQuery() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (subject != null && subject!.isNotEmpty) 'subject': subject,
        if (classGrade != null && classGrade!.isNotEmpty) 'class': classGrade,
        if (state != null && state!.isNotEmpty) 'state': state,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (locality != null && locality!.isNotEmpty) 'locality': locality,
        if (mode != null && mode!.isNotEmpty) 'mode': mode,
      };
}

class TutorFeedState {
  const TutorFeedState({
    this.tutors = const [],
    this.filters = const TutorFilters(),
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.failure,
  });

  final List<PublicTutor> tutors;
  final TutorFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final ApiFailure? failure;

  /// After the client-side filter the API has no parameter for.
  List<PublicTutor> get visible => filters.verifiedOnly
      ? tutors.where((t) => t.isKycVerified).toList()
      : tutors;

  TutorFeedState copyWith({
    List<PublicTutor>? tutors,
    TutorFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    ApiFailure? failure,
    bool clearFailure = false,
  }) =>
      TutorFeedState(
        tutors: tutors ?? this.tutors,
        filters: filters ?? this.filters,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        totalCount: totalCount ?? this.totalCount,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class TutorFeedNotifier extends StateNotifier<TutorFeedState> {
  TutorFeedNotifier(this._repo) : super(const TutorFeedState()) {
    _load(page: 1);
  }

  final UsersRepository _repo;

  Timer? _debounce;
  CancelToken? _cancelToken;
  int _page = 1;

  void search(String query) {
    state = state.copyWith(filters: state.filters.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  void applyFilters(TutorFilters filters) {
    state = state.copyWith(filters: filters);
    _load(page: 1);
  }

  void clearFilters() {
    state = state.copyWith(filters: TutorFilters(query: state.filters.query));
    _load(page: 1);
  }

  Future<void> refresh() => _load(page: 1);

  void loadMore() {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    _load(page: _page + 1);
  }

  /// Replaces one teacher in place after a favourite toggle or an unlock, so the
  /// list reflects the change without refetching the whole page.
  void replace(PublicTutor updated) {
    state = state.copyWith(
      tutors: [
        for (final t in state.tutors) if (t.id == updated.id) updated else t,
      ],
    );
  }

  Future<void> _load({required int page}) async {
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    final token = _cancelToken;

    final appending = page > 1;
    state = state.copyWith(
      isLoading: !appending,
      isLoadingMore: appending,
      clearFailure: true,
    );

    try {
      final result = await _repo.searchTutors(
        filters: state.filters.toQuery(),
        page: page,
        cancelToken: token,
      );
      if (!mounted || token!.isCancelled) return;

      _page = page;
      final combined =
          appending ? [...state.tutors, ...result.items] : result.items;
      state = state.copyWith(
        tutors: combined,
        totalCount: result.totalCount,
        hasMore: result.hasNext ||
            (result.totalCount > 0 && combined.length < result.totalCount),
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      // A cancelled request was replaced by a newer one; its error belongs to a
      // query the user has already moved past.
      if (failure.message == 'Request cancelled.') return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        failure: failure,
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final tutorFeedProvider =
    StateNotifierProvider.autoDispose<TutorFeedNotifier, TutorFeedState>(
  (ref) => TutorFeedNotifier(ref.watch(usersRepositoryProvider)),
);

/// One teacher's full profile, for the detail screen.
final tutorProvider = FutureProvider.autoDispose.family<PublicTutor, int>(
  (ref, tutorId) => ref.watch(usersRepositoryProvider).tutorDetail(tutorId),
);

/// Curated teachers for the parent home screen.
final featuredTutorsProvider = FutureProvider.autoDispose<List<PublicTutor>>(
  (ref) => ref.watch(usersRepositoryProvider).featuredTutors(),
);
