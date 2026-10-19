import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import 'theme.dart';

Color markColor(Mark mark) => mark == Mark.x ? Palette.mint : Palette.coral;

class MarkIcon extends StatelessWidget {
  const MarkIcon(this.mark, {super.key, this.size = 32, this.animate = false});
  final Mark mark;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 320,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => CustomPaint(painter: _MarkPainter(mark, value)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.mark, this.progress);
  final Mark mark;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = markColor(mark)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.8, size.width * .105)
      ..strokeCap = StrokeCap.round;
    final rect = (Offset.zero & size).deflate(size.width * .17);
    if (mark == Mark.o) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
    } else {
      canvas.drawLine(
        rect.topLeft,
        Offset.lerp(
          rect.topLeft,
          rect.bottomRight,
          (progress * 2).clamp(0, 1),
        )!,
        paint,
      );
      if (progress > .5) {
        canvas.drawLine(
          rect.topRight,
          Offset.lerp(
            rect.topRight,
            rect.bottomLeft,
            (progress * 2 - 1).clamp(0, 1),
          )!,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.mark != mark || old.progress != progress;
}

class GameBoard extends StatelessWidget {
  const GameBoard({super.key, required this.game, required this.haptics});
  final GameController game;
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final n = game.config.size;
    final cells = game.board;
    final gap = n > 5 ? 5.0 : 9.0;
    return AspectRatio(
      aspectRatio: 1,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: n > 4 ? 2.5 : 1,
        panEnabled: n > 4,
        scaleEnabled: n > 4,
        child: Stack(
          children: [
            GridView.builder(
              key: const Key('game-board'),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: n,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final mark = cells[index];
                final winning = game.winningLine.contains(index);
                final latest =
                    game.moves.isNotEmpty && game.moves.last.index == index;
                final available =
                    mark == null &&
                    !game.finished &&
                    game.humanTurn &&
                    !game.thinking;
                return Semantics(
                  label:
                      'Row ${index ~/ n + 1}, column ${index % n + 1}, ${mark?.label ?? 'empty'}',
                  button: true,
                  enabled: available,
                  child: AnimatedContainer(
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 220,
                    ),
                    decoration: BoxDecoration(
                      color: winning
                          ? markColor(mark!).withValues(alpha: .12)
                          : Palette.raised.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(n > 5 ? 9 : 16),
                      border: Border.all(
                        color: winning
                            ? markColor(mark!).withValues(alpha: .7)
                            : latest
                            ? Palette.muted.withValues(alpha: .35)
                            : Palette.border.withValues(alpha: .45),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('cell-$index'),
                        borderRadius: BorderRadius.circular(n > 5 ? 9 : 16),
                        onTap: available
                            ? () {
                                if (haptics) HapticFeedback.selectionClick();
                                game.play(index);
                              }
                            : null,
                        child: LayoutBuilder(
                          builder: (_, box) => Stack(
                            children: [
                              Center(
                                child: mark == null
                                    ? Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Palette.muted.withValues(
                                            alpha: .22,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : MarkIcon(
                                        mark,
                                        key: ValueKey(mark),
                                        size: box.maxWidth * .55,
                                        animate: true,
                                      ),
                              ),
                              if (latest && !winning)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: markColor(mark!),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (game.winner != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${game.round}-${game.winningLine}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 500,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) => CustomPaint(
                      painter: _WinPainter(
                        n,
                        gap,
                        game.winningLine,
                        markColor(game.winner!),
                        value,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WinPainter extends CustomPainter {
  _WinPainter(this.n, this.gap, this.line, this.color, this.progress);
  final int n;
  final double gap;
  final List<int> line;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = (size.width - gap * (n - 1)) / n;
    Offset center(int index) => Offset(
      (index % n) * (cell + gap) + cell / 2,
      (index ~/ n) * (cell + gap) + cell / 2,
    );
    final start = center(line.first);
    final end = Offset.lerp(start, center(line.last), progress)!;
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.withValues(alpha: .12)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WinPainter old) =>
      old.progress != progress || old.line != line;
}

class Celebration extends StatefulWidget {
  const Celebration({super.key});
  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _animation,
      builder: (_, _) =>
          CustomPaint(painter: _ConfettiPainter(_animation.value)),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(24);
    for (var i = 0; i < 48; i++) {
      final x = random.nextDouble();
      final speed = .5 + random.nextDouble();
      final y = -50 + progress * (size.height + 100) * speed;
      canvas.save();
      canvas.translate(x * size.width + sin(progress * 6 + i) * 24, y);
      canvas.rotate(progress * 5 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        Paint()
          ..color = [
            Palette.mint,
            Palette.coral,
            const Color(0xFFADAEFA),
          ][i % 3].withValues(alpha: (1 - progress).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
