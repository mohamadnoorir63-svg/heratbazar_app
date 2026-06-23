import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  bool _loading = false;
  String? _loginCode;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final securityAnswer = _securityAnswerController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        securityAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً همه فیلدها را پر کنید')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _loginCode = null;
    });

    try {
      final result = await AuthService.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        securityAnswer: securityAnswer,
      );

      if (!mounted) return;

      setState(() {
        _loginCode = result['login_code']?.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثبت نام موفق بود')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ثبت نام: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyCode() async {
    final code = _loginCode;
    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کد کپی شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت نام'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'نام',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'نام خانوادگی',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _securityAnswerController,
              decoration: const InputDecoration(
                labelText: 'نام اولین معلم شما',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('ثبت نام'),
              ),
            ),
            if (_loginCode != null) ...[
              const SizedBox(height: 24),
              Text(
                'کد ورود شما:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                _loginCode!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy),
                label: const Text('کپی کد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}