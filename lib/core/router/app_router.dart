import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';

// ── Screen imports ──
import 'package:tht_app/features/auth/screens/login_screen.dart';
import 'package:tht_app/features/auth/screens/signup_screen.dart';
import 'package:tht_app/features/auth/screens/forgot_password_screen.dart';
import 'package:tht_app/features/home/screens/home_screen.dart';
import 'package:tht_app/features/parent/screens/parent_shell.dart';
import 'package:tht_app/features/parent/screens/parent_home_screen.dart';
import 'package:tht_app/features/parent/screens/parent_dashboard_screen.dart';
import 'package:tht_app/features/parent/screens/my_jobs_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_shell.dart';
import 'package:tht_app/features/tutor/screens/tutor_home_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_dashboard_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_kyc_screen.dart';
import 'package:tht_app/features/explore/screens/explore_screen.dart';
import 'package:tht_app/features/explore/screens/tutor_detail_screen.dart';
import 'package:tht_app/features/jobs/screens/find_jobs_screen.dart';
import 'package:tht_app/features/jobs/screens/job_detail_screen.dart';
import 'package:tht_app/features/wallet/screens/wallet_screen.dart';
import 'package:tht_app/features/wallet/screens/packages_screen.dart';
import 'package:tht_app/features/notifications/screens/notifications_screen.dart';
import 'package:tht_app/features/shared/screens/splash_screen.dart';

import 'package:tht_app/features/admin/screens/admin_shell.dart';
import 'package:tht_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:tht_app/features/admin/screens/counsellor_pipeline_screen.dart';
import 'package:tht_app/features/admin/screens/admin_institute_screen.dart';
import 'package:tht_app/features/admin/screens/admin_kyc_screen.dart';

import 'package:tht_app/features/team_leader/screens/team_leader_shell.dart';
import 'package:tht_app/features/team_leader/screens/team_leader_home_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_members_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_member_detail_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_pipeline_screen.dart';
import 'package:tht_app/features/team_leader/screens/my_pipeline_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_performance_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_targets_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_warnings_screen.dart';
import 'package:tht_app/features/team_leader/screens/action_logs_screen.dart';
import 'package:tht_app/features/team_leader/screens/team_reports_screen.dart';

import 'package:tht_app/features/superadmin/screens/superadmin_shell.dart';
import 'package:tht_app/features/superadmin/screens/superadmin_dashboard_screen.dart';
import 'package:tht_app/features/superadmin/screens/superadmin_users_screen.dart';
import 'package:tht_app/features/superadmin/screens/superadmin_finance_screen.dart';
import 'package:tht_app/features/superadmin/screens/superadmin_settings_screen.dart';

import 'package:tht_app/features/institution/screens/institution_shell.dart';
import 'package:tht_app/features/institution/screens/institution_dashboard_screen.dart';
import 'package:tht_app/features/institution/screens/institution_staff_screen.dart';
import 'package:tht_app/features/institution/screens/institution_students_screen.dart';
import 'package:tht_app/features/institution/screens/institution_classes_screen.dart';

import 'package:tht_app/features/prep/screens/prep_shell.dart';
import 'package:tht_app/features/prep/screens/prep_dashboard_screen.dart';
import 'package:tht_app/features/prep/screens/prep_subjects_screen.dart';
import 'package:tht_app/features/prep/screens/prep_subject_detail_screen.dart';
import 'package:tht_app/features/prep/screens/prep_material_screen.dart';
import 'package:tht_app/features/prep/screens/prep_quiz_screen.dart';
import 'package:tht_app/features/prep/screens/prep_progress_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _parentShellKey = GlobalKey<NavigatorState>();
final _tutorShellKey = GlobalKey<NavigatorState>();
final _adminShellKey = GlobalKey<NavigatorState>();
final _teamLeaderShellKey = GlobalKey<NavigatorState>();
final _superadminShellKey = GlobalKey<NavigatorState>();
final _institutionShellKey = GlobalKey<NavigatorState>();
final _prepShellKey = GlobalKey<NavigatorState>();

