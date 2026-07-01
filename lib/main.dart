import 'package:flutter/material.dart';

import 'core/session.dart';
import 'core/lang.dart';
import 'pages/main_shell_page.dart';
import 'pages/language_select_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Session.loadUser();
  await T.load();

  final hasSelectedLang = await T.hasSelected();

  runApp(HeratBazarApp(hasSelectedLang: hasSelectedLang));
}

class HeratBazarApp extends StatelessWidget {
  final bool hasSelectedLang;

  const HeratBazarApp({
    super.key,
    required this.hasSelectedLang,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeratBazar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F1FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: hasSelectedLang
          ? const MainShellPage()
          : const LanguageSelectPage(),
    );
  }
}