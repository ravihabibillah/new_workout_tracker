import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/global_keys.dart';
import 'data/datasources/local/exercise_library_cache.dart';
import 'data/datasources/local/program_cache.dart';
import 'presentation/viewmodels/program_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: draw behind status bar and navigation bar with transparent
  // system bars so the dark theme background shows through.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local caches (Hive)
  final exerciseLibraryCache = ExerciseLibraryCache();
  await exerciseLibraryCache.init();

  final programCache = ProgramCache();
  await programCache.init();

  runApp(
    ProviderScope(
      overrides: [
        exerciseLibraryCacheProvider.overrideWithValue(exerciseLibraryCache),
        programCacheProvider.overrideWithValue(programCache),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'IronLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
