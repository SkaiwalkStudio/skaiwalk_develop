import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:skaiwalk_develop/service/ble_service.dart';
import 'package:skaiwalk_develop/skaios/skai_os_interface.dart';
import 'package:skaiwalk_develop/skaios/watch_peripheral_provider.dart';
import '../locator.dart';
import 'communicate_protocol.dart';

const String debugTagPhone = 'Phone';

// use for sending data to watch
class CommunicateTask {
  String getPhoneLog(dynamic fristKey, String? message) {
    return "[$debugTagPhone][$fristKey]$message";
  }

  List<int> packageL2Frame(L2Header header, List<int>? payload) {
    return [...encodeL2Header(header), ...?payload];
  }

  Future<void> sendBluetoothCommand(
      {required WristbandCommunicateCommand commandId,
      required int keyValue,
      List<int>? payload}) async {
    final L2Header header =
        L2Header(commandId, keyValue, (payload != null) ? payload.length : 0);
    List<int> buffer = packageL2Frame(header, payload);
    if (kIsWeb) {
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await locator<BleService>().bwpsTxNotify(buffer);
    }
  }

  ///////////////////
  /// Notify Command
  Future<void> sendNotifyCommand(NotifyKey key, {List<int>? payload}) async {
    await sendBluetoothCommand(
        commandId: WristbandCommunicateCommand.notifyCommandId,
        keyValue: key.value,
        payload: payload);
  }

////////////////////
  /// Set Config Command
  Future<void> sendSetConfigCommand(SettingsKey key,
      {List<int>? payload}) async {
    await sendBluetoothCommand(
        commandId: WristbandCommunicateCommand.setConfigCommandId,
        keyValue: key.value,
        payload: payload);
  }

  Future<void> setPeripheralDebugSwitch(WatchPeripheralSwitch command) async {
    await sendSetConfigCommand(SettingsKey.keyPeripheralDebugSwitch,
        payload: [command.index]);
  }
}

Future<void> l1SendHandler(Map<String, dynamic>? params) async {
  if (params == null) return;
  final type = L1SendType.values[params['type']];
  final data = params['param'];
  debugPrint("l1SendHandler: $type, $data");
  switch (type) {
    case L1SendType.l1SendDebugSwitchCommand:
      {
        WatchPeripheralSwitch command = WatchPeripheralSwitch.values[data];
        await locator<CommunicateTask>().setPeripheralDebugSwitch(command);
      }
      break;
    default:
      break;
  }
}
