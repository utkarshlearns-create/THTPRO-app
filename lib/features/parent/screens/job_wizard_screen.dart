import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';
import 'package:tht_app/features/parent/providers/job_wizard_provider.dart';

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
              title: const Text('Academics'),
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
                  const SizedBox(height: 16),
                  const Text('Board', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: state.board.isEmpty ? null : state.board,
                    hint: const Text('Select Board'),
                    items: state.masterBoards.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['name'],
                        child: Text(b['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(jobWizardProvider.notifier).updateField(board: val);
                    },
                  ),
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
              title: const Text('Location'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: state.city,
                    items: ['Lucknow', 'Delhi', 'Mumbai'].map((c) {
                      return DropdownMenuItem<String>(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      ref.read(jobWizardProvider.notifier).updateField(city: val);
                    },
                  ),
                  const SizedBox(height: 16),
                  ThtTextField(
                    controller: _localityController,
                    label: 'Locality / Area',
                    hint: 'e.g. Gomti Nagar',
                  ),
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
              title: const Text('Budget'),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      state.budgetRange.isNotEmpty ? state.budgetRange : 'Select a class grade to see estimate',
                      style: const TextStyle(color: AppColors.primaryOrangeDark, fontWeight: FontWeight.w600),
                    ),
                  ),
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
