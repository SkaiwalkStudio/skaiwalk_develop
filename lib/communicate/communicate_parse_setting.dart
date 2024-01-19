import '../constant/app_constant.dart';
import '../model/log_model.dart';
import '../skaios/skai_os_interface.dart';
import 'communicate_protocol.dart';

class SetConfigResolver {
  void resolve(L2Header l2Header, List<int> firstValue) {
    if (l2Header.valueLength != firstValue.length) {
      return;
    }
    resolveSettingsConfigCommand(l2Header.firstKey, firstValue);
  }

  void resolveSettingsConfigCommand(int key, List<int> pValue) async {
    final settingsKey = SettingsKey.fromInt(key);
    String? debugMessage;
    switch (settingsKey) {
      case SettingsKey.keyPeripheralDebugSwitch:
        {
          if (pValue.length == 1) {
            debugMessage = "Peripheral Debug Switch: ${pValue[0]}";
            await notifySkaiOSProvider(ServiceType.watchSystem,
                WatchSystemServiceType.peripheralDebugSwitch.index,
                param: pValue[0]);
          }
        }
        break;
      default:
        break;
    }
    if (AppConstant.usingDebugLog) {
      final logModelMap = LogMessagePacket(
              firstKey: settingsKey.toString(), message: debugMessage)
          .toMap();
      notifySkaiOSProvider(ServiceType.debug, DebugServiceType.log.index,
          param: logModelMap);
    }
    if (AppConstant.usingDebugToast) {
      if (debugMessage != null) {
        notifySkaiOSProvider(
            ServiceType.debug, DebugServiceType.debugToast.index,
            param: debugMessage);
      }
    }
  }
}
