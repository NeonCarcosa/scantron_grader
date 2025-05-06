import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scantron_grader/utils/answer_key_storage.dart';
import 'package:file_picker/file_picker.dart';

class AnswerKeyScreen extends StatefulWidget {
  @override
  _AnswerKeyScreenState createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  late TextEditingController _keyController;
  String _keyName = '';
  int _questionCount = 50;
  Map<int, String> _answers = {};
  List<String> _availableKeys = [];

  final List<String> choices = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _loadAvailableKeys();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableKeys() async {
    final keys = await AnswerKeyStorage.listKeys();
    final validKeys = <String>[];

    for (final key in keys) {
      final loaded = await AnswerKeyStorage.loadKey(key);
      if (loaded != null && loaded.isNotEmpty) {
        validKeys.add(key);
      }
    }

    setState(() {
      _availableKeys = validKeys;
    });
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    ));
  }

  Future<void> _saveKey() async {
    _keyName = _keyController.text.trim();
    if (_keyName.isEmpty) {
      _showMessage("Please enter a name for the answer key.");
      return;
    }

    if (_answers.isEmpty) {
      _showMessage("Please provide at least 1 answer.");
      return;
    }

    await AnswerKeyStorage.saveKey(_keyName, _answers);
    _showMessage("Answer key '$_keyName' saved successfully!", isSuccess: true);
    _keyController.clear();
    _answers.clear();
    
  }

  Future<void> _importFromCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final importedAnswers = await AnswerKeyStorage.importFromCSV(file);
      final fileName = file.path.split(Platform.pathSeparator).last.replaceAll('.csv', '');

      setState(() {
        _keyName = fileName;
        _keyController.text = fileName;
        _answers = importedAnswers;
        _questionCount = importedAnswers.length > 50 ? 100 : 50;
      });

      _showMessage("Imported '$fileName'. Tap Save to finalize.", isSuccess: true);
    }
  }

  Future<void> _loadKey(String name) async {
    final loaded = await AnswerKeyStorage.loadKey(name);
    if (loaded != null) {
      setState(() {
        _keyName = name;
        _keyController.text = name;
        _answers = loaded;
        _questionCount = loaded.length > 50 ? 100 : 50;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Answer Key")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_availableKeys.isNotEmpty)
              DropdownButton<String>(
                value: _keyName.isNotEmpty && _availableKeys.contains(_keyName) ? _keyName : null,
                hint: const Text("Select Existing Key"),
                isExpanded: true,
                items: _availableKeys.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _loadKey(value);
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(labelText: "Answer Key Name"),
              onChanged: (value) => setState(() => _keyName = value),
            ),
            const SizedBox(height: 12),
            DropdownButton<int>(
              value: _questionCount,
              isExpanded: true,
              items: [50, 100].map((count) {
                return DropdownMenuItem<int>(
                  value: count,
                  child: Text("$count Questions"),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _questionCount = value;
                    _answers = {};
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ...List.generate(_questionCount, (index) {
              int qNum = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text("Q$qNum", style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _answers[qNum],
                      hint: const Text("Select"),
                      items: choices.map((choice) {
                        return DropdownMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) _answers[qNum] = value;
                        });
                      },
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Import CSV"),
                  onPressed: _importFromCSV,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Export Key"),
                  onPressed: () async {
                    if (_keyName.isNotEmpty) {
                      await AnswerKeyStorage.exportToCSV(_keyName, _answers);
                      _showMessage("Exported $_keyName to Downloads.", isSuccess: true);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete Key"),
                  onPressed: () async {
                    if (_keyName.isNotEmpty) {
                      await AnswerKeyStorage.deleteKey(_keyName);
                      _showMessage("Deleted $_keyName.", isSuccess: true);
                      await _loadAvailableKeys();
                      setState(() {
                        _keyName = _availableKeys.isNotEmpty ? _availableKeys.first : '';
                        _keyController.text = _keyName;
                        _answers.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Answer Key"),
                onPressed: _saveKey,
              ),
            )
          ],
        ),
      ),
    );
  }
}
