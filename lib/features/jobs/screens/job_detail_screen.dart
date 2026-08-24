import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/unlock_status.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// One tuition requirement in full, and the decision a teacher makes about it.
///
/// The contact is the whole point of this screen, so the unlock card sits at the
/// top under the summary rather than buried at the bottom.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: AsyncView<Job>(
        value: job,
        onRetry: () => ref.invalidate(jobProvider(jobId)),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 140),
        ),
        data: (j) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jobProvider(jobId));
            ref.invalidate(unlockStatusProvider(jobId));
            await ref.read(jobProvider(jobId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _Summary(job: j),
              const SizedBox(height: AppSpacing.lg),
              _ApplyCard(jobId: jobId, job: j),
              const SizedBox(height: AppSpacing.md),
              _ContactCard(jobId: jobId, job: j),
              const SizedBox(height: AppSpacing.xl),
              _Requirement(job: j),
              if (j.allStudents.length > 1) ...[
                const SizedBox(height: AppSpacing.xl),
                _Students(job: j),
              ],
              if (j.requirements.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader('Notes from the family'),
                const SizedBox(height: AppSpacing.md),
                THTCard(
                  child: Text(
                    j.requirements.trim(),
                    style: const TextStyle(fontSize: 14, height: 1.55),
                  ),
                ),
              ],
              // Only once applied — the endpoint refuses anyone who hasn't, so
              // asking would surface a 403 as an error card.
              if (j.hasApplied) ...[
                const SizedBox(height: AppSpacing.xl),
                _CoApplicants(jobId: jobId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary ──────────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.subjects.isEmpty ? 'Tuition required' : Fmt.list(job.subjects, max: 4),
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: -0.4,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (job.classGrade.isNotEmpty) job.classGrade,
            if (job.board.isNotEmpty) job.board,
            job.modeLabel,
          ].where((s) => s.isNotEmpty).join(' · '),
          style: TextStyle(fontSize: 14, color: muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (job.isInstituteJob) const Pill('Institute lead', tone: Tone.accent),
            if (job.hasApplied)
              const Pill('Applied', tone: Tone.info, icon: Icons.check_rounded),
            Pill(
              job.applicationCount == 0
                  ? 'First applicant'
                  : Fmt.plural(job.applicationCount, 'applicant'),
              tone: job.applicationCount == 0 ? Tone.success : Tone.neutral,
            ),
            if (job.postedAt != null)
              Pill('Posted ${Fmt.relative(job.postedAt).toLowerCase()}'),
          ],
        ),
        if (job.genderMismatch) ...[
          const SizedBox(height: AppSpacing.base),
          _Notice(
            tone: Tone.warning,
            icon: Icons.info_outline_rounded,
            title: 'This family asked for a '
                '${job.tutorGenderPreference.toLowerCase()} teacher',
            message: 'Applications from other teachers are declined for '
                'gender-specific requirements, so this one is not open to you.',
          ),
        ],
      ],
    );
  }
}

// ── Co-applicants ────────────────────────────────────────────────────────────

