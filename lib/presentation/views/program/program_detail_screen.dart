import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';

class ProgramDetailScreen extends ConsumerWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(programByIdProvider(programId));

    return programAsync.when(
      data: (program) {
        if (program == null) {
          return GlassScaffold(
            appBar: AppBar(title: const Text('Program Not Found')),
            body: const Center(child: Text('Program not found')),
          );
        }

        return GlassScaffold(
          appBar: AppBar(
            title: Text(program.name),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.penToSquare),
                onPressed: () {
                  context.push(
                    AppRoutes.editProgram.replaceAll(':id', programId),
                  );
                },
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, color: AppColors.error),
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.spacing16,
                      AppSizes.spacing16,
                      AppSizes.spacing16,
                      AppSizes.spacing32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgramInfo(context, program),
                        const SizedBox(height: AppSizes.spacing24),
                        _buildExerciseList(context, program),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildStartButton(context, program),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
      loading: () => GlassScaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            child: const ShimmerWorkoutScreen(),
          ),
        ),
      ),
      error: (error, stack) => GlassScaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProgramInfo(BuildContext context, program) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    program.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.spacing4),
                    Text(
                      '${program.exercises.length} exercises',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (program.description != null) ...[
            const SizedBox(height: AppSizes.spacing16),
            const GlassDivider(),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              program.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        if (program.exercises.isEmpty)
          _buildEmptyState(context)
        else
          ...program.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            exercise.muscleGroup,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacing8,
                        vertical: AppSizes.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                      ),
                      child: Text(
                        exercise.muscleGroup,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSizes.spacing32),
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.dumbbell, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Edit this program to add exercises',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, program) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: LiquidGlass(
        tintColor: program.exercises.isEmpty ? null : AppColors.primary,
        tintOpacity: program.exercises.isEmpty ? 0.04 : 0.25,
        onTap: program.exercises.isEmpty
            ? null
            : () {
                context.push(
                  AppRoutes.workout.replaceAll(':programId', programId),
                );
              },
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.play,
              color: program.exercises.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: AppSizes.spacing12),
            Text(
              'Start Workout',
              style: TextStyle(
                color: program.exercises.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => GlassDialog(
        title: AppStrings.deleteProgram,
        content: const Text('Are you sure you want to delete this program?'),
        actions: [
          GlassDialogButton(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(dialogContext),
          ),
          GlassDialogButton(
            label: AppStrings.delete,
            color: AppColors.error,
            isPrimary: true,
            onTap: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(programViewModelProvider.notifier)
                    .deleteProgram(programId);
                if (context.mounted) {
                  context.pop();
                  context.showSnackBar('Program deleted successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to delete program');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
