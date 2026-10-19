import 'package:flutter/material.dart';
import 'ui/arena.dart';
import 'ui/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Palette.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/LICENSE.txt'));
  });
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gridly · Tic Tac Toe',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const Arena(),
  );
}
