import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/features/explore/providers/tutor_search_provider.dart';
import 'package:tht_app/features/explore/widgets/tutor_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(tutorSearchProvider.notifier).loadMore();
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Tutors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by subject or skill...',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                isDark ? Colors.black26 : Colors.grey[200],
              ),
              onChanged: (val) {
                ref.read(tutorSearchProvider.notifier).updateFilters(query: val);
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(tutorSearchProvider.notifier).refresh();
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(TutorSearchState state) {
    if (state.isLoading && state.tutors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.tutors.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.slate400),
            const SizedBox(height: 16),
            const Text(
              'No tutors found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters.',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.slate400 : AppColors.slate600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.tutors.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.tutors.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tutor = state.tutors[index] as Map<String, dynamic>;
        return TutorCard(tutor: tutor);
      },
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorSearchProvider);
    final notifier = ref.read(tutorSearchProvider.notifier);

    // Get cities for currently selected state
    final cities = SearchConstants.locationData[state.stateName] ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    notifier.updateFilters(
                      subject: '', classGrade: '', stateName: 'Uttar Pradesh', city: 'Lucknow', mode: ''
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.primaryOrange)),
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Subject',
              state.subject,
              ['', ...SearchConstants.subjects],
              (val) => notifier.updateFilters(subject: val ?? ''),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Class / Grade',
              state.classGrade,
              ['', ...SearchConstants.classes],
              (val) => notifier.updateFilters(classGrade: val ?? ''),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'State',
              state.stateName,
              SearchConstants.locationData.keys.toList(),
              (val) {
                if (val != null) {
                  final newCities = SearchConstants.locationData[val] ?? [];
                  notifier.updateFilters(
                    stateName: val,
                    city: newCities.isNotEmpty ? newCities.first : '',
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'City',
              state.city,
              ['', ...cities],
              (val) => notifier.updateFilters(city: val ?? ''),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Teaching Mode',
              state.mode,
              ['', 'HOME', 'ONLINE', 'BOTH'],
              (val) => notifier.updateFilters(mode: val ?? ''),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value.isEmpty ? null : value,
              hint: const Text('Any'),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.isEmpty ? null : item,
                  child: Text(item.isEmpty ? 'Any' : item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
