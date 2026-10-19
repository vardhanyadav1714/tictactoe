import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/main.dart';

void main() {
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(1280, 1000),
  ]) {
    testWidgets('Arena fits $size and supports a complete local round', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TicTacToeApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (size.width < 980) {
        await tester.ensureVisible(find.byTooltip('Game settings'));
        await tester.tap(find.byTooltip('Game settings'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Two players'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('start-game')));
      await tester.tap(find.byKey(const Key('start-game')));
      await tester.pumpAndSettle();
      for (final index in [0, 3, 1, 4, 2]) {
        await tester.ensureVisible(find.byKey(Key('cell-$index')));
        await tester.tap(find.byKey(Key('cell-$index')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Player X wins!'), findsOneWidget);
      expect(find.byKey(const Key('next-round')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('next-round')));
      await tester.tap(find.byKey(const Key('next-round')));
      await tester.pumpAndSettle();
      expect(find.text('Player O’s turn'), findsOneWidget);
      expect(find.text('ROUND 02'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Phone settings apply an 8×8 board and adjustable win length', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TicTacToeApp());
    await tester.tap(find.byTooltip('Game settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 × 8'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase win length'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('start-game')));
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cell-63')), findsOneWidget);
    expect(find.text('8 × 8 board  ·  Connect 4 to win'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Large text remains usable with reduced animation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.7),
            disableAnimations: true,
          ),
          child: const TicTacToeApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
