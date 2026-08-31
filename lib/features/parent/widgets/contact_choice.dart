import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';

/// How teachers may reach the family behind a requirement.
///
/// One choice, three arrangements. Kept deliberately free of money: the family
/// never learns that a teacher pays for their contact, and the server strips
/// the price from their side of the payload entirely. What they choose here is
/// *who gets to call them*, not what anyone is charged.
enum ContactChoice {
  /// Teachers reach the family directly. Fastest, and the family keeps the
  /// whole fee they agree.
  direct,

  /// THT screens teachers and introduces the good ones.
  screened,

  /// No contact shared. Teachers apply and our team handles everything.
  private;

  bool get allowContact => this != ContactChoice.private;
  bool get allowPayPerLead => this == ContactChoice.direct;
}

/// The picker. Used on the parent wizard and the institute's post form alike.
class ContactChoiceField extends StatelessWidget {
  const ContactChoiceField({
    super.key,
    required this.value,
    required this.onChanged,
    this.subjectNoun = 'you',
  });

  final ContactChoice value;
  final ValueChanged<ContactChoice> onChanged;

  /// "you" for a parent, "your institute" for an institute.
  final String subjectNoun;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How should teachers reach $subjectNoun?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Option(
          choice: ContactChoice.direct,
          selected: value,
          onChanged: onChanged,
          icon: Icons.bolt_rounded,
          tone: Tone.success,
          title: 'Let verified teachers contact $subjectNoun directly',
          body: 'They reach you on WhatsApp and you arrange the tuition '
              'between yourselves. THT takes no commission — you keep the '
              'full fee. This fills fastest.',
          badge: 'Recommended',
        ),
        _Option(
          choice: ContactChoice.screened,
          selected: value,
          onChanged: onChanged,
          icon: Icons.shield_outlined,
          tone: Tone.info,
          title: 'Let THT screen teachers for $subjectNoun',
          body: 'We check applicants and introduce the ones worth your time. '
              'Your number stays with us until you pick someone.',
        ),
        _Option(
          choice: ContactChoice.private,
          selected: value,
          onChanged: onChanged,
          icon: Icons.lock_outline_rounded,
          tone: Tone.neutral,
          title: 'Keep $subjectNoun private',
          body: 'Nobody gets your number. Teachers apply and our team handles '
              'every step with you.',
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.selected,
    required this.onChanged,
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.badge,
  });

  final ContactChoice choice;
  final ContactChoice selected;
  final ValueChanged<ContactChoice> onChanged;
  final IconData icon;
  final Tone tone;
  final String title;
  final String body;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final isSelected = selected == choice;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => onChanged(choice),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: isSelected ? tone.background(brightness) : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? tone.foreground(brightness)
                  : (isDark ? AppColors.darkBorder : AppColors.slate200),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected ? tone.foreground(brightness) : muted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: tone.foreground(brightness),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: isDark
                                  ? AppColors.slate50
                                  : AppColors.slate900,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Tone.success.background(brightness),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Tone.success.foreground(brightness),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style:
                          TextStyle(fontSize: 12.5, height: 1.45, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
