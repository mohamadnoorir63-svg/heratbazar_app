import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';

import 'account_page.dart';
import 'ad_detail_page.dart';
import 'auth_page.dart';
import 'chat_list_page.dart';
import 'create_ad_page.dart';
import 'home_page.dart';
import 'official_group_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int selectedIndex = 0;
  int unreadMessagesCount = 0;

  Timer? messageTimer;

  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  static const Color primaryColor = Color(0xFF5B3FD6);
  static const Color secondColor = Color(0xFF7C4DFF);
  static const Color bgColor = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    loadUnreadMessagesCount();

    messageTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => loadUnreadMessagesCount(showAlert: true),
    );
  }

  @override
  void dispose() {
    messageTimer?.cancel();
    super.dispose();
  }

  Future<void> loadUnreadMessagesCount({bool showAlert = false}) async {
    if (!Session.isLoggedIn || Session.userPhone.isEmpty) {
      if (!mounted) return;
      setState(() => unreadMessagesCount = 0);
      return;
    }

    try {
      final oldCount = unreadMessagesCount;

      final count = await Api.getUnreadMessagesCount(
        myPhone: Session.userPhone,
      );

      if (!mounted) return;

      setState(() {
        unreadMessagesCount = count;
      });

      if (showAlert && count > oldCount && selectedIndex != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
            content: Text(
              count - oldCount == 1
                  ? 'یک پیام جدید دریافت کردید'
                  : '${count - oldCount} پیام جدید دریافت کردید',
            ),
            action: SnackBarAction(
              label: 'دیدن',
              textColor: Colors.white,
              onPressed: () {
                changeTab(3);
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => unreadMessagesCount = 0);
    }
  }

  Future<bool> ensureLoggedIn() async {
    if (Session.isLoggedIn) return true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );

    if (result == true && mounted) {
      setState(() {});
      await loadUnreadMessagesCount();
    }

    return Session.isLoggedIn;
  }

  Future<void> openCreateAd() async {
    final logged = await ensureLoggedIn();
    if (!logged) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAdPage()),
    );

    if (result == true) {
      homeKey.currentState?.refreshAds();
    }

    if (mounted) {
      setState(() {
        selectedIndex = 0;
      });
      await loadUnreadMessagesCount();
    }
  }

  Future<void> changeTab(int index) async {
    if ((index == 1 || index == 3 || index == 4) &&
        !Session.isLoggedIn) {
      final logged = await ensureLoggedIn();
      if (!logged) return;
    }

    setState(() {
      selectedIndex = index;
    });

    if (index == 3) {
      await loadUnreadMessagesCount();
    }
  }

  Widget currentPage() {
    switch (selectedIndex) {
      case 0:
        return HomePage(key: homeKey);
      case 1:
        return const FavoritesPage();
      case 2:
        return const OfficialGroupPage();
      case 3:
        return const ChatListPage();
      case 4:
        return const AccountPage();
      default:
        return HomePage(key: homeKey);
    }
  }

  Widget badgeIcon({
    required IconData icon,
    required int count,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -7,
            left: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget buildCreateAdButton() {
    return FloatingActionButton.extended(
      onPressed: openCreateAd,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: const Text(
        'ثبت آگهی',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildGroupIcon({required bool selected}) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondColor],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: const Icon(
        Icons.groups,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCreateButton = selectedIndex == 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: currentPage(),
        floatingActionButton: showCreateButton ? buildCreateAdButton() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: primaryColor.withOpacity(0.12),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                final selected = states.contains(MaterialState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? primaryColor : Colors.grey.shade700,
                );
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                final selected = states.contains(MaterialState.selected);
                return IconThemeData(
                  color: selected ? primaryColor : Colors.grey.shade600,
                  size: selected ? 28 : 25,
                );
              }),
            ),
            child: NavigationBar(
              height: 74,
              elevation: 0,
              selectedIndex: selectedIndex,
              onDestinationSelected: changeTab,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search),
                  label: 'جستجو',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'علاقه‌مندی‌ها',
                ),
                NavigationDestination(
                  icon: buildGroupIcon(selected: false),
                  selectedIcon: buildGroupIcon(selected: true),
                  label: 'گروه',
                ),
                NavigationDestination(
                  icon: badgeIcon(
                    icon: Icons.chat_bubble_outline,
                    count: unreadMessagesCount,
                  ),
                  selectedIcon: badgeIcon(
                    icon: Icons.chat_bubble,
                    count: unreadMessagesCount,
                  ),
                  label: 'پیام‌ها',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'حساب من',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<dynamic>> future;

  static const Color primaryColor = Color(0xFF5B3FD6);
  static const Color bgColor = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    future = loadFavorites();
  }

  Future<List<dynamic>> loadFavorites() async {
    final favoriteIds = await Session.getFavoriteAdIds();
    final ads = await Api.getAds();

    return ads.where((ad) {
      if (ad is! Map) return false;
      final id = ad['id']?.toString() ?? '';
      return favoriteIds.contains(id);
    }).toList();
  }

  Future<void> refresh() async {
    setState(() {
      future = loadFavorites();
    });
  }

  String textOf(dynamic ad, String key) {
    if (ad is! Map) return '';
    return ad[key]?.toString() ?? '';
  }

  String priceText(String price) {
    if (price.isEmpty || price == '0') return 'قیمت توافقی';
    return 'AFN $price';
  }

  List<String> getImages(dynamic ad) {
    final result = <String>[];
    if (ad is! Map) return result;

    final images = ad['images'];
    if (images is List) {
      for (final img in images) {
        final url = Api.fullImageUrl(img.toString());
        if (url.isNotEmpty && !result.contains(url)) result.add(url);
      }
    }

    final imageUrl = Api.fullImageUrl(ad['image_url']?.toString());
    if (imageUrl.isNotEmpty && !result.contains(imageUrl)) {
      result.insert(0, imageUrl);
    }

    return result;
  }

  Future<void> openAd(dynamic ad) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailPage(ad: Map.from(ad)),
      ),
    );

    if (mounted) refresh();
  }

  Future<void> removeFavorite(dynamic ad) async {
    if (ad is! Map) return;

    final id = ad['id']?.toString() ?? '';
    await Session.removeFavoriteAd(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('از علاقه‌مندی‌ها حذف شد'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    refresh();
  }

  Widget buildImage(dynamic ad) {
    final images = getImages(ad);

    if (images.isEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.image, color: Colors.grey, size: 34),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        images.first,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 88,
            height: 88,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                color: primaryColor,
                size: 52,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'هنوز علاقه‌مندی ندارید',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'آگهی‌هایی که دوست دارید اینجا ذخیره می‌شوند.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFavoriteCard(dynamic ad) {
    final title = textOf(ad, 'title');
    final price = textOf(ad, 'price');
    final province = textOf(ad, 'province');
    final district = textOf(ad, 'district');

    final location = province.isNotEmpty && district.isNotEmpty
        ? '$province - $district'
        : province;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => openAd(ad),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                buildImage(ad),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'بدون عنوان' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        priceText(price),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location.isEmpty ? 'موقعیت نامشخص' : location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => removeFavorite(ad),
                  icon: const Icon(Icons.favorite, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('علاقه‌مندی‌ها'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطا در دریافت علاقه‌مندی‌ها\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final ads = snapshot.data ?? [];

          if (ads.isEmpty) return buildEmptyState();

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 18),
              itemCount: ads.length,
              itemBuilder: (context, index) {
                return buildFavoriteCard(ads[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
