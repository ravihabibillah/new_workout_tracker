import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';
import '../exercise/exercise_picker_dialog.dart';

class CreateProgramScreen extends ConsumerStatefulWidget {
  final String? programId;

  const CreateProgramScreen({super.key, this.programId});

  @override
  ConsumerState<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends ConsumerState<CreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ExerciseEntity> _exercises = [];
  bool _isLoading = false;
  bool _useRestTimer = false;
  int _restTimerDuration = 90;

  @override
  void initState() {
    super.initState();
    if (widget.programId != null) {
      _loadProgram();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProgram() async {
    setState(() => _isLoading = true);
    try {
      final program = await ref.read(programByIdProvider(widget.programId!).future);
      if (program != null && mounted) {
        setState(() {
          _nameController.text = program.name;
          _descriptionController.text = program.description ?? '';
          _exercises.addAll(program.exercises);
          _useRestTimer = program.useRestTimer;
          _restTimerDuration = program.restTimerDuration;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showErrorSnackBar('Failed to load program');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.programId != null;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editProgram : AppStrings.createProgram),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.floppyDisk, color: AppColors.primary),
              tooltip: AppStrings.save,
              onPressed: _saveProgram,
            ),
        ],
      ),
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: const ShimmerWorkoutScreen(),
            )
          : Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.spacing16,
                      AppSizes.spacing16,
                      AppSizes.spacing16,
                      AppSizes.spacing64 + AppSizes.spacing32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgramInfoSection(),
                        const SizedBox(height: AppSizes.spacing24),
                        _buildRestTimerSection(),
                        const SizedBox(height: AppSizes.spacing24),
                        _buildExercisesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: LiquidGlass(
        tintColor: AppColors.primary,
        tintOpacity: 0.25,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing16,
        ),
        onTap: _showAddExerciseDialog,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.plus, color: AppColors.primary, size: 16),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              AppStrings.addExercise,
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

  Widget _buildProgramInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          _GlassInputField(
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.programName,
                hintText: 'e.g., Push Day A',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16,
                  vertical: AppSizes.spacing12,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.dumbbell, size: 18, color: AppColors.primary),
                ),
                errorStyle: TextStyle(
                  color: AppColors.error.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.5,
                ),
                errorMaxLines: 2,
              ),
              validator: (value) => Validators.required(value, fieldName: 'Program name'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          _GlassInputField(
            child: TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: AppStrings.programDescription,
                hintText: 'Optional description',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16,
                  vertical: AppSizes.spacing12,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.fileLines, size: 18, color: AppColors.primary),
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.stopwatch, color: AppColors.primary),
              const SizedBox(width: AppSizes.spacing8),
              Expanded(
                child: Text(
                  'Rest Timer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              GlassSwitch(
                value: _useRestTimer,
                onChanged: (value) {
                  setState(() => _useRestTimer = value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            _useRestTimer
                ? 'Tap the timer button after completing a set to start the countdown.'
                : 'Enable to show a manual rest timer button on completed sets.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (_useRestTimer) ...[
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'Duration: ${_formatDuration(_restTimerDuration)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Slider(
              value: _restTimerDuration.toDouble(),
              min: 30,
              max: 300,
              divisions: 27,
              label: _formatDuration(_restTimerDuration),
              activeColor: AppColors.primary,
              inactiveColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _restTimerDuration = value.round());
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (minutes == 0) return '${remaining}s';
    if (remaining == 0) return '${minutes}m';
    return '${minutes}m ${remaining}s';
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${_exercises.length} exercises',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),
        if (_exercises.isEmpty)
          _buildEmptyExercisesState()
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _exercises.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final exercise = _exercises.removeAt(oldIndex);
                _exercises.insert(newIndex, exercise);
                for (int i = 0; i < _exercises.length; i++) {
                  _exercises[i] = _exercises[i].copyWith(order: i);
                }
              });
            },
            itemBuilder: (context, index) {
              final exercise = _exercises[index];
              return Padding(
                key: ValueKey(exercise.id),
                padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                child: Dismissible(
                  key: ValueKey('dismiss-${exercise.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeExercise(index),
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const FaIcon(
                      FontAwesomeIcons.trashCan,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSizes.spacing12),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSizes.spacing8),
                            child: FaIcon(FontAwesomeIcons.gripLines,
                                color: AppColors.textSecondary, size: 18),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyExercisesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacing32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.dumbbell,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No exercises added yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Tap the + button to add exercises',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog() async {
    final exercises = await showExercisePickerDialog(
      context,
      existingExercises: _exercises,
    );

    if (exercises != null && exercises.isNotEmpty && mounted) {
      setState(() {
        for (final exercise in exercises) {
          _exercises.add(exercise.copyWith(order: _exercises.length));
        }
      });
      context.showSnackBar(
        exercises.length == 1
            ? 'Exercise added'
            : '${exercises.length} exercises added',
      );
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = _exercises[i].copyWith(order: i);
      }
    });
    context.showSnackBar('Exercise removed');
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_exercises.isEmpty) {
      context.showErrorSnackBar('Please add at least one exercise');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.programId != null;

      if (isEditing) {
        final existingProgram = await ref.read(
          programByIdProvider(widget.programId!).future,
        );
        if (existingProgram != null) {
          final updatedProgram = existingProgram.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            exercises: _exercises,
            useRestTimer: _useRestTimer,
            restTimerDuration: _restTimerDuration,
          );
          await ref.read(programViewModelProvider.notifier).updateProgram(updatedProgram);
        }
      } else {
        await ref.read(programViewModelProvider.notifier).createProgram(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              exercises: _exercises,
              useRestTimer: _useRestTimer,
              restTimerDuration: _restTimerDuration,
            );
      }

      if (mounted) {
        context.pop();
        context.showSnackBar(
          isEditing ? 'Program updated successfully' : 'Program created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showErrorSnackBar('Failed to save program');
      }
    }
  }
}

class _GlassInputField extends StatelessWidget {
  final Widget child;

  const _GlassInputField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
      child: child,
    );
  }
}
