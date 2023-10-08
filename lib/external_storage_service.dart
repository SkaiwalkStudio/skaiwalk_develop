import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_helper.dart';

const String gsensorHeading = "timestamp,ax,ay,az";
const String imuHeading = "timestamp,ax,ay,az,gx,gy,gz";
const String heartRateResultHeading =
    "[0]heart_rate,[1]high_pressure,[2]low_pressure,[3]blood_oxygen,[4]off_hand_status,[5]debug_data,[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19]";

class ExtStorageService {
  /// 刪除位於路徑[path]的檔案
  Future<void> deleteFile(String path) async {
    File(path).delete();
  }

  /// 在App的資料夾底下創建一個包含項目名稱[itemName]與使用者編號[id]的路徑
  Future<Directory?> getTargetDir(String itemName, String id) async {
    return await getExternalStorageDirectory().then((directory) async {
      if (directory != null) {
        final path = "${directory.path}/$itemName/$id";
        return await FileHelper.getDirectory(path).then((dir) {
          return dir;
        });
      }
      return null;
    });
  }

  Future<Directory?> getDownloadsDir(String itemName, String id) async {
    return await getDownloadsDirectory().then((directory) async {
      if (directory != null) {
        final path = "${directory.path}/Skaiwalk/$itemName/$id";
        return await FileHelper.getDirectory(path).then((dir) {
          return dir;
        });
      }
      return null;
    });
  }

  /// 從資料夾中讀取所有檔案
  Future<List<File>?> getFilesFromTargetDir(String itemName, String id) async {
    return await getTargetDir(itemName, id).then((dir) {
      if (dir != null) {
        return dir.listSync().map((f) {
          return File(f.path);
        }).toList();
      }
      return null;
    });
  }


  /// 寫入資料集[content]至新建立的檔案[fileName]中
  Future<File?> writeCSVFileToTargetDirectoryWithHeading(
      String itemName, List<String> content, String uid,
      {String? fileName,
      String? heading,
      Function? success,
      Function? fail}) async {
    if (content.isEmpty) {
      if (fail != null) fail();
      return null;
    }

    String body = content.join('\n');
    String wholeContent = "";
    // 將字串編碼為 UTF-8形式的位元組

    return await getTargetDir(itemName, uid).then((dir) async {
      if (dir != null) {
        final file = File("${dir.path}/$fileName.csv");
        return await file.exists().then((exists) async {
          if (heading != null && exists == false) {
            wholeContent = "$heading\n$body\n";
          } else {
            wholeContent = "$body\n";
          }
          List<int> bytes = utf8.encode(wholeContent);
          return await file.writeAsBytes(bytes, mode: FileMode.append);
        });
      }
      return null;
    });
  }
}