/// GoRouter configuration — mirrors the Next.js App Router structure.
///
/// Auth redirect logic matches `ProtectedRoute.jsx`:
/// - Unauthenticated → /login
/// - Wrong role → role-appropriate home
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return '/splash';

      final isLoggedIn = authState.isAuthenticated;
      final path = state.uri.path;

      // Public routes that don't need auth
      const publicPaths = [
        '/login',
        '/signup',
        '/forgot-password',
        '/explore',
        '/tutors',
        '/find-jobs',
        '/',
      ];
      final isPublicRoute =
          publicPaths.contains(path) || path.startsWith('/tutors/');

      // Not logged in + trying to access protected route → login
      if (!isLoggedIn && !isPublicRoute && path != '/splash') {
        return '/login';
      }

      // Logged in + on login/signup → redirect to role home
      if (isLoggedIn && (path == '/login' || path == '/signup' || path == '/')) {
        return _homeForRole(authState.role);
      }

      return null; // No redirect
    },
    routes: [
      // ── Splash (loading) ──
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Public routes ──
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/tutors/:id',
        builder: (_, state) => TutorDetailScreen(
          tutorId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/find-jobs',
        builder: (_, __) => const FindJobsScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) => JobDetailScreen(
          jobId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // ── Parent shell (bottom navigation) ──
      ShellRoute(
        navigatorKey: _parentShellKey,
        builder: (_, __, child) => ParentShell(child: child),
        routes: [
          GoRoute(
            path: '/parent-home',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ParentHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/parent-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ParentDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/my-jobs',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: MyJobsScreen(),
            ),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: WalletScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
        ],
      ),

      // ── Tutor shell (bottom navigation) ──
      ShellRoute(
        navigatorKey: _tutorShellKey,
        builder: (_, __, child) => TutorShell(child: child),
        routes: [
          GoRoute(
            path: '/tutor-home',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-kyc',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorKYCScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-wallet',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: WalletScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-notifications',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
        ],
      ),

      // ── Admin shell (side drawer) ──
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin-pipeline',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: CounsellorPipelineScreen(),
            ),
          ),
          GoRoute(
            path: '/admin-kyc',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: AdminKYCScreen(),
            ),
          ),
          GoRoute(
            path: '/admin-institute',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: AdminInstituteScreen(),
            ),
          ),
        ],
      ),

      // ── Team Leader shell (side drawer) ──
      ShellRoute(
        navigatorKey: _teamLeaderShellKey,
        builder: (_, __, child) => TeamLeaderShell(child: child),
        routes: [
          GoRoute(
            path: '/tl-home',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamLeaderHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-members',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamMembersScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-members/:id',
            builder: (_, state) => TeamMemberDetailScreen(
              memberId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/tl-pipeline',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamPipelineScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-my-pipeline',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: MyPipelineScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-performance',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamPerformanceScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-targets',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamTargetsScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-warnings',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamWarningsScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-logs',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ActionLogsScreen(),
            ),
          ),
          GoRoute(
            path: '/tl-reports',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TeamReportsScreen(),
            ),
          ),
        ],
      ),

      // ── Superadmin shell (side drawer) ──
      ShellRoute(
        navigatorKey: _superadminShellKey,
        builder: (_, __, child) => SuperadminShell(child: child),
        routes: [
          GoRoute(
            path: '/sa-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: SuperadminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/sa-users',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: SuperadminUsersScreen(),
            ),
          ),
          GoRoute(
            path: '/sa-finance',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: SuperadminFinanceScreen(),
            ),
          ),
          GoRoute(
            path: '/sa-settings',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: SuperadminSettingsScreen(),
            ),
          ),
        ],
      ),

      // ── Institution shell (side drawer) ──
      ShellRoute(
        navigatorKey: _institutionShellKey,
        builder: (_, __, child) => InstitutionShell(child: child),
        routes: [
          GoRoute(
            path: '/inst-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-staff',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionStaffScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-students',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionStudentsScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-classes',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionClassesScreen(),
            ),
          ),
        ],
      ),

      // ── THT Prep shell (bottom navigation) ──
      ShellRoute(
        navigatorKey: _prepShellKey,
        builder: (_, __, child) => PrepShell(child: child),
        routes: [
          GoRoute(
            path: '/prep-dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PrepDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/prep-subjects',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PrepSubjectsScreen(),
            ),
          ),
          GoRoute(
            path: '/prep-subjects/:id',
            builder: (_, state) => PrepSubjectDetailScreen(
              subjectId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/prep-material/:id',
            builder: (_, state) => PrepMaterialScreen(
              materialId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/prep-quiz/:id',
            builder: (_, state) => PrepQuizScreen(
              quizId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/prep-progress',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PrepProgressScreen(),
            ),
          ),
        ],
      ),

      // ── Shared authenticated routes (push on top of shell) ──
      GoRoute(
        path: '/packages',
        builder: (_, __) => const PackagesScreen(),
      ),
    ],
  );
});

/// Returns the home path for a given role — mirrors the web's ProtectedRoute redirect logic.
String _homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.parent:
      return '/parent-home';
    case UserRole.teacher:
      return '/tutor-home';
    case UserRole.counsellor:
    case UserRole.tutorAdmin:
      return '/admin-dashboard'; // Phase 2
    case UserRole.teamLeader:
      return '/tl-home'; // Phase 2
    case UserRole.superadmin:
      return '/sa-dashboard'; // Phase 3
    case UserRole.institution:
      return '/inst-dashboard'; // Phase 3
    case UserRole.student:
      return '/prep-dashboard'; // Prep module
    case null:
      return '/login';
  }
}
