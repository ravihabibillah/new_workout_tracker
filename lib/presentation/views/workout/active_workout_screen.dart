import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_log_entity.dart';
import '../../../domain/entities/workout_session_entity.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/shimmer_loading.dart';
import '../../viewmodels/workout_viewmodel.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../exercise/exercise_picker_dialog.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? programId;

  const ActiveWorkoutScreen({super.key, this.programId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _isInitialized = false;
  bool _isAddingExercise = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkout();
    });
  }

  Future<void> _initializeWorkout() async {
    if (_isInitialized) return;

    final workoutState = ref.read(workoutViewModelProvider);
    if (workoutState.activeSession == null) {
      try {
        if (widget.programId == null) {
          await ref
              .read(workoutViewModelProvider.notifier)
              .startQuickWorkout();
          if (mounted) setState(() => _isInitialized = true);
          return;
        }

        final program = await ref.read(programByIdProvider(widget.programId!).future);
        if (program != null && mounted) {
          await ref.read(workoutViewModelProvider.notifier).startWorkout(
                program.id,
                program.name,
                useRestTimer: program.useRestTimer,
                restTimerDuration: program.restTimerDuration,
              );

          for (final exercise in program.exercises) {
            await ref.read(workoutViewModelProvider.notifier).addExerciseLog(
                  exercise.id,
                  exercise.name,
                  exercise.muscleGroup,
                );
          }
          setState(() => _isInitialized = true);
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to start workout');
          context.pop();
        }
      }
    } else {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutViewModelProvider);

    if (!_isInitialized || state.activeSession == null) {
      return GlassScaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: const ShimmerWorkoutScreen(),
        ),
      );
    }

    final session = state.activeSession!;

    return PopScope(
      canPop: true,
      child: GlassScaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.programName),
              Text(
                '${session.completedSets}/${session.totalSets} sets',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.stopwatch),
              tooltip: 'Set timer',
              onPressed: () => _showTimerPickerDialog(),
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trashCan),
              tooltip: 'Cancel workout',
              color: AppColors.error,
              onPressed: () async {
                final shouldCancel = await _showCancelConfirmation();
                if (shouldCancel == true && mounted) {
                  await ref.read(workoutViewModelProvider.notifier).cancelWorkout();
                  if (mounted && context.mounted) context.pop();
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: Column(
            children: [
              if (state.isRestTimerActive) _buildRestTimer(state),
              Expanded(
                child: _isAddingExercise
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.spacing16),
                        itemCount: session.exerciseLogs.length,
                        itemBuilder: (context, index) {
                          final exerciseLog = session.exerciseLogs[index];
                          return _buildExerciseCard(exerciseLog, key: ValueKey(exerciseLog.exerciseId));
                        },
                      ),
              ),
              _buildBottomBar(session),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestTimer(WorkoutState state) {
    final seconds = state.restTimerSeconds ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.stopwatch, color: AppColors.primary),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Timer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(workoutViewModelProvider.notifier).extendRestTimer(30);
            },
            child: const Text('+30s'),
          ),
          const SizedBox(width: AppSizes.spacing8),
          TextButton(
            onPressed: () {
              ref.read(workoutViewModelProvider.notifier).skipRestTimer();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseLogEntity exerciseLog, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseLog.exerciseName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSizes.spacing4),
                        GlassChip(label: exerciseLog.muscleGroup),
                      ],
                    ),
                  ),
                  Text(
                    '${exerciseLog.completedSetsCount}/${exerciseLog.sets.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                    color: AppColors.error,
                    tooltip: 'Remove exercise',
                    onPressed: () => _confirmRemoveExercise(exerciseLog),
                  ),
                ],
              ),
            const SizedBox(height: AppSizes.spacing16),
            if (exerciseLog.sets.isEmpty)
              _buildEmptySetState(exerciseLog)
            else
              ...exerciseLog.sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Dismissible(
                  key: ValueKey('${exerciseLog.exerciseId}-set-$index'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(workoutViewModelProvider.notifier).deleteSet(
                          exerciseLog.exerciseId,
                          index,
                        );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSizes.spacing16),
                    child: const FaIcon(
                      FontAwesomeIcons.trashCan,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  child: _SetRow(
                    key: ValueKey('${exerciseLog.exerciseId}-setrow-$index'),
                    exerciseLog: exerciseLog,
                    index: index,
                    set: set,
                  ),
                );
              }),
            const SizedBox(height: AppSizes.spacing12),
            GlassButton(
              label: AppStrings.addSet,
              icon: FontAwesomeIcons.plus,
              width: double.infinity,
              onTap: () {
                ref.read(workoutViewModelProvider.notifier).addSet(
                      exerciseLog.exerciseId,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySetState(ExerciseLogEntity exerciseLog) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Center(
        child: Text(
          'No sets added yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(session) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.spacing16,
          AppSizes.spacing12,
          AppSizes.spacing16,
          AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassButton(
              label: 'Add Exercise',
              icon: FontAwesomeIcons.plus,
              width: double.infinity,
              onTap: _addExerciseToWorkout,
            ),
            const SizedBox(height: AppSizes.spacing8),
            GlassButton(
              label: AppStrings.finishWorkout,
              icon: FontAwesomeIcons.check,
              width: double.infinity,
              filled: true,
              onTap: session.completedSets > 0 ? _finishWorkout : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExerciseToWorkout() async {
    final session = ref.read(workoutViewModelProvider).activeSession;
    if (session == null) return;

    final existingExercises = session.exerciseLogs
        .map((log) => ExerciseEntity(
              id: log.exerciseId,
              name: log.exerciseName,
              muscleGroup: log.muscleGroup,
              order: 0,
            ))
        .toList();

    final picked = await showExercisePickerDialog(
      context,
      existingExercises: existingExercises,
    );

    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _isAddingExercise = true);
      try {
        for (final exercise in picked) {
          await ref.read(workoutViewModelProvider.notifier).addExerciseLog(
                exercise.id,
                exercise.name,
                exercise.muscleGroup,
              );
        }
      } finally {
        if (mounted) setState(() => _isAddingExercise = false);
      }
    }
  }

  Future<void> _confirmRemoveExercise(ExerciseLogEntity exerciseLog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: 'Remove Exercise',
        content: Text(
          'Remove "${exerciseLog.exerciseName}" from this workout? All sets logged for this exercise will be lost.',
        ),
        actions: [
          GlassDialogButton(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(context, false),
          ),
          GlassDialogButton(
            label: AppStrings.delete,
            color: AppColors.error,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(workoutViewModelProvider.notifier)
          .removeExerciseLog(exerciseLog.exerciseId);
    }
  }

  Future<void> _finishWorkout() async {
    final session = ref.read(workoutViewModelProvider).activeSession;
    if (session == null) return;

    if (session.completedSets == 0) {
      context.showSnackBar(
        'Complete at least one set before finishing the workout.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: 'Finish Workout',
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          GlassDialogButton(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(context, false),
          ),
          GlassDialogButton(
            label: AppStrings.confirm,
            isPrimary: true,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(workoutViewModelProvider.notifier).finishWorkout();
        if (mounted) {
          if (session.isQuickWorkout && session.exerciseLogs.isNotEmpty) {
            await _showSaveAsProgramDialog(session);
          }
          if (mounted) {
            context.pop();
            context.showSnackBar('Workout completed! Great job!');
          }
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to finish workout');
        }
      }
    }
  }

  Future<void> _showSaveAsProgramDialog(WorkoutSessionEntity session) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _SaveAsProgramDialog(),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      final exercises = session.exerciseLogs
          .map((log) => ExerciseEntity(
                id: log.exerciseId,
                name: log.exerciseName,
                muscleGroup: log.muscleGroup,
                order: 0,
              ))
          .toList();

      await ref.read(programViewModelProvider.notifier).createProgram(
            name: result.trim(),
            exercises: exercises,
          );

      if (mounted) {
        context.showSnackBar('Program saved!');
      }
    }
  }

  Future<void> _showTimerPickerDialog() async {
    final seconds = await showDialog<int>(
      context: context,
      builder: (context) => const _TimerPickerDialog(),
    );

    if (seconds != null && seconds > 0 && mounted) {
      ref
          .read(workoutViewModelProvider.notifier)
          .startRestTimer(seconds, vibrateOnComplete: true);
    }
  }

  Future<bool?> _showCancelConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: AppStrings.cancelWorkout,
        content: const Text(
          'Are you sure you want to cancel this workout? All progress will be lost.',
        ),
        actions: [
          GlassDialogButton(
            label: 'Continue Workout',
            onTap: () => Navigator.pop(context, false),
          ),
          GlassDialogButton(
            label: AppStrings.cancel,
            color: AppColors.error,
            isPrimary: true,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

/// Format a numeric value for display in a text field without forcing a
/// trailing `.0` on whole numbers, so users can type values like `5` or `5.5`
/// freely.
String _formatNumber(num value) {
  if (value is int) return value.toString();
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({
    super.key,
    required this.exerciseLog,
    required this.index,
    required this.set,
  });

  final ExerciseLogEntity exerciseLog;
  final int index;
  final dynamic set;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final FocusNode _weightFocusNode;
  late final FocusNode _repsFocusNode;

  @override
  void initState() {
    super.initState();
    _weightController =
        TextEditingController(text: _formatNumber(widget.set.weight));
    _repsController =
        TextEditingController(text: _formatNumber(widget.set.reps));
    _weightFocusNode = FocusNode()..addListener(_onWeightFocus);
    _repsFocusNode = FocusNode()..addListener(_onRepsFocus);
  }

  void _onWeightFocus() {
    if (_weightFocusNode.hasFocus) {
      _weightController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _weightController.text.length,
      );
    }
  }

  void _onRepsFocus() {
    if (_repsFocusNode.hasFocus) {
      _repsController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _repsController.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync the field text from state when the underlying value changed
    // due to something other than the user's own typing (e.g. set completed,
    // reset, or programmatic update). This keeps the user's in-progress input
    // intact while still reflecting external changes.
    final newWeightText = _formatNumber(widget.set.weight);
    if (oldWidget.set.weight != widget.set.weight &&
        _weightController.text != newWeightText) {
      _weightController.text = newWeightText;
    }
    final newRepsText = _formatNumber(widget.set.reps);
    if (oldWidget.set.reps != widget.set.reps &&
        _repsController.text != newRepsText) {
      _repsController.text = newRepsText;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseLog = widget.exerciseLog;
    final index = widget.index;
    final set = widget.set;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing12,
        vertical: AppSizes.spacing8,
      ),
      decoration: BoxDecoration(
        color: set.isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: set.isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: set.isCompleted
                  ? AppColors.success.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: set.isCompleted
                    ? AppColors.success.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: set.isCompleted
                      ? AppColors.success
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextFormField(
                      controller: _weightController,
                      focusNode: _weightFocusNode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'kg',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing8,
                          vertical: AppSizes.spacing8,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final weight = double.tryParse(value);
                        if (weight != null) {
                          ref
                              .read(workoutViewModelProvider.notifier)
                              .updateSet(
                                exerciseLog.exerciseId,
                                index,
                                weight: weight,
                              );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextFormField(
                      controller: _repsController,
                      focusNode: _repsFocusNode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'reps',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing8,
                          vertical: AppSizes.spacing8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final reps = int.tryParse(value);
                        if (reps != null) {
                          ref
                              .read(workoutViewModelProvider.notifier)
                              .updateSet(
                                exerciseLog.exerciseId,
                                index,
                                reps: reps,
                              );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          GestureDetector(
            onTap: () {
              if (set.isCompleted) {
                ref.read(workoutViewModelProvider.notifier).uncompleteSet(
                      exerciseLog.exerciseId,
                      index,
                    );
              } else {
                ref.read(workoutViewModelProvider.notifier).completeSet(
                      exerciseLog.exerciseId,
                      index,
                    );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: set.isCompleted
                    ? AppColors.success
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: set.isCompleted
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: set.isCompleted
                  ? const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          if (set.isCompleted &&
              ref.watch(workoutViewModelProvider).activeSession?.useRestTimer ==
                  true) ...[
            const SizedBox(width: AppSizes.spacing4),
            GlassIconButton(
              icon: FontAwesomeIcons.stopwatch,
              color: AppColors.primary,
              size: 36,
              iconSize: 14,
              tooltip: 'Start rest timer',
              onTap: () {
                final duration = ref
                        .read(workoutViewModelProvider)
                        .activeSession
                        ?.restTimerDuration ??
                    90;
                ref
                    .read(workoutViewModelProvider.notifier)
                    .startRestTimer(duration);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveAsProgramDialog extends StatefulWidget {
  const _SaveAsProgramDialog();

  @override
  State<_SaveAsProgramDialog> createState() => _SaveAsProgramDialogState();
}

class _SaveAsProgramDialogState extends State<_SaveAsProgramDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Save as Program?',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Would you like to save this workout as a reusable program?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacing16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program name',
                hintText: 'e.g., My Custom Workout',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16,
                  vertical: AppSizes.spacing12,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ],
      ),
      actions: [
        GlassDialogButton(
          label: 'No thanks',
          onTap: () => Navigator.pop(context),
        ),
        GlassDialogButton(
          label: 'Save',
          isPrimary: true,
          onTap: () => Navigator.pop(context, _nameController.text),
        ),
      ],
    );
  }
}

class _TimerPickerDialog extends StatefulWidget {
  const _TimerPickerDialog();

  @override
  State<_TimerPickerDialog> createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<_TimerPickerDialog> {
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final FocusNode _minutesFocus;
  late final FocusNode _secondsFocus;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '1');
    _secondsController = TextEditingController(text: '30');
    _minutesFocus = FocusNode()..addListener(_onMinutesFocus);
    _secondsFocus = FocusNode()..addListener(_onSecondsFocus);
  }

  void _onMinutesFocus() {
    if (_minutesFocus.hasFocus) {
      _minutesController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _minutesController.text.length,
      );
    }
  }

  void _onSecondsFocus() {
    if (_secondsFocus.hasFocus) {
      _secondsController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _secondsController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocus.dispose();
    _secondsFocus.dispose();
    super.dispose();
  }

  int get _minutes => int.tryParse(_minutesController.text) ?? 0;
  int get _seconds => int.tryParse(_secondsController.text) ?? 0;
  int get _totalSeconds => (_minutes * 60 + _seconds).clamp(0, 600);

  void _adjustTime(int delta) {
    final newTotal = (_totalSeconds + delta).clamp(0, 600);
    final newMinutes = newTotal ~/ 60;
    final newSeconds = newTotal % 60;
    setState(() {
      _minutesController.text = newMinutes.toString();
      _secondsController.text = newSeconds.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Set Timer',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextField(
                      controller: _minutesController,
                      focusNode: _minutesFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  Text(
                    'min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextField(
                      controller: _secondsController,
                      focusNode: _secondsFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  Text(
                    'sec',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassButton(
                label: '-15s',
                onTap: _totalSeconds >= 15 ? () => _adjustTime(-15) : null,
              ),
              const SizedBox(width: AppSizes.spacing12),
              GlassButton(
                label: '+15s',
                onTap: _totalSeconds < 600 ? () => _adjustTime(15) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'Total: ${_formatDuration(_totalSeconds)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      actions: [
        GlassDialogButton(
          label: 'Cancel',
          onTap: () => Navigator.pop(context),
        ),
        GlassDialogButton(
          label: 'Start',
          isPrimary: true,
          onTap: _totalSeconds > 0
              ? () => Navigator.pop(context, _totalSeconds)
              : null,
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
}
