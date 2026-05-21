import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double tintOpacity;
  final VoidCallback? onTap;
  final bool highlight;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = AppSizes.radiusLarge,
    this.blur = 24,
    this.padding,
    this.margin,
    this.tintColor,
    this.tintOpacity = 0.08,
    this.onTap,
    this.highlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final tint = tintColor ?? Colors.white;

    Widget content = ClipRRect(
      borderRadius: radius,
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: tintOpacity + 0.06),
                  tint.withValues(alpha: tintOpacity * 0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: highlight ? 0.18 : 0.08),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                if (highlight)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: radius,
                    splashColor: AppColors.primary.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(AppSizes.spacing16),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: content,
    );
  }
}

class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppColors.background),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(
            color: AppColors.primary.withValues(alpha: 0.35),
            size: 320,
          ),
        ),
        Positioned(
          top: 180,
          right: -100,
          child: _Blob(
            color: AppColors.chartSecondary.withValues(alpha: 0.25),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -60,
          child: _Blob(
            color: AppColors.primary.withValues(alpha: 0.18),
            size: 360,
          ),
        ),
        Positioned(
          bottom: 80,
          right: -120,
          child: _Blob(
            color: AppColors.chartTertiary.withValues(alpha: 0.18),
            size: 260,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Scaffold dengan ambient glass background dan transparent appBar
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final wrappedAppBar = appBar == null
        ? null
        : _TransparentAppBarWrapper(child: appBar!);

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: wrappedAppBar,
      body: GlassBackground(child: body),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _TransparentAppBarWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const _TransparentAppBarWrapper({required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    if (child is AppBar) {
      final original = child as AppBar;
      return AppBar(
        leading: original.leading,
        automaticallyImplyLeading: original.automaticallyImplyLeading,
        title: original.title,
        actions: original.actions,
        flexibleSpace: original.flexibleSpace,
        bottom: original.bottom,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: original.centerTitle,
        titleTextStyle: original.titleTextStyle,
        iconTheme: original.iconTheme,
        actionsIconTheme: original.actionsIconTheme,
      );
    }
    return child;
  }
}

/// Compact glass card untuk konten umum (mengganti Card)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? tintColor;
  final double tintOpacity;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.tintColor,
    this.tintOpacity = 0.08,
    this.borderRadius = AppSizes.radiusLarge,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      tintColor: tintColor,
      tintOpacity: tintOpacity,
      child: child,
    );
  }
}

/// Glass circle icon button
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final double iconSize;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = AppColors.error,
    this.size = 40,
    this.iconSize = 16,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: color.withValues(alpha: 0.2),
          child: Center(
            child: FaIcon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

/// iOS-style switch dengan tema glass
class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  const GlassSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? activeColor.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              value ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.background : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass-styled dialog dengan backdrop blur dan border
class GlassDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.radiusLarge);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSizes.spacing24),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                  ],
                  if (content != null)
                    Padding(
                      padding: contentPadding ??
                          const EdgeInsets.only(bottom: 20),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        child: content!,
                      ),
                    ),
                  if (actions != null && actions!.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSizes.spacing8),
                          actions![i],
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-styled dialog button
class GlassDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool isPrimary;

  const GlassDialogButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? (isPrimary ? AppColors.primary : AppColors.textPrimary);
    return Container(
      decoration: BoxDecoration(
        color: isPrimary
            ? btnColor.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isPrimary
              ? btnColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: btnColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-styled chip
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final bool expand;

  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.selectedColor,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: expand ? TextAlign.center : null,
          style: TextStyle(
            color: selected ? accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Glass-styled divider
class GlassDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const GlassDivider({
    super.key,
    this.height = 1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Glass-styled outlined button
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool filled;
  final double? width;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.filled = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: filled
              ? accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            child: Row(
              mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  FaIcon(icon!, size: 14, color: filled ? accent : AppColors.textPrimary),
                  const SizedBox(width: AppSizes.spacing8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-styled bottom navigation bar with floating center action button
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final VoidCallback? onCenterTap;
  final IconData? centerIcon;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onCenterTap,
    this.centerIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasCenter = onCenterTap != null;
    final leftItems = hasCenter ? items.take(2).toList() : items;
    final rightItems = hasCenter ? items.skip(2).toList() : <GlassNavItem>[];

    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(leftItems.length, (index) {
                            final item = leftItems[index];
                            final isSelected = index == currentIndex;
                            return _GlassNavItemWidget(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => onTap(index),
                            );
                          }),
                        ),
                      ),
                      if (hasCenter) const SizedBox(width: 72),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(rightItems.length, (index) {
                            final item = rightItems[index];
                            final actualIndex = index + 2;
                            final isSelected = actualIndex == currentIndex;
                            return _GlassNavItemWidget(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => onTap(actualIndex),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasCenter)
            Positioned(
              bottom: 35,
              child: _FloatingCenterButton(
                icon: centerIcon ?? FontAwesomeIcons.play,
                onTap: onCenterTap!,
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingCenterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingCenterButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 3),
            child: FaIcon(
              icon,
              color: AppColors.background,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class _GlassNavItemWidget extends StatelessWidget {
  final GlassNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FaIcon(
                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}


