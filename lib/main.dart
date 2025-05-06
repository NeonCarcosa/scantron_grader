import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/scan_history_entry.dart';
import 'screens/capture_screen.dart';
import 'screens/answer_key_screen.dart';
import 'screens/results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register the adapter
  await Hive.initFlutter();
  Hive.registerAdapter(ScanHistoryEntryAdapter());

  // Open the history box
  await Hive.openBox<ScanHistoryEntry>('scan_history');

  runApp(ScantronGraderApp());
}

class ScantronGraderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scantron Grader',
      theme: ThemeData(primarySwatch: Colors.green),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    CaptureScreen(),
    AnswerKeyScreen(),
    ResultsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Answer Keys',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}
