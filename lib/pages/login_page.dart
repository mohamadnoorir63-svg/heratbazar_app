import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'register_page.dart';
import 'forgot_code_page.dart';

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

    if (phoneController.text.trim().isEmpty ||
        codeController.text.trim().isEmpty) {
      showMessage("شماره و کد ورود را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.login(
        phone: phoneController.text,
        loginCode: codeController.text,
      );

      if (mounted) {
        showMessage("ورود موفق شد");
        Navigator.pop(context, true);
      }
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> openRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );

    if (result == true && AuthService.isLoggedIn && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> openForgotCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotCodePage(),
      ),
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