import 'package:flutter/material.dart';

import 'core/session.dart';
import 'pages/main_shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.loadUser();
  runApp(const HeratBazarApp());
}

class HeratBazarApp extends StatelessWidget {
  const HeratBazarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeratBazar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff8f1fb),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const MainShellPage(),
    );
  }
}