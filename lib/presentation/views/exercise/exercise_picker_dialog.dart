import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_library_entity.dart';
import '../../widgets/shimmer_loading.dart';
import '../../viewmodels/exercise_library_viewmodel.dart';

class ExercisePickerDialog extends ConsumerStatefulWidget {
  final List<ExerciseEntity> existingExercises;

  const ExercisePickerDialog({
    super.key,
    this.existingExercises = const [],
  });

  @override
  ConsumerState<ExercisePickerDialog> createState() =>
      _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<ExercisePickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscleGroup;
  final Set<ExerciseLibraryEntity> _selectedExercises = {};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _newExerciseMuscleGroup = AppStrings.chest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.spacing16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spacing16,
                AppSizes.spacing16,
                AppSizes.spacing8,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.addExercise,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: AppStrings.selectFromLibrary),
                Tab(text: AppStrings.createNewExercise),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLibraryTab(),
                  _buildCreateTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab() {
    final state = ref.watch(exerciseLibraryViewModelProvider);
    final existingIds =
        widget.existingExercises.map((e) => e.name.toLowerCase()).toSet();

    List<ExerciseLibraryEntity> filtered = state.search(_searchQuery);
    if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
      filtered =
          filtered.where((e) => e.muscleGroup == _selectedMuscleGroup).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.searchExercises,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: AppSizes.spacing8),
              _buildMuscleGroupFilter(),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const ShimmerExerciseList()
              : filtered.isEmpty
                  ? _buildEmptyLibrary(state.exercises.isEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacing16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final alreadyAdded = existingIds
                            .contains(exercise.name.toLowerCase());
                        final isSelected =
                            _selectedExercises.contains(exercise);
                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: AppSizes.spacing8),
                          child: CheckboxListTile(
                            value: alreadyAdded ? true : isSelected,
                            onChanged: alreadyAdded
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedExercises.add(exercise);
                                      } else {
                                        _selectedExercises.remove(exercise);
                                      }
                                    });
                                  },
                            controlAffinity:
                                ListTileControlAffinity.trailing,
                            secondary: CircleAvatar(
                              backgroundColor: alreadyAdded
                                  ? AppColors.textSecondary.withOpacity(0.3)
                                  : AppColors.surfaceSecondary,
                              child: Icon(
                                alreadyAdded
                                    ? Icons.check
                                    : Icons.fitness_center,
                                color: alreadyAdded
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              style: TextStyle(
                                color: alreadyAdded
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              alreadyAdded
                                  ? '${exercise.muscleGroup} • Added'
                                  : exercise.muscleGroup,
                              style: TextStyle(
                                color: alreadyAdded
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_selectedExercises.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedExercises.length} selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedExercises.clear()),
                  child: const Text('Clear'),
                ),
                const SizedBox(width: AppSizes.spacing8),
                FilledButton.icon(
                  onPressed: _addSelectedFromLibrary,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Selected'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMuscleGroupFilter() {
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

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: muscleGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.spacing4),
        itemBuilder: (context, index) {
          final group = muscleGroups[index];
          final isAll = group == AppStrings.allMuscleGroups;
          final isSelected =
              isAll ? _selectedMuscleGroup == null : _selectedMuscleGroup == group;
          return FilterChip(
            label: Text(group),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedMuscleGroup = isAll ? null : group;
              });
            },
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildEmptyLibrary(bool isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              isEmpty
                  ? AppStrings.noExercisesInLibrary
                  : AppStrings.noMatchingExercises,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isEmpty) ...[
              const SizedBox(height: AppSizes.spacing16),
              TextButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.createNewExercise),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.exerciseName,
                hintText: 'e.g., Bench Press',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validators.required(v, fieldName: 'Exercise name'),
            ),
            const SizedBox(height: AppSizes.spacing16),
            DropdownButtonFormField<String>(
              value: _newExerciseMuscleGroup,
              decoration: const InputDecoration(
                labelText: AppStrings.muscleGroup,
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                AppStrings.chest,
                AppStrings.back,
                AppStrings.shoulders,
                AppStrings.arms,
                AppStrings.legs,
                AppStrings.core,
                AppStrings.fullBody,
      AppStrings.cardio,
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _newExerciseMuscleGroup = v);
              },
            ),
            const SizedBox(height: AppSizes.spacing16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: AppStrings.exerciseDescription,
                hintText: 'Optional notes',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _createAndAdd(saveToLibrary: false),
                    child: const Text('Add Only'),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _createAndAdd(saveToLibrary: true),
                    child: const Text('Add & Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              '"Add & Save" will also save to your exercise library for future use.',
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

  void _addSelectedFromLibrary() {
    final baseOrder = widget.existingExercises.length;
    final exercises = _selectedExercises
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => ExerciseEntity(
            id: const Uuid().v4(),
            name: entry.value.name,
            muscleGroup: entry.value.muscleGroup,
            order: baseOrder + entry.key,
          ),
        )
        .toList();
    Navigator.pop(context, exercises);
  }

  Future<void> _createAndAdd({required bool saveToLibrary}) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final muscleGroup = _newExerciseMuscleGroup;
    final description =
        _descController.text.trim().isEmpty ? null : _descController.text.trim();

    if (saveToLibrary) {
      try {
        await ref
            .read(exerciseLibraryViewModelProvider.notifier)
            .createExercise(
              name: name,
              muscleGroup: muscleGroup,
              description: description,
            );
      } catch (_) {
        if (mounted) {
          context.showErrorSnackBar('Failed to save to library');
        }
      }
    }

    final exercise = ExerciseEntity(
      id: const Uuid().v4(),
      name: name,
      muscleGroup: muscleGroup,
      order: widget.existingExercises.length,
    );

    if (mounted) Navigator.pop(context, [exercise]);
  }
}

Future<List<ExerciseEntity>?> showExercisePickerDialog(
  BuildContext context, {
  List<ExerciseEntity> existingExercises = const [],
}) {
  return showDialog<List<ExerciseEntity>>(
    context: context,
    builder: (context) => ExercisePickerDialog(
      existingExercises: existingExercises,
    ),
  );
}
