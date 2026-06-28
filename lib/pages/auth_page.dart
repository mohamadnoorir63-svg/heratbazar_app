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

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> loginPhone() async {
    if (loading) return;

    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      showMessage("شماره و کد ورود را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.login(phone: phone, loginCode: code);

      if (!mounted) return;
      showMessage("ورود موفق شد");
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> loginEmail() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage("ایمیل و رمز عبور را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.loginEmail(email: email, password: password);

      if (!mounted) return;
      showMessage("ورود ایمیلی موفق شد");
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
              icon: Icon(hideCode ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => hideCode = !hideCode),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : openForgotCode,
          child: const Text("کد را فراموش کرده‌ام"),
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
          decoration: const InputDecoration(
            labelText: "ایمیل",
            hintText: "example@gmail.com",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: hidePassword,
          decoration: InputDecoration(
            labelText: "رمز عبور",
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
          child: const Text("رمز عبور ایمیل را فراموش کرده‌ام"),
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
        appBar: AppBar(title: const Text("ورود به حساب"), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(isPhone ? Icons.phone_android : Icons.email,
                  size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Row(
                children: [
                  modeButton(AuthMode.phoneLogin, "شماره", Icons.phone),
                  const SizedBox(width: 8),
                  modeButton(AuthMode.emailLogin, "ایمیل", Icons.email),
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
                  child: Text(loading ? "در حال ورود..." : "ورود"),
                ),
              ),
              const SizedBox(height: 12),
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

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> registerEmail() async {
    if (loading) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showMessage("نام، نام خانوادگی، ایمیل و رمز عبور را وارد کنید");
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      showMessage("ایمیل معتبر وارد کنید");
      return;
    }

    if (password.length < 6) {
      showMessage("رمز عبور باید حداقل ۶ حرف باشد");
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
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(email: email),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
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
        appBar: AppBar(title: const Text("ثبت‌نام"), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                isPhone ? Icons.person_add : Icons.mark_email_read,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  modeButton(RegisterMode.phone, "شماره", Icons.phone),
                  const SizedBox(width: 8),
                  modeButton(RegisterMode.email, "ایمیل", Icons.email),
                ],
              ),
              const SizedBox(height: 18),
              field(firstNameController, "نام"),
              field(lastNameController, "نام خانوادگی"),
              if (isPhone) ...[
                field(phoneController, "شماره تلفن", type: TextInputType.phone),
                field(securityAnswerController, "نام اولین معلم شما چیست؟"),
              ] else ...[
                field(
                  emailController,
                  "ایمیل",
                  type: TextInputType.emailAddress,
                ),
                field(
                  passwordController,
                  "رمز عبور",
                  obscure: hidePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : (isPhone ? registerPhone : registerEmail),
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

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final codeController = TextEditingController();
  bool loading = false;

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> verify() async {
    if (loading) return;

    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage("کد ایمیل را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      showMessage("ایمیل تأیید شد");
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> resend() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      await Api.resendEmailCode(email: widget.email);

      if (!mounted) return;
      showMessage("کد دوباره ارسال شد");
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
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
        appBar: AppBar(title: const Text("تأیید ایمیل"), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.verified_user, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                "کد تأیید به ایمیل زیر ارسال شد:\n${widget.email}",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: "کد تأیید ایمیل",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : verify,
                  child: Text(loading ? "در حال تأیید..." : "تأیید ایمیل"),
                ),
              ),
              TextButton(
                onPressed: loading ? null : resend,
                child: const Text("ارسال دوباره کد"),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
        appBar: AppBar(title: const Text("فراموشی کد ورود"), centerTitle: true),
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

class ForgotEmailPasswordPage extends StatefulWidget {
  const ForgotEmailPasswordPage({super.key});

  @override
  State<ForgotEmailPasswordPage> createState() =>
      _ForgotEmailPasswordPageState();
}

class _ForgotEmailPasswordPageState extends State<ForgotEmailPasswordPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool codeSent = false;
  bool hidePassword = true;

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> sendCode() async {
    if (loading) return;

    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("ایمیل را وارد کنید");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.forgotPasswordEmail(email: email);

      if (!mounted) return;

      setState(() => codeSent = true);
      showMessage("کد بازیابی به ایمیل ارسال شد");
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> resetPassword() async {
    if (loading) return;

    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || code.isEmpty || password.isEmpty) {
      showMessage("ایمیل، کد و رمز جدید را وارد کنید");
      return;
    }

    if (password.length < 6) {
      showMessage("رمز جدید باید حداقل ۶ حرف باشد");
      return;
    }

    setState(() => loading = true);

    try {
      await Api.resetPasswordEmail(
        email: email,
        code: code,
        password: password,
      );

      if (!mounted) return;

      showMessage("رمز عبور تغییر کرد، حالا وارد شوید");
      Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
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
        appBar: AppBar(title: const Text("بازیابی رمز ایمیل"), centerTitle: true),
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
                decoration: const InputDecoration(
                  labelText: "ایمیل",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (codeSent) ...[
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: "کد بازیابی",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: "رمز عبور جدید",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : (codeSent ? resetPassword : sendCode),
                  child: Text(
                    loading
                        ? "لطفاً صبر کنید..."
                        : (codeSent ? "تغییر رمز عبور" : "ارسال کد بازیابی"),
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