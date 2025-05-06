// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanHistoryEntryAdapter extends TypeAdapter<ScanHistoryEntry> {
  @override
  final int typeId = 0;

  @override
  ScanHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanHistoryEntry(
      id: fields[0] as String,
      answerKeyName: fields[1] as String,
      timestamp: fields[2] as DateTime,
      detectedAnswers: (fields[3] as Map).cast<int, String>(),
      correctCount: fields[4] as int,
      percentage: fields[5] as double,
      imageFrontPath: fields[6] as String,
      imageBackPath: fields[7] as String?,
      studentName: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanHistoryEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.answerKeyName)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.detectedAnswers)
      ..writeByte(4)
      ..write(obj.correctCount)
      ..writeByte(5)
      ..write(obj.percentage)
      ..writeByte(6)
      ..write(obj.imageFrontPath)
      ..writeByte(7)
      ..write(obj.imageBackPath)
      ..writeByte(8)
      ..write(obj.studentName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
