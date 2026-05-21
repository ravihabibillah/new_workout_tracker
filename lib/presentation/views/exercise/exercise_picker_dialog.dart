import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_library_entity.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/liquid_glass.dart';
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
    final radius = BorderRadius.circular(AppSizes.radiusLarge);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.spacing16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark),
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
                    dividerColor: Colors.white.withValues(alpha: 0.08),
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
          ),
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
              _GlassField(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchExercises,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
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
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: AppSizes.spacing12),
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
                          child: _GlassListTile(
                            highlight: isSelected,
                            child: ListTile(
                              onTap: alreadyAdded
                                  ? null
                                  : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedExercises.remove(exercise);
                                        } else {
                                          _selectedExercises.add(exercise);
                                        }
                                      });
                                    },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: alreadyAdded
                                      ? AppColors.textSecondary.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                                ),
                                child: Center(
                                  child: FaIcon(
                                    alreadyAdded
                                        ? FontAwesomeIcons.check
                                        : FontAwesomeIcons.dumbbell,
                                    color: alreadyAdded
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    size: 16,
                                  ),
                                ),
                              ),
                              title: Text(
                                exercise.name,
                                style: TextStyle(
                                  color: alreadyAdded
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
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
                              trailing: _GlassCircularCheckbox(
                                value: alreadyAdded ? true : isSelected,
                                disabled: alreadyAdded,
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
              color: Colors.white.withValues(alpha: 0.04),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedExercises.clear()),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing16,
                          vertical: AppSizes.spacing8,
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addSelectedFromLibrary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing16,
                          vertical: AppSizes.spacing8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.plus, size: 12, color: AppColors.primary),
                            const SizedBox(width: AppSizes.spacing8),
                            Text(
                              'Add Selected',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
    );
  }

  Widget _buildEmptyLibrary(bool isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.dumbbell, size: 48, color: AppColors.textSecondary),
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
                icon: const FaIcon(FontAwesomeIcons.plus),
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
            _GlassField(
              child: TextFormField(
                controller: _nameController,
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
                validator: (v) =>
                    Validators.required(v, fieldName: 'Exercise name'),
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            _GlassField(
              child: DropdownButtonFormField<String>(
                value: _newExerciseMuscleGroup,
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
                ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _newExerciseMuscleGroup = v);
                },
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            _GlassField(
              child: TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: AppStrings.exerciseDescription,
                  hintText: 'Optional notes',
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
            const SizedBox(height: AppSizes.spacing24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _createAndAdd(saveToLibrary: false),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                          child: Center(
                            child: Text(
                              'Add Only',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _createAndAdd(saveToLibrary: true),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                          child: Center(
                            child: Text(
                              'Add & Save',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _GlassField extends StatelessWidget {
  final Widget child;

  const _GlassField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _GlassListTile extends StatelessWidget {
  final Widget child;
  final bool highlight;

  const _GlassListTile({required this.child, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}

class _GlassCircularCheckbox extends StatelessWidget {
  final bool value;
  final bool disabled;

  const _GlassCircularCheckbox({
    required this.value,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value
            ? (disabled ? AppColors.textSecondary.withValues(alpha: 0.3) : AppColors.primary)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: value
              ? (disabled ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.primary)
              : Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: value
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.background,
              ),
            )
          : null,
    );
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
