import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/ui/async_view.dart';

/// Passing a lead on to another teacher, or keeping the details to hand.
///
/// The text is built to be pasted into WhatsApp, because that is where it
/// actually goes. Contact details are deliberately absent — a shared lead
/// carries what the job *is*, never the family's number, which is bought and
/// belongs to whoever bought it.
class JobShare {
  const JobShare._();

  /// The block a teacher sends on.
  static String text(Job job) {
    final subjects = job.subjects.isEmpty ? 'All subjects' : job.subjects.join(', ');
    final fee = job.feeLabel ?? 'Negotiable';

    final lines = <String>[
      '🎓 *THE HOME TUITIONS*',
      '',
      '🆔 *Job ID:* JD-${job.id}',
      if (job.classGrade.isNotEmpty) '📌 *Class:* ${job.classGrade}'
          '${job.board.isEmpty ? '' : ' (${job.board})'}',
      '📚 *Subjects:* $subjects',
      if (job.locality.isNotEmpty) '📍 *Area:* ${job.locality}',
      '💰 *Fee:* $fee',
      if (job.daysPerWeek.isNotEmpty) '📅 *Days:* ${job.daysPerWeek}',
      if (job.preferredTime.isNotEmpty) '🕐 *Timing:* ${job.preferredTime}',
      '🏠 *Mode:* ${job.modeLabel}',
      if (job.tutorGenderPreference.isNotEmpty &&
          job.tutorGenderPreference.toLowerCase() != 'any')
        '👤 *Wanted:* ${job.tutorGenderPreference} teacher',
      if (job.isMultiChild)
        '👨‍👩‍👧 *${job.allStudents.length} children* — one teacher',
      '',
      '👇 *Apply here:*',
      '${ApiConfig.siteUrl}/jobs/${job.id}',
    ];
    return lines.join('\n');
  }

  /// Hands the block to the OS share sheet.
  static Future<void> share(BuildContext context, Job job) async {
    // Anchored for iPad, where a share sheet without an origin throws.
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text(job),
      subject: 'Tuition job JD-${job.id}',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  /// Copies the block, and says so — a clipboard write with no feedback looks
  /// like a button that did nothing.
  static Future<void> copy(BuildContext context, Job job) async {
    await Clipboard.setData(ClipboardData(text: text(job)));
    if (context.mounted) {
      context.showMessage('Job details copied — paste them anywhere.');
    }
  }
}

/// Share and copy, as app-bar actions.
class JobShareActions extends StatelessWidget {
  const JobShareActions({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => JobShare.copy(context, job),
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy details',
          ),
          IconButton(
            onPressed: () => JobShare.share(context, job),
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share this job',
          ),
        ],
      );
}
