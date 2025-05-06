import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AnswerKeyStorage {
  // Get the directory where answer keys are stored
  static Future<String> _getDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/answer_keys';
    await Directory(path).create(recursive: true);
    return path;
  }

  // Save as JSON file
  static Future<void> saveKey(String name, Map<int, String> answers) async {
    final dir = await _getDirectory();
    final file = File('$dir/$name.json');
    final data = {
      "testName": name,
      "answers": answers.map((k, v) => MapEntry(k.toString(), v))
    };
    await file.writeAsString(jsonEncode(data));
  }

  // Load from JSON file
  static Future<Map<int, String>?> loadKey(String name) async {
    final dir = await _getDirectory();
    final file = File('$dir/$name.json');
    if (!file.existsSync()) return null;

    final raw = jsonDecode(await file.readAsString());
    return (raw["answers"] as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), v.toString()));
  }

  // List all saved keys
  static Future<List<String>> listKeys() async {
    final dir = await _getDirectory();
    final files = Directory(dir).listSync().whereType<File>();
    return files
        .map((f) => f.path.split(Platform.pathSeparator).last.replaceAll('.json', ''))
        .toList();
  }

  // Delete an answer key
  static Future<void> deleteKey(String name) async {
    final dir = await _getDirectory();
    final file = File('$dir/$name.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Export to CSV file
  static Future<void> exportToCSV(String name, Map<int, String> answers) async {
    final dir = await _getDirectory();
    final file = File('$dir/$name.csv');
    final csvData = answers.entries.map((e) => '${e.key},${e.value}').join('\n');
    await file.writeAsString('Question,Answer\n$csvData');
  }

  // Import from CSV file
  static Future<Map<int, String>> importFromCSV(File file) async {
    final content = await file.readAsLines();
    final Map<int, String> answers = {};
    for (int i = 1; i < content.length; i++) {
      final parts = content[i].split(',');
      if (parts.length == 2) {
        final q = int.tryParse(parts[0].trim());
        final a = parts[1].trim().toUpperCase();
        if (q != null && ['A', 'B', 'C', 'D', 'E'].contains(a)) {
          answers[q] = a;
        }
      }
    }
    return answers;
  }
}

