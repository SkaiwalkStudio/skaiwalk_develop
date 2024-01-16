import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:win_ble/win_ble.dart';

import '../constant/app_constant.dart';
import '../skaios/skai_os_interface.dart';
import 'app_dialog.dart';
import 'ble_scan_result_tile.dart';
import '../locator.dart';
import '../service/shared_prefs_service.dart';
import '../skaios/skaios_provider.dart';
import '../constant/text_constant.dart';
import '../helper/ui_helper.dart';

class BondScreen extends StatelessWidget {
  const BondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<SkaiOSProvider, bool>(
      selector: (_, p) => p.isBluetoothEnabled,
      builder: (_, isBluetoothEnabled, __) {
        return const FindDevicesScreen();
        // if (isBluetoothEnabled) {
        //   return const FindDevicesScreen();
        // } else {
        //   return const BluetoothOffScreen(state: BluetoothAdapterState.off);
        // }
      },
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, required this.state}) : super(key: key);

  final BluetoothAdapterState state;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  Future<void> bindDevice(String address) async {
    debugPrint('綁定設備:$address');
    await SharedPrefsService().storeBondedAddress(address);
  }

  Widget loading(BuildContext context, String hint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
            height: 30, width: 30, child: CircularProgressIndicator()),
        verticalSpaceSmall,
        Text(
          hint,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _mobileScanResultBuilder(BuildContext context) {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.scanResults,
      // initialData: const [],
      builder: (c, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return waitingForScanResultWidget(context);
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return noDeviceFoundWidget(context);
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            child: Column(
              children: results.map(
                (r) {
                  return Visibility(
                    visible: r.device.platformName
                        .contains(TextConstants.skaiHeading),
                    child: ScanResultTile(
                      buttonTitle: "connect",
                      isActive: true,
                      result: r,
                      onTap: () async {
                        bindDevice(r.device.remoteId.toString());
                        locator<SkaiOSProvider>().pairWatchBluetooth(r.device);
                        bool? connected = await showDialog<bool?>(
                          context: context,
                          builder: (context) {
                            return AppDialogs.loadingDialog(
                              child: StreamBuilder<List<BluetoothDevice>>(
                                stream:
                                    Stream.periodic(const Duration(seconds: 2))
                                        .asyncMap((_) =>
                                            FlutterBluePlus.systemDevices),
                                initialData: const [],
                                builder: (c, snapshot) {
                                  if (snapshot.data!.isNotEmpty) {
                                    for (var d in snapshot.data!) {
                                      if (d.remoteId == r.device.remoteId) {
                                        return StreamBuilder<
                                                BluetoothConnectionState>(
                                            stream: d.connectionState,
                                            initialData:
                                                BluetoothConnectionState
                                                    .disconnected,
                                            builder: (c, snapshot) {
                                              if (snapshot.data ==
                                                  BluetoothConnectionState
                                                      .connected) {
                                                Navigator.pop(context, true);
                                              }
                                              return loading(context,
                                                  "${d.platformName}連線成功");
                                            });
                                      }
                                    }
                                  }
                                  return loading(
                                      context, "正在連線${r.device.platformName}");
                                },
                              ),
                            );
                          },
                        );
                        if (connected == true) {
                          debugPrint("==> 綁定 ==>");
                        }
                      },
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  List<BleDevice> devices = <BleDevice>[];
  Widget _windowsScanResultBuilder(BuildContext context) {
    return StreamBuilder<BleDevice>(
      stream: WinBle.scanStream,
      builder: (c, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return waitingForScanResultWidget(context);
        }
        final device = snapshot.data!;
        final index =
            devices.indexWhere((element) => element.address == device.address);
        // Updating existing device
        if (index != -1) {
          final name = devices[index].name;
          devices[index] = device;
          // Putting back cached name
          if (device.name.isEmpty || device.name == 'N/A') {
            devices[index].name = name;
          }
        } else {
          if (device.address.contains(TextConstants.skaiHeading)) {
            devices.add(device);
          }
        }
        if (devices.isEmpty) {
          return noDeviceFoundWidget(context);
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            child: Column(
              children: devices.map(
                (r) {
                  return Visibility(
                    visible: r.name.contains(TextConstants.skaiHeading),
                    child: InkWell(
                      onTap: () async {
                        bindDevice(r.address.toString());
                        locator<SkaiOSProvider>().pairWatchBluetooth(r);
                        bool? connected = await showDialog<bool?>(
                          context: context,
                          builder: (context) {
                            return AppDialogs.loadingDialog(
                              child: StreamBuilder<Map<String, dynamic>>(
                                stream: WinBle.connectionStream,
                                builder: (c, snapshot) {
                                  if (snapshot.data!.isNotEmpty) {
                                    String address = snapshot.data!["device"];
                                    bool connected =
                                        snapshot.data!["connected"];
                                    if (address == r.address) {
                                      if (connected) {
                                        Navigator.pop(context, true);
                                      }
                                      return loading(context, "${r.name}連線成功");
                                    }
                                  }
                                  return loading(context, "正在連線${r.name}");
                                },
                              ),
                            );
                          },
                        );
                        if (connected == true) {
                          debugPrint("==> 綁定 ==>");
                        }
                      },
                      child: Card(
                        child: ListTile(
                            title: Text(
                              "${device.name.isEmpty ? "N/A" : device.name} ( ${device.address} )",
                            ),
                            // trailing: Text(device.manufacturerData.toString()),
                            subtitle: Text(
                                "Rssi : ${device.rssi} | AdvTpe : ${device.advType}")),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TextConstants.connect),
      ),
      body: platformIsMobile
          ? _mobileScanResultBuilder(context)
          : _windowsScanResultBuilder(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Selector<SkaiOSProvider, bool>(
              selector: (_, p) => p.isScanning,
              builder: (_, isScanning, __) {
                if (isScanning) {
                  return TextButton(
                    child: const Text("stop"),
                    onPressed: () {
                      notifySkaiOSService(ServiceType.bluetooth,
                          BluetoothServiceType.scan.index,
                          param: false);
                    },
                  );
                } else {
                  return TextButton(
                    child: const Text("search"),
                    onPressed: () {
                      if (Platform.isWindows) {
                        devices.clear();
                      }
                      notifySkaiOSService(ServiceType.bluetooth,
                          BluetoothServiceType.scan.index,
                          param: true);
                    },
                  );
                }
              })),
    );
  }

  Widget waitingForScanResultWidget(BuildContext context) {
    return Center(
      child:
          Text('Waiting...', style: Theme.of(context).textTheme.headlineLarge),
    );
  }

  Widget noDeviceFoundWidget(BuildContext context) {
    return Center(
      child: Text('沒有找到藍牙裝置', style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}
