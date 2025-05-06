import 'dart:io';

Future<Map<int, String>> detectBubbles(File imageFile) async {
  // Simulate processing delay
  await Future.delayed(Duration(milliseconds: 500));

  // Mock result: 50 questions with random answers
  Map<int, String> mockAnswers = {};
  const choices = ['A', 'B', 'C', 'D', 'E'];
  for (int i = 1; i <= 50; i++) {
    mockAnswers[i] = choices[i % choices.length];
  }

  return mockAnswers;
}
