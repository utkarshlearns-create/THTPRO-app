import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/network/api_client.dart';

class TutorSearchState {
  const TutorSearchState({
    this.query = '',
    this.subject = '',
    this.classGrade = '',
    this.stateName = 'Uttar Pradesh',
    this.city = 'Lucknow',
    this.locality = '',
    this.mode = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.tutors = const [],
    this.error,
  });

  final String query;
  final String subject;
  final String classGrade;
  final String stateName;
  final String city;
  final String locality;
  final String mode;

  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final List<dynamic> tutors;
  final String? error;

  TutorSearchState copyWith({
    String? query,
    String? subject,
    String? classGrade,
    String? stateName,
    String? city,
    String? locality,
    String? mode,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    List<dynamic>? tutors,
    String? error,
  }) {
    return TutorSearchState(
      query: query ?? this.query,
      subject: subject ?? this.subject,
      classGrade: classGrade ?? this.classGrade,
      stateName: stateName ?? this.stateName,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      mode: mode ?? this.mode,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      tutors: tutors ?? this.tutors,
      error: error,
    );
  }
}

class TutorSearchNotifier extends StateNotifier<TutorSearchState> {
  TutorSearchNotifier() : super(const TutorSearchState()) {
    _fetchTutors(isLoadMore: false);
  }

  Timer? _debounce;
  CancelToken? _cancelToken;

  void updateFilters({
    String? query,
    String? subject,
    String? classGrade,
    String? stateName,
    String? city,
    String? locality,
    String? mode,
  }) {
    state = state.copyWith(
      query: query,
      subject: subject,
      classGrade: classGrade,
      stateName: stateName,
      city: city,
      locality: locality,
      mode: mode,
      currentPage: 1, // Reset to first page on filter change
    );

    // Debounce the API call
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchTutors(isLoadMore: false);
    });
  }

  void loadMore() {
    if (state.isLoading || state.currentPage >= state.totalPages) return;
    
    state = state.copyWith(currentPage: state.currentPage + 1);
    _fetchTutors(isLoadMore: true);
  }

  void refresh() {
    state = state.copyWith(currentPage: 1);
    _fetchTutors(isLoadMore: false);
  }

  Future<void> _fetchTutors({required bool isLoadMore}) async {
    _cancelToken?.cancel('Cancelled by new request');
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = <String, dynamic>{};
      if (state.query.isNotEmpty) queryParams['q'] = state.query;
      if (state.subject.isNotEmpty) queryParams['subject'] = state.subject;
      if (state.classGrade.isNotEmpty) queryParams['class'] = state.classGrade;
      if (state.stateName.isNotEmpty) queryParams['state'] = state.stateName;
      if (state.city.isNotEmpty) queryParams['city'] = state.city;
      if (state.locality.isNotEmpty) queryParams['locality'] = state.locality;
      if (state.mode.isNotEmpty) queryParams['mode'] = state.mode;
      queryParams['page'] = state.currentPage;

      final response = await ApiClient.instance.get(
        '/api/users/tutors/search/',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      final data = response.data;
      List<dynamic> newTutors = [];
      int totalPages = 1;

      if (data is Map && data.containsKey('results')) {
        newTutors = data['results'] as List<dynamic>;
        totalPages = ((data['count'] ?? 0) / 20).ceil();
        if (totalPages == 0) totalPages = 1;
      } else if (data is List) {
        newTutors = data;
      }

      state = state.copyWith(
        tutors: isLoadMore ? [...state.tutors, ...newTutors] : newTutors,
        totalPages: totalPages,
        isLoading: false,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // Ignore cancelled requests
      
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to fetch tutors',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final tutorSearchProvider = StateNotifierProvider.autoDispose<TutorSearchNotifier, TutorSearchState>((ref) {
  return TutorSearchNotifier();
});
