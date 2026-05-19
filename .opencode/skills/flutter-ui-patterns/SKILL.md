---
name: flutter-ui-patterns
description: Use when building Flutter UI components. Covers shimmer loading states, TextEditingController lifecycle, dialog with controllers, Font Awesome icons, edge-to-edge Android display, and login button loading state patterns.
---

# Flutter UI Patterns

Reusable UI patterns for Flutter apps covering loading states, form fields, dialogs, icons, and platform-specific display.

## Shimmer Loading States

Replace `CircularProgressIndicator` with shimmer skeletons for better perceived performance. Add the `shimmer` package and create reusable skeleton widgets:

```dart
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: child,
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

Keep `CircularProgressIndicator` only for:
- Splash screen branding spinner
- Small inline button spinner (20×20, `strokeWidth: 2`)

## TextEditingController in StatefulWidget

Always create and dispose controllers in `initState`/`dispose`. Never create them inline in `build()`:

```dart
class _MyFieldState extends State<MyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatNumber(widget.value));
    _focusNode = FocusNode()..addListener(_onFocus);
  }

  void _onFocus() {
    if (_focusNode.hasFocus) {
      // Auto-select all text on focus so user can type immediately
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(covariant MyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync from external state only when value changed externally
    if (oldWidget.value != widget.value) {
      final newText = _formatNumber(widget.value);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
```

`didUpdateWidget` is critical for fields that can be updated both by user input and external state changes (e.g., a set row that can be reset programmatically).

## Dialog with TextEditingController

**Never call `controller.dispose()` after `await showDialog<T>()`**. Flutter may still rebuild widgets referencing the controller, causing "TextEditingController was used after being disposed" errors.

Always extract dialog content with controllers into a separate `StatefulWidget`:

```dart
// WRONG
Future<void> _showDialog() async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose(); // CRASH: widget tree may still reference controller
}

// CORRECT — extract to StatefulWidget
class _MyDialog extends StatefulWidget {
  const _MyDialog();
  @override
  State<_MyDialog> createState() => _MyDialogState();
}

class _MyDialogState extends State<_MyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose(); // Framework calls this at the right time
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(controller: _controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
```

## Font Awesome Icons

Use `font_awesome_flutter` for a consistent icon set. After adding the package, do `flutter clean` + full rebuild (not hot reload) — fonts need to be re-bundled.

```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Basic usage
FaIcon(FontAwesomeIcons.dumbbell)
FaIcon(FontAwesomeIcons.dumbbell, size: 24, color: Colors.white)

// In IconButton
IconButton(
  icon: const FaIcon(FontAwesomeIcons.trashCan),
  onPressed: () {},
)
```

**Always set explicit `color`** on `FaIcon` inside colored buttons. `FaIcon` does not inherit `IconTheme` from `ElevatedButton` — without explicit color, the icon may be invisible against the button background.

For `prefixIcon` in `TextField`, wrap in `Padding` because Font Awesome icons render larger than Material defaults:

```dart
TextField(
  decoration: InputDecoration(
    prefixIcon: Padding(
      padding: const EdgeInsets.all(12),
      child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 20),
    ),
  ),
)
```

Common Material → Font Awesome mapping:

| Material | Font Awesome |
|----------|-------------|
| `Icons.fitness_center` | `FontAwesomeIcons.dumbbell` |
| `Icons.add` | `FontAwesomeIcons.plus` |
| `Icons.delete` / `delete_outline` | `FontAwesomeIcons.trashCan` |
| `Icons.edit` | `FontAwesomeIcons.penToSquare` |
| `Icons.settings` | `FontAwesomeIcons.gear` |
| `Icons.search` | `FontAwesomeIcons.magnifyingGlass` |
| `Icons.history` | `FontAwesomeIcons.clockRotateLeft` |
| `Icons.trending_up` | `FontAwesomeIcons.arrowTrendUp` |
| `Icons.timer` | `FontAwesomeIcons.stopwatch` |
| `Icons.check` | `FontAwesomeIcons.check` |
| `Icons.check_circle` | `FontAwesomeIcons.solidCircleCheck` |
| `Icons.check_circle_outline` | `FontAwesomeIcons.circleCheck` |
| `Icons.close` | `FontAwesomeIcons.xmark` |
| `Icons.bar_chart` | `FontAwesomeIcons.chartColumn` |
| `Icons.logout` | `FontAwesomeIcons.rightFromBracket` |
| `Icons.flash_on` | `FontAwesomeIcons.bolt` |
| `Icons.drag_handle` | `FontAwesomeIcons.gripLines` |
| `Icons.more_vert` | `FontAwesomeIcons.ellipsisVertical` |
| `Icons.calendar_today` | `FontAwesomeIcons.calendar` |
| `Icons.access_time` | `FontAwesomeIcons.clock` |
| `Icons.repeat` | `FontAwesomeIcons.repeat` |
| `Icons.play_arrow` | `FontAwesomeIcons.play` |

## Edge-to-Edge Display (Android)

To draw behind status bar and navigation bar with transparent system bars:

1. `main.dart` — set overlay style:
```dart
import 'package:flutter/services.dart';

SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ),
);
```

2. `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
import androidx.core.view.WindowCompat

override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  WindowCompat.setDecorFitsSystemWindows(window, false)
}
```

3. `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml`:
```xml
<item name="android:windowTranslucentStatus">true</item>
<item name="android:windowTranslucentNavigation">true</item>
```

4. Set `compileSdkVersion 35` in `android/app/build.gradle`.

## Login Button Loading State

Don't reset `_isLoading = false` after successful sign-in. The screen will be replaced by router redirect, so resetting state on a disposed widget is wasteful. Only reset on error:

```dart
Future<void> _signIn() async {
  setState(() => _isLoading = true);
  try {
    await ref.read(authViewModelProvider.notifier).signIn();
    // Don't reset: router redirects to home, screen is disposed
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      context.showErrorSnackBar(e.toString());
    }
  }
}
```

## Keyboard Dismissal

For screens with forms, wrap the body in a `GestureDetector` to dismiss keyboard on tap outside:

```dart
body: GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  behavior: HitTestBehavior.opaque,
  child: SingleChildScrollView(...),
)
```

For multi-line text fields, add `textInputAction: TextInputAction.done` to show a "Done" button on the keyboard.
