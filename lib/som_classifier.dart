import 'dart:io';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class Classifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  int _numClasses = 4;

  // ✅ Fixed: both models were trained on 224x224, not 200x200
  static const int INPUT_SIZE = 224;

  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenetv2_model.tflite',
      );

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      _numClasses = outputShape.last;
      print('SOM model output shape: $outputShape → $_numClasses classes');

      final labelsData = await rootBundle.loadString('assets/som_labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      print('SOM Classifier loaded. Labels: $_labels');
      print('SOM label count: ${_labels.length}, model classes: $_numClasses');
    } catch (e) {
      print('Error loading SOM model: $e');
    }
  }

  Future<Map<String, dynamic>> classify(String imagePath) async {
    if (_interpreter == null) {
      return {'label': 'Error', 'confidence': '0', 'index': -1};
    }

    try {
      final imageFile = File(imagePath);
      final rawBytes = imageFile.readAsBytesSync();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        return {'label': 'Invalid Image', 'confidence': '0', 'index': -1};
      }

      final resized = img.copyResize(
        decoded,
        width: INPUT_SIZE,
        height: INPUT_SIZE,
      );

      // ✅ Fixed: training used data / 255.0 → range [0, 1]
      // Old code wrongly used (pixel / 127.5) - 1.0 which is MobileNetV2's
      // built-in preprocess_input range, but your training script used /255.0
      var input = List.generate(
        1,
        (_) => List.generate(
          INPUT_SIZE,
          (y) => List.generate(INPUT_SIZE, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      var output = List<double>.filled(
        _numClasses,
        0,
      ).reshape([1, _numClasses]);
      _interpreter!.run(input, output);

      final List<double> rawScores = List<double>.from(output[0]);
      print('SOM raw output: $rawScores');

      // ✅ Softmax in case model outputs logits instead of probabilities
      final List<double> scores = _softmax(rawScores);
      print('SOM softmax scores: $scores');

      double maxScore = -1.0;
      int maxIndex = -1;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      final label = (maxIndex >= 0 && maxIndex < _labels.length)
          ? _labels[maxIndex]
          : 'Class $maxIndex';

      print(
        'SOM maxIndex: $maxIndex, label: "$label", confidence: ${(maxScore * 100).toStringAsFixed(1)}%',
      );

      return {
        'label': label,
        'confidence': (maxScore * 100).toStringAsFixed(1),
        'index': maxIndex,
      };
    } catch (e) {
      print('SOM classify ERROR: $e');
      return {'label': 'Error', 'confidence': '0', 'index': -1};
    }
  }

  // Softmax to normalize logits into probabilities
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(max);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void dispose() {
    _interpreter?.close();
  }
}
