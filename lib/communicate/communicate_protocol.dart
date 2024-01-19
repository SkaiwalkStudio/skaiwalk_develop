import 'communicate_task.dart';

const int disable = 0x00;
const int enable = 0x01;

enum CommunicateDevice {
  watch,
  phone,
  desktop,
  web,
}

////////// 2023 Communicate Protocol [GATT_SRV_BWPS_TX_INDEX]/////////////
/* Header */
/*  phone ---> watch */
/*  watch ---> phone */
const int l2HeaderSize = 2;
const int l2HeaderVersion = 0x00;
const int l2keySize = 1;
const int l2PayladHeaderSize = 3;
const int l2FirstValuePosition = l2HeaderSize + l2PayladHeaderSize;

class L2Header {
  final WristbandCommunicateCommand commandId;
  final int firstKey;
  final int valueLength;
  const L2Header(this.commandId, this.firstKey, this.valueLength);
  /* written by Chat-GPT */
  @override
  String toString() {
    return 'L2Header(commandId: $commandId, firstKey: $firstKey, valueLength: $valueLength)';
  }
}

List<int> encodeL2Header(L2Header l2Header) {
  List<int> header = [];
  header.add(l2Header.commandId.value); /* command id */
  header.add(l2HeaderVersion); /* L2 header version */
  header.add(l2Header.firstKey); /* first key */
  int high = (l2Header.valueLength >> 8) & 0xff; /* length high */
  int low = l2Header.valueLength & 0xff; /* length low */
  header.addAll([high, low]);
  return header;
}

L2Header? decodeL2Header(List<int> l2Header) {
  if (l2Header[1] != l2HeaderVersion) {
    return null;
  }
  WristbandCommunicateCommand commandId =
      WristbandCommunicateCommand.fromInt(l2Header[0]);
  int firstKey = l2Header[2];
  int valueLength = ((l2Header[3] << 8) | l2Header[4]) & 0x1FF;
  return L2Header(commandId, firstKey, valueLength);
}

// https://medium.com/codex/flutter-3-what-are-enums-and-what-is-new-about-it-f5f2c481e7b5
/* Command ID */
enum WristbandCommunicateCommand {
  firmwareUpdateCmdId(0x01),
  setConfigCommandId(0x02),
  bondCommandId(0x03),
  notifyCommandId(0x04),
  healthDataCommandId(0x05),
  factoryTestCommandId(0x06),
  controlCommandId(0x07),
  weatherInformationId(0x0b),
  bluetoothLogCommandId(0x0a),
  getStackDump(0x10),
  testFlashReadWrite(0xfe),
  testCommandId(0xff),
  voiceRecognitionResult(0x08),
  skaiLinkCommandId(0x20);

  final int value;
  const WristbandCommunicateCommand(this.value);
  static WristbandCommunicateCommand fromInt(int value) {
    switch (value) {
      case 0x01:
        return WristbandCommunicateCommand.firmwareUpdateCmdId;
      case 0x02:
        return WristbandCommunicateCommand.setConfigCommandId;
      case 0x03:
        return WristbandCommunicateCommand.bondCommandId;
      case 0x04:
        return WristbandCommunicateCommand.notifyCommandId;
      case 0x05:
        return WristbandCommunicateCommand.healthDataCommandId;
      case 0x06:
        return WristbandCommunicateCommand.factoryTestCommandId;
      case 0x07:
        return WristbandCommunicateCommand.controlCommandId;
      case 0x0b:
        return WristbandCommunicateCommand.weatherInformationId;
      case 0x0a:
        return WristbandCommunicateCommand.bluetoothLogCommandId;
      case 0x10:
        return WristbandCommunicateCommand.getStackDump;
      case 0x20:
        return WristbandCommunicateCommand.skaiLinkCommandId;
      case 0xfe:
        return WristbandCommunicateCommand.testFlashReadWrite;
      case 0xff:
        return WristbandCommunicateCommand.testCommandId;
      default:
        throw ArgumentError('Invalid WristbandCommunicateCommand value');
    }
  }
}

