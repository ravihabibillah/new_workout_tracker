import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_log_entity.dart';
import '../../../domain/entities/workout_session_entity.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = state.activeSession!;

    return WillPopScope(
      onWillPop: () async {
        return true;
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
              icon: const Icon(Icons.timer_outlined),
              tooltip: 'Set timer',
              onPressed: () => _showTimerPickerDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Cancel workout',
              color: AppColors.error,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _addExerciseToWorkout,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            ElevatedButton.icon(
              onPressed: session.completedSets > 0 ? _finishWorkout : null,
              icon: const Icon(Icons.check),
              label: const Text(AppStrings.finishWorkout),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
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
      for (final exercise in picked) {
        await ref.read(workoutViewModelProvider.notifier).addExerciseLog(
              exercise.id,
              exercise.name,
              exercise.muscleGroup,
            );
      }
    }
  }

  Future<void> _finishWorkout() async {
    final session = ref.read(workoutViewModelProvider).activeSession;
    if (session == null) return;

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
              tooltip: 'Mark as completed',
              onPressed: () {
                ref.read(workoutViewModelProvider.notifier).completeSet(
                      exerciseLog.exerciseId,
                      index,
                    );
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              color: AppColors.success,
              tooltip: 'Tap to edit this set',
              onPressed: () {
                ref.read(workoutViewModelProvider.notifier).uncompleteSet(
                      exerciseLog.exerciseId,
                      index,
                    );
              },
            ),
            if (ref.watch(workoutViewModelProvider).activeSession?.useRestTimer == true)
              IconButton(
                icon: const Icon(Icons.timer, size: 20),
                color: AppColors.primary,
                tooltip: 'Start rest timer',
                onPressed: () {
                  final duration = ref.read(workoutViewModelProvider).activeSession?.restTimerDuration ?? 90;
                  ref.read(workoutViewModelProvider.notifier).startRestTimer(duration);
                },
              ),
          ],
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
    return AlertDialog(
      title: const Text('Save as Program?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Would you like to save this workout as a reusable program?'),
          const SizedBox(height: AppSizes.spacing16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Program name',
              hintText: 'e.g., My Custom Workout',
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No thanks'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _nameController.text),
          child: const Text('Save'),
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
    return AlertDialog(
      title: const Text('Set Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _minutesController,
                      focusNode: _minutesFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _secondsController,
                      focusNode: _secondsFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
              OutlinedButton(
                onPressed: _totalSeconds >= 15
                    ? () => _adjustTime(-15)
                    : null,
                child: const Text('-15s'),
              ),
              const SizedBox(width: AppSizes.spacing12),
              OutlinedButton(
                onPressed: _totalSeconds < 600
                    ? () => _adjustTime(15)
                    : null,
                child: const Text('+15s'),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _totalSeconds > 0
              ? () => Navigator.pop(context, _totalSeconds)
              : null,
          child: const Text('Start'),
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
