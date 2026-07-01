import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/lang.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

enum AuthMode { phoneLogin, emailLogin }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthMode mode = AuthMode.phoneLogin;

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hideCode = true;
  bool hidePassword = true;

  String tr(String key) => T.tr(key);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> loginPhone() async {
    if (loading) return;

    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      showMessage(tr('enter_phone_code'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.login(phone: phone, loginCode: code);
      if (!mounted) return;
      showMessage(tr('login_success'));
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> loginEmail() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(tr('enter_email_password'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.loginEmail(email: email, password: password);
      if (!mounted) return;
      showMessage(tr('email_login_success'));
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
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

  Future<void> openForgotEmailPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotEmailPasswordPage()),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget modeButton(AuthMode item, String text, IconData icon) {
    final selected = mode == item;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : () => setState(() => mode = item),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.deepPurple : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.black54, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget phoneLoginForm() {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: tr('phone_number'),
            hintText: tr('phone_example'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          obscureText: hideCode,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: tr('six_digit_login_code'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(hideCode ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => hideCode = !hideCode),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : openForgotCode,
          child: Text(tr('code_forgot')),
        ),
      ],
    );
  }

  Widget emailLoginForm() {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            labelText: tr('email'),
            hintText: 'example@gmail.com',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: hidePassword,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: tr('password'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => hidePassword = !hidePassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : openForgotEmailPassword,
          child: Text(tr('email_password_forgot')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = mode == AuthMode.phoneLogin;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('login_to_account')), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(isPhone ? Icons.phone_android : Icons.email, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Row(
                children: [
                  modeButton(AuthMode.phoneLogin, tr('phone'), Icons.phone),
                  const SizedBox(width: 8),
                  modeButton(AuthMode.emailLogin, tr('email'), Icons.email),
                ],
              ),
              const SizedBox(height: 18),
              isPhone ? phoneLoginForm() : emailLoginForm(),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : (isPhone ? loginPhone : loginEmail),
                  child: Text(loading ? tr('logging_in') : tr('login')),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: loading ? null : openRegister,
                child: Text(tr('no_account_register')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum RegisterMode { phone, email }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  RegisterMode mode = RegisterMode.phone;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final securityAnswerController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  String tr(String key) => T.tr(key);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        textDirection: type == TextInputType.emailAddress ? TextDirection.ltr : TextDirection.rtl,
        textAlign: type == TextInputType.emailAddress ? TextAlign.left : TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget modeButton(RegisterMode item, String text, IconData icon) {
    final selected = mode == item;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : () => setState(() => mode = item),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.deepPurple : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.black54, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registerPhone() async {
    if (loading) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final securityAnswer = securityAnswerController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty || securityAnswer.isEmpty) {
      showMessage(tr('fill_all_fields'));
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

      final code = result['login_code']?.toString() ?? '';

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(tr('register_success')),
              content: SelectableText(
                '${tr('your_login_code')}\n\n$code\n\n${tr('keep_this_code')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showMessage(tr('code_copied'));
                  },
                  child: Text(tr('copy_code')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('understood')),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> registerEmail() async {
    if (loading) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage(tr('enter_register_email_fields'));
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      showMessage(tr('enter_valid_email'));
      return;
    }

    if (password.length < 6) {
      showMessage(tr('password_min_6'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.registerEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailPage(email: email)),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    securityAnswerController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = mode == RegisterMode.phone;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('register')), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(isPhone ? Icons.person_add : Icons.mark_email_read, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Row(
                children: [
                  modeButton(RegisterMode.phone, tr('phone'), Icons.phone),
                  const SizedBox(width: 8),
                  modeButton(RegisterMode.email, tr('email'), Icons.email),
                ],
              ),
              const SizedBox(height: 18),
              field(firstNameController, tr('first_name')),
              field(lastNameController, tr('last_name')),
              if (isPhone) ...[
                field(phoneController, tr('phone_number'), type: TextInputType.phone),
                field(securityAnswerController, tr('security_question_teacher')),
              ] else ...[
                field(emailController, tr('email'), type: TextInputType.emailAddress),
                field(
                  passwordController,
                  tr('password'),
                  obscure: hidePassword,
                  suffixIcon: IconButton(
                    icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : (isPhone ? registerPhone : registerEmail),
                  child: Text(loading ? tr('registering') : tr('register')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final codeController = TextEditingController();
  bool loading = false;

  String tr(String key) => T.tr(key);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> verify() async {
    if (loading) return;

    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage(tr('enter_email_code'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.verifyEmail(email: widget.email, code: code);
      if (!mounted) return;
      showMessage(tr('email_verified'));
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> resend() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      await Api.resendEmailCode(email: widget.email);
      if (!mounted) return;
      showMessage(tr('code_resent'));
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('verify_email')), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.verified_user, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                '${tr('verify_code_sent_to')}\n${widget.email}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: tr('email_verify_code'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : verify,
                  child: Text(loading ? tr('verifying') : tr('verify_email')),
                ),
              ),
              TextButton(
                onPressed: loading ? null : resend,
                child: Text(tr('resend_code')),
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

  String tr(String key) => T.tr(key);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Widget field(TextEditingController controller, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> recoverCode() async {
    if (loading) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final answer = answerController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty || answer.isEmpty) {
      showMessage(tr('fill_all_fields'));
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

      final code = data['new_code']?.toString() ?? '';

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(tr('new_code_created')),
              content: SelectableText(
                '${tr('your_new_login_code')}\n\n$code\n\n${tr('keep_this_code')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showMessage(tr('code_copied'));
                  },
                  child: Text(tr('copy_code')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('understood')),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
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
        appBar: AppBar(title: Text(tr('forgot_code')), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.password, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              field(firstNameController, tr('first_name')),
              field(lastNameController, tr('last_name')),
              field(phoneController, tr('phone_number'), type: TextInputType.phone),
              field(answerController, tr('security_question_teacher')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : recoverCode,
                  child: Text(loading ? tr('checking') : tr('get_new_code')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotEmailPasswordPage extends StatefulWidget {
  const ForgotEmailPasswordPage({super.key});

  @override
  State<ForgotEmailPasswordPage> createState() => _ForgotEmailPasswordPageState();
}

class _ForgotEmailPasswordPageState extends State<ForgotEmailPasswordPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool codeSent = false;
  bool hidePassword = true;

  String tr(String key) => T.tr(key);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> sendCode() async {
    if (loading) return;

    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(tr('enter_email'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.forgotPasswordEmail(email: email);
      if (!mounted) return;
      setState(() => codeSent = true);
      showMessage(tr('recovery_code_sent'));
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> resetPassword() async {
    if (loading) return;

    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || code.isEmpty || password.isEmpty) {
      showMessage(tr('enter_email_code_password'));
      return;
    }

    if (password.length < 6) {
      showMessage(tr('password_min_6'));
      return;
    }

    setState(() => loading = true);

    try {
      await Api.resetPasswordEmail(email: email, code: code, password: password);
      if (!mounted) return;
      showMessage(tr('password_changed'));
      Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception:', '').trim());
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('reset_email_password')), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                enabled: !codeSent,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: tr('email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (codeSent) ...[
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: tr('recovery_code'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: tr('new_password'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : (codeSent ? resetPassword : sendCode),
                  child: Text(
                    loading
                        ? tr('please_wait')
                        : (codeSent ? tr('change_password') : tr('send_recovery_code')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
