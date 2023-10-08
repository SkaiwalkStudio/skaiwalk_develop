import 'communicate_protocol.dart';

class CommunicateModel {
  final WristbandCommunicateCommand commandId;
  final List<int> pData;
  CommunicateModel({required this.commandId, required this.pData});

  factory CommunicateModel.fromMap(dynamic map) {
    int id = map['id'];
    List<int> pData = List<int>.from(map['pData']);
    return CommunicateModel(
      commandId: WristbandCommunicateCommand.fromInt(id),
      pData: pData,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    DateTime now = DateTime.now();
    int timestamp = now.millisecondsSinceEpoch;
    map['id'] = commandId.index;
    map['timestamp'] = timestamp;
    map['pData'] = pData;
    return map;
  }
}
