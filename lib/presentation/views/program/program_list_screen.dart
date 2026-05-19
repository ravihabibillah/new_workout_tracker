import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(programViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.programs),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(programViewModelProvider.notifier).loadPrograms();
        },
        child: _buildBody(context, ref, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createProgram),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.createProgram),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProgramState state) {
    if (state.isLoading && state.programs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacing16),
        child: ShimmerProgramList(itemCount: 5),
      );
    }

    if (state.errorMessage != null) {
      return Center(
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
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing24),
            ElevatedButton(
              onPressed: () {
                ref.read(programViewModelProvider.notifier).loadPrograms();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.programs.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      itemCount: state.programs.length,
      itemBuilder: (context, index) {
        final program = state.programs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSizes.spacing16),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 28,
              child: Text(
                program.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              program.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.spacing4),
                if (program.description != null) ...[
                  Text(
                    program.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      '${program.exercises.length} exercises',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: AppSizes.spacing8),
                      Text(AppStrings.edit),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      context.push(
                        AppRoutes.editProgram.replaceAll(':id', program.id),
                      );
                    });
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: AppSizes.spacing8),
                      Text(
                        AppStrings.delete,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _showDeleteConfirmation(context, ref, program.id);
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              context.push(
                AppRoutes.programDetail.replaceAll(':id', program.id),
              );
            },
          ),
        );
      },
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
              Icons.fitness_center,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Text(
              AppStrings.noPrograms,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              AppStrings.createFirstProgram,
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

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String programId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteProgram),
        content: const Text('Are you sure you want to delete this program?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(programViewModelProvider.notifier)
                    .deleteProgram(programId);
                if (context.mounted) {
                  context.showSnackBar('Program deleted successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to delete program');
                }
              }
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
