import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String themeModeKey = 'theme'; //應用程式的色彩模式
  static const String isLoginKey = 'auth';
  static const String userIdKey = "USERIDKEY";
  static const String userNameKey = "USERNAMEKEY";
  static const String displayNameKey = "USERDISPLAYNAME";
  static const String userEmailKey = "USEREMAILKEY";
  static const String userPasswordKey = "USERPASSWORDKEY";
  static const String userProfileUrlKey = "USERPROFILEKEY";

  static const String targetDeviceKey = "TARGETDEVICENAME";
  static const String bondedKey = 'binded';
  static const String watchAudioKey = 'WATCH_AUDIO_KEY';
  static const String watchSysKey = 'WATCHSYS';
  static const String alarmModifiedKey = 'ALARM_MODIFIED_KEY';

  /// APP的主題色彩模式
  Future<int> get themeMode async => await _getFromDisk(themeModeKey) ?? 1;
  Future<void> setThemeMode(int value) async =>
      await _saveToDisk(themeModeKey, value);

  /// APP登入狀態
  Future<bool> get isLogin async => await _getFromDisk(isLoginKey) ?? false;
  Future<void> setLoginState(bool value) async =>
      await _saveToDisk(isLoginKey, value);

  Future<String> get userId async => await _getFromDisk(userIdKey) ?? '';
  Future<void> storeUserId(String value) async =>
      await _saveToDisk(userIdKey, value);
  Future<void> removeUserId() async => await _removeFromDisk(userIdKey);

  Future<String> get userName async => await _getFromDisk(userNameKey) ?? '';
  Future<void> storeUserName(String value) async =>
      await _saveToDisk(userNameKey, value);

  Future<String> get userEmail async => await _getFromDisk(userEmailKey) ?? '';
  Future<void> storeUserEmail(String value) async =>
      await _saveToDisk(userEmailKey, value);

  Future<String> get userPassword async =>
      await _getFromDisk(userPasswordKey) ?? '';
  Future<void> storeUserPassword(String value) async =>
      await _saveToDisk(userPasswordKey, value);

  Future<String> get userProfileUrl async =>
      await _getFromDisk(userProfileUrlKey) ?? '';
  Future<void> storeUserProfileUrl(String value) async =>
      await _saveToDisk(userProfileUrlKey, value);

  Future<Map<String, dynamic>> getUidAndPassword() async {
    final uid = await userId;
    final password = await userPassword;
    return {
      'uid': uid,
      'password': password,
    };
  }

  Future<String> get bondedAddress async {
    final address = await _getFromDisk(bondedKey);
    if (address == null) return "";
    return address as String;
  }

  Future<void> storeBondedAddress(String address) async {
    await _saveToDisk(bondedKey, address);
  }

  /// 使用鑰匙[key]從內存中取得數據
  Future _getFromDisk(String key) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.reload();
    final value = sp.get(key);
    if (kDebugMode) {
      print(
          '(TRACE) LocalStorageService:_getFromDisk. key: $key value: $value');
    }
    return value;
  }

  /// 儲存數據[content]至內存
  Future<void> _saveToDisk<T>(String key, T content) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.reload();
    if (kDebugMode) {
      print(
          '(TRACE) LocalStorageService:_saveStringToDisk. key: $key value: $content');
    }
    if (content is String) {
      await sp.setString(key, content);
    }
    if (content is bool) {
      await sp.setBool(key, content);
    }
    if (content is int) {
      await sp.setInt(key, content);
    }
    if (content is double) {
      await sp.setDouble(key, content);
    }
    if (content is List<String>) {
      await sp.setStringList(key, content);
    }
  }

  Future<void> _removeFromDisk(String key) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.reload();
    await sp.remove(key);
  }
}