/* Setitng Key */
enum SettingsKey {
  keyTimeSettings(0x01),
  keyAlarmSettings(0x02),
  keyRequestAlarmSettings(0x03),
  keyReturnAlarmSettings(0x04),
  keyStepTargetSettings(0x05),
  keySleepTargetSettings(0x06),
  keyProfileSettings(0x10),
  keyDevLossAlertSettings(0x20),
  keyLongTimeSitAlert(0x21),
  keyPhoneOsVersion(0x23),
  keyIncommingMessageSettings(0x25),
  keyLongTimeSitSettingRequest(0x26),
  keyLongTimeSitSettingReturn(0x27),
  keyIncommingMessageSettingsRequest(0x28),
  keyIncommingMessageSettingsReturn(0x29),
  keyLiftSwitchSetting(0x2a),
  keyLiftSwitchRequest(0x2b),
  keyLiftSwitchReturn(0x2c),
  keyIncommingMessageAllSettings(0x2d),
  keyTwistSwitchSetting(0x30),
  keyTwistSwitchRequest(0x31),
  keyTwistSwitchReturn(0x32),
  keyDisplaySwitchSetting(0x33),
  keyDisplaySwtichRequest(0x34),
  keyDisplaySwtichReturn(0x35),
  keyFunctionsRequest(0x36),
  keyFunctionsReturn(0x37),
  keyDialSetting(0x38),
  keyDialRequest(0x39),
  keyDialReturn(0x3a),
  keyExercisemodeRequest(0x3b),
  keyBeikeMsgSetting(0x3c),
  keyBeikeMsgRequest(0x3d),
  keyBeikeMsgReturn(0x3e),
  keyHrSampleRequest(0x3f),
  keyHourFormatSetting(0x41),
  keyHourFormatRequest(0x42),
  keyHourFormatReturn(0x43),
  keyDistanceUnitSetting(0x44),
  keyDistanceUnitRequest(0x45),
  keyDistanceUnitReturn(0x46),
  keyDndmSetting(0x47),
  keyDndmRequest(0x48),
  keyDndmReturn(0x49),
  keyOledDisplayTimeSetting(0x4a),
  keyOledDisplayTimeRequest(0x4b),
  keyOledDisplayTimeReturn(0x4c),
  keyLanguageSetting(0x4e),
  keyLanguageRequest(0x4f),
  keyLanguageReturn(0x50),
  keyDeviceinfoRequest(0x51),
  keyDeviceinfoReturn(0x52),
  keyBacklightSetting(0x53),
  keyBacklightRequest(0x54),
  keyBacklightReturn(0x55),
  keyHiddenFuncSetting(0x59),
  keyHiddenFuncRequest(0x5a),
  keyHiddenFuncReturn(0x5b),
  keyBbproMacRequest(0x60),
  keyBbproStateRequest(0x61),
  keyBbproConnectedStateRequest(0x62),
  keyBbproConnectedStateReturn(0x63),
  keyBbproCreateConnectionRequest(0x64),
  keyMotorStrengthSetting(0x65),
  keyMotorPeriodSetting(0x66),
  keyGestureAccelLimitSetting(0x67),
  keyPeripheralDebugSwitch(0x68);

