// scantron_alignment.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../services/tflite_service.dart';

/// Aligns and crops scantron using actual YOLOv8 model output
Future<File> alignAndCropScantronImage(File imageFile) async {
  final rawBytes = await imageFile.readAsBytes();
  final original = img.decodeImage(rawBytes);
  if (original == null) throw Exception("❌ Could not decode image.");

  final width = original.width;
  final height = original.height;

  print("📷 Image loaded: $width x $height");

  final detections = await TFLiteService().runModelOnImage(imageFile);

  // Filter predictions by confidence > 0.5
  final valid = detections
      .where((box) => box[4] > 0.5)
      .toList()
      ..sort((a, b) => b[4].compareTo(a[4])); // Descending by confidence

  if (valid.isEmpty) throw Exception("❌ No valid YOLO detections found.");

  final best = valid.first;
  final cx = best[0];
  final cy = best[1];
  final w = best[2];
  final h = best[3];

  // Convert normalized center x/y and w/h to pixel values
  int cropLeft = ((cx - w / 2) * width).round();
  int cropTop = ((cy - h / 2) * height).round();
  int cropWidth = (w * width).round();
  int cropHeight = (h * height).round();

  // Enforce boundaries
  cropLeft = cropLeft.clamp(0, width - 1);
  cropTop = cropTop.clamp(0, height - 1);
  cropWidth = cropWidth.clamp(32, width - cropLeft);
  cropHeight = cropHeight.clamp(32, height - cropTop);

  final cropped = img.copyCrop(
    original,
    x: cropLeft,
    y: cropTop,
    width: cropWidth,
    height: cropHeight,
  );

  print("📐 Crop: left=$cropLeft, top=$cropTop, width=$cropWidth, height=$cropHeight");

  // Save to temp
  final tempDir = await getTemporaryDirectory();
  final outPath = '${tempDir.path}/cropped_${const Uuid().v4()}.jpg';
  final outFile = File(outPath)..writeAsBytesSync(img.encodeJpg(cropped));

  print("✅ Cropped saved to: $outPath");
  return outFile;
}

