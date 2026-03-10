# Wordle Game

A Flutter implementation of the popular word-guessing game Wordle with a dark theme.

## Features

- **495 five-letter words** from the provided CSV file
- **Three difficulty levels**:
  - Easy: 8 attempts
  - Medium: 6 attempts (default)
  - Hard: 4 attempts
- **Dark theme** with Wordle-inspired colors
- **Virtual keyboard** with color-coded hints
- **Physical keyboard** support
- **App bar** with menu icon, title, and settings

## Screenshots

The app features:
- A grid-based game board that adapts to difficulty (number of rows changes)
- Color-coded tiles: Green (correct position), Yellow (wrong position), Gray (not in word)
- Settings to change difficulty
- How to play instructions
- About section

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK

### Installation

1. Navigate to the project directory:
```bash
cd wordle_game
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

1. Guess the 5-letter word in the given number of tries
2. Each guess must be a valid 5-letter word
3. Press Enter or tap the ENTER key to submit
4. The color of the tiles will change:
   - **Green**: Letter is in the word and in the correct spot
   - **Yellow**: Letter is in the word but in the wrong spot
   - **Gray**: Letter is not in the word

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   └── game_model.dart    # Game state and data models
├── providers/
│   └── game_provider.dart # State management with Provider
├── screens/
│   └── game_screen.dart   # Main game screen
├── utils/
│   └── constants.dart     # Colors and constants
└── widgets/
    ├── grid_tile.dart     # Letter tile widget
    └── keyboard.dart      # Virtual keyboard widget
```

## Dependencies

- `provider`: State management
- `csv`: CSV file parsing

## License

This project is for educational purposes.
