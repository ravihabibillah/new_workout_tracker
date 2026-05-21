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

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(programViewModelProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.programs),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, color: AppColors.primary),
            tooltip: AppStrings.createProgram,
            onPressed: () => context.push(AppRoutes.createProgram),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(programViewModelProvider.notifier).loadPrograms();
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
            FaIcon(
              FontAwesomeIcons.circleExclamation,
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
            LiquidGlass(
              tintColor: AppColors.primary,
              tintOpacity: 0.2,
              onTap: () {
                ref.read(programViewModelProvider.notifier).loadPrograms();
              },
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing24,
                vertical: AppSizes.spacing12,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.programs.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing16,
        AppSizes.spacing16,
        AppSizes.spacing64 + AppSizes.spacing32,
      ),
      itemCount: state.programs.length,
      itemBuilder: (context, index) {
        final program = state.programs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            onTap: () {
              context.push(
                AppRoutes.programDetail.replaceAll(':id', program.id),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      program.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
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
                          FaIcon(
                            FontAwesomeIcons.dumbbell,
                            size: 14,
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
                ),
                PopupMenuButton(
                  icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
                  color: AppColors.surface.withValues(alpha: 0.95),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          FaIcon(FontAwesomeIcons.penToSquare, size: 18),
                          SizedBox(width: AppSizes.spacing8),
                          Text(AppStrings.edit),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          if (context.mounted) {
                            context.push(
                              AppRoutes.editProgram.replaceAll(':id', program.id),
                            );
                          }
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trashCan, size: 18, color: AppColors.error),
                          SizedBox(width: AppSizes.spacing8),
                          Text(
                            AppStrings.delete,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          if (context.mounted) {
                            _showDeleteConfirmation(context, ref, program.id);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
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
            FaIcon(
              FontAwesomeIcons.dumbbell,
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: AppStrings.deleteProgram,
        content: const Text('Are you sure you want to delete this program?'),
        actions: [
          GlassDialogButton(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(context),
          ),
          GlassDialogButton(
            label: AppStrings.delete,
            color: AppColors.error,
            isPrimary: true,
            onTap: () async {
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
          ),
        ],
      ),
    );
  }
}
