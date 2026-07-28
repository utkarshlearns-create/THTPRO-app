import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/paginated.dart';
import 'package:tht_app/core/models/unlock_status.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// The filters a teacher can narrow the feed by.
class JobFilters {
  const JobFilters({
    this.query = '',
    this.subject,
    this.grade,
    this.city,
    this.locality,
    this.mode,
    this.unappliedOnly = false,
  });

  final String query;
  final String? subject;
  final String? grade;
  final String? city;
  final String? locality;
  final String? mode;

  /// Hides leads this teacher has already applied to — the common case when
  /// coming back to the feed a second time.
  final bool unappliedOnly;

  /// How many filters are active, for the badge on the filter button.
  int get activeCount => [
        subject,
        grade,
        city,
        locality,
        mode,
      ].where((f) => f != null && f.isNotEmpty).length + (unappliedOnly ? 1 : 0);

  bool get isEmpty => activeCount == 0 && query.trim().isEmpty;

  JobFilters copyWith({
    String? query,
    String? Function()? subject,
    String? Function()? grade,
    String? Function()? city,
    String? Function()? locality,
    String? Function()? mode,
    bool? unappliedOnly,
  }) =>
      JobFilters(
        query: query ?? this.query,
        subject: subject == null ? this.subject : subject(),
        grade: grade == null ? this.grade : grade(),
        city: city == null ? this.city : city(),
        locality: locality == null ? this.locality : locality(),
        mode: mode == null ? this.mode : mode(),
        unappliedOnly: unappliedOnly ?? this.unappliedOnly,
      );

  /// Only non-empty values, so the API isn't handed blank filters.
  Map<String, dynamic> toQuery() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (subject != null && subject!.isNotEmpty) 'subject': subject,
        if (grade != null && grade!.isNotEmpty) 'grade': grade,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (locality != null && locality!.isNotEmpty) 'locality': locality,
        if (mode != null && mode!.isNotEmpty) 'mode': mode,
      };
}

/// The state of the job feed: the page loaded so far plus what's in flight.
class JobFeedState {
  const JobFeedState({
    this.jobs = const [],
    this.filters = const JobFilters(),
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.failure,
  });

  final List<Job> jobs;
  final JobFilters filters;

  /// First load, or reloading after a filter change.
  final bool isLoading;

  /// Appending the next page — the list stays on screen.
  final bool isLoadingMore;

  final bool hasMore;
  final int totalCount;
  final ApiFailure? failure;

  /// The list after client-side filters the API doesn't support.
  List<Job> get visible =>
      filters.unappliedOnly ? jobs.where((j) => !j.hasApplied).toList() : jobs;

  JobFeedState copyWith({
    List<Job>? jobs,
    JobFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    ApiFailure? failure,
    bool clearFailure = false,
  }) =>
      JobFeedState(
        jobs: jobs ?? this.jobs,
        filters: filters ?? this.filters,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        totalCount: totalCount ?? this.totalCount,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class JobFeedNotifier extends StateNotifier<JobFeedState> {
  JobFeedNotifier(this._repo) : super(const JobFeedState()) {
    _load(page: 1);
  }

  final JobsRepository _repo;

  Timer? _debounce;
  CancelToken? _cancelToken;
  int _page = 1;

  /// Typing in the search box. Debounced so a five-letter word is one request,
  /// not five.
  void search(String query) {
    state = state.copyWith(filters: state.filters.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  /// Applying filters from the sheet — no debounce, the user has committed.
  void applyFilters(JobFilters filters) {
    state = state.copyWith(filters: filters);
    _load(page: 1);
  }

  void clearFilters() {
    state = state.copyWith(filters: JobFilters(query: state.filters.query));
    _load(page: 1);
  }

  Future<void> refresh() => _load(page: 1);

  void loadMore() {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    _load(page: _page + 1);
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
      final result = await _repo.searchJobs(
        filters: state.filters.toQuery(),
        page: page,
        cancelToken: token,
      );
      if (!mounted || token!.isCancelled) return;

      _page = page;
      state = state.copyWith(
        jobs: appending ? [...state.jobs, ...result.items] : result.items,
        totalCount: result.totalCount,
        hasMore: _hasMore(result),
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      // A cancelled request was replaced by a newer one; showing its error
      // would flash a message for something the user already moved past.
      if (failure.message == 'Request cancelled.') return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        failure: failure,
      );
    }
  }

  /// `next` is authoritative when the endpoint paginates; when it returns a bare
  /// list there is nothing more to fetch.
  bool _hasMore(Paginated<Job> page) =>
      page.hasNext || (page.totalCount > 0 && state.jobs.length + page.items.length < page.totalCount);

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final jobFeedProvider =
    StateNotifierProvider.autoDispose<JobFeedNotifier, JobFeedState>(
  (ref) => JobFeedNotifier(ref.watch(jobsRepositoryProvider)),
);

/// One job on its own, for the detail screen.
final jobProvider = FutureProvider.autoDispose.family<Job, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).job(jobId),
);

/// Whether this teacher holds the parent's contact for a given job.
final unlockStatusProvider =
    FutureProvider.autoDispose.family<UnlockStatus, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).unlockStatus(jobId),
);
