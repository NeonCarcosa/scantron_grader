import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Main ML Kit detection entry point
Future<Map<int, String>> detectBubblesWithMLKit(File imageFile, int maxQuestions) async {
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
    debugPrint("Detection error: $e");
    return {};
  }

  await detector.close();

  debugPrint("🔍 Detected ${objects.length} objects");

  final List<Rect> boundingBoxes = objects.map((o) => o.boundingBox).toList();
  const double rowThreshold = 25.0;
  final List<List<Rect>> rows = [];

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

  rows.sort((a, b) => a.first.center.dy.compareTo(b.first.center.dy));
  for (final row in rows) {
    row.sort((a, b) => a.center.dx.compareTo(b.center.dx));
  }

  const choices = ['A', 'B', 'C', 'D', 'E'];
  final results = <int, String>{};

  for (int i = 0; i < rows.length && i < maxQuestions; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;

    // 🔍 Step 2: Size Filtering
    final areas = row.map((r) => r.width * r.height).toList();
    final median = areas..sort();
    final medianArea = median[median.length ~/ 2];
    final minArea = medianArea * 0.8;
    final maxArea = medianArea * 1.2;

    final filtered = row.where((r) {
      final area = r.width * r.height;
      return area >= minArea && area <= maxArea;
    }).toList();

    if (filtered.isEmpty) {
      debugPrint("⚠️ Row ${i + 1} had no valid bubbles after size filter.");
      continue;
    }

    // Still use largest valid as "filled"
    filtered.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    final selectedIndex = min(filtered.length - 1, 0);
    final selectedChoice = choices[selectedIndex % choices.length];

    results[i + 1] = selectedChoice;
  }

  debugPrint("✅ Parsed ${results.length} answers");
  return results;
}
