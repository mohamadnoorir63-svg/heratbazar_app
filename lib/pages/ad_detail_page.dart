import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'chat_page.dart';
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
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteState();
  }

  String getText(String key) {
    final value = widget.ad[key];
    if (value == null) return "";
    return value.toString();
  }

  int getAdId() {
    return int.tryParse(getText("id")) ?? 0;
  }

  String maskedPhone(String phone) {
    final clean = phone.trim();

    if (clean.isEmpty) return "نامشخص";
    if (clean.length <= 4) return "مخفی";

    return "${clean.substring(0, 3)}******${clean.substring(clean.length - 2)}";
  }

  Future<void> loadFavoriteState() async {
    final id = getAdId().toString();

    if (id == "0") return;

    final liked = await Session.isFavoriteAd(id);

    if (!mounted) return;

    setState(() {
      isFavorite = liked;
    });
  }

  Future<void> toggleFavorite() async {
    final id = getAdId().toString();

    if (id == "0") {
      showMessage("شناسه آگهی نامعتبر است");
      return;
    }

    final liked = await Session.toggleFavoriteAd(id);

    if (!mounted) return;

    setState(() {
      isFavorite = liked;
    });

    showMessage(
      liked
          ? "آگهی به علاقه‌مندی‌ها اضافه شد"
          : "آگهی از علاقه‌مندی‌ها حذف شد",
    );
  }

  List<String> getImages() {
    final images = widget.ad["images"];
    final imageUrl = getText("image_url");

    final result = <String>[];

    if (images is List) {
      for (final img in images) {
        final url = Api.fullImageUrl(img.toString());
        if (url.isNotEmpty && !result.contains(url)) {
          result.add(url);
        }
      }
    }

    final mainImage = Api.fullImageUrl(imageUrl);
    if (mainImage.isNotEmpty && !result.contains(mainImage)) {
      result.insert(0, mainImage);
    }

    return result;
  }

  String formatPrice(String price) {
    final raw = price.trim();

    if (raw.isEmpty || raw == "0") {
      return "توافقی";
    }

    final number = int.tryParse(raw.replaceAll(",", ""));
    if (number == null) {
      return "$raw افغانی";
    }

    final formatted = number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ",",
        );

    return "$formatted افغانی";
  }

  String getLocation() {
    final province = getText("province");
    final district = getText("district");
    final city = getText("city");
    final address = getText("address");

    if (address.isNotEmpty) {
      return address;
    }

    if (province.isNotEmpty && district.isNotEmpty) {
      return "$province - $district";
    }

    if (city.isNotEmpty) return city;

    return "موقعیت نامشخص";
  }

  String getCleanDescription() {
    final description = getText("description");
    if (description.isEmpty) return "توضیحی ثبت نشده است.";

    final lines = description.split("\n");

    final cleanLines = lines.where((line) {
      final text = line.trim();

      if (text.isEmpty) return false;
      if (text.startsWith("دسته اصلی:")) return false;
      if (text.startsWith("زیر دسته:")) return false;
      if (text.startsWith("ولایت:")) return false;
      if (text.startsWith("ولسوالی:")) return false;
      if (text.startsWith("آدرس دقیق:")) return false;
      if (text.startsWith("مختصات:")) return false;
      if (text.startsWith("مشخصات")) return false;
      if (text.contains(":")) return false;

      return true;
    }).toList();

    if (cleanLines.isEmpty) return "توضیحی ثبت نشده است.";

    return cleanLines.join("\n");
  }
  String getMainCategory() {
    final description = getText("description");

    for (final line in description.split("\n")) {
      final text = line.trim();
      if (text.startsWith("دسته اصلی:")) {
        return text.replaceFirst("دسته اصلی:", "").trim();
      }
    }

    return "";
  }

  String getSubCategory() {
    final description = getText("description");

    for (final line in description.split("\n")) {
      final text = line.trim();
      if (text.startsWith("زیر دسته:")) {
        return text.replaceFirst("زیر دسته:", "").trim();
      }
    }

    final category = getText("category_name");
    if (category.isNotEmpty) return category;

    return "دسته‌بندی نامشخص";
  }

  List<Map<String, String>> getSpecs() {
    final description = getText("description");
    final specs = <Map<String, String>>[];

    for (final line in description.split("\n")) {
      final text = line.trim();

      if (text.isEmpty) continue;
      if (!text.contains(":")) continue;

      if (text.startsWith("دسته اصلی:")) continue;
      if (text.startsWith("زیر دسته:")) continue;
      if (text.startsWith("ولایت:")) continue;
      if (text.startsWith("ولسوالی:")) continue;
      if (text.startsWith("مختصات:")) continue;
      if (text.startsWith("مشخصات")) continue;

      final parts = text.split(":");
      if (parts.length < 2) continue;

      final key = parts.first.trim();
      final value = parts.sublist(1).join(":").trim();

      if (key.isEmpty || value.isEmpty) continue;

      specs.add({
        "key": key,
        "value": value,
      });
    }

    return specs;
  }

  Color categoryColor(String category) {
    switch (category) {
      case "املاک":
        return Colors.deepPurple;
      case "وسایل نقلیه":
        return Colors.blue;
      case "لوازم الکترونیکی":
        return Colors.teal;
      case "مربوط به خانه":
        return Colors.orange;
      case "خدمات":
        return Colors.green;
      case "وسایل شخصی":
        return Colors.pink;
      case "سرگرمی و فراغت":
        return Colors.indigo;
      case "لوازم کودک":
        return Colors.cyan;
      case "برای کسب و کار":
        return Colors.brown;
      case "استخدام و کاریابی":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case "املاک":
        return Icons.apartment;
      case "وسایل نقلیه":
        return Icons.directions_car;
      case "لوازم الکترونیکی":
        return Icons.devices;
      case "مربوط به خانه":
        return Icons.chair;
      case "خدمات":
        return Icons.handyman;
      case "وسایل شخصی":
        return Icons.watch;
      case "سرگرمی و فراغت":
        return Icons.sports_esports;
      case "لوازم کودک":
        return Icons.child_care;
      case "برای کسب و کار":
        return Icons.store;
      case "استخدام و کاریابی":
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> isOwner() async {
    final adOwnerToken = getText("owner_token");
    if (adOwnerToken.isEmpty) return false;

    final myOwnerToken = await Session.getOwnerToken();
    if (myOwnerToken.isEmpty) return false;

    return adOwnerToken == myOwnerToken;
  }

  Future<void> callSeller(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      showMessage("شماره تماس موجود نیست");
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("تماس با فروشنده"),
            content: Text("شماره تماس:\n$cleanPhone"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("لغو"),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.phone),
                label: const Text("تماس"),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    final uri = Uri(scheme: "tel", path: cleanPhone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage("امکان تماس با این شماره وجود ندارد");
    }
  }

  Future<void> openEditPage() async {
    final canEdit = await isOwner();

    if (!canEdit) {
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
    final canDelete = await isOwner();

    if (!canDelete) {
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
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("حذف"),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => actionLoading = true);

    try {
      final ownerToken = await Session.getOwnerToken();

      final response = await http.delete(
        Uri.parse("$apiBase/ads/${getAdId()}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_token": ownerToken,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        showMessage("آگهی حذف شد");
        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 403) {
        showMessage("شما اجازه حذف این آگهی را ندارید");
      } else {
        showMessage("حذف آگهی انجام نشد");
      }
    } catch (_) {
      showMessage("خطا در حذف آگهی");
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> showOwnerMenu() async {
    final canManage = await isOwner();

    if (!mounted) return;

    if (!canManage) {
      showMessage("این آگهی مربوط به شما نیست");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
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

  void openFullImage(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget galleryBackButton() {
    return Positioned(
      top: 34,
      right: 14,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget galleryMenuButton() {
    return Positioned(
      top: 34,
      left: 14,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: toggleFavorite,
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<bool>(
            future: isOwner(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }

              return CircleAvatar(
                backgroundColor: Colors.black54,
                child: actionLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: showOwnerMenu,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget imageGallery(List<String> images, String title) {
    if (images.isEmpty) {
      return Stack(
        children: [
          Container(
            height: 360,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.image, size: 90, color: Colors.grey),
            ),
          ),
          galleryBackButton(),
          galleryMenuButton(),
        ],
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 360,
              width: double.infinity,
              color: Colors.black,
              child: PageView.builder(
                controller: pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => currentImage = index);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => openFullImage(images, index),
                    child: Image.network(
                      images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
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
            galleryBackButton(),
            galleryMenuButton(),
            if (images.length > 1)
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: previousImage,
                    ),
                  ),
                ),
              ),
            if (images.length > 1)
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => nextImage(images),
                    ),
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
                  "${currentImage + 1}/${images.length}",
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
                  title.isEmpty ? "جزئیات آگهی" : title,
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
        ),
        if (images.length > 1) imageThumbnails(images),
      ],
    );
  }

  Widget imageThumbnails(List<String> images) {
    return Container(
      width: double.infinity,
      height: 86,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == currentImage;

          return GestureDetector(
            onTap: () {
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? Colors.blue : Colors.grey.shade300,
                  width: selected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ),
          );
        },
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
          Icon(icon, color: color ?? Colors.grey.shade600, size: 24),
          const SizedBox(width: 10),
          Text(
            "$title: ",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "نامشخص" : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 17, height: 1.4),
            ),
          ),
        ],
      ),
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
            title.isEmpty ? "بدون عنوان" : title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "قیمت: ${formatPrice(price)}",
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
            title: "موقعیت",
            value: location,
          ),
          detailLine(
            icon: Icons.category,
            title: "دسته‌بندی",
            value: subCategory,
            color: color,
          ),
          detailLine(
            icon: Icons.phone,
            title: "شماره تماس",
            value: phone.isEmpty ? "نامشخص" : maskedPhone(phone),
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
                  : "$mainCategory  •  $subCategory",
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
            "توضیحات",
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
            "مشخصات آگهی",
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
                      item["key"] ?? "",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item["value"] ?? "",
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

  Future<void> showReportDialog() async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("گزارش آگهی"),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "دلیل گزارش",
                hintText: "مثلاً کلاهبرداری، آگهی تکراری، محتوای نامناسب...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لغو"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text("ارسال"),
              ),
            ],
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    try {
      setState(() => actionLoading = true);

      await Api.reportAd(
        adId: getAdId(),
        reason: reason,
        reporterPhone: Session.userContact,
      );

      showMessage("گزارش شما ارسال شد");
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Widget sellerActions(String phone) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text("تماس با فروشنده"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => callSeller(phone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("چت"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: actionLoading ? null : showReportDialog,
              icon: const Icon(Icons.report_problem, color: Colors.red),
              label: const Text(
                "گزارش آگهی",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
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
    final title = getText("title");
    final price = getText("price");
    final phone = getText("phone");
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
            SliverToBoxAdapter(child: imageGallery(images, title)),
            SliverToBoxAdapter(child: categoryBadge(mainCategory, subCategory)),
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
            SliverToBoxAdapter(child: specsCard(specs)),
            SliverToBoxAdapter(child: descriptionCard(description)),
            SliverToBoxAdapter(child: sellerActions(phone)),
          ],
        ),
      ),
    );
  }
}

class FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late final PageController controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      widget.images[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 90,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 38,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    "${index + 1}/${widget.images.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}