  final int value;
  const SettingsKey(this.value);
  static SettingsKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return SettingsKey.keyTimeSettings;
      case 0x02:
        return SettingsKey.keyAlarmSettings;
      case 0x03:
        return SettingsKey.keyRequestAlarmSettings;
      case 0x04:
        return SettingsKey.keyReturnAlarmSettings;
      case 0x05:
        return SettingsKey.keyStepTargetSettings;
      case 0x06:
        return SettingsKey.keySleepTargetSettings;
      case 0x10:
        return SettingsKey.keyProfileSettings;
      case 0x20:
        return SettingsKey.keyDevLossAlertSettings;
      case 0x21:
        return SettingsKey.keyLongTimeSitAlert;
      case 0x23:
        return SettingsKey.keyPhoneOsVersion;
      case 0x25:
        return SettingsKey.keyIncommingMessageSettings;
      case 0x26:
        return SettingsKey.keyLongTimeSitSettingRequest;
      case 0x27:
        return SettingsKey.keyLongTimeSitSettingReturn;
      case 0x28:
        return SettingsKey.keyIncommingMessageSettingsRequest;
      case 0x29:
        return SettingsKey.keyIncommingMessageSettingsReturn;
      case 0x2a:
        return SettingsKey.keyLiftSwitchSetting;
      case 0x2b:
        return SettingsKey.keyLiftSwitchRequest;
      case 0x2c:
        return SettingsKey.keyLiftSwitchReturn;
      case 0x2d:
        return SettingsKey.keyIncommingMessageAllSettings;
      case 0x30:
        return SettingsKey.keyTwistSwitchSetting;
      case 0x31:
        return SettingsKey.keyTwistSwitchRequest;
      case 0x32:
        return SettingsKey.keyTwistSwitchReturn;
      case 0x33:
        return SettingsKey.keyDisplaySwitchSetting;
      case 0x34:
        return SettingsKey.keyDisplaySwtichRequest;
      case 0x35:
        return SettingsKey.keyDisplaySwtichReturn;
      case 0x36:
        return SettingsKey.keyFunctionsRequest;
      case 0x37:
        return SettingsKey.keyFunctionsReturn;
      case 0x38:
        return SettingsKey.keyDialSetting;
      case 0x39:
        return SettingsKey.keyDialRequest;
      case 0x3a:
        return SettingsKey.keyDialReturn;
      case 0x3b:
        return SettingsKey.keyExercisemodeRequest;
      case 0x3c:
        return SettingsKey.keyBeikeMsgSetting;
      case 0x3d:
        return SettingsKey.keyBeikeMsgRequest;
      case 0x3e:
        return SettingsKey.keyBeikeMsgReturn;
      case 0x3f:
        return SettingsKey.keyHrSampleRequest;
      case 0x41:
        return SettingsKey.keyHourFormatSetting;
      case 0x42:
        return SettingsKey.keyHourFormatRequest;
      case 0x43:
        return SettingsKey.keyHourFormatReturn;
      case 0x44:
        return SettingsKey.keyDistanceUnitSetting;
      case 0x45:
        return SettingsKey.keyDistanceUnitRequest;
      case 0x46:
        return SettingsKey.keyDistanceUnitReturn;
      case 0x47:
        return SettingsKey.keyDndmSetting;
      case 0x48:
        return SettingsKey.keyDndmRequest;
      case 0x49:
        return SettingsKey.keyDndmReturn;
      case 0x4a:
        return SettingsKey.keyOledDisplayTimeSetting;
      case 0x4b:
        return SettingsKey.keyOledDisplayTimeRequest;
      case 0x4c:
        return SettingsKey.keyOledDisplayTimeReturn;
      case 0x4e:
        return SettingsKey.keyLanguageSetting;
      case 0x4f:
        return SettingsKey.keyLanguageRequest;
      case 0x50:
        return SettingsKey.keyLanguageReturn;
      case 0x51:
        return SettingsKey.keyDeviceinfoRequest;
      case 0x52:
        return SettingsKey.keyDeviceinfoReturn;
      case 0x53:
        return SettingsKey.keyBacklightSetting;
      case 0x54:
        return SettingsKey.keyBacklightRequest;
      case 0x55:
        return SettingsKey.keyBacklightReturn;
      case 0x59:
        return SettingsKey.keyHiddenFuncSetting;
      case 0x5a:
        return SettingsKey.keyHiddenFuncRequest;
      case 0x5b:
        return SettingsKey.keyHiddenFuncReturn;
      case 0x60:
        return SettingsKey.keyBbproMacRequest;
      case 0x61:
        return SettingsKey.keyBbproStateRequest;
      case 0x62:
        return SettingsKey.keyBbproConnectedStateRequest;
      case 0x63:
        return SettingsKey.keyBbproConnectedStateReturn;
      case 0x64:
        return SettingsKey.keyBbproCreateConnectionRequest;
      case 0x65:
        return SettingsKey.keyMotorStrengthSetting;
      case 0x66:
        return SettingsKey.keyMotorPeriodSetting;
      case 0x67:
        return SettingsKey.keyGestureAccelLimitSetting;
      case 0x68:
        return SettingsKey.keyPeripheralDebugSwitch;
      default:
        throw ArgumentError('Invalid SettingsKey value');
    }
  }
}

