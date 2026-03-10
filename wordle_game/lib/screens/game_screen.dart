import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/keyboard.dart';
import '../widgets/grid_tile.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) => context.read<GameProvider>().handleKeyEvent(event),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
          title: const Text('WORDLE'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
        body: Consumer<GameProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.text,
                ),
              );
            }

            return Column(
              children: [
                // Difficulty indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${provider.difficulty.label} - ${provider.wordList.length} words',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Game Grid
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildGrid(provider),
                      ),
                    ),
                  ),
                ),
                
                // Game Over Message
                if (provider.game.isGameOver)
                  _buildGameOverMessage(context, provider),
                
                // Virtual Keyboard
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VirtualKeyboard(
                    keyboardStatus: provider.game.keyboardStatus,
                    onKeyPressed: provider.typeLetter,
                    onDelete: provider.deleteLetter,
                    onEnter: provider.submitGuess,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(GameProvider provider) {
    final game = provider.game;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: GameConfig.wordLength,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: game.maxAttempts * GameConfig.wordLength,
      itemBuilder: (context, index) {
        final row = index ~/ GameConfig.wordLength;
        final col = index % GameConfig.wordLength;
        final letter = game.guesses[row][col];
        final isCurrentRow = row == game.currentRow && !game.isGameOver;
        
        return LetterTile(
          letter: letter,
          isActive: isCurrentRow,
        );
      },
    );
  }

  Widget _buildGameOverMessage(BuildContext context, GameProvider provider) {
    final game = provider.game;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: game.isWon ? AppColors.correct : AppColors.absent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            game.isWon ? 'Congratulations!' : 'Game Over',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game.isWon 
                ? 'You guessed the word!' 
                : 'The word was: ${game.targetWord.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.newGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: game.isWon ? AppColors.correct : AppColors.absent,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final provider = context.read<GameProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.text),
                title: const Text(
                  'New Game',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  provider.newGame();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.text),
                title: const Text(
                  'How to Play',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHowToPlay(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.text),
                title: const Text(
                  'About',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAbout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final provider = context.read<GameProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Difficulty',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Changes the number of attempts you get',
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<Difficulty>(
                groupValue: provider.difficulty,
                onChanged: (value) {
                  if (value != null) {
                    provider.setDifficulty(value);
                    Navigator.pop(context);
                  }
                },
                child: Column(
                  children: Difficulty.values.map((difficulty) => RadioListTile<Difficulty>(
                    title: Text(
                      difficulty.label,
                      style: const TextStyle(color: AppColors.text),
                    ),
                    subtitle: Text(
                      '${difficulty.maxAttempts} attempts',
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    value: difficulty,
                    activeColor: AppColors.correct,
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'How to Play',
          style: TextStyle(color: AppColors.text),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Guess the word in the given number of tries.',
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 16),
              const Text(
                'Each guess must be a valid 5-letter word. Hit the enter button to submit.',
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 16),
              const Text(
                'After each guess, the color of the tiles will change to show how close your guess was to the word.',
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 24),
              _buildExample('WEARY', 'W is in the word and in the correct spot.', 0),
              const SizedBox(height: 12),
              _buildExample('PILLS', 'I is in the word but in the wrong spot.', 1),
              const SizedBox(height: 12),
              _buildExample('VAGUE', 'U is not in the word in any spot.', 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: AppColors.correct),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String word, String explanation, int highlightedIndex) {
    final colors = List.filled(5, AppColors.absent);
    if (highlightedIndex == 0) {
      colors[0] = AppColors.correct;
    } else if (highlightedIndex == 1) {
      colors[1] = AppColors.present;
    } else {
      colors[3] = AppColors.absent;
    }
    
    return Row(
      children: [
        ...word.split('').asMap().entries.map((entry) {
          return Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: colors[entry.key],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                entry.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            explanation,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'About',
          style: TextStyle(color: AppColors.text),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wordle Game',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A Flutter implementation of the popular word-guessing game.',
              style: TextStyle(color: AppColors.text),
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• 495 five-letter words\n• Three difficulty levels\n• Dark theme\n• Virtual and physical keyboard support',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.correct),
            ),
          ),
        ],
      ),
    );
  }
}
