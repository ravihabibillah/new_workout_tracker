import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/program_viewmodel.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/responsive_layout.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _labels = ['Home', 'Programs', 'Progress', 'History'];
  static const _icons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.layerGroup,
    FontAwesomeIcons.arrowTrendUp,
    FontAwesomeIcons.clockRotateLeft,
  ];

  static const _items = [
    GlassNavItem(icon: FontAwesomeIcons.house, label: 'Home'),
    GlassNavItem(icon: FontAwesomeIcons.layerGroup, label: 'Programs'),
    GlassNavItem(icon: FontAwesomeIcons.arrowTrendUp, label: 'Progress'),
    GlassNavItem(icon: FontAwesomeIcons.clockRotateLeft, label: 'History'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(
        navigationShell: navigationShell,
        items: _items,
        onTap: _onTap,
        onStartWorkout: () => _showStartWorkoutDialog(context),
      ),
      desktop: _DesktopShell(
        navigationShell: navigationShell,
        labels: _labels,
        icons: _icons,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        onStartWorkout: () => _showStartWorkoutDialog(context),
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

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback onStartWorkout;

  const _MobileShell({
    required this.navigationShell,
    required this.items,
    required this.onTap,
    required this.onStartWorkout,
  });

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
          items: items,
          centerIcon: FontAwesomeIcons.play,
          onCenterTap: onStartWorkout,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<String> labels;
  final List<IconData> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onStartWorkout;

  const _DesktopShell({
    required this.navigationShell,
    required this.labels,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _SideNav(
            labels: labels,
            icons: icons,
            currentIndex: currentIndex,
            onTap: onTap,
            onStartWorkout: onStartWorkout,
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF2A2A2A)),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onStartWorkout;

  const _SideNav({
    required this.labels,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Heft',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(labels.length, (i) => _SideNavItem(
              icon: icons[i],
              label: labels[i],
              isSelected: currentIndex == i,
              onTap: () => onTap(i),
            )),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStartWorkout,
                  icon: const FaIcon(FontAwesomeIcons.play, size: 14),
                  label: const Text('Start Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : const Color(0xFF888888),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : const Color(0xFF888888),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWorkoutSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StartWorkoutSheet> createState() => _StartWorkoutSheetState();
}

class _StartWorkoutSheetState extends ConsumerState<_StartWorkoutSheet> {
  bool _showingPrograms = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_showingPrograms)
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft,
                        size: 16, color: Colors.white),
                    onPressed: () => setState(() => _showingPrograms = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_showingPrograms) const SizedBox(width: 8),
                Text(
                  _showingPrograms ? 'Choose Program' : 'Start Workout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _showingPrograms ? _buildProgramList() : _buildMainOptions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GlassButton(
            label: 'Quick Workout',
            icon: FontAwesomeIcons.bolt,
            width: double.infinity,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.quickWorkout);
            },
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'From Program',
            icon: FontAwesomeIcons.layerGroup,
            width: double.infinity,
            onTap: () => setState(() => _showingPrograms = true),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramList() {
    final state = ref.watch(programViewModelProvider);

    if (state.isLoading && state.programs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.programs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.dumbbell,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No programs yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.programs.length,
        itemBuilder: (context, index) {
          final program = state.programs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.workout.replaceAll(':programId', program.id),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        program.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${program.exercises.length} exercises',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FaIcon(FontAwesomeIcons.play,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