/* Bond Key */
enum BondKey {
  keyBondRequest(0x01),
  keyBondRespose(0x02),
  keyLoginRequest(0x03),
  keyLoginResponse(0x04),
  keyUnbond(0x05),
  keySuperBond(0x06),
  keySuperBondResponse(0x07);

  final int value;
  const BondKey(this.value);
  static BondKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return BondKey.keyBondRequest;
      case 0x02:
        return BondKey.keyBondRespose;
      case 0x03:
        return BondKey.keyLoginRequest;
      case 0x04:
        return BondKey.keyLoginResponse;
      case 0x05:
        return BondKey.keyUnbond;
      case 0x06:
        return BondKey.keySuperBond;
      case 0x07:
        return BondKey.keySuperBondResponse;
      default:
        throw ArgumentError('Invalid BondKey value');
    }
  }
}

/* Notify Key */
enum NotifyKey {
  keyIncommingCall(0x01),
  keyIncommingCallAccept(0x02),
  keyIncommingCallRefuse(0x03),
  keyIncommingMessage(0x04),
  keyIncommingCallReject(0x05),
  keyBatteryChargeStatus(0x06),
  keyIncommingCallId(0x07),
  keyBBproMacAddressReturn(0x10),
  keyBBproStateReturn(0x11),
  keyAncsIncommingCallReturn(0x12),
  keyBBproConnInfoReturn(0x13),
  keyVoiceRecognitionResult(0x14),
  keyGsensorSample(0x15),
  keyWristCoordinate(0x16),
  keyGestureDetect(0x17),
  keyMovementSensitivity(0x18),
  keyCreateTask(0x1a),
  keyToggleTask(0x1b),
  keyTaskSyncStart(0x1c),
  keyTaskSyncEnd(0x1d),
  keyUpdateTask(0x1e),
  keyGetNote(0x1f),
  keyRemoteInput(0x20),
  keyCreateNote(0x21),
  keyNoteSyncStart(0x22),
  keyNoteSyncEnd(0x23),
  keyUpdateNote(0x24),
  keyWatchFontSyncStart(0x30),
  keyWatchFontSyncEnd(0x31),
  keyUpdateWatchFont(0x32),
  keyWatchImageSyncStart(0x33),
  keyWatchImageSyncEnd(0x34),
  keyUpdateWatchImage(0x35),
  keyWatchIconSyncStart(0x36),
  keyWatchIconSyncEnd(0x37),
  keyUpdateWatchIcon(0x38),
  keyWatchFaceSyncStart(0x39),
  keyWatchFaceSyncEnd(0x3a),
  keyUpdateWatchFace(0x3b),
  keyHeartRateSensorSample(0x40),
  keyHeartRateSensorResult(0x41),
  keyWatchSysRequest(0x42),
  keyWatchSysReturn(0x43),
  keyReturnChatIntent(0x44),
  keyChatResult(0x45),
  keyMediaTitle(0x46),
  keyQuaternionData(0x47);

  final int value;
  const NotifyKey(this.value);
  static NotifyKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return NotifyKey.keyIncommingCall;
      case 0x02:
        return NotifyKey.keyIncommingCallAccept;
      case 0x03:
        return NotifyKey.keyIncommingCallRefuse;
      case 0x04:
        return NotifyKey.keyIncommingMessage;
      case 0x05:
        return NotifyKey.keyIncommingCallReject;
      case 0x06:
        return NotifyKey.keyBatteryChargeStatus;
      case 0x07:
        return NotifyKey.keyIncommingCallId;
      case 0x10:
        return NotifyKey.keyBBproMacAddressReturn;
      case 0x11:
        return NotifyKey.keyBBproStateReturn;
      case 0x12:
        return NotifyKey.keyAncsIncommingCallReturn;
      case 0x13:
        return NotifyKey.keyBBproConnInfoReturn;
      case 0x14:
        return NotifyKey.keyVoiceRecognitionResult;
      case 0x15:
        return NotifyKey.keyGsensorSample;
      case 0x16:
        return NotifyKey.keyWristCoordinate;
      case 0x17:
        return NotifyKey.keyGestureDetect;
      case 0x18:
        return NotifyKey.keyMovementSensitivity;

