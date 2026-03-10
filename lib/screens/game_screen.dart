import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/keyboard.dart';
import '../widgets/grid_tile.dart';
import '../widgets/shake_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ConfettiController _confettiController;
  final FocusNode _focusNode = FocusNode();
  final List<StreamController<void>> _shakeControllers = List.generate(
    Difficulty.easy.maxAttempts, // Max possible rows
    (_) => StreamController<void>.broadcast(),
  );
  StreamSubscription? _shakeSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Listen for shake signals from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      _shakeSubscription = provider.shakeSignal.listen((rowIndex) {
        if (rowIndex < _shakeControllers.length) {
          _shakeControllers[rowIndex].add(null);
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _focusNode.dispose();
    _shakeSubscription?.cancel();
    for (var controller in _shakeControllers) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => context.read<GameProvider>().handleKeyEvent(event),
      child: Stack(
        children: [
          Scaffold(
            drawer: _buildDrawer(context),
            appBar: AppBar(
              title: const Text('Wordle'),

              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettings(context),
                ),
              ],
            ),
            body: Consumer<GameProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.wordList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.text,
                    ),
                  );
                }

                // Trigger confetti if game is won
                if (provider.game.isWon && _confettiController.state == ConfettiControllerState.stopped) {
                  _confettiController.play();
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        // Difficulty indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${provider.difficulty.label} - ${provider.wordList.length} words',
                            style: TextStyle(
                              color: AppColors.text.withAlpha(153),
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
                        
                        // Virtual Keyboard
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VirtualKeyboard(
                            keyboardStatus: provider.game.keyboardStatus,
                            onKeyPressed: (letter) => provider.typeLetter(letter),
                            onDelete: () => provider.deleteLetter(),
                            onEnter: () => provider.submitGuess(),
                          ),
                        ),
                      ],
                    ),
                    
                    // Game Over Overlay
                    if (provider.game.isGameOver)
                      Center(
                        child: _buildGameOverMessage(context, provider),
                      ),
                      
                    if (provider.isLoading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: AppColors.correct,
                          minHeight: 2,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.correct,
                AppColors.present,
                Colors.blue,
                Colors.pink,
                Colors.orange,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(GameProvider provider) {
    final game = provider.game;
    final wordLength = game.targetWord.isEmpty ? WordLength.five.length : game.targetWord.length;
    final rowCount = game.maxAttempts;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(rowCount, (rowIndex) {
        return ShakeWidget(
          shakeSignal: _shakeControllers[rowIndex].stream,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(wordLength, (colIndex) {
                final letter = game.guesses[rowIndex][colIndex];
                final isCurrentRow = rowIndex == game.currentRow && !game.isGameOver;
                
                return Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: LetterTile(
                    letter: letter,
                    isActive: isCurrentRow,
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameOverMessage(BuildContext context, GameProvider provider) {
    final game = provider.game;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: game.isWon ? AppColors.correct : AppColors.absent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            onPressed: () {
              provider.newGame();
              _confettiController.stop();
            },
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

  Widget _buildDrawer(BuildContext context) {
    final provider = context.read<GameProvider>();
    
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ezWordle',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.wordLength.label} Mode',
                  style: TextStyle(
                    color: AppColors.text.withAlpha(153),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: AppColors.text),
                  title: const Text(
                    'New Game',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    provider.newGame();
                    _confettiController.stop();
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: AppColors.text.withAlpha(102),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, provider, child) => SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Word Length',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    provider.wordLength.label,
                    style: const TextStyle(
                      color: AppColors.correct,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.correct,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.correct,
                  overlayColor: AppColors.correct.withAlpha(51),
                  valueIndicatorColor: AppColors.correct,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  showValueIndicator: ShowValueIndicator.onDrag,
                  tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
                  activeTickMarkColor: Colors.white.withAlpha(128),
                  inactiveTickMarkColor: AppColors.text.withAlpha(64),
                ),
                child: Slider(
                  value: provider.wordLength.length.toDouble(),
                  min: 4,
                  max: 6,
                  divisions: 2,
                  label: provider.wordLength.label,
                  onChanged: (value) {
                    final newLength = WordLength.values.firstWhere(
                      (wl) => wl.length == value.round(),
                    );
                    if (newLength != provider.wordLength) {
                      provider.setWordLength(newLength);
                      _confettiController.stop();
                    }
                  },
                ),
              ),

              const Divider(height: 32, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Difficulty',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                   Text(
                    provider.difficulty.label,
                    style: const TextStyle(
                      color: AppColors.correct,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Changes the number of attempts: ${provider.difficulty.maxAttempts} tries',
                style: TextStyle(
                  color: AppColors.text.withAlpha(153),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.correct,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.correct,
                  overlayColor: AppColors.correct.withAlpha(51),
                  valueIndicatorColor: AppColors.correct,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  showValueIndicator: ShowValueIndicator.onDrag,
                  tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
                  activeTickMarkColor: Colors.white.withAlpha(128),
                  inactiveTickMarkColor: AppColors.text.withAlpha(64),
                ),
                child: Slider(
                  value: Difficulty.values.indexOf(provider.difficulty).toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: provider.difficulty.label,
                  onChanged: (value) {
                    final newDifficulty = Difficulty.values[value.round()];
                    if (newDifficulty != provider.difficulty) {
                      provider.setDifficulty(newDifficulty);
                      _confettiController.stop();
                    }
                  },
                ),
              ),

            ],
          ),
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
                'Each guess must be a valid word of the chosen length. Hit the enter button to submit.',
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
              'ezWordle',
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
              '• Variable word lengths (4, 5, 6)\n• Three difficulty levels\n• Dark theme\n• Virtual and physical keyboard support',
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
