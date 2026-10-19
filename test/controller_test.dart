import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/game/controller.dart';
import 'package:tictactoe/game/engine.dart';

void main() {
  const local = GameConfig(mode: GameMode.local);

  test('Win scores once, locks the board, and alternates next starter', () {
    final game = GameController(config: local);
    addTearDown(game.dispose);
    for (final index in [0, 3, 1, 4, 2]) {
      game.play(index);
    }
    expect(game.winner, Mark.x);
    expect(game.winningLine, [0, 1, 2]);
    expect(game.xWins, 1);
    game.play(5);
    game.undo();
    expect(game.moves.length, 5);
    expect(game.xWins, 1);
    game.nextRound();
    expect(game.turn, Mark.o);
    expect(game.round, 2);
    expect(game.moves, isEmpty);
    expect(game.xWins, 1);
  });

  test('Full draw, occupied cells, invalid taps, and restart scoring', () {
    final game = GameController(config: local);
    addTearDown(game.dispose);
    game.play(-1);
    game.play(9);
    expect(game.moves, isEmpty);
    game.play(0);
    game.play(0);
    expect(game.moves.length, 1);
    game.restartRound();
    for (final index in [0, 1, 2, 4, 3, 5, 7, 6, 8]) {
      game.play(index);
    }
    expect(game.isDraw, isTrue);
    expect(game.draws, 1);
    game.restartRound();
    expect(game.round, 2);
    expect(game.draws, 1);
  });

  test('Local undo returns the right mark', () {
    final game = GameController(config: local);
    addTearDown(game.dispose);
    game.play(0);
    game.play(4);
    game.undo();
    expect(game.turn, Mark.o);
    expect(game.board[4], isNull);
    expect(game.moves.length, 1);
  });

  testWidgets(
    'Undo cancels pending AI and takes back a completed AI response',
    (tester) async {
      final game = GameController();
      addTearDown(game.dispose);
      game.play(0);
      expect(game.thinking, isTrue);
      game.play(1);
      expect(game.moves.length, 1);
      game.undo();
      await tester.pump(const Duration(seconds: 1));
      expect(game.moves, isEmpty);
      expect(game.turn, Mark.x);
      game.play(0);
      await tester.pump(const Duration(seconds: 1));
      expect(game.moves.length, 2);
      game.undo();
      expect(game.moves, isEmpty);
      expect(game.turn, Mark.x);
    },
  );

  testWidgets('Playing O preserves the bot opening when undoing', (
    tester,
  ) async {
    final game = GameController(config: const GameConfig(human: Mark.o));
    addTearDown(game.dispose);
    expect(game.thinking, isTrue);
    expect(game.canUndo, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(game.moves.length, 1);
    final free = game.board.indexOf(null);
    game.play(free);
    await tester.pump(const Duration(seconds: 1));
    game.undo();
    expect(game.moves.length, 1);
    expect(game.turn, Mark.o);
    expect(game.thinking, isFalse);
  });

  testWidgets('Changing rules cancels old AI work and resets match scores', (
    tester,
  ) async {
    final game = GameController();
    addTearDown(game.dispose);
    game.play(0);
    game.configure(const GameConfig(size: 8, target: 5, mode: GameMode.local));
    await tester.pump(const Duration(seconds: 1));
    expect(game.board.length, 64);
    expect(game.moves, isEmpty);
    expect(game.thinking, isFalse);
    for (final index in [0, 8, 1, 9, 2, 10, 3, 11, 4]) {
      game.play(index);
    }
    expect(game.winner, Mark.x);
    game.configure(local);
    expect(game.xWins, 0);
    expect(game.round, 1);
  });

  testWidgets('Disposal cancels scheduled AI callbacks', (tester) async {
    final game = GameController(config: const GameConfig(human: Mark.o));
    game.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
