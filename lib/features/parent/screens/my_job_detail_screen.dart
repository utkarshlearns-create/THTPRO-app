import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/detail_row.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/subject_glyph.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';
import 'package:tht_app/features/parent/widgets/attendance_card.dart';
import 'package:tht_app/features/parent/widgets/demo_review_sheet.dart';
import 'package:tht_app/features/parent/widgets/rate_tutor_sheet.dart';
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

    final job = ref.watch(myJobProvider(jobId)).valueOrNull;

    // Every action in the menu is PARENT-only server-side.
    final isParent = ref.watch(authProvider).role == UserRole.parent;

    // Nothing to close once it is already closed or cancelled.
    final canClose = isParent &&
        job != null &&
        !const {'CLOSED', 'CANCELLED'}.contains(job.status.toUpperCase());

    // Reassignment is refused unless a teacher is actually on the job.
    final canReassign = isParent &&
        job != null &&
        const {'ASSIGNED', 'TUTOR_SELECTED'}.contains(job.status.toUpperCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your requirement'),
        actions: [
          if (isParent)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) => switch (value) {
                'close' => _closeRequirement(context, ref),
                'reassign' => _requestReassignment(context, ref),
                _ => null,
              },
              itemBuilder: (_) => [
                // Only while a teacher is actually on the job — the server
                // refuses reassignment on anything else.
                if (canReassign)
                  const PopupMenuItem(
                    value: 'reassign',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.swap_horiz_rounded),
                      title: Text('Ask for a different teacher'),
                    ),
                  ),
                if (canClose)
                  const PopupMenuItem(
                    value: 'close',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Close this requirement'),
                    ),
                  ),
              ],
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
            ref
              ..invalidate(applicantsProvider(jobId))
              ..invalidate(myJobsProvider);
            await ref.read(applicantsProvider(jobId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              // What they posted, on their own screen. This used to live behind
              // an info button that pushed the teacher-facing job page, where a
              // parent was told to spend a credit to unlock their own contact.
              if (job != null) ...[
                _RequirementCard(job: job),
                const SizedBox(height: AppSpacing.xl),
              ],
              // Only once there is a teacher to keep a record of, and only for
              // the parent — marking is PARENT-only server-side.
              ..._attendance(context, ref, list),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No teachers yet',
                  message: 'We are showing your requirement to matching '
                      'teachers in your area. You will be notified as soon '
                      'as someone is interested.',
                  compact: true,
                )
              else ...[
                SectionHeader(
                  isParent ? 'Interested teachers' : 'Applicants',
                  icon: Icons.people_alt_outlined,
                  iconTone: Tone.success,
                  subtitle: '${Fmt.plural(list.length, 'teacher')} '
                      'want${list.length == 1 ? 's' : ''} this tuition',
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _ApplicantCard(jobId: jobId, application: list[i]),
                ],
              ],
              // Institutes monitor this list; their THT relationship manager
              // runs the demos and the hiring. Saying so once, at the bottom,
              // explains the absence of every button above it.
              if (!isParent && list.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const NoteBox(
                  tone: Tone.info,
                  message: 'Demos and hiring are managed by your THT '
                      'relationship manager — they will confirm each step '
                      'with you.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The attendance card, when there is a hired teacher to keep a record of.
  ///
  /// Empty for an institute: `TutorAttendanceView.perform_create` refuses
  /// anyone whose role is not PARENT, so offering the buttons would be offering
  /// a 403.
  List<Widget> _attendance(
    BuildContext context,
    WidgetRef ref,
    List<Application> applicants,
  ) {
    if (ref.watch(authProvider).role != UserRole.parent) return const [];

    for (final a in applicants) {
      final tutor = a.tutor;
      if (a.isHired && tutor != null) {
        return [
          AttendanceCard(
            jobId: jobId,
            tutorProfileId: tutor.id,
            tutorName: a.tutorName.trim().isNotEmpty ? a.tutorName : tutor.name,
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      }
    }
    return const [];
  }

  /// Asks our team to swap the teacher on a running tuition.
  ///
  /// The reason is mandatory server-side, so the dialog will not submit
  /// without one — a blank comes back as a 400 that reads like a bug.
  Future<void> _requestReassignment(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ask for a different teacher?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Our team will look for a replacement and contact you. Tell '
                'us what went wrong so we match you better this time.',
                style: TextStyle(fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What did not work?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Request'),
            ),
          ],
        ),
      );
      if (reason == null || !context.mounted) return;

      await ref
          .read(jobsRepositoryProvider)
          .requestReassignment(jobId, reason: reason);
      ref
        ..invalidate(myJobsProvider)
        ..invalidate(myJobProvider(jobId));
      if (context.mounted) {
        context.showMessage(
          'Requested. Our team will find you another teacher.',
        );
      }
    } catch (e) {
      if (context.mounted) context.showFailure(e);
    } finally {
      controller.dispose();
    }
  }

  /// Takes the requirement out of the feed for good.
  ///
  /// Irreversible from the app — nothing here reopens a closed requirement —
  /// so it asks first and says plainly what it costs.
  Future<void> _closeRequirement(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close this requirement?'),
        content: const Text(
          'Teachers will stop seeing it and no one new can apply. You cannot '
          'reopen it here — you would need to post it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it open'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Close it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(jobsRepositoryProvider).closeJob(jobId);
      ref
        ..invalidate(myJobsProvider)
        ..invalidate(myJobProvider(jobId))
        ..invalidate(parentStatsProvider);
      if (context.mounted) {
        context.showMessage('Requirement closed.');
      }
    } catch (e) {
      if (context.mounted) context.showFailure(e);
    }
  }
}

