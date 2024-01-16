import 'dart:convert';
import '../constant/app_constant.dart';
import '../model/log_model.dart';
import '../skaios/skai_os_interface.dart';
import 'communicate_protocol.dart';

class BluetoothLogResolver {
  void resolve(L2Header l2Header, List<int> firstValue) {
    if (l2Header.valueLength != firstValue.length) {
      return;
    }
    resolveBluetoothLogCommand(l2Header.firstKey, firstValue);
  }

  void resolveBluetoothLogCommand(int key, List<int> pValue) async {
    final bluetoothLogKey = BluetoothLogKey.fromInt(key);
    String? debugMessage;
    switch (bluetoothLogKey) {
      case BluetoothLogKey.keyDebug:
        {
          debugMessage = utf8.decode(pValue);
        }
        break;
      default:
        break;
    }
    if (AppConstant.usingDebugLog) {
      final logModelMap = LogMessagePacket(
              firstKey: bluetoothLogKey.toString(), message: debugMessage)
          .toMap();
      await notifySkaiOSProvider(ServiceType.debug, DebugServiceType.log.index,
          param: logModelMap);
    }
  }
}
