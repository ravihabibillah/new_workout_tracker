import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../viewmodels/workout_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final programState = ref.watch(programViewModelProvider);
    final workoutState = ref.watch(workoutViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(programViewModelProvider.notifier).loadPrograms();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context, user?.displayName),
              const SizedBox(height: AppSizes.spacing24),
              if (workoutState.activeSession != null)
                _buildActiveWorkoutCard(context, workoutState),
              const SizedBox(height: AppSizes.spacing24),
              _buildQuickActions(context, ref),
              const SizedBox(height: AppSizes.spacing24),
              _buildRecentPrograms(context, programState),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartWorkoutDialog(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Workout'),
      ),
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
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.workout}/${session.programId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.background,
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
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add,
                label: 'New Program',
                onTap: () => context.push(AppRoutes.createProgram),
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.history,
                label: 'History',
                onTap: () => context.push(AppRoutes.workoutHistory),
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.trending_up,
                label: 'Progress',
                onTap: () => context.push(AppRoutes.progress),
              ),
            ),
          ],
        ),
      ],
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
          const Center(child: CircularProgressIndicator())
        else if (state.programs.isEmpty)
          _buildEmptyState(context)
        else
          ...state.programs.take(3).map((program) => Card(
                margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      program.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(program.name),
                  subtitle: Text('${program.exercises.length} exercises'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push(
                    AppRoutes.programDetail.replaceAll(':id', program.id),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              AppStrings.noPrograms,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartWorkoutDialog(BuildContext context, WidgetRef ref) {
    final programs = ref.read(programViewModelProvider).programs;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Program'),
        content: programs.isEmpty
            ? const Text('Create a program first')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return ListTile(
                      title: Text(program.name),
                      subtitle: Text('${program.exercises.length} exercises'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          AppRoutes.workout.replaceAll(':programId', program.id),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
