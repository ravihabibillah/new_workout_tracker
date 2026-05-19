import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/exercise_log_entity.dart';
import '../../viewmodels/workout_viewmodel.dart';
import '../../viewmodels/program_viewmodel.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String programId;

  const ActiveWorkoutScreen({super.key, required this.programId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _isInitialized = false;

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
        final program = await ref.read(programByIdProvider(widget.programId).future);
        if (program != null && mounted) {
          await ref.read(workoutViewModelProvider.notifier).startWorkout(
                program.id,
                program.name,
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
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = state.activeSession!;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showCancelConfirmation();
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
              icon: const Icon(Icons.close),
              onPressed: () async {
                final shouldCancel = await _showCancelConfirmation();
                if (shouldCancel == true && mounted) {
                  await ref.read(workoutViewModelProvider.notifier).cancelWorkout();
                  if (mounted) context.pop();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.isRestTimerActive) _buildRestTimer(state),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                itemCount: session.exerciseLogs.length,
                itemBuilder: (context, index) {
                  final exerciseLog = session.exerciseLogs[index];
                  return _buildExerciseCard(exerciseLog);
                },
              ),
            ),
            _buildBottomBar(session),
          ],
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
        color: AppColors.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: AppColors.primary),
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

  Widget _buildExerciseCard(ExerciseLogEntity exerciseLog) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
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
                      Chip(
                        label: Text(
                          exerciseLog.muscleGroup,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppColors.surfaceSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing8,
                        ),
                      ),
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
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            if (exerciseLog.sets.isEmpty)
              _buildEmptySetState(exerciseLog)
            else
              ...exerciseLog.sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return _SetRow(
                  key: ValueKey(
                    '${exerciseLog.exerciseId}-$index-${set.isCompleted}',
                  ),
                  exerciseLog: exerciseLog,
                  index: index,
                  set: set,
                );
              }),
            const SizedBox(height: AppSizes.spacing12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(workoutViewModelProvider.notifier).addSet(
                        exerciseLog.exerciseId,
                      );
                },
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addSet),
              ),
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
        color: AppColors.surfaceSecondary,
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: session.completedSets > 0 ? _finishWorkout : null,
          icon: const Icon(Icons.check),
          label: const Text(AppStrings.finishWorkout),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(workoutViewModelProvider.notifier).finishWorkout();
        if (mounted) {
          context.pop();
          context.showSnackBar('Workout completed! Great job! 💪');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to finish workout');
        }
      }
    }
  }

  Future<bool?> _showCancelConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cancelWorkout),
        content: const Text(
          'Are you sure you want to cancel this workout? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Workout'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.error),
            ),
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
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: set.isCompleted
            ? AppColors.success.withOpacity(0.1)
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: set.isCompleted ? AppColors.success : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: set.isCompleted ? AppColors.success : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: set.isCompleted ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    focusNode: _weightFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !set.isCompleted,
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
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    focusNode: _repsFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !set.isCompleted,
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
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          if (!set.isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.success,
              onPressed: () {
                ref.read(workoutViewModelProvider.notifier).completeSet(
                      exerciseLog.exerciseId,
                      index,
                    );
              },
            )
          else
            const Icon(Icons.check_circle, color: AppColors.success),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            onPressed: () {
              ref.read(workoutViewModelProvider.notifier).deleteSet(
                    exerciseLog.exerciseId,
                    index,
                  );
            },
          ),
        ],
      ),
    );
  }
}
