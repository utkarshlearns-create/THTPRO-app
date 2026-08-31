import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/providers/master_data_provider.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Narrowing the job feed.
///
/// A side panel rather than a bottom sheet: there are seven filters here, and a
/// sheet tall enough to hold them covers the results a teacher is filtering.
/// Sliding in from the right leaves the feed visible behind it.
///
/// Everything is a dropdown. Chip grids meant scrolling a wall of options to
/// find one locality among dozens; a dropdown is one tap and a searchable list.
class JobFilterPanel extends ConsumerStatefulWidget {
  const JobFilterPanel({super.key, required this.initial});

  final JobFilters initial;

  /// Slides in from the right. Returns the chosen filters, or null if dismissed.
  static Future<JobFilters?> show(BuildContext context, JobFilters initial) =>
      showGeneralDialog<JobFilters>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Filters',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => JobFilterPanel(initial: initial),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          );
        },
      );

  @override
  ConsumerState<JobFilterPanel> createState() => _JobFilterPanelState();
}

class _JobFilterPanelState extends ConsumerState<JobFilterPanel> {
  late JobFilters _draft = widget.initial;

  static const _modes = {
    'HOME': 'At home',
    'ONLINE_ONE_TO_ONE': 'Online, one-to-one',
    'ONLINE_GROUP': 'Online, group',
    'INSTITUTION': 'At a centre',
    'BOTH': 'Home or online',
  };

  /// True when every filter matches what the teacher's own profile says.
  bool _matchesProfile(TutorProfile p) =>
      _draft.subject == _firstOrNull(p.subjects) &&
      _draft.grade == _firstOrNull(p.classes) &&
      _draft.board == _firstOrNull(p.preferredBoards) &&
      _draft.locality == _firstOrNull(p.preferredLocations) &&
      (_draft.city ?? '') == p.city &&
      _draft.gender != null;

  static String? _firstOrNull(List<String> xs) => xs.isEmpty ? null : xs.first;

