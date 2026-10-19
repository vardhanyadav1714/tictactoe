import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/game/engine.dart';

void main() {
  test('All board sizes detect every legal winning window', () {
    for (var size = 3; size <= 8; size++) {
      for (var target = 3; target <= size; target++) {
        final windows = winningWindows(size, target);
        expect(
          windows.length,
          2 * size * (size - target + 1) + 2 * pow(size - target + 1, 2),
        );
        for (final line in windows) {
          final board = List<Mark?>.filled(size * size, null);
          for (final index in line) {
            board[index] = Mark.x;
          }
          expect(findWinningLine(board, windows), isNotEmpty);
          board[line.last] = Mark.o;
          expect(findWinningLine(board, windows), isEmpty);
        }
      }
    }
  });

  test('Rows never wrap at the edge and gaps never count', () {
    final board = List<Mark?>.filled(25, null);
    for (final index in [3, 4, 5, 10, 12, 14]) {
      board[index] = Mark.x;
    }
    expect(findWinningLine(board, winningWindows(5, 3)), isEmpty);
  });

  test('AI takes wins before blocks and never mutates the input', () {
    for (final difficulty in [Difficulty.medium, Difficulty.hard]) {
      final board = <Mark?>[
        Mark.o,
        Mark.o,
        null,
        Mark.x,
        Mark.x,
        null,
        null,
        null,
        Mark.x,
      ];
      final original = List<Mark?>.of(board);
      expect(
        ComputerPlayer().choose(
          board,
          GameConfig(difficulty: difficulty),
          Mark.o,
        ),
        2,
      );
      expect(board, original);
      board[1] = null;
      expect(
        ComputerPlayer().choose(
          board,
          GameConfig(difficulty: difficulty),
          Mark.o,
        ),
        5,
      );
    }
  });

  test(
    'Hard 3×3 cannot lose against ANY human continuation as either mark',
    () {
      const config = GameConfig(difficulty: Difficulty.hard);
      final ai = ComputerPlayer();
      final windows = winningWindows(3, 3);
      for (final bot in Mark.values) {
        final board = List<Mark?>.filled(9, null);
        void explore(Mark turn) {
          final line = findWinningLine(board, windows);
          if (line.isNotEmpty) {
            expect(board[line.first], bot);
            return;
          }
          if (!board.contains(null)) return;
          if (turn == bot) {
            final index = ai.choose(board, config, bot);
            expect(board[index], isNull);
            board[index] = bot;
            explore(turn.other);
            board[index] = null;
          } else {
            for (var i = 0; i < 9; i++) {
              if (board[i] != null) continue;
              board[i] = turn;
              explore(turn.other);
              board[i] = null;
            }
          }
        }

        explore(Mark.x);
      }
    },
  );

  test('Every AI level completes legal games on all configurations', () {
    for (var size = 3; size <= 8; size++) {
      for (var target = 3; target <= size; target++) {
        for (final difficulty in Difficulty.values) {
          final ai = ComputerPlayer(random: Random(82));
          final config = GameConfig(
            size: size,
            target: target,
            difficulty: difficulty,
          );
          final windows = winningWindows(size, target);
          final board = List<Mark?>.filled(size * size, null);
          var turn = Mark.x;
          while (board.contains(null) &&
              findWinningLine(board, windows).isEmpty) {
            final move = ai.choose(board, config, turn);
            expect(board[move], isNull);
            board[move] = turn;
            turn = turn.other;
          }
        }
      }
    }
  });

  test('Invalid configurations fail early; shrinking clamps the target', () {
    expect(() => const GameConfig(size: 9).validate(), throwsArgumentError);
    expect(
      () => const GameConfig(size: 3, target: 4).validate(),
      throwsArgumentError,
    );
    expect(const GameConfig(size: 8, target: 7).copyWith(size: 3).target, 3);
  });
}
