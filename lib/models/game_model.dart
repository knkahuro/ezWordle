import '../utils/constants.dart';

class Letter {
  final String char;
  final LetterStatus status;

  const Letter({
    required this.char,
    this.status = LetterStatus.unknown,
  });

  Letter copyWith({
    String? char,
    LetterStatus? status,
  }) {
    return Letter(
      char: char ?? this.char,
      status: status ?? this.status,
    );
  }
}

class GameModel {
  final String targetWord;
  final List<List<Letter>> guesses;
  final int currentRow;
  final int currentCol;
  final bool isGameOver;
  final bool isWon;
  final Map<String, LetterStatus> keyboardStatus;
  final int maxAttempts;

  GameModel({
    required this.targetWord,
    required this.guesses,
    required this.currentRow,
    required this.currentCol,
    required this.isGameOver,
    required this.isWon,
    required this.keyboardStatus,
    required this.maxAttempts,
  });

  factory GameModel.initial(int maxAttempts) {
    return GameModel(
      targetWord: '',
      guesses: List.generate(
        maxAttempts,
        (_) => List.generate(
          GameConfig.wordLength,
          (_) => const Letter(char: ''),
        ),
      ),
      currentRow: 0,
      currentCol: 0,
      isGameOver: false,
      isWon: false,
      keyboardStatus: {},
      maxAttempts: maxAttempts,
    );
  }

  GameModel copyWith({
    String? targetWord,
    List<List<Letter>>? guesses,
    int? currentRow,
    int? currentCol,
    bool? isGameOver,
    bool? isWon,
    Map<String, LetterStatus>? keyboardStatus,
    int? maxAttempts,
  }) {
    return GameModel(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      currentRow: currentRow ?? this.currentRow,
      currentCol: currentCol ?? this.currentCol,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      keyboardStatus: keyboardStatus ?? this.keyboardStatus,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  String get currentGuess {
    return guesses[currentRow].map((l) => l.char).join();
  }

  bool get canSubmit {
    return currentCol == GameConfig.wordLength;
  }

  bool get canType {
    return !isGameOver && currentCol < GameConfig.wordLength;
  }

  bool get canDelete {
    return currentCol > 0;
  }
}
