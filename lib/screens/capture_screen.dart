import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../utils/preprocessing.dart';
import '../utils/mlkit_bubble_detection.dart';
import '../utils/scantron_alignment.dart';
import '../utils/answer_key_storage.dart';
import '../utils/scan_history_storage.dart';
import '../models/scan_history_entry.dart';
import '../utils/aspect_ratio_cropper.dart'; // ✅ New import
import '../services/tflite_service.dart';


class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _imageFileFront;
  File? _imageFileBack;
  Map<int, String> _mockAnswers = {};
  int _correct = 0;
  double _scorePercent = 0;

  String _scantronType = 'One-sided (50 questions)';
  String? _selectedKey;
  List<String> _availableKeys = [];
  Map<int, String>? _currentAnswerKey;

  int get _maxQuestions => _scantronType.contains('Two') ? 100 : 50;

  @override
  void initState() {
    super.initState();
    _loadAvailableKeys();
    TFLiteService().loadModel(); // Load YOLO model
  }

  Future<void> _loadAvailableKeys() async {
    final keys = await AnswerKeyStorage.listKeys();
    final validKeys = <String>[];

    for (final key in keys) {
      final data = await AnswerKeyStorage.loadKey(key);
      if (data != null && data.isNotEmpty) {
        validKeys.add(key);
      }
    }

    setState(() {
      _availableKeys = validKeys;
      _selectedKey = validKeys.contains(_selectedKey)
          ? _selectedKey
          : (validKeys.isNotEmpty ? validKeys.first : null);
    });

    if (_selectedKey != null) {
      _currentAnswerKey = await AnswerKeyStorage.loadKey(_selectedKey!);
    } else {
      _currentAnswerKey = null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_currentAnswerKey == null) {
      _showMissingKeyAlert();
      return;
    }

    final pickedFront = await ImageService.pickImage(source);
    if (pickedFront == null) return;

    final croppedFront = await cropToScantronAspectRatio(pickedFront); // ✅ Aspect crop
    final alignedFront = await alignAndCropScantronImage(croppedFront);  // ✅ ML alignment
    setState(() => _imageFileFront = alignedFront);

    final detectedFront = await detectBubblesWithMLKit(alignedFront, _maxQuestions);
    Map<int, String> detectedAll = Map.from(detectedFront);

    File? alignedBack;

    if (_maxQuestions > 50) {
      final pickedBack = await ImageService.pickImage(source);
      if (pickedBack == null) return;

      final croppedBack = await cropToScantronAspectRatio(pickedBack); // ✅ Aspect crop
      alignedBack = await alignAndCropScantronImage(croppedBack);      // ✅ ML alignment
      setState(() => _imageFileBack = alignedBack);

      final detectedBack = await detectBubblesWithMLKit(alignedBack, _maxQuestions);
      detectedBack.forEach((k, v) {
        detectedAll[k] = v;
      });
    }

    int correct = 0;
    final filteredAnswers = detectedAll.entries
        .where((entry) => _currentAnswerKey!.containsKey(entry.key))
        .toList();

    for (var entry in filteredAnswers) {
      if (_currentAnswerKey![entry.key] == entry.value) {
        correct++;
      }
    }

    setState(() {
      _mockAnswers = Map.fromEntries(filteredAnswers);
      _correct = correct;
      _scorePercent = filteredAnswers.isNotEmpty
          ? (correct / filteredAnswers.length) * 100
          : 0;
    });

    await ScanHistoryStorage.saveEntry(
      ScanHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        answerKeyName: _selectedKey ?? 'Unknown',
        timestamp: DateTime.now(),
        detectedAnswers: _mockAnswers,
        correctCount: _correct,
        percentage: _scorePercent,
        imageFrontPath: _imageFileFront?.path ?? '',
        imageBackPath: _imageFileBack?.path,
      ),
    );
  }

  void _showMissingKeyAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Missing Answer Key"),
        content: const Text("No Answer Key Provided."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Scantron')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (_imageFileFront != null)
              Image.file(_imageFileFront!, height: 200)
            else
              const Placeholder(fallbackHeight: 200),

            if (_imageFileBack != null)
              Image.file(_imageFileBack!, height: 200),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: _scantronType,
                isExpanded: true,
                items: [
                  'One-sided (50 questions)',
                  'Two-sided (100 questions)',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _scantronType = newValue!;
                    _imageFileBack = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),
            if (_availableKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: _selectedKey,
                  hint: const Text("Select Test"),
                  isExpanded: true,
                  items: _availableKeys.map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    final loaded = await AnswerKeyStorage.loadKey(value!);
                    setState(() {
                      _selectedKey = value;
                      _currentAnswerKey = loaded;
                    });
                  },
                ),
              ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text("Choose from Gallery"),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),

            const SizedBox(height: 20),
            if (_mockAnswers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._mockAnswers.entries.map((entry) {
                      final correct = _currentAnswerKey?[entry.key] ?? "-";
                      final isCorrect = correct == entry.value;
                      return Text(
                        'Q${entry.key}: ${entry.value}  (Correct: $correct)',
                        style: TextStyle(
                          fontSize: 16,
                          color: isCorrect ? Colors.black : Colors.red,
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(
                      'Score: $_correct / ${_mockAnswers.length} (${_scorePercent.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
