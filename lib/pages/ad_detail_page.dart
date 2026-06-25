import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/session.dart';

import 'chat_page.dart';
import 'chat_list_page.dart';
import 'create_ad_page.dart';

const apiBase = "https://api.kooktalayi.com/heratbazar-api/api";

class AdDetailPage extends StatefulWidget {
  final Map ad;

  const AdDetailPage({
    super.key,
    required this.ad,
  });

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  final PageController pageController = PageController();

  int currentImage = 0;
  bool actionLoading = false;
  bool favoriteLoading = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteState();
  }

  Future<void> loadFavoriteState() async {
    final result = await Session.isFavoriteMap(widget.ad);
    if (!mounted) return;

    setState(() {
      isFavorite = result;
    });
  }

  Future<void> toggleFavorite() async {
    if (favoriteLoading) return;

    setState(() {
      favoriteLoading = true;
    });

    try {
      final result = await Session.toggleFavoriteMap(widget.ad);

      if (!mounted) return;

      setState(() {
        isFavorite = result;
      });

      showMessage(result ? "به علاقه‌مندی‌ها اضافه شد" : "از علاقه‌مندی‌ها حذف شد");
    } catch (e) {
      showMessage("خطا در ذخیره علاقه‌مندی");
    }

    if (mounted) {
      setState(() {
        favoriteLoading = false;
      });
    }
  }

  String getText(String key) {
    final value = widget.ad[key];
    if (value == null) return '';
    return value.toString();
  }

  int getAdId() {
    return int.tryParse(getText('id')) ?? 0;
  }

  bool get isOwner {
    final adUserId = int.tryParse(getText('user_id'));
    final myUserId = Session.userId;

    return adUserId != null && myUserId != null && adUserId == myUserId;
  }

  List<String> getImages() {
    final images = widget.ad['images'];
    final imageUrl = getText('image_url');

    final result = <String>[];

    if (images is List) {
      for (final img in images) {
        final url = img.toString().trim();
        if (url.isNotEmpty && !result.contains(url)) {
          result.add(url);
        }
      }
    }

    if (imageUrl.isNotEmpty && !result.contains(imageUrl)) {
      result.insert(0, imageUrl);
    }

    return result;
  }

  String getLocation() {
    final province = getText('province');
    final district = getText('district');
    final city = getText('city');

    if (province.isNotEmpty && district.isNotEmpty) {
      return '$province - $district';
    }

    if (city.isNotEmpty) return city;

    return 'موقعیت نامشخص';
  }

  String getCleanDescription() {
    final description = getText('description');
    if (description.isEmpty) return 'توضیحی ثبت نشده است.';

    final lines = description.split('\n');

    final cleanLines = lines.where((line) {
      final text = line.trim();

      if (text.isEmpty) return false;
      if (text.startsWith('دسته اصلی:')) return false;
      if (text.startsWith('زیر دسته:')) return false;
      if (text.startsWith('ولایت:')) return false;
      if (text.startsWith('ولسوالی:')) return false;
      if (text.startsWith('مشخصات')) return false;
      if (text.contains(':')) return false;

      return true;
    }).toList();

    if (cleanLines.isEmpty) return 'توضیحی ثبت نشده است.';

    return cleanLines.join('\n');
  }

  String getMainCategory() {
    final description = getText('description');

    for (final line in description.split('\n')) {
      final text = line.trim();
      if (text.startsWith('دسته اصلی:')) {
        return text.replaceFirst('دسته اصلی:', '').trim();
      }
    }

    return '';
  }

  String getSubCategory() {
    final description = getText('description');

    for (final line in description.split('\n')) {
      final text = line.trim();
      if (text.startsWith('زیر دسته:')) {
        return text.replaceFirst('زیر دسته:', '').trim();
      }
    }

    final category = getText('category_name');
    if (category.isNotEmpty) return category;

    return 'دسته‌بندی نامشخص';
  }

  List<Map<String, String>> getSpecs() {
    final description = getText('description');
    final specs = <Map<String, String>>[];

    for (final line in description.split('\n')) {
      final text = line.trim();

      if (text.isEmpty) continue;
      if (!text.contains(':')) continue;

      if (text.startsWith('دسته اصلی:')) continue;
      if (text.startsWith('زیر دسته:')) continue;
      if (text.startsWith('ولایت:')) continue;
      if (text.startsWith('ولسوالی:')) continue;
      if (text.startsWith('مشخصات')) continue;

      final parts = text.split(':');

      if (parts.length < 2) continue;

      final key = parts.first.trim();
      final value = parts.sublist(1).join(':').trim();

      if (key.isEmpty || value.isEmpty) continue;

      specs.add({
        'key': key,
        'value': value,
      });
    }

    return specs;
  }
  Color categoryColor(String category) {
    switch (category) {
      case 'املاک':
        return Colors.deepPurple;
      case 'وسایل نقلیه':
        return Colors.blue;
      case 'لوازم الکترونیکی':
        return Colors.teal;
      case 'مربوط به خانه':
        return Colors.orange;
      case 'خدمات':
        return Colors.green;
      case 'وسایل شخصی':
        return Colors.pink;
      case 'سرگرمی و فراغت':
        return Colors.indigo;
      case 'لوازم کودک':
        return Colors.cyan;
      case 'برای کسب و کار':
        return Colors.brown;
      case 'استخدام و کاریابی':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'املاک':
        return Icons.apartment;
      case 'وسایل نقلیه':
        return Icons.directions_car;
      case 'لوازم الکترونیکی':
        return Icons.devices;
      case 'مربوط به خانه':
        return Icons.chair;
      case 'خدمات':
        return Icons.handyman;
      case 'وسایل شخصی':
        return Icons.watch;
      case 'سرگرمی و فراغت':
        return Icons.sports_esports;
      case 'لوازم کودک':
        return Icons.child_care;
      case 'برای کسب و کار':
        return Icons.store;
      case 'استخدام و کاریابی':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> openEditPage() async {
    if (!isOwner) {
      showMessage("شما اجازه ویرایش این آگهی را ندارید");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAdPage(ad: widget.ad),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> deleteAd() async {
    if (!isOwner) {
      showMessage("شما اجازه حذف این آگهی را ندارید");
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("حذف آگهی"),
            content: const Text("آیا مطمئن هستید که این آگهی حذف شود؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("لغو"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("حذف"),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      actionLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse("$apiBase/ads/${getAdId()}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": Session.userId,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          showMessage("آگهی حذف شد");
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 403) {
        showMessage("شما اجازه حذف این آگهی را ندارید");
      } else {
        showMessage("حذف آگهی انجام نشد");
      }
    } catch (e) {
      showMessage("خطا در حذف آگهی");
    }

    if (mounted) {
      setState(() {
        actionLoading = false;
      });
    }
  }

  Future<void> showOwnerMenu() async {
    if (!mounted) return;

    if (!isOwner) {
      showMessage("این آگهی مربوط به شما نیست");
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("ویرایش آگهی"),
                  onTap: () {
                    Navigator.pop(context);
                    openEditPage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("حذف آگهی"),
                  onTap: () {
                    Navigator.pop(context);
                    deleteAd();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void previousImage() {
    if (currentImage <= 0) return;

    pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void nextImage(List<String> images) {
    if (currentImage >= images.length - 1) return;

    pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget topCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget imageGallery(List<String> images, String title) {
    final favoriteIcon = isFavorite ? Icons.favorite : Icons.favorite_border;
    final favoriteColor = isFavorite ? Colors.redAccent : Colors.white;

    if (images.isEmpty) {
      return Stack(
        children: [
          Container(
            height: 360,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(
                Icons.image,
                size: 90,
                color: Colors.grey,
              ),
            ),
          ),
          Positioned(
            top: 34,
            right: 14,
            child: topCircleButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 34,
            left: 70,
            child: topCircleButton(
              icon: favoriteIcon,
              iconColor: favoriteColor,
              onPressed: toggleFavorite,
            ),
          ),
          Positioned(
            top: 34,
            left: 14,
            child: actionLoading
                ? const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : topCircleButton(
                    icon: Icons.more_vert,
                    onPressed: showOwnerMenu,
                  ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          height: 360,
          width: double.infinity,
          color: Colors.black,
          child: PageView.builder(
            controller: pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                currentImage = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  images[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 90,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 34,
          right: 14,
          child: topCircleButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 34,
          left: 70,
          child: topCircleButton(
            icon: favoriteIcon,
            iconColor: favoriteColor,
            onPressed: toggleFavorite,
          ),
        ),
        Positioned(
          top: 34,
          left: 14,
          child: actionLoading
              ? const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : topCircleButton(
                  icon: Icons.more_vert,
                  onPressed: showOwnerMenu,
                ),
        ),
        if (images.length > 1)
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: topCircleButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: previousImage,
              ),
            ),
          ),

        if (images.length > 1)
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: topCircleButton(
                icon: Icons.arrow_forward_ios,
                onPressed: () => nextImage(images),
              ),
            ),
          ),

        Positioned(
          right: 18,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${currentImage + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Positioned(
          left: 18,
          bottom: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              title.isEmpty ? 'جزئیات آگهی' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget priceAndTitleCard({
    required String title,
    required String price,
    required String location,
    required String mainCategory,
    required String subCategory,
    required String phone,
  }) {
    final color = categoryColor(mainCategory);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            title.isEmpty ? 'بدون عنوان' : title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            price.isEmpty || price == '0'
                ? 'قیمت توافقی'
                : 'قیمت: $price AFN',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          detailLine(
            icon: Icons.location_on,
            title: 'موقعیت',
            value: location,
          ),
          detailLine(
            icon: Icons.category,
            title: 'دسته‌بندی',
            value: subCategory,
            color: color,
          ),
          detailLine(
            icon: Icons.phone,
            title: 'شماره تماس',
            value: phone.isEmpty ? 'نامشخص' : phone,
          ),
        ],
      ),
    );
  }

  Widget detailLine({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color ?? Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'نامشخص' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryBadge(String mainCategory, String subCategory) {
    final color = categoryColor(mainCategory);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(
              categoryIcon(mainCategory),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mainCategory.isEmpty
                  ? subCategory
                  : '$mainCategory  •  $subCategory',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget descriptionCard(String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          const Text(
            'توضیحات',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 17, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget specsCard(List<Map<String, String>> specs) {
    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مشخصات آگهی',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            textDirection: TextDirection.rtl,
            children: specs.map((item) {
              return Container(
                width: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      item['key'] ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['value'] ?? '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget sellerActions(String phone) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text('تماس با فروشنده'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      phone.isEmpty
                          ? 'شماره تماس موجود نیست'
                          : 'شماره تماس: $phone',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: Icon(isOwner ? Icons.message : Icons.chat),
              label: Text(isOwner ? 'پیام‌ها' : 'چت'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                if (!Session.isLoggedIn) {
                  showMessage("برای چت باید وارد حساب شوید");
                  return;
                }

                if (isOwner) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatListPage(),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      ad: widget.ad,
                      myPhone: Session.userPhone,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = getText('title');
    final price = getText('price');
    final phone = getText('phone');
    final images = getImages();
    final location = getLocation();
    final mainCategory = getMainCategory();
    final subCategory = getSubCategory();
    final description = getCleanDescription();
    final specs = getSpecs();

    return Scaffold(
      backgroundColor: const Color(0xfff7f1fa),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: imageGallery(images, title),
            ),
            SliverToBoxAdapter(
              child: categoryBadge(mainCategory, subCategory),
            ),
            SliverToBoxAdapter(
              child: priceAndTitleCard(
                title: title,
                price: price,
                location: location,
                mainCategory: mainCategory,
                subCategory: subCategory,
                phone: phone,
              ),
            ),
            SliverToBoxAdapter(
              child: specsCard(specs),
            ),
            SliverToBoxAdapter(
              child: descriptionCard(description),
            ),
            SliverToBoxAdapter(
              child: sellerActions(phone),
            ),
          ],
        ),
      ),
    );
  }
}