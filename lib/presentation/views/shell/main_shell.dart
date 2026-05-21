import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../widgets/liquid_glass.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _items = [
    GlassNavItem(
      icon: FontAwesomeIcons.house,
      label: 'Home',
    ),
    GlassNavItem(
      icon: FontAwesomeIcons.layerGroup,
      label: 'Programs',
    ),
    GlassNavItem(
      icon: FontAwesomeIcons.arrowTrendUp,
      label: 'Progress',
    ),
    GlassNavItem(
      icon: FontAwesomeIcons.clockRotateLeft,
      label: 'History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: GlassBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          items: _items,
          centerIcon: FontAwesomeIcons.play,
          onCenterTap: () => _showStartWorkoutDialog(context),
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }

  void _showStartWorkoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StartWorkoutSheet(),
    );
  }
}

class _StartWorkoutSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start Workout',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassButton(
              label: 'Quick Workout',
              icon: FontAwesomeIcons.bolt,
              width: double.infinity,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.quickWorkout);
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassButton(
              label: 'From Program',
              icon: FontAwesomeIcons.layerGroup,
              width: double.infinity,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.programs);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
