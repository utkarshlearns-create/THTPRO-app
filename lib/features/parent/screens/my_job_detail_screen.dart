import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// One of the parent's requirements, and the teachers who want it.
///
/// The applicant list is the point of this screen — a parent comes here to
/// choose someone, so each card carries enough to judge them and the actions
/// sit on the card rather than behind a menu.
class MyJobDetailScreen extends ConsumerWidget {
  const MyJobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicants = ref.watch(applicantsProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your requirement'),
        actions: [
          IconButton(
            onPressed: () => context.push('/jobs/$jobId'),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Requirement details',
          ),
        ],
      ),
      body: AsyncView<List<Application>>(
        value: applicants,
        onRetry: () => ref.invalidate(applicantsProvider(jobId)),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 140),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(applicantsProvider(jobId));
            await ref.read(applicantsProvider(jobId).future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No teachers yet',
                      message: 'We are showing your requirement to matching '
                          'teachers in your area. You will be notified as soon '
                          'as someone is interested.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    SectionHeader(
                      'Interested teachers',
                      subtitle: '${Fmt.plural(list.length, 'teacher')} '
                          'want${list.length == 1 ? 's' : ''} this tuition',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _ApplicantCard(jobId: jobId, application: list[i]),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerStatefulWidget {
  const _ApplicantCard({required this.jobId, required this.application});

  final int jobId;
  final Application application;

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final tutor = a.tutor;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final name = a.tutorName.trim().isNotEmpty
        ? a.tutorName
        : (tutor?.name ?? 'Teacher');

    return THTCard(
      onTap: tutor == null ? null : () => context.push('/tutors/${tutor.id}'),
      borderColor: a.isHired ? Tone.success.border(brightness) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THTAvatar(
                name: name,
                imageUrl: tutor?.imageUrl,
                size: 46,
                verified: a.tutorApproved,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            Fmt.titleCase(name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.slate50
                                  : AppColors.slate900,
                            ),
                          ),
                        ),
                        if (a.tutorApproved) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Tone.info.foreground(brightness),
                          ),
                        ],
                      ],
                    ),
                    if (tutor != null && tutor.credentialLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        tutor.credentialLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(a.stageLabel, tone: toneForStatus(a.toneKey), dense: true),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (tutor != null && tutor.hasRatings)
                Pill(
                  '${tutor.avgRating!.toStringAsFixed(1)} '
                  '(${Fmt.plural(tutor.ratingCount, 'review')})',
                  tone: Tone.success,
                  icon: Icons.star_rounded,
                  dense: true,
                )
              else
                const Pill('No reviews yet', dense: true),
              if (tutor != null && tutor.ongoingTuitions > 0)
                Pill(
                  '${tutor.ongoingTuitions} running',
                  icon: Icons.school_outlined,
                  dense: true,
                ),
              if (a.createdAt != null)
                Pill(
                  'Applied ${Fmt.relative(a.createdAt).toLowerCase()}',
                  dense: true,
                ),
            ],
          ),

          if (a.coverMessage.trim().isNotEmpty &&
              !a.coverMessage.startsWith('Auto-applied')) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                a.coverMessage.trim(),
                style: const TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
          ],

          if (a.demoDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 15,
                  color: Tone.info.foreground(brightness),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Demo ${a.demoStatus.toUpperCase() == 'ACCEPTED' ? 'booked' : 'proposed'} '
                    'for ${Fmt.dateTime(a.demoDate)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Tone.info.foreground(brightness),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.base),
          _actions(a),
        ],
      ),
    );
  }

  Widget _actions(Application a) {
    // Once hired, the useful action is contacting them, not choosing again.
    if (a.isHired) {
      final phone = a.tutorPhone;
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: phone == null
                  ? null
                  : () => launchUrl(
                        Uri.parse('tel:$phone'),
                        mode: LaunchMode.externalApplication,
                      ),
              icon: const Icon(Icons.call_rounded, size: 17),
              label: Text(phone == null ? 'Number with our team' : 'Call'),
            ),
          ),
          if (a.tutor != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/tutors/${a.tutor!.id}'),
                child: const Text('View profile'),
              ),
            ),
          ],
        ],
      );
    }

    if (a.isClosed) {
      return OutlinedButton(
        onPressed:
            a.tutor == null ? null : () => context.push('/tutors/${a.tutor!.id}'),
        child: const Text('View profile'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _working ? null : _confirm,
            child: _working
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Choose this teacher'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: a.tutor == null
                ? null
                : () => context.push('/tutors/${a.tutor!.id}'),
            child: const Text('View profile'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    final a = widget.application;
    final name = Fmt.titleCase(
      a.tutorName.trim().isNotEmpty ? a.tutorName : (a.tutor?.name ?? 'this teacher'),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Go ahead with $name?'),
        content: const Text(
          'We will let them know and arrange the next step with you. You can '
          'still change your mind before the tuition starts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(jobsRepositoryProvider).confirmTutor(a.id);
      if (!mounted) return;
      ref.invalidate(applicantsProvider(widget.jobId));
      ref.invalidate(myJobsProvider);
      ref.invalidate(parentStatsProvider);
      context.showMessage('$name has been chosen. We will be in touch.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}
