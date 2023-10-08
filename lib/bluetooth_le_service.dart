import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../communicate/communicate_parse.dart';
import '../communicate/communicate_protocol.dart';
import 'app_constant.dart';
import 'locator.dart';
import 'shared_prefs_service.dart';
import 'skai_os_interface.dart';
import 'time_helper.dart';

class BLEService {
  final int rxBytesMaxLength = 244;
  String targetAddress = "";
  Future<void> init({void Function()? onConnected}) async {
    debugPrint("<<<<<<<<<< init BLEService >>>>>>>>>>");
    this.onConnected = onConnected;
    if (adapterStateSubscription != null) {
      adapterStateSubscription?.cancel();
      adapterStateSubscription = null;
    }
    // 藍芽是否打開
    adapterStateSubscription = FlutterBluePlus.adapterState.listen((event) {
      if (event == BluetoothAdapterState.on) {
        bluetoothAdapterState = BluetoothAdapterState.on;
        startScanning();
      } else if (event == BluetoothAdapterState.off) {
        bluetoothAdapterState = BluetoothAdapterState.off;
        disconnect();
        isWatchConnected = false;
        _clearResources();
      }
    });
    // 目標設備是否連線
    // flutterBlue.connectedDevices
    //     .asStream()
    //     .listen((List<BluetoothDevice> devices) {});

    scanSubscription =
        FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.remoteId.toString() == targetAddress) {
          debugPrint("target device ${result.device} scanned!!");
          stopScanning();
          if (!isWatchConnected) {
            connect(result.device);
          }
        } else {
          // debugPrint("other device ${result.device} scanned!!");
        }
      }
    }, onDone: () {
      debugPrint("scan done");
      stopScanning();
    }, onError: (error) {
      debugPrint("scan error $error");
    });
  }

  void notifyUiTask(BluetoothServiceType type, {dynamic param}) {
    debugPrint("notifyUiTask: $type, param: $param");
    notifySkaiOSProvider(ServiceType.bluetooth, type.index, param: param);
  }

  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.on;
  BluetoothAdapterState get bluetoothAdapterState => _bluetoothAdapterState;
  set bluetoothAdapterState(BluetoothAdapterState val) {
    if (val != _bluetoothAdapterState) {
      _bluetoothAdapterState = val;
      notifyUiTask(BluetoothServiceType.enable,
          param: _bluetoothAdapterState == BluetoothAdapterState.on);
    }
  }

  bool _isScanning = false;
  bool get isScanning => _isScanning;
  set isScanning(bool val) {
    if (val != _isScanning) {
      _isScanning = val;
      notifyUiTask(BluetoothServiceType.scanning, param: _isScanning);
    }
  }

  bool _isWatchConnected = false;
  bool get isWatchConnected => _isWatchConnected;
  set isWatchConnected(bool status) {
    if (_isWatchConnected != status) {
      _isWatchConnected = status;
      notifyUiTask(BluetoothServiceType.connected, param: _isWatchConnected);
    }
  }

  BluetoothDevice? targetDevice;
  // TX Characteristic
  BluetoothCharacteristic? bwpsTxCharacteristic;

  // RX Characteristic
  BluetoothCharacteristic? bwpsRxCharacteristic;
  StreamSubscription? _bwpsRxSubscription;
  // Device Name Characteristic
  BluetoothCharacteristic? bwpsDeviceNameCharacteristic;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;
  // StreamSubscription<int>? _mtuSubscription;
  StreamSubscription<List<BluetoothService>>? _servicesSubscription;

  Timer? scanTimer;

  void Function()? onConnected;

  bool userDisconnect = false;

  final Map<DeviceIdentifier, StreamController<List<BluetoothService>>>
      servicesStream = {};

  void autoScan() {
    debugPrint("autoScan intent");
    if (scanTimer != null) {
      scanTimer?.cancel();
      scanTimer = null;
    }
    scanTimer = TimeHelper.oneTimer(
        seconds: 20,
        timerOutCallback: () {
          if (!isWatchConnected) {
            startScanning();
            debugPrint('start autoScan');
          } else {
            scanTimer?.cancel();
            scanTimer = null;
            debugPrint('watch is already connected');
          }
        });
  }

  Future<void> startScanning() async {
    if (isWatchConnected) {
      notifyUiTask(BluetoothServiceType.connected, param: true);
      return;
    }
    if (isScanning) return;
    targetAddress = await SharedPrefsService().bondedAddress;
    if (targetAddress.isEmpty) {
      debugPrint("targetAddress is empty, please bond first");
      return;
    }
    isScanning = true;
    await FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 10), androidUsesFineLocation: true)
        .then((value) {
      debugPrint('startScan finished');
      autoScan();
    });
    isScanning = false;
  }

  void stopScanning() {
    isScanning = false;
    FlutterBluePlus.stopScan();
    // _scanSubScription.cancel();
    // scanTimer = null;
  }

  // https://github.com/pauldemarco/flutter_blue/issues/525
  Future<void> connect(BluetoothDevice device) async {
    await disconnect();
    await _clearResources();
    debugPrint('Connecting...');
    await device.connect(autoConnect: false);
    // The subscription cannot be null due to the auto-reconnect feature.
    connectionStateSubscription = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("Disconnected.");
        isWatchConnected = false;
        await disconnect();
        targetDevice = null;
        await _clearResources();
        if (userDisconnect) {
          debugPrint('User Disconnect');
          userDisconnect = false;
        } else {
          autoScan();
        }
      } else if (state == BluetoothConnectionState.connected) {
        debugPrint("Connected!");
        isWatchConnected = true;
        onConnected?.call();
        targetDevice = device;
        await device.requestMtu(247);
        servicesStream[device.remoteId] ??=
            StreamController<List<BluetoothService>>();

        _servicesSubscription ??=
            servicesStream[device.remoteId]!.stream.listen((services) async {
          for (var service in services) {
            if (service.uuid.toString() == AppConstant.bwpsServiceUuid) {
              for (var characteristic in service.characteristics) {
                var characteristicsUUiD = characteristic.uuid.toString();
                if (characteristicsUUiD == AppConstant.bwpsTxCharacteristic) {
                  bwpsTxCharacteristic = characteristic;
                } else if (characteristicsUUiD ==
                    AppConstant.bwpsRxCharacteristic) {
                  bwpsRxCharacteristic = characteristic;
                  //https://github.com/pauldemarco/flutter_blue/issues/295#issuecomment-549997455
                  //Better to be placed here before finishing iterating
                  await bwpsRxCharacteristic?.setNotifyValue(true);
                  await Future.delayed(AppConstant.commandDelayDuration);
                } else if (characteristicsUUiD ==
                    AppConstant.bwpsDeviceNameCharacteristic) {
                  bwpsDeviceNameCharacteristic = characteristic;
                }
              }
              _bwpsRxSubscription = startListeningRxCharacteristic();

              notifyUiTask(BluetoothServiceType.bwpsConnected, param: true);
            }
          }
        });

        await device.discoverServices();
        servicesStream[device.remoteId] ??=
            StreamController<List<BluetoothService>>();
        servicesStream[device.remoteId]!.add(device.servicesList ?? []);
      }
    });
  }

  Future<void> disconnect() async {
    return targetDevice?.disconnect();
  }

  Future<void> _clearResources() async {
    debugPrint("Clear Bluetooth low energy connection Resources");
    await _bwpsRxSubscription?.cancel();
    await connectionStateSubscription?.cancel();
  }

  Future<void> disposeBLEService() async {
    await _clearResources();
    await adapterStateSubscription?.cancel();
    adapterStateSubscription = null;
    await scanSubscription?.cancel();
    scanSubscription = null;
  }

  Future<void> bwpsTxNotify(List<int> bytes) async {
    if (bwpsTxCharacteristic == null) {
      return;
    }
    await bwpsTxCharacteristic?.write(bytes, withoutResponse: false);
  }

  StreamSubscription<void> startListeningRxCharacteristic() {
    return bwpsRxCharacteristic!.onValueReceived.listen((buffer) {
      if (buffer.isEmpty) {
        return;
      }
      locator<CommunicateParse>()
          .resolveL2Frame(buffer, from: CommunicateDevice.watch);
    });
  }
}
