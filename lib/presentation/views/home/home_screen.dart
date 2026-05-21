import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../viewmodels/workout_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _programsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final programState = ref.watch(programViewModelProvider);
    final workoutState = ref.watch(workoutViewModelProvider);

    if (user != null && !_programsLoaded) {
      _programsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(programViewModelProvider.notifier).loadPrograms();
        }
      });
    }

    if (user == null) {
      _programsLoaded = false;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.appName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear),
            onPressed: () => _showSettingsMenu(context, ref),
          ),
        ],
      ),
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(programViewModelProvider.notifier).loadPrograms();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + AppSizes.spacing16,
              left: AppSizes.spacing16,
              right: AppSizes.spacing16,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context, user?.displayName),
                const SizedBox(height: AppSizes.spacing24),
                if (workoutState.activeSession != null)
                  _buildActiveWorkoutCard(context, workoutState),
                if (workoutState.activeSession != null)
                  const SizedBox(height: AppSizes.spacing24),
                _buildRecentPrograms(context, programState),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String? displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back${displayName != null ? ', $displayName' : ''}!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          'Ready to crush your workout?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildActiveWorkoutCard(BuildContext context, WorkoutState state) {
    final session = state.activeSession!;
    return LiquidGlass(
      tintColor: AppColors.primary,
      tintOpacity: 0.15,
      onTap: () {
        if (session.isQuickWorkout || session.programId == null) {
          context.push(AppRoutes.quickWorkout);
        } else {
          context.push(
            AppRoutes.workout.replaceAll(':programId', session.programId!),
          );
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const FaIcon(
              FontAwesomeIcons.dumbbell,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout in Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  session.programName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.chevronRight,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPrograms(BuildContext context, ProgramState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Programs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.programs),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),
        if (state.isLoading)
          const ShimmerProgramList()
        else if (state.programs.isEmpty)
          _buildEmptyState(context)
        else
          ...state.programs.take(3).map((program) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                child: LiquidGlass(
                  onTap: () => context.push(
                    AppRoutes.programDetail.replaceAll(':id', program.id),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        child: Center(
                          child: Text(
                            program.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.spacing4),
                            Text(
                              '${program.exercises.length} exercises',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.chevronRight,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LiquidGlass(
      padding: const EdgeInsets.all(AppSizes.spacing32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.dumbbell,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              AppStrings.noPrograms,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlass(
        borderRadius: AppSizes.radiusLarge,
        margin: const EdgeInsets.all(AppSizes.spacing16),
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.rightFromBracket, color: AppColors.error),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: 'Logout',
        content: const Text('Are you sure you want to logout?'),
        actions: [
          GlassDialogButton(
            label: 'Cancel',
            onTap: () => Navigator.pop(context),
          ),
          GlassDialogButton(
            label: 'Logout',
            color: AppColors.error,
            isPrimary: true,
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) {
                context.showSnackBar('Logged out successfully');
              }
            },
          ),
        ],
      ),
    );
  }
}