// ── The requirement ──────────────────────────────────────────────────────────

/// Everything the parent asked for, as they wrote it.
class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final title = job.subjects.isEmpty
        ? 'Tuition requirement'
        : job.subjects.map((s) => '${SubjectGlyph.of(s)} $s').join(', ');

    final schedule = [
      if (job.preferredTime.trim().isNotEmpty) job.preferredTime.trim(),
      if (job.daysPerWeek.trim().isNotEmpty) job.daysPerWeek.trim(),
    ].join(' · ');

    return Column(
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
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (job.classGrade.isNotEmpty) job.classGrade,
                      if (job.board.isNotEmpty) job.board,
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (job.status.trim().isNotEmpty) Pill.status(job.status),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              DetailRow(
                label: 'Fee offered',
                value: job.feeLabel ?? 'Not set',
              ),
              const Divider(height: 1),
              DetailRow(
                label: 'Area',
                value: job.locality.trim().isEmpty
                    ? 'Not set'
                    : job.locality.trim(),
              ),
              if (job.detailedAddress.trim().isNotEmpty) ...[
                const Divider(height: 1),
                DetailRow(label: 'Address', value: job.detailedAddress.trim()),
              ],
              if (schedule.isNotEmpty) ...[
                const Divider(height: 1),
                DetailRow(label: 'When', value: schedule),
              ],
              const Divider(height: 1),
              DetailRow(
                label: 'Mode',
                value: job.modeLabel.isEmpty ? 'Not set' : job.modeLabel,
              ),
              if (job.tutorGenderPreference.trim().isNotEmpty &&
                  job.tutorGenderPreference.toLowerCase() != 'any') ...[
                const Divider(height: 1),
                DetailRow(
                  label: 'Teacher preference',
                  value: job.tutorGenderPreference,
                ),
              ],
              if (job.postedAt != null) ...[
                const Divider(height: 1),
                DetailRow(
                  label: 'Posted',
                  value: Fmt.relative(job.postedAt),
                ),
              ],
            ],
          ),
        ),
        if (job.allStudents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.base),
          THTCard(
            child: Row(
              children: [
                Icon(
                  job.isMultiChild
                      ? Icons.groups_rounded
                      : Icons.person_outline_rounded,
                  size: 19,
                  color: Tone.info.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.isMultiChild ? 'Students' : 'Student',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.allStudents.map(Fmt.titleCase).join(', '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (job.requirements.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.base),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you asked for',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 4),
                Text(
                  job.requirements.trim(),
                  style: const TextStyle(fontSize: 13.5, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ],
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

  /// What the parent can do about this teacher *right now*.
  ///
  /// The server runs a strict sequence — shortlist for a demo, agree the slot
  /// our team books, then approve with a review — and refuses anything out of
  /// order. This mirrors it rather than offering one button that mostly fails:
  /// the old single "Choose this teacher" called the approve endpoint, which
  /// rejects every application whose demo is not yet `COMPLETED`, and rejects
  /// it again for arriving without the mandatory review body.
  Widget _actions(Application a) {
    final name = _name;

    // Everything below acts on the parent's behalf and is PARENT-only
    // server-side. An institute reads the same list on the same screen, so it
    // gets the informational half and none of the buttons that would 403.
    if (!_canAct) {
      return _ghostRow(a, primaryLabel: null);
    }

    // Once hired, the useful action is contacting them, not choosing again.
    if (a.isHired) {
      final phone = a.tutorPhone;
      return Column(
        children: [
          Row(
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
          ),
          if (a.tutor != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _working ? null : _message,
                icon: const Icon(Icons.forum_outlined, size: 17),
                label: const Text('Message'),
              ),
            ),
          ],
          // Only once there is something to review. Asking a parent to rate a
          // teacher on their first day is asking them to guess.
          if (a.tutor != null && (a.isRunning || a.isCompleted)) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _working ? null : _rate,
                icon: const Icon(Icons.star_outline_rounded, size: 17),
                label: const Text('Rate this teacher'),
              ),
            ),
          ],
        ],
      );
    }

    if (a.isClosed) return _ghostRow(a, primaryLabel: null);

    // The demo has been taken — this is the only point the server accepts an
    // approval, and only with a review attached.
    if (a.isDemoDone) {
      return _actionRow(
        // No name in the label: the card already carries it two rows up, and
        // "Approve Kanishka Vishwakarma" truncated to "Approve Ka…" at larger
        // text sizes.
        primary: 'Approve this teacher',
        onPrimary: _approve,
        secondary: 'Change teacher',
        onSecondary: () => _rejectDemo(name),
      );
    }

    // Our team has put a time on the calendar; the parent agrees to it or asks
    // for someone else.
    if (a.isDemoAwaitingParent) {
      return _actionRow(
        primary: 'Accept this time',
        onPrimary: _acceptDemoSlot,
        secondary: 'Change teacher',
        onSecondary: () => _rejectDemo(name),
      );
    }

    // Shortlisted and booked, or shortlisted and waiting on us to schedule —
    // either way the next move is not the parent's.
    if (a.isDemoBooked || a.isShortlisted) {
      return _ghostRow(
        a,
        primaryLabel: a.isDemoBooked ? 'Demo booked' : 'We are scheduling',
      );
    }

    // Fresh application: shortlist them for a demo, or decline.
    return _actionRow(
      primary: 'Accept for demo',
      onPrimary: _acceptForDemo,
      secondary: 'Decline',
      onSecondary: () => _reject(name),
    );
  }

  /// A primary/secondary pair, with the spinner on whichever is running.
  ///
  /// Stacked rather than side by side: these labels are whole phrases, and
  /// half a 360dp row could not hold one. At 1.3× text scale the pair rendered
  /// as "Approve Ka…" beside "Change te…" — two buttons that say nothing.
  Widget _actionRow({
    required String primary,
    required Future<void> Function() onPrimary,
    required String secondary,
    required Future<void> Function() onSecondary,
  }) =>
      Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _working ? null : () => onPrimary(),
              child: _working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primary, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _working ? null : () => onSecondary(),
              child: Text(secondary, textAlign: TextAlign.center),
            ),
          ),
        ],
      );

  /// No decision to make here — a disabled note of where things stand, and the
  /// profile link, which is always useful.
  Widget _ghostRow(Application a, {required String? primaryLabel}) {
    final profile = OutlinedButton(
      onPressed:
          a.tutor == null ? null : () => context.push('/tutors/${a.tutor!.id}'),
      child: const Text('View profile'),
    );
    if (primaryLabel == null) return SizedBox(width: double.infinity, child: profile);

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: null,
            child: Text(
              primaryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: profile),
      ],
    );
  }

  String get _name {
    final a = widget.application;
    return Fmt.titleCase(
      a.tutorName.trim().isNotEmpty
          ? a.tutorName
          : (a.tutor?.name ?? 'this teacher'),
    );
  }

  /// Only a parent may act. The applicants endpoint is owner-scoped, so an
  /// institute reaches this screen legitimately — but every action view checks
  /// `role == PARENT` and answers 403.
  bool get _canAct => ref.read(authProvider).role == UserRole.parent;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _acceptForDemo() => _run(
        () => ref
            .read(jobsRepositoryProvider)
            .applicationAction(widget.application.id, 'ACCEPT_DEMO'),
        success: '$_name has been shortlisted. We will arrange a demo and '
            'confirm the timing with you.',
      );

  Future<void> _acceptDemoSlot() => _run(
        () => ref
            .read(jobsRepositoryProvider)
            .demoAction(widget.application.id, 'ACCEPT'),
        success: 'Demo confirmed. We have let $_name know.',
      );

  Future<void> _reject(String name) async {
    final ok = await _ask(
      title: 'Decline $name?',
      body: 'They will be told they were not selected for this requirement. '
          'Other teachers can still apply.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (ok != true) return;

    await _run(
      () => ref
          .read(jobsRepositoryProvider)
          .applicationAction(widget.application.id, 'REJECT'),
      success: '$name has been declined.',
    );
  }

  /// Rejecting a *demo* is the "change teacher" path: it reopens the
  /// requirement and raises a reassignment request with our team, so the reason
  /// matters and is worth asking for.
  Future<void> _rejectDemo(String name) async {
    final reason = await _askReason(
      title: 'Ask for a different teacher?',
      body: 'We will reopen your requirement and find someone else. Telling us '
          'what did not fit helps us match better next time.',
      hint: 'What did not work? (optional)',
      confirmLabel: 'Change teacher',
    );
    if (reason == null) return;

    await _run(
      () => ref.read(jobsRepositoryProvider).demoAction(
            widget.application.id,
            'REJECT',
            remarks: reason,
          ),
      success: 'Noted. We are looking for another teacher for you.',
    );
  }

  /// Opens the thread with this teacher, creating it if there is none.
  ///
  /// Starting a conversation is parent-only server-side — the view takes the
  /// parent from the caller — which is why this sits on the parent's screen and
  /// the teacher only ever replies.
  Future<void> _message() async {
    final tutor = widget.application.tutor;
    if (tutor == null) return;

    setState(() => _working = true);
    try {
      final convo = await ref.read(messagesRepositoryProvider).start(
            tutorProfileId: tutor.id,
            jobId: widget.jobId,
          );
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      context.push('/messages/${convo.id}');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _rate() async {
    final tutor = widget.application.tutor;
    if (tutor == null) return;

    final result = await RateTutorSheet.show(context, tutorName: _name);
    if (result == null) return;

    await _run(
      () => ref.read(jobsRepositoryProvider).rateTutor(
            // The rating table keys on the TutorProfile, which is what the
            // applicant payload's `tutor_details.id` is.
            tutorProfileId: tutor.id,
            jobId: widget.jobId,
            rating: result.rating,
            review: result.review,
          ),
      success: "Thank you — your rating is on $_name's profile.",
    );
  }

  Future<void> _approve() async {
    final review = await DemoReviewSheet.show(context, tutorName: _name);
    if (review == null) return;

    await _run(
      () => ref
          .read(jobsRepositoryProvider)
          .confirmTutor(widget.application.id, review: review),
      success: 'Thank you. Your review is with the counsellor, who will '
          'confirm the fee and schedule with you.',
    );
  }

  /// Runs one action, refreshes everything it could have changed, and reports.
  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (!mounted) return;
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      ref
        ..invalidate(applicantsProvider(widget.jobId))
        ..invalidate(myJobsProvider)
        ..invalidate(parentStatsProvider);
      context.showMessage(success);
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _ask({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

  /// Returns the reason typed (possibly empty), or null if they backed out —
  /// so an empty box still counts as going ahead.
  Future<String?> _askReason({
    required String title,
    required String body,
    required String hint,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body, style: const TextStyle(fontSize: 13.5, height: 1.5)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: hint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
