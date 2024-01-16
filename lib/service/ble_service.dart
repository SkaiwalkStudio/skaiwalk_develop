abstract class BleService {
  bool get connected => false;
  set connected(bool val) {}

  Future<void> startScanning();
  Future<void> stopScanning();
  Future<void> connect(dynamic device);
  Future<void> disconnect();
  Future<void> bwpsTxNotify(List<int> bytes);
}
