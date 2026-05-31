import 'package:vibration/vibration.dart';

Future<void> vibrateIfSupported() async {
  final hasVibrator = await Vibration.hasVibrator();
  if (hasVibrator) {
    Vibration.vibrate(duration: 500, amplitude: 255);
  }
}
