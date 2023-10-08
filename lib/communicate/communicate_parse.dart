import 'communicate_parse_log.dart';
import 'communicate_parse_notify.dart';
import 'communicate_protocol.dart';


// use for parsing data from phone
class CommunicateParse {
  List<int> getFirstValue(List<int> pData) {
    List<int> bufferAfterFifthIndex = pData.skip(5).toList();
    return bufferAfterFifthIndex;
  }

  bool resolveL2Frame(List<int> pData, {CommunicateDevice? from}) {
    if (pData.isEmpty) {
      return false;
    }
    // get and decode first five buffer
    var firstFive = pData.take(l2FirstValuePosition).toList();
    var l2Header = decodeL2Header(firstFive);
    // debugPrint("l2Header = $l2Header");
    if (l2Header == null) {
      return false;
    }
    // debugPrint("l2Header commandId = ${l2Header.commandId}");
    switch (l2Header.commandId) {
      case WristbandCommunicateCommand.notifyCommandId:
        {
          NotifyResolver resolver = NotifyResolver();
          resolver.resolve(l2Header, getFirstValue(pData));
        }
        break;
      case WristbandCommunicateCommand.bluetoothLogCommandId:
        {
          BluetoothLogResolver resolver = BluetoothLogResolver();
          resolver.resolve(l2Header, getFirstValue(pData));
        }
        break;
      default:
        break;
    }
    return true;
  }
}
