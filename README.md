# ezWordle

A premium Flutter implementation of the popular word-guessing game Wordle with a sleek dark theme and advanced features.

## Features

- **Dynamic Word Lengths**: Choose between **4, 5, or 6-letter** words for a varied challenge.
- **Three Difficulty Levels**:
  - **Easy**: 8 attempts
  - **Medium**: 6 attempts (default)
  - **Hard**: 4 attempts

## Sleek UI/UX

- **Side Drawer**: Quick access to game controls and info.
- **Custom Dark Theme**: Professional color palette inspired by the original game.
- **Responsive Grid**: Board layout automatically adjusts based on word length and difficulty.
- **Full Input Support**:
  - **Virtual Keyboard**: Color-coded hints as you play.
  - **Physical Keyboard**: Full support for desktop and web power users.
- **Interactive Instructions**: "How to Play" dialog with visual examples.

## Project Evolution

This project has evolved from a simple clone to a flexible word-guessing platform:

1. **Drawer Navigation**: Replaced the basic menu with a premium side drawer.
2. **Multi-Asset Support**: Integrated separate word lists for 4, 5, and 6-letter modes.
3. **Dynamic State Management**: Refactored to handle variable game configurations on the fly.

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK

### Installation

1. Navigate to the project directory:

```bash
cd ezWordle
```

2. Get dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## How to Play

1. Choose your preferred **Word Length** and **Difficulty** in the settings.
2. Guess the secret word in the given number of tries.
3. Each guess must be a valid word of the selected length.
4. Press Enter or tap the ENTER key to submit.
5. The color of the tiles will change to provide clues:
   - **Green**: Correct letter, correct spot.
   - **Yellow**: Correct letter, wrong spot.
   - **Gray**: Letter not in the word.

## Project Structure

```text
lib/
├── main.dart              # App entry point & Theme configuration
├── models/
│   └── game_model.dart    # Flexible game state and logic models
├── providers/
│   └── game_provider.dart # State management & word list loading
├── screens/
│   └── game_screen.dart   # Responsive UI & Navigation Drawer
├── utils/
│   └── constants.dart     # Enums, colors, and configuration
└── widgets/
    ├── grid_tile.dart     # Animated letter tile widget
    └── keyboard.dart      # Interactive virtual keyboard
```

## Dependencies

- [provider](https://pub.dev/packages/provider): Robust state management.
- [csv](https://pub.dev/packages/csv): Efficient parsing of word list assets.

## License

This project is for educational purposes.
