import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/states.dart';

/// Pick an area by searching, rather than typing it blind.
///
/// Lucknow alone has several hundred named localities, so a free-text box
/// produced "gomti nagar", "Gomtinagar" and "Gomti Ngr" for the same place —
/// and a teacher filtering by locality matches none of them.
///
/// The list comes from the master payload the wizard already loads: each
/// location carries its own `localities`, so this stays in step with whatever
/// an admin has seeded. A city with none seeded falls back to free text, which
/// is the same thing the website does outside Lucknow.
class LocalityPicker extends StatelessWidget {
  const LocalityPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.city,
  });

  final String value;

  /// Locality names for the selected city, in the order the API returned them.
  final List<String> options;

  final ValueChanged<String> onChanged;
  final String city;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final picked = await _LocalitySheet.show(
              context,
              options: options,
              city: city,
              current: value,
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Area / Locality',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              suffixIcon: Icon(
                hasValue ? Icons.edit_outlined : Icons.search_rounded,
                size: 20,
              ),
            ),
            child: Text(
              hasValue ? value : 'Search your area',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? null : muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: muted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                "Can't find your exact area? Pick the nearest one.",
                style: TextStyle(fontSize: 11.5, height: 1.4, color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── The sheet ────────────────────────────────────────────────────────────────

class _LocalitySheet extends StatefulWidget {
  const _LocalitySheet({
    required this.options,
    required this.city,
    required this.current,
  });

  final List<String> options;
  final String city;
  final String current;

  static Future<String?> show(
    BuildContext context, {
    required List<String> options,
    required String city,
    required String current,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _LocalitySheet(
          options: options,
          city: city,
          current: current,
        ),
      );

  @override
  State<_LocalitySheet> createState() => _LocalitySheetState();
}

class _LocalitySheetState extends State<_LocalitySheet> {
  late final _search = TextEditingController(text: '');
  late List<String> _matches = _rank('');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Exact match first, then prefix, then anything containing the query.
  ///
  /// Ranking rather than plain filtering matters here: typing "nagar" in
  /// Lucknow matches dozens of areas, and "Gomti Nagar" should not sit
  /// nineteenth behind every alphabetically earlier one.
  List<String> _rank(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return widget.options;

    int score(String option) {
      final o = option.toLowerCase();
      if (o == q) return 3;
      if (o.startsWith(q)) return 2;
      if (o.contains(q)) return 1;
      return 0;
    }

    final scored = widget.options
        .map((o) => (o, score(o)))
        .where((e) => e.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));

    return scored.map((e) => e.$1).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final typed = _search.text.trim();

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your area',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? AppColors.slate50 : AppColors.slate900,
                          ),
                        ),
                        Text(
                          'in ${widget.city}',
                          style: TextStyle(fontSize: 12.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _search,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Search area, e.g. Gomti Nagar',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: typed.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() => _matches = _rank(''));
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Clear',
                        ),
                ),
                onChanged: (q) => setState(() => _matches = _rank(q)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _matches.isEmpty
                  ? _NoMatch(
                      query: typed,
                      onUseAnyway: () => Navigator.of(context).pop(typed),
                    )
                  : ListView.separated(
                      controller: controller,
                      itemCount: _matches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final area = _matches[i];
                        final selected = area == widget.current;
                        return ListTile(
                          title: _Highlighted(text: area, query: typed),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(area),
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

/// Bolds the part of the name that matched, so a long list of similar areas is
/// scannable rather than a wall of near-identical text.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    const base = TextStyle(fontSize: 14.5);

    if (q.isEmpty) return Text(text, style: base);

    final index = text.toLowerCase().indexOf(q.toLowerCase());
    if (index < 0) return Text(text, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + q.length),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(index + q.length)),
        ],
      ),
    );
  }
}

/// Nothing matched — offer what they typed rather than a dead end.
///
/// The seeded list will never cover every colony, and refusing an area the
/// parent knows exists would block the whole form.
class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query, required this.onUseAnyway});

  final String query;
  final VoidCallback onUseAnyway;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off_outlined,
        title: 'No areas listed',
        message: 'Type your area name and we will use it as you write it.',
        compact: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.location_off_outlined,
            title: 'No match for "$query"',
            message: 'Use it anyway, or try a shorter search.',
            compact: true,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onUseAnyway,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Use "$query"'),
          ),
        ],
      ),
    );
  }
}
