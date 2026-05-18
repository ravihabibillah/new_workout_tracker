import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/splash_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/program/program_list_screen.dart';
import '../../presentation/views/program/program_detail_screen.dart';
import '../../presentation/views/program/create_program_screen.dart';
import '../../presentation/views/workout/active_workout_screen.dart';
import '../../presentation/views/workout/workout_history_screen.dart';
import '../../presentation/views/progress/progress_screen.dart';
import '../../presentation/views/progress/exercise_progress_screen.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String programs = '/programs';
  static const String programDetail = '/programs/:id';
  static const String createProgram = '/programs/create';
  static const String editProgram = '/programs/:id/edit';
  static const String workout = '/workout/:programId';
  static const String workoutHistory = '/workout-history';
  static const String progress = '/progress';
  static const String exerciseProgress = '/progress/:exerciseId';
}

/// GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoading = authState.isLoading;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      // Show splash while loading
      if (isLoading && isSplash) {
        return null;
      }

      // Redirect to home if authenticated and on splash/login
      if (isAuthenticated && (isSplash || isLogin)) {
        return AppRoutes.home;
      }

      // Redirect to login if not authenticated and not on login/splash
      if (!isAuthenticated && !isLogin && !isSplash) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.programs,
        builder: (context, state) => const ProgramListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createProgram,
        builder: (context, state) => const CreateProgramScreen(),
      ),
      GoRoute(
        path: AppRoutes.programDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProgramDetailScreen(programId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editProgram,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateProgramScreen(programId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.workout,
        builder: (context, state) {
          final programId = state.pathParameters['programId']!;
          return ActiveWorkoutScreen(programId: programId);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutHistory,
        builder: (context, state) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.exerciseProgress,
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          final exerciseName = state.uri.queryParameters['name'] ?? '';
          return ExerciseProgressScreen(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
