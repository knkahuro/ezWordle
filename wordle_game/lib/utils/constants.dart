import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121213);
  static const Color surface = Color(0xFF1A1A1B);
  static const Color text = Color(0xFFD7DADC);
  static const Color border = Color(0xFF3A3A3C);
  static const Color borderActive = Color(0xFF565758);
  
  // Wordle colors
  static const Color correct = Color(0xFF538D4E);      // Green - correct position
  static const Color present = Color(0xFFB59F3B);      // Yellow - wrong position
  static const Color absent = Color(0xFF3A3A3C);       // Gray - not in word
  static const Color unknown = Color(0xFF121213);      // Empty tile
}

class GameConfig {
  static const int wordLength = 5;
  static const int defaultMaxAttempts = 6;
  static const int easyMaxAttempts = 8;
  static const int hardMaxAttempts = 4;
}

enum Difficulty {
  easy('Easy', GameConfig.easyMaxAttempts),
  medium('Medium', GameConfig.defaultMaxAttempts),
  hard('Hard', GameConfig.hardMaxAttempts);

  final String label;
  final int maxAttempts;

  const Difficulty(this.label, this.maxAttempts);
}

enum LetterStatus {
  unknown,
  correct,
  present,
  absent,
}
