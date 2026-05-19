import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../viewmodels/progress_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';

enum ProgressMetric { maxWeight, totalVolume, maxReps }

extension on ProgressMetric {
  String get label {
    switch (this) {
      case ProgressMetric.maxWeight:
        return 'Max Weight';
      case ProgressMetric.totalVolume:
        return 'Total Volume';
      case ProgressMetric.maxReps:
        return 'Max Reps';
    }
  }

  String get jsonKey {
    switch (this) {
      case ProgressMetric.maxWeight:
        return 'maxWeight';
      case ProgressMetric.totalVolume:
        return 'totalVolume';
      case ProgressMetric.maxReps:
        return 'maxReps';
    }
  }

  String get unit {
    switch (this) {
      case ProgressMetric.maxWeight:
      case ProgressMetric.totalVolume:
        return 'kg';
      case ProgressMetric.maxReps:
        return '';
    }
  }
}

enum DateRangeFilter { all, last30, last90 }

extension on DateRangeFilter {
  String get label {
    switch (this) {
      case DateRangeFilter.all:
        return 'All time';
      case DateRangeFilter.last30:
        return 'Last 30 days';
      case DateRangeFilter.last90:
        return 'Last 90 days';
    }
  }

  int? get days {
    switch (this) {
      case DateRangeFilter.all:
        return null;
      case DateRangeFilter.last30:
        return 30;
      case DateRangeFilter.last90:
        return 90;
    }
  }
}

class ExerciseProgressScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends ConsumerState<ExerciseProgressScreen> {
  ProgressMetric _selectedMetric = ProgressMetric.maxWeight;
  DateRangeFilter _selectedRange = DateRangeFilter.all;

  @override
  Widget build(BuildContext context) {
    final progressAsync =
        ref.watch(exerciseProgressDataProvider(widget.exerciseName));
    final recordsAsync =
        ref.watch(exercisePersonalRecordsProvider(widget.exerciseName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.exerciseName),
      ),
      body: progressAsync.when(
        data: (progressData) => recordsAsync.when(
          data: (records) => _buildContent(context, progressData, records),
          loading: () => const ShimmerProgressScreen(),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const ShimmerProgressScreen(),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  List<Map<String, dynamic>> _filterByRange(
    List<Map<String, dynamic>> data,
  ) {
    final days = _selectedRange.days;
    if (days == null) return data;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return data
        .where((entry) => (entry['date'] as DateTime).isAfter(cutoff))
        .toList();
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> progressData,
    Map<String, dynamic> records,
  ) {
    if (progressData.isEmpty) {
      return _buildEmptyState(context);
    }

    final filtered = _filterByRange(progressData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalRecords(context, records, progressData.length),
          const SizedBox(height: AppSizes.spacing24),
          _buildFilterBar(context),
          const SizedBox(height: AppSizes.spacing16),
          if (filtered.isEmpty)
            _buildNoDataInRangeCard(context)
          else ...[
            _buildTrendCard(context, filtered),
            const SizedBox(height: AppSizes.spacing16),
            _buildChart(context, filtered),
            const SizedBox(height: AppSizes.spacing24),
            _buildRecentSessions(context, filtered),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metric',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing8,
              children: ProgressMetric.values.map((metric) {
                final isSelected = _selectedMetric == metric;
                return ChoiceChip(
                  label: Text(metric.label),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedMetric = metric),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'Date range',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing8,
              children: DateRangeFilter.values.map((range) {
                final isSelected = _selectedRange == range;
                return ChoiceChip(
                  label: Text(range.label),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedRange = range),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecords(
    BuildContext context,
    Map<String, dynamic> records,
    int sessionCount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Records',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RecordItem(
                  icon: Icons.fitness_center,
                  label: 'Max Weight',
                  value:
                      '${records['maxWeight']?.toStringAsFixed(1) ?? '0'} kg',
                ),
                _RecordItem(
                  icon: Icons.repeat,
                  label: 'Max Reps',
                  value: '${records['maxReps'] ?? 0}',
                ),
                _RecordItem(
                  icon: Icons.trending_up,
                  label: 'Max Volume',
                  value:
                      '${records['maxVolume']?.toStringAsFixed(0) ?? '0'} kg',
                ),
              ],
            ),
            const Divider(height: AppSizes.spacing32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.spacing4),
                Text(
                  '$sessionCount total sessions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    if (data.length < 2) return const SizedBox.shrink();

    final key = _selectedMetric.jsonKey;
    final first = (data.first[key] as num).toDouble();
    final last = (data.last[key] as num).toDouble();
    final delta = last - first;
    final percent = first > 0 ? (delta / first) * 100 : 0;
    final isUp = delta > 0;
    final isFlat = delta == 0;

    final color = isFlat
        ? AppColors.textSecondary
        : (isUp ? AppColors.success : AppColors.error);
    final icon = isFlat
        ? Icons.trending_flat
        : (isUp ? Icons.trending_up : Icons.trending_down);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedMetric.label} trend',
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} ${_selectedMetric.unit} '
                    '(${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    final key = _selectedMetric.jsonKey;
    final values = data.map((e) => (e[key] as num).toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final range = (maxY - minY).abs();
    final padding = range == 0 ? (maxY == 0 ? 1.0 : maxY * 0.1) : range * 0.1;
    final chartMaxY = maxY + padding;
    final chartMinY = (minY - padding).clamp(0, double.infinity).toDouble();
    final interval = ((chartMaxY - chartMinY) / 4).clamp(1, double.infinity).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: AppColors.primary),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  '${_selectedMetric.label} Over Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: data.length > 6
                            ? (data.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = data[index]['date'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final index = spot.x.toInt();
                          final date =
                              data[index]['date'] as DateTime;
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n'
                            '${spot.y.toStringAsFixed(1)} ${_selectedMetric.unit}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value[key] as num).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.background,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    final recentSessions = data.reversed.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        ...recentSessions.map((session) {
          final date = session['date'] as DateTime;
          final maxWeight = session['maxWeight'] as num;
          final totalVolume = session['totalVolume'] as num;
          final maxReps = session['maxReps'] as num;
          final sets = session['sets'] as int;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          DateFormat('dd').format(date),
                          style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(date),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$sets sets',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SessionMetric(
                        label: 'Max',
                        value: '${maxWeight.toStringAsFixed(1)} kg',
                      ),
                      _SessionMetric(
                        label: 'Volume',
                        value: '${totalVolume.toStringAsFixed(0)} kg',
                      ),
                      _SessionMetric(
                        label: 'Top Reps',
                        value: '$maxReps',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoDataInRangeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSizes.spacing12),
              Text(
                'No sessions in ${_selectedRange.label.toLowerCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
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
              Icons.bar_chart,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing24),
            Text(
              'No progress data yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              'Complete workouts with this exercise to see progress',
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
}

class _RecordItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecordItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SessionMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SessionMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
