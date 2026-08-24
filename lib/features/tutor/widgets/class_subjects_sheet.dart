import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/providers/master_data_provider.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// What the teacher teaches, class by class.
///
/// This edits `class_subjects` — the writable field. `subjects` and `classes`
/// are in the serializer's `read_only_fields`, so the app used to show them
/// with "Set on the website" and leave a teacher unable to change the one thing
/// every job match runs on.
class ClassSubjectsSheet extends ConsumerStatefulWidget {
  const ClassSubjectsSheet({super.key, required this.profile});

  final TutorProfile profile;

  static Future<void> show(BuildContext context, TutorProfile profile) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ClassSubjectsSheet(profile: profile),
      );

  @override
  ConsumerState<ClassSubjectsSheet> createState() => _ClassSubjectsSheetState();
}

class _ClassSubjectsSheetState extends ConsumerState<ClassSubjectsSheet> {
  late final Map<String, List<String>> _draft = {
    for (final entry in widget.profile.classSubjects.entries)
      entry.key: List.of(entry.value),
  };

  bool _saving = false;
  String? _error;

  /// Classes carrying no subject yet. Saving one teaches nothing, so the sheet
  /// says which before it lets the teacher out.
  List<String> get _empties =>
      _draft.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final master = ref.watch(masterDataProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'What you teach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AsyncView<MasterData>(
                value: master,
                onRetry: () => ref.invalidate(masterDataProvider),
                data: (data) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: _body(data, isDark),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(MasterData data, bool isDark) {
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final remaining =
        data.classes.where((c) => !_draft.containsKey(c)).toList();

    return [
      Text(
        'Pick a class, then the subjects you teach in it. This is what we '
        'match you to — a job outside your list will not reach you.',
        style: TextStyle(fontSize: 13, height: 1.5, color: muted),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_draft.isEmpty)
        const NoteBox(
          tone: Tone.warning,
          message: 'You have not added any classes yet, so no job matches you '
              'at the moment.',
        )
      else
        for (final className in _draft.keys.toList())
          _ClassBlock(
            className: className,
            selected: _draft[className]!,
            options: data.subjects,
            onToggle: (subject) => setState(() {
              final list = _draft[className]!;
              list.contains(subject) ? list.remove(subject) : list.add(subject);
            }),
            onRemove: () => setState(() => _draft.remove(className)),
          ),
      const SizedBox(height: AppSpacing.md),
      if (remaining.isEmpty && data.classes.isNotEmpty)
        Text(
          'Every class is on your list.',
          style: TextStyle(fontSize: 12.5, color: muted),
        )
      else
        OutlinedButton.icon(
          onPressed: () => _addClass(remaining),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add a class'),
        ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        NoteBox(message: _error!),
      ],
    ];
  }

  Future<void> _addClass(List<String> options) async {
    if (options.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Add a class',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),
            for (final option in options)
              ListTile(
                title: Text(option),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _draft[picked] = <String>[]);
    }
  }

  Future<void> _save() async {
    final empties = _empties;
    if (empties.isNotEmpty) {
      setState(() => _error = empties.length == 1
          ? 'Pick at least one subject for ${empties.first}, or remove it.'
          : 'These have no subjects yet: ${empties.join(', ')}.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(usersRepositoryProvider)
          .updateTutorProfile({'class_subjects': _draft});
      if (!mounted) return;
      // `subjects` and `classes` are derived server-side from what we just
      // sent, so the cached profile is stale in three fields, not one.
      ref.invalidate(tutorProfileProvider);
      Navigator.of(context).pop();
      context.showMessage('Updated what you teach.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }
}

class _ClassBlock extends StatelessWidget {
  const _ClassBlock({
    required this.className,
    required this.selected,
    required this.options,
    required this.onToggle,
    required this.onRemove,
  });

  final String className;
  final List<String> selected;
  final List<String> options;
  final ValueChanged<String> onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Anything already on the teacher's list stays offered even if it is not in
    // the master list any more — removing it silently would drop a subject they
    // chose deliberately.
    final all = [
      ...options,
      ...selected.where((s) => !options.contains(s)),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  className,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Remove $className',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final subject in all)
                FilterChip(
                  label: Text(subject),
                  selected: selected.contains(subject),
                  onSelected: (_) => onToggle(subject),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
