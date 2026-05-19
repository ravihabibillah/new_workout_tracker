---
name: flutter-fl-chart-progress
description: Use when building progress/analytics screens with fl_chart in Flutter. Covers LineChart configuration, dynamic Y-axis scaling, tooltips, date-based X-axis labels, and metric/range filtering UI patterns.
---

# fl_chart Progress Screens

Patterns for building progress and analytics screens with `fl_chart`. Covers chart configuration, axis scaling, tooltips, and filter UI.

## LineChart with Dynamic Scaling

Y-axis bounds should adapt to the data, not be hardcoded. Compute min/max from values with padding:

```dart
final values = data.map((e) => (e[key] as num).toDouble()).toList();
final maxY = values.reduce((a, b) => a > b ? a : b);
final minY = values.reduce((a, b) => a < b ? a : b);
final range = (maxY - minY).abs();
final padding = range == 0 ? (maxY == 0 ? 1.0 : maxY * 0.1) : range * 0.1;
final chartMaxY = maxY + padding;
final chartMinY = (minY - padding).clamp(0, double.infinity).toDouble();
final interval = ((chartMaxY - chartMinY) / 4).clamp(1, double.infinity).toDouble();
```

Note: `.clamp()` returns `num` — call `.toDouble()` if the field expects `double` (`horizontalInterval`, `interval` parameters do).

## Full LineChart Configuration

```dart
LineChart(
  LineChartData(
    minY: chartMinY,
    maxY: chartMaxY,
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: AppColors.divider,
        strokeWidth: 1,
      ),
    ),
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: data.length > 6 ? (data.length / 5).ceilToDouble() : 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.length) {
              final date = data[index]['date'] as DateTime;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 10),
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
          getTitlesWidget: (value, meta) => Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    ),
    borderData: FlBorderData(show: false),
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) {
          return spots.map((spot) {
            final date = data[spot.x.toInt()]['date'] as DateTime;
            return LineTooltipItem(
              '${DateFormat('MMM d').format(date)}\n'
              '${spot.y.toStringAsFixed(1)} kg',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: AppColors.primary,
            strokeWidth: 2,
            strokeColor: AppColors.background,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
    ],
  ),
)
```

## Avoid Overlapping X-Axis Labels

When data has many points, set `interval` so labels don't overlap:

```dart
interval: data.length > 6 ? (data.length / 5).ceilToDouble() : 1,
```

This shows roughly 5 labels regardless of data length.

## Metric Filter UI (ChoiceChip)

Use `ChoiceChip` for selecting between metrics (max weight, total volume, max reps):

```dart
enum ProgressMetric { maxWeight, totalVolume, maxReps }

extension on ProgressMetric {
  String get label {
    switch (this) {
      case ProgressMetric.maxWeight: return 'Max Weight';
      case ProgressMetric.totalVolume: return 'Total Volume';
      case ProgressMetric.maxReps: return 'Max Reps';
    }
  }

  String get jsonKey {
    switch (this) {
      case ProgressMetric.maxWeight: return 'maxWeight';
      case ProgressMetric.totalVolume: return 'totalVolume';
      case ProgressMetric.maxReps: return 'maxReps';
    }
  }
}

Wrap(
  spacing: 8,
  children: ProgressMetric.values.map((metric) {
    final isSelected = _selectedMetric == metric;
    return ChoiceChip(
      label: Text(metric.label),
      selected: isSelected,
      labelStyle: TextStyle(
        // CRITICAL: set explicit color for both states in dark themes
        color: isSelected ? AppColors.background : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedMetric = metric),
    );
  }).toList(),
)
```

**Critical**: Always set `labelStyle` with explicit colors. Default `ChoiceChip` text color in dark themes is often invisible against the surface color when unselected.

## Date Range Filter

```dart
enum DateRangeFilter { all, last30, last90 }

extension on DateRangeFilter {
  int? get days {
    switch (this) {
      case DateRangeFilter.all: return null;
      case DateRangeFilter.last30: return 30;
      case DateRangeFilter.last90: return 90;
    }
  }
}

List<Map<String, dynamic>> _filterByRange(List<Map<String, dynamic>> data) {
  final days = _selectedRange.days;
  if (days == null) return data;
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return data
      .where((entry) => (entry['date'] as DateTime).isAfter(cutoff))
      .toList();
}
```

## Trend Card

Show delta and percent change between first and last data point:

```dart
Widget _buildTrendCard(List<Map<String, dynamic>> data) {
  if (data.length < 2) return const SizedBox.shrink();

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trend', style: textTheme.bodySmall),
                Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} '
                  '(${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%)',
                  style: textTheme.titleMedium?.copyWith(
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
```

## Empty State for Filtered Data

When the filter excludes all data, show a different message than "no data ever":

```dart
if (filtered.isEmpty)
  Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48),
            const SizedBox(height: 12),
            Text('No sessions in ${_selectedRange.label.toLowerCase()}'),
          ],
        ),
      ),
    ),
  )
```
