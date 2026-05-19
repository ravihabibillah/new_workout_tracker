import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceSecondary,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSizes.radiusSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
        child: Row(
          children: [
            const ShimmerBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 16),
                  const SizedBox(height: AppSizes.spacing8),
                  ShimmerBox(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }
}

class ShimmerProgramList extends StatelessWidget {
  final int itemCount;

  const ShimmerProgramList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSizes.spacing12),
          child: ShimmerCard(height: 72),
        ),
      ),
    );
  }
}

class ShimmerExerciseList extends StatelessWidget {
  final int itemCount;

  const ShimmerExerciseList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSizes.spacing16),
      itemBuilder: (context, index) => const ShimmerListItem(),
    );
  }
}

class ShimmerWorkoutScreen extends StatelessWidget {
  const ShimmerWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 200, height: 24),
            const SizedBox(height: AppSizes.spacing8),
            const ShimmerBox(width: 100, height: 16),
            const SizedBox(height: AppSizes.spacing24),
            const ShimmerCard(height: 200),
            const SizedBox(height: AppSizes.spacing16),
            const ShimmerCard(height: 200),
          ],
        ),
      ),
    );
  }
}

class ShimmerProgressScreen extends StatelessWidget {
  const ShimmerProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerCard(height: 120),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(child: ShimmerCard(height: 100)),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(child: ShimmerCard(height: 100)),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            const ShimmerCard(height: 250),
          ],
        ),
      ),
    );
  }
}

class ShimmerHistoryList extends StatelessWidget {
  final int itemCount;

  const ShimmerHistoryList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSizes.spacing16),
      itemBuilder: (context, index) => const ShimmerCard(height: 140),
    );
  }
}
