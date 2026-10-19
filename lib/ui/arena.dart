import 'dart:math';
import 'package:flutter/material.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import 'board.dart';
import 'config_panel.dart';
import 'theme.dart';

class Arena extends StatefulWidget {
  const Arena({super.key});
  @override
  State<Arena> createState() => _ArenaState();
}

class _ArenaState extends State<Arena> {
  final game = GameController();
  bool haptics = true;

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  void _configure(GameConfig config) {
    game.configure(config);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'New match · ${config.size} × ${config.size} · connect ${config.target}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _settings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Palette.surface,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: ConfigPanel(
            config: game.config,
            onApply: (config) {
              Navigator.pop(sheetContext);
              _configure(config);
            },
          ),
        ),
      ),
    ),
  );

  void _help() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A little strategy. A lot of fun.'),
      content: const SingleChildScrollView(
        child: Text(
          'Take turns placing X and O in empty cells. Connect the chosen number of marks horizontally, vertically, or diagonally to win. A full board with no winner is a draw.\n\n'
          'Start with a classic 3 × 3 board, or go up to 8 × 8. Set the win length anywhere from 3 to the board size. On larger boards, pinch to zoom.\n\n'
          'Play the AI or pass the device to a friend. Hard AI plays perfectly on 3 × 3 and uses tactical search on larger boards.\n\n'
          'Undo takes back your turn and the AI response. Finished rounds are final. The starting mark alternates each round. Start fresh clears the match scores.\n\n'
          'Everything works offline. Settings and scores last for this session.',
          style: TextStyle(color: Palette.muted, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Let’s play'),
        ),
      ],
    ),
  );

  Future<void> _restart() async {
    if (game.moves.isEmpty || game.finished) {
      game.restartRound();
      return;
    }
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart this round?'),
        content: const Text('The board will clear. Your match scores stay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (restart == true && mounted) game.restartRound();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _Backdrop())),
        ),
        SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final mobile = constraints.maxWidth < 600;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 20 : 40,
                    vertical: mobile ? 16 : 30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(
                            constraints.maxWidth < 900 ||
                                MediaQuery.textScalerOf(context).scale(1) > 1.3,
                          ),
                          SizedBox(height: mobile ? 22 : 42),
                          _intro(mobile),
                          SizedBox(height: mobile ? 20 : 32),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: Column(
                                    children: [
                                      _Panel(
                                        child: ConfigPanel(
                                          config: game.config,
                                          onApply: _configure,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _tipCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: _gamePanel(context, wide: true),
                                ),
                              ],
                            )
                          else ...[
                            _gamePanel(context, wide: false),
                            const SizedBox(height: 20),
                            if (!mobile) _tipCard(),
                          ],
                          SizedBox(height: mobile ? 24 : 30),
                          _footer(mobile),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );

  Widget _header(bool mobile) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Palette.mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.grid_3x3_rounded,
          color: Palette.background,
          size: 27,
        ),
      ),
      const SizedBox(width: 11),
      const SizedBox(
        width: 78,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'gridly',
            style: TextStyle(
              fontSize: 27,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      if (!mobile) ...[
        const SizedBox(width: 18),
        Container(width: 1, height: 20, color: Palette.border),
        const SizedBox(width: 18),
        const Text(
          'TIC TAC TOE, YOUR WAY',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            color: Palette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const Spacer(),
      IconButton(
        tooltip: haptics ? 'Turn haptics off' : 'Turn haptics on',
        onPressed: () => setState(() => haptics = !haptics),
        icon: Icon(
          haptics ? Icons.vibration_rounded : Icons.do_not_disturb_on_outlined,
          size: 20,
          color: Palette.muted,
        ),
      ),
      if (mobile)
        IconButton(
          tooltip: 'How to play',
          onPressed: _help,
          icon: const Icon(
            Icons.help_outline_rounded,
            color: Palette.muted,
            size: 22,
          ),
        )
      else
        TextButton.icon(
          onPressed: _help,
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('How to play'),
          style: TextButton.styleFrom(foregroundColor: Palette.muted),
        ),
    ],
  );

  Widget _intro(bool mobile) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THE CLASSIC. REIMAGINED.',
              style: TextStyle(
                color: Palette.mint,
                letterSpacing: 2.2,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mobile
                  ? 'Your next great move.'
                  : 'Small grid. Big possibilities.',
              style: mobile
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              mobile
                  ? 'Your rules. Your rival. Your next great move.'
                  : 'A quick break or a worthy challenge. Build your board and make your move.',
              style: const TextStyle(
                color: Palette.muted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
      if (!mobile) ...[
        const SizedBox(width: 28),
        Transform.rotate(angle: -.12, child: _floatingMark(Mark.x)),
        Transform.translate(
          offset: const Offset(-8, 14),
          child: Transform.rotate(angle: .16, child: _floatingMark(Mark.o)),
        ),
      ],
    ],
  );

  Widget _floatingMark(Mark mark) => Container(
    width: 67,
    height: 67,
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.border),
      boxShadow: [
        BoxShadow(
          color: markColor(mark).withValues(alpha: .06),
          blurRadius: 30,
        ),
      ],
    ),
    child: Center(child: MarkIcon(mark, size: 35)),
  );

  Widget _gamePanel(BuildContext context, {required bool wide}) {
    final n = game.config.size;
    return _Panel(
      padding: wide ? 28 : 18,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Palette.mint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ROUND ${game.round.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: Palette.muted,
                ),
              ),
              const Spacer(),
              if (!wide)
                IconButton(
                  tooltip: 'Game settings',
                  onPressed: _settings,
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Palette.mint,
                  ),
                )
              else
                const Text(
                  'THE ARENA',
                  style: TextStyle(
                    color: Palette.muted,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _score(Mark.x)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      '${game.draws}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Palette.muted,
                      ),
                    ),
                    const Text(
                      'DRAWS',
                      style: TextStyle(
                        color: Palette.muted,
                        fontSize: 9,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _score(Mark.o)),
            ],
          ),
          const SizedBox(height: 24),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180,
              ),
              child: Row(
                key: ValueKey(
                  '${game.turn}-${game.winner}-${game.isDraw}-${game.thinking}',
                ),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (game.thinking)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (game.winner != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 9),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: Palette.mint,
                        size: 22,
                      ),
                    )
                  else if (!game.isDraw)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MarkIcon(game.turn, size: 21),
                    ),
                  Flexible(
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            game.finished
                ? (game.isDraw
                      ? 'A worthy match. Ready for a rematch?'
                      : 'Beautifully played. Keep the streak going.')
                : '$n × $n board  ·  Connect ${game.config.target} to win',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Stack(
                children: [
                  GameBoard(game: game, haptics: haptics),
                  if (game.winner != null &&
                      !MediaQuery.disableAnimationsOf(context))
                    Positioned.fill(
                      child: Celebration(
                        key: ValueKey('celebrate-${game.round}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (game.finished)
            SizedBox(
              width: 440,
              child: FilledButton.icon(
                key: const Key('next-round'),
                onPressed: game.nextRound,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Next round'),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: game.canUndo ? game.undo : null,
                    icon: const Icon(Icons.undo_rounded, size: 17),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Restart'),
                  ),
                ),
              ],
            ),
          if (n > 4)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Pinch to zoom for a closer look',
                style: TextStyle(fontSize: 11, color: Palette.muted),
              ),
            ),
          const SizedBox(height: 22),
          Container(height: 1, color: Palette.border.withValues(alpha: .65)),
          const SizedBox(height: 16),
          _history(),
        ],
      ),
    );
  }

  String get _status {
    if (game.winner != null) {
      return '${_playerName(game.winner!)} ${game.config.mode == GameMode.solo && game.winner == game.config.human ? 'win' : 'wins'}!';
    }
    if (game.isDraw) return 'It’s a draw!';
    if (game.thinking) return 'AI is thinking…';
    if (game.config.mode == GameMode.solo) return 'Your move';
    return 'Player ${game.turn.label}’s turn';
  }

  String _playerName(Mark mark) => game.config.mode == GameMode.local
      ? 'Player ${mark.label}'
      : game.config.human == mark
      ? 'You'
      : 'AI';

  Widget _score(Mark mark) {
    final active = !game.finished && game.turn == mark;
    return AnimatedContainer(
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      decoration: BoxDecoration(
        color: active
            ? markColor(mark).withValues(alpha: .07)
            : Palette.raised.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? markColor(mark).withValues(alpha: .5)
              : Palette.border.withValues(alpha: .5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final score = Text(
            '${mark == Mark.x ? game.xWins : game.oWins}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: markColor(mark),
            ),
          );
          final name = Text(
            _playerName(mark),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          );
          if (constraints.maxWidth < 145 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MarkIcon(mark, size: 22),
                    Flexible(child: score),
                  ],
                ),
                const SizedBox(height: 4),
                name,
              ],
            );
          }
          return Row(
            children: [
              MarkIcon(mark, size: 24),
              const SizedBox(width: 9),
              Expanded(child: name),
              score,
            ],
          );
        },
      ),
    );
  }

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: Palette.muted),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Move trail',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${game.moves.length} moves',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Palette.muted, fontSize: 11),
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      if (game.moves.isEmpty)
        const Text(
          'A blank board. A fresh possibility.',
          style: TextStyle(fontSize: 12, color: Palette.muted),
        )
      else
        Wrap(
          spacing: 6,
          runSpacing: 7,
          children: game.moves.reversed
              .take(8)
              .map(
                (move) => Semantics(
                  label:
                      '${move.mark.label} at row ${move.index ~/ game.config.size + 1}, column ${move.index % game.config.size + 1}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.raised,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarkIcon(move.mark, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          '${String.fromCharCode(65 + move.index ~/ game.config.size)}${move.index % game.config.size + 1}',
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
    ],
  );

  Widget _tipCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [
          Palette.mint.withValues(alpha: .07),
          Palette.surface.withValues(alpha: .5),
        ],
      ),
      border: Border.all(color: Palette.mint.withValues(alpha: .12)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_outlined, color: Palette.mint, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room to think bigger',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'Try a 5 × 5 board with 4 in a row. A familiar game, a whole new strategy.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Palette.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _footer(bool mobile) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 20,
    runSpacing: 8,
    children: [
      const Text(
        'CRAFTED BY INNOVATIXHUB',
        style: TextStyle(
          fontSize: 9,
          color: Palette.muted,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Palette.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'Offline. Always ready to play.',
              style: TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = 22});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Palette.surface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Palette.border.withValues(alpha: .75)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .1),
          blurRadius: 40,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _Backdrop extends CustomPainter {
  const _Backdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.7, -.8),
          radius: 1,
          colors: [Palette.mint.withValues(alpha: .05), Colors.transparent],
        ).createShader(bounds),
    );
    final paint = Paint()..color = Palette.muted.withValues(alpha: .07);
    for (var x = 0.0; x < size.width; x += 28) {
      for (var y = 0.0; y < min(size.height, 1400); y += 28) {
        canvas.drawCircle(Offset(x, y), .7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Backdrop old) => false;
}
