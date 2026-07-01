import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/lang.dart';

import 'account_page.dart';
import 'ad_detail_page.dart';
import 'auth_page.dart';
import 'chat_list_page.dart';
import 'create_ad_page.dart';
import 'home_page.dart';

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
        final diff = count - oldCount;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
            content: Text(
              diff == 1
                  ? T.tr('new_message_one')
                  : '$diff ${T.tr('new_messages')}',
            ),
            action: SnackBarAction(
              label: T.tr('view'),
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

    if (!mounted) return;

    if (result == true) {
      setState(() {
        selectedIndex = 0;
      });

      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      final homeState = homeKey.currentState;

      if (homeState != null) {
        await homeState.refreshAds();
      } else {
        setState(() {});
      }
    }

    if (mounted) {
      await loadUnreadMessagesCount();
    }
  }

  Future<void> openSupportTelegram() async {
    final uri = Uri.parse('https://t.me/heratbazar_app');

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.tr('support_open_failed')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> changeTab(int index) async {
    if (index == 2) {
      await openCreateAd();
      return;
    }

    if ((index == 1 || index == 3 || index == 4) && !Session.isLoggedIn) {
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
    required bool selected,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: selected ? primaryColor : Colors.grey.shade600,
          size: selected ? 27 : 24,
        ),
        if (count > 0)
          Positioned(
            top: -8,
            left: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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

  Widget buildSupportButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: openSupportTelegram,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.support_agent,
            color: primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    Widget? customIcon,
  }) {
    final selected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIcon ??
                  Icon(
                    selected ? activeIcon : icon,
                    color: selected ? primaryColor : Colors.grey.shade600,
                    size: selected ? 27 : 24,
                  ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? primaryColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget createAdCenterButton() {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => changeTab(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, secondColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 31),
            ),
            const SizedBox(height: 4),
            Text(
              T.tr('post_ad'),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            navItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: T.tr('home'),
            ),
            navItem(
              index: 1,
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              label: T.tr('favorites'),
            ),
            createAdCenterButton(),
            navItem(
              index: 3,
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: T.tr('messages'),
              customIcon: badgeIcon(
                icon: selectedIndex == 3
                    ? Icons.chat_bubble
                    : Icons.chat_bubble_outline,
                count: unreadMessagesCount,
                selected: selectedIndex == 3,
              ),
            ),
            navItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: T.tr('account'),
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
        backgroundColor: bgColor,
        body: Stack(
          children: [
            currentPage(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              child: buildSupportButton(),
            ),
          ],
        ),
        bottomNavigationBar: buildBottomBar(),
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
    if (price.isEmpty || price == '0') return T.tr('negotiable_price');
    return '$price ${T.tr('afghani')}';
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
      MaterialPageRoute(builder: (_) => AdDetailPage(ad: Map.from(ad))),
    );

    if (mounted) refresh();
  }

  Future<void> removeFavorite(dynamic ad) async {
    if (ad is! Map) return;

    final id = ad['id']?.toString() ?? '';
    await Session.removeFavoriteAd(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(T.tr('removed_from_favorites')),
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
            Text(
              T.tr('no_favorites_yet'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              T.tr('favorites_empty_desc'),
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
                        title.isEmpty ? T.tr('no_title') : title,
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
                        location.isEmpty ? T.tr('unknown_location') : location,
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
        title: Text(T.tr('favorites')),
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
                '${T.tr('favorites_load_error')}\n${snapshot.error}',
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
              padding: const EdgeInsets.only(bottom: 102),
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