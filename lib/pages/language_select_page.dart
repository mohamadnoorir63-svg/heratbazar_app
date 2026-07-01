import 'package:flutter/material.dart';

import '../core/lang.dart';
import 'main_shell_page.dart';

class LanguageSelectPage extends StatefulWidget {
  const LanguageSelectPage({super.key});

  @override
  State<LanguageSelectPage> createState() => _LanguageSelectPageState();
}

class _LanguageSelectPageState extends State<LanguageSelectPage> {
  String selectedLang = 'fa';

  Future<void> saveLanguage() async {
    await T.set(selectedLang);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShellPage()),
    );
  }

  Widget langCard({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = selectedLang == value;

    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedLang,
        onChanged: (v) {
          if (v == null) return;
          setState(() => selectedLang = v);
        },
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(T.tr('select_language')),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              langCard(
                title: 'دری',
                subtitle: 'زبان دری',
                value: 'fa',
              ),
              langCard(
                title: 'پښتو',
                subtitle: 'پښتو ژبه',
                value: 'ps',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: saveLanguage,
                  child: Text(T.tr('continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}