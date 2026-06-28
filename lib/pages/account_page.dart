import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';

import 'ad_detail_page.dart';
import 'auth_page.dart';
import 'chat_list_page.dart';
import 'create_ad_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void refresh() {
    if (mounted) setState(() {});
  }

  String accountContactText() {
    final email = Session.currentUser?["email"]?.toString().trim() ?? "";
    final phone = Session.userPhone.trim();

    if (email.isNotEmpty) return email;
    if (phone.startsWith("email_")) return "ایمیل ثبت شده";
    if (phone.isNotEmpty) return phone;

    return "اطلاعات تماس ثبت نشده";
  }

  Future<void> openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );

    if (result == true) refresh();
  }

  Future<void> logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("خروج از حساب"),
            content: const Text("آیا مطمئن هستید که می‌خواهید خارج شوید؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("لغو"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("خروج"),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    await Session.logout();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("از حساب خارج شدید")),
    );

    setState(() {});
  }

  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    final logged = Session.isLoggedIn;
    final name = Session.userFullName;
    final contact = accountContactText();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("حساب من"),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Colors.deepPurple,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logged
                              ? (name.isEmpty ? "کاربر HeratBazar" : name)
                              : "وارد حساب نشده‌اید",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          logged ? contact : "برای استفاده کامل وارد شوید",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (!logged)
              _AccountTile(
                icon: Icons.login,
                color: Colors.green,
                title: "ورود / ثبت‌نام",
                subtitle: "ورود به حساب یا ساخت حساب جدید",
                onTap: openLogin,
              ),

            if (logged)
              _AccountTile(
                icon: Icons.person,
                color: Colors.deepPurple,
                title: "پروفایل",
                subtitle: "مشاهده اطلاعات حساب",
                onTap: () => openPage(const ProfileSectionPage()),
              ),

            if (logged)
              _AccountTile(
                icon: Icons.list_alt,
                color: Colors.blue,
                title: "آگهی‌های من",
                subtitle: "مدیریت، ویرایش و حذف آگهی‌های شما",
                onTap: () => openPage(const MyAdsSectionPage()),
              ),

            if (logged)
              _AccountTile(
                icon: Icons.chat,
                color: Colors.orange,
                title: "پیام‌ها",
                subtitle: "گفتگوهای خرید و فروش",
                onTap: () => openPage(const ChatListPage()),
              ),

            _AccountTile(
              icon: Icons.add_circle,
              color: Colors.green,
              title: "ثبت آگهی",
              subtitle: "ثبت کالا، خدمات یا ملک برای فروش",
              onTap: () => openPage(const CreateAdPage()),
            ),

            _AccountTile(
              icon: Icons.security,
              color: Colors.red,
              title: "راهنمای امنیت",
              subtitle: "جلوگیری از کلاهبرداری و معامله امن",
              onTap: () => openPage(const SafetyGuidePage()),
            ),

            _AccountTile(
              icon: Icons.settings,
              color: Colors.grey,
              title: "تنظیمات",
              subtitle: "تنظیمات برنامه",
              onTap: () => openPage(const SettingsSectionPage()),
            ),

            if (logged)
              _AccountTile(
                icon: Icons.logout,
                color: Colors.red,
                title: "خروج",
                subtitle: "خروج از حساب فعلی",
                onTap: logout,
              ),
          ],
        ),
      ),
    );
  }
}
class _AccountTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class ProfileSectionPage extends StatelessWidget {
  const ProfileSectionPage({super.key});

  String contactValue() {
    final email = Session.currentUser?["email"]?.toString().trim() ?? "";
    final phone = Session.userPhone.trim();

    if (email.isNotEmpty) return email;
    if (phone.startsWith("email_")) return "ایمیل ثبت شده";
    if (phone.isNotEmpty) return phone;

    return "";
  }

  String contactTitle() {
    final email = Session.currentUser?["email"]?.toString().trim() ?? "";
    if (email.isNotEmpty) return "ایمیل";
    return "شماره";
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("پروفایل"),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(
              radius: 46,
              child: Icon(Icons.person, size: 54),
            ),
            const SizedBox(height: 18),
            _InfoRow(title: "نام", value: user["first_name"]?.toString() ?? ""),
            _InfoRow(
              title: "نام خانوادگی",
              value: user["last_name"]?.toString() ?? "",
            ),
            _InfoRow(title: contactTitle(), value: contactValue()),
            _InfoRow(title: "شناسه کاربر", value: Session.userId?.toString() ?? ""),
          ],
        ),
      ),
    );
  }
}

class MyAdsSectionPage extends StatefulWidget {
  const MyAdsSectionPage({super.key});

  @override
  State<MyAdsSectionPage> createState() => _MyAdsSectionPageState();
}

