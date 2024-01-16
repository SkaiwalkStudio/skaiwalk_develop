import 'package:flutter/foundation.dart';

const String debugTagWatch = 'Watch';
String getWatchLog(dynamic fristKey, String? message) {
  String log = "[$debugTagWatch][$fristKey]";
  if (message != null) {
    log += message;
  }
  return log;
}

class LogModel with ChangeNotifier {
  final int maxLength;
  LogModel({this.maxLength = 100});

  List<String> _logs = [];

  List<String> get logs => _logs;

  set logs(List<String> newLogs) {
    _logs = newLogs;
    notifyListeners();
  }

  void addLog(String log) {
    String timestamp = DateTime.now().toString();
    _logs.add("$timestamp : $log");
    if (_logs.length > maxLength) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  String bleDebugPrint(LogMessagePacket packet) {
    String? message = packet.message;
    dynamic fristKey = packet.firstKey;
    var log = getWatchLog(fristKey, message);
    debugPrint(log);
    addLog(log);
    notifyListeners();
    return log;
  }
}

class LogMessagePacket {
  final String? message;
  final String firstKey;
  LogMessagePacket({required this.firstKey, this.message});

  Map<String, dynamic> toMap() {
    return {
      'firstKey': firstKey,
      'message': message,
    };
  }

  factory LogMessagePacket.fromMap(Map<String, dynamic> map) {
    return LogMessagePacket(
      message: map['message'],
      firstKey: map['firstKey'],
    );
  }
}
