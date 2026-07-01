import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/lang.dart';
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

  // Converts old Persian/Dari stored category names OR new English keys
  // into one stable key. This makes old ads and new ads both display correctly.
  String normalizeKey(String value) {
    final v = value.trim();
    if (v.isEmpty) return "";

    if (v.startsWith("cat_") ||
        v.startsWith("sub_") ||
        v.startsWith("province_")) {
      return v;
    }

    const map = {
      "املاک": "cat_real_estate",
      "وسایل نقلیه": "cat_vehicles",
      "لوازم الکترونیکی": "cat_electronics",
      "مربوط به خانه": "cat_home",
      "خدمات": "cat_services",
      "وسایل شخصی": "cat_personal",
      "سرگرمی و فراغت": "cat_entertainment",
      "لوازم کودک": "cat_kids",
      "برای کسب و کار": "cat_business",
      "استخدام و کاریابی": "cat_jobs",

      "خانه فروشی": "sub_house_sale",
      "خانه کرایی": "sub_house_rent",
      "آپارتمان": "sub_apartment",
      "آپارتمان فروشی": "sub_apartment_sale",
      "آپارتمان کرایی": "sub_apartment_rent",
      "زمین": "sub_land",
      "دکان و مغازه": "sub_shop",
      "دکان فروشی": "sub_shop_sale",
      "دکان کرایی": "sub_shop_rent",
      "دفتر کار": "sub_office",
      "دفتر فروشی": "sub_office_sale",
      "دفتر کرایی": "sub_office_rent",
      "گدام": "sub_warehouse",
      "زمین زراعتی": "sub_farm",
      "باغ": "sub_garden",
      "اتاق کرایی": "sub_room_rent",

      "موتر": "sub_car",
      "موترسایکل": "sub_motorcycle",
      "بایسکل": "sub_bicycle",
      "لاری / کامیون": "sub_truck",
      "بس": "sub_bus",
      "وان / سراچه": "sub_van",
      "ریکشا": "sub_rickshaw",
      "پرزه موتر": "sub_car_parts",
      "تایر و پرزه": "sub_tires_parts",
      "لوازم موتر": "sub_vehicle_accessories",

      "موبایل": "sub_mobile",
      "لپتاپ": "sub_laptop",
      "کمپیوتر": "sub_computer",
      "تبلت": "sub_tablet",
      "تلویزیون": "sub_tv",
      "یخچال": "sub_fridge",
      "ماشین لباس‌شویی": "sub_washing_machine",
      "کمره": "sub_camera",
      "جنراتور": "sub_generator",
      "پرنتر": "sub_printer",
      "اسپیکر و صوتی": "sub_speaker",
      "کنسول بازی": "sub_console",
      "ساعت هوشمند": "sub_smart_watch",
      "مودم / روتر": "sub_router",
      "سولر و پنل آفتابی": "sub_solar_panel",
      "پرزه الکترونیکی": "sub_electronic_parts",

      "فرنیچر": "sub_furniture",
      "قالین": "sub_carpet",
      "ظروف": "sub_dishes",
      "لوازم آشپزخانه": "sub_kitchen_items",
      "بستر و کمپل": "sub_bedding",
      "دکور خانه": "sub_home_decor",
      "ابزار کار": "sub_tools",
      "وسایل باغبانی": "sub_garden_tools",
      "وسایل پاک‌کاری": "sub_cleaning_items",

      "خدمات ساختمانی": "sub_construction_services",
      "خدمات تخنیکی": "sub_technical_services",
      "خدمات صحی": "sub_health_services",
      "خدمات آموزشی": "sub_education_services",
      "خدمات انتقالات": "sub_transport_services",
      "خدمات خانه": "sub_home_services",
      "خدمات ترمیم": "sub_repair_services",
      "خدمات حقوقی": "sub_legal_services",
      "خدمات محفل": "sub_event_services",
      "دیزاین و گرافیک": "sub_design_services",

      "لباس": "sub_clothes",
      "کفش": "sub_shoes",
      "ساعت": "sub_watch",
      "عطر": "sub_perfume",
      "زیورات": "sub_jewelry",
      "بکس": "sub_bag",
      "آرایشی و بهداشتی": "sub_cosmetics",
      "عینک": "sub_glasses",

      "کتاب": "sub_book",
      "اسباب‌بازی": "sub_toy",
      "ورزشی": "sub_sport",
      "موسیقی": "sub_music",
      "بازی و سرگرمی": "sub_games",
      "بایسکل ورزشی": "sub_bicycle_sport",
      "لوازم حیوانات": "sub_pet_supplies",

      "لباس کودک": "sub_kids_clothes",
      "کالسکه": "sub_stroller",
      "اسباب‌بازی کودک": "sub_kids_toy",
      "تخت کودک": "sub_kids_bed",
      "لوازم مکتب": "sub_school_items",
      "لوازم نوزاد": "sub_baby_items",
      "بایسکل کودک": "sub_kids_bicycle",

      "وسایل دکان": "sub_shop_equipment",
      "وسایل رستورانت": "sub_restaurant_equipment",
      "وسایل دفتر": "sub_office_equipment",
      "ماشین‌آلات": "sub_machinery",
      "مواد خام": "sub_raw_materials",
      "وسایل زراعتی": "sub_agriculture_equipment",
      "وسایل طبی": "sub_medical_equipment",
      "وسایل فابریکه": "sub_factory_equipment",

      "کار تمام وقت": "sub_full_time",
      "کار نیمه وقت": "sub_part_time",
      "کار روزمزد": "sub_daily_work",
      "کار آنلاین": "sub_online_work",
      "استخدام کارمند": "sub_hiring",
      "کارآموزی": "sub_internship",
      "راننده": "sub_driver_job",
      "معلم / استاد": "sub_teacher_job",
      "نگهبان / امنیت": "sub_security_job",
      "کارگر": "sub_worker_job",
    };

    return map[v] ?? v;
  }

  String trValue(String value) {
    final key = normalizeKey(value);
    if (key.isEmpty) return "";
    return T.tr(key);
  }

  String normalizeSpecKey(String key) {
    final k = key.trim();

    if (k.startsWith("main_category") || k == "دسته اصلی") return "main_category";
    if (k.startsWith("sub_category") || k == "زیر دسته") return "sub_category";

    const map = {
      "آدرس دقیق": "exact_address",
      "آدرس": "exact_address",
      "برند": "brand",
      "برند/نوع": "brand_type",
      "برند / نوع": "brand_type",
      "برند / نوع موتر": "brand_type_vehicle",
      "عنوان": "title",
      "مدل": "model",
      "مدل/اندازه": "model_size",
      "مدل / اندازه": "model_size",
      "سال ساخت": "year_made",
      "سال/نسخه": "year_version",
      "سال / نسخه": "year_version",
      "رنگ": "color",
      "وضعیت": "condition",
      "اندازه": "size",
      "اندازه/حافظه/ظرفیت": "size_capacity",
      "اندازه / ظرفیت کلی": "size_capacity",
      "اندازه / ظرفیت": "size_capacity",
      "ظرفیت": "capacity",
      "حافظه داخلی": "internal_storage",
      "رم": "ram",
      "پردازنده": "processor",
      "باتری": "battery_status",
      "وضعیت باتری": "battery_status",
      "اندازه صفحه": "screen_size",
      "گارانتی": "warranty",
      "جعبه اصلی": "original_box",
      "سریال / IMEI": "serial_imei",
      "سریال/IMEI": "serial_imei",
      "لوازم همراه": "accessories",
      "سابقه تعمیر": "repair_history",
      "کیلومتر": "km_used",
      "کیلومتر کارکرد": "km_used",
      "تیل": "fuel_type",
      "نوع تیل": "fuel_type",
      "گیربکس": "gearbox",
      "اسناد/پلاک": "plate_docs",
      "اسناد / نمبر پلیت": "plate_docs",
      "نوع سند": "document_type",
      "متراژ": "area",
      "متراژ زمین": "land_area",
      "تعداد اتاق": "rooms",
      "تعداد تشناب": "bathrooms",
      "آشپزخانه": "kitchen",
      "طبقه/منزل": "floor",
      "طبقه / منزل": "floor",
      "پارکینگ": "parking",
      "امکانات": "facilities",
      "کرایه": "monthly_rent",
      "کرایه ماهانه": "monthly_rent",
      "گروی": "deposit",
      "نوع ملک": "property_type",
      "جهت زمین": "land_direction",
      "آب و برق": "water_power",
      "نوع استفاده زمین": "land_use",
      "بر جاده": "frontage",
      "بر خیابان": "frontage",
      "ارتفاع": "height",
      "معاش/قیمت": "salary_service_price",
      "معاش / قیمت خدمات": "salary_service_price",
      "وقت کاری": "work_time",
      "تجربه لازم": "experience_required",
      "نام پرزه": "part_name",
      "برای کدام مدل": "part_for",
      "تعداد / مقدار": "quantity",
      "وزن": "weight",
      "نام کتاب": "book_title",
      "نویسنده": "author",
      "سن مناسب": "age_range",
    };

    return map[k] ?? k;
  }

  String maskedPhone(String phone) {
    final clean = phone.trim();

    if (clean.isEmpty) return T.tr("unknown");
    if (clean.length <= 4) return T.tr("hidden");

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
      showMessage(T.tr("invalid_ad_id"));
      return;
    }

    final liked = await Session.toggleFavoriteAd(id);

    if (!mounted) return;

    setState(() {
      isFavorite = liked;
    });

    showMessage(
      liked ? T.tr("added_to_favorites") : T.tr("ad_removed_from_favorites"),
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

    if (raw.isEmpty || raw == "0" || raw.toLowerCase() == "negotiable") {
      return T.tr("negotiable");
    }

    final number = int.tryParse(raw.replaceAll(",", ""));
    if (number == null) {
      return "${trValue(raw)} ${T.tr("afghani")}";
    }

    final formatted = number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ",",
        );

    return "$formatted ${T.tr("afghani")}";
  }

  String getLocation() {
    final province = getText("province");
    final district = getText("district");
    final city = getText("city");
    final address = getText("address");

    if (address.isNotEmpty) return address;

    if (province.isNotEmpty && district.isNotEmpty) {
      return "$province - $district";
    }

    if (city.isNotEmpty) return city;

    return T.tr("unknown_location");
  }

  String getCleanDescription() {
    final description = getText("description");
    if (description.isEmpty) return T.tr("no_description");

    final lines = description.split("\n");

    final cleanLines = lines.where((line) {
      final text = line.trim();

      if (text.isEmpty) return false;
      if (text.startsWith("دسته اصلی:")) return false;
      if (text.startsWith("زیر دسته:")) return false;
      if (text.startsWith("main_category:")) return false;
      if (text.startsWith("sub_category:")) return false;
      if (text.startsWith("ولایت:")) return false;
      if (text.startsWith("ولسوالی:")) return false;
      if (text.startsWith("آدرس دقیق:")) return false;
      if (text.startsWith("مختصات:")) return false;
      if (text.startsWith("مشخصات")) return false;
      if (text.contains(":")) return false;

      return true;
    }).toList();

    if (cleanLines.isEmpty) return T.tr("no_description");

    return cleanLines.join("\n");
  }

  String getMainCategory() {
    final direct = getText("main_category");
    if (direct.isNotEmpty) return normalizeKey(direct);

    final description = getText("description");
    for (final line in description.split("\n")) {
      final text = line.trim();

      if (text.startsWith("دسته اصلی:")) {
        return normalizeKey(text.replaceFirst("دسته اصلی:", "").trim());
      }

      if (text.startsWith("main_category:")) {
        return normalizeKey(text.replaceFirst("main_category:", "").trim());
      }
    }

    return "";
  }

  String getSubCategory() {
    final direct = getText("sub_category");
    if (direct.isNotEmpty) return normalizeKey(direct);

    final description = getText("description");
    for (final line in description.split("\n")) {
      final text = line.trim();

      if (text.startsWith("زیر دسته:")) {
        return normalizeKey(text.replaceFirst("زیر دسته:", "").trim());
      }

      if (text.startsWith("sub_category:")) {
        return normalizeKey(text.replaceFirst("sub_category:", "").trim());
      }
    }

    final category = getText("category_name");
    if (category.isNotEmpty) return normalizeKey(category);

    return "unknown_category";
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
      if (text.startsWith("main_category:")) continue;
      if (text.startsWith("sub_category:")) continue;
      if (text.startsWith("ولایت:")) continue;
      if (text.startsWith("ولسوالی:")) continue;
      if (text.startsWith("مختصات:")) continue;
      if (text.startsWith("مشخصات")) continue;

      final parts = text.split(":");
      if (parts.length < 2) continue;

      final rawKey = parts.first.trim();
      final rawValue = parts.sublist(1).join(":").trim();

      if (rawKey.isEmpty || rawValue.isEmpty) continue;

      final key = normalizeSpecKey(rawKey);
      final value = normalizeKey(rawValue);

      specs.add({
        "key": T.tr(key),
        "value": value == rawValue ? rawValue : T.tr(value),
      });
    }

    return specs;
  }

  Color categoryColor(String category) {
    switch (normalizeKey(category)) {
      case "cat_real_estate":
        return Colors.deepPurple;
      case "cat_vehicles":
        return Colors.blue;
      case "cat_electronics":
        return Colors.teal;
      case "cat_home":
        return Colors.orange;
      case "cat_services":
        return Colors.green;
      case "cat_personal":
        return Colors.pink;
      case "cat_entertainment":
        return Colors.indigo;
      case "cat_kids":
        return Colors.cyan;
      case "cat_business":
        return Colors.brown;
      case "cat_jobs":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String category) {
    switch (normalizeKey(category)) {
      case "cat_real_estate":
        return Icons.apartment;
      case "cat_vehicles":
        return Icons.directions_car;
      case "cat_electronics":
        return Icons.devices;
      case "cat_home":
        return Icons.chair;
      case "cat_services":
        return Icons.handyman;
      case "cat_personal":
        return Icons.watch;
      case "cat_entertainment":
        return Icons.sports_esports;
      case "cat_kids":
        return Icons.child_care;
      case "cat_business":
        return Icons.store;
      case "cat_jobs":
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> isOwner() async {
    if (!Session.isLoggedIn) return false;

    final adUserId = int.tryParse(getText("user_id"));
    final myUserId = Session.userId;

    if (adUserId != null && adUserId > 0 && myUserId != null) {
      return adUserId == myUserId;
    }

    return false;
  }

  Future<void> callSeller(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      showMessage(T.tr("phone_not_available"));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(T.tr("call_seller")),
            content: Text("${T.tr("phone_number")}:\n$cleanPhone"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(T.tr("cancel")),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.phone),
                label: Text(T.tr("call")),
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
      showMessage(T.tr("cannot_call"));
    }
  }

  Future<void> openEditPage() async {
    final canEdit = await isOwner();

    if (!canEdit) {
      showMessage(T.tr("no_permission_edit"));
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
      showMessage(T.tr("no_permission_delete"));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(T.tr("delete_ad")),
            content: Text(T.tr("delete_ad_confirm")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(T.tr("cancel")),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text(T.tr("delete")),
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
        showMessage(T.tr("ad_deleted"));
        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 403) {
        showMessage(T.tr("no_permission_delete"));
      } else {
        showMessage(T.tr("delete_ad_failed"));
      }
    } catch (_) {
      showMessage(T.tr("delete_ad_error"));
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> showOwnerMenu() async {
    final canManage = await isOwner();

    if (!mounted) return;

    if (!canManage) {
      showMessage(T.tr("not_your_ad"));
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
                  title: Text(T.tr("edit_ad")),
                  onTap: () {
                    Navigator.pop(context);
                    openEditPage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(T.tr("delete_ad")),
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
          if (getText("user_id") == Session.userId?.toString()) ...[
            const SizedBox(width: 8),
            CircleAvatar(
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
            ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  title.isEmpty ? T.tr("ad_details") : title,
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
              value.isEmpty ? T.tr("unknown") : value,
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
            title.isEmpty ? T.tr("no_title") : title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${T.tr("price")}: ${formatPrice(price)}",
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
            title: T.tr("location"),
            value: location,
          ),
          detailLine(
            icon: Icons.category,
            title: T.tr("category"),
            value: trValue(subCategory),
            color: color,
          ),
          detailLine(
            icon: Icons.phone,
            title: T.tr("phone_number"),
            value: phone.isEmpty ? T.tr("unknown") : maskedPhone(phone),
          ),
        ],
      ),
    );
  }

  Widget categoryBadge(String mainCategory, String subCategory) {
    final color = categoryColor(mainCategory);
    final mainText = trValue(mainCategory);
    final subText = trValue(subCategory);

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
              mainCategory.isEmpty ? subText : "$mainText  •  $subText",
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
          Text(
            T.tr("description"),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
          Text(
            T.tr("ad_specs"),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            title: Text(T.tr("report_ad")),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: T.tr("report_reason"),
                hintText: T.tr("report_hint"),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(T.tr("cancel")),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(T.tr("send")),
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

      showMessage(T.tr("report_sent"));
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
                  label: Text(T.tr("call_seller")),
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
                  label: Text(T.tr("chat")),
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
              label: Text(
                T.tr("report_ad"),
                style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
