import 'package:hive/hive.dart';

part 'scan_history_entry.g.dart';

@HiveType(typeId: 0)
class ScanHistoryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String answerKeyName;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Map<int, String> detectedAnswers;

  @HiveField(4)
  final int correctCount;

  @HiveField(5)
  final double percentage;

  @HiveField(6)
  final String imageFrontPath;

  @HiveField(7)
  final String? imageBackPath;

  @HiveField(8)
  final String? studentName;

  ScanHistoryEntry({
    required this.id,
    required this.answerKeyName,
    required this.timestamp,
    required this.detectedAnswers,
    required this.correctCount,
    required this.percentage,
    required this.imageFrontPath,
    this.imageBackPath,
    this.studentName,
  });
}
