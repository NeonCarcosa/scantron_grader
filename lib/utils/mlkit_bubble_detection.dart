import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Main ML Kit detection entry point
Future<Map<int, String>> detectBubblesWithMLKit(File imageFile, int maxQuestions) async {
  // Guard: Check image size before passing to ML Kit
  final rawBytes = await imageFile.readAsBytes();
  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) {
    debugPrint("❌ Could not decode image before detection.");
    return {};
  }

  if (decoded.width < 32 || decoded.height < 32) {
    debugPrint("❌ Image too small for ML Kit: ${decoded.width}x${decoded.height}");
    return {};
  }

  final inputImage = InputImage.fromFile(imageFile);

  final options = ObjectDetectorOptions(
    classifyObjects: false,
    multipleObjects: true,
    mode: DetectionMode.single,
  );

  final detector = ObjectDetector(options: options);

  final List<DetectedObject> objects;
  try {
    objects = await detector.processImage(inputImage);
  } catch (e) {
    debugPrint("❌ Detection error: $e");
    return {};
  }

  await detector.close();

  debugPrint("🔍 Detected ${objects.length} objects");

  // Step 1: Extract bounding boxes
  final List<Rect> boundingBoxes = objects.map((o) => o.boundingBox).toList();
  final List<List<Rect>> rows = [];

  // Step 2: Group boxes into rows based on vertical proximity
  const double rowThreshold = 25.0;

  for (final box in boundingBoxes) {
    bool added = false;
    for (final row in rows) {
      if ((row.first.center.dy - box.center.dy).abs() < rowThreshold) {
        row.add(box);
        added = true;
        break;
      }
    }
    if (!added) {
      rows.add([box]);
    }
  }

  debugPrint("📊 Grouped into ${rows.length} rows");

  // Step 3: Sort rows vertically and boxes within each row horizontally
  rows.sort((a, b) => a.first.center.dy.compareTo(b.first.center.dy));
  for (final row in rows) {
    row.sort((a, b) => a.center.dx.compareTo(b.center.dx));
  }

  // Step 4: Determine selected choice per row by largest area
  const choices = ['A', 'B', 'C', 'D', 'E'];
  final Map<int, String> results = {};

  for (int i = 0; i < rows.length && i < maxQuestions; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;

    row.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    final selectedIndex = 0;
    final selectedChoice = choices[min(selectedIndex, row.length - 1) % choices.length];

    results[i + 1] = selectedChoice;
  }

  debugPrint("✅ Parsed ${results.length} answers");
  return results;
}
