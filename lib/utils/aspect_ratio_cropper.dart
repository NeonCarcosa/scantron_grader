import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Crop to 1:2.59 aspect ratio (height/width)
Future<File> cropToScantronAspectRatio(File imageFile) async {
  final original = img.decodeImage(await imageFile.readAsBytes())!;
  const targetAspect = 2.59;

  int width = original.width;
  int height = original.height;
  late img.Image cropped;

  if (height / width > targetAspect) {
    // Too tall, crop top/bottom
    int newHeight = (width * targetAspect).round();
    int top = ((height - newHeight) / 2).round();
    cropped = img.copyCrop(
      original,
      x: 0,
      y: top,
      width: width,
      height: newHeight,
    );
  } else {
    // Too wide, crop sides
    int newWidth = (height / targetAspect).round();
    int left = ((width - newWidth) / 2).round();
    cropped = img.copyCrop(
      original,
      x: left,
      y: 0,
      width: newWidth,
      height: height,
    );
  }

  final tempDir = await getTemporaryDirectory();
  final outPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final outputFile = File(outPath)..writeAsBytesSync(img.encodeJpg(cropped));

  return outputFile;
}
