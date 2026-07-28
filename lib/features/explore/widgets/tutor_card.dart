import 'package:flutter/material.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// One teacher in a parent's list.
///
/// A parent scanning this is deciding who to spend a credit on, so it leads with
/// the name and what they teach, then the things that actually differentiate:
/// verification, experience, and whether real parents have rated them.
class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    this.onTap,
    this.onToggleFavourite,
  });

  final PublicTutor tutor;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THTAvatar(
                name: tutor.name,
                imageUrl: tutor.imageUrl,
                size: 52,
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
                            tutor.name.trim().isEmpty
                                ? 'Teacher'
                                : Fmt.titleCase(tutor.name),
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
                        if (tutor.isKycVerified) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Tone.info.foreground(
                              Theme.of(context).brightness,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tutor.subjects.isEmpty
                          ? 'Subjects not listed'
                          : Fmt.list(tutor.subjects),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                    if (tutor.credentialLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tutor.credentialLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (onToggleFavourite != null)
                IconButton(
                  onPressed: onToggleFavourite,
                  visualDensity: VisualDensity.compact,
                  tooltip: tutor.isFavourite
                      ? 'Remove from saved'
                      : 'Save this teacher',
                  icon: Icon(
                    tutor.isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: tutor.isFavourite ? AppColors.rose : muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Only a real rating is shown. A default star value would tell a
              // parent something the platform does not actually know.
              if (tutor.hasRatings)
                Pill(
                  '${tutor.avgRating!.toStringAsFixed(1)} '
                  '(${Fmt.plural(tutor.ratingCount, 'review')})',
                  tone: Tone.success,
                  icon: Icons.star_rounded,
                  dense: true,
                )
              else
                const Pill('No reviews yet', dense: true),
              if (tutor.isUnlocked)
                const Pill(
                  'Contact unlocked',
                  tone: Tone.success,
                  icon: Icons.lock_open_rounded,
                  dense: true,
                ),
              if (tutor.isBed) const Pill('B.Ed', tone: Tone.info, dense: true),
              if (tutor.isTet) const Pill('TET', tone: Tone.info, dense: true),
              if (tutor.expectedFee != null && tutor.expectedFee! > 0)
                Pill(
                  '${Fmt.rupees(tutor.expectedFee)} / month',
                  icon: Icons.payments_outlined,
                  dense: true,
                ),
            ],
          ),
          if (tutor.teachingMode.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.cast_for_education_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tutor.modeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ),
                if (tutor.ongoingTuitions > 0)
                  Text(
                    '${tutor.ongoingTuitions} running',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
