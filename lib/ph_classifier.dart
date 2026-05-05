import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class PhClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  int _numClasses = 5; // ← auto-detected mula sa model

  static const int INPUT_SIZE = 200;

  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ph_model.tflite');

      // ── Auto-detect output classes mula sa model ──
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      _numClasses = outputShape.last;
      print('pH model output shape: $outputShape → $_numClasses classes');

      final labelsData = await rootBundle.loadString('assets/ph_labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      print('pH Classifier loaded. Labels: $_labels');
      print('pH label count: ${_labels.length}, model classes: $_numClasses');
    } catch (e) {
      print('Error loading pH model: $e');
    }
  }

  Future<Map<String, dynamic>> classify(String imagePath) async {
    if (_interpreter == null) {
      return {'label': 'Error', 'confidence': '0', 'phValue': '0', 'index': -1};
    }

    try {
      final imageFile = File(imagePath);
      final rawBytes = imageFile.readAsBytesSync();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        return {
          'label': 'Invalid Image',
          'confidence': '0',
          'phValue': '0',
          'index': -1,
        };
      }

      final resized = img.copyResize(
        decoded,
        width: INPUT_SIZE,
        height: INPUT_SIZE,
      );

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

      // ── Gamitin ang auto-detected _numClasses ──
      var output = List<double>.filled(
        _numClasses,
        0,
      ).reshape([1, _numClasses]);
      _interpreter!.run(input, output);

      final List<double> scores = List<double>.from(output[0]);

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
          : _labels.isNotEmpty
          ? _labels.last
          : 'Ph7';

      print('pH scores: $scores');
      print('pH maxIndex: $maxIndex');
      print('pH raw label: "$label"');

      return {
        'label': label,
        'confidence': (maxScore * 100).toStringAsFixed(1),
        'phValue': _getPhValue(label),
        'index': maxIndex,
      };
    } catch (e) {
      print('pH classify ERROR: $e');
      return {'label': 'Error', 'confidence': '0', 'phValue': '0', 'index': -1};
    }
  }

  String _getPhValue(String label) {
    switch (label.trim().toLowerCase()) {
      case 'ph3':
        return '3';
      case 'ph4':
        return '4';
      case 'ph5':
        return '5';
      case 'ph6':
        return '6';
      case 'ph7':
        return '7';
      default:
        print('WARNING: Unknown pH label "$label"');
        return '0';
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
