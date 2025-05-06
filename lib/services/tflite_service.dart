import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  late Interpreter _interpreter;

  TFLiteService._internal();

  factory TFLiteService() => _instance;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: options,
      );
      print('✅ YOLO model loaded');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  /// Runs model and returns bounding boxes: [x, y, w, h, conf, class] normalized
  Future<List<List<double>>> runModelOnImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Image could not be decoded.");
    final resized = img.copyResize(image, width: 640, height: 640);
    final input = _imageToFloat32List(resized);

    final inputShape = [1, 640, 640, 3];
    final output = List.generate(1, (_) => List.generate(6, (_) => List.filled(8400, 0.0)));

    _interpreter.run(input.reshape(inputShape), output);

    return List.generate(8400, (i) => List.generate(6, (j) => output[0][j][i]));
  }

  Float32List _imageToFloat32List(img.Image image) {
    final floatList = Float32List(640 * 640 * 3);
    int index = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        floatList[index++] = pixel.r / 255.0;
        floatList[index++] = pixel.g / 255.0;
        floatList[index++] = pixel.b / 255.0;
      }
    }

    return floatList;
  }
}
