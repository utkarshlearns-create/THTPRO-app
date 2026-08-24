import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/board_logo.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';
import 'package:tht_app/features/parent/providers/job_wizard_provider.dart';
import 'package:tht_app/features/parent/widgets/locality_picker.dart';

class JobWizardScreen extends ConsumerStatefulWidget {
  const JobWizardScreen({super.key});

  @override
  ConsumerState<JobWizardScreen> createState() => _JobWizardScreenState();
}

class _JobWizardScreenState extends ConsumerState<JobWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Controllers for text inputs
  final _studentNameController = TextEditingController();
  final _localityController = TextEditingController();
  final _addressController = TextEditingController();
  final _requirementsController = TextEditingController();

  @override
  void dispose() {
    _studentNameController.dispose();
    _localityController.dispose();
    _addressController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Basic validation before proceeding
    final state = ref.read(jobWizardProvider);
    if (_currentStep == 0) {
      if (_studentNameController.text.trim().isEmpty) {
        _showError('Please enter student name');
        return;
      }
      ref.read(jobWizardProvider.notifier).updateField(studentName: _studentNameController.text.trim());
    }
    
    if (_currentStep == 1) {
      if (state.classGrade.isEmpty || state.subjects.isEmpty) {
        _showError('Please select class and at least one subject');
        return;
      }
    }

    if (_currentStep == 2) {
      if (_localityController.text.trim().isEmpty) {
        _showError('Please enter locality');
        return;
      }
      ref.read(jobWizardProvider.notifier).updateField(
        locality: _localityController.text.trim(),
        detailedAddress: _addressController.text.trim(),
      );
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  Future<void> _submit() async {
    ref.read(jobWizardProvider.notifier).updateField(
      requirements: _requirementsController.text.trim(),
    );

    setState(() => _isSubmitting = true);
    final success = await ref.read(jobWizardProvider.notifier).submitJob();
    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!'), backgroundColor: AppColors.success),
        );
        context.pop();
        context.go('/parent-home');
      }
    } else {
      if (mounted) {
        final error = ref.read(jobWizardProvider).error;
        _showError(error ?? 'Failed to post job');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobWizardProvider);

    if (state.isLoadingMasterData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Tuition Requirement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _prevStep,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ThtButton(
                      label: _currentStep == 3 ? 'Post Job' : 'Next',
                      isLoading: _isSubmitting,
                      onPressed: details.onStepContinue,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ThtButton(
                        label: 'Back',
                        variant: ThtButtonVariant.outlined,
                        onPressed: _isSubmitting ? null : details.onStepCancel,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // STEP 1: Student Details
            Step(
              title: const Text('Basic'),
              isActive: _currentStep >= 0,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThtTextField(
                    controller: _studentNameController,
                    label: 'Student Name',
                    hint: 'Enter student name',
                  ),
                  const SizedBox(height: 16),
                  const Text('Student Gender', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['Male', 'Female'].map((g) {
                      return ChoiceChip(
                        label: Text(g),
                        selected: state.studentGender == g,
                        onSelected: (selected) {
                          if (selected) ref.read(jobWizardProvider.notifier).updateField(studentGender: g);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tutor Gender Preference', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['Any', 'Male', 'Female'].map((g) {
                      return ChoiceChip(
                        label: Text(g),
                        selected: state.tutorGenderPreference == g,
                        onSelected: (selected) {
                          if (selected) ref.read(jobWizardProvider.notifier).updateField(tutorGenderPreference: g);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tuition Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['HOME', 'ONLINE'].map((m) {
                      return ChoiceChip(
                        label: Text(m),
                        selected: state.tuitionMode == m,
                        onSelected: (selected) {
                          if (selected) ref.read(jobWizardProvider.notifier).updateField(tuitionMode: m);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // STEP 2: Academics
            Step(
              title: const Text('Class'),
              isActive: _currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Class / Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: state.classGrade.isEmpty ? null : state.classGrade,
                    hint: const Text('Select Class'),
                    items: state.masterClasses.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['name'],
                        child: Text(c['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(jobWizardProvider.notifier).updateField(classGrade: val);
                    },
                  ),
                  // A hobby class has no board, and picking one here used to be
                  // silently wiped when the pricing rules ran — so the question
                  // is not asked at all.
                  if (!JobWizardNotifier.isBoardless(state.classGrade)) ...[
                    const SizedBox(height: 16),
                    const Text('Board',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _BoardPicker(
                      boards: state.masterBoards,
                      selected: state.board,
                      onSelected: (val) => ref
                          .read(jobWizardProvider.notifier)
                          .updateField(board: val),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Subjects (Select multiple)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: state.masterSubjects.map((s) {
                      final name = s['name'] as String;
                      final isSelected = state.subjects.contains(name);
                      return FilterChip(
                        label: Text(name),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newSubjects = List<String>.from(state.subjects);
                          if (selected) {
                            newSubjects.add(name);
                          } else {
                            newSubjects.remove(name);
                          }
                          ref.read(jobWizardProvider.notifier).updateField(subjects: newSubjects);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // STEP 3: Location
            Step(
              title: const Text('Area'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
                  Builder(builder: (context) {
                    // From the master payload, not a hardcoded three: an admin
                    // adding a city should not need an app release.
                    final cities = state.cities.isEmpty
                        ? const ['Lucknow']
                        : state.cities;
                    final current =
                        cities.contains(state.city) ? state.city : cities.first;
                    return DropdownButtonFormField<String>(
                      initialValue: current,
                      items: cities
                          .map((c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        // An area belongs to a city, so changing the city has
                        // to drop the area with it.
                        _localityController.clear();
                        ref
                            .read(jobWizardProvider.notifier)
                            .updateField(city: val, locality: '');
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final areas = state.localitiesFor(state.city);
                    // Free text where the city has no seeded areas — the same
                    // fallback the website uses outside Lucknow.
                    if (areas.isEmpty) {
                      return ThtTextField(
                        controller: _localityController,
                        label: 'Locality / Area',
                        hint: 'e.g. Gomti Nagar',
                      );
                    }
                    return LocalityPicker(
                      value: state.locality,
                      options: areas,
                      city: state.city,
                      onChanged: (val) {
                        _localityController.text = val;
                        ref
                            .read(jobWizardProvider.notifier)
                            .updateField(locality: val);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  ThtTextField(
                    controller: _addressController,
                    label: 'Detailed Address',
                    hint: 'House No, Block, Landmark',
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // STEP 4: Budget & Schedule
            Step(
              title: const Text('Fees'),
              isActive: _currentStep >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Days Per Week', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: state.daysPerWeek.isEmpty ? null : state.daysPerWeek,
                    hint: const Text('Select Days'),
                    items: ['3 Days/Week', '4 Days/Week', '5 Days/Week', '6 Days/Week'].map((d) {
                      return DropdownMenuItem<String>(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      ref.read(jobWizardProvider.notifier).updateField(daysPerWeek: val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Budget Range (Auto-calculated)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Builder(builder: (context) {
                    // This wizard is parent-only, so it follows the scheme.
                    final primary = Theme.of(context).colorScheme.primary;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        state.budgetRange.isNotEmpty ? state.budgetRange : 'Select a class grade to see estimate',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ThtTextField(
                    controller: _requirementsController,
                    label: 'Specific Requirements (Optional)',
                    hint: 'Any other details for the tutor...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Board picker ─────────────────────────────────────────────────────────────

/// Boards as logo tiles rather than a dropdown of full legal names.
///
/// Two things were wrong with the dropdown it replaces. It listed
/// "Central Board of Secondary Education" where every parent says "CBSE", and
/// it submitted that full name — while the website submits `short_name`, so the
/// same board arrived in the database under two different strings depending on
/// where the requirement was posted. This sends what the website sends.
class _BoardPicker extends StatelessWidget {
  const _BoardPicker({
    required this.boards,
    required this.selected,
    required this.onSelected,
  });

  final List<dynamic> boards;

  /// The stored value — a short name such as `CBSE`.
  final String selected;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (boards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final raw in boards)
          if (raw is Map) _BoardTile(
            // Short name is the canonical value; fall back to the full name
            // for any board an admin adds without one.
            value: '${raw['short_name'] ?? ''}'.trim().isEmpty
                ? '${raw['name']}'
                : '${raw['short_name']}',
            fullName: '${raw['name']}',
            selected: selected,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.value,
    required this.fullName,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final String fullName;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isSelected = selected == value;
    final radius = BorderRadius.circular(AppRadius.md);

    return Semantics(
      button: true,
      selected: isSelected,
      // The tile shows the short name; the full one belongs to screen readers
      // and to anyone who does not recognise the initials.
      label: fullName,
      child: Material(
        color: isSelected
            ? primary.withValues(alpha: isDark ? 0.18 : 0.08)
            : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: () => onSelected(value),
          borderRadius: radius,
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? primary
                    : (isDark ? AppColors.darkBorder : AppColors.slate200),
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoardLogo(board: value, size: 40),
                const SizedBox(height: 7),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.2,
                    color: isSelected
                        ? primary
                        : (isDark ? AppColors.slate300 : AppColors.slate700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