/// Who else is in for this lead.
///
/// A teacher deciding whether to chase a family deserves to know they are one
/// of nine, or the only one. Contacts are never in this payload — it is
/// standing, not a directory.
class _CoApplicants extends ConsumerWidget {
  const _CoApplicants({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(coApplicantsProvider(jobId));

    return AsyncView<CoApplicants>(
      value: data,
      onRetry: () => ref.invalidate(coApplicantsProvider(jobId)),
      loading: const SkeletonList(count: 2, itemHeight: 70),
      compactError: true,
      data: (co) {
        final others = co.others;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              'Who else applied',
              icon: Icons.groups_outlined,
              iconTone: Tone.info,
              subtitle: _subtitle(co),
            ),
            const SizedBox(height: AppSpacing.md),
            if (co.hired != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NoteBox(
                  tone: co.hired!.isMe ? Tone.success : Tone.neutral,
                  title: co.hired!.isMe
                      ? 'You were hired for this'
                      : 'A teacher has been hired',
                  message: co.hired!.isMe
                      ? 'Nothing more to do here — the tuition is yours.'
                      : 'The family has chosen someone. This lead is closed.',
                ),
              ),
            if (others.isEmpty)
              const THTCard(
                child: Text(
                  'Nobody else has applied yet. You have this family to '
                  'yourself for now.',
                  style: TextStyle(fontSize: 13.5, height: 1.5),
                ),
              )
            else
              THTCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < others.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _CoApplicantRow(applicant: others[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String? _subtitle(CoApplicants co) {
    if (co.totalCount <= 1) return 'You are the only applicant so far';
    final rank = co.myRank;
    if (rank == null) return '${Fmt.plural(co.totalCount, 'teacher')} in total';
    // Application order, which is the only ordering the server gives — not a
    // ranking of who is likeliest to be picked.
    return 'You applied ${_ordinal(rank)} of ${co.totalCount}';
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

class _CoApplicantRow extends StatelessWidget {
  const _CoApplicantRow({required this.applicant});

  final CoApplicant applicant;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final a = applicant;

    final line = [
      if (a.experienceYears > 0) Fmt.plural(a.experienceYears, 'year'),
      if (a.subjects.isNotEmpty) a.subjects.take(2).join(', '),
      if (a.locality.isNotEmpty) a.locality,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          THTAvatar(name: a.name, imageUrl: a.imageUrl, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Fmt.titleCase(a.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.slate50 : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (a.isHired) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Pill('Hired', tone: Tone.success, dense: true),
                    ],
                  ],
                ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ],
            ),
          ),
          // A badge only when the teacher has actually earned one. A PENDING
          // pill next to a rated rival would read as a rating, not an absence.
          if (a.isRated) ...[
            const SizedBox(width: AppSpacing.sm),
            Pill(
              a.totalScore.toStringAsFixed(0),
              tone: a.totalScore >= 75
                  ? Tone.success
                  : a.totalScore >= 50
                      ? Tone.warning
                      : Tone.neutral,
              icon: Icons.workspace_premium_rounded,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Apply ────────────────────────────────────────────────────────────────────

/// Putting your name forward — a different decision from unlocking the contact.
///
/// The app had no apply action at all, so unlocking was the only way into a
/// job. That left two holes. A lead whose counsellor set `allow_contact=False`
/// answers 403 on unlock, making it unreachable; and the unlock view
/// deliberately bypasses the gender and active-tuition guards ("this is for
/// tracking, not a chosen application"), so neither rule was ever enforced in
/// the app. Applying runs both, and works on leads unlock cannot touch.
class _ApplyCard extends ConsumerStatefulWidget {
  const _ApplyCard({required this.jobId, required this.job});

  final int jobId;
  final Job job;

  @override
  ConsumerState<_ApplyCard> createState() => _ApplyCardState();
}

class _ApplyCardState extends ConsumerState<_ApplyCard> {
  bool _working = false;

  /// Whatever the server said no with, kept on the card rather than in a
  /// snackbar — "you have 3 active tuitions" is a paragraph a teacher needs to
  /// re-read, not a message that slides away.
  String? _refusal;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final brightness = Theme.of(context).brightness;

    // Already in. The applications screen is where the state lives from here.
    if (job.hasApplied) {
      return THTCard(
        borderColor: Tone.info.border(brightness),
        background: Tone.info.background(brightness),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: Tone.info.foreground(brightness),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'You have applied for this tuition.',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Tone.info.foreground(brightness),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/tutor-applications'),
              child: const Text('Track it'),
            ),
          ],
        ),
      );
    }

    // The server takes applications only while the lead is APPROVED. Once a
    // teacher has been selected, offering the button would be offering a 400.
    final status = job.status.toUpperCase();
    if (status.isNotEmpty && status != 'APPROVED') {
      return THTCard(
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                status == 'CLOSED' || status == 'CANCELLED'
                    ? 'This requirement has closed.'
                    : 'A teacher has already been selected for this tuition.',
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_reg_outlined, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Put your name forward',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Applying is free and costs no credit. The family sees you on '
            'their list of interested teachers, and our team may line up a '
            'demo. You do not see their number until you unlock it.',
            style: TextStyle(fontSize: 13.5, height: 1.55),
          ),
          if (_refusal != null) ...[
            const SizedBox(height: AppSpacing.base),
            NoteBox(message: _refusal!),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _working ? null : _apply,
              icon: _working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_working ? 'Applying…' : 'Apply for this tuition'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    setState(() {
      _working = true;
      _refusal = null;
    });

    try {
      final result =
          await ref.read(jobsRepositoryProvider).applyToJob(widget.jobId);
      if (!mounted) return;

      ref.invalidate(jobProvider(widget.jobId));
      ref.read(jobFeedProvider.notifier).refresh();

      context.showMessage(
        result['is_first_applicant'] == true
            ? 'Applied — and you are the first teacher here. '
                'That is a strong position.'
            : 'Applied. The family will see you on their list.',
      );

      // The server lets a teacher with no credits apply, then flags it: they
      // cannot be assigned the tuition until they hold one. Saying so now beats
      // letting them find out when the assignment does not come.
      if (result['low_credits'] == true && mounted) {
        await _offerCredits();
      }
    } catch (e) {
      if (!mounted) return;
      // The backend writes these refusals itself, and they are specific —
      // which gender it wants, how many tuitions you are already running.
      // Showing its words beats paraphrasing them.
      setState(() => _refusal = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _offerCredits() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('You have no credits'),
        content: const Text(
          'Your application is in. But a tuition can only be assigned to you '
          'once you hold at least one credit, so it is worth topping up '
          'before the family decides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('See plans'),
          ),
        ],
      ),
    );
    if (go == true && mounted) context.push('/packages');
  }
}

// ── Contact / unlock ─────────────────────────────────────────────────────────

class _ContactCard extends ConsumerStatefulWidget {
  const _ContactCard({required this.jobId, required this.job});

  final int jobId;
  final Job job;

  @override
  ConsumerState<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends ConsumerState<_ContactCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(unlockStatusProvider(widget.jobId));

    return AsyncView<UnlockStatus>(
      value: status,
      onRetry: () => ref.invalidate(unlockStatusProvider(widget.jobId)),
      loading: const SkeletonBox(height: 150, radius: AppRadius.lg),
      compactError: true,
      data: (s) => s.isUnlocked || widget.job.isContactUnlocked
          ? _unlocked(s)
          : _locked(s),
    );
  }

  // ── Unlocked: the contact, and the two ways to use it ──

  Widget _unlocked(UnlockStatus status) {
    final phone = widget.job.parentPhone;
    final whatsapp = status.whatsapp ?? widget.job.parentWhatsapp ?? phone;
    final brightness = Theme.of(context).brightness;

    return THTCard(
      borderColor: Tone.success.border(brightness),
      background: Tone.success.background(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 18,
                color: Tone.success.foreground(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Contact unlocked',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Tone.success.foreground(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.job.parentName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (phone != null) ...[
            const SizedBox(height: 2),
            Text(
              Fmt.phone(phone),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              if (phone != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _open('tel:$phone', 'phone app'),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              if (phone != null && whatsapp != null)
                const SizedBox(width: AppSpacing.sm),
              if (whatsapp != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      'https://wa.me/${_intl(whatsapp)}',
                      'WhatsApp',
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Please reach out and schedule your demo visit soon. A credit is '
            'deducted only if you never visit the family.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Tone.success.foreground(brightness).withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked: what it costs, what it commits them to ──

  Widget _locked(UnlockStatus status) {
    final blocked = status.blockedReason;
    final slots = status.slotsLeft;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Parent contact is hidden',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Unlocking is free and shows you the family’s phone and WhatsApp. '
            'It also puts your name forward for this tuition — and it is a '
            'commitment to visit and take the demo. One credit is deducted only '
            'if you don’t go.',
            style: TextStyle(fontSize: 13.5, height: 1.55),
          ),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Pill(
                '${status.balance.toStringAsFixed(0)} credits in your wallet',
                tone: status.hasCredits ? Tone.neutral : Tone.critical,
                icon: Icons.account_balance_wallet_outlined,
                dense: true,
              ),
              if (slots != null)
                Pill(
                  slots == 0 ? 'No slots left' : '$slots of ${status.maxUnlocks} slots left',
                  tone: slots == 0
                      ? Tone.critical
                      : slots <= 2
                          ? Tone.warning
                          : Tone.neutral,
                  icon: Icons.group_outlined,
                  dense: true,
                ),
            ],
          ),
          if (blocked != null) ...[
            const SizedBox(height: AppSpacing.base),
            _Notice(
              tone: status.limitReached ? Tone.critical : Tone.warning,
              icon: Icons.info_outline_rounded,
              title: status.limitReached ? 'Limit reached' : 'Not enough credits',
              message: blocked,
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: status.hasCredits || status.limitReached
                ? FilledButton.icon(
                    onPressed:
                        _working || !status.canUnlock ? null : () => _unlock(status),
                    icon: _working
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(_working ? 'Unlocking…' : 'Unlock contact'),
                  )
                : FilledButton.icon(
                    onPressed: () => context.push('/packages'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add credits'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlock(UnlockStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlock this contact?'),
        content: const Text(
          'You’ll see the family’s phone and WhatsApp, and your name goes '
          'forward for this tuition.\n\n'
          'Please visit them and take the demo. If you don’t, one credit is '
          'deducted from your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(jobsRepositoryProvider).unlockJobContact(widget.jobId);
      if (!mounted) return;
      // The job itself now carries the contact, and the feed's "Applied" state
      // changed, so both have to be re-read.
      ref.invalidate(unlockStatusProvider(widget.jobId));
      ref.invalidate(jobProvider(widget.jobId));
      ref.read(jobFeedProvider.notifier).refresh();
      context.showMessage('Contact unlocked — please visit and take the demo.');
    } catch (e) {
      if (!mounted) return;
      context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// wa.me needs a country code; numbers are stored as 10 local digits.
  String _intl(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '91$digits' : digits;
  }

  Future<void> _open(String uri, String what) async {
    final ok = await launchUrl(
      Uri.parse(uri),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      context.showMessage("Couldn't open your $what.");
    }
  }
}

// ── Requirement details ──────────────────────────────────────────────────────

class _Requirement extends StatelessWidget {
  const _Requirement({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (job.feeLabel != null)
        (Icons.payments_outlined, 'Fee offered', job.feeLabel!),
      if (job.locality.isNotEmpty)
        (Icons.location_on_outlined, 'Area', job.locality),
      if (job.detailedAddress.trim().isNotEmpty)
        (Icons.home_outlined, 'Address', job.detailedAddress.trim()),
      if (job.preferredTime.isNotEmpty)
        (Icons.schedule_outlined, 'Preferred time', job.preferredTime),
      if (job.daysPerWeek.isNotEmpty)
        (Icons.calendar_today_outlined, 'Days per week', job.daysPerWeek),
      (Icons.cast_for_education_outlined, 'Mode', job.modeLabel),
      if (job.tutorGenderPreference.isNotEmpty &&
          job.tutorGenderPreference.toLowerCase() != 'any')
        (
          Icons.person_outline_rounded,
          'Teacher preference',
          '${job.tutorGenderPreference} teacher'
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('The requirement'),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _DetailRow(
                  icon: rows[i].$1,
                  label: rows[i].$2,
                  value: rows[i].$3,
                ),
              ],
            ],
          ),
        ),
        if (job.mapLink.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(_mapUri(job.mapLink.trim())),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Open in Maps'),
          ),
        ],
      ],
    );
  }

  /// The field holds either a full URL or bare `lat,lng`.
  String _mapUri(String value) => value.startsWith('http')
      ? value
      : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(value)}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Siblings ─────────────────────────────────────────────────────────────────

class _Students extends StatelessWidget {
  const _Students({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final students = job.allStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Students',
          subtitle: '${students.length} children share this tuition',
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < students.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        students[i],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (i == 0 && job.classGrade.isNotEmpty)
                      Pill(job.classGrade, dense: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Inline notice ────────────────────────────────────────────────────────────

class _Notice extends StatelessWidget {
  const _Notice({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Tone tone;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = tone.foreground(brightness);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.border(brightness)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: fg.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
