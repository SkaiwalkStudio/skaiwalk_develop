import 'package:flutter/foundation.dart';

enum WatchPeripheralSwitch {
  imuSwitchOn,
  imuSwitchOff,
  ppgSwitchOn,
  ppgSwitchOff,
}

class WatchPeripheralProvider extends ChangeNotifier {
  bool _imuSwitch = true;
  bool get imuSwitch => _imuSwitch;
  set imuSwitch(bool value) {
    _imuSwitch = value;
    notifyListeners();
  }

  bool _ppgSwitch = true;
  bool get ppgSwitch => _ppgSwitch;
  set ppgSwitch(bool value) {
    _ppgSwitch = value;
    notifyListeners();
  }
}
