import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/explore/providers/tutor_search_provider.dart';
import 'package:tht_app/features/explore/widgets/tutor_card.dart';
import 'package:tht_app/features/explore/widgets/tutor_filter_sheet.dart';

/// Find a teacher. Public — a parent can browse before signing in, and is only
/// asked to sign in when they try to unlock a contact.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
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

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 600) ref.read(tutorFeedProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorFeedProvider);
    final notifier = ref.read(tutorFeedProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tutors = state.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a teacher'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await TutorFilterSheet.show(context, state.filters);
              if (result != null) notifier.applyFilters(result);
            },
            tooltip: state.filters.activeCount == 0
                ? 'Filter teachers'
                : '${state.filters.activeCount} filters active',
            icon: Badge(
              isLabelVisible: state.filters.activeCount > 0,
              label: Text('${state.filters.activeCount}'),
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.tune_rounded),
            ),
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
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Subject, class or area',
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
                      tutors.isEmpty
                          ? 'No teachers match'
                          : state.totalCount > tutors.length
                              ? 'Showing ${tutors.length} of '
                                  '${Fmt.number(state.totalCount)} teachers'
                              : Fmt.plural(tutors.length, 'teacher'),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
          Expanded(child: _body(state, notifier, tutors)),
        ],
      ),
    );
  }

  Widget _body(
    TutorFeedState state,
    TutorFeedNotifier notifier,
    List<PublicTutor> tutors,
  ) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SkeletonList(count: 4, itemHeight: 120),
      );
    }

    if (state.failure != null && state.tutors.isEmpty) {
      return SingleChildScrollView(
        child: ErrorView(failure: state.failure!, onRetry: notifier.refresh),
      );
    }

    if (tutors.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          children: [
            EmptyState(
              icon: Icons.person_search_outlined,
              title: state.filters.isEmpty
                  ? 'No teachers listed yet'
                  : 'Nothing matches those filters',
              message: state.filters.isEmpty
                  ? 'Pull down to check again.'
                  : 'Try a wider subject or class, or clear the filters.',
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
        itemCount: tutors.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i >= tutors.length) {
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
          final tutor = tutors[i];
          return TutorCard(
            tutor: tutor,
            onTap: () => context.push('/tutors/${tutor.id}'),
            onToggleFavourite: () => _toggleFavourite(tutor, notifier),
          );
        },
      ),
    );
  }

  Future<void> _toggleFavourite(
    PublicTutor tutor,
    TutorFeedNotifier notifier,
  ) async {
    try {
      await ref.read(usersRepositoryProvider).toggleFavourite(tutor.id);
      if (!mounted) return;
      // Re-read the one row rather than the whole page, so the list does not
      // jump under the finger that just tapped.
      final updated = await ref.read(usersRepositoryProvider).tutorDetail(tutor.id);
      if (!mounted) return;
      notifier.replace(updated);
    } catch (e) {
      if (mounted) context.showFailure(e);
    }
  }
}
