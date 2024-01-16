import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skaiwalk_develop/helper/file_helper.dart';
import 'package:skaiwalk_develop/main.dart';
import 'package:skaiwalk_develop/constant/text_constant.dart';
import '../constant/app_constant.dart';
import 'app_dialog.dart';
import 'common_menu_card.dart';
import '../service/external_storage_service.dart';
import '../locator.dart';
import '../model/log_model.dart';
import 'log_view.dart';
import '../skaios/skai_os_interface.dart';
import '../skaios/skaios_provider.dart';
import 'watch_connection_view.dart';

bool bluetoothLog = true;
bool voiceRecognitionService = false;
bool mediaControllService = false;
bool developmentControl = false;
bool developmentNotify = true;
bool developmentSettings = false;
bool gestureDemo = false;
bool slideControlPanel = false;

class DevelopScreen extends StatelessWidget {
  const DevelopScreen({super.key});

  Widget buildWatchConnectionCardMobile() {
    return Selector<SkaiOSProvider, bool>(
      selector: (_, provider) => provider.isWatchConnected,
      builder: (context, isConnected, child) => MenuCard(
        title: TextConstants.skaiWatch,
        child: WatchConnectionView(isConnected: isConnected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(children: [
      buildWatchConnectionCardMobile(),

      ////// BLE LOG 介面 //////
      Visibility(
        visible: bluetoothLog,
        child: MenuCard(
            title: "BLE LOG",
            child: Consumer<LogModel>(
                builder: (context, bleLog, child) =>
                    LogTextView(logs: bleLog.logs))),
      ),

      Visibility(
        visible: developmentNotify,
        child: MenuCard(
            title: "Gsensor",
            child: Selector<SkaiOSProvider, String>(
              selector: (_, notifier) => notifier.selectedMotionLabel,
              builder: (_, label, __) => Column(children: [
                Selector<SkaiOSProvider, bool>(
                  selector: (_, notifier) => notifier.isRecordingAccelerometer,
                  builder: (_, isRecording, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("蒐集加速度",
                          style: Theme.of(context).textTheme.bodyLarge),
                      DropdownButton<String>(
                        items: isRecording
                            ? null
                            : AppConstant.gestureTable
                                .map<DropdownMenuItem<String>>(
                                    (String value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ))
                                .toList(),
                        value: label,
                        onChanged: isRecording
                            ? null
                            : (label) {
                                if (label != null) {
                                  locator<SkaiOSProvider>()
                                      .selectedMotionLabel = label;
                                  notifySkaiOSService(
                                      ServiceType.gestureDataCollction,
                                      GestureDataCollctionServiceType
                                          .selectLabel.index,
                                      param: label);
                                }
                              },
                        icon: const Icon(Icons.flutter_dash),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          if (isRecording) {
                            locator<SkaiOSProvider>()
                                .showDialogAfterFinishedMotionRecord(
                                    context, label);
                            locator<SkaiOSProvider>().isRecordingAccelerometer =
                                false;
                            notifySkaiOSService(
                                ServiceType.gestureDataCollction,
                                GestureDataCollctionServiceType.recording.index,
                                param: false);
                          } else {
                            locator<SkaiOSProvider>().isRecordingAccelerometer =
                                true;
                            notifySkaiOSService(
                                ServiceType.gestureDataCollction,
                                GestureDataCollctionServiceType.recording.index,
                                param: true);
                          }
                        },
                        child: isRecording
                            ? Text('停止紀錄',
                                style: Theme.of(context).textTheme.bodyLarge!)
                            : Text('開始記錄',
                                style: Theme.of(context).textTheme.bodyLarge!),
                      )
                    ],
                  ),
                ),
                FutureBuilder(
                  future: ExtStorageService().getFilesFromTargetDir(label, uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          Text("已紀錄的手勢",
                              style: Theme.of(context).textTheme.bodyLarge),
                          ...snapshot.data!
                              .map<Widget>((file) => TextButton(
                                    onPressed: () {
                                      // use dialog to show csv file content
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AppDialogs.loadingDialog(
                                                child: FutureBuilder<
                                                    List<List<dynamic>>>(
                                                  future:
                                                      FileHelper.loadCsvFile(
                                                          file),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      final data =
                                                          snapshot.data!;
                                                      // plot column 1, 2, 3 as Y-axis and 0 as X-axis
                                                      return ListView.builder(
                                                          itemCount:
                                                              data.length,
                                                          itemBuilder:
                                                              (_, index) {
                                                            return Card(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .all(3),
                                                              color: index == 0
                                                                  ? Colors
                                                                      .grey[200]
                                                                  : Colors
                                                                      .white,
                                                              child: ListTile(
                                                                leading: Text(
                                                                    data[index]
                                                                            [0]
                                                                        .toString()),
                                                                // (1, 2, 3)
                                                                title: Text(data[
                                                                        index]
                                                                    .getRange(
                                                                        1, 4)
                                                                    .toString()),
                                                              ),
                                                            );
                                                          });
                                                    } else {
                                                      return const SizedBox();
                                                    }
                                                  },
                                                ),
                                              ));
                                    },
                                    child: Text(file.path.split('/').last,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!),
                                  ))
                              .toList()
                        ],
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                )
              ]),
            )),
      ),
    ]));
  }
}
