import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class PhClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];

  static const int INPUT_SIZE = 200;
  static const int NUM_CLASSES = 5; // Ph3, Ph4, Ph5, Ph6, Ph7

  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ph_model.tflite');
      final labelsData = await rootBundle.loadString('assets/ph_labels.txt');
      _labels = labelsData.split('\n').where((l) => l.isNotEmpty).toList();
      print('pH Classifier loaded. Labels: $_labels');
    } catch (e) {
      print('Error loading pH model: $e');
    }
  }

  Future<Map<String, dynamic>> classify(String imagePath) async {
    if (_interpreter == null) {
      return {'label': 'Error', 'confidence': '0', 'phValue': '7', 'index': -1};
    }

    final imageFile = File(imagePath);
    final rawBytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return {
        'label': 'Invalid Image',
        'confidence': '0',
        'phValue': '7',
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

    var output = List<double>.filled(NUM_CLASSES, 0).reshape([1, NUM_CLASSES]);
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

    final label = _labels.length > maxIndex ? _labels[maxIndex] : 'Ph$maxIndex';

    return {
      'label': label,
      'confidence': (maxScore * 100).toStringAsFixed(1),
      'phValue': _getPhValue(label),
      'index': maxIndex,
    };
  }

  /// Exact pH numeric value per class
  String _getPhValue(String label) {
    switch (label.trim()) {
      case 'Ph3':
        return '3';
      case 'Ph4':
        return '4';
      case 'Ph5':
        return '5';
      case 'Ph6':
        return '6';
      case 'Ph7':
        return '7';
      default:
        return '7';
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