      case 0x1a:
        return NotifyKey.keyCreateTask;
      case 0x1b:
        return NotifyKey.keyToggleTask;
      case 0x1c:
        return NotifyKey.keyTaskSyncStart;
      case 0x1d:
        return NotifyKey.keyTaskSyncEnd;
      case 0x1e:
        return NotifyKey.keyUpdateTask;
      case 0x1f:
        return NotifyKey.keyGetNote;
      case 0x20:
        return NotifyKey.keyRemoteInput;
      case 0x21:
        return NotifyKey.keyCreateNote;
      case 0x22:
        return NotifyKey.keyNoteSyncStart;
      case 0x23:
        return NotifyKey.keyNoteSyncEnd;
      case 0x24:
        return NotifyKey.keyUpdateNote;
      case 0x30:
        return NotifyKey.keyWatchFontSyncStart;
      case 0x31:
        return NotifyKey.keyWatchFontSyncEnd;
      case 0x32:
        return NotifyKey.keyUpdateWatchFont;
      case 0x33:
        return NotifyKey.keyWatchImageSyncStart;
      case 0x34:
        return NotifyKey.keyWatchImageSyncEnd;
      case 0x35:
        return NotifyKey.keyUpdateWatchImage;

      case 0x36:
        return NotifyKey.keyWatchIconSyncStart;
      case 0x37:
        return NotifyKey.keyWatchIconSyncEnd;
      case 0x38:
        return NotifyKey.keyUpdateWatchIcon;

      case 0x39:
        return NotifyKey.keyWatchIconSyncStart;
      case 0x3a:
        return NotifyKey.keyWatchIconSyncEnd;
      case 0x3b:
        return NotifyKey.keyUpdateWatchIcon;

      case 0x40:
        return NotifyKey.keyHeartRateSensorSample;
      case 0x41:
        return NotifyKey.keyHeartRateSensorResult;
      case 0x42:
        return NotifyKey.keyWatchSysRequest;
      case 0x43:
        return NotifyKey.keyWatchSysReturn;
      case 0x44:
        return NotifyKey.keyReturnChatIntent;
      case 0x45:
        return NotifyKey.keyChatResult;
      case 0x46:
        return NotifyKey.keyMediaTitle;
      case 0x47:
        return NotifyKey.keyQuaternionData;
      
      default:
        throw ArgumentError('Invalid value for NotifyKey: $value');
    }
  }
}

enum NotificationsType {
  notifyCalendar,
  notifyFacebook,
  notifyFacetime,
  notifyInstagram,
  notifyKakaotalk,
  notifyLine,
  notifyLinkedin,
  notifyMail,
  notifyMessenger,
  notifyOthers,
  notifyQQ,
  notifySkype,
  notifySMS,
  notifySnap,
  notifyTim,
  notifyTwitter,
  notifyViber,
  notifyVk,
  notifyWechat,
  notifyWhatsapp,
  notifyGmail,
  notifyDingtalk,
  notifyWorkwechat,
  notifyAplus,
  notifyLINK,
  notifyBeike,
  notifyLianjia,
  notifyCalling,
  notifyGooglechat,
} // NOTIFICATIONS_TYPE;

