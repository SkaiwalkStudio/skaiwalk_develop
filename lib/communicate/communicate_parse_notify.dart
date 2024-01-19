import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constant/app_constant.dart';
import '../helper/time_helper.dart';
import '../service/external_storage_service.dart';
import '../service/gesture_detect_service.dart';
import '../model/inertial_model.dart';
import '../locator.dart';
import '../model/log_model.dart';
import '../skaios/skai_os_interface.dart';
import 'communicate_protocol.dart';

class NotifyResolver {
  void resolve(L2Header l2Header, List<int> firstValue) {
    if (l2Header.valueLength != firstValue.length) {
      return;
    }
    resolveNotifyCommand(l2Header.firstKey, firstValue);
  }

  void resolveNotifyCommand(int key, List<int> pValue) async {
    final notifyKey = NotifyKey.fromInt(key);
    String? debugMessage;
    switch (notifyKey) {
      case NotifyKey.keyGsensorSample:
        {
          final dataset = await parseGsensorSample(
              pValue, AppConstant.configGsensor.sampleCount);
          debugMessage = await storeGsensorDataset(dataset);
          // notifySkaiOSService(
          //   ServiceType.gestureDetect,
          //   GestureDetectServiceType.classify.index,
          //   param: dataset.map((e) => e.toMap()).toList(),
          // );
          await notifySkaiOSProvider(
            ServiceType.gestureDataCollction,
            GestureDataCollctionServiceType.plot.index,
            param: dataset.map((e) => e.toMap()).toList(),
          );
        }
        break;
      case NotifyKey.keyGestureDetect:
        {
          int label = pValue[0];
          if (label >= 0) {
            GestureType gestureType = GestureType.values[label];
            await notifySkaiOSProvider(
              ServiceType.gestureDetect,
              GestureDetectServiceType.label.index,
              param: label,
            );
            debugMessage = "${gestureType.name}[$label] on mobile!";
          }
        }
        break;
      case NotifyKey.keyHeartRateSensorSample:
        {
          List<int> samples = [];
          for (var i = 0; i < 30; i++) {
            Uint8List array =
                Uint8List.fromList([pValue[i * 2], pValue[i * 2 + 1]]);
            int value = (array[0] << 8) | array[1];
            samples.add(value);
          }
          debugMessage =
              "heart rate samples len = ${samples.length} "; //"From buf = $pValue, Got heart samples = $samples";
          await storeHeartSamples(samples);
          await notifySkaiOSProvider(
            ServiceType.heartrateDataCollction,
            HRDataCollctionServiceType.plot.index,
            param: samples,
          );
        }
        break;
      default:
        break;
    }
    if (AppConstant.usingDebugLog) {
      final logModelMap = LogMessagePacket(
              firstKey: notifyKey.toString(), message: debugMessage)
          .toMap();
      notifySkaiOSProvider(ServiceType.debug, DebugServiceType.log.index,
          param: logModelMap);
    }
    if (AppConstant.usingDebugToast) {
      if (debugMessage != null) {
        notifySkaiOSProvider(
            ServiceType.debug, DebugServiceType.debugToast.index,
            param: debugMessage);
      }
    }
  }

  Future<List<MARGModel>> parseGsensorSample(
      List<int> buffer, int sampleCount) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final gsensorBuffer = Uint8List.fromList(buffer);
    final byteData = ByteData.sublistView(gsensorBuffer);
    List<MARGModel> margDataset = [];
    for (int sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      // 6 bytes per sample(3-axis)
      // 12 bytes per sample(6-axis)
      int offset = AppConstant.configGsensor.bufferSizePerSample * sampleIndex;
      List<double> dataset = [];
      int accelerationAxisX = byteData.getInt16(offset, Endian.little);
      int accelerationAxisY = byteData.getInt16(offset + 2, Endian.little);
      int accelerationAxisZ = byteData.getInt16(offset + 4, Endian.little);
      dataset.addAll([
        accelerationAxisX / 16384.0 * 9.8,
        accelerationAxisY / 16384.0 * 9.8,
        accelerationAxisZ / 16384.0 * 9.8,
      ]);
      if (AppConstant.configGsensor.bufferSizePerSample == 8) {
        int ppg = byteData.getInt16(offset + 6, Endian.little);
        dataset.add(ppg.toDouble());
      } else if (AppConstant.configGsensor.bufferSizePerSample == 12) {
        int gravityX = byteData.getInt16(offset + 6, Endian.little);
        int gravityY = byteData.getInt16(offset + 8, Endian.little);
        int gravityZ = byteData.getInt16(offset + 10, Endian.little);
        dataset.addAll([
          gravityX / 16384.0 * 9.8,
          gravityY / 16384.0 * 9.8,
          gravityZ / 16384.0 * 9.8,
        ]);
      }
      // debugPrint("dataset=$dataset");
      //period=20ms(frequency=50Hz)
      final data = MARGModel(currentTime + 20 * sampleIndex, dataset);
      // debugPrint(
      //     "i=$sampleIndex,X=$accelerationAxisX,Y=$accelerationAxisY,Z=$accelerationAxisZ");
      margDataset.add(data);
    }
    return margDataset;
  }

  Future<String> storeGsensorDataset(List<MARGModel> margDataset) async {
    String hintMesaage = "";
    bool isRecording = locator<MARGDatabaseService>().isRecordingAccelerometer;
    var label = locator<MARGDatabaseService>().selectedMotionLabel;
    if (isRecording) {
      for (var i = 0; i < margDataset.length; i++) {
        debugPrint("[$i]${margDataset[i].toPacket}");
        locator<MARGDatabaseService>().insert(label, margDataset[i]);
      }
      locator<MARGDatabaseService>().amountOfCollectedLabel++;
    }
    int amountOfCollectedLabel =
        locator<MARGDatabaseService>().amountOfCollectedLabel;
    hintMesaage = "[$label]";
    if (label == "grab") {
      amountOfCollectedLabel = (amountOfCollectedLabel / 2 + 0.5).ceil();
      locator<MARGDatabaseService>().selectedMotionLabel = "release";
    } else if (label == "release") {
      amountOfCollectedLabel = (amountOfCollectedLabel / 2 + 0.5).ceil();
      locator<MARGDatabaseService>().selectedMotionLabel = "grab";
    }
    hintMesaage += "[$amountOfCollectedLabel]";

    return hintMesaage;
  }

  Future<void> storeHeartSamples(List<int> samples) async {
    List<String> stringSamples =
        samples.map((sample) => sample.toString()).toList();
    await ExtStorageService()
        .writeCSVFileToTargetDirectoryWithHeading(
            "HRM", stringSamples, AppConstant.defaultUid,
            fileName:
                'HeartSamples_${TimeHelper.formattedDate(DateTime.now())}')
        .then((file) {
      if (file != null) {
        debugPrint("File generated:$file");
      }
    });
  }
}
