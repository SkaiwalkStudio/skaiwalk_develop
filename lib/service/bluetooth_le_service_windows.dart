import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:skaiwalk_develop/locator.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
import '../communicate/communicate_parse.dart';
import '../communicate/communicate_protocol.dart';
import '../constant/app_constant.dart';
import '../helper/time_helper.dart';
import '../skaios/skai_os_interface.dart';
import 'ble_service.dart';

class BLEServiceWindows extends BleService {
  BLEServiceWindows() {
    initBLEService();
  }
  StreamSubscription? scanSubscription;
  StreamSubscription? connectionStream;
  StreamSubscription? bluetoothStateSubscription;

  BleDevice? targetDevice;
  //bwps
  BleCharacteristic? bwpsTxCharacteristic;
  BleCharacteristic? bwpsRxCharacteristic;
  BleCharacteristic? bwpsDeviceNameCharacteristic;

  String bleStatus = "";
  String bleError = "";

  List<BleDevice> devices = <BleDevice>[];

  void notifyUiTask(BluetoothServiceType type, {dynamic param}) {
    debugPrint("notifyUiTask: $type, param: $param");
    notifySkaiOSProvider(ServiceType.bluetooth, type.index, param: param);
  }

  // 掃描進行狀態
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  set isScanning(bool val) {
    if (val != _isScanning) {
      _isScanning = val;
      notifyUiTask(BluetoothServiceType.scanning, param: _isScanning);
    }
  }

  final int rxBytesMaxLength = 244;
  // 藍芽開啟狀態
  bool _isBluetoothEnabled = false;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  set isBluetoothEnabled(bool val) {
    if (val != _isBluetoothEnabled) {
      _isBluetoothEnabled = val;
      notifyUiTask(BluetoothServiceType.enable, param: isBluetoothEnabled);
    }
  }

  // 藍芽連線狀態
  bool _isWatchConnected = false;
  bool get isWatchConnected => _isWatchConnected;
  set isWatchConnected(bool status) {
    if (_isWatchConnected != status) {
      _isWatchConnected = status;
      notifyUiTask(BluetoothServiceType.connected, param: _isWatchConnected);
    }
  }

  StreamSubscription? _bwpsRxSubscription;

  Timer? scanTimer;

  void Function()? onConnected;

  bool userDisconnect = false;

  void initBLEService({void Function()? onConnected}) async {
    this.onConnected = onConnected;
    var path = await WinServer.path();
    WinBle.initialize(serverPath: path, enableLog: true);
    // Listen to Scan Stream , we can cancel in onDispose()
    // final bondedAddress = await SharedPrefsService().bondedAddress;
    // scanSubscription = WinBle.scanStream.listen((event) {
    //   if (!devices.any((element) => element.address == event.address)) {
    //     devices.add(event);
    //     debugPrint("device: ${event.name} ${event.address}");
    //   }
    //   if (bondedAddress.isNotEmpty) {
    //     for (var device in devices) {
    //       if (device.address == bondedAddress) {
    //         debugPrint("target device scanned!!");
    //         targetDevice = device;
    //         stopScanning();
    //         if (!isWatchConnected) {
    //           connect(device);
    //         }
    //       }
    //     }
    //   }
    // });

    // Listen to Ble State Stream
    bluetoothStateSubscription = WinBle.bleState.listen((BleState state) {
      if (state == BleState.On) {
        isBluetoothEnabled = true;
      } else {
        isBluetoothEnabled = false;
      }
    });
  }

  @override
  Future<void> startScanning() async {
    if (isWatchConnected) {
      return;
    }
    if (isScanning) return;
    isScanning = true;
    WinBle.startScanning();
  }

  @override
  Future<void> stopScanning() async {
    isScanning = false;
    WinBle.stopScanning();
  }

