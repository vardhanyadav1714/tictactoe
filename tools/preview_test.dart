// Run explicitly: flutter test tools/preview_test.dart --update-goldens
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/main.dart';

void main() {
  testWidgets('Render desktop and phone previews with bundled fonts', (
    tester,
  ) async {
    for (final entry in {
      'regular': '400',
      'medium': '500',
      'bold': '700',
      'black': '900',
    }.entries) {
      final loader = FontLoader('GridlySans')
        ..addFont(rootBundle.load('assets/fonts/roboto-${entry.key}.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final size in [const Size(1440, 1200), const Size(390, 980)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: captureKey, child: const TicTacToeApp()),
      );
      await tester.pumpAndSettle();
      if (size.width < 980) {
        await tester.tap(find.byTooltip('Game settings'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Two players'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('start-game')));
      await tester.tap(find.byKey(const Key('start-game')));
      await tester.pumpAndSettle();
      for (final index in [0, 4, 8, 2]) {
        await tester.ensureVisible(find.byKey(Key('cell-$index')));
        await tester.tap(find.byKey(Key('cell-$index')));
        await tester.pumpAndSettle();
      }
      // Restore scroll position to include the brand and introduction.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 1500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage();
        final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final name = size.width > 980 ? 'desktop' : 'phone';
        await File('docs/$name.png').writeAsBytes(png!.buffer.asUint8List());
        rendered.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
