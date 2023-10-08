import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'inertial_model.dart';

class AiModel {
  String title;
  Interpreter interpreter;

  AiModel({required this.title, required this.interpreter});
}

// the object used to store result of motion recognition
class Result {
  final int itemIndex;
  double score;
  Result({required this.itemIndex, this.score = 0.0});
  String get label => GestureType.values[itemIndex].name;
}

enum GestureType {
  unknown,
  wave,
  snap,
  // grab,
  // release,
}

const int timeSteps = 20;
const int steps = 20;
// const int outputSize = 4;

class GestureDetectService {
  GestureDetectService() {
    initModels();
  }

  final _modelFileName = 'gesture_detector';

  // TensorFlow Lite Interpreter object
  late AiModel myAiModel;

  Interpreter get interpreter => myAiModel.interpreter;

  // input data buffer
  final List<List<double>> _buffer = [];
  List<List<List<double>>> inputData = [
    [[]]
  ]..length = 1;

  // 輸出標籤陣列暫存器
  List<double> _outputVector = [];
  List<double> get outputVector => _outputVector;

  int continueCount = 0;
  int prevLabel = 0;

  Future<int> decideLabel(int outputIndex) async {
    if (outputIndex == prevLabel) {
      if (continueCount < 2) {
        continueCount++;
      }
    } else {
      if (continueCount > 0) {
        continueCount--;
      }
    }
    if (continueCount == 0) {
      prevLabel = outputIndex;
    }
    return prevLabel;
  }

  void initModels() {
    _loadModel('assets/model/$_modelFileName.tflite').then((interpreter) {
      if (interpreter != null) {
        // Load model when the classifier is initialized.
        myAiModel = AiModel(
          title: _modelFileName,
          interpreter: interpreter,
        );
      }
    });
  }

  Future<Interpreter?> _loadModel(String assetName) async {
    debugPrint('Interpreter($assetName) is loading...');
    // Creating the interpreter using Interpreter.fromAsset
    var interpreter = await Interpreter.fromAsset(assetName);
    debugPrint('Interpreter($assetName) loaded successfully');
    return interpreter;
  }

  /// 填充樣本
  Future<bool> _isTimeWindowFilled(List<double> sampleData) async {
    if (_buffer.length == timeSteps) {
      ///generate a new List Object instead of getting value form [_buffer].
      inputData[0] = List.from(_buffer);
      _buffer.removeRange(0, steps);
      _buffer.add(sampleData);
      return true;
    } else {
      _buffer.add(sampleData);
      // print(_buffer.length);
      // print(inputData[0].length);
      return false;
    }
  }

  // Input vector shape: [1,TIME_STEPS, 4] -->
  // --> Output vector shape: [1,4]
  Future<List<double>> classify(
    Interpreter interpreter,
    List<List<List<double>>> input,
  ) async {
    // debugPrint(
    //     'start classification with input tensor: ${input[0].length} sets');
    int outputSize = GestureType.values.length;
    final output =
        List<double>.filled(outputSize, 0.0).reshape([1, outputSize]);
    interpreter.run(input, output);
    // debugPrint('classification finished, return output vector: $output');
    List<double> outputArray = [];
    for (var i = 0; i < outputSize; i++) {
      outputArray.add(output[0][i]);
    }
    return outputArray;
  }

  /// put the [dataset] to the motion recognition model
  Future<Result?> input(
    List<double> dataset,
  ) async {
    return await _isTimeWindowFilled(dataset).then((isFilled) async {
      if (isFilled) {
        // if input samples are prepared, it will start classification
        final vector = await classify(
          myAiModel.interpreter,
          inputData,
        );
        _outputVector = vector;
        final maxValue = outputVector.reduce(max);
        int index = outputVector.indexOf(maxValue);
        debugPrint(' >>> gesture index is: $index <<<');
        return Result(itemIndex: index, score: outputVector[index]);
        // if (index >= 0) {
        //   debugPrint('MAX label is: $index');
        //   return await decideLabel(index).then((label) {
        //     return Result(itemIndex: label, score: outputVector[label]);
        //   });
        // }
      }
      return null;
    });
  }

  Future<void> classifyGesture(List<MARGModel> dataset) async {
    final inputData =
        dataset.map((acc) => acc.dataset.map((e) => e).toList()).toList();
    final result = await classify(interpreter, [inputData]);
    // get max score index
    int maxScoreIndex = 0;
    double maxScore = 0;
    for (var i = 0; i < result.length; i++) {
      if (result[i] > maxScore) {
        maxScore = result[i];
        maxScoreIndex = i;
      }
    }
    final GestureType gestureType = GestureType.values[maxScoreIndex];
    debugPrint(
        'result: $result, classifyGesture[$maxScoreIndex]: $gestureType');
  }
}
