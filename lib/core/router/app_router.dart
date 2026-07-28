import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';

// ── Screen imports ──
import 'package:tht_app/features/auth/screens/login_screen.dart';
import 'package:tht_app/features/auth/screens/signup_screen.dart';
import 'package:tht_app/features/auth/screens/forgot_password_screen.dart';
import 'package:tht_app/features/auth/screens/continue_on_web_screen.dart';
import 'package:tht_app/features/home/screens/home_screen.dart';
import 'package:tht_app/features/parent/screens/parent_shell.dart';
import 'package:tht_app/features/parent/screens/parent_home_screen.dart';
import 'package:tht_app/features/parent/screens/my_job_detail_screen.dart';
import 'package:tht_app/features/parent/screens/job_wizard_screen.dart';
import 'package:tht_app/features/parent/screens/my_jobs_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_shell.dart';
import 'package:tht_app/features/tutor/screens/tutor_home_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_profile_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_kyc_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_applications_screen.dart';
import 'package:tht_app/features/tutor/screens/tutor_schedule_screen.dart';
import 'package:tht_app/features/explore/screens/explore_screen.dart';
import 'package:tht_app/features/explore/screens/tutor_detail_screen.dart';
import 'package:tht_app/features/jobs/screens/find_jobs_screen.dart';
import 'package:tht_app/features/jobs/screens/job_detail_screen.dart';
import 'package:tht_app/features/wallet/screens/wallet_screen.dart';
import 'package:tht_app/features/wallet/screens/packages_screen.dart';
import 'package:tht_app/features/notifications/screens/notifications_screen.dart';
import 'package:tht_app/features/shared/screens/splash_screen.dart';

import 'package:tht_app/features/institution/screens/institution_shell.dart';
import 'package:tht_app/features/institution/screens/institution_dashboard_screen.dart';
import 'package:tht_app/features/institution/screens/institution_jobs_screen.dart';
import 'package:tht_app/features/institution/screens/institution_teachers_screen.dart';
import 'package:tht_app/features/institution/screens/institution_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _parentShellKey = GlobalKey<NavigatorState>();
final _tutorShellKey = GlobalKey<NavigatorState>();
final _institutionShellKey = GlobalKey<NavigatorState>();

/// Routing for the three audiences this app serves.
///
/// Parents, teachers and institutes each get a shell with their own bottom
/// navigation. Staff roles are not routed here at all — they are redirected to
/// an explanation and a link to the website, which is where their tools live.
///
/// Redirect order matters: unauthenticated users are bounced to /login first,
/// then an unsupported role is parked, and only then does a signed-in user on a
/// public entry point get sent to their home.
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

      // Signed in with a role the app doesn't serve (counsellor, team leader,
      // superadmin). Their credentials are valid, so this is not a failed
      // login — park them on an explanation with a link to the website.
      if (authState.isUnsupportedRole) {
        return path == '/continue-on-web' ? null : '/continue-on-web';
      }
      if (!authState.isUnsupportedRole && path == '/continue-on-web') {
        return _homeForRole(authState.role);
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
        path: '/continue-on-web',
        builder: (_, __) => const ContinueOnWebScreen(),
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
          // Find-a-teacher inside the parent shell, so the bottom bar stays
          // put. It needs its own path: the public /explore route is declared
          // at the top level for anonymous browsing, and two routes with the
          // same path would silently resolve to whichever was declared first.
          GoRoute(
            path: '/find-teachers',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/my-jobs/:id',
            builder: (_, state) => MyJobDetailScreen(
              jobId: int.parse(state.pathParameters['id']!),
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
            path: '/tutor-profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorProfileScreen(),
            ),
          ),
          // The teacher-side jobs feed. The public /find-jobs route renders the
          // same screen for anyone browsing before they sign in; this one lives
          // inside the shell so the bottom bar stays put.
          GoRoute(
            path: '/tutor-jobs',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: FindJobsScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-kyc',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorKYCScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-applications',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorApplicationsScreen(),
            ),
          ),
          GoRoute(
            path: '/tutor-schedule',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: TutorScheduleScreen(),
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

      // ── Institution shell (bottom navigation) ──
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
            path: '/inst-jobs',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionJobsScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-teachers',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionTeachersScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-notifications',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/inst-profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: InstitutionProfileScreen(),
            ),
          ),
          // An institute reviews applicants on the same screen a parent does —
          // both own the job and see the same applicant list.
          GoRoute(
            path: '/my-jobs/:id',
            builder: (_, state) => MyJobDetailScreen(
              jobId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),

      // ── Shared authenticated routes (push on top of shell) ──
      GoRoute(
        path: '/packages',
        builder: (_, __) => const PackagesScreen(),
      ),
      // Full-screen on purpose: posting a requirement is a multi-step form, and
      // a bottom bar offering four ways to leave it half-finished is a way to
      // lose the answers already given.
      GoRoute(
        path: '/post-requirement',
        builder: (_, __) => const JobWizardScreen(),
      ),
    ],
  );
});

/// Where a signed-in user lands, by role.
///
/// The app serves parents, teachers and institutes. Every other role — the
/// staff side of the marketplace — is handed back to the website.
String _homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.parent:
      return '/parent-home';
    case UserRole.teacher:
      return '/tutor-home';
    case UserRole.institution:
      return '/inst-dashboard';
    case UserRole.counsellor:
    case UserRole.tutorAdmin:
    case UserRole.teamLeader:
    case UserRole.superadmin:
    case UserRole.student:
      return '/continue-on-web';
    case null:
      return '/login';
  }
}
