import 'dart:io';
import 'package:flutter/foundation.dart';

import '../model/g_sensor.dart';

// Define a constant to check if the app is running on desktop platform
final bool kIsDesktop =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

final bool platformIsMobile = kIsWeb
    ? false
    : (Platform.isAndroid || Platform.isIOS)
        ? true
        : false;

enum PageIndex {
  health,
  docs,
  browser,
}

enum WebPageViewIndex {
  files,
  docs,
}

enum DocsIndex {
  // todo,
  note,
}

class AndroidAppPackageID {
  static const String calendar = "com.google.android.calendar";
  static const String facebook = "com.facebook.katana";
  static const String instagram = "com.instagram.android";
  static const String kakaotalk = "com.kakao.talk";
  static const String line = "jp.naver.line.android";
  static const String linkedin = "com.linkedin.android";
  static const String messenger = "com.facebook.orca";
  static const String qq = "com.tencent.mobileqq";
  static const String sms = "com.google.android.apps.messaging";
  static const String skype = "com.skype.raider";
  static const String snap = "com.snapchat.android";
  static const String twitter = "com.twitter.android";
  static const String viber = "com.viber.voip";
  static const String vk = "com.vkontakte.android";
  static const String wechat = "com.tencent.mm";
  static const String whatsapp = "com.whatsapp";
  static const String gmail = "com.google.android.gm";
  static const String dingTalk = "com.alibaba.android.rimet";
  static const String workwechat = "com.tencent.wework";
  static const String googlechat = "com.google.android.apps.dynamite";
}

class Developer {
  static const String idSkaiwalk = "skaiwalk18Wo10qFScWr01LxRYk2";
  static const String idJack = "aKxNRx7OqRWo1CqFScWr53LxRYk2";
}

class AppConstant {
  static const bool isDevelopmentMode = true;
  static const bool usingDebugToast = true;
  static const bool usingDebugLog = true;
  static const bool usingScaffoldMessage = false;
  static const Duration bluetoothWriteDelayDuration =
      Duration(milliseconds: 60);
  static const Duration commandDelayDuration = Duration(milliseconds: 500);
  static const Duration oneSecondDelayDuration = Duration(seconds: 1);
  // ------ BWPS(bee wristband private protocol) Service ------ //
  static const String bwpsServiceUuid = "000001ff-3c17-d293-8e48-14fe2e4da212";
  static const String bwpsTxCharacteristicUuid =
      "ff02"; //0000ff02-0000-1000-8000-00805f9b34fb
  static const String bwpsRxCharacteristicUuid =
      "ff03"; //0000ff03-0000-1000-8000-00805f9b34fb
  static const String bwpsDeviceNameCharacteristicUuid =
      "ff04"; //0000ff04-0000-1000-8000-00805f9b34fb
  static const ConfigGsensor configGsensor =
      ConfigGsensor(featureCount: 3, bufferSizePerSample: 6);
  static const List<String> gestureTable = [
    "unknown",
    "tap",
    "snap",
    "grab",
    "release",
  ];
}
