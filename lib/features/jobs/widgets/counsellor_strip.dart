import 'package:flutter/material.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';

/// The THT counsellor who owns this lead, and two ways to reach them.
///
/// Not the family's contact — that is bought. This is our own staff, reachable
/// for free and before committing, for the questions that decide whether a
/// lead is worth buying at all: is it still live, how far is the address
/// really, what did "flexible timings" mean.
///
/// Renders nothing when no counsellor is assigned or no number came back,
/// rather than offering a button that dials nothing.
class CounsellorStrip extends StatelessWidget {
  const CounsellorStrip({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final counsellor = job.counsellor;
    if (counsellor == null || !counsellor.isReachable) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              THTAvatar(
                name: counsellor.name,
                imageUrl: counsellor.photo,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need help with this job?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Fmt.titleCase(counsellor.name)} is handling this lead',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
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
                child: OutlinedButton.icon(
                  onPressed: () => _open('tel:${counsellor.phone}'),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _open(
                    'https://wa.me/${counsellor.whatsappNumber}'
                    '?text=${Uri.encodeComponent(_message)}',
                  ),
                  icon: Icon(
                    Icons.chat_rounded,
                    size: 17,
                    color: Tone.success.foreground(brightness),
                  ),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens the chat with the lead already named, so the counsellor is not
  /// asked "which job?" as the first reply.
  String get _message {
    final what = [
      if (job.classGrade.isNotEmpty) job.classGrade,
      if (job.subjects.isNotEmpty) job.subjects.take(2).join(', '),
    ].join(' ');
    return 'Hi, I have a question about job JD-${job.id}'
        '${what.isEmpty ? '' : ' ($what'
            '${job.locality.isEmpty ? '' : ', ${job.locality}'})'}.';
  }

  Future<void> _open(String uri) =>
      launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
}
