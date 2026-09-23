import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/statistics_screen.dart';
import '../../features/dashboard/screens/about_screen.dart';
import '../../features/simulation/screens/simulation_screen.dart';
import '../../features/simulation/screens/session_history_screen.dart';
import '../../features/simulation/screens/session_conversation_screen.dart';
import '../../features/exercises/screens/exercises_screen.dart';
import '../../features/qa/screens/standalone_qa_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/activity_history/screens/activity_history_screen.dart';
import '../../core/widgets/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorSimulationKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellSimulation');
final GlobalKey<NavigatorState> _shellNavigatorExercisesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellExercises');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email =
              state.uri.queryParameters['email'] ??
              (state.extra as String?) ??
              '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra! as Map)
              : <String, dynamic>{};
          return OtpVerificationScreen(
            email: extra['email'] as String? ?? '',
            expiresInSeconds: extra['expiresInSeconds'] as int?,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'statistics',
                    builder: (context, state) => const StatisticsScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSimulationKey,
            routes: [
              GoRoute(
                path: AppRoutes.simulation,
                builder: (context, state) => const SimulationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExercisesKey,
            routes: [
              GoRoute(
                path: AppRoutes.exercises,
                builder: (context, state) => const ExercisesScreen(),
                routes: [
                  GoRoute(
                    path: 'qa',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final exerciseId =
                          state.uri.queryParameters['exerciseId'];
                      final exerciseTitle =
                          state.uri.queryParameters['exerciseTitle'];
                      final domaine = state.uri.queryParameters['domaine'];
                      final difficulte =
                          state.uri.queryParameters['difficulte'];
                      return StandaloneQAScreen(
                        exerciseId: exerciseId,
                        exerciseTitle: exerciseTitle,
                        domaine: domaine,
                        difficulte: difficulte,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.simulationHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SessionHistoryScreen(),
        routes: [
          GoRoute(
            path: ':sessionId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return SessionConversationScreen(sessionId: sessionId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.activityHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ActivityHistoryScreen(),
      ),
    ],
  );
}
