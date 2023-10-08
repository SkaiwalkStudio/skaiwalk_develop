import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'app_dialog.dart';
import 'ble_scan_result_tile.dart';
import 'locator.dart';
import 'shared_prefs_service.dart';
import 'skaios_provider.dart';
import 'text_constant.dart';
import 'ui_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TextConstants.connect),
      ),
      body: StreamBuilder<List<ScanResult>>(
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
            onRefresh: () async {
              if (Platform.isAndroid || Platform.isIOS) {
                FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
              }
            },
            child: SingleChildScrollView(
              child: Column(
                children: results.map(
                  (r) {
                    return Visibility(
                      visible: r.device.platformName
                          .contains(TextConstants.skaiHeading),
                      child: ScanResultTile(
                        buttonTitle: "綁定",
                        isActive: true,
                        result: r,
                        onTap: () async {
                          bindDevice(r.device.remoteId.toString());
                          locator<SkaiOSProvider>()
                              .pairWatchBluetooth(r.device);
                          bool? connected = await showDialog<bool?>(
                            context: context,
                            builder: (context) {
                              return AppDialogs.loadingDialog(
                                child: StreamBuilder<List<BluetoothDevice>>(
                                  stream: Stream.periodic(
                                          const Duration(seconds: 2))
                                      .asyncMap((_) => FlutterBluePlus
                                          .connectedSystemDevices),
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
                                    return loading(context,
                                        "正在連線${r.device.platformName}");
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StreamBuilder<bool>(
          stream: FlutterBluePlus.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data!) {
              return TextButton(
                child: const Text("stop"),
                onPressed: () => FlutterBluePlus.stopScan(),
              );
            } else {
              return TextButton(
                child: const Text("search"),
                onPressed: () => FlutterBluePlus.startScan(
                    timeout: const Duration(seconds: 10)),
              );
            }
          },
        ),
      ),
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

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () => c.write([13, 24]),
                    onNotificationPressed: () =>
                        c.setNotifyValue(!c.isNotifying),
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write([11, 12]),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.platformName),
        actions: <Widget>[
          StreamBuilder<BluetoothConnectionState>(
            stream: device.connectionState,
            initialData: BluetoothConnectionState.disconnected,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothConnectionState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothConnectionState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .labelLarge!
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothConnectionState>(
              stream: device.connectionState,
              initialData: BluetoothConnectionState.disconnected,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothConnectionState.connected)
                    ? const Icon(Icons.bluetooth_connected)
                    : const Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.remoteId}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => device.discoverServices(),
                      ),
                      const IconButton(
                        icon: SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: const Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.servicesStream,
              initialData: const [],
              builder: (c, snapshot) {
                if (snapshot.connectionState == ConnectionState.active &&
                    snapshot.data != null) {
                  return Column(
                    children: _buildServiceTiles(snapshot.data!),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
