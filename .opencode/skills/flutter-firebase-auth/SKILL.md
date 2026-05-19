---
name: flutter-firebase-auth
description: Use when implementing Firebase Authentication in Flutter, particularly Google Sign-In. Covers auth state streams, Riverpod integration, sign-out cleanup with cache clearing, and login button loading states.
---

# Flutter Firebase Auth

Patterns for Firebase Authentication in Flutter apps with Google Sign-In and Riverpod.

## Auth Repository Interface

```dart
abstract class IAuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
}
```

## Datasource Implementation

```dart
class FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException(message: 'Sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      if (userCred.user == null) {
        throw AuthException(message: 'Failed to sign in');
      }
      return UserModel.fromFirebaseUser(userCred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Auth failed', code: e.code);
    } catch (e) {
      throw AuthException(message: 'Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
    } catch (e) {
      throw AuthException(message: 'Sign-out failed: $e');
    }
  }
}
```

`Future.wait` ensures both Google and Firebase sign-out complete before resolving.

## Riverpod Auth ViewModel

```dart
@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  Stream<UserEntity?> build() {
    final repo = ref.read(authRepositoryProvider);
    return repo.authStateChanges;
  }

  Future<void> signInWithGoogle() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signInWithGoogle();
    } on Failure catch (e) {
      throw e.message;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    // Clear per-user caches on sign-out
    await ref.read(programCacheProvider).clearOnLogout();
  }
}

@riverpod
UserEntity? currentUser(CurrentUserRef ref) {
  return ref.watch(authViewModelProvider).value;
}

@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(currentUserProvider) != null;
}
```

The viewmodel exposes a `Stream<UserEntity?>` so the router can watch it for redirects.

## Login Button Loading State

Don't reset `_isLoading = false` after successful sign-in. The router will redirect to home, disposing the login screen. Resetting state on a disposed widget is wasteful:

```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authViewModelProvider.notifier).signInWithGoogle();
      // Don't reset _isLoading: GoRouter will redirect to home.
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showErrorSnackBar(e.toString());
      }
    }
  }
}
```

## Google Logo on Sign-In Button

Use `font_awesome_flutter` for the brand logo. Set explicit color or it may render invisible against colored backgrounds:

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _signInWithGoogle,
  child: _isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.google,
              size: 20,
              color: AppColors.background, // explicit color critical
            ),
            const SizedBox(width: 12),
            const Text('Sign in with Google'),
          ],
        ),
)
```

After adding `font_awesome_flutter`, do **`flutter clean` + full rebuild** (not hot reload) — fonts need to be re-bundled.

## Logout Snackbar

Showing a snackbar after `signOut()` fails because the router redirects to login before the snackbar renders. Use a global `ScaffoldMessengerKey`:

```dart
// core/utils/global_keys.dart
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// main.dart
MaterialApp.router(
  scaffoldMessengerKey: scaffoldMessengerKey,
  ...
)

// In logout handler
Future<void> _logout() async {
  Navigator.pop(context); // close confirmation dialog
  await ref.read(authViewModelProvider.notifier).signOut();
  scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Logged out successfully')),
  );
}
```

## Router Redirect Based on Auth

In the router provider, watch the auth state:

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
      return null;
    },
    routes: [...],
  );
});
```

## Defer User Data Loading Until Authenticated

Don't load Firestore data before login — it causes permission errors. Either guard in the load method or trigger from screen on first authenticated build:

```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (!_loaded && user != null) {
      _loaded = true;
      Future.microtask(() {
        ref.read(programViewModelProvider.notifier).loadPrograms();
      });
    }
    // ...
  }
}
```

## Splash Screen with Auth Resolution

Splash screen should wait for the auth state to resolve, with a fallback timeout in case of network issues:

```dart
class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Fallback: if auth doesn't resolve in 5s, force navigation to login
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && ref.read(currentUserProvider) == null) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

The router's `redirect` handles the success path; this fallback handles the edge case where Firebase Auth is slow or fails.
