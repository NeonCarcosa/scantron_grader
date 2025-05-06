import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 4000,
      imageQuality: 100,
    );
    return picked != null ? File(picked.path) : null;
  }
}