/* Health Key */
enum HealthKey {
  keyRequestData(0x01),
  keyReturnSportsData(0x02),
  keyReturnSleepData(0x03),
  keyMore(0x04),
  keyReturnSleepSetting(0x05),
  keySetStepsNotify(0x06),
  keyDataSyncStart(0x07),
  keyDataSyncEnd(0x08),
  keyDailyDataSync(0x09),
  keyLatestDataSync(0x0A),
  keyDailyDataCalibration(0x0B),
  keyDailyDataCalibrationReturn(0x0C),
  keyRequestHeartData(0x0D),
  keyHeartDataSampleSetting(0x0E),
  keyHeartDataReturn(0x0F),
  keyCancelHeartSample(0x10),
  keyRequestHeartSampleSetting(0x11),
  keyReturnHeartSampleSetting(0x12);

  final int value;
  const HealthKey(this.value);
  static HealthKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return HealthKey.keyRequestData;
      case 0x02:
        return HealthKey.keyReturnSportsData;
      case 0x03:
        return HealthKey.keyReturnSleepData;
      case 0x04:
        return HealthKey.keyMore;
      case 0x05:
        return HealthKey.keyReturnSleepSetting;
      case 0x06:
        return HealthKey.keySetStepsNotify;
      case 0x07:
        return HealthKey.keyDataSyncStart;
      case 0x08:
        return HealthKey.keyDataSyncEnd;
      case 0x09:
        return HealthKey.keyDailyDataSync;
      case 0x0a:
        return HealthKey.keyLatestDataSync;
      case 0x0b:
        return HealthKey.keyDailyDataCalibration;
      case 0x0c:
        return HealthKey.keyDailyDataCalibrationReturn;
      case 0x0d:
        return HealthKey.keyRequestHeartData;
      case 0x0e:
        return HealthKey.keyHeartDataSampleSetting;
      case 0x0f:
        return HealthKey.keyHeartDataReturn;
      case 0x10:
        return HealthKey.keyCancelHeartSample;
      case 0x11:
        return HealthKey.keyRequestHeartSampleSetting;
      case 0x12:
        return HealthKey.keyReturnHeartSampleSetting;
      default:
        throw ArgumentError('Invalid HealthKey value');
    }
  }
}

/* Control Key */
enum ControlKey {
  keyTakePhoto(0x01),
  keyFindPhone(0x02),
  keyFindWatch(0x03),
  keyPhoneMediaControl(0x04),
  keyPhoneMediaStatus(0x05),
  keyPhoneVolume(0x06),
  keyReturnVolume(0x07),
  keyPhoneCameraStatus(0x11),
  keyVoice2TextStatus(0x12),
  keyReturnVoice2TextIntent(0x13),
  keyVoiceRecordStatus(0x14),
  keyReturnVoiceRecordIntent(0x15),
  keyGestureModeStatus(0x16),
  keyTouchpadCoordinate(0x20),
  keyTouchpadGesture(0x21),
  keyUnitTestUnicode(0xE0);

  final int value;
  const ControlKey(this.value);

  static ControlKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return keyTakePhoto;
      case 0x02:
        return keyFindPhone;
      case 0x03:
        return keyFindWatch;
      case 0x04:
        return keyPhoneMediaControl;
      case 0x05:
        return keyPhoneMediaStatus;
      case 0x06:
        return keyPhoneVolume;
      case 0x07:
        return keyReturnVolume;
      case 0x11:
        return keyPhoneCameraStatus;
      case 0x12:
        return keyVoice2TextStatus;
      case 0x13:
        return keyReturnVoice2TextIntent;
      case 0x14:
        return keyVoiceRecordStatus;
      case 0x15:
        return keyReturnVoiceRecordIntent;
      case 0x16:
        return keyGestureModeStatus;
      case 0x20:
        return keyTouchpadCoordinate;
      case 0x21:
        return keyTouchpadGesture;
      case 0xE0:
        return keyUnitTestUnicode;
      default:
        throw Exception('Invalid ControlKey value');
    }
  }
}

/* Bluetooth Log Key */
enum BluetoothLogKey {
  keyDebug(0x01);

  final int value;
  const BluetoothLogKey(this.value);
  static BluetoothLogKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return BluetoothLogKey.keyDebug;
      default:
        throw ArgumentError('Invalid BluetoothLogKey value');
    }
  }
}

