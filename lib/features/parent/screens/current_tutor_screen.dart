import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/detail_row.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';
import 'package:tht_app/features/parent/providers/current_tutor_provider.dart';
import 'package:tht_app/features/parent/widgets/attendance_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Who is teaching your child, and everything about that arrangement.
///
/// A parent mid-tuition cares about one thing, and it used to be scattered: a
/// name and a photo on the home hero, the fee and schedule buried in an
/// applicant row inside the requirement, attendance somewhere else again.
class CurrentTutorScreen extends ConsumerWidget {
  const CurrentTutorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutors = ref.watch(currentTutorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your teacher')),
      body: AsyncView<List<EngagedTutor>>(
        value: tutors,
        onRetry: () => ref.invalidate(currentTutorsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 2, itemHeight: 200),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentTutorsProvider);
            await ref.read(currentTutorsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No teacher yet',
                      message: 'Once you choose a teacher for one of your '
                          'requirements, everything about that tuition lives '
                          'here.',
                      actionLabel: 'See your requirements',
                      onAction: () => context.go('/my-jobs'),
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
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.xl),
                      _TutorBlock(engaged: list[i]),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TutorBlock extends ConsumerStatefulWidget {
  const _TutorBlock({required this.engaged});

  final EngagedTutor engaged;

  @override
  ConsumerState<_TutorBlock> createState() => _TutorBlockState();
}

class _TutorBlockState extends ConsumerState<_TutorBlock> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final e = widget.engaged;
    final a = e.application;
    final job = e.job;
    final tutor = a.tutor;
    final name = a.tutorName.trim().isNotEmpty
        ? a.tutorName
        : (tutor?.name ?? 'Your teacher');
    final phone = a.tutorPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        THTCard(
          borderColor: e.isRunning ? Tone.success.border(brightness) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  THTAvatar(
                    name: name,
                    imageUrl: tutor?.imageUrl,
                    size: 56,
                    verified: a.tutorApproved,
                    onTap: tutor == null
                        ? null
                        : () => context.push('/tutors/${tutor.id}'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Fmt.titleCase(name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? AppColors.slate50 : AppColors.slate900,
                          ),
                        ),
                        if (tutor != null &&
                            tutor.credentialLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
                        const SizedBox(height: AppSpacing.sm),
                        Pill(
                          a.stageLabel,
                          tone: e.isRunning ? Tone.success : Tone.neutral,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
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
                      label: Text(phone == null ? 'Via our team' : 'Call'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working || tutor == null ? null : _message,
                      icon: const Icon(Icons.forum_outlined, size: 17),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // The arrangement itself — the numbers a parent is asked about and
        // could not previously find.
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              DetailRow(
                label: 'Teaching',
                value: job.summaryLine.isEmpty ? 'Tuition' : job.summaryLine,
              ),
              if (a.finalizedAmount != null) ...[
                const Divider(height: 1),
                DetailRow(
                  label: 'Agreed fee',
                  value: '${Fmt.rupees(a.finalizedAmount)} / month',
                ),
              ],
              if (job.preferredTime.isNotEmpty ||
                  job.daysPerWeek.isNotEmpty) ...[
                const Divider(height: 1),
                DetailRow(
                  label: 'When',
                  value: [
                    if (job.daysPerWeek.isNotEmpty) job.daysPerWeek,
                    if (job.preferredTime.isNotEmpty) job.preferredTime,
                  ].join(' · '),
                ),
              ],
              if (a.tuitionStartDate != null) ...[
                const Divider(height: 1),
                DetailRow(
                  label: 'Started',
                  value: Fmt.date(a.tuitionStartDate),
                ),
              ],
              const Divider(height: 1),
              DetailRow(
                label: 'Mode',
                value: job.modeLabel,
              ),
              const Divider(height: 1),
              DetailRow(
                label: 'Requirement',
                value: 'Open the full posting',
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () => context.push('/my-jobs/${job.id}'),
              ),
            ],
          ),
        ),

        // Attendance belongs with the teacher it is about.
        if (tutor != null && e.isRunning) ...[
          const SizedBox(height: AppSpacing.xl),
          AttendanceCard(
            jobId: job.id,
            tutorProfileId: tutor.id,
            tutorName: name,
          ),
        ],
      ],
    );
  }

  Future<void> _message() async {
    final tutor = widget.engaged.application.tutor;
    if (tutor == null) return;

    setState(() => _working = true);
    try {
      final convo = await ref.read(messagesRepositoryProvider).start(
            tutorProfileId: tutor.id,
            jobId: widget.engaged.job.id,
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
}
