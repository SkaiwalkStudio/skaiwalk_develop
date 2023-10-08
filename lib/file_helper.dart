import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class FileHelper {
  /// 檢查路徑[path]是否存在資料夾，如果沒有就創建一個
  static Future<Directory> getDirectory(String path) async {
    final myDir = Directory(path);
    var isThere = await myDir.exists();
    if (isThere) {
      debugPrint("資料夾存在於路徑: $path");
      return myDir;
    } else {
      var newDir = await Directory(path).create(recursive: true);
      debugPrint("資料夾不存在，已創建於路徑: $path");
      return newDir;
    }
  }

  // delete file
  static Future<void> deleteFile(String path) async {
    var file = File(path);
    if (file.existsSync()) {
      await file.delete();
      debugPrint("已刪除檔案: $path");
    }
  }

  static Future<List<List<dynamic>>> loadCsvFile(File file) async {
    final lines = await file.readAsLines();
    List<List<dynamic>> csvTable =
        const CsvToListConverter().convert(lines.join('\r\n'));
    return csvTable;
  }
}
