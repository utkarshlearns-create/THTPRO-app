import 'package:flutter/material.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';

/// The filter sheet for the job feed.
///
/// Edits a local copy and only commits on "Show jobs", so a half-set filter
/// never reloads the list underneath the sheet.
class JobFilterSheet extends StatefulWidget {
  const JobFilterSheet({super.key, required this.initial});

  final JobFilters initial;

  /// Returns the chosen filters, or null if dismissed.
  static Future<JobFilters?> show(BuildContext context, JobFilters initial) =>
      showModalBottomSheet<JobFilters>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => JobFilterSheet(initial: initial),
      );

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late JobFilters _draft = widget.initial;

  static const _modes = {
    'HOME': 'At home',
    'ONLINE_ONE_TO_ONE': 'Online, one-to-one',
    'ONLINE_GROUP': 'Online, group',
    'INSTITUTION': 'At a centre',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cities = SearchConstants.locationData.values.expand((c) => c).toList()
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
                    'Filter jobs',
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
                        selected: _draft.grade == c,
                        onTap: () => setState(() => _draft = _draft.copyWith(
                              grade: () => _draft.grade == c ? null : c,
                            )),
                      ),
                  ],
                ),
                _Group(
                  label: 'Teaching mode',
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
                  value: _draft.unappliedOnly,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(unappliedOnly: v)),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hide jobs I have applied to',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
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
                        ? 'Show all jobs'
                        : 'Show jobs (${_draft.activeCount} filter${_draft.activeCount == 1 ? '' : 's'})',
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
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: children),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primaryOrangeDark : null,
      ),
      selectedColor: AppColors.primaryOrangeLight,
      side: selected
          ? const BorderSide(color: AppColors.primaryOrange)
          : BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.slate200,
            ),
    );
  }
}
