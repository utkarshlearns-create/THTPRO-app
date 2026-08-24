import 'package:flutter/material.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/features/explore/providers/tutor_search_provider.dart';

/// Filters for the teacher list. Edits a draft and commits on confirm, so the
/// list underneath does not reload while the parent is still choosing.
class TutorFilterSheet extends StatefulWidget {
  const TutorFilterSheet({super.key, required this.initial});

  final TutorFilters initial;

  static Future<TutorFilters?> show(BuildContext context, TutorFilters initial) =>
      showModalBottomSheet<TutorFilters>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TutorFilterSheet(initial: initial),
      );

  @override
  State<TutorFilterSheet> createState() => _TutorFilterSheetState();
}

class _TutorFilterSheetState extends State<TutorFilterSheet> {
  late TutorFilters _draft = widget.initial;

  static const _modes = {
    'HOME': 'Comes to your home',
    'ONLINE': 'Teaches online',
    'BOTH': 'Either',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Picking a state narrows the cities to that state's, which is how the
    // location data is keyed. With no state chosen, every city is offered.
    final cities = (_draft.state == null
            ? SearchConstants.locationData.values.expand((c) => c)
            : (SearchConstants.locationData[_draft.state!] ?? const <String>[]))
        .toList()
      ..sort();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
                    'Filter teachers',
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
                      () => _draft = TutorFilters(query: _draft.query),
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
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _Group(
                  label: 'Subject',
                  children: [
                    for (final s in SearchConstants.subjects)
                      _Choice(
                        label: s,
                        selected: _draft.subject == s,
                        onTap: () => setState(() => _draft = _draft.copyWith(
                              subject: () => _draft.subject == s ? null : s,
                            )),
                      ),
                  ],
                ),
                _Group(
                  label: 'Class',
                  children: [
                    for (final c in SearchConstants.classes)
                      _Choice(
                        label: c,
                        selected: _draft.classGrade == c,
                        onTap: () => setState(() => _draft = _draft.copyWith(
                              classGrade: () =>
                                  _draft.classGrade == c ? null : c,
                            )),
                      ),
                  ],
                ),
                _Group(
                  label: 'How they teach',
                  children: [
                    for (final entry in _modes.entries)
                      _Choice(
                        label: entry.value,
                        selected: _draft.mode == entry.key,
                        onTap: () => setState(() => _draft = _draft.copyWith(
                              mode: () =>
                                  _draft.mode == entry.key ? null : entry.key,
                            )),
                      ),
                  ],
                ),
                _Group(
                  label: 'State',
                  children: [
                    for (final state in SearchConstants.locationData.keys)
                      _Choice(
                        label: state,
                        selected: _draft.state == state,
                        onTap: () => setState(() {
                          final clearing = _draft.state == state;
                          _draft = _draft.copyWith(
                            state: () => clearing ? null : state,
                            // The old city no longer belongs to this state.
                            city: () => null,
                          );
                        }),
                      ),
                  ],
                ),
                _Group(
                  label: 'City',
                  children: [
                    for (final city in cities)
                      _Choice(
                        label: city,
                        selected: _draft.city == city,
                        onTap: () => setState(() => _draft = _draft.copyWith(
                              city: () => _draft.city == city ? null : city,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  value: _draft.verifiedOnly,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(verifiedOnly: v)),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'ID-verified teachers only',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Their documents have been checked by our team.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: Text(
                    _draft.activeCount == 0
                        ? 'Show all teachers'
                        : 'Show teachers (${_draft.activeCount} filter'
                            '${_draft.activeCount == 1 ? '' : 's'})',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Resolved from the scheme, not a literal: this sheet is shared with the
    // parent side, where the primary colour is blue.
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? primary : null,
      ),
      selectedColor: primary.withValues(alpha: 0.12),
      side: selected
          ? BorderSide(color: primary)
          : BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.slate200,
            ),
    );
  }
}
