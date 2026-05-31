export 'haptic_feedback_stub.dart'
    if (dart.library.io) 'haptic_feedback_mobile.dart'
    if (dart.library.html) 'haptic_feedback_web.dart';
