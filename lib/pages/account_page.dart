import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/lang.dart';

import 'ad_detail_page.dart';
import 'auth_page.dart';
import 'chat_list_page.dart';
import 'create_ad_page.dart';
import 'main_shell_page.dart';

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
    if (phone.startsWith("email_")) return T.tr("email_registered");
    if (phone.isNotEmpty) return phone;

    return T.tr("contact_not_set");
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
            title: Text(T.tr("logout_title")),
            content: Text(T.tr("logout_confirm")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(T.tr("cancel")),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text(T.tr("logout")),
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
      SnackBar(content: Text(T.tr("logout_done"))),
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
          title: Text(T.tr("account")),
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
                              ? (name.isEmpty ? T.tr("user_heratbazar") : name)
                              : T.tr("not_logged_in"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          logged ? contact : T.tr("use_full"),
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
                title: T.tr("login_register"),
                subtitle: T.tr("login_register_sub"),
                onTap: openLogin,
              ),

            if (logged)
              _AccountTile(
                icon: Icons.person,
                color: Colors.deepPurple,
                title: T.tr("profile"),
                subtitle: T.tr("profile_sub"),
                onTap: () => openPage(const ProfileSectionPage()),
              ),

            if (logged)
              _AccountTile(
                icon: Icons.list_alt,
                color: Colors.blue,
                title: T.tr("my_ads"),
                subtitle: T.tr("my_ads_sub"),
                onTap: () => openPage(const MyAdsSectionPage()),
              ),

            if (logged)
              _AccountTile(
                icon: Icons.chat,
                color: Colors.orange,
                title: T.tr("messages"),
                subtitle: T.tr("messages_sub"),
                onTap: () => openPage(const ChatListPage()),
              ),

            _AccountTile(
              icon: Icons.add_circle,
              color: Colors.green,
              title: T.tr("post_ad"),
              subtitle: T.tr("post_ad_sub"),
              onTap: () => openPage(const CreateAdPage()),
            ),

            _AccountTile(
              icon: Icons.security,
              color: Colors.red,
              title: T.tr("safety_guide"),
              subtitle: T.tr("safety_guide_sub"),
              onTap: () => openPage(const SafetyGuidePage()),
            ),

            _AccountTile(
              icon: Icons.settings,
              color: Colors.grey,
              title: T.tr("settings"),
              subtitle: T.tr("settings_sub"),
              onTap: () => openPage(const SettingsSectionPage()),
            ),

            if (logged)
              _AccountTile(
                icon: Icons.logout,
                color: Colors.red,
                title: T.tr("logout"),
                subtitle: T.tr("logout_sub"),
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
    if (phone.startsWith("email_")) return T.tr("email_registered");
    if (phone.isNotEmpty) return phone;

    return "";
  }

  String contactTitle() {
    final email = Session.currentUser?["email"]?.toString().trim() ?? "";
    if (email.isNotEmpty) return T.tr("email");
    return T.tr("phone");
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(T.tr("profile")),
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
            _InfoRow(
              title: T.tr("first_name"),
              value: user["first_name"]?.toString() ?? "",
            ),
            _InfoRow(
              title: T.tr("last_name"),
              value: user["last_name"]?.toString() ?? "",
            ),
            _InfoRow(title: contactTitle(), value: contactValue()),
            _InfoRow(
              title: T.tr("user_id"),
              value: Session.userId?.toString() ?? "",
            ),
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
          title: Text(T.tr("my_ads")),
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
              return Center(
                child: Text(T.tr("my_ads_empty")),
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
                      title.isEmpty ? T.tr("no_title") : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      price.isEmpty || price == "0"
                          ? T.tr("negotiable_price")
                          : "$price ${T.tr("afghani")}",
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

class SettingsSectionPage extends StatefulWidget {
  const SettingsSectionPage({super.key});

  @override
  State<SettingsSectionPage> createState() => _SettingsSectionPageState();
}

class _SettingsSectionPageState extends State<SettingsSectionPage> {
  Future<void> changeLanguage(String value) async {
    await T.set(value);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShellPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(T.tr("settings")),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: RadioListTile<String>(
                value: "fa",
                groupValue: T.lang,
                onChanged: (v) {
                  if (v != null) changeLanguage(v);
                },
                title: Text(T.tr("dari")),
                subtitle: Text(T.tr("dari_subtitle")),
              ),
            ),
            Card(
              child: RadioListTile<String>(
                value: "ps",
                groupValue: T.lang,
                onChanged: (v) {
                  if (v != null) changeLanguage(v);
                },
                title: Text(T.tr("pashto")),
                subtitle: Text(T.tr("pashto_subtitle")),
              ),
            ),
            _InfoRow(title: T.tr("version"), value: "1.0.0"),
            const SizedBox(height: 20),
            Text(
              T.tr("more_settings_soon"),
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
          title: Text(T.tr("safety_guide")),
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
              child: Text(
                T.tr("safety_warning"),
                textAlign: TextAlign.right,
                style: const TextStyle(
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
              title: T.tr("scam_signs"),
              items: [
                T.tr("scam_1"),
                T.tr("scam_2"),
                T.tr("scam_3"),
                T.tr("scam_4"),
                T.tr("scam_5"),
                T.tr("scam_6"),
                T.tr("scam_7"),
                T.tr("scam_8"),
                T.tr("scam_9"),
              ],
            ),

            section(
              icon: Icons.mobile_friendly,
              color: Colors.red,
              title: T.tr("credit_warning"),
              items: [
                T.tr("credit_1"),
                T.tr("credit_2"),
                T.tr("credit_3"),
                T.tr("credit_4"),
              ],
            ),

            section(
              icon: Icons.shopping_bag,
              color: Colors.green,
              title: T.tr("safe_buying"),
              items: [
                T.tr("buy_1"),
                T.tr("buy_2"),
                T.tr("buy_3"),
                T.tr("buy_4"),
                T.tr("buy_5"),
              ],
            ),

            section(
              icon: Icons.sell,
              color: Colors.blue,
              title: T.tr("safe_selling"),
              items: [
                T.tr("sell_1"),
                T.tr("sell_2"),
                T.tr("sell_3"),
                T.tr("sell_4"),
              ],
            ),

            section(
              icon: Icons.report,
              color: Colors.deepPurple,
              title: T.tr("if_suspicious"),
              items: [
                T.tr("sus_1"),
                T.tr("sus_2"),
                T.tr("sus_3"),
                T.tr("sus_4"),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              T.tr("safety_note"),
              textAlign: TextAlign.right,
              style: const TextStyle(
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
        subtitle: Text(value.isEmpty ? T.tr("not_set") : value),
      ),
    );
  }
}