import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/network/token_storage.dart';

/// Represents the data collected during the Job Wizard flow.
class JobWizardState {
  const JobWizardState({
    this.studentName = '',
    this.studentGender = '',
    this.tutorGenderPreference = 'Any',
    this.tuitionMode = 'HOME',
    this.classGrade = '',
    this.board = '',
    this.subjects = const [],
    this.city = 'Lucknow',
    this.locality = '',
    this.detailedAddress = '',
    this.daysPerWeek = '',
    this.preferredTime = '',
    this.budgetRange = '',
    this.hourlyRate = '',
    this.requirements = '',
    this.parentWhatsappNumber = '',
    this.allowContact = true,
    this.allowPayPerLead = true,
    this.maxContactUnlocks = 0,
    
    // Master data
    this.masterSubjects = const [],
    this.masterBoards = const [],
    this.masterClasses = const [],
    this.masterLocations = const [],
    this.isLoadingMasterData = true,
    this.error,
  });

  final String studentName;
  final String studentGender;
  final String tutorGenderPreference;
  final String tuitionMode;
  final String classGrade;
  final String board;
  final List<String> subjects;
  final String city;
  final String locality;
  final String detailedAddress;
  final String daysPerWeek;
  final String preferredTime;
  final String budgetRange;
  final String hourlyRate;
  final String requirements;
  final String parentWhatsappNumber;

  // ── How teachers reach this family ────────────────────────────────────────
  //
  // Three arrangements, one choice on the form:
  //
  //   direct    allowContact + allowPayPerLead  — teachers buy the contact and
  //                                               come to you; no commission
  //   screened  allowContact only               — THT screens and introduces
  //   private   neither                         — apply only, we handle it all
  //
  // The parent never sees what a teacher pays; the server strips that field on
  // their side entirely.

  final bool allowContact;
  final bool allowPayPerLead;

  /// How many teachers may buy this contact. 0 is unlimited.
  final int maxContactUnlocks;

  final List<dynamic> masterSubjects;
  final List<dynamic> masterBoards;
  final List<dynamic> masterClasses;
  final List<dynamic> masterLocations;
  final bool isLoadingMasterData;
  final String? error;

  JobWizardState copyWith({
    String? studentName,
    String? studentGender,
    String? tutorGenderPreference,
    String? tuitionMode,
    String? classGrade,
    String? board,
    List<String>? subjects,
    String? city,
    String? locality,
    String? detailedAddress,
    String? daysPerWeek,
    String? preferredTime,
    String? budgetRange,
    String? hourlyRate,
    String? requirements,
    String? parentWhatsappNumber,
    bool? allowContact,
    bool? allowPayPerLead,
    int? maxContactUnlocks,
    List<dynamic>? masterSubjects,
    List<dynamic>? masterBoards,
    List<dynamic>? masterClasses,
    List<dynamic>? masterLocations,
    bool? isLoadingMasterData,
    String? error,
  }) {
    return JobWizardState(
      studentName: studentName ?? this.studentName,
      studentGender: studentGender ?? this.studentGender,
      tutorGenderPreference: tutorGenderPreference ?? this.tutorGenderPreference,
      tuitionMode: tuitionMode ?? this.tuitionMode,
      classGrade: classGrade ?? this.classGrade,
      board: board ?? this.board,
      subjects: subjects ?? this.subjects,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      preferredTime: preferredTime ?? this.preferredTime,
      budgetRange: budgetRange ?? this.budgetRange,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      requirements: requirements ?? this.requirements,
      parentWhatsappNumber: parentWhatsappNumber ?? this.parentWhatsappNumber,
      allowContact: allowContact ?? this.allowContact,
      allowPayPerLead: allowPayPerLead ?? this.allowPayPerLead,
      maxContactUnlocks: maxContactUnlocks ?? this.maxContactUnlocks,
      masterSubjects: masterSubjects ?? this.masterSubjects,
      masterBoards: masterBoards ?? this.masterBoards,
      masterClasses: masterClasses ?? this.masterClasses,
      masterLocations: masterLocations ?? this.masterLocations,
      isLoadingMasterData: isLoadingMasterData ?? this.isLoadingMasterData,
      error: error,
    );
  }

  /// Cities the backend knows about, in the order it returned them.
  ///
  /// Beats a hardcoded list: an admin adding a city makes it selectable here
  /// without an app release.
  List<String> get cities => masterLocations
      .map((l) => (l is Map ? l['city'] : null)?.toString() ?? '')
      .where((c) => c.isNotEmpty)
      .toList();

  /// Named areas within [city].
  ///
  /// These ride along inside `locations` — `LocationSerializer` nests each
  /// city's `localities` — so they cost no extra request. Empty means none are
  /// seeded for that city, and the form should fall back to free text.
  List<String> localitiesFor(String city) {
    final match = masterLocations.firstWhere(
      (l) => l is Map && '${l['city']}'.toLowerCase() == city.toLowerCase(),
      orElse: () => null,
    );
    if (match is! Map) return const [];
    final raw = match['localities'];
    if (raw is! List) return const [];
    return raw
        .where((e) => e is Map && e['is_active'] != false)
        .map((e) => '${(e as Map)['name']}')
        .where((n) => n.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'student_name': studentName,
      'student_gender': studentGender,
      'tutor_gender_preference': tutorGenderPreference,
      'tuition_mode': tuitionMode,
      'class_grade': classGrade,
      'board': board,
      'subjects': subjects,
      'city': city,
      'locality': locality,
      'detailed_address': detailedAddress,
      'days_per_week': daysPerWeek,
      'preferred_time': preferredTime,
      'budget_range': budgetRange,
      'hourly_rate': hourlyRate,
      'requirements': requirements,
      'parent_whatsapp_number': parentWhatsappNumber,
      // How teachers may reach this family. Defaults to the open arrangement
      // so a requirement posted from the app is buyable — that is what gets it
      // in front of teachers fastest, and the parent can narrow it.
      'allow_contact': allowContact,
      'allow_pay_per_lead': allowPayPerLead,
      'max_contact_unlocks': maxContactUnlocks,
    };
  }
}

