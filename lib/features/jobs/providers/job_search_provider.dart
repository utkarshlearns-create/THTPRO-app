import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/chance_detail.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/lead_purchase.dart';
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
    this.state,
    this.city,
    this.locality,
    this.mode,
    this.board,
    this.gender,
    this.unappliedOnly = false,
    this.buyableOnly = false,
  });

  final String query;
  final String? subject;
  final String? grade;

  /// Narrows the city dropdown only.
  ///
  /// Deliberately absent from [toQuery]: `/api/jobs/search/` accepts `city` and
  /// `locality` but has no `state` parameter, and sending one it ignores would
  /// look like a filter that quietly does nothing.
  final String? state;

  final String? city;
  final String? locality;
  final String? mode;

  /// A board's short name — `CBSE`, `ICSE` — which is how jobs store it.
  final String? board;

  /// The teacher's own gender, sent to hide leads asking for the other one.
  ///
  /// Not a gender *chooser*: the endpoint answers with jobs whose preference
  /// matches this value **or** is "Any", so it means "only what I can apply
  /// for". The sheet fills it from the profile rather than asking.
  final String? gender;

  /// Hides leads this teacher has already applied to — the common case when
  /// coming back to the feed a second time.
  final bool unappliedOnly;

  /// Shows only leads whose contact can be bought outright.
  ///
  /// Client-side, because `/api/jobs/search/` has no parameter for it — the
  /// server takes subject, grade, city, locality, mode, board and gender, and
  /// nothing about pay-per-lead. So this narrows what has already been
  /// fetched, and a page with no buyable leads on it looks empty until more
  /// are loaded. [JobFeedState.visible] is where it is applied.
  final bool buyableOnly;

  /// How many filters are active, for the badge on the filter button.
  int get activeCount =>
      [
        subject,
        grade,
        city,
        locality,
        mode,
        board,
        gender,
      ].where((f) => f != null && f.isNotEmpty).length +
      (unappliedOnly ? 1 : 0) +
      (buyableOnly ? 1 : 0);

  bool get isEmpty => activeCount == 0 && query.trim().isEmpty;

  JobFilters copyWith({
    String? query,
    String? Function()? subject,
    String? Function()? grade,
    String? Function()? state,
    String? Function()? city,
    String? Function()? locality,
    String? Function()? mode,
    String? Function()? board,
    String? Function()? gender,
    bool? unappliedOnly,
    bool? buyableOnly,
  }) =>
      JobFilters(
        query: query ?? this.query,
        subject: subject == null ? this.subject : subject(),
        grade: grade == null ? this.grade : grade(),
        state: state == null ? this.state : state(),
        city: city == null ? this.city : city(),
        locality: locality == null ? this.locality : locality(),
        mode: mode == null ? this.mode : mode(),
        board: board == null ? this.board : board(),
        gender: gender == null ? this.gender : gender(),
        unappliedOnly: unappliedOnly ?? this.unappliedOnly,
        buyableOnly: buyableOnly ?? this.buyableOnly,
      );

  /// Only non-empty values, so the API isn't handed blank filters.
  Map<String, dynamic> toQuery() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (subject != null && subject!.isNotEmpty) 'subject': subject,
        if (grade != null && grade!.isNotEmpty) 'grade': grade,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (locality != null && locality!.isNotEmpty) 'locality': locality,
        if (mode != null && mode!.isNotEmpty) 'mode': mode,
        if (board != null && board!.isNotEmpty) 'board': board,
        if (gender != null && gender!.isNotEmpty) 'gender': gender,
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
  List<Job> get visible {
    var out = jobs;
    if (filters.unappliedOnly) {
      out = out.where((j) => !j.hasApplied).toList();
    }
    if (filters.buyableOnly) {
      out = out.where((j) => j.isBuyable).toList();
    }
    return out;
  }

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
      page.hasNext ||
      (page.totalCount > 0 &&
          state.jobs.length + page.items.length < page.totalCount);

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

/// Who else has applied to a job this teacher is already in for.
///
/// Only meaningful once applied — the endpoint 403s otherwise — so the caller
/// gates on `hasApplied` rather than letting this surface an error.
final coApplicantsProvider =
    FutureProvider.autoDispose.family<CoApplicants, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).coApplicants(jobId),
);

/// Whether this teacher holds the parent's contact for a given job.
final unlockStatusProvider =
    FutureProvider.autoDispose.family<UnlockStatus, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).unlockStatus(jobId),
);

/// The teachers who already bought this lead.
///
/// Shown to someone deciding whether to buy: three people holding the number
/// is a materially different proposition from none.
final leadBuyersProvider = FutureProvider.autoDispose.family<LeadBuyers, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).leadBuyers(jobId),
);

/// The per-pillar breakdown behind a teacher's hiring chance on one lead.
///
/// Keyed by (job, tutor profile) because the server scopes it — a teacher may
/// ask about themselves, staff may ask about anyone.
final chanceDetailProvider =
    FutureProvider.autoDispose.family<ChanceDetail, (int, int)>(
  (ref, key) => ref.watch(jobsRepositoryProvider).chanceDetail(key.$1, key.$2),
);
