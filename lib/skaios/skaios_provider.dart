import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:win_ble/win_ble.dart';
import '../communicate/communicate_protocol.dart';
import '../constant/app_constant.dart';
import '../model/inertial_model.dart';
import '../ui/app_dialog.dart';
import '../locator.dart';
import '../model/log_model.dart';
import 'skai_os_interface.dart';
import '../helper/time_helper.dart';
import '../helper/ui_helper.dart';
import 'watch_peripheral_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Quaternion, Vector3;

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

  bool _isScanning = false;
  bool get isScanning => _isScanning;
  set isScanning(bool val) {
    if (val != _isScanning) {
      _isScanning = val;
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
      'address': device.remoteId.toString(),
    };
    notifySkaiOSService(ServiceType.bluetooth, BluetoothServiceType.pair.index,
        param: deviceJson);
  }

  Future<void> pairWatchBluetoothOnWindows(BleDevice device) async {
    final deviceJson = {
      'address': device.address,
    };
    notifySkaiOSService(ServiceType.bluetooth, BluetoothServiceType.pair.index,
        param: deviceJson);
  }

  Future<void> pairWatchBluetooth(dynamic device) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await pairWatchBluetoothOnMobile(device);
    } else if (Platform.isWindows) {
      await pairWatchBluetoothOnWindows(device);
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

  /// [Test]Gesture Acceleration ///
  int _accelThreshold = 8;
  int get accelThreshold => _accelThreshold;
  set accelThreshold(int val) {
    if (val != _accelThreshold) {
      _accelThreshold = val;
      notifyListeners();
    }
  }

  Future<void> syncWatchGestureAccelThreshold(int threshold) async {
    await l1Send(L1SendType.l1SendGestureAccelLimitThreshold, param: threshold);
  }

  Timer? smoothSlidingTimer;
  void setGestureAccelLimitThreshold(int threshold) async {
    if (smoothSlidingTimer != null) {
      smoothSlidingTimer?.cancel();
    }
    accelThreshold = threshold;
    smoothSlidingTimer = Timer(const Duration(milliseconds: 200), () {
      syncWatchGestureAccelThreshold(accelThreshold);
    });
  }

  // Create a StreamController for Quaternion
  final StreamController<Quaternion> _quaternionStreamController =
      StreamController<Quaternion>();

  // Expose the stream to be used in your widgets
  Stream<Quaternion> get quaternionStream => _quaternionStreamController.stream;

  // Function to add data to the stream
  void addQuaternion(Quaternion quaternion) {
    _quaternionStreamController.sink.add(quaternion);
  }

  List<List<FlSpot>> _accelerationFlSpotList = [];
  List<List<FlSpot>> get accelerationFlSpotList => _accelerationFlSpotList;
  set accelerationFlSpotList(List<List<FlSpot>> val) {
    if (val != _accelerationFlSpotList) {
      _accelerationFlSpotList = val;
      notifyListeners();
    }
  }

  List<List<FlSpot>> _ppgFlSpotList = [];
  List<List<FlSpot>> get ppgFlSpotList => _ppgFlSpotList;
  set ppgFlSpotList(List<List<FlSpot>> val) {
    if (val != _ppgFlSpotList) {
      _ppgFlSpotList = val;
      notifyListeners();
    }
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
                isWatchConnected = param as bool;
              }
              break;
            case BluetoothServiceType.scanning:
              {
                debugPrint("scanning: $param");
                isScanning = param as bool;
              }
              break;
            case BluetoothServiceType.enable:
              {
                isBluetoothEnabled = param as bool;
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
      case ServiceType.watchSystem:
        final watchSystemServiceType = WatchSystemServiceType.values[type];
        {
          switch (watchSystemServiceType) {
            case WatchSystemServiceType.peripheralDebugSwitch:
              {
                final command = WatchPeripheralSwitch.values[param];
                switch (command) {
                  case WatchPeripheralSwitch.imuSwitchOn:
                    {
                      locator<WatchPeripheralProvider>().imuSwitch = true;
                    }
                    break;
                  case WatchPeripheralSwitch.imuSwitchOff:
                    {
                      locator<WatchPeripheralProvider>().imuSwitch = false;
                    }
                    break;
                  case WatchPeripheralSwitch.ppgSwitchOn:
                    {
                      locator<WatchPeripheralProvider>().ppgSwitch = true;
                    }
                    break;
                  case WatchPeripheralSwitch.ppgSwitchOff:
                    {
                      locator<WatchPeripheralProvider>().ppgSwitch = false;
                    }
                    break;
                }
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
      case ServiceType.gestureDataCollction:
        final gestureDataCollctionType =
            GestureDataCollctionServiceType.values[type];
        switch (gestureDataCollctionType) {
          case GestureDataCollctionServiceType.plot:
            {
              List<dynamic> mapList = param;
              List<MARGModel> margList = mapList
                  .map(
                      (marg) => MARGModel.fromMap(marg as Map<String, dynamic>))
                  .toList();
              // length = 3
              accelerationFlSpotList = List.generate(3, (i) {
                List<FlSpot> flSpotList = [];
                for (int j = 0; j < margList.length; j++) {
                  flSpotList.add(FlSpot(j.toDouble(), margList[j].dataset[i]));
                }
                return flSpotList;
              }).toList();
            }
            break;
          default:
            break;
        }
        break;
      case ServiceType.motionTracking:
        final motionTrackingType = MotionTrackingServiceType.values[type];
        switch (motionTrackingType) {
          case MotionTrackingServiceType.quaternion:
            {
              List<dynamic> data = param;
              List<double> qArray =
                  data.map((e) => (e as double) * 100.0).toList();
              // debugPrint("quaternions: $qArray");
              // rotate cube by quaternion
              Quaternion quaternion =
                  Quaternion(qArray[1], qArray[2], qArray[3], qArray[0]);
              addQuaternion(quaternion);
            }
            break;
          default:
            break;
        }
        break;
      case ServiceType.heartrateDataCollction:
        final hrDataCollctionType = HRDataCollctionServiceType.values[type];
        switch (hrDataCollctionType) {
          case HRDataCollctionServiceType.plot:
            {
              List<dynamic> dataset = param;
              List<int> hrList = dataset.cast<int>();
              ppgFlSpotList = List.generate(1, (i) {
                List<FlSpot> flSpotList = [];
                for (int j = 0; j < hrList.length; j++) {
                  flSpotList.add(FlSpot(j.toDouble(), hrList[j].toDouble()));
                }
                return flSpotList;
              }).toList();
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
