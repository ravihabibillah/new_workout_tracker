import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/workout_session_entity.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';

final workoutHistoryProvider = FutureProvider<List<WorkoutSessionEntity>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getWorkoutHistory(limit: 50);
});

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: historyAsync.when(
          data: (sessions) => _buildHistoryList(context, sessions),
          loading: () => const ShimmerHistoryList(),
          error: (error, stack) => _buildErrorState(context, error.toString()),
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<WorkoutSessionEntity> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.spacing16,
          AppSizes.spacing16,
          AppSizes.spacing16,
          100 + AppSizes.spacing16,
        ),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
            child: _WorkoutSessionCard(session: session),
          );
        },
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
            FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Text(
              'No workout history yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              'Complete your first workout to see it here',
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
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'Failed to load history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              error,
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
}

class _WorkoutSessionCard extends StatelessWidget {
  final WorkoutSessionEntity session;

  const _WorkoutSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.programName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.calendar,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spacing4),
              Text(
                dateFormat.format(session.startTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              FaIcon(
                FontAwesomeIcons.clock,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spacing4),
              Text(
                timeFormat.format(session.startTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          const GlassDivider(),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: FontAwesomeIcons.dumbbell,
                label: 'Exercises',
                value: session.exerciseLogs.length.toString(),
              ),
              _StatItem(
                icon: FontAwesomeIcons.repeat,
                label: 'Sets',
                value: session.totalSets.toString(),
              ),
              _StatItem(
                icon: FontAwesomeIcons.stopwatch,
                label: 'Duration',
                value: session.duration != null ? '${session.duration!.inMinutes}m' : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: AppSizes.spacing4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
