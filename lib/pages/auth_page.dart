import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/session.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  bool loading = false;
  bool hideCode = true;

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> login() async {
    if (loading) return;

    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      showMessage("شماره و کد ورود را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.login(
        phone: phone,
        loginCode: code,
      );

      if (!mounted) return;

      showMessage("ورود موفق شد");
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> openRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (result == true && Session.isLoggedIn && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> openForgotCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotCodePage()),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ورود به حساب"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "شماره تلفن",
                  hintText: "مثلاً 0700000000",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                obscureText: hideCode,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: "کد ۶ رقمی ورود",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideCode ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideCode = !hideCode;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: Text(loading ? "در حال ورود..." : "ورود"),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: loading ? null : openForgotCode,
                child: const Text("کد را فراموش کرده‌ام"),
              ),

              TextButton(
                onPressed: loading ? null : openRegister,
                child: const Text("حساب ندارم، ثبت‌نام کنم"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final securityAnswerController = TextEditingController();

  bool loading = false;

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> register() async {
    if (loading) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final securityAnswer = securityAnswerController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        securityAnswer.isEmpty) {
      showMessage("لطفاً همه فیلدها را پر کنید");
      return;
    }

    setState(() => loading = true);

    try {
      final result = await Api.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        securityAnswer: securityAnswer,
      );

      final code = result["login_code"]?.toString() ?? "";

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text("ثبت‌نام موفق شد"),
              content: SelectableText(
                "کد ورود شما:\n\n$code\n\nاین کد را نگه دارید.",
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
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
    securityAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ثبت‌نام"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),

              field(firstNameController, "نام"),
              field(lastNameController, "نام خانوادگی"),
              field(phoneController, "شماره تلفن", type: TextInputType.phone),
              field(securityAnswerController, "نام اولین معلم شما چیست؟"),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : register,
                  child: Text(loading ? "در حال ثبت‌نام..." : "ثبت‌نام"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final answer = answerController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        answer.isEmpty) {
      showMessage("همه فیلدها را پر کنید");
      return;
    }

    setState(() => loading = true);

    try {
      final data = await Api.forgotCode(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        securityAnswer: answer,
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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
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