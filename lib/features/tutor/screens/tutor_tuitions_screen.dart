import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/tuition_record.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Every tuition this teacher holds or has held.
///
/// The Tuitions tab shows *today*; this is the whole book, including finished
/// ones. The `past` list was being fetched and discarded, so a teacher had no
/// record of work they had completed — or of money still owed on it.
class TutorTuitionsScreen extends ConsumerStatefulWidget {
  const TutorTuitionsScreen({super.key});

  @override
  ConsumerState<TutorTuitionsScreen> createState() =>
      _TutorTuitionsScreenState();
}

class _TutorTuitionsScreenState extends ConsumerState<TutorTuitionsScreen> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final tuitions = ref.watch(myTuitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All tuitions')),
      body: AsyncView<({List<TuitionRecord> active, List<TuitionRecord> past})>(
        value: tuitions,
        onRetry: () => ref.invalidate(myTuitionsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 130),
        ),
        data: (data) {
          final shown = _showPast ? data.past : data.active;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myTuitionsProvider);
              await ref.read(myTuitionsProvider.future);
            },
            child: Column(
              children: [
                _Segments(
                  activeCount: data.active.length,
                  pastCount: data.past.length,
                  showPast: _showPast,
                  onChanged: (v) => setState(() => _showPast = v),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            EmptyState(
                              icon: _showPast
                                  ? Icons.history_rounded
                                  : Icons.school_outlined,
                              title: _showPast
                                  ? 'Nothing finished yet'
                                  : 'No tuitions running',
                              message: _showPast
                                  ? 'Completed tuitions move here, with what '
                                      'you earned from each.'
                                  : 'Once a family hires you, the tuition '
                                      'appears here.',
                              compact: true,
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
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) =>
                              _TuitionCard(tuition: shown[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.activeCount,
    required this.pastCount,
    required this.showPast,
    required this.onChanged,
  });

  final int activeCount;
  final int pastCount;
  final bool showPast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text('Running · $activeCount')),
            ButtonSegment(value: true, label: Text('Finished · $pastCount')),
          ],
          selected: {showPast},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      );
}

class _TuitionCard extends StatelessWidget {
  const _TuitionCard({required this.tuition});

  final TuitionRecord tuition;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final t = tuition;

    return THTCard(
      onTap: () => context.push('/jobs/${t.jobId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName.trim().isEmpty
                          ? 'Student'
                          : Fmt.titleCase(t.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (t.summaryLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.summaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(
                t.isRunning ? 'Running' : Fmt.status(t.completionStatus),
                tone: t.isRunning ? Tone.success : Tone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (t.slot.isNotEmpty)
                Pill(t.slot, icon: Icons.schedule_rounded, dense: true),
              if (t.locality.isNotEmpty)
                Pill(t.locality, icon: Icons.location_on_outlined, dense: true),
              if (t.startDate != null)
                Pill(
                  'Since ${Fmt.date(t.startDate)}',
                  icon: Icons.event_outlined,
                  dense: true,
                ),
            ],
          ),
          if (t.earning != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 15, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your share',
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ),
                Text(
                  Fmt.rupees(t.earning),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Two different events: the family paying THT, and THT paying
                // the teacher. Only the second one is money in their hand.
                Pill(
                  t.tutorPaid ? 'Paid out' : Fmt.status(t.paymentStatus),
                  tone: t.tutorPaid ? Tone.success : Tone.warning,
                  dense: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
