import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tht_app/core/constants/kyc_documents.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/upload_file.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Identity and qualification verification.
///
/// Verification is what stands between a teacher and any leads at all, so the
/// screen is explicit about what is needed and where each document stands.
///
/// Every slot the KYC record holds is offered here — the app used to expose
/// three of seventeen, which left the professional certificates (B.Ed, TET,
/// CTET, NET…) uploadable only on the website even though they feed the score.
class TutorKYCScreen extends ConsumerStatefulWidget {
  const TutorKYCScreen({super.key});

  @override
  ConsumerState<TutorKYCScreen> createState() => _TutorKYCScreenState();
}

class _TutorKYCScreenState extends ConsumerState<TutorKYCScreen> {
  /// Files chosen this session, keyed by form field. Not paths — a picked file
  /// has no readable path on web.
  final _picked = <String, XFile>{};

  bool _termsAccepted = false;
  bool _submitting = false;

  /// The field currently being replaced on its own, so only its row spins.
  String? _replacing;

  bool get _hasRequired => KycDocuments.requiredDocs
      .every((d) => _picked.containsKey(d.field));

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
          child: SkeletonList(count: 4, itemHeight: 84),
        ),
        data: (status) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(kycStatusProvider);
            await ref.read(kycStatusProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: _body(status),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(KycStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    // Once approved, the identity documents are frozen — but a verified teacher
    // can still add a certificate they have just earned.
    final frozen = status.isVerified;

    return [
      _StatusBanner(status: status),
      if (status.submissionCount > 0) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Submitted ${status.submissionCount} '
          '${status.submissionCount == 1 ? 'time' : 'times'} so far.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Photos only — JPG or PNG. PDFs are not accepted. Make sure the text '
        'is readable and all four corners are in frame.',
        style: TextStyle(fontSize: 12.5, height: 1.5, color: muted),
      ),
      const SizedBox(height: AppSpacing.lg),

      _group('Identity', KycDocuments.identity, status, frozen,
          tone: Tone.info),
      _group('Education', KycDocuments.academic, status, frozen,
          tone: Tone.accent,
          note: 'Verified degrees raise your score, which decides how high you '
              'appear to families.'),
      _group('Teaching certificates', KycDocuments.professional, status, frozen,
          tone: Tone.success,
          note: 'Each verified certificate adds to your qualification score. '
              'Add only the ones you actually hold.'),

      if (!frozen) ...[
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
              : Text(
                  status.isPending || status.isRejected
                      ? 'Send updated documents'
                      : 'Submit for verification',
                ),
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
    ];
  }

  bool get _canSubmit => _hasRequired && _termsAccepted && !_submitting;

  Widget _group(
    String title,
    List<KycDoc> docs,
    KycStatus status,
    bool frozen, {
    required Tone tone,
    String? note,
  }) {
    final done = docs.where((d) => status.isDocVerified(d.verifiedField)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title,
          icon: docs.first.icon,
          iconTone: tone,
          subtitle: done > 0 ? '$done of ${docs.length} verified' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (note != null) ...[
          Text(
            note,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final doc in docs) ...[
          _DocRow(
            doc: doc,
            picked: _picked[doc.field],
            status: status,
            frozen: frozen,
            busy: _replacing == doc.field,
            onPick: () => _pick(doc),
            onClear: () => setState(() => _picked.remove(doc.field)),
            // Once approved, a single certificate can be added without
            // resubmitting the whole record and re-entering review.
            onReplaceNow: frozen ? () => _replaceOne(doc) : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.base),
      ],
    );
  }

  Future<XFile?> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
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
    if (source == null) return null;

    return ImagePicker().pickImage(
      source: source,
      // Full-resolution phone photos are many megabytes and the upload is
      // often on mobile data; this stays readable at a fraction of the size.
      maxWidth: 2000,
      imageQuality: 85,
    );
  }

  Future<void> _pick(KycDoc doc) async {
    try {
      final file = await _choose();
      if (file == null || !mounted) return;
      setState(() => _picked[doc.field] = file);
    } catch (e) {
      if (mounted) context.showFailure(e);
    }
  }

  /// Replaces one document without resubmitting the whole record.
  ///
  /// `PATCH /api/users/kyc/document/` exists precisely so a verified teacher
  /// can fill a gap without dropping back into review. It had no caller.
  Future<void> _replaceOne(KycDoc doc) async {
    try {
      final file = await _choose();
      if (file == null || !mounted) return;

      setState(() => _replacing = doc.field);
      await ref.read(usersRepositoryProvider).uploadKycDocument(
            field: doc.field,
            file: UploadFile(
              bytes: await file.readAsBytes(),
              filename: file.name,
            ),
          );
      if (!mounted) return;
      ref.invalidate(kycStatusProvider);
      context.showMessage('${doc.label} sent for checking.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _replacing = null);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repo = ref.read(usersRepositoryProvider);

    try {
      // The server rejects documents outright if terms were never accepted, so
      // record acceptance first rather than letting the upload fail.
      await repo.acceptTerms();
      await repo.submitKyc({
        for (final entry in _picked.entries)
          entry.key: UploadFile(
            bytes: await entry.value.readAsBytes(),
            filename: entry.value.name,
          ),
      });
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
    final tone = status.isVerified
        ? Tone.success
        : status.isRejected
            ? Tone.critical
            : status.isPending
                ? Tone.info
                : Tone.warning;

    return NoteBox(
      tone: tone,
      icon: status.isVerified
          ? Icons.verified_rounded
          : status.isRejected
              ? Icons.error_outline_rounded
              : Icons.shield_outlined,
      title: status.shortLabel,
      message: status.isVerified
          ? 'Families see an ID-verified badge on your profile. You can still '
              'add a certificate you have newly earned.'
          : (status.nextStep ?? 'Our team is checking your documents.'),
    );
  }
}

// ── One document row ─────────────────────────────────────────────────────────

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.doc,
    required this.picked,
    required this.status,
    required this.frozen,
    required this.busy,
    required this.onPick,
    required this.onClear,
    this.onReplaceNow,
  });

  final KycDoc doc;
  final XFile? picked;
  final KycStatus status;
  final bool frozen;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  /// Set only when a single-document replace is allowed.
  final VoidCallback? onReplaceNow;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final attached = picked != null;
    final verified = status.isDocVerified(doc.verifiedField);
    final onFile = status.hasDoc(doc.field);
    final needsAgain = status.needsResubmit(doc.field);

    final tone = needsAgain
        ? Tone.critical
        : verified
            ? Tone.success
            : attached
                ? Tone.info
                : Tone.neutral;

    return THTCard(
      onTap: busy ? null : (onReplaceNow ?? (attached ? null : onPick)),
      borderColor: tone == Tone.neutral ? null : tone.border(brightness),
      child: Row(
        children: [
          _Thumb(picked: picked, brightness: brightness, doc: doc),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doc.label,
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
                    if (doc.required) ...[
                      const SizedBox(width: 5),
                      Text(
                        '*',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Tone.critical.foreground(brightness),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(attached, verified, onFile, needsAgain),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: tone == Tone.neutral
                        ? muted
                        : tone.foreground(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (verified)
            Icon(
              Icons.verified_rounded,
              size: 20,
              color: Tone.success.foreground(brightness),
            )
          else if (attached)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Remove',
            )
          else
            TextButton(
              onPressed: onReplaceNow ?? onPick,
              child: Text(onFile ? 'Replace' : 'Add'),
            ),
        ],
      ),
    );
  }

  String _subtitle(bool attached, bool verified, bool onFile, bool needsAgain) {
    if (needsAgain) return 'Our team asked for this one again';
    if (verified) return 'Verified by our team';
    if (attached) return 'Ready to send';
    if (onFile) return 'Uploaded — waiting to be checked';
    return doc.hint;
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.picked,
    required this.brightness,
    required this.doc,
  });

  final XFile? picked;
  final Brightness brightness;
  final KycDoc doc;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final file = picked;

    if (file == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(doc.icon, size: 20, color: AppColors.slate400),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 44,
        height: 44,
        // Rendered from bytes rather than a path, so the thumbnail works in a
        // browser too — on web the picked file has a blob URL that `File`
        // cannot open.
        child: FutureBuilder<Uint8List>(
          future: file.readAsBytes(),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) return _placeholder();
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Tone.success.background(brightness),
        child: Icon(
          Icons.check_rounded,
          color: Tone.success.foreground(brightness),
        ),
      );
}

// ── Terms ────────────────────────────────────────────────────────────────────

class _TermsCheck extends StatelessWidget {
  const _TermsCheck({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'I confirm these documents are mine and accept the Terms & '
                  'Conditions.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? AppColors.slate300 : AppColors.slate600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
