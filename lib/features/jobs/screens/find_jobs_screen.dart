import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:tht_app/features/jobs/widgets/job_card.dart';
import 'package:tht_app/features/jobs/widgets/job_filter_sheet.dart';

/// The teacher's job feed — every open requirement they can apply to.
class FindJobsScreen extends ConsumerStatefulWidget {
  const FindJobsScreen({super.key});

  @override
  ConsumerState<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends ConsumerState<FindJobsScreen> {
  final _scroll = ScrollController();
  final _searchField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchField.dispose();
    super.dispose();
  }

  /// Fetch the next page a little before the list actually runs out, so the
  /// scroll doesn't stall on the last card.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 600) {
      ref.read(jobFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobFeedProvider);
    final notifier = ref.read(jobFeedProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobs = state.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find jobs'),
        actions: [
          _FilterButton(
            count: state.filters.activeCount,
            onPressed: () async {
              final result = await JobFilterSheet.show(context, state.filters);
              if (result != null) notifier.applyFilters(result);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchField,
              onChanged: (v) {
                notifier.search(v);
                setState(() {}); // reveal or hide the clear button
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Subject, class or locality',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchField.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchField.clear();
                          notifier.search('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          if (!state.isLoading && state.failure == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _resultLine(state, jobs.length),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                  ),
                  if (state.filters.activeCount > 0)
                    TextButton(
                      onPressed: notifier.clearFilters,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
          Expanded(child: _body(state, notifier, jobs)),
        ],
      ),
    );
  }

  String _resultLine(JobFeedState state, int shown) {
    if (shown == 0) return 'No jobs match';
    if (state.filters.unappliedOnly && shown < state.jobs.length) {
      return '$shown not yet applied to';
    }
    final total = state.totalCount;
    return total > shown
        ? 'Showing $shown of ${Fmt.number(total)} jobs'
        : Fmt.plural(shown, 'job');
  }

  Widget _body(JobFeedState state, JobFeedNotifier notifier, List<Job> jobs) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SkeletonList(count: 4, itemHeight: 120),
      );
    }

    if (state.failure != null && state.jobs.isEmpty) {
      return SingleChildScrollView(
        child: ErrorView(failure: state.failure!, onRetry: notifier.refresh),
      );
    }

    if (jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          children: [
            EmptyState(
              icon: Icons.work_off_outlined,
              title: state.filters.isEmpty
                  ? 'No open jobs right now'
                  : 'Nothing matches those filters',
              message: state.filters.isEmpty
                  ? 'New requirements are posted through the day. Pull down to '
                      'check again.'
                  : 'Try widening the subject or class, or clear the filters to '
                      'see everything open.',
              actionLabel: state.filters.isEmpty ? null : 'Clear filters',
              onAction: state.filters.isEmpty ? null : notifier.clearFilters,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        itemCount: jobs.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i >= jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final job = jobs[i];
          return JobCard(
            job: job,
            onTap: () => context.push('/jobs/${job.id}'),
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: count == 0 ? 'Filter jobs' : '$count filters active',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune_rounded),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
