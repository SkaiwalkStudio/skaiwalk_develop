import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_le_service.dart';
import 'gesture_detect_service.dart';
import 'inertial_model.dart';
import 'locator.dart';
import 'skaios_provider.dart';

enum ServiceType {
  bluetooth,
  voiceRecognition,
  voiceRecord,
  voicePlayback,
  watchSystem,
  motionTracking,
  gestureDetect,
  gestureDataCollction,
  notification,
  navigation,
  chatGPT,
  debug,
  database,
  auth,
  skaiLink,
  skaiNote,
  media,
}

enum BluetoothServiceType {
  enable,
  scanning,
  connected,
  deviceStatus,
  disconnect,
  pair,
  scan,
  pairAudioBT,
  bond,
  bwpsConnected,
}

enum WatchSystemServiceType {
  charge,
  backlight,
  liftSwitchStatus,
  twistSwitchStatus,
  sitAlertStatus,
  clockStatus,
  hourFormat,
  distanceUnit,
  dndMode,
  oledDisplayTime,
  language,
  deviceInfo,
  addAlarm,
  updateAlarm,
  deleteAlarm,
  overrideAlarms,
  cursor,
  tpGesture,
  gestureModeStatus,
  flashing,
  flashingProgress,
}

enum MotionTrackingServiceType {
  coordinate,
}

enum GestureDetectServiceType {
  label,
  classify,
}

enum GestureDataCollctionServiceType {
  recording,
  selectLabel,
  delete,
  save,
}

enum NotificationServiceType {
  enable,
  disable,
  send,
  remoteInput,
}

enum NavigationServiceType {
  navigate,
  navigateHome,
  navigateWithRepalcement,
  back,
}

enum ChatGPTServiceType { send, addMessage, setModel }

enum VoiceRecordServiceType {
  start,
  stop,
  pause,
  resume,
  seek,
}

enum VoicePlaybackServiceType {
  start,
  stop,
  pause,
  resume,
  seek,
}

enum VoiceRecognitionServiceType {
  toText,
  toSound,
  stop,
  isListening,
  resultText,
}

enum DebugServiceType {
  log,
  hintToast,
  debugToast,
}

enum DatabaseServiceType {
  todoStream,
  noteStream,
  chatRoomFuture,
  queryChatroom,
  chatMessageStream,
  subscribeChatMessage,
  sendChatMessage,
  skaiwalkMessageStream,
  subscribeSkaiwalkMessage,
  sendSkaiwalkMessage,
  querySkaiwalkMessage,
}

enum AuthServiceType {
  login,
  logout,
  register,
  resetPassword,
  changePassword,
  editPhoto,
  changeUserData,
}

enum SkaiLinkServiceType {
  url,
  pptIndex,
  controlSlider,
  curtainStatus,
  appOnpressIndex,
}

enum SkaiNoteServiceType {
  add,
  update,
  delete,
}

enum MediaServiceType {
  play,
  pause,
  skipPrevious,
  skipNext,
  volume,
  volumeUp,
  volumeDown,
  //
  sessions,
  currentPlaybackState,
  currentSessionTitle,
  currentSessionArtist,
  currentToken,
}

Future<void> skaiOSServiceHandler(Map<String, dynamic>? arg) async {
  if (arg == null) return;
  final service = ServiceType.values[arg['service']];
  final type = arg['type'];
  final param = arg['param'];
  switch (service) {
    case ServiceType.bluetooth:
      {
        final bluetoothType = BluetoothServiceType.values[type];
        switch (bluetoothType) {
          case BluetoothServiceType.disconnect:
            {
              await locator<BLEService>().disconnect();
            }
            break;
          case BluetoothServiceType.pair:
            {
              final deviceJson = param;
              final device = BluetoothDevice.fromId(deviceJson['address']);
              await locator<BLEService>().connect(device);
            }
            break;
          case BluetoothServiceType.scan:
            {
              bool isEnable = param;
              if (isEnable) {
                await locator<BLEService>().startScanning();
              } else {
                locator<BLEService>().stopScanning();
              }
            }
            break;
          default:
            break;
        }
      }
      break;
    case ServiceType.gestureDetect:
      {
        final gestureDetectType = GestureDetectServiceType.values[type];
        switch (gestureDetectType) {
          case GestureDetectServiceType.classify:
            {
              List<Map<String, dynamic>> mapList = param;
              List<MARGModel> inputDataset =
                  mapList.map((map) => MARGModel.fromMap(map)).toList();
              locator<GestureDetectService>().classifyGesture(inputDataset);
            }
            break;
          default:
            break;
        }
      }
      break;
    case ServiceType.gestureDataCollction:
      {
        final gestureDataCollctionType =
            GestureDataCollctionServiceType.values[type];
        switch (gestureDataCollctionType) {
          case GestureDataCollctionServiceType.recording:
            {
              locator<MARGDatabaseService>().setIsRecordingAccelerometer =
                  param;
            }
            break;
          case GestureDataCollctionServiceType.selectLabel:
            {
              locator<MARGDatabaseService>().selectedMotionLabel = param;
            }
            break;
          case GestureDataCollctionServiceType.delete:
            {
              var label = locator<MARGDatabaseService>().selectedMotionLabel;
              await locator<MARGDatabaseService>().delete(label);
              if (label == 'grab') {
                label = 'release';
              } else if (label == 'release') {
                label = 'grab';
              }
              await locator<MARGDatabaseService>().delete(label);
            }
            break;
          case GestureDataCollctionServiceType.save:
            {
              var label = locator<MARGDatabaseService>().selectedMotionLabel;
              var dataset = await locator<MARGDatabaseService>().getMARG(label);
              if (dataset.isEmpty) {
                return;
              }
              await locator<MARGDatabaseService>().saveDataset(label, dataset);
              await locator<MARGDatabaseService>().delete(label);
              if (label != "grab" && label != "release") {
                return;
              }
              if (label == "grab") {
                label = "release";
              } else if (label == "release") {
                label = "grab";
              }
              dataset = await locator<MARGDatabaseService>().getMARG(label);
              if (dataset.isEmpty) {
                return;
              }
              await locator<MARGDatabaseService>().saveDataset(label, dataset);
              await locator<MARGDatabaseService>().delete(label);
            }
            break;
        }
      }
      break;

    default:
      break;
  }
}

// to ui
Future<void> notifySkaiOSProvider(ServiceType serviceType, int type,
    {dynamic param}) async {
  debugPrint("Notify SkaiOSProvider: $serviceType, $type, $param");
  await locator<SkaiOSProvider>().uiHandler(serviceType, type, param: param);
}

// to background
Future<void> notifySkaiOSService(ServiceType serviceType, int type,
    {dynamic param}) async {
  final arg = {
    "service": serviceType.index,
    "type": type,
    "param": param,
  };
  debugPrint("notifySkaiOSService: $serviceType, $type, $param");
  await skaiOSServiceHandler(arg);
}