  bool isConnecting = false;
  // https://github.com/pauldemarco/flutter_blue/issues/525
  @override
  Future<void> connect(dynamic device) async {
    BleDevice currentDevice = device;
    if (isConnecting) {
      return;
    }
    isConnecting = true;
    debugPrint('connecting...');
    await _clearResources();
    targetDevice = currentDevice;
    final address = currentDevice.address;
    await WinBle.connect(address);
    isConnecting = false;
    connectionStream = WinBle.connectionStream.listen((event) async {
      debugPrint("Connection Event : $event");
      // String address = event["device"];
      bool connected = event["connected"];
      if (!connected) {
        debugPrint("disconnected!");
        isWatchConnected = false;
        await disconnect();
        targetDevice = null;
        await _clearResources();
        if (userDisconnect) {
          debugPrint('user Disconnect');
          userDisconnect = false;
        } else {
          _autoScan();
        }
      } else {
        isWatchConnected = true;
        debugPrint("connected!");
      }
    });
    await WinBle.discoverServices(address).then((services) async {
      for (var serviceID in services) {
        if (serviceID == AppConstant.bwpsServiceUuid) {
          List<BleCharacteristic> bleCharacteristics =
              await WinBle.discoverCharacteristics(
                  address: address, serviceId: serviceID);
          for (var characteristic in bleCharacteristics) {
            final characteristicsUUiD = characteristic.uuid.toString();
            if (characteristicsUUiD == AppConstant.bwpsTxCharacteristicUuid) {
              bwpsTxCharacteristic = characteristic;
            } else if (characteristicsUUiD ==
                AppConstant.bwpsRxCharacteristicUuid) {
              bwpsRxCharacteristic = characteristic;
              await WinBle.subscribeToCharacteristic(
                  address: address,
                  serviceId: serviceID,
                  characteristicId: characteristicsUUiD);
              await Future.delayed(AppConstant.commandDelayDuration);
            } else if (characteristicsUUiD ==
                AppConstant.bwpsDeviceNameCharacteristicUuid) {
              bwpsDeviceNameCharacteristic = characteristic;
            }
          }
          if (_bwpsRxSubscription != null) {
            _bwpsRxSubscription!.resume();
          } else {
            _bwpsRxSubscription = _startListeningRxCharacteristic();
          }
        }
      }
    });
  }

  @override
  Future<void> disconnect() async {
    if (targetDevice == null) {
      return;
    }
    await WinBle.disconnect(targetDevice?.address);
  }

  Future<void> _clearResources() async {
    if (_bwpsRxSubscription != null) {
      await _bwpsRxSubscription?.cancel();
      _bwpsRxSubscription = null;
      debugPrint("cancel bwpsRxSubscription");
    }
  }

  Future<void> disposeBLEService() async {
    await _clearResources();
    await bluetoothStateSubscription?.cancel();
    bluetoothStateSubscription = null;
    await scanSubscription?.cancel();
    scanSubscription = null;
  }

  @override
  Future<void> bwpsTxNotify(List<int> data) async {
    if (bwpsTxCharacteristic == null) {
      debugPrint("bwpsTxSubscription is null");
      return;
    }
    if (targetDevice == null) {
      debugPrint("targetDevice is null");
      return;
    }
    if (data.isEmpty) {
      debugPrint("data is empty");
      return;
    }
    final bytes = Uint8List.fromList(data);
    try {
      await WinBle.write(
        address: targetDevice!.address,
        service: AppConstant.bwpsServiceUuid,
        characteristic: bwpsTxCharacteristic!.uuid,
        data: bytes,
        writeWithResponse: false,
      );
      debugPrint(
          "[device ${targetDevice!.address}]bwpsTxNotify(id=${bwpsTxCharacteristic!.uuid}) [${bytes.join(",")}]");
    } catch (e) {
      // Handle the exception here
      print('Error writing to Bluetooth device: $e');
      // You can also try disconnecting and reconnecting to the peripheral here
    }
  }

  /// Rx Characteristic
  /// - [Mobile] Subscrib Rx Characteristic
  Future<void> subscribeRxCharacteristic() async {
    if (targetDevice == null) {
      return;
    }
    if (bwpsRxCharacteristic == null) {
      return;
    }
    debugPrint("Subscribe Rx Characteristic");
    await WinBle.subscribeToCharacteristic(
        address: targetDevice!.address,
        serviceId: AppConstant.bwpsServiceUuid,
        characteristicId: bwpsRxCharacteristic!.uuid.toString());
    if (_bwpsRxSubscription != null) {
      _bwpsRxSubscription!.resume();
    } else {
      _bwpsRxSubscription = _startListeningRxCharacteristic();
    }
  }

  Future<void> unsubscribeRxCharacteristic() async {
    if (targetDevice == null) {
      return;
    }
    if (bwpsRxCharacteristic == null) {
      return;
    }
    debugPrint("Unsubscribe Rx Characteristic");
    await WinBle.unSubscribeFromCharacteristic(
        address: targetDevice!.address,
        serviceId: AppConstant.bwpsServiceUuid,
        characteristicId: bwpsRxCharacteristic!.uuid.toString());
    if (_bwpsRxSubscription != null) {
      _bwpsRxSubscription!.pause();
    }
  }

  StreamSubscription<void> _startListeningRxCharacteristic() {
    StreamSubscription characteristicValueStream =
        WinBle.characteristicValueStream.listen((event) {
      // Here We will Receive All Characteristic Events
      debugPrint("characteristicValueStream: $event");
      List<dynamic> dynamicList = event["value"];
      List<int> buffer = dynamicList.map((e) => e as int).toList();
      if (buffer.isEmpty) {
        return;
      }
      locator<CommunicateParse>()
          .resolveL2Frame(buffer, from: CommunicateDevice.watch);
    });
    return characteristicValueStream;
  }

  void _autoScan() {
    debugPrint("autoScan intent");
    if (scanTimer != null) {
      scanTimer!.cancel();
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
}
