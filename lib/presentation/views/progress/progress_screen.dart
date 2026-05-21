import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/progress_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressViewModelProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.progress),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(progressViewModelProvider.notifier).loadExerciseNames();
        },
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: _buildBody(context, ref, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProgressState state) {
    if (state.isLoading && state.exerciseNames.isEmpty) {
      return const ShimmerProgressScreen();
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
              const ShimmerProgressScreen()
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
    return GlassCard(
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
          _GlassDropdown(
            value: state.selectedExercise,
            hint: 'Choose an exercise',
            items: state.exerciseNames,
            onChanged: (value) {
              if (value != null) {
                ref.read(progressViewModelProvider.notifier).selectExercise(value);
              }
            },
          ),
        ],
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
              child: _GlassStatCard(
                icon: FontAwesomeIcons.dumbbell,
                label: AppStrings.maxWeight,
                value: '${records['maxWeight']?.toStringAsFixed(1) ?? '0'} kg',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _GlassStatCard(
                icon: FontAwesomeIcons.repeat,
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
              child: _GlassStatCard(
                icon: FontAwesomeIcons.arrowTrendUp,
                label: AppStrings.totalVolume,
                value: '${records['maxVolume']?.toStringAsFixed(0) ?? '0'} kg',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: _GlassStatCard(
                icon: FontAwesomeIcons.clockRotateLeft,
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
    return LiquidGlass(
      tintColor: AppColors.primary,
      tintOpacity: 0.2,
      onTap: () {
        final exerciseName = state.selectedExercise!;
        context.push(
          '/progress/${Uri.encodeComponent(exerciseName)}?name=${Uri.encodeComponent(exerciseName)}',
        );
      },
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.chartColumn, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSizes.spacing12),
          Text(
            'View Detailed Progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
            FaIcon(
              FontAwesomeIcons.chartColumn,
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
            FaIcon(
              FontAwesomeIcons.arrowTrendUp,
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
            FaIcon(
              FontAwesomeIcons.circleExclamation,
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

class _GlassDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _GlassDropdown({
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Row(
              children: [
                FaIcon(FontAwesomeIcons.dumbbell,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.spacing12),
                Text(
                  hint,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            icon: const FaIcon(FontAwesomeIcons.chevronDown,
                size: 14, color: AppColors.textSecondary),
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing4,
            ),
            selectedItemBuilder: (context) => items
                .map(
                  (name) => Row(
                    children: [
                      FaIcon(FontAwesomeIcons.dumbbell,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
            items: items
                .map(
                  (name) => DropdownMenuItem(
                    value: name,
                    child: Text(
                      name,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GlassStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 28),
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
