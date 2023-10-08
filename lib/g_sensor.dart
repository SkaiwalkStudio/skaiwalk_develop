class ConfigGsensor {
  final int featureCount;
  final int sampleCount;
  final int bufferSizePerSample;
  const ConfigGsensor({
    this.featureCount = 3,
    this.sampleCount = 20,
    this.bufferSizePerSample = 6,
  });
}
