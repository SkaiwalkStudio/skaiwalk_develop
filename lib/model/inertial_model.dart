import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constant/app_constant.dart';
import '../service/external_storage_service.dart';
import '../main.dart';

/// 存放六軸數據的物件
class MARGModel {
  int timestamp; //id
  List<double> dataset; // []
  MARGModel(this.timestamp, this.dataset) {
    ax = dataset[0];
    ay = dataset[1];
    az = dataset[2];
    if (dataset.length == 4) {
      ppg = dataset[3];
    } else if (dataset.length == 6) {
      gx = dataset[3];
      gy = dataset[4];
      gz = dataset[5];
    }
  }
  late double ax;
  late double ay;
  late double az;
  late double gx;
  late double gy;
  late double gz;
  late double ppg;

  factory MARGModel.fromMap(Map<String, dynamic> map) {
    int datetime = map['id'];
    String dataString = map['data'];
    List<double> dataset =
        dataString.split(',').map((e) => double.parse(e)).toList();
    return MARGModel(datetime, dataset);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'id': timestamp,
      'data': dataset.map((e) => e.toString()).toList().join(','),
    };
    return map;
  }

  String get toPacket => (dataset.length > 3)
      ? (dataset.length == 4)
          ? "$timestamp,$ax,$ay,$az,$ppg"
          : "$timestamp,$ax,$ay,$az,$gx,$gy,$gz"
      : "$timestamp,$ax,$ay,$az";

  Map<String, dynamic> toAccelerationMap() {
    Map<String, dynamic> map = {
      "ax": ax,
      "ay": ay,
      "az": az,
    };
    return map;
  }

  Map<String, dynamic> toGyroscopeMap() {
    Map<String, dynamic> map = {
      "gx": gx,
      "gy": gy,
      "gz": gz,
    };
    return map;
  }

  @override
  String toString() {
    return "id(datetime): $timestamp || dataset: $dataset";
  }
}

class MARGDatabaseService {
  MARGDatabaseService() {
    initializeDatabase();
  }
  Future<void> initializeDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbName = "motion_record";
    String dbPath = "${documentsDirectory.path}/$dbName.db";
    await open(dbPath);
  }

  String selectedMotionLabel = AppConstant.gestureTable[0];
  bool isRecordingAccelerometer = false;
  set setIsRecordingAccelerometer(bool value) {
    isRecordingAccelerometer = value;
    if (value) {
      amountOfCollectedLabel = 0;
    }
  }

  int amountOfCollectedLabel = 0;

  Database? db;
  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      for (var element in AppConstant.gestureTable) {
        await db.execute('''
create table $element ( 
  id INTEGER, 
  data TEXT)
''');
      }
    });
  }

  Future<MARGModel?> insert(String tableMARG, MARGModel marg) async {
    if (db == null) {
      return null;
    }
    final map = marg.toMap();
    // debugPrint("insert $map");
    await db!.insert(tableMARG, map);
    return marg;
  }

  Future<List<MARGModel>> getMARG(String tableMARG) async {
    List<Map<String, dynamic>> maps = await db!.query(tableMARG);
    return List.generate(maps.length, (i) {
      return MARGModel.fromMap(maps[i]);
    });
  }

  Future<int> delete(String tableMARG) async {
    return await db!.delete(tableMARG);
  }

  Future close() async => db!.close();

  Future saveDataset(String label, List<MARGModel> dataset) async {
    List<String> lines = List.generate(dataset.length, (index) {
      return dataset[index].toPacket;
    });
    String? heading;
    if (AppConstant.configGsensor.featureCount == 4) {
      heading = "timestamp,ax,ay,az,ppg";
    } else if (AppConstant.configGsensor.featureCount == 6) {
      heading = "timestamp,ax,ay,az,gx,gy,gz";
    } else {
      heading = "timestamp,ax,ay,az";
    }
    await ExtStorageService()
        .writeCSVFileToTargetDirectoryWithHeading(label, lines, uid,
            fileName: '${label}_${DateTime.now()}', heading: heading)
        .then((file) {
      if (file != null) {
        debugPrint("File generated:$file");
      }
    });
  }
}
