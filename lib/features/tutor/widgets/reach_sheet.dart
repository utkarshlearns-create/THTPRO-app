import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/core/constants/time_slots.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/providers/master_data_provider.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Which part of a teacher's reach this sheet is editing.
enum ReachField { locations, boards, timeSlots }

/// The three list fields that decide which leads find a teacher.
///
/// All writable on `/api/users/profile/` and none of them editable in the app
/// before — areas and boards were read-only chips, and availability was not
/// even parsed.
class ReachSheet extends ConsumerStatefulWidget {
  const ReachSheet({super.key, required this.profile, required this.field});

  final TutorProfile profile;
  final ReachField field;

  static Future<void> show(
    BuildContext context,
    TutorProfile profile,
    ReachField field,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ReachSheet(profile: profile, field: field),
      );

  @override
  ConsumerState<ReachSheet> createState() => _ReachSheetState();
}

class _ReachSheetState extends ConsumerState<ReachSheet> {
  late final List<String> _selected = List.of(switch (widget.field) {
    ReachField.locations => widget.profile.preferredLocations,
    ReachField.boards => widget.profile.preferredBoards,
    ReachField.timeSlots => widget.profile.availableTimeSlots,
  });

  bool _saving = false;
  String? _error;

  String get _title => switch (widget.field) {
        ReachField.locations => 'Areas you cover',
        ReachField.boards => 'Boards you teach',
        ReachField.timeSlots => 'When you are free',
      };

  String get _blurb => switch (widget.field) {
        ReachField.locations =>
          'Leads in these areas reach you. Pick everywhere you can realistically '
              'travel to — an area you leave off is a lead you never see.',
        ReachField.boards =>
          'Leave this empty if you are happy with any board.',
        ReachField.timeSlots =>
          'Families are matched to teachers free at the hour they want. Pick '
              '"Flexible" if your timings are open.',
      };

  String get _apiField => switch (widget.field) {
        ReachField.locations => 'preferred_locations',
        ReachField.boards => 'preferred_boards',
        ReachField.timeSlots => 'available_time_slots',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      _title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _options(controller, isDark)),
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
                        : Text(
                            _selected.isEmpty
                                ? 'Save'
                                : 'Save ${_selected.length}',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _options(ScrollController controller, bool isDark) {
    // Only boards need fetching; the other two are fixed vocabularies.
    if (widget.field != ReachField.boards) {
      return _list(controller, isDark, _staticOptions);
    }

    return AsyncView<MasterData>(
      value: ref.watch(masterDataProvider),
      onRetry: () => ref.invalidate(masterDataProvider),
      data: (data) => _list(controller, isDark, data.boards),
    );
  }

  List<String> get _staticOptions => switch (widget.field) {
        // Every locality we serve, flattened out of the state → cities map.
        ReachField.locations =>
          SearchConstants.locationData.values.expand((c) => c).toSet().toList()
            ..sort(),
        ReachField.timeSlots => TimeSlots.all,
        ReachField.boards => const [],
      };

  Widget _list(ScrollController controller, bool isDark, List<String> options) {
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    // Anything already saved stays offered even if it has since left the master
    // list — dropping a teacher's own choice silently is worse than showing an
    // option we no longer suggest.
    final all = [
      ...options,
      ..._selected.where((s) => !options.contains(s)),
    ];

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          _blurb,
          style: TextStyle(fontSize: 13, height: 1.5, color: muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.field == ReachField.locations && _selected.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.base),
            child: NoteBox(
              tone: Tone.warning,
              message: 'With no areas set, nearby leads will not find you.',
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in all)
              FilterChip(
                label: Text(option),
                selected: _selected.contains(option),
                onSelected: (_) => setState(() {
                  _selected.contains(option)
                      ? _selected.remove(option)
                      : _selected.add(option);
                }),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          NoteBox(message: _error!),
        ],
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(usersRepositoryProvider)
          .updateTutorProfile({_apiField: _selected});
      if (!mounted) return;
      ref.invalidate(tutorProfileProvider);
      Navigator.of(context).pop();
      context.showMessage('Saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }
}
