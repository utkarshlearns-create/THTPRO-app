import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/explore/widgets/tutor_card.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';

/// The teacher directory an institute hires from.
///
/// Note this is every active teacher on the platform, not staff already
/// attached to the institute — the API has no concept of institute staff
/// outside THT Prep, so the screen does not pretend otherwise.
class InstitutionTeachersScreen extends ConsumerStatefulWidget {
  const InstitutionTeachersScreen({super.key});

  @override
  ConsumerState<InstitutionTeachersScreen> createState() =>
      _InstitutionTeachersScreenState();
}

class _InstitutionTeachersScreenState
    extends ConsumerState<InstitutionTeachersScreen> {
  final _searchField = TextEditingController();

  @override
  void dispose() {
    _searchField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutors = ref.watch(institutionTutorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Find teachers')),
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
              textInputAction: TextInputAction.search,
              // The endpoint filters on name and subject only, so the hint says
              // that rather than inviting a query it will silently ignore.
              decoration: InputDecoration(
                hintText: 'Name or subject',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchField.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchField.clear();
                          ref.read(teacherSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
              ),
              onSubmitted: (v) {
                ref.read(teacherSearchQueryProvider.notifier).state = v;
                setState(() {});
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: AsyncView<List<PublicTutor>>(
              value: tutors,
              onRetry: () => ref.invalidate(institutionTutorsProvider),
              loading: const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(count: 4, itemHeight: 120),
              ),
              data: (list) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(institutionTutorsProvider);
                  await ref.read(institutionTutorsProvider.future);
                },
                child: list.isEmpty
                    ? ListView(
                        children: const [
                          EmptyState(
                            icon: Icons.person_search_outlined,
                            title: 'No teachers found',
                            message: 'Try a different name or subject.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xxxl,
                        ),
                        itemCount: list.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Text(
                              Fmt.plural(list.length, 'teacher available'),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                            );
                          }
                          final tutor = list[i - 1];
                          return TutorCard(
                            tutor: tutor,
                            onTap: () => context.push('/tutors/${tutor.id}'),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
