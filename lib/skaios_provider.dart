import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'app_constant.dart';
import 'app_dialog.dart';
import 'locator.dart';
import 'log_model.dart';
import 'skai_os_interface.dart';
import 'time_helper.dart';
import 'ui_helper.dart';

class SkaiOSProvider extends ChangeNotifier {
  bool _isWatchConnected = false;
  bool get isWatchConnected => _isWatchConnected;
  set isWatchConnected(bool val) {
    if (val != _isWatchConnected) {
      _isWatchConnected = val;
      notifyListeners();
    }
  }

  bool _isBluetoothEnabled = false;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  set isBluetoothEnabled(bool val) {
    if (val != _isBluetoothEnabled) {
      _isBluetoothEnabled = val;
      notifyListeners();
    }
  }

  bool _isWatchBwpsConnected = false;
  bool get isWatchBwpsConnected => _isWatchBwpsConnected;
  set isWatchBwpsConnected(bool val) {
    if (val != _isWatchBwpsConnected) {
      _isWatchBwpsConnected = val;
      notifyListeners();
    }
  }

  /// ----------- Toast ----------- ///
  void Function()? textToastCancelFunc;
  // only one task can be executed at the same time
  void Function()? loadingToastCancelFunc;

  void showDebugToast({required String msg, Color? backgroundColor}) {
    if (textToastCancelFunc != null) textToastCancelFunc!();
    textToastCancelFunc = BotToast.showText(
        text: msg, backgroundColor: backgroundColor ?? Colors.transparent);
  }

  void showHintToast({required String msg}) {
    if (textToastCancelFunc != null) textToastCancelFunc!();
    textToastCancelFunc = BotToast.showText(text: msg);
  }

  void showLoading({
    required String msg,
    void Function()? onClose,
  }) {
    if (loadingToastCancelFunc != null) return;
    loadingToastCancelFunc = BotToast.showCustomLoading(
        toastBuilder: (context) {
          return UIHelper.blurredBackground(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator()),
                  verticalSpaceSmall,
                  Text(
                    msg,
                  )
                ],
              ),
              withGoBack: false);
        },
        clickClose: true,
        onClose: onClose);
  }

  /// ----------- Motion tracking & Gesture Recognition ----------- ///
  bool _gestureMode = false;
  bool get gestureMode => _gestureMode;
  set gestureMode(bool val) {
    if (val != _gestureMode) {
      _gestureMode = val;
      notifyListeners();
    }
  }

  int _gestureIndex = 0;
  int get gestureIndex => _gestureIndex;
  set gestureIndex(int val) {
    if (val != _gestureIndex) {
      _gestureIndex = val;
      notifyListeners();
    }
  }

  ///////COMMUNICATE WITH WATCH///////
  Future<void> pairWatchBluetoothOnMobile(BluetoothDevice device) async {
    final deviceJson = {
      // 'name': device.platformName,
      'address': device.remoteId.toString(),
    };
    notifySkaiOSService(ServiceType.bluetooth, BluetoothServiceType.pair.index,
        param: deviceJson);
  }

  Future<void> pairWatchBluetooth(dynamic device) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await pairWatchBluetoothOnMobile(device);
    }
  }

  Future<void> scanWatchBluetoothOnMobile(bool isEnabled) async {
    notifySkaiOSService(ServiceType.bluetooth, BluetoothServiceType.scan.index,
        param: isEnabled);
  }

  Timer? timerBLEConnect;
  Future<void> scanWatchBluetooth() async {
    if (timerBLEConnect != null) {
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await scanWatchBluetoothOnMobile(true);
    }

    timerBLEConnect = TimeHelper.oneTimer(
        seconds: 10,
        timerOutCallback: () {
          loadingToastCancelFunc?.call();
        });
    showLoading(
        msg: "Connecting to watch..",
        onClose: () {
          loadingToastCancelFunc = null;
          timerBLEConnect?.cancel();
          timerBLEConnect = null;
          if (Platform.isAndroid || Platform.isIOS) {
            scanWatchBluetoothOnMobile(false);
          }
        });
  }

  Future<void> disconnectWatchBluetoothOnMobile() async {
    await notifySkaiOSService(
        ServiceType.bluetooth, BluetoothServiceType.disconnect.index);
  }

  Future<void> disconnectWatchBluetooth() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await disconnectWatchBluetoothOnMobile();
    }
  }

  /// Record Gsensor Data ///
  Future<void> showDialogAfterFinishedMotionRecord(
      BuildContext context, String table) async {
    debugPrint('showDialogAfterFinishedMotionRecord $table');
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppDialogs.choiceDialog(
              content: '是否保留為檔案',
              textLeft: '刪除',
              callbackLeft: () async {
                await notifySkaiOSService(ServiceType.gestureDataCollction,
                        GestureDataCollctionServiceType.delete.index)
                    .then((_) => Navigator.pop(context));
              },
              textRight: '儲存',
              callbackRight: () async {
                await notifySkaiOSService(ServiceType.gestureDataCollction,
                        GestureDataCollctionServiceType.save.index)
                    .then((_) => Navigator.pop(context));
              },
            ));
  }

  String _selectedMotionLabel = AppConstant.gestureTable[0];
  String get selectedMotionLabel => _selectedMotionLabel;
  set selectedMotionLabel(String label) {
    if (label != selectedMotionLabel) {
      _selectedMotionLabel = label;
      notifyListeners();
    }
  }

  bool _isRecordingAccelerometer = false;
  bool get isRecordingAccelerometer => _isRecordingAccelerometer;
  set isRecordingAccelerometer(bool value) {
    _isRecordingAccelerometer = value;
    notifyListeners();
  }

  Future<void> uiHandler(ServiceType serviceType, int type,
      {dynamic param}) async {
    switch (serviceType) {
      case ServiceType.bluetooth:
        {
          BluetoothServiceType bluetoothServiceType =
              BluetoothServiceType.values[type];
          switch (bluetoothServiceType) {
            case BluetoothServiceType.connected:
              {
                bool isConnected = param;
                isWatchConnected = isConnected;
              }
              break;
            case BluetoothServiceType.scanning:
              {
                debugPrint("scanning: $param");
              }
              break;
            case BluetoothServiceType.enable:
              {
                bool isEnabled = param;
                isBluetoothEnabled = isEnabled;
              }
              break;
            case BluetoothServiceType.bwpsConnected:
              {
                isWatchBwpsConnected = param as bool;
              }
              break;
            default:
              break;
          }
        }
        break;
      case ServiceType.gestureDetect:
        final gestureDetectType = GestureDetectServiceType.values[type];
        switch (gestureDetectType) {
          case GestureDetectServiceType.label:
            {
              gestureIndex = param;
            }
            break;
          default:
            break;
        }
        break;
      case ServiceType.debug:
        {
          final debugType = DebugServiceType.values[type];
          switch (debugType) {
            case DebugServiceType.log:
              {
                final package = LogMessagePacket.fromMap(param);
                locator<LogModel>().bleDebugPrint(package);
              }
              break;
            case DebugServiceType.debugToast:
              {
                if (param != null) {
                  String msg = param;
                  showDebugToast(msg: msg);
                }
              }
              break;
            case DebugServiceType.hintToast:
              {
                String msg = param;
                showHintToast(msg: msg);
              }
              break;
            default:
              break;
          }
        }
        break;
      default:
        break;
    }
  }
}
