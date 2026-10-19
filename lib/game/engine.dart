import 'dart:math';

enum Mark {
  x,
  o;

  Mark get other => this == x ? o : x;
  String get label => name.toUpperCase();
}

enum GameMode { solo, local }

enum Difficulty { easy, medium, hard }

class GameConfig {
  const GameConfig({
    this.size = 3,
    this.target = 3,
    this.mode = GameMode.solo,
    this.difficulty = Difficulty.medium,
    this.human = Mark.x,
  });

  final int size;
  final int target;
  final GameMode mode;
  final Difficulty difficulty;
  final Mark human;

  GameConfig copyWith({
    int? size,
    int? target,
    GameMode? mode,
    Difficulty? difficulty,
    Mark? human,
  }) => GameConfig(
    size: size ?? this.size,
    target: (target ?? this.target).clamp(3, size ?? this.size),
    mode: mode ?? this.mode,
    difficulty: difficulty ?? this.difficulty,
    human: human ?? this.human,
  );

  void validate() {
    if (size < 3 || size > 8 || target < 3 || target > size) {
      throw ArgumentError(
        'Use a board from 3 to 8 and a target from 3 to board size.',
      );
    }
  }
}

class Move {
  const Move(this.index, this.mark);
  final int index;
  final Mark mark;
}

/// Every possible horizontal, vertical, or diagonal target window.
List<List<int>> winningWindows(int size, int target) {
  final windows = <List<int>>[];
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      for (final direction in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
        final endRow = row + (target - 1) * direction.$1;
        final endCol = col + (target - 1) * direction.$2;
        if (endRow < size && endCol >= 0 && endCol < size) {
          windows.add(
            List.generate(
              target,
              (i) => (row + i * direction.$1) * size + col + i * direction.$2,
            ),
          );
        }
      }
    }
  }
  return windows;
}

List<int> findWinningLine(List<Mark?> board, List<List<int>> windows) {
  for (final line in windows) {
    final first = board[line.first];
    if (first != null && line.every((index) => board[index] == first)) {
      return line;
    }
  }
  return const [];
}

/// Full minimax on 3×3. Larger boards use tactical wins/blocks followed by a
/// bounded two-ply search over promising moves to keep 8×8 work predictable.
class ComputerPlayer {
  ComputerPlayer({Random? random}) : _random = random ?? Random();
  final Random _random;

  int choose(List<Mark?> source, GameConfig config, Mark player) {
    final board = List<Mark?>.of(source);
    final empty = [
      for (var i = 0; i < board.length; i++)
        if (board[i] == null) i,
    ];
    if (empty.isEmpty) throw StateError('No legal moves remain.');
    if (config.difficulty == Difficulty.easy) {
      return empty[_random.nextInt(empty.length)];
    }
    final windows = winningWindows(config.size, config.target);
    for (final mark in [player, player.other]) {
      for (final index in empty) {
        board[index] = mark;
        final wins = findWinningLine(board, windows).isNotEmpty;
        board[index] = null;
        if (wins) return index;
      }
    }
    if (config.difficulty == Difficulty.hard && config.size == 3) {
      var best = -10000;
      var choice = empty.first;
      for (final index in _ordered(board, config, player, windows)) {
        board[index] = player;
        final score = _minimax(
          board,
          player.other,
          player,
          windows,
          0,
          -10000,
          10000,
        );
        board[index] = null;
        if (score > best) {
          best = score;
          choice = index;
        }
      }
      return choice;
    }
    final candidates = _ordered(board, config, player, windows);
    if (config.difficulty == Difficulty.medium) return candidates.first;
    var best = double.negativeInfinity;
    var choice = candidates.first;
    for (final index in candidates.take(12)) {
      board[index] = player;
      var worst = double.infinity;
      final replies = _ordered(board, config, player.other, windows).take(12);
      if (replies.isEmpty) worst = 0;
      for (final reply in replies) {
        board[reply] = player.other;
        final score = findWinningLine(board, windows).isNotEmpty
            ? -1e12
            : _evaluate(board, player, windows);
        worst = min(worst, score);
        board[reply] = null;
      }
      board[index] = null;
      if (worst > best) {
        best = worst;
        choice = index;
      }
    }
    return choice;
  }

  List<int> _ordered(
    List<Mark?> board,
    GameConfig config,
    Mark player,
    List<List<int>> windows,
  ) {
    final scores = <int, double>{};
    final center = (config.size - 1) / 2;
    for (var i = 0; i < board.length; i++) {
      if (board[i] != null) continue;
      board[i] = player;
      final attack = _evaluate(board, player, windows);
      board[i] = player.other;
      final defense = _evaluate(board, player.other, windows);
      board[i] = null;
      scores[i] =
          attack +
          defense * .85 -
          ((i ~/ config.size - center).abs() +
              (i % config.size - center).abs());
    }
    return scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
  }

  double _evaluate(List<Mark?> board, Mark player, List<List<int>> windows) {
    var total = 0.0;
    for (final line in windows) {
      var mine = 0;
      var theirs = 0;
      for (final i in line) {
        if (board[i] == player) mine++;
        if (board[i] == player.other) theirs++;
      }
      if (theirs == 0 && mine > 0) total += pow(8, mine).toDouble();
      if (mine == 0 && theirs > 0) total -= pow(8, theirs).toDouble();
    }
    return total;
  }

  int _minimax(
    List<Mark?> board,
    Mark turn,
    Mark bot,
    List<List<int>> windows,
    int depth,
    int alpha,
    int beta,
  ) {
    final line = findWinningLine(board, windows);
    if (line.isNotEmpty) {
      return board[line.first] == bot ? 100 - depth : depth - 100;
    }
    final empty = [
      for (var i = 0; i < board.length; i++)
        if (board[i] == null) i,
    ];
    if (empty.isEmpty) return 0;
    var best = turn == bot ? -1000 : 1000;
    for (final index in empty) {
      board[index] = turn;
      final score = _minimax(
        board,
        turn.other,
        bot,
        windows,
        depth + 1,
        alpha,
        beta,
      );
      board[index] = null;
      best = turn == bot ? max(best, score) : min(best, score);
      if (turn == bot) {
        alpha = max(alpha, best);
      } else {
        beta = min(beta, best);
      }
      if (beta <= alpha) break;
    }
    return best;
  }
}