class JobWizardNotifier extends StateNotifier<JobWizardState> {
  /// [initialState] skips the master-data fetch, for tests and previews that
  /// supply their own subjects, boards and locations.
  JobWizardNotifier({JobWizardState? initialState})
      : super(initialState ?? const JobWizardState()) {
    if (initialState == null) _init();
  }

  Future<void> _init() async {
    try {
      final response = await ApiClient.instance.get('/api/jobs/master/');
      final data = response.data;
      
      final phone = await TokenStorage.getPhone();
      
      state = state.copyWith(
        masterSubjects: data['subjects'] ?? [],
        masterBoards: data['boards'] ?? [],
        masterClasses: data['class_levels'] ?? [],
        masterLocations: data['locations'] ?? [],
        parentWhatsappNumber: phone ?? '',
        isLoadingMasterData: false,
      );
    } catch (e) {
      // Fallback data if API fails (matching React implementation)
      state = state.copyWith(
        masterSubjects: [
          {'id': 1, 'name': 'Maths'},
          {'id': 2, 'name': 'Science'},
          {'id': 3, 'name': 'English'},
        ],
        masterBoards: [
          {'id': 1, 'name': 'CBSE', 'short_name': 'CBSE'},
          {'id': 2, 'name': 'ICSE', 'short_name': 'ICSE'},
          {'id': 4, 'name': 'State Board', 'short_name': 'State'},
        ],
        masterClasses: List.generate(12, (i) => {'id': i + 1, 'name': 'Class ${i + 1}'}),
        isLoadingMasterData: false,
        error: 'Failed to load master data. Using defaults.',
      );
    }
  }

  void updateField({
    String? studentName,
    String? studentGender,
    String? tutorGenderPreference,
    String? tuitionMode,
    String? classGrade,
    String? board,
    List<String>? subjects,
    String? city,
    String? locality,
    String? detailedAddress,
    String? daysPerWeek,
    String? preferredTime,
    String? budgetRange,
    String? hourlyRate,
    String? requirements,
    String? parentWhatsappNumber,
    bool? allowContact,
    bool? allowPayPerLead,
    int? maxContactUnlocks,
  }) {
    state = state.copyWith(
      studentName: studentName,
      studentGender: studentGender,
      tutorGenderPreference: tutorGenderPreference,
      tuitionMode: tuitionMode,
      classGrade: classGrade,
      board: board,
      subjects: subjects,
      city: city,
      locality: locality,
      detailedAddress: detailedAddress,
      daysPerWeek: daysPerWeek,
      preferredTime: preferredTime,
      budgetRange: budgetRange,
      hourlyRate: hourlyRate,
      requirements: requirements,
      parentWhatsappNumber: parentWhatsappNumber,
      allowContact: allowContact,
      allowPayPerLead: allowPayPerLead,
      maxContactUnlocks: maxContactUnlocks,
    );

    // Dynamic pricing check
    if (classGrade != null) {
      _applyDynamicPricing(classGrade);
    }
  }

  /// A hobby or "other" class has no school board — music, art, spoken English
  /// and the like. The pricing rules already branch on this; the form has to
  /// branch on the same test or the two disagree.
  static bool isBoardless(String classGrade) {
    final lower = classGrade.toLowerCase();
    return lower.contains('hobby') || lower.contains('other');
  }

  void _applyDynamicPricing(String classGrade) {
    final lower = classGrade.toLowerCase();
    String budget = 'Negotiable based on requirements';
    
    if (lower.contains('hobby') || lower.contains('other')) {
      budget = 'Negotiable based on hobby type';
      state = state.copyWith(budgetRange: budget, hourlyRate: '', board: '');
      return;
    }

    if (lower.contains('nursery') || lower.contains('lkg') || lower.contains('ukg') || 
        lower.contains('class 1') || lower.contains('class 2') || lower.contains('class 3') || 
        lower.contains('class 4') || lower.contains('class 5')) {
      budget = '₹3,500 - ₹5,000 / month (6 days a week)';
    } else if (lower.contains('class 6') || lower.contains('class 7') || lower.contains('class 8')) {
      budget = '₹4,500 - ₹5,000 / month (6 days a week)';
    } else if (lower.contains('class 9') || lower.contains('class 10')) {
      budget = '₹6,000 - ₹7,000 / month (6 days a week)';
    } else if (lower.contains('class 11') || lower.contains('class 12')) {
      budget = '₹7,000 - ₹9,000 / month (per subject, 3 days a week)';
    } else if (lower.contains('jee') || lower.contains('neet')) {
      budget = '₹8,000 - ₹10,000 / month (per subject, 3 days a week)';
    }

    state = state.copyWith(budgetRange: budget, hourlyRate: '');
  }

  Future<bool> submitJob() async {
    try {
      await ApiClient.instance.post('/api/jobs/create/', data: state.toJson());
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: e.response?.data?.toString() ?? 'Failed to create job');
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final jobWizardProvider = StateNotifierProvider.autoDispose<JobWizardNotifier, JobWizardState>((ref) {
  return JobWizardNotifier();
});
