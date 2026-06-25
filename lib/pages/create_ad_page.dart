import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'auth_page.dart';

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

  final propertyTypeController = TextEditingController();
  final documentController = TextEditingController();
  final facilityController = TextEditingController();
  final directionController = TextEditingController();
  final bathroomController = TextEditingController();
  final kitchenController = TextEditingController();
  final parkingController = TextEditingController();
  final waterPowerController = TextEditingController();
  final landUseController = TextEditingController();
  final frontageController = TextEditingController();
  final heightController = TextEditingController();

  final kmController = TextEditingController();
  final fuelController = TextEditingController();
  final gearController = TextEditingController();

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
    final phone = Session.userPhone;

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

    readDescription(adText("description"));

    final images = widget.ad?["images"];

    if (images is List) {
      for (final img in images) {
        final url = Api.fullImageUrl(img.toString());
        if (url.isNotEmpty && !existingImageUrls.contains(url)) {
          existingImageUrls.add(url);
        }
      }
    }

    final imageUrl = Api.fullImageUrl(adText("image_url"));

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
    } else if (key == "وضعیت") {
      conditionController.text = value;
    } else if (key == "اندازه/حافظه/ظرفیت") {
      sizeController.text = value;
    } else if (key == "کیلومتر") {
      kmController.text = value;
    } else if (key == "تیل") {
      fuelController.text = value;
    } else if (key == "گیربکس") {
      gearController.text = value;
    } else if (key == "اسناد/پلاک" || key == "نوع سند") {
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
    } else if (key == "نوع ملک") {
      propertyTypeController.text = value;
    } else if (key == "امکانات") {
      facilityController.text = value;
    } else if (key == "جهت زمین") {
      directionController.text = value;
    } else if (key == "تعداد تشناب") {
      bathroomController.text = value;
    } else if (key == "آشپزخانه") {
      kitchenController.text = value;
    } else if (key == "پارکینگ") {
      parkingController.text = value;
    } else if (key == "آب و برق") {
      waterPowerController.text = value;
    } else if (key == "نوع استفاده زمین") {
      landUseController.text = value;
    } else if (key == "بر جاده") {
      frontageController.text = value;
    } else if (key == "ارتفاع") {
      heightController.text = value;
    } else if (key == "آدرس دقیق" || key == "آدرس") {
      addressController.text = value;
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
  void clearCategoryFields() {
    brandController.clear();
    modelController.clear();
    yearController.clear();
    colorController.clear();
    sizeController.clear();
    conditionController.clear();

    meterController.clear();
    roomsController.clear();
    floorController.clear();
    addressController.clear();
    rentController.clear();
    depositController.clear();

    propertyTypeController.clear();
    documentController.clear();
    facilityController.clear();
    directionController.clear();
    bathroomController.clear();
    kitchenController.clear();
    parkingController.clear();
    waterPowerController.clear();
    landUseController.clear();
    frontageController.clear();
    heightController.clear();

    kmController.clear();
    fuelController.clear();
    gearController.clear();

    salaryController.clear();
    workTimeController.clear();
    experienceController.clear();
  }

  void selectCategory(String main, String sub) {
    setState(() {
      mainCategory = main;
      subCategory = sub;
      categoryId = getCategoryId(main, sub);
      categorySelected = true;

      if (!isEditMode) {
        clearCategoryFields();
      }
    });
  }

  void backToCategories() {
    setState(() {
      categorySelected = false;
    });
  }

  Future<bool> ensureLoggedIn() async {
    if (Session.isLoggedIn) {
      fillPhoneFromLoggedUser();
      return true;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );

    if (result == true && Session.isLoggedIn) {
      fillPhoneFromLoggedUser();
      setState(() {});
      return true;
    }

    showMessage("لطفاً وارد حساب خود شوید");
    return false;
  }

  Future<void> openAuthForChangeAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );

    if (result == true && Session.isLoggedIn) {
      fillPhoneFromLoggedUser();
      setState(() {});
    }
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
      return await Api.uploadImageBytes(
        bytes: await image.readAsBytes(),
        filename: image.name,
      );
    } catch (_) {
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

  bool get isPropertyForRent {
    return subCategory == "خانه کرایی" ||
        subCategory == "آپارتمان" ||
        subCategory == "دکان و مغازه" ||
        subCategory == "دفتر کار" ||
        subCategory == "گدام";
  }

  bool get isHouseLikeProperty {
    return subCategory == "خانه فروشی" ||
        subCategory == "خانه کرایی" ||
        subCategory == "آپارتمان";
  }

  bool get isLandProperty {
    return subCategory == "زمین";
  }

  bool get isShopProperty {
    return subCategory == "دکان و مغازه";
  }

  bool get isOfficeProperty {
    return subCategory == "دفتر کار";
  }

  bool get isWarehouseProperty {
    return subCategory == "گدام";
  }

  void writeIfNotEmpty(
    StringBuffer buffer,
    String label,
    TextEditingController controller,
  ) {
    final value = controller.text.trim();

    if (value.isNotEmpty) {
      buffer.writeln("$label: $value");
    }
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

      writeIfNotEmpty(buffer, "برند/نوع", brandController);
      writeIfNotEmpty(buffer, "مدل", modelController);
      writeIfNotEmpty(buffer, "سال ساخت", yearController);
      writeIfNotEmpty(buffer, "رنگ", colorController);

      if (subCategory == "موتر" || subCategory == "موترسایکل") {
        writeIfNotEmpty(buffer, "کیلومتر", kmController);
        writeIfNotEmpty(buffer, "تیل", fuelController);
        writeIfNotEmpty(buffer, "گیربکس", gearController);
        writeIfNotEmpty(buffer, "اسناد/پلاک", documentController);
      }

      if (subCategory == "بایسکل") {
        writeIfNotEmpty(buffer, "مدل/اندازه", modelController);
        writeIfNotEmpty(buffer, "وضعیت", conditionController);
      }

      if (subCategory == "پرزه موتر" || subCategory == "تایر و پرزه") {
        writeIfNotEmpty(buffer, "مدل/اندازه", modelController);
        writeIfNotEmpty(buffer, "وضعیت", conditionController);
      }
    }

    if (mainCategory == "املاک") {
      buffer.writeln();
      buffer.writeln("مشخصات ملک:");

      writeIfNotEmpty(buffer, "نوع ملک", propertyTypeController);
      writeIfNotEmpty(buffer, "متراژ", meterController);

      if (isHouseLikeProperty) {
        writeIfNotEmpty(buffer, "تعداد اتاق", roomsController);
        writeIfNotEmpty(buffer, "تعداد تشناب", bathroomController);
        writeIfNotEmpty(buffer, "آشپزخانه", kitchenController);
        writeIfNotEmpty(buffer, "طبقه/منزل", floorController);
        writeIfNotEmpty(buffer, "پارکینگ", parkingController);
        writeIfNotEmpty(buffer, "نوع سند", documentController);
        writeIfNotEmpty(buffer, "امکانات", facilityController);
      }

      if (isLandProperty) {
        writeIfNotEmpty(buffer, "نوع استفاده زمین", landUseController);
        writeIfNotEmpty(buffer, "نوع سند", documentController);
        writeIfNotEmpty(buffer, "جهت زمین", directionController);
        writeIfNotEmpty(buffer, "بر جاده", frontageController);
        writeIfNotEmpty(buffer, "آب و برق", waterPowerController);
      }

      if (isShopProperty) {
        writeIfNotEmpty(buffer, "طبقه/منزل", floorController);
        writeIfNotEmpty(buffer, "بر جاده", frontageController);
        writeIfNotEmpty(buffer, "آب و برق", waterPowerController);
        writeIfNotEmpty(buffer, "نوع سند", documentController);
        writeIfNotEmpty(buffer, "امکانات", facilityController);
      }

      if (isOfficeProperty) {
        writeIfNotEmpty(buffer, "تعداد اتاق", roomsController);
        writeIfNotEmpty(buffer, "تعداد تشناب", bathroomController);
        writeIfNotEmpty(buffer, "طبقه/منزل", floorController);
        writeIfNotEmpty(buffer, "پارکینگ", parkingController);
        writeIfNotEmpty(buffer, "آب و برق", waterPowerController);
        writeIfNotEmpty(buffer, "امکانات", facilityController);
      }

      if (isWarehouseProperty) {
        writeIfNotEmpty(buffer, "ارتفاع", heightController);
        writeIfNotEmpty(buffer, "آب و برق", waterPowerController);
        writeIfNotEmpty(buffer, "بر جاده", frontageController);
        writeIfNotEmpty(buffer, "نوع سند", documentController);
        writeIfNotEmpty(buffer, "امکانات", facilityController);
      }

      if (isPropertyForRent) {
        writeIfNotEmpty(buffer, "کرایه", rentController);
        writeIfNotEmpty(buffer, "گروی", depositController);
      }

      writeIfNotEmpty(buffer, "آدرس دقیق", addressController);
    }
    if (mainCategory == "لوازم الکترونیکی") {
      buffer.writeln();
      buffer.writeln("مشخصات وسیله:");

      writeIfNotEmpty(buffer, "برند", brandController);
      writeIfNotEmpty(buffer, "مدل", modelController);
      writeIfNotEmpty(buffer, "سال/نسخه", yearController);
      writeIfNotEmpty(buffer, "رنگ", colorController);
      writeIfNotEmpty(buffer, "اندازه/حافظه/ظرفیت", sizeController);
      writeIfNotEmpty(buffer, "وضعیت", conditionController);
    }

    if (mainCategory == "مربوط به خانه" ||
        mainCategory == "وسایل شخصی" ||
        mainCategory == "سرگرمی و فراغت" ||
        mainCategory == "لوازم کودک" ||
        mainCategory == "برای کسب و کار") {
      buffer.writeln();
      buffer.writeln("مشخصات کالا:");

      writeIfNotEmpty(buffer, "برند/نوع", brandController);
      writeIfNotEmpty(buffer, "مدل/اندازه", modelController);
      writeIfNotEmpty(buffer, "رنگ", colorController);
      writeIfNotEmpty(buffer, "وضعیت", conditionController);
    }

    if (mainCategory == "خدمات" || mainCategory == "استخدام و کاریابی") {
      buffer.writeln();
      buffer.writeln("مشخصات کار/خدمات:");

      writeIfNotEmpty(buffer, "عنوان", brandController);
      writeIfNotEmpty(buffer, "معاش/قیمت", salaryController);
      writeIfNotEmpty(buffer, "وقت کاری", workTimeController);
      writeIfNotEmpty(buffer, "تجربه لازم", experienceController);
      writeIfNotEmpty(buffer, "آدرس", addressController);
    }

    return buffer.toString();
  }

  Future<void> submitAd() async {
    if (loading) return;

    final logged = await ensureLoggedIn();
    if (!logged) return;

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

    setState(() => loading = true);

    try {
      final ownerToken = await Session.getOwnerToken();
      final imageUrls = await uploadAllImages();

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
        "user_id": Session.userId,
      };

      await Api.saveAd(
        isEdit: isEditMode,
        adId: isEditMode ? int.tryParse(widget.ad!["id"].toString()) : null,
        body: body,
      );

      if (!mounted) return;

      showMessage(
        isEditMode ? "آگهی با موفقیت ویرایش شد" : "آگهی با موفقیت ثبت شد",
      );

      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    }

    if (mounted) setState(() => loading = false);
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

  Widget textField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? hint,
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
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
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
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(isEditMode ? "تغییر دسته‌بندی" : "دسته‌بندی آگهی‌ها"),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: mainCategories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = mainCategories[index];
          final color = item["color"] as Color;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(item["icon"] as IconData, color: color),
              ),
              title: Text(
                item["name"].toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                showSubCategories(
                  item["name"].toString(),
                  List<String>.from(item["subs"] as List),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void showSubCategories(String main, List<String> subs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F8FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final sub = subs[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
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
                          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
        onTap: loading ? null : backToCategories,
      ),
    );
  }

  Widget accountCard() {
    final isLogged = Session.isLoggedIn;
    final userName =
        Session.userFullName.isEmpty ? "کاربر عزیز" : Session.userFullName;
    final phone = Session.userPhone;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLogged
              ? [
                  const Color(0xFFE8F5E9),
                  const Color(0xFFF1F8E9),
                ]
              : [
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFF8E1),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLogged ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLogged ? Colors.green.shade600 : Colors.orange.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isLogged ? Icons.verified_user : Icons.person_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogged ? userName : "ورود به حساب",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLogged && phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () async {
                    if (Session.isLoggedIn) {
                      await openAuthForChangeAccount();
                    } else {
                      await ensureLoggedIn();
                      setState(() {});
                    }
                  },
            child: Text(isLogged ? "تغییر" : "ورود"),
          ),
        ],
      ),
    );
  }

  Widget propertyFields() {
    if (isLandProperty) {
      return Column(
        children: [
          sectionTitle("مشخصات زمین"),
          textField(meterController, "متراژ زمین", type: TextInputType.number),
          textField(
            landUseController,
            "نوع استفاده زمین",
            hint: "مثلاً رهایشی، تجارتی، زراعتی",
          ),
          textField(
            documentController,
            "نوع سند",
            hint: "مثلاً قباله، عرفی، رسمی",
          ),
          textField(directionController, "جهت زمین"),
          textField(frontageController, "بر جاده / سرک"),
          textField(waterPowerController, "آب و برق"),
          textField(addressController, "آدرس دقیق زمین", maxLines: 2),
        ],
      );
    }

    if (isShopProperty) {
      return Column(
        children: [
          sectionTitle("مشخصات دکان و مغازه"),
          textField(meterController, "متراژ دکان", type: TextInputType.number),
          textField(floorController, "طبقه / موقعیت"),
          textField(frontageController, "بر جاده / بازار"),
          textField(waterPowerController, "برق، آب یا امکانات"),
          textField(documentController, "نوع سند"),
          textField(facilityController, "امکانات دیگر", maxLines: 2),
          textField(rentController, "کرایه ماهانه", type: TextInputType.number),
          textField(
            depositController,
            "گروی / پیش‌پرداخت",
            type: TextInputType.number,
          ),
          textField(addressController, "آدرس دقیق دکان", maxLines: 2),
        ],
      );
    }

    if (isOfficeProperty) {
      return Column(
        children: [
          sectionTitle("مشخصات دفتر کار"),
          textField(meterController, "متراژ دفتر", type: TextInputType.number),
          textField(roomsController, "تعداد اتاق", type: TextInputType.number),
          textField(
            bathroomController,
            "تعداد تشناب",
            type: TextInputType.number,
          ),
          textField(floorController, "طبقه / منزل"),
          textField(parkingController, "پارکینگ"),
          textField(waterPowerController, "آب، برق، انترنت"),
          textField(facilityController, "امکانات دفتر", maxLines: 2),
          textField(rentController, "کرایه ماهانه", type: TextInputType.number),
          textField(
            depositController,
            "گروی / پیش‌پرداخت",
            type: TextInputType.number,
          ),
          textField(addressController, "آدرس دقیق دفتر", maxLines: 2),
        ],
      );
    }

    if (isWarehouseProperty) {
      return Column(
        children: [
          sectionTitle("مشخصات گدام"),
          textField(meterController, "متراژ گدام", type: TextInputType.number),
          textField(heightController, "ارتفاع گدام"),
          textField(frontageController, "دسترسی موتر / سرک"),
          textField(waterPowerController, "برق، آب یا برق سه‌فاز"),
          textField(documentController, "نوع سند"),
          textField(facilityController, "امکانات گدام", maxLines: 2),
          textField(rentController, "کرایه ماهانه", type: TextInputType.number),
          textField(
            depositController,
            "گروی / پیش‌پرداخت",
            type: TextInputType.number,
          ),
          textField(addressController, "آدرس دقیق گدام", maxLines: 2),
        ],
      );
    }

    return Column(
      children: [
        sectionTitle("مشخصات خانه یا آپارتمان"),
        textField(meterController, "متراژ", type: TextInputType.number),
        textField(roomsController, "تعداد اتاق", type: TextInputType.number),
        textField(
          bathroomController,
          "تعداد تشناب",
          type: TextInputType.number,
        ),
        textField(kitchenController, "آشپزخانه"),
        textField(floorController, "طبقه / منزل / همکف"),
        textField(parkingController, "پارکینگ"),
        textField(documentController, "نوع سند"),
        textField(facilityController, "امکانات", maxLines: 2),
        if (subCategory == "خانه کرایی" || subCategory == "آپارتمان") ...[
          textField(rentController, "کرایه ماهانه", type: TextInputType.number),
          textField(
            depositController,
            "گروی / پیش‌پرداخت",
            type: TextInputType.number,
          ),
        ],
        textField(addressController, "آدرس دقیق", maxLines: 2),
      ],
    );
  }

  Widget vehicleFields() {
    if (subCategory == "بایسکل") {
      return Column(
        children: [
          sectionTitle("مشخصات بایسکل"),
          textField(brandController, "برند / نوع بایسکل"),
          textField(modelController, "مدل / سایز"),
          textField(colorController, "رنگ"),
          textField(conditionController, "وضعیت"),
        ],
      );
    }

    if (subCategory == "پرزه موتر" || subCategory == "تایر و پرزه") {
      return Column(
        children: [
          sectionTitle("مشخصات پرزه"),
          textField(brandController, "نام پرزه / برند"),
          textField(modelController, "مدل / اندازه"),
          textField(conditionController, "وضعیت"),
          textField(colorController, "رنگ"),
        ],
      );
    }

    return Column(
      children: [
        sectionTitle("مشخصات وسیله نقلیه"),
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

  Widget categorySpecificFields() {
    if (mainCategory == "املاک") {
      return propertyFields();
    }

    if (mainCategory == "وسایل نقلیه") {
      return vehicleFields();
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
    final totalImages = existingImageUrls.length + selectedImages.length;

    return Column(
      children: [
        sectionTitle("عکس‌های آگهی"),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : pickImages,
            icon: const Icon(Icons.image),
            label: Text(
              totalImages == 0 ? "انتخاب عکس" : "عکس‌ها ($totalImages/20)",
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
                  final mainIndex = existingImageUrls.length + index;

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
                      if (mainIndex == 0)
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
      ],
    );
  }

  Widget buildFormPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(isEditMode ? "ویرایش آگهی" : "ثبت آگهی"),
        centerTitle: true,
        elevation: 0,
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
              if (!isEditMode) accountCard(),

              categoryHeader(),

              sectionTitle("اطلاعات اصلی"),
              textField(titleController, "عنوان آگهی"),
              textField(
                descriptionController,
                "توضیحات عمومی",
                maxLines: 4,
              ),
              textField(
                priceController,
                mainCategory == "املاک" && isPropertyForRent
                    ? "قیمت / کرایه"
                    : "قیمت",
                type: TextInputType.number,
              ),
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
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    phoneController.dispose();

    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    colorController.dispose();
    sizeController.dispose();
    conditionController.dispose();

    meterController.dispose();
    roomsController.dispose();
    floorController.dispose();
    addressController.dispose();
    rentController.dispose();
    depositController.dispose();

    propertyTypeController.dispose();
    documentController.dispose();
    facilityController.dispose();
    directionController.dispose();
    bathroomController.dispose();
    kitchenController.dispose();
    parkingController.dispose();
    waterPowerController.dispose();
    landUseController.dispose();
    frontageController.dispose();
    heightController.dispose();

    kmController.dispose();
    fuelController.dispose();
    gearController.dispose();

    salaryController.dispose();
    workTimeController.dispose();
    experienceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: categorySelected ? buildFormPage() : buildCategoryList(),
    );
  }
}