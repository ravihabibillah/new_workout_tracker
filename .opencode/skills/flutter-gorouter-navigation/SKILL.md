---
name: flutter-gorouter-navigation
description: Use when configuring or debugging navigation in a Flutter app using GoRouter. Covers route definitions, auth-based redirects, URL construction with path parameters, and common pitfalls like using route templates as URLs.
---

# GoRouter Navigation for Flutter

Patterns for GoRouter in Flutter apps with auth-based redirects, typed path parameters, and safe URL construction.

## Route Definitions

Define route names as constants to avoid typos:

```dart
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String programDetail = '/programs/:id';
  static const String workout = '/workout/:programId';
  static const String quickWorkout = '/workout/quick';  // static before dynamic
  static const String exerciseProgress = '/progress/:exerciseId';
}
```

**Static routes must be declared before dynamic routes with the same prefix.** GoRouter matches top-to-bottom, so `/workout/quick` must come before `/workout/:programId` or it will be captured as `programId = "quick"`.

```dart
GoRoute(
  path: AppRoutes.quickWorkout,          // static first
  builder: (context, state) => const QuickWorkoutScreen(),
),
GoRoute(
  path: AppRoutes.workout,               // dynamic second
  builder: (context, state) {
    final programId = state.pathParameters['programId']!;
    return ActiveWorkoutScreen(programId: programId);
  },
),
```

## Auth-Based Redirect

Watch the auth state provider and redirect accordingly:

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoading = authState.isLoading;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (isLoading && isSplash) return null;
      if (isAuthenticated && (isSplash || isLogin)) return AppRoutes.home;
      if (!isAuthenticated && !isLogin && !isSplash) return AppRoutes.login;
      if (!isLoading && !isAuthenticated && isSplash) return AppRoutes.login;

      return null;
    },
    routes: [...],
  );
});
```

## URL Construction with Path Parameters

**Never use route templates as navigation URLs.** `AppRoutes.programDetail` is `/programs/:id` — the `:id` is a template placeholder, not a real URL segment.

```dart
// WRONG — navigates to literal "/programs/:id"
context.push(AppRoutes.programDetail);

// CORRECT — replace the placeholder
context.push(AppRoutes.programDetail.replaceAll(':id', program.id));
```

For path segments that may contain spaces or special characters, use `Uri.encodeComponent`:

```dart
// Exercise names like "Incline Barbell Bench Press" need encoding
context.push(
  '/progress/${Uri.encodeComponent(exerciseName)}?name=${Uri.encodeComponent(exerciseName)}',
);
```

GoRouter decodes path parameters automatically, so `state.pathParameters['exerciseId']` returns the decoded string.

## Query Parameters

Pass extra data via query parameters when it doesn't belong in the path:

```dart
// Navigate
context.push('/progress/${Uri.encodeComponent(id)}?name=${Uri.encodeComponent(name)}');

// Read in route builder
final exerciseId = state.pathParameters['exerciseId']!;
final exerciseName = state.uri.queryParameters['name'] ?? '';
```

## Programmatic Navigation

```dart
// Push (adds to stack)
context.push('/programs/${program.id}');

// Replace (replaces current route)
context.replace(AppRoutes.home);

// Pop
context.pop();

// Pop with result
context.pop(true);
```

## WillPopScope / Back Button Behavior

For screens where back = "close but preserve state" (not cancel):

```dart
return WillPopScope(
  onWillPop: () async => true,  // allow back, don't intercept
  child: Scaffold(...),
);
```

For screens where back should be intercepted (e.g., confirm before leaving):

```dart
return WillPopScope(
  onWillPop: () async {
    final shouldLeave = await showConfirmDialog(context);
    return shouldLeave ?? false;
  },
  child: Scaffold(...),
);
```

Note: `WillPopScope` is deprecated in Flutter 3.12+. Prefer `PopScope` with `canPop: false` and `onPopInvoked` for new code.

## Error Page

Always define an `errorBuilder` to avoid blank screens on unknown routes:

```dart
GoRouter(
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.matchedLocation}'),
    ),
  ),
  routes: [...],
)
```

## Snackbars After Redirect

Showing a snackbar after an action that triggers a GoRouter redirect (e.g., logout) fails because the originating screen unmounts before the snackbar renders. Use a global `ScaffoldMessengerKey`:

```dart
// core/utils/global_keys.dart
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// main.dart
MaterialApp.router(
  scaffoldMessengerKey: scaffoldMessengerKey,
  ...
)

// Anywhere in the app
scaffoldMessengerKey.currentState?.showSnackBar(
  const SnackBar(content: Text('Logged out')),
);
```

Define the key in a separate file (not `main.dart`) to avoid circular imports when screens import it.
