import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class LetterTile extends StatelessWidget {
  final Letter letter;
  final bool isActive;

  const LetterTile({
    super.key,
    required this.letter,
    this.isActive = false,
  });

  Color get _backgroundColor {
    switch (letter.status) {
      case LetterStatus.correct:
        return AppColors.correct;
      case LetterStatus.present:
        return AppColors.present;
      case LetterStatus.absent:
        return AppColors.absent;
      case LetterStatus.unknown:
        return AppColors.unknown;
    }
  }

  Color get _borderColor {
    if (letter.status != LetterStatus.unknown) {
      return _backgroundColor;
    }
    if (letter.char.isNotEmpty) {
      return AppColors.borderActive;
    }
    if (isActive) {
      return AppColors.borderActive;
    }
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border.all(
          color: _borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: letter.status == LetterStatus.unknown 
                ? AppColors.text 
                : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          child: Text(
            letter.char.toUpperCase(),
          ),
        ),
      ),
    );
  }
}
