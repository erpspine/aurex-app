import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav.dart';
import 'diet.dart';
import 'diet_form.dart';
import 'exercise_detail_list.dart';
import 'exercise_list.dart';
import 'landing.dart';
import 'login.dart';
import 'profile.dart';
import 'progress.dart';
import 'providers.dart';
import 'workout_detail.dart';
import 'workout_plan_detail.dart';
import 'workout_session.dart';
import 'workouts.dart';

class AurexRoutes {
  const AurexRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';

  static const home = '/home';
  static const workouts = '/workouts';
  static const diet = '/diet';
  static const addFood = '/diet/add';
  static const progress = '/progress';
  static const profile = '/profile';
  static const bodyParts = '/exercises/body-parts';
  static const equipment = '/exercises/equipment';

  static const _public = {
    login,
    signUp,
    forgotPassword,
    resetPassword,
    verifyEmail,
  };

  static String workout(String id) => '$workouts/${Uri.encodeComponent(id)}';

  static String exerciseGroup(String groupType, String name) =>
      '/exercises/${groupType == 'Equipment' ? 'equipment' : 'body-parts'}/'
      '${Uri.encodeComponent(name)}';

  static String exercise(String id) => '/exercise/${Uri.encodeComponent(id)}';

  static String session(String exerciseId) => '${exercise(exerciseId)}/session';

  static String withEmail(String path, String email) =>
      Uri(path: path, queryParameters: {'email': email}).toString();
}

/// Extra data for auth screens that show a server message and a resend timer.
class AuthScreenExtra {
  const AuthScreenExtra({this.message, this.retryAfter = 60});

  final String? message;
  final int retryAfter;
}

/// Pops the current route, or navigates to [fallback] when the page was
/// opened directly (deep link or browser refresh) and has nothing to pop.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => sessionChanges.value++);
  ref.onDispose(sessionChanges.dispose);

  final router = GoRouter(
    initialLocation: AurexRoutes.home,
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;

      // Wait on the splash screen until the saved session has been checked,
      // remembering where the user was going.
      if (!session.hasValue) {
        if (location == AurexRoutes.splash) {
          return null;
        }
        return Uri(
          path: AurexRoutes.splash,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      final signedIn = session.value != null;
      if (location == AurexRoutes.splash) {
        final from = state.uri.queryParameters['from'];
        if (!signedIn) {
          return AurexRoutes.login;
        }
        return from == null ||
                AurexRoutes._public.contains(Uri.parse(from).path)
            ? AurexRoutes.home
            : from;
      }

      final isPublic = AurexRoutes._public.contains(location);
      if (!signedIn && !isPublic) {
        return AurexRoutes.login;
      }
      if (signedIn && isPublic) {
        return AurexRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AurexRoutes.splash,
        builder: (context, state) => const AurexSplashScreen(),
      ),
      GoRoute(
        path: AurexRoutes.login,
        builder: (context, state) => const AurexLoginScreen(),
      ),
      GoRoute(
        path: AurexRoutes.signUp,
        builder: (context, state) => const AurexSignUpScreen(),
      ),
      GoRoute(
        path: AurexRoutes.forgotPassword,
        builder: (context, state) => const AurexForgotPasswordScreen(),
      ),
      GoRoute(
        path: AurexRoutes.resetPassword,
        builder: (context, state) {
          final extra = state.extra as AuthScreenExtra?;
          return AurexPasswordResetScreen(
            email: state.uri.queryParameters['email'] ?? '',
            initialMessage: extra?.message,
            retryAfter: extra?.retryAfter ?? 0,
          );
        },
      ),
      GoRoute(
        path: AurexRoutes.verifyEmail,
        builder: (context, state) {
          final extra = state.extra as AuthScreenExtra?;
          return AurexEmailVerificationScreen(
            email: state.uri.queryParameters['email'] ?? '',
            initialMessage: extra?.message,
            retryAfter: extra?.retryAfter ?? 0,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AurexShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AurexRoutes.home,
                builder: (context, state) => const AurexLandingScreen(),
              ),
              GoRoute(
                path: AurexRoutes.bodyParts,
                builder: (context, state) => const ExerciseListPage.bodyParts(),
                routes: [
                  GoRoute(
                    path: ':name',
                    builder: (context, state) => ExerciseDetailListPage(
                      groupType: 'Body Part',
                      title: state.pathParameters['name']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AurexRoutes.equipment,
                builder: (context, state) => const ExerciseListPage.equipment(),
                routes: [
                  GoRoute(
                    path: ':name',
                    builder: (context, state) => ExerciseDetailListPage(
                      groupType: 'Equipment',
                      title: state.pathParameters['name']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/exercise/:id',
                builder: (context, state) =>
                    WorkoutDetailPage(exerciseId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'session',
                    builder: (context, state) => WorkoutSessionPage(
                      exerciseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AurexRoutes.workouts,
                builder: (context, state) => WorkoutsPage(
                  initialLevel: state.uri.queryParameters['level'],
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => WorkoutPlanDetailPage(
                      workoutId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AurexRoutes.diet,
                builder: (context, state) => const DietPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddDietFormPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AurexRoutes.progress,
                builder: (context, state) => const ProgressPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AurexRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
