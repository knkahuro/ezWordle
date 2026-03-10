import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
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
    _loadWords();
  }

  Future<void> _loadWords() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final String csvString = await rootBundle.loadString(_wordLength.assetPath);
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      _wordList = csvTable
          .where((row) => row.length >= 2)
          .map((row) => row[1].toString().toLowerCase().trim())
          .where((word) => word.length == _wordLength.length)
          .toList();
      
      _isLoading = false;
      _startNewGame();
    } catch (e) {
      debugPrint('Error loading words: $e');
      // Fallback word list
      _wordList = _wordLength == WordLength.four 
          ? ['test', 'word', 'game', 'play']
          : _wordLength == WordLength.five
              ? ['about', 'above', 'abuse', 'actor', 'acute']
              : ['action', 'active', 'actual', 'advice', 'affect'];
      _isLoading = false;
      _startNewGame();
    }
  }

  void setDifficulty(Difficulty difficulty) {
    _difficulty = difficulty;
    _startNewGame();
    notifyListeners();
  }

  void setWordLength(WordLength wordLength) {
    _wordLength = wordLength;
    _loadWords();
  }

  void _startNewGame() {
    if (_wordList.isEmpty) return;
    
    final random = Random();
    final targetWord = _wordList[random.nextInt(_wordList.length)].toLowerCase();
    
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
    if (_game.isGameOver || !_game.canSubmit) return;
    
    final guess = _game.currentGuess.toLowerCase();
    
    // Check if word is valid
    if (!_wordList.contains(guess)) {
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
      
      if (key == LogicalKeyboardKey.enter) {
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

