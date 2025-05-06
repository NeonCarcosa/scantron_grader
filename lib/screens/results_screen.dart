import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_history_entry.dart';

class ResultsScreen extends StatefulWidget {
  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _filter = 'All';

  List<ScanHistoryEntry> _applyFilter(List<ScanHistoryEntry> all) {
    DateTime now = DateTime.now();
    switch (_filter) {
      case 'Last 7 Days':
        return all.where((e) => now.difference(e.timestamp).inDays <= 7).toList();
      case 'Top Scores':
        return List.from(all)..sort((a, b) => b.percentage.compareTo(a.percentage));
      default:
        return all.reversed.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Results"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'All', child: Text("All")),
              const PopupMenuItem(value: 'Last 7 Days', child: Text("Last 7 Days")),
              const PopupMenuItem(value: 'Top Scores', child: Text("Top Scores")),
            ],
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ScanHistoryEntry>('scan_history').listenable(),
        builder: (context, Box<ScanHistoryEntry> box, _) {
          final entries = _applyFilter(box.values.toList());

          if (entries.isEmpty) {
            return const Center(child: Text("No scan history found."));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.imageFrontPath.isNotEmpty)
                        Image.file(
                          File(entry.imageFrontPath),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      if (entry.imageBackPath != null &&
                          entry.imageBackPath!.isNotEmpty)
                        const SizedBox(width: 4),
                      if (entry.imageBackPath != null &&
                          entry.imageBackPath!.isNotEmpty)
                        Image.file(
                          File(entry.imageBackPath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                  title: Text(entry.answerKeyName),
                  subtitle: Text(
                    "${entry.timestamp.toLocal()} • Score: ${entry.percentage.toStringAsFixed(1)}%",
                  ),
                  onTap: () {
                    // Future: Navigate to detailed results screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
