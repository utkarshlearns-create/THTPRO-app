import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// One document the teacher can attach.
class _Doc {
  const _Doc(this.field, this.label, this.hint, {this.required = false});

  /// The backend field name this file is posted as.
  final String field;

  final String label;
  final String hint;
  final bool required;
}

/// Identity verification.
///
/// Verification is what stands between a teacher and any leads at all, so the
/// screen is explicit about exactly what is needed and what happens next — never
/// a bare "Upload documents" button with no list.
class TutorKYCScreen extends ConsumerStatefulWidget {
  const TutorKYCScreen({super.key});

  @override
  ConsumerState<TutorKYCScreen> createState() => _TutorKYCScreenState();
}

class _TutorKYCScreenState extends ConsumerState<TutorKYCScreen> {
  /// Aadhaar is the only hard requirement; the qualification certificate speeds
  /// approval, so it is offered here rather than left for a later round-trip.
  static const _docs = [
    _Doc('aadhaar_front', 'Aadhaar — front', 'The side with your photo',
        required: true),
    _Doc('aadhaar_back', 'Aadhaar — back', 'The side with your address',
        required: true),
    _Doc(
      'highest_qualification_certificate',
      'Highest qualification',
      'Degree or marksheet — speeds up approval',
    ),
  ];

  final _picked = <String, String>{};
  bool _termsAccepted = false;
  bool _submitting = false;

  bool get _hasRequired =>
      _docs.where((d) => d.required).every((d) => _picked.containsKey(d.field));

  @override
  Widget build(BuildContext context) {
    final kyc = ref.watch(kycStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: AsyncView<KycStatus>(
        value: kyc,
        onRetry: () => ref.invalidate(kycStatusProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 90),
        ),
        data: (status) => status.isVerified
            ? _verified(status)
            : _form(status),
      ),
    );
  }

  // ── Already verified: nothing to do here ──

  Widget _verified(KycStatus status) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        THTCard(
          background: Tone.success.background(Theme.of(context).brightness),
          borderColor: Tone.success.border(Theme.of(context).brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Tone.success
                        .foreground(Theme.of(context).brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "You're verified",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Tone.success
                          .foreground(Theme.of(context).brightness),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Families see an ID-verified badge on your profile. Your '
                'documents are locked now — contact your admin if something '
                'needs correcting.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: Tone.success
                      .foreground(Theme.of(context).brightness)
                      .withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Not verified: what to send, and where it stands ──

  Widget _form(KycStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final inReview = status.isPending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (status.nextStep != null)
          _StatusBanner(status: status),
        const SizedBox(height: AppSpacing.lg),
        Text(
          inReview ? 'Your documents' : 'What we need',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Photos only — JPG or PNG. PDFs are not accepted. Make sure the text '
          'is readable and all four corners are in frame.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: muted),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final doc in _docs) ...[
          _DocRow(
            doc: doc,
            path: _picked[doc.field],
            onPick: () => _pick(doc),
            onClear: () => setState(() => _picked.remove(doc.field)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        _TermsCheck(
          value: _termsAccepted,
          onChanged: (v) => setState(() => _termsAccepted = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(inReview ? 'Send updated documents' : 'Submit for verification'),
        ),
        if (!_hasRequired) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Both sides of your Aadhaar are needed to submit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ] else if (!_termsAccepted) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please accept the Terms & Conditions to submit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ],
    );
  }

  bool get _canSubmit => _hasRequired && _termsAccepted && !_submitting;

  Future<void> _pick(_Doc doc) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        // Full-resolution phone photos are many megabytes and the upload is
        // often on mobile data; this stays readable at a fraction of the size.
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() => _picked[doc.field] = file.path);
    } catch (e) {
      if (mounted) context.showFailure(e);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repo = ref.read(usersRepositoryProvider);

    try {
      // The server rejects documents outright if terms were never accepted, so
      // record acceptance first rather than letting the upload fail.
      await repo.acceptTerms();
      await repo.submitKyc(Map.of(_picked));
      if (!mounted) return;

      ref.invalidate(kycStatusProvider);
      setState(() => _picked.clear());
      context.showMessage(
        'Documents submitted. We usually review within a working day.',
      );
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final KycStatus status;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tone = status.isRejected
        ? Tone.critical
        : status.isPending
            ? Tone.info
            : Tone.warning;
    final fg = tone.foreground(brightness);

    return THTCard(
      background: tone.background(brightness),
      borderColor: tone.border(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.isPending
                    ? Icons.hourglass_top_rounded
                    : status.isRejected
                        ? Icons.error_outline_rounded
                        : Icons.badge_outlined,
                size: 19,
                color: fg,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status.shortLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            status.nextStep!,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: fg.withValues(alpha: 0.95),
            ),
          ),
          if (status.documentsToResubmit.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final doc in status.documentsToResubmit)
                  Pill(
                    doc.replaceAll('_', ' '),
                    tone: Tone.critical,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── One document row ─────────────────────────────────────────────────────────

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.doc,
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final _Doc doc;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final attached = path != null;

    return THTCard(
      onTap: attached ? null : onPick,
      borderColor: attached ? Tone.success.border(brightness) : null,
      child: Row(
        children: [
          _Thumb(path: path, attached: attached, brightness: brightness),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      doc.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (doc.required) ...[
                      const SizedBox(width: 5),
                      Text(
                        '*',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Tone.critical.foreground(brightness),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  attached ? 'Attached' : doc.hint,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: attached
                        ? Tone.success.foreground(brightness)
                        : muted,
                  ),
                ),
              ],
            ),
          ),
          if (attached)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Remove ${doc.label}',
            )
          else
            Icon(Icons.add_a_photo_outlined, size: 19, color: muted),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.path,
    required this.attached,
    required this.brightness,
  });

  final String? path;
  final bool attached;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;

    if (!attached) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.description_outlined,
          size: 20,
          color: isDark ? AppColors.slate400 : AppColors.slate400,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 46,
        height: 46,
        // The picked file is a local path, so it renders from disk. On web the
        // path is a blob URL that File cannot read, hence the icon fallback.
        child: kIsWeb
            ? Container(
                color: Tone.success.background(brightness),
                child: Icon(
                  Icons.check_rounded,
                  color: Tone.success.foreground(brightness),
                ),
              )
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Tone.success.background(brightness),
                  child: Icon(
                    Icons.check_rounded,
                    color: Tone.success.foreground(brightness),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Terms ────────────────────────────────────────────────────────────────────

class _TermsCheck extends StatelessWidget {
  const _TermsCheck({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 11),
                child: Text(
                  'I confirm these documents are mine and accept the Terms & '
                  'Conditions.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
