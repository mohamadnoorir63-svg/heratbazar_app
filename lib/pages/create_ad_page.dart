import 'dart:convert';
import 'dart:typed_data';

import '../services/ad_owner_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const apiBase = "https://api.kooktalayi.com/heratbazar-api/api";
const publicBase = "https://api.kooktalayi.com/heratbazar-api";

class CreateAdPage extends StatefulWidget {
  final Map? ad;

  const CreateAdPage({
    super.key,
    this.ad,
  });

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final picker = ImagePicker();

  bool loading = false;
  bool categorySelected = false;

  String mainCategory = "";
  String subCategory = "";

  int categoryId = 3;

  String province = "هرات";
  String district = "مرکز هرات";

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final phoneController = TextEditingController();

  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final colorController = TextEditingController();
  final sizeController = TextEditingController();
  final conditionController = TextEditingController();

  final meterController = TextEditingController();
  final roomsController = TextEditingController();
  final floorController = TextEditingController();
  final addressController = TextEditingController();
  final rentController = TextEditingController();
  final depositController = TextEditingController();

  final kmController = TextEditingController();
  final fuelController = TextEditingController();
  final gearController = TextEditingController();
  final documentController = TextEditingController();

  final salaryController = TextEditingController();
  final workTimeController = TextEditingController();
  final experienceController = TextEditingController();

  final List<XFile> selectedImages = [];
  final List<Uint8List> selectedImageBytes = [];

  final List<String> existingImageUrls = [];

  bool get isEditMode => widget.ad != null;

  final List<Map<String, dynamic>> mainCategories = [
    {
      "name": "املاک",
      "icon": Icons.apartment,
      "color": Colors.deepPurple,
      "subs": [
        "خانه فروشی",
        "خانه کرایی",
        "آپارتمان",
        "زمین",
        "دکان و مغازه",
        "دفتر کار",
        "گدام",
      ],
    },
    {
      "name": "وسایل نقلیه",
      "icon": Icons.directions_car,
      "color": Colors.blue,
      "subs": [
        "موتر",
        "موترسایکل",
        "بایسکل",
        "پرزه موتر",
        "تایر و پرزه",
      ],
    },
    {
      "name": "لوازم الکترونیکی",
      "icon": Icons.devices,
      "color": Colors.teal,
      "subs": [
        "موبایل",
        "لپتاپ",
        "کمپیوتر",
        "تلویزیون",
        "یخچال",
        "ماشین لباس‌شویی",
        "کمره",
        "جنراتور",
      ],
    },
    {
      "name": "مربوط به خانه",
      "icon": Icons.chair,
      "color": Colors.orange,
      "subs": [
        "فرنیچر",
        "قالین",
        "ظروف",
        "لوازم آشپزخانه",
        "بستر و کمپل",
        "دکور خانه",
      ],
    },
    {
      "name": "خدمات",
      "icon": Icons.handyman,
      "color": Colors.green,
      "subs": [
        "خدمات ساختمانی",
        "خدمات تخنیکی",
        "خدمات صحی",
        "خدمات آموزشی",
        "خدمات انتقالات",
        "خدمات خانه",
      ],
    },
    {
      "name": "وسایل شخصی",
      "icon": Icons.watch,
      "color": Colors.pink,
      "subs": [
        "لباس",
        "کفش",
        "ساعت",
        "عطر",
        "زیورات",
        "بکس",
      ],
    },
    {
      "name": "سرگرمی و فراغت",
      "icon": Icons.sports_esports,
      "color": Colors.indigo,
      "subs": [
        "کتاب",
        "اسباب‌بازی",
        "ورزشی",
        "موسیقی",
        "بازی و سرگرمی",
      ],
    },
    {
      "name": "لوازم کودک",
      "icon": Icons.child_care,
      "color": Colors.cyan,
      "subs": [
        "لباس کودک",
        "کالسکه",
        "اسباب‌بازی کودک",
        "تخت کودک",
        "لوازم مکتب",
      ],
    },
    {
      "name": "برای کسب و کار",
      "icon": Icons.store,
      "color": Colors.brown,
      "subs": [
        "وسایل دکان",
        "وسایل رستورانت",
        "وسایل دفتر",
        "ماشین‌آلات",
        "مواد خام",
      ],
    },
    {
      "name": "استخدام و کاریابی",
      "icon": Icons.work,
      "color": Colors.redAccent,
      "subs": [
        "کار تمام وقت",
        "کار نیمه وقت",
        "کار روزمزد",
        "کار آنلاین",
        "استخدام کارمند",
      ],
    },
  ];

