import 'package:flutter/material.dart';

import '../core/api.dart';
import 'ad_detail_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int selectedTab = 0;
  bool loading = false;

  String userSearchText = "";
  String adSearchText = "";
  String chatSearchText = "";
  String reportStatus = "all";
  String adStatusFilter = "all";
  String userStatusFilter = "all";

  int? selectedUserAdsFilterId;
  String selectedUserAdsFilterName = "";

  late Future<Map<String, dynamic>> statsFuture;
  late Future<List<dynamic>> usersFuture;
  late Future<List<dynamic>> adsFuture;
  late Future<List<dynamic>> reportsFuture;
  late Future<List<dynamic>> chatsFuture;
  late Future<List<dynamic>> notificationsFuture;
  late Future<List<dynamic>> paymentsFuture;
  late Future<Map<String, dynamic>> settingsFuture;
  late Future<List<dynamic>> auditLogsFuture;
  late Future<List<dynamic>> blockedWordsFuture;
  late Future<List<dynamic>> devicesFuture;
  late Future<List<dynamic>> onlineUsersFuture;

  final userSearchController = TextEditingController();
  final adSearchController = TextEditingController();
  final chatSearchController = TextEditingController();

  final notificationTitleController = TextEditingController();
  final notificationBodyController = TextEditingController();

  final paymentUserIdController = TextEditingController();
  final paymentAdIdController = TextEditingController();
  final paymentAmountController = TextEditingController();
  final paymentNoteController = TextEditingController();

  final settingKeyController = TextEditingController();
  final settingValueController = TextEditingController();

  final blockedWordController = TextEditingController();
  final blockedWordTypeController = TextEditingController(text: "general");

  @override
  void initState() {
    super.initState();
    reloadAll();
  }

  void reloadAll() {
    statsFuture = Api.getAdminAdvancedStats();
    usersFuture = Api.getAdminUsers();
    adsFuture = Api.getAds();
    reportsFuture = Api.getAdminReports(status: reportStatus);
    chatsFuture = Api.getAdminAdvancedChats(q: chatSearchText);
    notificationsFuture = Api.getAdminNotifications();
    paymentsFuture = Api.getAdminPayments();
    settingsFuture = Api.getAdminSettings();
    auditLogsFuture = Api.getAdminAuditLogs();
    blockedWordsFuture = Api.getBlockedWords();
    devicesFuture = Api.getAdminDevices();
    onlineUsersFuture = Api.getAdminOnlineUsers();
  }

  Future<void> reload() async {
    setState(() {
      reloadAll();
    });
  }

  @override
  void dispose() {
    userSearchController.dispose();
    adSearchController.dispose();
    chatSearchController.dispose();
    notificationTitleController.dispose();
    notificationBodyController.dispose();
    paymentUserIdController.dispose();
    paymentAdIdController.dispose();
    paymentAmountController.dispose();
    paymentNoteController.dispose();
    settingKeyController.dispose();
    settingValueController.dispose();
    blockedWordController.dispose();
    blockedWordTypeController.dispose();
    super.dispose();
  }

  String textOf(dynamic item, String key) {
    if (item is! Map) return "";
    return item[key]?.toString() ?? "";
  }

  int intOf(dynamic item, String key) {
    return int.tryParse(textOf(item, key)) ?? 0;
  }

  bool boolOf(dynamic item, String key) {
    final value = textOf(item, key).toLowerCase();
    return value == "1" || value == "true" || value == "yes";
  }

  String cleanError(Object e) {
    return e.toString().replaceAll("Exception:", "").trim();
  }

  bool isMuted(dynamic user) {
    final mutedUntil = textOf(user, "muted_until");
    if (mutedUntil.isEmpty || mutedUntil == "null") return false;
    final dt = DateTime.tryParse(mutedUntil);
    if (dt == null) return true;
    return dt.toLocal().isAfter(DateTime.now());
  }

  Color statusColor(String status) {
    final s = status.toLowerCase();
    if (s == "pending") return Colors.orange;
    if (s == "approved") return Colors.green;
    if (s == "reviewed") return Colors.green;
    if (s == "rejected") return Colors.red;
    if (s == "dismissed") return Colors.red;
    if (s == "paid") return Colors.green;
    if (s == "failed") return Colors.red;
    if (s == "hidden") return Colors.pink;
    return Colors.grey;
  }

  String statusFa(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "در انتظار";
      case "approved":
        return "تأیید شده";
      case "reviewed":
        return "بررسی شده";
      case "rejected":
        return "رد شده";
      case "dismissed":
        return "رد گزارش";
      case "paid":
        return "پرداخت شده";
      case "failed":
        return "ناموفق";
      case "all":
        return "همه";
      default:
        return status.isEmpty ? "نامشخص" : status;
    }
  }

  dynamic statValue(Map<String, dynamic> stats, List<String> keys) {
    for (final key in keys) {
      if (stats[key] != null) return stats[key];
    }
    return 0;
  }

  String userDisplayName(dynamic user) {
    final firstName = textOf(user, "first_name");
    final lastName = textOf(user, "last_name");
    final name = textOf(user, "name");

    if (name.isNotEmpty) return name;

    final fullName = "$firstName $lastName".trim();
    if (fullName.isNotEmpty) return fullName;

    return "کاربر بدون نام";
  }

  Widget smallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(left: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        onPressed: loading ? null : onTap,
        icon: Icon(icon, size: 16),
        label: Text(text),
      ),
    );
  }

  Future<bool> askConfirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("لغو"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("تأیید"),
              ),
            ],
          ),
        );
      },
    );

    return ok == true;
  }

  Future<String?> askText({
    required String title,
    required String label,
    String initial = "",
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initial);

    final value = await showDialog<String>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لغو"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text("ثبت"),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return value;
  }

  Future<Map<String, int>?> askPinOptions() async {
    final daysController = TextEditingController(text: "7");
    final positionController = TextEditingController(text: "1");

    final value = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("پن پیشرفته آگهی"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: positionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "جایگاه پن؛ مثلاً 1 تا 20",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "مدت پن به روز",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لغو"),
              ),
              FilledButton(
                onPressed: () {
                  final position =
                      int.tryParse(positionController.text.trim()) ?? 1;
                  final days = int.tryParse(daysController.text.trim()) ?? 7;
                  Navigator.pop(context, {
                    "position": position,
                    "days": days,
                  });
                },
                child: const Text("پن کن"),
              ),
            ],
          ),
        );
      },
    );

    daysController.dispose();
    positionController.dispose();
    return value;
  }

  Future<int?> askMuteDays() async {
    final controller = TextEditingController(text: "1");

    final value = await showDialog<int>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("سکوت کاربر"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "مدت سکوت به روز",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لغو"),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    int.tryParse(controller.text.trim()) ?? 1,
                  );
                },
                child: const Text("اعمال سکوت"),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return value;
  }

  Future<void> runAction(
    Future<void> Function() action,
    String successMessage, {
    String? auditAction,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
  }) async {
    if (loading) return;

    setState(() => loading = true);

    try {
      await action();

      if (auditAction != null) {
        try {
          await Api.createAdminAuditLog(
            action: auditAction,
            targetType: targetType,
            targetId: targetId,
            details: details,
          );
        } catch (_) {}
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );

      await reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget tabButton(int index, IconData icon, String title) {
    final selected = selectedTab == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : Colors.deepPurple,
        ),
        selectedColor: Colors.deepPurple,
        label: Text(title),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          setState(() => selectedTab = index);
        },
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Text(
        "پنل مدیریت حرفه‌ای",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          tabButton(0, Icons.dashboard, "داشبورد"),
          tabButton(1, Icons.people, "کاربران"),
          tabButton(2, Icons.campaign, "آگهی‌ها"),
          tabButton(3, Icons.report, "گزارش‌ها"),
          tabButton(4, Icons.chat, "پیام‌ها"),
          tabButton(5, Icons.notifications, "اعلان‌ها"),
          tabButton(6, Icons.payment, "پرداخت‌ها"),
          tabButton(7, Icons.block, "کلمات ممنوعه"),
          tabButton(8, Icons.devices, "دستگاه‌ها"),
          tabButton(9, Icons.settings, "تنظیمات"),
          tabButton(10, Icons.history, "لاگ‌ها"),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (selectedTab == 0) return buildDashboard();
    if (selectedTab == 1) return buildUsers();
    if (selectedTab == 2) return buildAds();
    if (selectedTab == 3) return buildReports();
    if (selectedTab == 4) return buildChats();
    if (selectedTab == 5) return buildNotifications();
    if (selectedTab == 6) return buildPayments();
    if (selectedTab == 7) return buildBlockedWords();
    if (selectedTab == 8) return buildDevices();
    if (selectedTab == 9) return buildSettings();
    if (selectedTab == 10) return buildAuditLogs();

    return const Center(child: Text("بخش نامعتبر"));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff7f4fb),
        body: Column(
          children: [
            buildHeader(),
            buildTabs(),
            if (loading) const LinearProgressIndicator(),
            Expanded(child: buildBody()),
          ],
        ),
      ),
    );
  }

  Widget buildDashboard() {
    return RefreshIndicator(
      onRefresh: reload,
      child: FutureBuilder<Map<String, dynamic>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(cleanError(snapshot.error!)));
          }

          final stats = snapshot.data ?? {};

          Widget dashboardRow({
            required String title,
            required dynamic value,
            required IconData icon,
            required Color color,
          }) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "$value",
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              dashboardRow(
                title: "کاربران",
                value: statValue(stats, ["users", "users_count", "total_users"]),
                icon: Icons.people,
                color: Colors.blue,
              ),
              dashboardRow(
                title: "کاربران آنلاین",
                value: statValue(stats, ["online_users", "online_count"]),
                icon: Icons.online_prediction,
                color: Colors.green,
              ),
              dashboardRow(
                title: "کاربران مسدود",
                value: statValue(stats, ["banned_users", "banned_count"]),
                icon: Icons.block,
                color: Colors.red,
              ),
              dashboardRow(
                title: "کاربران ویژه",
                value: statValue(stats, ["premium_users", "premium_users_count"]),
                icon: Icons.workspace_premium,
                color: Colors.teal,
              ),
              dashboardRow(
                title: "آگهی‌ها",
                value: statValue(stats, ["ads", "ads_count", "total_ads"]),
                icon: Icons.campaign,
                color: Colors.green,
              ),
              dashboardRow(
                title: "آگهی‌های منتظر بررسی",
                value: statValue(stats, ["pending_ads", "pending_count"]),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              dashboardRow(
                title: "آگهی‌های رد شده",
                value: statValue(stats, ["rejected_ads", "rejected_count"]),
                icon: Icons.cancel,
                color: Colors.redAccent,
              ),
              dashboardRow(
                title: "آگهی‌های مخفی",
                value: statValue(stats, ["hidden_ads", "hidden_count"]),
                icon: Icons.visibility_off,
                color: Colors.pink,
              ),
              dashboardRow(
                title: "آگهی‌های ویژه",
                value: statValue(stats, ["featured_ads", "featured_count"]),
                icon: Icons.star,
                color: Colors.deepPurple,
              ),
              dashboardRow(
                title: "گزارش‌های منتظر",
                value: statValue(stats, ["pending_reports", "reports", "total_reports"]),
                icon: Icons.report,
                color: Colors.deepOrange,
              ),
              dashboardRow(
                title: "درآمد کل",
                value: "${statValue(stats, ["total_income", "income"])} AFN",
                icon: Icons.payments,
                color: Colors.indigo,
              ),
            ],
          );
        },
      ),
    );
  }

  List<dynamic> filterUsers(List<dynamic> users) {
    final q = userSearchText.trim().toLowerCase();

    return users.where((user) {
      if (user is! Map) return false;

      final banned = boolOf(user, "is_banned") || boolOf(user, "banned");
      final verified = boolOf(user, "is_verified");
      final premium = boolOf(user, "is_premium");
      final muted = isMuted(user);

      if (userStatusFilter == "banned" && !banned) return false;
      if (userStatusFilter == "verified" && !verified) return false;
      if (userStatusFilter == "premium" && !premium) return false;
      if (userStatusFilter == "muted" && !muted) return false;

      if (q.isEmpty) return true;

      final text = [
        textOf(user, "id"),
        textOf(user, "first_name"),
        textOf(user, "last_name"),
        textOf(user, "name"),
        textOf(user, "phone"),
        textOf(user, "email"),
        textOf(user, "role"),
      ].join(" ").toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> openUserAds(dynamic user) async {
    final userId = intOf(user, "id");
    final name = userDisplayName(user);

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("شناسه کاربر موجود نیست")),
      );
      return;
    }

    setState(() {
      selectedTab = 2;
      selectedUserAdsFilterId = userId;
      selectedUserAdsFilterName = name;
      adSearchText = "";
      adSearchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("آگهی‌های $name نمایش داده شد")),
    );
  }

  void clearUserAdsFilter() {
    setState(() {
      selectedUserAdsFilterId = null;
      selectedUserAdsFilterName = "";
      adSearchText = "";
      adSearchController.clear();
    });
  }

  Widget buildUsers() {
    return FutureBuilder<List<dynamic>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(cleanError(snapshot.error!)));
        }

        final users = filterUsers(snapshot.data ?? []);

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    TextField(
                      controller: userSearchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: "جستجو با نام، شماره، ایمیل یا شناسه",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          userSearchText = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: userStatusFilter,
                      decoration: InputDecoration(
                        labelText: "فیلتر کاربر",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("همه")),
                        DropdownMenuItem(value: "banned", child: Text("مسدود")),
                        DropdownMenuItem(value: "verified", child: Text("تأیید شده")),
                        DropdownMenuItem(value: "premium", child: Text("پریمیوم")),
                        DropdownMenuItem(value: "muted", child: Text("سکوت زده")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => userStatusFilter = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (users.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: Text("کاربری پیدا نشد")),
                      ),
                  ],
                );
              }

              final user = users[index - 1];
              return buildUserCard(user);
            },
          ),
        );
      },
    );
  }

  Widget buildUserCard(dynamic user) {
    final id = intOf(user, "id");
    final name = userDisplayName(user);

    final phone = textOf(user, "phone");
    final email = textOf(user, "email");
    final role = textOf(user, "role");
    final city = textOf(user, "city");
    final lastSeen = textOf(user, "last_seen");
    final mutedUntil = textOf(user, "muted_until");

    final isBanned = boolOf(user, "is_banned") || boolOf(user, "banned");
    final isVerified = boolOf(user, "is_verified");
    final isBlue = boolOf(user, "is_blue_verified");
    final isPremium = boolOf(user, "is_premium");
    final muted = isMuted(user);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openUserAds(user),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  CircleAvatar(
                    backgroundColor: isBanned ? Colors.red : Colors.deepPurple,
                    child: Text(
                      id == 0 ? "U" : id.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isBlue)
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (phone.isNotEmpty) Text("شماره: $phone"),
                        if (email.isNotEmpty) Text("ایمیل: $email"),
                        if (city.isNotEmpty) Text("شهر: $city"),
                        if (lastSeen.isNotEmpty) Text("آخرین بازدید: $lastSeen"),
                        if (muted) Text("سکوت تا: $mutedUntil"),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  smallChip(role.isEmpty ? "user" : role, Colors.deepPurple),
                  if (isBanned) smallChip("مسدود", Colors.red),
                  if (isVerified) smallChip("تأیید شده", Colors.green),
                  if (isBlue) smallChip("تیک آبی", Colors.blue),
                  if (isPremium) smallChip("پریمیوم", Colors.orange),
                  if (muted) smallChip("سکوت زده", Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  actionButton(
                    text: "آگهی‌های کاربر",
                    icon: Icons.campaign,
                    color: Colors.deepPurple,
                    onTap: () => openUserAds(user),
                  ),
                  actionButton(
                    text: isBanned ? "رفع مسدودی" : "مسدود",
                    icon: isBanned ? Icons.lock_open : Icons.block,
                    color: isBanned ? Colors.green : Colors.red,
                    onTap: () {
                      if (id == 0) return;
                      if (isBanned) {
                        handleUnbanUser(id);
                      } else {
                        handleBanUser(id);
                      }
                    },
                  ),
                  actionButton(
                    text: muted ? "رفع سکوت" : "سکوت",
                    icon: muted ? Icons.record_voice_over : Icons.volume_off,
                    color: muted ? Colors.green : Colors.blueGrey,
                    onTap: () {
                      if (id == 0) return;
                      if (muted) {
                        handleUnmuteUser(id);
                      } else {
                        handleMuteUser(id);
                      }
                    },
                  ),
                  actionButton(
                    text: isVerified ? "لغو تأیید" : "تأیید",
                    icon: isVerified ? Icons.cancel : Icons.check_circle,
                    color: isVerified ? Colors.grey : Colors.green,
                    onTap: () {
                      if (id == 0) return;
                      if (isVerified) {
                        handleUnverifyUser(id);
                      } else {
                        handleVerifyUser(id);
                      }
                    },
                  ),
                  actionButton(
                    text: isBlue ? "لغو تیک آبی" : "تیک آبی",
                    icon: Icons.verified,
                    color: Colors.blue,
                    onTap: () {
                      if (id == 0) return;
                      if (isBlue) {
                        handleUnblueUser(id);
                      } else {
                        handleBlueUser(id);
                      }
                    },
                  ),
                  actionButton(
                    text: isPremium ? "لغو پریمیوم" : "پریمیوم",
                    icon: Icons.workspace_premium,
                    color: Colors.orange,
                    onTap: () {
                      if (id == 0) return;
                      if (isPremium) {
                        handleUnpremiumUser(id);
                      } else {
                        handlePremiumUser(id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleBanUser(int id) async {
    final ok = await askConfirm(
      "مسدود کردن کاربر",
      "آیا این کاربر مسدود شود؟",
    );
    if (!ok) return;

    await runAction(
      () => Api.banUser(id, "blocked by admin"),
      "کاربر مسدود شد",
      auditAction: "ban_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleUnbanUser(int id) async {
    await runAction(
      () => Api.unbanUser(id),
      "مسدودی کاربر برداشته شد",
      auditAction: "unban_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleMuteUser(int id) async {
    final days = await askMuteDays();
    if (days == null) return;

    await runAction(
      () => Api.muteUser(id, days: days),
      "کاربر برای $days روز سکوت شد",
      auditAction: "mute_user",
      targetType: "user",
      targetId: id,
      details: {"days": days},
    );
  }

  Future<void> handleUnmuteUser(int id) async {
    await runAction(
      () => Api.unmuteUser(id),
      "سکوت کاربر برداشته شد",
      auditAction: "unmute_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleVerifyUser(int id) async {
    await runAction(
      () => Api.verifyUser(id),
      "کاربر تأیید شد",
      auditAction: "verify_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleUnverifyUser(int id) async {
    await runAction(
      () => Api.unverifyUser(id),
      "تأیید کاربر لغو شد",
      auditAction: "unverify_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleBlueUser(int id) async {
    await runAction(
      () => Api.blueVerifyUser(id),
      "تیک آبی فعال شد",
      auditAction: "blue_verify_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handleUnblueUser(int id) async {
    await runAction(
      () => Api.unblueVerifyUser(id),
      "تیک آبی لغو شد",
      auditAction: "unblue_verify_user",
      targetType: "user",
      targetId: id,
    );
  }

  Future<void> handlePremiumUser(int id) async {
    await runAction(
      () => Api.premiumUser(id, days: 30),
      "پریمیوم فعال شد",
      auditAction: "premium_user",
      targetType: "user",
      targetId: id,
      details: {"days": 30},
    );
  }

  Future<void> handleUnpremiumUser(int id) async {
    await runAction(
      () => Api.unpremiumUser(id),
      "پریمیوم لغو شد",
      auditAction: "unpremium_user",
      targetType: "user",
      targetId: id,
    );
  }

  List<dynamic> filterAds(List<dynamic> ads) {
    final q = adSearchText.trim().toLowerCase();

    return ads.where((ad) {
      if (ad is! Map) return false;

      if (selectedUserAdsFilterId != null) {
        final adUserId = int.tryParse(textOf(ad, "user_id")) ?? 0;
        if (adUserId != selectedUserAdsFilterId) return false;
      }

      final status = textOf(ad, "status").isEmpty ? "approved" : textOf(ad, "status");
      final isHidden = boolOf(ad, "is_hidden") || boolOf(ad, "hidden");
      final isFeatured = boolOf(ad, "is_featured");
      final isPinned = boolOf(ad, "is_pinned");

      if (adStatusFilter == "hidden" && !isHidden) return false;
      if (adStatusFilter == "featured" && !isFeatured) return false;
      if (adStatusFilter == "pinned" && !isPinned) return false;
      if (["pending", "approved", "rejected"].contains(adStatusFilter) &&
          status != adStatusFilter) {
        return false;
      }

      if (q.isEmpty) return true;

      final text = [
        textOf(ad, "id"),
        textOf(ad, "user_id"),
        textOf(ad, "title"),
        textOf(ad, "description"),
        textOf(ad, "phone"),
        textOf(ad, "province"),
        textOf(ad, "district"),
        textOf(ad, "city"),
        textOf(ad, "category_name"),
        textOf(ad, "status"),
      ].join(" ").toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Widget buildAds() {
    return FutureBuilder<List<dynamic>>(
      future: adsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(cleanError(snapshot.error!)));
        }

        final ads = filterAds(snapshot.data ?? []);

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ads.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    if (selectedUserAdsFilterId != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.person, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "نمایش آگهی‌های: $selectedUserAdsFilterName",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: clearUserAdsFilter,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: adSearchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: "جستجوی آگهی با عنوان، شماره، شهر یا شناسه",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          adSearchText = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: adStatusFilter,
                      decoration: InputDecoration(
                        labelText: "فیلتر آگهی",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("همه")),
                        DropdownMenuItem(value: "pending", child: Text("منتظر بررسی")),
                        DropdownMenuItem(value: "approved", child: Text("تأیید شده")),
                        DropdownMenuItem(value: "rejected", child: Text("رد شده")),
                        DropdownMenuItem(value: "hidden", child: Text("مخفی")),
                        DropdownMenuItem(value: "featured", child: Text("ویژه")),
                        DropdownMenuItem(value: "pinned", child: Text("پن شده")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => adStatusFilter = value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              if (index == 1) {
                if (ads.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 70),
                    child: Center(child: Text("آگهی‌ای پیدا نشد")),
                  );
                }
                return const SizedBox.shrink();
              }

              final ad = ads[index - 2];
              return buildAdManageCard(ad);
            },
          ),
        );
      },
    );
  }

  String adMainImage(dynamic ad) {
    final image = textOf(ad, "image_url");
    final full = Api.fullImageUrl(image);
    if (full.isNotEmpty) return full;

    if (ad is Map && ad["images"] is List && (ad["images"] as List).isNotEmpty) {
      return Api.fullImageUrl((ad["images"] as List).first.toString());
    }

    return "";
  }

  Widget buildAdManageCard(dynamic ad) {
    final id = intOf(ad, "id");
    final userId = textOf(ad, "user_id");
    final title = textOf(ad, "title");
    final price = textOf(ad, "price");
    final phone = textOf(ad, "phone");
    final province = textOf(ad, "province");
    final district = textOf(ad, "district");
    final category = textOf(ad, "category_name");
    final image = adMainImage(ad);
    final status = textOf(ad, "status").isEmpty ? "approved" : textOf(ad, "status");
    final rejectReason = textOf(ad, "reject_reason");

    final isHidden = boolOf(ad, "is_hidden") || boolOf(ad, "hidden");
    final isFeatured = boolOf(ad, "is_featured");
    final isPinned = boolOf(ad, "is_pinned");

    final pinnedUntil = textOf(ad, "pinned_until");
    final pinPosition = textOf(ad, "pin_position");
    final featuredUntil = textOf(ad, "featured_until");
    final callCount = textOf(ad, "call_count");
    final chatCount = textOf(ad, "chat_count");
    final viewCount = textOf(ad, "view_count");

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: image.isEmpty
                      ? Container(
                          width: 82,
                          height: 82,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 34),
                        )
                      : Image.network(
                          image,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 82,
                              height: 82,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        title.isEmpty ? "بدون عنوان" : title,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        price.isEmpty || price == "0"
                            ? "قیمت توافقی"
                            : "$price افغانی",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (phone.isNotEmpty) Text("تماس: $phone"),
                      Text("${province.isEmpty ? '-' : province} - ${district.isEmpty ? '-' : district}"),
                      if (rejectReason.isNotEmpty) Text("دلیل رد: $rejectReason"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              children: [
                smallChip("ID: $id", Colors.deepPurple),
                if (userId.isNotEmpty) smallChip("User: $userId", Colors.indigo),
                smallChip(statusFa(status), statusColor(status)),
                if (category.isNotEmpty) smallChip(category, Colors.blue),
                if (isHidden) smallChip("مخفی", Colors.red),
                if (isFeatured) smallChip("ویژه", Colors.orange),
                if (isPinned) smallChip("پن", Colors.green),
                if (pinPosition.isNotEmpty && pinPosition != "null")
                  smallChip("جایگاه پن: $pinPosition", Colors.green),
                if (pinnedUntil.isNotEmpty && pinnedUntil != "null")
                  smallChip("پن تا: $pinnedUntil", Colors.green),
                if (featuredUntil.isNotEmpty && featuredUntil != "null")
                  smallChip("ویژه تا: $featuredUntil", Colors.orange),
                if (viewCount.isNotEmpty) smallChip("بازدید: $viewCount", Colors.grey),
                if (callCount.isNotEmpty) smallChip("تماس: $callCount", Colors.teal),
                if (chatCount.isNotEmpty) smallChip("چت: $chatCount", Colors.teal),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                actionButton(
                  text: "دیدن",
                  icon: Icons.visibility,
                  color: Colors.deepPurple,
                  onTap: () => openAd(ad),
                ),
                actionButton(
                  text: "تأیید",
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onTap: () {
                    if (id == 0) return;
                    handleApproveAd(id);
                  },
                ),
                actionButton(
                  text: "رد",
                  icon: Icons.cancel,
                  color: Colors.red,
                  onTap: () {
                    if (id == 0) return;
                    handleRejectAd(id);
                  },
                ),
                actionButton(
                  text: isHidden ? "نمایش" : "مخفی",
                  icon: isHidden ? Icons.visibility : Icons.visibility_off,
                  color: isHidden ? Colors.green : Colors.red,
                  onTap: () {
                    if (id == 0) return;
                    if (isHidden) {
                      handleUnhideAd(id);
                    } else {
                      handleHideAd(id);
                    }
                  },
                ),
                actionButton(
                  text: isFeatured ? "لغو ویژه" : "ویژه",
                  icon: Icons.star,
                  color: Colors.orange,
                  onTap: () {
                    if (id == 0) return;
                    if (isFeatured) {
                      handleUnfeatureAd(id);
                    } else {
                      handleFeatureAd(id);
                    }
                  },
                ),
                actionButton(
                  text: isPinned ? "لغو پن" : "پن پیشرفته",
                  icon: Icons.push_pin,
                  color: Colors.green,
                  onTap: () {
                    if (id == 0) return;
                    if (isPinned) {
                      handleUnpinAd(id);
                    } else {
                      handlePinAdvanced(id);
                    }
                  },
                ),
                actionButton(
                  text: "تمدید ۳۰ روز",
                  icon: Icons.update,
                  color: Colors.blue,
                  onTap: () {
                    if (id == 0) return;
                    handleExtendAd(id);
                  },
                ),
                actionButton(
                  text: "حذف",
                  icon: Icons.delete,
                  color: Colors.red.shade700,
                  onTap: () {
                    if (id == 0) return;
                    handleDeleteAd(id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openAd(dynamic ad) async {
    if (ad is! Map) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailPage(ad: Map<String, dynamic>.from(ad)),
      ),
    );

    if (result == true) {
      reload();
    }
  }

  Future<void> handleApproveAd(int id) async {
    await runAction(
      () => Api.approveAd(id),
      "آگهی تأیید شد",
      auditAction: "approve_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Future<void> handleRejectAd(int id) async {
    final reason = await askText(
      title: "رد آگهی",
      label: "دلیل رد آگهی",
      maxLines: 3,
    );

    if (reason == null) return;

    await runAction(
      () => Api.rejectAd(id, reason),
      "آگهی رد شد",
      auditAction: "reject_ad",
      targetType: "ad",
      targetId: id,
      details: {"reason": reason},
    );
  }

  Future<void> handleHideAd(int id) async {
    final ok = await askConfirm(
      "مخفی کردن آگهی",
      "آیا این آگهی از کاربران مخفی شود؟",
    );
    if (!ok) return;

    await runAction(
      () => Api.hideAd(id, "hidden by admin"),
      "آگهی مخفی شد",
      auditAction: "hide_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Future<void> handleUnhideAd(int id) async {
    await runAction(
      () => Api.unhideAd(id),
      "آگهی دوباره نمایش داده شد",
      auditAction: "unhide_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Future<void> handleFeatureAd(int id) async {
    await runAction(
      () => Api.featureAd(id, days: 7),
      "آگهی ویژه شد",
      auditAction: "feature_ad",
      targetType: "ad",
      targetId: id,
      details: {"days": 7},
    );
  }

  Future<void> handleUnfeatureAd(int id) async {
    await runAction(
      () => Api.unfeatureAd(id),
      "ویژه آگهی لغو شد",
      auditAction: "unfeature_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Future<void> handlePinAdvanced(int id) async {
    final options = await askPinOptions();
    if (options == null) return;

    final days = options["days"] ?? 7;
    final position = options["position"] ?? 1;

    await runAction(
      () => Api.pinAdAdvanced(id, days: days, position: position),
      "آگهی در جایگاه $position برای $days روز پن شد",
      auditAction: "pin_ad_advanced",
      targetType: "ad",
      targetId: id,
      details: {"days": days, "position": position},
    );
  }

  Future<void> handlePinAd(int id) async {
    await handlePinAdvanced(id);
  }

  Future<void> handleUnpinAd(int id) async {
    await runAction(
      () => Api.unpinAdAdvanced(id),
      "پن آگهی لغو شد",
      auditAction: "unpin_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Future<void> handleExtendAd(int id) async {
    await runAction(
      () => Api.extendAd(id, days: 30),
      "آگهی ۳۰ روز تمدید شد",
      auditAction: "extend_ad",
      targetType: "ad",
      targetId: id,
      details: {"days": 30},
    );
  }

  Future<void> handleDeleteAd(int id) async {
    final ok = await askConfirm(
      "حذف آگهی",
      "آیا این آگهی کامل حذف شود؟",
    );
    if (!ok) return;

    await runAction(
      () => Api.deleteAd(id),
      "آگهی حذف شد",
      auditAction: "delete_ad",
      targetType: "ad",
      targetId: id,
    );
  }

  Widget buildReports() {
    return FutureBuilder<List<dynamic>>(
      future: reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(cleanError(snapshot.error!)));
        }

        final reports = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: reportStatus,
                      decoration: InputDecoration(
                        labelText: "وضعیت گزارش",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("همه")),
                        DropdownMenuItem(value: "pending", child: Text("در انتظار")),
                        DropdownMenuItem(value: "reviewed", child: Text("بررسی شده")),
                        DropdownMenuItem(value: "dismissed", child: Text("رد شده")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          reportStatus = value;
                          reportsFuture = Api.getAdminReports(status: reportStatus);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reports.isEmpty
                  ? const Center(child: Text("گزارشی وجود ندارد"))
                  : RefreshIndicator(
                      onRefresh: reload,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          return buildReportCard(reports[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget buildReportCard(dynamic report) {
    final id = intOf(report, "id");
    final adId = intOf(report, "ad_id");
    final adTitle = textOf(report, "ad_title");
    final reason = textOf(report, "reason");
    final reporterPhone = textOf(report, "reporter_phone");
    final status = textOf(report, "status").isEmpty ? "pending" : textOf(report, "status");
    final createdAt = textOf(report, "created_at");

    final adPhone = textOf(report, "ad_phone");
    final province = textOf(report, "province");
    final district = textOf(report, "district");
    final imageUrl = Api.fullImageUrl(textOf(report, "ad_image_url"));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl.isEmpty
                      ? Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.report),
                        )
                      : Image.network(
                          imageUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 76,
                              height: 76,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        adTitle.isEmpty ? "گزارش آگهی" : adTitle,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text("دلیل: ${reason.isEmpty ? "-" : reason}"),
                      if (reporterPhone.isNotEmpty) Text("گزارش‌دهنده: $reporterPhone"),
                      if (adPhone.isNotEmpty) Text("شماره صاحب آگهی: $adPhone"),
                      if (province.isNotEmpty || district.isNotEmpty)
                        Text("موقعیت: $province - $district"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              children: [
                smallChip("Report ID: $id", Colors.deepPurple),
                if (adId != 0) smallChip("Ad ID: $adId", Colors.blue),
                smallChip(statusFa(status), statusColor(status)),
                if (createdAt.isNotEmpty) smallChip(createdAt, Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                actionButton(
                  text: "دیدن آگهی",
                  icon: Icons.visibility,
                  color: Colors.deepPurple,
                  onTap: () => openReportedAd(report),
                ),
                actionButton(
                  text: "بررسی شد",
                  icon: Icons.done,
                  color: Colors.green,
                  onTap: () => handleReportStatus(report, "reviewed"),
                ),
                actionButton(
                  text: "رد گزارش",
                  icon: Icons.close,
                  color: Colors.orange,
                  onTap: () => handleReportStatus(report, "dismissed"),
                ),
                actionButton(
                  text: "در انتظار",
                  icon: Icons.pending,
                  color: Colors.blueGrey,
                  onTap: () => handleReportStatus(report, "pending"),
                ),
                if (adId != 0)
                  actionButton(
                    text: "مخفی آگهی",
                    icon: Icons.visibility_off,
                    color: Colors.red,
                    onTap: () => handleHideAd(adId),
                  ),
                if (adId != 0)
                  actionButton(
                    text: "حذف آگهی",
                    icon: Icons.delete_forever,
                    color: Colors.red.shade800,
                    onTap: () => handleDeleteAd(adId),
                  ),
                actionButton(
                  text: "حذف گزارش",
                  icon: Icons.delete,
                  color: Colors.black87,
                  onTap: () => handleDeleteReport(report),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openReportedAd(dynamic report) async {
    final adId = intOf(report, "ad_id");

    if (adId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("شناسه آگهی موجود نیست")),
      );
      return;
    }

    try {
      final ads = await Api.getAds();
      dynamic found;

      for (final ad in ads) {
        if (int.tryParse(textOf(ad, "id")) == adId) {
          found = ad;
          break;
        }
      }

      if (found == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("آگهی پیدا نشد یا حذف شده است")),
        );
        return;
      }

      await openAd(found);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleReportStatus(dynamic report, String status) async {
    final id = int.tryParse(textOf(report, "id"));
    if (id == null) return;

    await runAction(
      () => Api.updateReportStatus(id, status),
      "وضعیت گزارش تغییر کرد",
      auditAction: "report_status",
      targetType: "report",
      targetId: id,
      details: {"status": status},
    );
  }

  Future<void> handleDeleteReport(dynamic report) async {
    final id = int.tryParse(textOf(report, "id"));
    if (id == null) return;

    final ok = await askConfirm("حذف گزارش", "آیا این گزارش حذف شود؟");
    if (!ok) return;

    await runAction(
      () => Api.deleteReport(id),
      "گزارش حذف شد",
      auditAction: "delete_report",
      targetType: "report",
      targetId: id,
      details: {"report_id": id},
    );
  }

  Widget buildChats() {
    return FutureBuilder<List<dynamic>>(
      future: chatsFuture,
      builder: (context, snapshot) {
        final chats = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    TextField(
                      controller: chatSearchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: "جستجوی پیام با متن، شماره یا شناسه آگهی",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              chatSearchText = chatSearchController.text.trim();
                              chatsFuture = Api.getAdminAdvancedChats(
                                q: chatSearchText,
                              );
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          chatSearchText = value.trim();
                          chatsFuture = Api.getAdminAdvancedChats(q: chatSearchText);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),
                    if (snapshot.hasError)
                      Center(child: Text(cleanError(snapshot.error!))),
                    if (snapshot.connectionState != ConnectionState.waiting &&
                        !snapshot.hasError &&
                        chats.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 70),
                        child: Center(child: Text("پیامی وجود ندارد")),
                      ),
                  ],
                );
              }

              return buildChatCard(chats[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget buildChatCard(dynamic chat) {
    final id = intOf(chat, "id");
    final adId = textOf(chat, "ad_id");
    final adTitle = textOf(chat, "ad_title");
    final imageUrl = Api.fullImageUrl(textOf(chat, "image_url"));
    final sender = textOf(chat, "sender_phone");
    final receiver = textOf(chat, "receiver_phone");
    final message = textOf(chat, "message");
    final createdAt = textOf(chat, "created_at");
    final deleted = boolOf(chat, "is_deleted");

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isEmpty
                      ? Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.chat),
                        )
                      : Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        adTitle.isEmpty ? "پیام آگهی #$adId" : adTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("از: ${sender.isEmpty ? '-' : sender}"),
                      Text("به: ${receiver.isEmpty || receiver == 'null' ? '-' : receiver}"),
                      if (createdAt.isNotEmpty) Text(createdAt),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: deleted ? Colors.red.withOpacity(0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message.isEmpty ? "-" : message,
                textAlign: TextAlign.right,
                style: TextStyle(
                  height: 1.5,
                  decoration: deleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              children: [
                smallChip("Message ID: $id", Colors.deepPurple),
                if (adId.isNotEmpty) smallChip("Ad: $adId", Colors.blue),
                if (deleted) smallChip("حذف شده", Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                if (!deleted)
                  actionButton(
                    text: "حذف پیام",
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: () {
                      if (id == 0) return;
                      handleDeleteMessage(id);
                    },
                  ),
                if (deleted)
                  actionButton(
                    text: "برگرداندن پیام",
                    icon: Icons.restore,
                    color: Colors.green,
                    onTap: () {
                      if (id == 0) return;
                      handleRestoreMessage(id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleDeleteMessage(int id) async {
    final ok = await askConfirm("حذف پیام", "آیا این پیام حذف شود؟");
    if (!ok) return;

    await runAction(
      () => Api.deleteAdminMessage(id),
      "پیام حذف شد",
      auditAction: "delete_message",
      targetType: "message",
      targetId: id,
    );
  }

  Future<void> handleRestoreMessage(int id) async {
    await runAction(
      () => Api.restoreAdminMessage(id),
      "پیام برگردانده شد",
      auditAction: "restore_message",
      targetType: "message",
      targetId: id,
    );
  }

  Widget buildNotifications() {
    return FutureBuilder<List<dynamic>>(
      future: notificationsFuture,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        "ارسال اعلان مدیریتی",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notificationTitleController,
                        decoration: const InputDecoration(
                          labelText: "عنوان اعلان",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notificationBodyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "متن اعلان",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading ? null : sendNotification,
                          icon: const Icon(Icons.send),
                          label: const Text("ارسال اعلان عمومی"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                Center(child: Text(cleanError(snapshot.error!))),
              if (notifications.isEmpty)
                const Center(child: Text("اعلانی وجود ندارد")),
              ...notifications.map((item) {
                final title = textOf(item, "title");
                final body = textOf(item, "body");
                final createdAt = textOf(item, "created_at");

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.notifications),
                    ),
                    title: Text(title.isEmpty ? "اعلان" : title),
                    subtitle: Text(body.isEmpty ? "-" : "$body\n$createdAt"),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> sendNotification() async {
    final title = notificationTitleController.text.trim();
    final body = notificationBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("عنوان و متن اعلان را وارد کنید")),
      );
      return;
    }

    await runAction(
      () => Api.sendAdminNotification(title: title, body: body),
      "اعلان ارسال شد",
      auditAction: "send_notification",
      targetType: "notification",
      details: {"title": title},
    );

    notificationTitleController.clear();
    notificationBodyController.clear();
  }

  Widget buildPayments() {
    return FutureBuilder<List<dynamic>>(
      future: paymentsFuture,
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        "ثبت پرداخت دستی",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: paymentUserIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "شناسه کاربر اختیاری",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: paymentAdIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "شناسه آگهی اختیاری",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: paymentAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "مبلغ",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: paymentNoteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "یادداشت",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading ? null : createPayment,
                          icon: const Icon(Icons.add_card),
                          label: const Text("ثبت پرداخت"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                Center(child: Text(cleanError(snapshot.error!))),
              if (payments.isEmpty)
                const Center(child: Text("پرداختی وجود ندارد")),
              ...payments.map((item) {
                final id = textOf(item, "id");
                final amount = textOf(item, "amount");
                final currency = textOf(item, "currency");
                final status = textOf(item, "status");
                final purpose = textOf(item, "purpose");
                final createdAt = textOf(item, "created_at");

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor(status),
                      child: const Icon(Icons.payment, color: Colors.white),
                    ),
                    title: Text("پرداخت #$id - $amount $currency"),
                    subtitle: Text("وضعیت: ${statusFa(status)}\nهدف: $purpose\n$createdAt"),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> createPayment() async {
    final amount = int.tryParse(paymentAmountController.text.trim()) ?? 0;
    final userId = int.tryParse(paymentUserIdController.text.trim());
    final adId = int.tryParse(paymentAdIdController.text.trim());
    final note = paymentNoteController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("مبلغ را درست وارد کنید")),
      );
      return;
    }

    await runAction(
      () => Api.createAdminPayment(
        userId: userId,
        adId: adId,
        amount: amount,
        currency: "AFN",
        status: "paid",
        purpose: "manual",
        note: note,
      ),
      "پرداخت ثبت شد",
      auditAction: "create_payment",
      targetType: "payment",
      details: {
        "user_id": userId,
        "ad_id": adId,
        "amount": amount,
      },
    );

    paymentUserIdController.clear();
    paymentAdIdController.clear();
    paymentAmountController.clear();
    paymentNoteController.clear();
  }

  Widget buildBlockedWords() {
    return FutureBuilder<List<dynamic>>(
      future: blockedWordsFuture,
      builder: (context, snapshot) {
        final words = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        "افزودن کلمه ممنوعه",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: blockedWordController,
                        decoration: const InputDecoration(
                          labelText: "کلمه",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: blockedWordTypeController,
                        decoration: const InputDecoration(
                          labelText: "نوع؛ general / scam / badword",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading ? null : addBlockedWord,
                          icon: const Icon(Icons.add),
                          label: const Text("افزودن"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                Center(child: Text(cleanError(snapshot.error!))),
              if (words.isEmpty)
                const Center(child: Text("کلمه ممنوعه‌ای وجود ندارد")),
              ...words.map((item) {
                final id = intOf(item, "id");
                final word = textOf(item, "word");
                final type = textOf(item, "type");
                final active = boolOf(item, "is_active");

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: active ? Colors.red : Colors.grey,
                      child: const Icon(Icons.block, color: Colors.white),
                    ),
                    title: Text(word.isEmpty ? "-" : word),
                    subtitle: Text("نوع: ${type.isEmpty ? 'general' : type}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (id == 0) return;
                        handleDeleteBlockedWord(id);
                      },
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> addBlockedWord() async {
    final word = blockedWordController.text.trim();
    final type = blockedWordTypeController.text.trim().isEmpty
        ? "general"
        : blockedWordTypeController.text.trim();

    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("کلمه را وارد کنید")),
      );
      return;
    }

    await runAction(
      () => Api.addBlockedWord(word: word, type: type),
      "کلمه ممنوعه اضافه شد",
      auditAction: "add_blocked_word",
      targetType: "blocked_word",
      details: {"word": word, "type": type},
    );

    blockedWordController.clear();
  }

  Future<void> handleDeleteBlockedWord(int id) async {
    final ok = await askConfirm("حذف کلمه", "آیا این کلمه حذف شود؟");
    if (!ok) return;

    await runAction(
      () => Api.deleteBlockedWord(id),
      "کلمه حذف شد",
      auditAction: "delete_blocked_word",
      targetType: "blocked_word",
      targetId: id,
    );
  }

  Widget buildDevices() {
    return FutureBuilder<List<dynamic>>(
      future: devicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(cleanError(snapshot.error!)));
        }

        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text("دستگاهی ثبت نشده است")),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final item = devices[index];
              final id = textOf(item, "id");
              final phone = textOf(item, "phone");
              final platform = textOf(item, "platform");
              final token = textOf(item, "fcm_token");
              final updatedAt = textOf(item, "updated_at");
              final createdAt = textOf(item, "created_at");

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.devices),
                  ),
                  title: Text("دستگاه #$id - ${phone.isEmpty ? '-' : phone}"),
                  subtitle: Text(
                    [
                      if (platform.isNotEmpty) "پلتفرم: $platform",
                      if (token.isNotEmpty) "توکن: ${token.length > 30 ? '${token.substring(0, 30)}...' : token}",
                      if (updatedAt.isNotEmpty) "آپدیت: $updatedAt",
                      if (createdAt.isNotEmpty) "ساخت: $createdAt",
                    ].join("\n"),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildSettings() {
    return FutureBuilder<Map<String, dynamic>>(
      future: settingsFuture,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? {};

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        "ذخیره تنظیمات سیستم",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: settingKeyController,
                        decoration: const InputDecoration(
                          labelText: "کلید تنظیمات",
                          hintText: "مثلاً app_notice",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: settingValueController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "مقدار",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loading ? null : saveSetting,
                          icon: const Icon(Icons.save),
                          label: const Text("ذخیره تنظیمات"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                Center(child: Text(cleanError(snapshot.error!))),
              if (settings.isEmpty)
                const Center(child: Text("تنظیمی وجود ندارد")),
              ...settings.entries.map((entry) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.settings),
                    ),
                    title: Text(entry.key),
                    subtitle: Text(entry.value.toString()),
                    onTap: () {
                      settingKeyController.text = entry.key;
                      settingValueController.text = entry.value.toString();
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> saveSetting() async {
    final key = settingKeyController.text.trim();
    final value = settingValueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("کلید و مقدار را وارد کنید")),
      );
      return;
    }

    await runAction(
      () => Api.saveAdminSetting(key: key, value: value),
      "تنظیمات ذخیره شد",
      auditAction: "save_setting",
      targetType: "setting",
      details: {"key": key},
    );

    settingKeyController.clear();
    settingValueController.clear();
  }

  Widget buildAuditLogs() {
    return FutureBuilder<List<dynamic>>(
      future: auditLogsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(cleanError(snapshot.error!)));
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text("لاگ مدیریتی وجود ندارد")),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final item = logs[index];

              final action = textOf(item, "action");
              final targetType = textOf(item, "target_type");
              final targetId = textOf(item, "target_id");
              final adminPhone = textOf(item, "admin_phone");
              final adminUser = textOf(item, "admin_user");
              final createdAt = textOf(item, "created_at");
              final details = textOf(item, "details");

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.history),
                  ),
                  title: Text(
                    action.isEmpty ? "عملیات مدیریت" : action,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      if (targetType.isNotEmpty) "نوع: $targetType",
                      if (targetId.isNotEmpty) "شناسه: $targetId",
                      if (adminPhone.isNotEmpty) "مدیر: $adminPhone",
                      if (adminUser.isNotEmpty) "مدیر: $adminUser",
                      if (details.isNotEmpty) "جزئیات: $details",
                      if (createdAt.isNotEmpty) createdAt,
                    ].join("\n"),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
