import 'package:get_it/get_it.dart';

import 'bluetooth_le_service.dart';
import 'communicate/communicate_parse.dart';
import 'communicate/communicate_task.dart';
import 'gesture_detect_service.dart';
import 'inertial_model.dart';
import 'log_model.dart';
import 'skaios_provider.dart';

GetIt locator = GetIt.instance;
void registerLocator() {
  locator.registerLazySingleton(() => CommunicateParse());
  locator.registerLazySingleton(() => CommunicateTask());
  locator.registerLazySingleton(() => BLEService());
  locator.registerLazySingleton(() => GestureDetectService());
  locator.registerLazySingleton(() => MARGDatabaseService());
  locator.registerLazySingleton(() => LogModel());
  locator.registerLazySingleton(() => SkaiOSProvider());
}
