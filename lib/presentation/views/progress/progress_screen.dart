import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../viewmodels/progress_viewmodel.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.progress),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(progressViewModelProvider.notifier).loadExerciseNames();
        },
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProgressState state) {
    if (state.isLoading && state.exerciseNames.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(context, state.errorMessage!);
    }

    if (state.exerciseNames.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExerciseSelector(context, ref, state),
          const SizedBox(height: AppSizes.spacing24),
          if (state.selectedExercise != null) ...[
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildPersonalRecords(context, state),
              const SizedBox(height: AppSizes.spacing24),
              _buildViewDetailButton(context, state),
            ],
          ] else
            _buildSelectExercisePrompt(context),
        ],
      ),
    );
  }

  Widget _buildExerciseSelector(
    BuildContext context,
    WidgetRef ref,
    ProgressState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.selectExercise,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            DropdownButtonFormField<String>(
              value: state.selectedExercise,
              decoration: InputDecoration(
                hintText: 'Choose an exercise',
                prefixIcon: const Icon(Icons.fitness_center),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
              ),
              items: state.exerciseNames.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(progressViewModelProvider.notifier).selectExercise(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecords(BuildContext context, ProgressState state) {
    final records = state.personalRecords;
    if (records == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Records',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                label: AppStrings.maxWeight,
                value: '${records['maxWeight']?.toStringAsFixed(1) ?? '0'} kg',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _StatCard(
                icon: Icons.repeat,
                label: AppStrings.maxReps,
                value: '${records['maxReps'] ?? 0}',
                color: AppColors.chartSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                label: AppStrings.totalVolume,
                value: '${records['maxVolume']?.toStringAsFixed(0) ?? '0'} kg',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _StatCard(
                icon: Icons.history,
                label: AppStrings.totalSessions,
                value: '${state.progressData.length}',
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewDetailButton(BuildContext context, ProgressState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final exerciseName = state.selectedExercise!;
          context.push(
            '/progress/${Uri.encodeComponent(exerciseName)}?name=${Uri.encodeComponent(exerciseName)}',
          );
        },
        icon: const Icon(Icons.bar_chart),
        label: const Text('View Detailed Progress'),
      ),
    );
  }

  Widget _buildSelectExercisePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Text(
              'Select an exercise to view progress',
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Text(
              AppStrings.noProgressData,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              AppStrings.startTrackingProgress,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
