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
      title: 'افغان بازار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainShellPage(),
    );
  }
}