  /// Fills the panel from the teacher's profile in one tap.
  ///
  /// Uses only what they have actually set — a teacher with no preferred areas
  /// gets no locality filter rather than an invented one.
  void _applyProfile(TutorProfile p) {
    setState(() {
      _draft = _draft.copyWith(
        subject: () => _firstOrNull(p.subjects),
        grade: () => _firstOrNull(p.classes),
        board: () => _firstOrNull(p.preferredBoards),
        locality: () => _firstOrNull(p.preferredLocations),
        city: () => p.city.isEmpty ? null : p.city,
        gender: () => p.gender.trim().isEmpty ? null : p.gender.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final master = ref.watch(masterDataProvider).valueOrNull;
    final profile = ref.watch(tutorProfileProvider).valueOrNull;

    final cities = (_draft.state == null
            ? SearchConstants.locationData.values.expand((c) => c)
            : (SearchConstants.locationData[_draft.state!] ?? const <String>[]))
        .toSet()
        .toList()
      ..sort();

    final localities = SearchConstants.locationData.values
        .expand((c) => c)
        .toSet()
        .toList()
      ..sort();

    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        // Not full width: the strip of feed left visible is what tells the
        // teacher this is a filter over their results, not a new screen.
        widthFactor: 0.9,
        child: Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                _header(isDark),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (profile != null) ...[
                        _preferenceToggle(profile, isDark),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _Dropdown(
                        label: 'Subject',
                        value: _draft.subject,
                        options: master?.subjects ?? SearchConstants.subjects,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(subject: () => v),
                        ),
                      ),
                      _Dropdown(
                        label: 'Class',
                        value: _draft.grade,
                        options: master?.classes ?? SearchConstants.classes,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(grade: () => v),
                        ),
                      ),
                      _Dropdown(
                        label: 'Board',
                        value: _draft.board,
                        options: master?.boards ?? const [],
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(board: () => v),
                        ),
                      ),
                      _Dropdown(
                        label: 'Teaching mode',
                        value: _draft.mode,
                        options: _modes.keys.toList(),
                        labelFor: (k) => _modes[k] ?? k,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(mode: () => v),
                        ),
                      ),
                      _Dropdown(
                        label: 'State',
                        value: _draft.state,
                        options: SearchConstants.locationData.keys.toList(),
                        onChanged: (v) => setState(() {
                          // The chosen city may not belong to the new state.
                          _draft = _draft.copyWith(
                            state: () => v,
                            city: () => null,
                          );
                        }),
                      ),
                      _Dropdown(
                        label: 'City',
                        value: _draft.city,
                        options: cities,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(city: () => v),
                        ),
                      ),
                      _Dropdown(
                        label: 'Area',
                        value: _draft.locality,
                        options: localities,
                        searchable: true,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(locality: () => v),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile.adaptive(
                        value: _draft.unappliedOnly,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(unappliedOnly: v),
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Hide jobs I have applied to',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        value: _draft.buyableOnly,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(buyableOnly: v),
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Only leads I can buy',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // The server has no parameter for this, so it narrows
                        // what has already been fetched. Saying so is kinder
                        // than a list that looks empty for no visible reason.
                        subtitle: const Text(
                          'Filters the jobs already loaded — scroll for more',
                          style: TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                _footer(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
            ),
            if (_draft.activeCount > 0)
              TextButton(
                onPressed: () => setState(
                  () => _draft = JobFilters(query: _draft.query),
                ),
                child: const Text('Clear all'),
              ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
          ],
        ),
      );

  Widget _preferenceToggle(TutorProfile p, bool isDark) {
    final on = _matchesProfile(p);
    final brightness = Theme.of(context).brightness;

    // Nothing to match against — a teacher who has set no subjects, areas or
    // boards would get an empty filter and wonder why nothing happened.
    if (p.subjects.isEmpty &&
        p.preferredLocations.isEmpty &&
        p.preferredBoards.isEmpty) {
      return const NoteBox(
        tone: Tone.info,
        message: 'Set your subjects and the areas you cover in your profile, '
            'and you can filter the feed to them in one tap.',
      );
    }

    return InkWell(
      onTap: () => on
          ? setState(() => _draft = JobFilters(query: _draft.query))
          : _applyProfile(p),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: on ? Tone.success.background(brightness) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: on
                ? Tone.success.foreground(brightness)
                : (isDark ? AppColors.darkBorder : AppColors.slate200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_pin_circle_outlined,
              size: 20,
              color: on
                  ? Tone.success.foreground(brightness)
                  : (isDark ? AppColors.slate400 : AppColors.slate500),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show as per my preference',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fills these from your profile — your subjects, classes, '
                    'boards and areas.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: on,
              onChanged: (v) => v
                  ? _applyProfile(p)
                  : setState(() => _draft = JobFilters(query: _draft.query)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(bool isDark) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.slate200,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_draft),
            child: Text(
              _draft.activeCount == 0
                  ? 'Show all jobs'
                  : 'Show jobs (${_draft.activeCount})',
            ),
          ),
        ),
      );
}

/// One filter, as a dropdown with a clear action.
class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelFor,
    this.searchable = false,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  /// Turns a stored value into what the teacher reads — modes are stored as
  /// `ONLINE_ONE_TO_ONE` and shown as "Online, one-to-one".
  final String Function(String)? labelFor;

  /// Long lists get a search field rather than a scroll.
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    // Anything already chosen stays selectable even if it has left the list,
    // so a saved filter never silently resets.
    final all = [
      ...options,
      if (value != null && !options.contains(value)) value!,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: InkWell(
        onTap: all.isEmpty
            ? null
            : () async {
                final picked = await _OptionPicker.show(
                  context,
                  title: label,
                  options: all,
                  selected: value,
                  labelFor: labelFor,
                  searchable: searchable || all.length > 12,
                );
                if (picked != null) onChanged(picked.isEmpty ? null : picked);
              },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null
                ? const Icon(Icons.expand_more_rounded, size: 20)
                : IconButton(
                    onPressed: () => onChanged(null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Clear $label',
                  ),
          ),
          child: Text(
            value == null ? 'Any' : (labelFor?.call(value!) ?? value!),
            style: TextStyle(
              fontSize: 15,
              fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The list a dropdown opens, with search when the list is long.
class _OptionPicker extends StatefulWidget {
  const _OptionPicker({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    this.labelFor,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final bool searchable;
  final String Function(String)? labelFor;

  /// Returns the chosen value, an empty string to clear, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? selected,
    required bool searchable,
    String Function(String)? labelFor,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _OptionPicker(
          title: title,
          options: options,
          selected: selected,
          searchable: searchable,
          labelFor: labelFor,
        ),
      );

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => (widget.labelFor?.call(o) ?? o)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: widget.searchable ? 0.75 : 0.5,
        maxChildSize: 0.92,
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
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.selected != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing matches "$_query"',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final o = shown[i];
                        final isSelected = o == widget.selected;
                        return ListTile(
                          title: Text(widget.labelFor?.call(o) ?? o),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, size: 20)
                              : null,
                          selected: isSelected,
                          onTap: () => Navigator.of(context).pop(o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