class _MyAdsSectionPageState extends State<MyAdsSectionPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = loadMyAds();
  }

  Future<List<dynamic>> loadMyAds() async {
    final ads = await Api.getAds();
    final myId = Session.userId;

    return ads.where((ad) {
      if (ad is! Map) return false;
      final adUserId = int.tryParse(ad["user_id"]?.toString() ?? "");
      return myId != null && adUserId == myId;
    }).toList();
  }

  Future<void> refresh() async {
    setState(() {
      future = loadMyAds();
    });
  }

  String textOf(dynamic ad, String key) {
    if (ad is! Map) return "";
    return ad[key]?.toString() ?? "";
  }

  void openAd(dynamic ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailPage(ad: Map.from(ad)),
      ),
    ).then((result) {
      if (result == true) refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("آگهی‌های من"),
          centerTitle: true,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString().replaceAll("Exception:", "").trim(),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final ads = snapshot.data ?? [];

            if (ads.isEmpty) {
              return const Center(
                child: Text("شما هنوز آگهی ثبت نکرده‌اید"),
              );
            }

            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView.separated(
                itemCount: ads.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  final title = textOf(ad, "title");
                  final price = textOf(ad, "price");
                  final image = Api.fullImageUrl(textOf(ad, "image_url"));

                  return ListTile(
                    leading: image.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.image))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const CircleAvatar(
                                  child: Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                    title: Text(
                      title.isEmpty ? "بدون عنوان" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      price.isEmpty || price == "0"
                          ? "قیمت توافقی"
                          : "$price AFN",
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => openAd(ad),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تنظیمات"),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _InfoRow(title: "زبان", value: "فارسی / دری"),
            _InfoRow(title: "نسخه", value: "1.0.0"),
            SizedBox(height: 20),
            Text(
              "تنظیمات بیشتر بعداً اضافه می‌شود.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyGuidePage extends StatelessWidget {
  const SafetyGuidePage({super.key});

  Widget section({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "• $item",
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("راهنمای امنیت"),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.withOpacity(0.35)),
              ),
              child: const Text(
                "⛔ افغانستان بازار هیچ‌وقت از شما کردیت موبایل، رمز کارت، کد تأیید، بیعانه یا پرداخت قبل از دیدن کالا درخواست نمی‌کند.",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            section(
              icon: Icons.warning,
              color: Colors.orange,
              title: "نشانه‌های کلاهبرداری",
              items: [
                "قیمت بسیار پایین‌تر از بازار",
                "عجله برای گرفتن پول یا تحویل کالا",
                "درخواست بیعانه قبل از دیدن کالا",
                "درخواست ارسال کردیت موبایل",
                "ارسال لینک پرداخت ناشناس",
                "رسید بانکی یا اسکرین‌شات جعلی",
                "درخواست رمز کارت، رمز پویا یا کد تأیید",
                "خودداری از ملاقات حضوری",
                "انتقال گفتگو به بیرون از برنامه برای پرداخت مشکوک",
              ],
            ),

            section(
              icon: Icons.mobile_friendly,
              color: Colors.red,
              title: "کردیت موبایل نفرستید",
              items: [
                "برای هیچ‌کس کردیت MTN، Roshan، Etisalat، AWCC یا Salaam نفرستید.",
                "درخواست کردیت معمولاً نشانه کلاهبرداری است.",
                "کردیت ارسال‌شده قابل برگشت نیست.",
                "اگر کسی گفت اول کردیت بفرست تا کالا را نگه دارم، معامله را قطع کنید.",
              ],
            ),

            section(
              icon: Icons.shopping_bag,
              color: Colors.green,
              title: "خرید امن",
              items: [
                "تا حد امکان حضوری معامله کنید.",
                "قبل از پرداخت، کالا را کامل بررسی کنید.",
                "تا وقتی کالا را ندیده‌اید، پول یا بیعانه نفرستید.",
                "به عکس، ویدیو یا وعده فروشنده به تنهایی اعتماد نکنید.",
                "در مکان عمومی و امن معامله کنید.",
              ],
            ),

            section(
              icon: Icons.sell,
              color: Colors.blue,
              title: "فروش امن",
              items: [
                "قبل از اطمینان از دریافت پول، کالا را تحویل ندهید.",
                "به رسید بانکی یا پیامک جعلی اعتماد نکنید.",
                "موجودی حساب خود را مستقیم بررسی کنید.",
                "اگر خریدار عجله یا فشار آورد، معامله را متوقف کنید.",
              ],
            ),

            section(
              icon: Icons.report,
              color: Colors.deepPurple,
              title: "اگر مشکوک شدید",
              items: [
                "معامله را فوراً متوقف کنید.",
                "آگهی را گزارش دهید.",
                "با پشتیبانی تماس بگیرید.",
                "در صورت ضرر مالی، موضوع را به مراجع قانونی گزارش دهید.",
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              "توجه: افغانستان بازار فقط بستر نشر آگهی و ارتباط کاربران است. مسئولیت بررسی کالا، پرداخت، تحویل، توافقات مالی و هرگونه ضرر یا کلاهبرداری بر عهده خریدار و فروشنده است. افغانستان بازار مسئولیتی در قبال معاملات خارج از برنامه، پرداخت اشتباه، ارسال کردیت، بیعانه، رسید جعلی یا کلاهبرداری کاربران ندارد.",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value.isEmpty ? "ثبت نشده" : value),
      ),
    );
  }
}