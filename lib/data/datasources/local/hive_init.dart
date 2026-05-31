export 'hive_init_stub.dart'
    if (dart.library.io) 'hive_init_mobile.dart'
    if (dart.library.html) 'hive_init_web.dart';
