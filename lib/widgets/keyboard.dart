import 'package:flutter/material.dart';
import '../utils/constants.dart';

class VirtualKeyboard extends StatelessWidget {
  final Map<String, LetterStatus> keyboardStatus;
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onEnter;

  const VirtualKeyboard({
    super.key,
    required this.keyboardStatus,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onEnter,
  });

  static const List<String> _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const List<String> _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const List<String> _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  Color _getKeyColor(String key) {
    final status = keyboardStatus[key.toLowerCase()];
    switch (status) {
      case LetterStatus.correct:
        return AppColors.correct;
      case LetterStatus.present:
        return AppColors.present;
      case LetterStatus.absent:
        return AppColors.absent;
      default:
        return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1
          _buildKeyRow(_row1),
          const SizedBox(height: 8),
          // Row 2
          _buildKeyRow(_row2, padding: const EdgeInsets.symmetric(horizontal: 16)),
          const SizedBox(height: 8),
          // Row 3 with Enter and Backspace
          _buildLastRow(),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, {EdgeInsets padding = EdgeInsets.zero}) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) => _buildKey(key)).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: _getKeyColor(key),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () {
            debugPrint('Key pressed: $key');
            onKeyPressed(key.toLowerCase());
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 48,
            color: Colors.transparent, // Ensure it's hit-testable
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  color: keyboardStatus.containsKey(key.toLowerCase()) 
                      ? Colors.white 
                      : AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backspace key
        _buildActionKey(
          '⌫',
          onDelete,
          width: 52,
        ),
        const SizedBox(width: 4),
        // Letter keys
        ..._row3.map((key) => _buildKey(key)),
        const SizedBox(width: 4),
        // Enter key
        _buildActionKey(
          'ENTER',
          onEnter,
          width: 52, 
        ),
      ],
    );
  }

  Widget _buildActionKey(String label, VoidCallback onTap, {required double width}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {
          debugPrint('Action key pressed: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: width,
          height: 48,
          color: Colors.transparent, // Ensure it's hit-testable
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
