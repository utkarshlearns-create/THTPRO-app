import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/unlocked_lead.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/subject_glyph.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Leads this teacher has unlocked — the families whose numbers they hold.
///
/// The endpoint was being fetched and thrown away. It matters because unlocking
/// is a promise to visit: a credit is deducted from anyone who never turns up,
/// so a teacher needs to see what they have taken on.
class TutorLeadsScreen extends ConsumerWidget {
  const TutorLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(unlockedLeadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unlocked leads')),
      body: AsyncView<List<UnlockedLead>>(
        value: leads,
        onRetry: () => ref.invalidate(unlockedLeadsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 4, itemHeight: 120),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(unlockedLeadsProvider);
            await ref.read(unlockedLeadsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.lock_open_outlined,
                      title: 'No unlocked leads yet',
                      message: 'When you unlock a family from the job feed, '
                          'they appear here with their contact so you can '
                          'reach out.',
                      actionLabel: 'Find jobs',
                      onAction: () => context.go('/tutor-jobs'),
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
                  children: _body(list),
                ),
        ),
      ),
    );
  }

  List<Widget> _body(List<UnlockedLead> list) {
    final cold = list.where((l) => l.isGoingCold).length;

    return [
      if (cold > 0) ...[
        NoteBox(
          tone: Tone.warning,
          title: cold == 1
              ? 'One lead is waiting on you'
              : '$cold leads are waiting on you',
          message: 'Unlocking is free, but a credit is deducted if you never '
              'visit the family. Reach out before these go cold.',
        ),
        const SizedBox(height: AppSpacing.base),
      ],
      for (var i = 0; i < list.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        _LeadCard(lead: list[i]),
      ],
    ];
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final UnlockedLead lead;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final phone = lead.whatsapp;

    return THTCard(
      onTap: () => context.push('/jobs/${lead.jobId}'),
      borderColor: lead.isGoingCold ? Tone.warning.border(brightness) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate800 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  lead.subjects.isEmpty
                      ? SubjectGlyph.fallback
                      : SubjectGlyph.of(lead.subjects.first),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.studentName.trim().isEmpty
                          ? 'Family'
                          : Fmt.titleCase(lead.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (lead.summaryLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lead.summaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (lead.isDecided)
                Pill(Fmt.status(lead.jobStatus), dense: true)
              else if (lead.unlockedAt != null)
                Pill(
                  Fmt.relative(lead.unlockedAt),
                  tone: lead.isGoingCold ? Tone.warning : Tone.neutral,
                  dense: true,
                ),
            ],
          ),
          if (lead.locality.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    lead.locality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ),
                if (lead.budgetRange.trim().isNotEmpty)
                  Text(
                    lead.budgetRange.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Tone.success.foreground(brightness),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: phone == null || phone.trim().isEmpty
                      ? null
                      : () => launchUrl(
                            Uri.parse('tel:${phone.trim()}'),
                            mode: LaunchMode.externalApplication,
                          ),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: const Text('Call'),
                ),
              ),
              if (phone != null && phone.trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://wa.me/${_intl(phone)}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 17),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// wa.me needs a country code; numbers are stored as 10 local digits.
  String _intl(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '91$digits' : digits;
  }
}