  final provinces = [
    "هرات",
    "کابل",
    "قندهار",
    "بلخ",
    "ننگرهار",
    "بدخشان",
    "فراه",
    "غزنی",
    "بامیان",
    "هلمند",
  ];

  final Map<String, List<String>> districts = {
    "هرات": [
      "مرکز هرات",
      "انجیل",
      "گذره",
      "کرخ",
      "رباط سنگی",
      "زنده جان",
      "پشتون زرغون",
      "شیندند",
      "ادرسکن",
      "اوبه",
      "چشت شریف",
      "گلران",
      "کوهسان",
      "کشک",
      "کشک کهنه",
      "غوریان",
    ],
    "کابل": [
      "مرکز کابل",
      "پغمان",
      "بگرامی",
      "ده سبز",
      "شکردره",
      "استالف",
      "قره باغ",
      "چهار آسیاب",
      "موسهی",
      "خاک جبار",
      "سروبی",
      "کلکان",
      "گلدره",
      "فرزه",
    ],
    "قندهار": ["مرکز قندهار"],
    "بلخ": ["مرکز مزار شریف"],
    "ننگرهار": ["مرکز جلال‌آباد"],
    "بدخشان": ["مرکز فیض‌آباد"],
    "فراه": ["مرکز فراه"],
    "غزنی": ["مرکز غزنی"],
    "بامیان": ["مرکز بامیان"],
    "هلمند": ["مرکز لشکرگاه"],
  };

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      loadAdForEdit();
    } else {
      fillPhoneFromLoggedUser();
    }
  }

  void fillPhoneFromLoggedUser() {
    final user = AuthService.currentUser;

    if (user == null) return;

    final phone = user["phone"]?.toString() ?? "";

    if (phone.isNotEmpty) {
      phoneController.text = phone;
    }
  }

  String adText(String key) {
    final value = widget.ad?[key];

    if (value == null) return "";

    return value.toString();
  }

  void loadAdForEdit() {
    titleController.text = adText("title");
    priceController.text = adText("price");
    phoneController.text = adText("phone");

    province = adText("province").isEmpty ? "هرات" : adText("province");
    district = adText("district").isEmpty ? "مرکز هرات" : adText("district");

    categoryId = int.tryParse(adText("category_id")) ?? 3;

    final description = adText("description");

    readDescription(description);

    final images = widget.ad?["images"];

    if (images is List) {
      for (final img in images) {
        final url = img.toString();

        if (url.isNotEmpty && !existingImageUrls.contains(url)) {
          existingImageUrls.add(url);
        }
      }
    }

    final imageUrl = adText("image_url");

    if (imageUrl.isNotEmpty && !existingImageUrls.contains(imageUrl)) {
      existingImageUrls.insert(0, imageUrl);
    }

    if (mainCategory.isEmpty) {
      mainCategory = categoryNameFromOldId(categoryId);
    }

    if (subCategory.isEmpty) {
      subCategory = adText("category_name").isEmpty
          ? mainCategory
          : adText("category_name");
    }

    categorySelected = true;
  }
  void readDescription(String description) {
    final normalLines = <String>[];

    for (final line in description.split("\n")) {
      final text = line.trim();

      if (text.isEmpty) continue;

      if (text.startsWith("دسته اصلی:")) {
        mainCategory = text.replaceFirst("دسته اصلی:", "").trim();
        continue;
      }

      if (text.startsWith("زیر دسته:")) {
        subCategory = text.replaceFirst("زیر دسته:", "").trim();
        continue;
      }

      if (text.startsWith("ولایت:")) {
        province = text.replaceFirst("ولایت:", "").trim();
        continue;
      }

      if (text.startsWith("ولسوالی:")) {
        district = text.replaceFirst("ولسوالی:", "").trim();
        continue;
      }

      if (text.startsWith("مشخصات")) continue;

      if (text.contains(":")) {
        final parts = text.split(":");

        if (parts.length >= 2) {
          final key = parts.first.trim();
          final value = parts.sublist(1).join(":").trim();

          setFieldFromDescription(key, value);
        }

        continue;
      }

      normalLines.add(text);
    }

    descriptionController.text = normalLines.join("\n");
  }

  void setFieldFromDescription(String key, String value) {
    if (key == "برند" || key == "برند/نوع" || key == "عنوان") {
      brandController.text = value;
    } else if (key == "مدل" || key == "مدل/اندازه") {
      modelController.text = value;
    } else if (key == "سال ساخت" || key == "سال/نسخه") {
      yearController.text = value;
    } else if (key == "رنگ") {
      colorController.text = value;
    } else if (key == "کیلومتر") {
      kmController.text = value;
    } else if (key == "تیل") {
      fuelController.text = value;
    } else if (key == "گیربکس") {
      gearController.text = value;
    } else if (key == "اسناد/پلاک") {
      documentController.text = value;
    } else if (key == "متراژ") {
      meterController.text = value;
    } else if (key == "تعداد اتاق") {
      roomsController.text = value;
    } else if (key == "طبقه/منزل") {
      floorController.text = value;
    } else if (key == "کرایه") {
      rentController.text = value;
    } else if (key == "گروی") {
      depositController.text = value;
    } else if (key == "آدرس دقیق" || key == "آدرس") {
      addressController.text = value;
    } else if (key == "اندازه/حافظه/ظرفیت") {
      sizeController.text = value;
    } else if (key == "وضعیت") {
      conditionController.text = value;
    } else if (key == "معاش/قیمت") {
      salaryController.text = value;
    } else if (key == "وقت کاری") {
      workTimeController.text = value;
    } else if (key == "تجربه لازم") {
      experienceController.text = value;
    }
  }

  String categoryNameFromOldId(int id) {
    if (id == 1) return "وسایل نقلیه";
    if (id == 2) return "املاک";
    if (id == 3) return "لوازم الکترونیکی";
    if (id == 4) return "لوازم الکترونیکی";
    if (id == 5) return "وسایل شخصی";
    if (id == 6) return "خدمات";

    return "لوازم الکترونیکی";
  }

  int getCategoryId(String main, String sub) {
    if (main == "وسایل نقلیه") return 1;
    if (main == "املاک") return 2;
    if (sub == "موبایل") return 3;
    if (sub == "لپتاپ" || sub == "کمپیوتر") return 4;
    if (main == "وسایل شخصی") return 5;
    if (main == "خدمات" || main == "استخدام و کاریابی") return 6;

    return 3;
  }

  void selectCategory(String main, String sub) {
    setState(() {
      mainCategory = main;
      subCategory = sub;
      categoryId = getCategoryId(main, sub);
      categorySelected = true;
    });
  }

  void backToCategories() {
    if (isEditMode) {
      setState(() {
        categorySelected = false;
      });
      return;
    }

    setState(() {
      categorySelected = false;
    });
  }

  Future<bool> ensureLoggedIn() async {
    if (AuthService.isLoggedIn) {
      fillPhoneFromLoggedUser();
      return true;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );

    if (result == true && AuthService.isLoggedIn) {
      fillPhoneFromLoggedUser();
      return true;
    }

    showMessage("برای ثبت آگهی اول وارد حساب شوید");
    return false;
  }

  Future<void> pickImages() async {
    if (loading) return;

    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;

    final totalNow = existingImageUrls.length + selectedImages.length;
    final remaining = 20 - totalNow;

    if (remaining <= 0) {
      showMessage("حداکثر ۲۰ عکس می‌توانید انتخاب کنید");
      return;
    }

    final limited = files.take(remaining).toList();
    final bytesList = <Uint8List>[];

    for (final file in limited) {
      bytesList.add(await file.readAsBytes());
    }

    setState(() {
      selectedImages.addAll(limited);
      selectedImageBytes.addAll(bytesList);
    });

    if (files.length > remaining) {
      showMessage("فقط $remaining عکس اضافه شد؛ حداکثر ۲۰ عکس مجاز است");
    }
  }

  void removeNewImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      selectedImageBytes.removeAt(index);
    });
  }

  void removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  Future<String?> uploadOneImage(XFile image) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$apiBase/uploads"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          await image.readAsBytes(),
          filename: image.name,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) return null;

      final data = jsonDecode(body);
      final url = data["url"]?.toString();

      if (url == null || url.isEmpty) return null;
      if (url.startsWith("http")) return url;

      return "$publicBase$url";
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadAllImages() async {
    final urls = <String>[];

    urls.addAll(existingImageUrls);

    for (final image in selectedImages) {
      final url = await uploadOneImage(image);

      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }

    return urls;
  }
  String buildFullDescription() {
    final normal = descriptionController.text.trim();

    final buffer = StringBuffer();

    if (normal.isNotEmpty) {
      buffer.writeln(normal);
      buffer.writeln();
    }

    buffer.writeln("دسته اصلی: $mainCategory");
    buffer.writeln("زیر دسته: $subCategory");
    buffer.writeln("ولایت: $province");
    buffer.writeln("ولسوالی: $district");

    if (mainCategory == "وسایل نقلیه") {
      buffer.writeln();
      buffer.writeln("مشخصات وسایط:");
      buffer.writeln("برند/نوع: ${brandController.text.trim()}");
      buffer.writeln("مدل: ${modelController.text.trim()}");
      buffer.writeln("سال ساخت: ${yearController.text.trim()}");
      buffer.writeln("رنگ: ${colorController.text.trim()}");
      buffer.writeln("کیلومتر: ${kmController.text.trim()}");
      buffer.writeln("تیل: ${fuelController.text.trim()}");
      buffer.writeln("گیربکس: ${gearController.text.trim()}");
      buffer.writeln("اسناد/پلاک: ${documentController.text.trim()}");
    }

    if (mainCategory == "املاک") {
      buffer.writeln();
      buffer.writeln("مشخصات ملک:");
      buffer.writeln("متراژ: ${meterController.text.trim()}");
      buffer.writeln("تعداد اتاق: ${roomsController.text.trim()}");
      buffer.writeln("طبقه/منزل: ${floorController.text.trim()}");
      buffer.writeln("کرایه: ${rentController.text.trim()}");
      buffer.writeln("گروی: ${depositController.text.trim()}");
      buffer.writeln("آدرس دقیق: ${addressController.text.trim()}");
    }

    if (mainCategory == "لوازم الکترونیکی") {
      buffer.writeln();
      buffer.writeln("مشخصات وسیله:");
      buffer.writeln("برند: ${brandController.text.trim()}");
      buffer.writeln("مدل: ${modelController.text.trim()}");
      buffer.writeln("سال/نسخه: ${yearController.text.trim()}");
      buffer.writeln("رنگ: ${colorController.text.trim()}");
      buffer.writeln("اندازه/حافظه/ظرفیت: ${sizeController.text.trim()}");
      buffer.writeln("وضعیت: ${conditionController.text.trim()}");
    }

    if (mainCategory == "مربوط به خانه" ||
        mainCategory == "وسایل شخصی" ||
        mainCategory == "سرگرمی و فراغت" ||
        mainCategory == "لوازم کودک" ||
        mainCategory == "برای کسب و کار") {
      buffer.writeln();
      buffer.writeln("مشخصات کالا:");
      buffer.writeln("برند/نوع: ${brandController.text.trim()}");
      buffer.writeln("مدل/اندازه: ${modelController.text.trim()}");
      buffer.writeln("رنگ: ${colorController.text.trim()}");
      buffer.writeln("وضعیت: ${conditionController.text.trim()}");
    }

    if (mainCategory == "خدمات" || mainCategory == "استخدام و کاریابی") {
      buffer.writeln();
      buffer.writeln("مشخصات کار/خدمات:");
      buffer.writeln("عنوان: ${brandController.text.trim()}");
      buffer.writeln("معاش/قیمت: ${salaryController.text.trim()}");
      buffer.writeln("وقت کاری: ${workTimeController.text.trim()}");
      buffer.writeln("تجربه لازم: ${experienceController.text.trim()}");
      buffer.writeln("آدرس: ${addressController.text.trim()}");
    }

    return buffer.toString();
  }

  int? currentUserId() {
    final user = AuthService.currentUser;

    if (user == null) return null;

    return int.tryParse(user["id"].toString());
  }

  Future<void> submitAd() async {
    if (loading) return;

    if (!isEditMode) {
      final logged = await ensureLoggedIn();
      if (!logged) return;
    }

    if (titleController.text.trim().isEmpty) {
      showMessage("عنوان آگهی را وارد کنید");
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage("شماره تماس را وارد کنید");
      return;
    }

    if (mainCategory.isEmpty || subCategory.isEmpty) {
      showMessage("دسته‌بندی آگهی را انتخاب کنید");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final ownerToken = await AdOwnerService.getOwnerToken();
      final imageUrls = await uploadAllImages();
      final userId = currentUserId();

      final body = {
        "title": titleController.text.trim(),
        "description": buildFullDescription(),
        "price": int.tryParse(priceController.text.trim()) ?? 0,
        "phone": phoneController.text.trim(),
        "province": province,
        "district": district,
        "city": "$province - $district",
        "category_id": categoryId,
        "image_url": imageUrls.isEmpty ? null : imageUrls.first,
        "images": imageUrls,
        "owner_token": ownerToken,
        "user_id": userId,
      };

      final response = isEditMode
          ? await http.put(
              Uri.parse("$apiBase/ads/${widget.ad!['id']}"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
          : await http.post(
              Uri.parse("$apiBase/ads"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          showMessage(
            isEditMode
                ? "آگهی با موفقیت ویرایش شد"
                : "آگهی با موفقیت ثبت شد",
          );

          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 403) {
        showMessage("شما اجازه ویرایش این آگهی را ندارید");
      } else {
        showMessage(isEditMode ? "ویرایش انجام نشد" : "ثبت آگهی انجام نشد");
      }
    } catch (e) {
      showMessage(isEditMode ? "خطا در ویرایش آگهی" : "خطا در ثبت آگهی");
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget textField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    final isNumber = type == TextInputType.number;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : type,
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget dropdown<T>({
    required T value,
    required String label,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: loading ? null : onChanged,
      ),
    );
  }
  Widget buildCategoryList() {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "تغییر دسته‌بندی" : "دسته‌بندی آگهی‌ها"),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: mainCategories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = mainCategories[index];
          final color = item["color"] as Color;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(item["icon"] as IconData, color: color),
            ),
            title: Text(
              item["name"].toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              showSubCategories(
                item["name"].toString(),
                List<String>.from(item["subs"] as List),
              );
            },
          );
        },
      ),
    );
  }

  void showSubCategories(String main, List<String> subs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 55,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                        Expanded(
                          child: Text(
                            main,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sub = subs[index];

                        return ListTile(
                          title: Text(
                            sub,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 17),
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () {
                            Navigator.pop(context);
                            selectCategory(main, sub);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget categoryHeader() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: const Icon(Icons.category),
        title: Text(
          "$mainCategory / $subCategory",
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "برای تغییر دسته‌بندی روی این بخش بزنید",
          textAlign: TextAlign.right,
        ),
        trailing: const Icon(Icons.edit),
        onTap: backToCategories,
      ),
    );
  }

  Widget categorySpecificFields() {
    if (mainCategory == "وسایل نقلیه") {
      return Column(
        children: [
          sectionTitle("مشخصات وسایل نقلیه"),
          textField(brandController, "برند یا نوع وسیله"),
          textField(modelController, "مدل"),
          textField(yearController, "سال ساخت", type: TextInputType.number),
          textField(kmController, "کیلومتر کارکرد", type: TextInputType.number),
          textField(colorController, "رنگ"),
          textField(fuelController, "نوع تیل مثل پترول، دیزل، گاز"),
          textField(gearController, "گیربکس مثل اتومات یا دنده‌ای"),
          textField(documentController, "اسناد، نمبر پلیت، محصول"),
        ],
      );
    }

    if (mainCategory == "املاک") {
      return Column(
        children: [
          sectionTitle("مشخصات املاک"),
          textField(meterController, "متراژ", type: TextInputType.number),
          textField(roomsController, "تعداد اتاق", type: TextInputType.number),
          textField(floorController, "طبقه / منزل / همکف"),
          textField(rentController, "کرایه ماهانه", type: TextInputType.number),
          textField(
            depositController,
            "گروی / پیش‌پرداخت",
            type: TextInputType.number,
          ),
          textField(addressController, "آدرس دقیق", maxLines: 2),
        ],
      );
    }

    if (mainCategory == "لوازم الکترونیکی") {
      return Column(
        children: [
          sectionTitle("مشخصات لوازم الکترونیکی"),
          textField(brandController, "برند"),
          textField(modelController, "مدل"),
          textField(sizeController, "حافظه / اندازه / ظرفیت"),
          textField(colorController, "رنگ"),
          textField(conditionController, "وضعیت مثل نو، کارکرده، خراب"),
        ],
      );
    }

    if (mainCategory == "خدمات" || mainCategory == "استخدام و کاریابی") {
      return Column(
        children: [
          sectionTitle("مشخصات کار یا خدمات"),
          textField(brandController, "عنوان کار یا خدمات"),
          textField(salaryController, "معاش / قیمت خدمات"),
          textField(workTimeController, "وقت کاری"),
          textField(experienceController, "تجربه لازم"),
          textField(addressController, "آدرس", maxLines: 2),
        ],
      );
    }

    return Column(
      children: [
        sectionTitle("مشخصات کالا"),
        textField(brandController, "برند / نوع"),
        textField(modelController, "مدل / اندازه"),
        textField(colorController, "رنگ"),
        textField(conditionController, "وضعیت"),
      ],
    );
  }

  Widget locationFields() {
    final districtList = districts[province] ?? ["مرکز هرات"];

    return Column(
      children: [
        sectionTitle("موقعیت"),
        dropdown<String>(
          value: province,
          label: "ولایت",
          items: provinces,
          onChanged: (v) {
            if (v == null) return;

            setState(() {
              province = v;
              district = districts[v]?.first ?? "مرکز هرات";
            });
          },
        ),
        dropdown<String>(
          value: district,
          label: "ولسوالی",
          items: districtList,
          onChanged: (v) {
            if (v == null) return;

            setState(() {
              district = v;
            });
          },
        ),
      ],
    );
  }

  Widget imagePickerSection() {
    return Column(
      children: [
        sectionTitle("عکس‌های آگهی"),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : pickImages,
            icon: const Icon(Icons.image),
            label: Text(
              existingImageUrls.isEmpty && selectedImages.isEmpty
                  ? "انتخاب عکس"
                  : "عکس‌ها (${existingImageUrls.length + selectedImages.length}/20)",
            ),
          ),
        ),
        if (existingImageUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 125,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: existingImageUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 125,
                        height: 125,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            existingImageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: InkWell(
                          onTap: loading
                              ? null
                              : () => removeExistingImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "عکس اصلی",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        if (selectedImageBytes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 125,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImageBytes.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 125,
                        height: 125,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            selectedImageBytes[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: InkWell(
                          onTap: loading ? null : () => removeNewImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget buildFormPage() {
    final user = AuthService.currentUser;
    final userName = user == null
        ? "وارد نشده"
        : "${user["first_name"] ?? ""} ${user["last_name"] ?? ""}".trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "ویرایش آگهی" : "ثبت آگهی"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: loading ? null : backToCategories,
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!isEditMode)
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text("حساب: $userName"),
                    subtitle: const Text(
                      "برای ثبت آگهی باید وارد حساب باشید",
                    ),
                    trailing: TextButton(
                      onPressed: loading
                          ? null
                          : () async {
                              await ensureLoggedIn();
                              setState(() {});
                            },
                      child: Text(
                        AuthService.isLoggedIn ? "تغییر حساب" : "ورود",
                      ),
                    ),
                  ),
                ),
              categoryHeader(),
              textField(titleController, "عنوان آگهی"),
              textField(descriptionController, "توضیحات عمومی", maxLines: 4),
              textField(priceController, "قیمت", type: TextInputType.number),
              textField(
                phoneController,
                "شماره تماس",
                type: TextInputType.phone,
              ),
              categorySpecificFields(),
              locationFields(),
              imagePickerSection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : submitAd,
                  child: Text(
                    loading
                        ? (isEditMode
                            ? "در حال ویرایش..."
                            : "در حال ثبت آگهی...")
                        : (isEditMode ? "ذخیره تغییرات" : "ثبت آگهی"),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: categorySelected ? buildFormPage() : buildCategoryList(),
    );
  }
}