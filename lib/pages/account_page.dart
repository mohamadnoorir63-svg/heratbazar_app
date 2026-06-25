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

  Future<void> openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );

    if (result == true) refresh();
  }

  Future<void> logout() async {
    await Session.logout();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("از حساب خارج شدید")),
    );

    Navigator.pop(context, true);
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
    final phone = Session.userPhone;

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
                          logged ? phone : "برای استفاده کامل وارد شوید",
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
            _InfoRow(title: "شماره", value: Session.userPhone),
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