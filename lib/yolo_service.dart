import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class YoloService {
  late YOLO yolo;
  Future<String> _getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/best_float32.tflite';
    final file = File(path);

    // Copy only if not exists
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/model/best_float32.tflite');

      await file.writeAsBytes(data.buffer.asUint8List());
    }

    print("DEVICE DIRECTORY: ${directory.path}");
    print("FINAL MODEL PATH: $path");
    return path;
  }

  Future<void> initializeModel() async {
    yolo = YOLO(modelPath: await _getModelPath(), task: YOLOTask.detect);
    yolo.loadModel();
  }

  Future<List<Map<String, dynamic>>> detectObjects(Uint8List imageBytes) async {
    try {
      final results = await yolo.predict(imageBytes);
      return List<Map<String, dynamic>>.from(results['boxes'] ?? []);
    } catch (e) {
      print('Detection error: $e');
      return [];
    }
  }

  void boundingBoxes(List<Map<String, dynamic>> results) {
    print('count: ${results.length}');
    for (final box in results) {
      print('Object: ${box['class']}');
      print('Confidence: ${box['confidence']}');
      print(
        'Box: x=${box['x1']}, y=${box['y1']}, w=${box['x2'] - box['x1']}, h=${box['y2'] - box['y1']}',
      );
    }
  }
}
