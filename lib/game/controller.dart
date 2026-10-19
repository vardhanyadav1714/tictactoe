import 'dart:async';
import 'package:flutter/foundation.dart';
import 'engine.dart';

class GameController extends ChangeNotifier {
  GameController({
    GameConfig config = const GameConfig(),
    ComputerPlayer? computer,
    this.thinkTime = const Duration(milliseconds: 440),
  }) : _config = (config..validate()),
       _computer = computer ?? ComputerPlayer() {
    _resetBoard();
  }

  GameConfig _config;
  GameConfig get config => _config;
  final ComputerPlayer _computer;
  final Duration thinkTime;
  Timer? _timer;
  bool _disposed = false;
  List<Mark?> _board = [];
  List<Mark?> get board => List.unmodifiable(_board);
  final List<Move> _moves = [];
  List<Move> get moves => List.unmodifiable(_moves);
  List<List<int>> _windows = [];
  List<int> _winningLine = [];
  List<int> get winningLine => List.unmodifiable(_winningLine);
  Mark turn = Mark.x;
  Mark starter = Mark.x;
  Mark? winner;
  bool thinking = false;
  int round = 1;
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  bool get isDraw => winner == null && !_board.contains(null);
  bool get finished => winner != null || isDraw;
  bool get canUndo =>
      _moves.isNotEmpty &&
      !finished &&
      (_config.mode == GameMode.local ||
          _moves.any((m) => m.mark == _config.human));
  bool get humanTurn => _config.mode == GameMode.local || turn == _config.human;

  void play(int index) {
    if (_disposed ||
        thinking ||
        !humanTurn ||
        finished ||
        index < 0 ||
        index >= _board.length ||
        _board[index] != null) {
      return;
    }
    _place(index);
    _scheduleComputer();
    notifyListeners();
  }

  void _place(int index) {
    _board[index] = turn;
    _moves.add(Move(index, turn));
    _winningLine = findWinningLine(_board, _windows);
    if (_winningLine.isNotEmpty) {
      winner = turn;
      if (turn == Mark.x) {
        xWins++;
      } else {
        oWins++;
      }
    } else if (isDraw) {
      draws++;
    } else {
      turn = turn.other;
    }
  }

  void _scheduleComputer() {
    if (_disposed || finished || humanTurn) return;
    thinking = true;
    _timer = Timer(thinkTime, () {
      if (_disposed) return;
      final index = _computer.choose(_board, _config, turn);
      thinking = false;
      _place(index);
      notifyListeners();
    });
  }

  void undo() {
    if (!canUndo) return;
    _timer?.cancel();
    thinking = false;
    do {
      final move = _moves.removeLast();
      _board[move.index] = null;
      turn = move.mark;
    } while (_config.mode == GameMode.solo &&
        _moves.isNotEmpty &&
        turn != _config.human);
    _scheduleComputer();
    notifyListeners();
  }

  void restartRound() {
    if (finished) {
      nextRound();
      return;
    }
    _resetBoard();
    notifyListeners();
  }

  void nextRound() {
    if (!finished) return;
    round++;
    starter = starter.other;
    _resetBoard();
    notifyListeners();
  }

  void configure(GameConfig config) {
    config.validate();
    _config = config;
    round = 1;
    starter = Mark.x;
    xWins = oWins = draws = 0;
    _resetBoard();
    notifyListeners();
  }

  void _resetBoard() {
    _timer?.cancel();
    thinking = false;
    turn = starter;
    winner = null;
    _winningLine = [];
    _moves.clear();
    _board = List.filled(_config.size * _config.size, null);
    _windows = winningWindows(_config.size, _config.target);
    _scheduleComputer();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
