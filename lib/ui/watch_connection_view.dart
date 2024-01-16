import 'package:flutter/material.dart';
import 'bond_screen.dart';
import '../locator.dart';
import '../service/shared_prefs_service.dart';
import '../skaios/skaios_provider.dart';
import '../constant/text_constant.dart';

class WatchConnectionView extends StatelessWidget {
  final bool isConnected;

  const WatchConnectionView({
    Key? key,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      return TextButton(
        child: Text(
          TextConstants.disconnect,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 30,
              ),
        ),
        onPressed: () async {
          await locator<SkaiOSProvider>().disconnectWatchBluetooth();
        },
      );
    } else {
      return TextButton(
        child: Text(
          TextConstants.connect,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 30,
              ),
        ),
        onPressed: () async {
          await SharedPrefsService().storeBondedAddress("");
          await locator<SkaiOSProvider>().disconnectWatchBluetooth();
          // navigate to bond
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const BondScreen();
          }));
        },
      );
    }

    // return ListTile(
    //   title: Text(
    //     "Connect",
    //     style: Theme.of(context).textTheme.bodyLarge,
    //   ),
    //   trailing: const Icon(Icons.bluetooth_rounded),
    //   onTap: () async {
    //     await locator<SkaiOSProvider>().scanWatchBluetooth();
    //   },
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(20.0),
    //   ),
    // );
  }
}
