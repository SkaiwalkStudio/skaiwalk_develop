import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TimeHelper {
  static Timer oneTimer(
      {required int seconds, required Function timerOutCallback}) {
    var duration = Duration(seconds: seconds);
    final timer = Timer.periodic(
      duration,
      (Timer timer) {
        timer.cancel();
        timerOutCallback.call();
        debugPrint("[TimeHelper.oneTimer]cancel timer after $seconds");
      },
    );
    return timer;
  }

  // period timer
  static Timer periodTimer(
      {required int seconds, required Function timerOutCallback}) {
    var duration = Duration(seconds: seconds);
    final timer = Timer.periodic(
      duration,
      (Timer timer) {
        timerOutCallback.call();
        debugPrint("[TimeHelper.periodTimer]timer out after $seconds");
      },
    );
    return timer;
  }

  static String formattedDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
}