enum SkaiLinkKey {
  keyBrowser(0x01),
  keySetPresentation(0x02),
  keyReturnPresentationId(0x03),
  keySetPresentData(0x04),
  keyReturnPresentData(0x05),
  keyReturnSlideCommand(0x06),
  keySetSlideUrl(0x07),
  keySetNoteId(0x08),
  keySkaiosMode(0x09),
  keyReturnCurtainStatus(0x0A),
  keyAppOnpressIndex(0x0B);

  final int value;
  const SkaiLinkKey(this.value);
  static SkaiLinkKey fromInt(int value) {
    switch (value) {
      case 0x01:
        return SkaiLinkKey.keyBrowser;
      case 0x02:
        return SkaiLinkKey.keySetPresentation;
      case 0x03:
        return SkaiLinkKey.keyReturnPresentationId;
      case 0x04:
        return SkaiLinkKey.keySetPresentData;
      case 0x05:
        return SkaiLinkKey.keyReturnPresentData;
      case 0x06:
        return SkaiLinkKey.keyReturnSlideCommand;
      case 0x07:
        return SkaiLinkKey.keySetSlideUrl;
      case 0x08:
        return SkaiLinkKey.keySetNoteId;
      case 0x09:
        return SkaiLinkKey.keySkaiosMode;
      case 0x0A:
        return SkaiLinkKey.keyReturnCurtainStatus;
      case 0x0B:
        return SkaiLinkKey.keyAppOnpressIndex;
      default:
        throw ArgumentError('Invalid BluetoothLogKey value');
    }
  }
}

enum BrowserIntent {
  nothing,
  openOnMobile,
  openOnDesktop,
}

enum L1SendType {
  l1SendUnbond,
  l1SendBondRequest,
  l1SendLoginRequest,
  l1SendPhoneCameraStatus,
  l1SendVoice2TextStatus,
  l1SendVoiceRecognitionResult,
  l1SendResetRemoteUrl,
  l1SendRemoteOpenUrl,
  l1SendNoteId,
  l1SendMotorTest,
  l1SendWatchBinary,
  l1SendRtcTime,
  l1SendPhoneOSVersion,
  l1SendAlarmSettings,
  l1SendRequestAlarmSettings,
  l1SendDeviceInfo,
  l1SendStepTarget,
  l1SendSleepTarget,
  l1SendRequestHistoryData,
  l1SendMediaTitle,
  l1SendMediaStatus,
  l1SendUserProfile,
  l1SendHourFormat,
  l1SendRequestHourFormat,
  l1SendDistanceUnit,
  l1SendRequestDistanceUnit,
  l1SendBackLight,
  l1SendRequestBackLight,
  l1SendDial,
  l1SendRequestDial,
  l1SendLongTimeSitAlert,
  l1SendRequestLongTimeSitAlert,
  l1SendDNDMode,
  l1SendRequestDNDMode,
  l1SendLiftSwitch,
  l1SendRequestLiftSwitch,
  l1SendTwistSwitch,
  l1SendRequestTwistSwitch,
  l1SendFindWatch,
  l1SendDisplayTime,
  l1SendRequestDisplayTime,
  l1SendLanguage,
  l1SendRequestLanguage,
  l1SendHorizontalMovementSensitivity,
  l1SendTestUnicode,
  l1SendVibrationLevel,
  l1SendVibrationPeriod,
  l1SendGestureAccelLimitThreshold,
  l1SendVoiceRecordStatus,
  l1SendPhoneVolume,
  l1SendRequestWatchSystem,
  l1SendControlSlider,
  l1SendWebSlideUrl,
  l1SendNotification,
  l1SendListeningNotification,
  l1SendTaskToWatch,
  l1SendChatIntent,
  l1SendChatGPTResult,
  l1SendNoteToWatch,
  l1SendDebugSwitchCommand,
}

// inside background service
Future<void> l1Send(L1SendType type, {dynamic param}) async {
  await l1SendHandler({
    'type': type.index,
    'param': param,
  });
}
