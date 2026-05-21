import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/exercise_library_entity.dart';
import '../../viewmodels/exercise_library_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscleGroup;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseLibraryViewModelProvider);

    List<ExerciseLibraryEntity> filtered = state.search(_searchQuery);
    if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
      filtered =
          filtered.where((e) => e.muscleGroup == _selectedMuscleGroup).toList();
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.exerciseLibrary),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: Column(
          children: [
            _buildSearchAndFilter(state),
            Expanded(
              child: state.isLoading
                  ? const ShimmerExerciseList()
                  : filtered.isEmpty
                      ? _buildEmptyState(state.exercises.isEmpty)
                      : _buildExerciseList(filtered),
            ),
          ],
        ),
      ),
      floatingActionButton: LiquidGlass(
        borderRadius: AppSizes.radiusLarge,
        tintColor: AppColors.primary,
        tintOpacity: 0.25,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing16,
        ),
        onTap: () => _showExerciseFormDialog(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.plus, color: AppColors.primary, size: 16),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              AppStrings.createExercise,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(ExerciseLibraryState state) {
    final muscleGroups = [
      AppStrings.allMuscleGroups,
      AppStrings.chest,
      AppStrings.back,
      AppStrings.shoulders,
      AppStrings.arms,
      AppStrings.legs,
      AppStrings.core,
      AppStrings.fullBody,
      AppStrings.cardio,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing16,
        AppSizes.spacing16,
        AppSizes.spacing8,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchExercises,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const FaIcon(FontAwesomeIcons.circleXmark, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: muscleGroups.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSizes.spacing8),
              itemBuilder: (context, index) {
                final group = muscleGroups[index];
                final isAll = group == AppStrings.allMuscleGroups;
                final isSelected = isAll
                    ? _selectedMuscleGroup == null
                    : _selectedMuscleGroup == group;
                return GlassChip(
                  label: group,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedMuscleGroup = isAll ? null : group;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List<ExerciseLibraryEntity> exercises) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing8,
        AppSizes.spacing16,
        AppSizes.spacing64 + AppSizes.spacing32,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      exercise.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSizes.spacing4),
                      Text(
                        exercise.muscleGroup,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                      if (exercise.description != null &&
                          exercise.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSizes.spacing4),
                          child: Text(
                            exercise.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
                  color: AppColors.surface,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showExerciseFormDialog(context, exercise: exercise);
                    } else if (value == 'delete') {
                      _confirmDelete(context, exercise);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                          SizedBox(width: AppSizes.spacing8),
                          Text(AppStrings.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trashCan, size: 16, color: AppColors.error),
                          SizedBox(width: AppSizes.spacing8),
                          Text(
                            AppStrings.delete,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
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

  Widget _buildEmptyState(bool isLibraryEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.dumbbell, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              isLibraryEmpty
                  ? AppStrings.noExercisesInLibrary
                  : AppStrings.noMatchingExercises,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (isLibraryEmpty) ...[
              const SizedBox(height: AppSizes.spacing8),
              Text(
                AppStrings.createFirstExercise,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExerciseFormDialog(
    BuildContext context, {
    ExerciseLibraryEntity? exercise,
  }) {
    final isEditing = exercise != null;
    final nameController =
        TextEditingController(text: isEditing ? exercise.name : '');
    final descController =
        TextEditingController(text: isEditing ? exercise.description ?? '' : '');
    String selectedMuscleGroup =
        isEditing ? exercise.muscleGroup : AppStrings.chest;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: isEditing ? AppStrings.editExercise : AppStrings.createExercise,
        content: StatefulBuilder(
          builder: (context, setDialogState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.exerciseName,
                        hintText: 'e.g., Bench Press',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.dumbbell, size: 18, color: AppColors.primary),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Exercise name'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedMuscleGroup,
                      decoration: const InputDecoration(
                        labelText: AppStrings.muscleGroup,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.tag, size: 18, color: AppColors.primary),
                        ),
                      ),
                      dropdownColor: AppColors.surface,
                      items: [
                        AppStrings.chest,
                        AppStrings.back,
                        AppStrings.shoulders,
                        AppStrings.arms,
                        AppStrings.legs,
                        AppStrings.core,
                        AppStrings.fullBody,
                        AppStrings.cardio,
                      ]
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedMuscleGroup = v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.exerciseDescription,
                        hintText: 'Optional notes or instructions',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.fileLines, size: 18, color: AppColors.primary),
                        ),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          GlassDialogButton(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(context),
          ),
          GlassDialogButton(
            label: AppStrings.save,
            isPrimary: true,
            onTap: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                if (isEditing) {
                  await ref
                      .read(exerciseLibraryViewModelProvider.notifier)
                      .updateExercise(
                        exercise.copyWith(
                          name: nameController.text.trim(),
                          muscleGroup: selectedMuscleGroup,
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                  if (mounted && context.mounted) context.showSnackBar('Exercise updated');
                } else {
                  await ref
                      .read(exerciseLibraryViewModelProvider.notifier)
                      .createExercise(
                        name: nameController.text.trim(),
                        muscleGroup: selectedMuscleGroup,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      );
                  if (mounted && context.mounted) context.showSnackBar('Exercise created');
                }
              } catch (_) {
                if (mounted && context.mounted) {
                  context.showErrorSnackBar('Failed to save exercise');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExerciseLibraryEntity exercise) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: AppStrings.delete,
        content: Text(
          'Delete "${exercise.name}"? This will not affect existing programs.',
        ),
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
                    .read(exerciseLibraryViewModelProvider.notifier)
                    .deleteExercise(exercise.id);
                if (mounted && context.mounted) context.showSnackBar('Exercise deleted');
              } catch (_) {
                if (mounted && context.mounted) {
                  context.showErrorSnackBar('Failed to delete exercise');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
