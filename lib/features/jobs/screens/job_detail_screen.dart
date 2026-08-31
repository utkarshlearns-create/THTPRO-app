import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/co_applicants.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/lead_purchase.dart';
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
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';
import 'package:tht_app/features/jobs/widgets/chance_sheet.dart';
import 'package:tht_app/features/jobs/widgets/counsellor_strip.dart';
import 'package:tht_app/features/jobs/widgets/two_ways_card.dart';
import 'package:tht_app/features/jobs/widgets/ineligible_notice.dart';
import 'package:tht_app/features/jobs/widgets/job_share.dart';
import 'package:tht_app/features/jobs/widgets/lead_terms_sheet.dart';
import 'package:tht_app/features/wallet/services/checkout_service.dart';
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
      appBar: AppBar(
        title: const Text('Job details'),
        actions: [
          // Only once the job has loaded — sharing a lead we do not have the
          // details of would share an empty block.
          if (job.valueOrNull case final j?) JobShareActions(job: j),
        ],
      ),
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
              // The trade-off, stated once before either card asks for a
              // decision. Renders nothing unless both routes are really open.
              if (j.isBuyable) ...[
                TwoWaysCard(job: j),
                const SizedBox(height: AppSpacing.lg),
              ],
              // The paid route leads, because on a buyable lead it is the one
              // that gets a teacher the family today. Applying stays below it
              // as the free alternative, never removed.
              _ContactCard(jobId: jobId, job: j),
              // Who already holds this contact. Only on a lead that is sold —
              // on any other kind there is nothing to have bought.
              if (j.isBuyable) _LeadBuyers(jobId: jobId),
              const _OrDivider(),
              _ApplyCard(jobId: jobId, job: j),
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
              const SizedBox(height: AppSpacing.xl),
              CounsellorStrip(job: j),
              const SizedBox(height: AppSpacing.xl),
              // Always present, but only *fetched* once applied — the endpoint
              // 403s otherwise. Rendering nothing at all was the wrong answer:
              // a teacher could not tell whether there were no applicants, or
              // whether the section had failed to load.
              if (j.hasApplied)
                _CoApplicants(jobId: jobId)
              else
                const _ApplicantsLocked(),
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
          job.subjects.isEmpty
              ? 'Tuition required'
              : Fmt.list(job.subjects, max: 4),
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
            if (job.isInstituteJob)
              const Pill('Institute lead', tone: Tone.accent),
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
            // The teacher's own standing, before the list of everyone else.
            // A percentage on its own is a verdict with no recourse, so it is
            // tappable through to what drove it.
            if (co.me?.chancePercentage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ChanceBadge(
                  jobId: jobId,
                  tutorProfileId: co.me!.tutorId,
                  percentage: co.me!.chancePercentage!,
                  rank: co.myRank,
                  total: co.totalCount,
                ),
              ),
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

    // The teacher's own curation state, read ahead of the tap so the button
    // can say so rather than letting them find out from a 403. Absent profile
    // means eligible — never block on a flag that has not loaded.
    final profile = ref.watch(tutorProfileProvider).valueOrNull;
    final ineligible = profile != null && !profile.isEligible;

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
              // go, not push: this page is on the root navigator and the target
              // lives in the tutor shell. Pushing asks that shell to exist
              // twice in one stack and it renders blank.
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
            'Applying is free. The family sees you on '
            'their list of interested teachers, and our team may line up a '
            'demo. Their number stays private unless you are chosen.',
            style: TextStyle(fontSize: 13.5, height: 1.55),
          ),
          if (ineligible) ...[
            const SizedBox(height: AppSpacing.base),
            IneligibleNotice.strip(
              context,
              reason: profile.ineligibleReason,
            ),
          ],
          if (_refusal != null) ...[
            const SizedBox(height: AppSpacing.base),
            NoteBox(message: _refusal!),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            // Outlined while ineligible: a full-primary button reads as "go",
            // which is the opposite of what it says. Still tappable, because
            // it opens the explanation — a dead button teaches nobody why.
            child: ineligible
                ? OutlinedButton.icon(
                    onPressed: _working
                        ? null
                        : () => IneligibleNotice.show(
                              context,
                              reason: profile.ineligibleReason,
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Tone.warning.foreground(brightness),
                      side: BorderSide(
                        color: Tone.warning.border(brightness),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Not eligible to apply'),
                  )
                : FilledButton.icon(
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
                    label:
                        Text(_working ? 'Applying…' : 'Apply for this tuition'),
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
      final failure = ApiFailure.from(e);

      // The authoritative eligibility gate. The profile flag read above can be
      // stale — an admin may have marked this teacher since it loaded — so the
      // 403 is what actually decides, and it gets the full explanation rather
      // than a line of red text among the other refusals.
      if (failure.statusCode == 403 && failure.flag('not_eligible')) {
        // Re-read the profile so the button relabels itself and the strip
        // appears without the teacher having to reopen the screen.
        ref.invalidate(tutorProfileProvider);
        await IneligibleNotice.show(
          context,
          reason: failure.body['ineligible_reason'] as String?,
        );
        return;
      }

      // The backend writes its other refusals itself, and they are specific —
      // which gender it wants, how many tuitions you are already running.
      // Showing its words beats paraphrasing them.
      setState(() => _refusal = failure.message);
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

/// How a teacher gets the family behind this lead.
///
/// Six states, in priority order. Which one shows is decided by the lead's own
/// flags plus this teacher's status — the lead says whether it is for sale, the
/// status says whether this teacher may buy it.
///
///   held        → the number, and a WhatsApp button
///   sold out    → every place taken
///   unapproved  → profile not approved, so the server would refuse
///   buyable     → the price, and a way to pay it
///   THT-managed → contact shared by us if selected
///   private     → no contact, apply only
///
/// Applying is free and always available underneath, whatever this card says.
class _ContactCardState extends ConsumerState<_ContactCard> {
  bool _working = false;

  /// Revealed by a verified purchase in this session, before the status
  /// provider has refetched.
  String? _justBought;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(unlockStatusProvider(widget.jobId));

    return AsyncView<UnlockStatus>(
      value: status,
      onRetry: () => ref.invalidate(unlockStatusProvider(widget.jobId)),
      loading: const SkeletonBox(height: 150, radius: AppRadius.lg),
      compactError: true,
      data: _card,
    );
  }

  Widget _card(UnlockStatus s) {
    final job = widget.job;

    if (s.isUnlocked || job.isContactUnlocked || _justBought != null) {
      return _held(s);
    }
    if (job.isBuyable && s.isSoldOut) return _soldOut();
    if (job.isBuyable && !s.isApproved) return _notApproved();
    if (s.canBuy(leadIsBuyable: job.isBuyable)) return _buyable(s);
    if (job.isThtManaged) return _thtManaged();
    return _private();
  }

  // ── 1. Held ────────────────────────────────────────────────────────────────

  Widget _held(UnlockStatus status) {
    final job = widget.job;
    final whatsapp =
        _justBought ?? status.whatsapp ?? job.parentWhatsapp ?? job.parentPhone;
    final brightness = Theme.of(context).brightness;
    final bought = status.isPaid || _justBought != null;

    return THTCard(
      borderColor: Tone.success.border(brightness),
      background: Tone.success.background(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 18,
                color: Tone.success.foreground(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                bought ? 'Lead purchased' : 'Contact unlocked',
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
            job.parentName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (whatsapp != null) ...[
            const SizedBox(height: 2),
            Text(
              Fmt.phone(whatsapp),
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
              if (whatsapp != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _open('https://wa.me/${_intl(whatsapp)}', 'WhatsApp'),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
              if (whatsapp != null && job.parentPhone != null)
                const SizedBox(width: AppSpacing.sm),
              if (job.parentPhone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _open('tel:${job.parentPhone}', 'phone app'),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            bought
                ? 'This lead is yours to manage directly with the family. THT '
                    'takes no commission on the tuition fee.'
                : 'Please reach out and arrange your demo visit soon.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color:
                  Tone.success.foreground(brightness).withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Sold out ────────────────────────────────────────────────────────────

  Widget _soldOut() => _lockedCard(
        icon: Icons.do_not_disturb_on_outlined,
        tone: Tone.neutral,
        title: 'Sold out',
        body: 'The most teachers this family wanted have already bought this '
            'lead. You can still apply below and be considered.',
      );

  // ── 3. Not approved ────────────────────────────────────────────────────────

  Widget _notApproved() => _lockedCard(
        icon: Icons.gpp_maybe_outlined,
        tone: Tone.warning,
        title: 'Approval needed to buy leads',
        body: 'Only approved teachers can buy a lead. Finish your profile and '
            'verification and this opens up. You can still apply below.',
        action: ('Finish verification', () => context.go('/tutor-kyc')),
      );

  // ── 4. Buyable ─────────────────────────────────────────────────────────────

  Widget _buyable(UnlockStatus status) {
    final brightness = Theme.of(context).brightness;
    final price = widget.job.leadPrice!;
    final spots = status.spotsLine;

    return THTCard(
      borderColor: Tone.accent.border(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 18,
                color: Tone.accent.foreground(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Buy this lead',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Tone.accent.foreground(brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "Get the family's WhatsApp number straight away and arrange the "
            'tuition with them yourself. THT takes no commission — the fee you '
            'agree is yours.',
            style: TextStyle(fontSize: 13.5, height: 1.55),
          ),
          if (spots != null) ...[
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 15,
                  color: Tone.warning.foreground(brightness),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    spots,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Tone.warning.foreground(brightness),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _working ? null : _buy,
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
              label: Text(
                _working ? 'Opening payment…' : 'Buy this lead — ₹$price',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. THT-managed ─────────────────────────────────────────────────────────

  Widget _thtManaged() => _lockedCard(
        icon: Icons.shield_outlined,
        tone: Tone.info,
        title: 'THT shares this contact',
        body: 'This family asked us to screen teachers for them. Apply below '
            'and we will pass on your profile — we share the contact once you '
            'are selected.',
      );

  // ── 6. Private ─────────────────────────────────────────────────────────────

  Widget _private() => _lockedCard(
        icon: Icons.lock_outline_rounded,
        tone: Tone.neutral,
        title: 'Contact kept private',
        body: 'This family is not sharing their number directly. Apply below '
            'and our team will take it from there.',
      );

  /// The shared shape of every state that is not a purchase.
  Widget _lockedCard({
    required IconData icon,
    required Tone tone,
    required String title,
    required String body,
    (String, VoidCallback)? action,
  }) {
    final brightness = Theme.of(context).brightness;
    final isNeutral = tone == Tone.neutral;

    return THTCard(
      borderColor: isNeutral ? null : tone.border(brightness),
      background: isNeutral ? null : tone.background(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone.foreground(brightness)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tone.foreground(brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isNeutral
                  ? null
                  : tone.foreground(brightness).withValues(alpha: 0.95),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton(onPressed: action.$2, child: Text(action.$1)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Buying ─────────────────────────────────────────────────────────────────

  Future<void> _buy() async {
    final price = widget.job.leadPrice;
    if (price == null) return;

    // Terms first, and not as a formality: this is money, it is
    // non-refundable, and buying does not win the tuition.
    final agreed = await LeadTermsSheet.show(context, price: price);
    if (agreed != true || !mounted) return;

    setState(() => _working = true);
    try {
      final order =
          await ref.read(jobsRepositoryProvider).createLeadOrder(widget.jobId);
      if (!mounted) return;

      final result = await CheckoutService().openForLead(
        order: order,
        user: ref.read(currentUserProvider).valueOrNull,
      );
      if (!mounted) return;

      switch (result) {
        case CheckoutCancelled():
          setState(() => _working = false);
        case CheckoutFailed(:final message):
          setState(() => _working = false);
          context.showMessage(message);
        case CheckoutPaid(:final paymentId, :final orderId, :final signature):
          // The device saying "paid" is not proof. Nothing is revealed until
          // the server has checked the signature.
          final purchase =
              await ref.read(jobsRepositoryProvider).verifyLeadPurchase(
                    widget.jobId,
                    orderId: orderId,
                    paymentId: paymentId,
                    signature: signature,
                  );
          if (!mounted) return;
          setState(() {
            _justBought = purchase.whatsapp;
            _working = false;
          });
          ref
            ..invalidate(unlockStatusProvider(widget.jobId))
            ..invalidate(jobProvider(widget.jobId))
            ..invalidate(leadBuyersProvider(widget.jobId));
          context.showMessage(
            'Lead purchased. Message the family and set up your demo.',
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      // The server writes these refusals itself and they are specific — not
      // approved, lead full, already owned. Its words beat a paraphrase.
      context.showMessage(ApiFailure.from(e).message);
      ref.invalidate(unlockStatusProvider(widget.jobId));
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

/// The teachers who have already bought this lead.
///
/// Renders nothing at all when nobody has — an empty "0 buyers" line would
/// discourage the first buyer for no reason.
class _LeadBuyers extends ConsumerWidget {
  const _LeadBuyers({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(leadBuyersProvider(jobId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return AsyncView<LeadBuyers>(
      value: data,
      compactError: true,
      loading: const SizedBox.shrink(),
      onRetry: () => ref.invalidate(leadBuyersProvider(jobId)),
      data: (b) {
        if (b.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              // Overlapping avatars, so a crowded lead reads as crowded at a
              // glance rather than as a list to count.
              SizedBox(
                height: 28,
                width: 28.0 + (b.buyers.take(4).length - 1).clamp(0, 3) * 18,
                child: Stack(
                  children: [
                    for (var i = 0; i < b.buyers.take(4).length; i++)
                      Positioned(
                        left: i * 18.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: THTAvatar(
                            name: b.buyers[i].name,
                            imageUrl: b.buyers[i].photo,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  b.totalCount == 1
                      ? '1 teacher has bought this lead'
                      : '${b.totalCount} teachers have bought this lead',
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Why the applicant list is not here yet.
///
/// The server refuses this list to anyone who has not applied, which is a
/// reasonable rule and a terrible silence — the section simply did not exist,
/// so it read as broken. Saying what is behind it turns that into a reason to
/// apply.
class _ApplicantsLocked extends StatelessWidget {
  const _ApplicantsLocked();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Who else applied',
          icon: Icons.groups_outlined,
          iconTone: Tone.neutral,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 19, color: muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Apply and you will see everyone else in the running here — '
                  'their experience, their ranking, and where you sit against '
                  'them.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The teacher's hiring chance on this lead, and their place in the queue.
///
/// Tappable: the number alone tells someone they are losing without telling
/// them why, and the six-pillar breakdown behind it is actionable.
class _ChanceBadge extends StatelessWidget {
  const _ChanceBadge({
    required this.jobId,
    required this.tutorProfileId,
    required this.percentage,
    required this.rank,
    required this.total,
  });

  final int jobId;
  final int tutorProfileId;
  final double percentage;
  final int? rank;
  final int total;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final tone = toneForChance(percentage);

    return THTCard(
      onTap: () => ChanceSheet.show(
        context,
        jobId: jobId,
        tutorProfileId: tutorProfileId,
      ),
      borderColor: tone.border(brightness),
      background: tone.background(brightness),
      child: Row(
        children: [
          Text(
            '🎯',
            style: TextStyle(fontSize: 20, color: tone.foreground(brightness)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.round()}% chance on this lead',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: tone.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rank == null
                      ? 'Tap to see what this is based on'
                      : total > 0
                          ? 'You are #$rank of $total applicants · tap for why'
                          : 'You are #$rank · tap for why',
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}

/// The seam between paying for the contact and applying for free.
///
/// Both routes stay open on every lead, so the divider says "or" rather than
/// implying the one above is required.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? AppColors.darkBorder : AppColors.slate200;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        children: [
          Expanded(child: Divider(color: line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'or',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
          Expanded(child: Divider(color: line)),
        ],
      ),
    );
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
