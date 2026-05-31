import 'package:hive/hive.dart';

Future<void> initHive() async {
  Hive.init('hive_db');
}
