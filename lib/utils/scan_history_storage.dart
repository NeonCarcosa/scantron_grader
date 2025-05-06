import 'package:hive/hive.dart';
import '../models/scan_history_entry.dart';

class ScanHistoryStorage {
  static const String boxName = 'scan_history';

  static Future<void> saveEntry(ScanHistoryEntry entry) async {
    final box = Hive.box<ScanHistoryEntry>(boxName);
    await box.put(entry.id, entry);
  }

  static List<ScanHistoryEntry> getAllEntries() {
    final box = Hive.box<ScanHistoryEntry>(boxName);
    return box.values.toList();
  }
}
