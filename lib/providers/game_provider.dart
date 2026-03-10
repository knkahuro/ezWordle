import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  GameModel _game = GameModel.initial(GameConfig.defaultMaxAttempts, GameConfig.defaultWordLength);
  List<String> _wordList = [];
  Difficulty _difficulty = Difficulty.medium;
  WordLength _wordLength = WordLength.five;
  bool _isLoading = true;
  final _shakeSignalController = StreamController<int>.broadcast();

  GameModel get game => _game;
  List<String> get wordList => _wordList;
  Difficulty get difficulty => _difficulty;
  WordLength get wordLength => _wordLength;
  bool get isLoading => _isLoading;
  Stream<int> get shakeSignal => _shakeSignalController.stream;

  GameProvider() {
    // Start loading in the next microtask to ensure the provider is ready
    Future.microtask(() => _loadWords());
  }

  Future<void> _loadWords() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final String csvString = await rootBundle.loadString(_wordLength.assetPath);
      
      // Removed compute as CSV parsing for this size is fast and compute can hang on Web
      final List<String> words = _parseCsvData({
        'csvString': csvString,
        'length': _wordLength.length,
      });
      
      if (words.isNotEmpty) {
        _wordList = words;
      } else {
        throw Exception('No valid words found in CSV');
      }
    } catch (e) {
      debugPrint('Error loading words: $e');
      _wordList = []; // Reset if load fails
    } finally {
      _isLoading = false;
      _startNewGame();
    }
  }

  void setDifficulty(Difficulty difficulty) {
    if (_difficulty == difficulty) return;
    _difficulty = difficulty;
    _startNewGame();
    notifyListeners();
  }

  void setWordLength(WordLength wordLength) {
    if (_wordLength == wordLength) return;
    _wordLength = wordLength;
    notifyListeners(); // Update UI immediately
    _loadWords();
  }

  void _startNewGame() {
    if (_wordList.isEmpty) {
      debugPrint('Error: Word list is empty. Game cannot start.');
      notifyListeners();
      return;
    }
    
    final random = Random();
    final targetWord = _wordList[random.nextInt(_wordList.length)].toLowerCase().trim();
    debugPrint('Starting new game with targetWord: "$targetWord" (length: ${targetWord.length})');
    
    _game = GameModel.initial(_difficulty.maxAttempts, _wordLength.length).copyWith(
      targetWord: targetWord,
    );
    notifyListeners();
  }

  void newGame() {
    _startNewGame();
  }

  void typeLetter(String letter) {
    if (_game.isGameOver || !_game.canType) return;
    
    final newGuesses = List<List<Letter>>.from(
      _game.guesses.map((row) => List<Letter>.from(row)),
    );
    
    newGuesses[_game.currentRow][_game.currentCol] = Letter(char: letter.toLowerCase());
    
    _game = _game.copyWith(
      guesses: newGuesses,
      currentCol: _game.currentCol + 1,
    );
    notifyListeners();
  }

  void deleteLetter() {
    if (_game.isGameOver || !_game.canDelete) return;
    
    final newGuesses = List<List<Letter>>.from(
      _game.guesses.map((row) => List<Letter>.from(row)),
    );
    
    newGuesses[_game.currentRow][_game.currentCol - 1] = const Letter(char: '');
    
    _game = _game.copyWith(
      guesses: newGuesses,
      currentCol: _game.currentCol - 1,
    );
    notifyListeners();
  }

  void submitGuess() {
    final length = _game.targetWord.isNotEmpty ? _game.targetWord.length : _game.wordLength;
    debugPrint('submitGuess: currentCol=${_game.currentCol}, targetLen=$length, targetWord="${_game.targetWord}"');
    
    if (_game.isGameOver) {
      debugPrint('submitGuess blocked: Game is over');
      return;
    }
    
    if (!_game.canSubmit) {
      debugPrint('submitGuess blocked: canSubmit is false (currentCol != length)');
      return;
    }
    
    final guess = _game.currentGuess.toLowerCase();
    debugPrint('Checking validity of guess: "$guess" against word list of size ${_wordList.length}');
    
    // Check if word is valid
    if (!_wordList.contains(guess)) {
      debugPrint('Invalid word: "$guess"');
      _shakeSignalController.add(_game.currentRow);
      return;
    }
    
    final targetChars = _game.targetWord.split('');
    final newRow = List<Letter>.from(_game.guesses[_game.currentRow]);
    final newKeyboardStatus = Map<String, LetterStatus>.from(_game.keyboardStatus);
    
    // First pass: mark correct positions
    for (int i = 0; i < _game.targetWord.length; i++) {
      final char = newRow[i].char;
      if (char == targetChars[i]) {
        newRow[i] = newRow[i].copyWith(status: LetterStatus.correct);
        targetChars[i] = ''; // Mark as used
        newKeyboardStatus[char] = LetterStatus.correct;
      }
    }
    
    // Second pass: mark present and absent
    for (int i = 0; i < _game.targetWord.length; i++) {
      if (newRow[i].status == LetterStatus.correct) continue;
      
      final char = newRow[i].char;
      final targetIndex = targetChars.indexOf(char);
      
      if (targetIndex != -1) {
        newRow[i] = newRow[i].copyWith(status: LetterStatus.present);
        targetChars[targetIndex] = ''; // Mark as used
        if (newKeyboardStatus[char] != LetterStatus.correct) {
          newKeyboardStatus[char] = LetterStatus.present;
        }
      } else {
        newRow[i] = newRow[i].copyWith(status: LetterStatus.absent);
        if (!newKeyboardStatus.containsKey(char) || 
            newKeyboardStatus[char] == LetterStatus.unknown) {
          newKeyboardStatus[char] = LetterStatus.absent;
        }
      }
    }
    
    final newGuesses = List<List<Letter>>.from(
      _game.guesses.map((row) => List<Letter>.from(row)),
    );
    newGuesses[_game.currentRow] = newRow;
    
    final isWon = guess == _game.targetWord;
    final isGameOver = isWon || _game.currentRow + 1 >= _game.maxAttempts;
    
    _game = _game.copyWith(
      guesses: newGuesses,
      currentRow: _game.currentRow + 1,
      currentCol: 0,
      isWon: isWon,
      isGameOver: isGameOver,
      keyboardStatus: newKeyboardStatus,
    );
    notifyListeners();
  }

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        submitGuess();
      } else if (key == LogicalKeyboardKey.backspace) {
        deleteLetter();
      } else if (key.keyLabel.length == 1) {
        final char = key.keyLabel.toLowerCase();
        if (RegExp(r'^[a-z]$').hasMatch(char)) {
          typeLetter(char);
        }
      }
    }
  }
  @override
  void dispose() {
    _shakeSignalController.close();
    super.dispose();
  }
}

List<String> _parseCsvData(Map<String, dynamic> params) {
  final String csvString = params['csvString'] as String;
  final int targetLength = params['length'] as int;
  
  // Use a highly resilient approach: 
  // 1. Find all alpha-sequences that match the target length
  // 2. Ensure they are isolated (not part of a larger alphanumeric sequence)
  // This bypasses any CSV parsing, encoding, or newline issues.
  final wordRegex = RegExp(r'\b[a-zA-Z]{' + targetLength.toString() + r'}\b');
  final matches = wordRegex.allMatches(csvString);
  
  final Set<String> words = {};
  for (final match in matches) {
    final word = match.group(0)!.toLowerCase();
    // Double check it's pure alphabetical
    if (RegExp(r'^[a-z]+$').hasMatch(word)) {
      words.add(word);
    }
  }
  
  debugPrint('Resiliently parsed ${words.length} words for length $targetLength');
  return words.toList();
}

