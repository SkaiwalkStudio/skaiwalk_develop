import 'dart:io';

import 'package:get_it/get_it.dart';

import 'service/ble_service.dart';
import 'service/bluetooth_le_service_mobile.dart';
import 'communicate/communicate_parse.dart';
import 'communicate/communicate_task.dart';
import 'service/bluetooth_le_service_windows.dart';
import 'service/gesture_detect_service.dart';
import 'model/inertial_model.dart';
import 'model/log_model.dart';
import 'skaios/skaios_provider.dart';
import 'skaios/watch_peripheral_provider.dart';

GetIt locator = GetIt.instance;
void registerLocator() {
  locator.registerLazySingleton(() => CommunicateParse());
  locator.registerLazySingleton(() => CommunicateTask());
  registerBLEService();
  locator.registerLazySingleton(() => GestureDetectService());
  locator.registerLazySingleton(() => MARGDatabaseService());
  locator.registerLazySingleton(() => LogModel());
  locator.registerLazySingleton(() => WatchPeripheralProvider());
  locator.registerLazySingleton(() => SkaiOSProvider());
}

void registerBLEService() {
  late BleService bleService;
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    bleService = BLEServiceMobile();
  } else if (Platform.isWindows) {
    bleService = BLEServiceWindows();
  }
  locator.registerLazySingleton(() => bleService);
}
