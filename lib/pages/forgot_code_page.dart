import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class ForgotCodePage extends StatefulWidget {
  const ForgotCodePage({super.key});

  @override
  State<ForgotCodePage> createState() => _ForgotCodePageState();
}

class _ForgotCodePageState extends State<ForgotCodePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final answerController = TextEditingController();

  bool loading = false;

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> recoverCode() async {
    if (loading) return;

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        answerController.text.trim().isEmpty) {
      showMessage("همه فیلدها را پر کنید");
      return;
    }

    setState(() => loading = true);

    try {
      final data = await AuthService.forgotCode(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        phone: phoneController.text,
        securityAnswer: answerController.text,
      );

      final code = data["new_code"]?.toString() ?? "";

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text("کد جدید ساخته شد"),
              content: SelectableText(
                "کد ورود جدید شما:\n\n$code\n\nاین کد را حتماً نگه دارید.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showMessage("کد کپی شد");
                  },
                  child: const Text("کپی کد"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("فهمیدم"),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("فراموشی کد ورود"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.password, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              field(firstNameController, "نام"),
              field(lastNameController, "نام خانوادگی"),
              field(phoneController, "شماره تلفن", type: TextInputType.phone),
              field(answerController, "نام اولین معلم شما چیست؟"),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : recoverCode,
                  child: Text(loading ? "در حال بررسی..." : "دریافت کد جدید"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}