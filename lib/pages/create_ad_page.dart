import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  final ImagePicker picker = ImagePicker();

  bool loading = false;
  bool categorySelected = false;
  bool locationLoading = false;

  double? latitude;
  double? longitude;

  String mainCategory = "";
  String subCategory = "";
  int categoryId = 3;

  String province = "هرات";
  String district = "مرکز هرات";

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final colorController = TextEditingController();
  final conditionController = TextEditingController();
  final sizeController = TextEditingController();

  final warrantyController = TextEditingController();
  final originalBoxController = TextEditingController();
  final storageController = TextEditingController();
  final ramController = TextEditingController();
  final processorController = TextEditingController();
  final batteryController = TextEditingController();
  final screenSizeController = TextEditingController();
  final serialController = TextEditingController();
  final accessoriesController = TextEditingController();
  final repairController = TextEditingController();

  final meterController = TextEditingController();
  final roomsController = TextEditingController();
  final floorController = TextEditingController();
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

  static const Color primaryColor = Color(0xFF5B3FD6);
  static const Color bgColor = Color(0xFFF7F8FA);

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
        "پرنتر",
        "اسپیکر و صوتی",
        "کنسول بازی",
        "ساعت هوشمند",
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
  final List<String> provinces = [
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
    "بدغیس",
    "بغلان",
    "دایکندی",
    "فاریاب",
    "غور",
    "جوزجان",
    "کاپیسا",
    "خوست",
    "کنر",
    "کندز",
    "لغمان",
    "لوگر",
    "میدان وردک",
    "نورستان",
    "نیمروز",
    "پکتیا",
    "پکتیکا",
    "پنجشیر",
    "پروان",
    "سمنگان",
    "سرپل",
    "تخار",
    "ارزگان",
    "زابل",
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
      "میر بچه کوت",
    ],
    "قندهار": [
      "مرکز قندهار",
      "دامان",
      "ارغنداب",
      "پنجوایی",
      "ژیری",
      "شاه ولی کوت",
      "میوند",
      "سپین بولدک",
      "معروف",
      "ریگستان",
      "تخته پل",
      "ارغستان",
      "نیش",
      "خاکریز",
      "غورک",
      "میانشین",
    ],
    "بلخ": [
      "مرکز مزار شریف",
      "بلخ",
      "چمتال",
      "چارکنت",
      "دولت‌آباد",
      "دهدادی",
      "خلم",
      "کشنده",
      "کلدار",
      "مارمل",
      "نهر شاهی",
      "شورتپه",
      "زاری",
    ],
    "ننگرهار": [
      "مرکز جلال‌آباد",
      "اچین",
      "بتی کوت",
      "بهسود",
      "چپرهار",
      "دره نور",
      "گوشته",
      "حصارک",
      "خوگیانی",
      "کامه",
      "کوت",
      "کوز کنر",
      "لعل پور",
      "مهمند دره",
      "نازیان",
      "پچیراگام",
      "رودات",
      "شینوار",
      "سرخ رود",
    ],
    "بدخشان": [
      "مرکز فیض‌آباد",
      "ارگو",
      "ارغنجخواه",
      "بهارک",
      "درایم",
      "اشکاشم",
      "جرم",
      "کشم",
      "خواهان",
      "کوف آب",
      "کران و منجان",
      "مایمی",
      "نسی",
      "راغ",
      "شغنان",
      "شهر بزرگ",
      "تشکان",
      "واخان",
      "وردوج",
      "یفتل",
    ],
    "فراه": [
      "مرکز فراه",
      "بالابلوک",
      "بکواه",
      "گلستان",
      "خاک سفید",
      "لاش و جوین",
      "پشت رود",
      "پرچمن",
      "شیب کوه",
      "انار دره",
      "قلعه کاه",
    ],
    "غزنی": [
      "مرکز غزنی",
      "آب بند",
      "اجرستان",
      "اندار",
      "ده یک",
      "گیرو",
      "جاغوری",
      "خواجه عمری",
      "مالستان",
      "مقر",
      "ناوه",
      "ناور",
      "قره باغ",
      "رشیدان",
      "واغظ",
      "ولی محمد شهید",
      "زنه خان",
    ],
    "بامیان": [
      "مرکز بامیان",
      "یکاولنگ",
      "پنجاب",
      "ورس",
      "سیغان",
      "کهمرد",
      "شیبر",
    ],
    "هلمند": [
      "مرکز لشکرگاه",
      "باغران",
      "دیشو",
      "گرمسیر",
      "گرشک",
      "کجکی",
      "خانشین",
      "موسی قلعه",
      "نادعلی",
      "ناوه بارکزایی",
      "نوزاد",
      "ریگ",
      "سنگین",
      "واشیر",
    ],
    "بدغیس": [
      "مرکز قلعه نو",
      "آب کمری",
      "بالا مرغاب",
      "غورماچ",
      "جوند",
      "مقر",
      "قادس",
    ],
    "بغلان": [
      "مرکز پلخمری",
      "اندراب",
      "بغلان مرکزی",
      "برکه",
      "ده صلاح",
      "دوشی",
      "فرنگ و غارو",
      "گذرگاه نور",
      "خنجان",
      "خوست و فرنگ",
      "نهرین",
      "پل حصار",
      "تاله و برفک",
    ],
    "دایکندی": [
      "مرکز نیلی",
      "اشترلی",
      "خدیر",
      "کجران",
      "کیتی",
      "میرامور",
      "سنگ تخت",
      "شهرستان",
    ],
    "فاریاب": [
      "مرکز میمنه",
      "المار",
      "اندخوی",
      "بلچراغ",
      "دولت‌آباد",
      "گرزیوان",
      "خان چهارباغ",
      "خواجه سبزپوش",
      "کوهستان",
      "قرغان",
      "قیصار",
      "شیرین تگاب",
    ],
    "غور": [
      "مرکز فیروزکوه",
      "چغچران",
      "چارسده",
      "دولینه",
      "دولت یار",
      "لعل و سرجنگل",
      "پسابند",
      "ساغر",
      "شهرک",
      "تیوره",
      "تولک",
    ],
    "جوزجان": [
      "مرکز شبرغان",
      "آقچه",
      "درزاب",
      "فیض‌آباد",
      "خم آب",
      "خواجه دوکوه",
      "مردیان",
      "منگجک",
      "قرقین",
    ],
    "کاپیسا": [
      "مرکز محمود راقی",
      "اله سای",
      "حصه اول کوهستان",
      "حصه دوم کوهستان",
      "کوه بند",
      "نجراب",
      "تگاب",
    ],
    "خوست": [
      "مرکز خوست",
      "باک",
      "گربز",
      "جانی خیل",
      "مندوزی",
      "نادرشاه کوت",
      "قلندر",
      "صبری",
      "شمل",
      "سپیره",
      "تنی",
      "تیرزایی",
    ],
    "کنر": [
      "مرکز اسعدآباد",
      "برکنر",
      "چپه دره",
      "دانگام",
      "دره پیچ",
      "غازی آباد",
      "خاص کنر",
      "مروره",
      "ناری",
      "نورگل",
      "سرکانی",
      "شیگل",
      "وته پور",
    ],
    "کندز": [
      "مرکز کندز",
      "علی آباد",
      "چهاردره",
      "خان آباد",
      "قلعه زال",
      "امام صاحب",
      "دشت ارچی",
    ],
    "لغمان": [
      "مرکز مهترلام",
      "الینگار",
      "علیشنگ",
      "دولت شاه",
      "قرغه‌ای",
    ],
    "لوگر": [
      "مرکز پل علم",
      "برکی برک",
      "خوشی",
      "محمد آغه",
      "چرخ",
      "خروار",
      "ازره",
    ],
    "میدان وردک": [
      "مرکز میدان شهر",
      "چک",
      "دایمیرداد",
      "حصه اول بهسود",
      "جلریز",
      "مرکز بهسود",
      "نرخ",
      "سیدآباد",
    ],
    "نورستان": [
      "مرکز پارون",
      "برگ متال",
      "دوآب",
      "کامدیش",
      "مندول",
      "نورگرام",
      "واما",
      "وایگل",
    ],
    "نیمروز": [
      "مرکز زرنج",
      "چهاربرجک",
      "چخانسور",
      "خاشرود",
      "کنگ",
    ],
    "پکتیا": [
      "مرکز گردیز",
      "احمدآباد",
      "جانی خیل",
      "لجه منگل",
      "سید کرم",
      "شواک",
      "وزی زدران",
      "زازی",
      "زرمت",
    ],
    "پکتیکا": [
      "مرکز شرنه",
      "برمل",
      "دیله",
      "گومل",
      "گیان",
      "جانی خیل",
      "مته خان",
      "نکه",
      "اورگون",
      "سروبی",
      "سرحوضه",
      "وازه خواه",
      "یحیی خیل",
      "یوسف خیل",
      "زیروک",
    ],
    "پنجشیر": [
      "مرکز بازارک",
      "عنابه",
      "دره",
      "پریان",
      "رخه",
      "شتل",
    ],
    "پروان": [
      "مرکز چاریکار",
      "بگرام",
      "جبل السراج",
      "سالنگ",
      "سیدخیل",
      "شیخ علی",
      "شینواری",
      "سرخ پارسا",
    ],
    "سمنگان": [
      "مرکز ایبک",
      "دره صوف بالا",
      "دره صوف پایین",
      "حضرت سلطان",
      "خرم و سارباغ",
      "روی دوآب",
    ],
    "سرپل": [
      "مرکز سرپل",
      "بلخاب",
      "گوسفندی",
      "کوهستانات",
      "صیاد",
      "سوزمه قلعه",
    ],
    "تخار": [
      "مرکز تالقان",
      "بهارک",
      "بنگی",
      "چاه آب",
      "چال",
      "درقد",
      "دشت قلعه",
      "فرخار",
      "کلفگان",
      "خواجه بهاءالدین",
      "خواجه غار",
      "نمک آب",
      "رستاق",
      "ورسج",
      "ینگی قلعه",
    ],
    "ارزگان": [
      "مرکز ترینکوت",
      "چوره",
      "دهراوود",
      "گیزاب",
      "خاص ارزگان",
      "شهید حساس",
    ],
    "زابل": [
      "مرکز قلات",
      "ارغنداب",
      "اتغر",
      "دایچوپان",
      "کاکر",
      "میزان",
      "نوبهار",
      "شاه جوی",
      "شملزی",
      "شینکی",
      "ترنک و جلدک",
    ],
  };

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      loadAdForEdit();
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
    addressController.text = adText("address");

    latitude = double.tryParse(adText("latitude"));
    longitude = double.tryParse(adText("longitude"));

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

    if (!provinces.contains(province)) {
      province = "هرات";
    }

    final districtList = districts[province] ?? ["مرکز هرات"];
    if (!districtList.contains(district)) {
      district = districtList.first;
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

      if (text.startsWith("آدرس دقیق:")) {
        if (addressController.text.trim().isEmpty) {
          addressController.text = text.replaceFirst("آدرس دقیق:", "").trim();
        }
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
    } else if (key == "سال ساخت" ||
        key == "سال/نسخه" ||
        key == "سال / نسخه") {
      yearController.text = value;
    } else if (key == "رنگ") {
      colorController.text = value;
    } else if (key == "وضعیت") {
      conditionController.text = value;
    } else if (key == "اندازه/حافظه/ظرفیت" ||
        key == "اندازه / ظرفیت کلی") {
      sizeController.text = value;
    } else if (key == "گارانتی") {
      warrantyController.text = value;
    } else if (key == "جعبه اصلی") {
      originalBoxController.text = value;
    } else if (key == "حافظه داخلی") {
      storageController.text = value;
    } else if (key == "رم") {
      ramController.text = value;
    } else if (key == "پردازنده") {
      processorController.text = value;
    } else if (key == "باتری" || key == "وضعیت باتری") {
      batteryController.text = value;
    } else if (key == "اندازه صفحه") {
      screenSizeController.text = value;
    } else if (key == "سریال / IMEI" || key == "سریال/IMEI") {
      serialController.text = value;
    } else if (key == "لوازم همراه") {
      accessoriesController.text = value;
    } else if (key == "سابقه تعمیر") {
      repairController.text = value;
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
    conditionController.clear();
    sizeController.clear();

    warrantyController.clear();
    originalBoxController.clear();
    storageController.clear();
    ramController.clear();
    processorController.clear();
    batteryController.clear();
    screenSizeController.clear();
    serialController.clear();
    accessoriesController.clear();
    repairController.clear();

    meterController.clear();
    roomsController.clear();
    floorController.clear();
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
    if (Session.isLoggedIn) return true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );

    if (result == true && Session.isLoggedIn) {
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
      setState(() {});
    }
  }
  //===================== IMAGES =====================//

Future<void> pickImages() async {
  if (loading) return;

  final files = await picker.pickMultiImage(
    imageQuality: 85,
  );

  if (files.isEmpty) return;

  final remain = 20 - (selectedImages.length + existingImageUrls.length);

  if (remain <= 0) {
    showMessage("حداکثر ۲۰ عکس مجاز است");
    return;
  }

  final picked = files.take(remain).toList();

  for (final f in picked) {
    selectedImages.add(f);
    selectedImageBytes.add(await f.readAsBytes());
  }

  setState(() {});
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
  final result = <String>[];

  result.addAll(existingImageUrls);

  for (final img in selectedImages) {
    final url = await uploadOneImage(img);

    if (url != null && url.isNotEmpty) {
      result.add(url);
    }
  }

  return result;
}

//===================== GPS =====================//

Future<void> detectCurrentLocation() async {
  if (locationLoading) return;

  setState(() => locationLoading = true);

  try {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      showMessage("GPS خاموش است. موقعیت اختیاری است، می‌توانید بدون آن هم ثبت کنید.");
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      showMessage("اجازه موقعیت داده نشد. موقعیت اختیاری است.");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String foundAddress = "";

    try {
      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (places.isNotEmpty) {
        final p = places.first;

        foundAddress = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).join("، ");
      }
    } catch (_) {}

    setState(() {
      latitude = pos.latitude;
      longitude = pos.longitude;

      if (foundAddress.isNotEmpty) {
        addressController.text = foundAddress;
      }
    });

    showMessage("موقعیت ثبت شد. این بخش اختیاری است.");
  } catch (_) {
    showMessage("موقعیت گرفته نشد. بدون موقعیت هم می‌توانید آگهی ثبت کنید.");
  } finally {
    if (mounted) {
      setState(() => locationLoading = false);
    }
  }
}

//===================== PROPERTY TYPE =====================//

bool get isPropertyForRent =>
    subCategory == "خانه کرایی" ||
    subCategory == "آپارتمان" ||
    subCategory == "دفتر کار" ||
    subCategory == "دکان و مغازه" ||
    subCategory == "گدام";

bool get isHouseLikeProperty =>
    subCategory == "خانه فروشی" ||
    subCategory == "خانه کرایی" ||
    subCategory == "آپارتمان";

bool get isLandProperty => subCategory == "زمین";

bool get isShopProperty => subCategory == "دکان و مغازه";

bool get isOfficeProperty => subCategory == "دفتر کار";

bool get isWarehouseProperty => subCategory == "گدام";

//===================== DESCRIPTION =====================//

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
  final buffer = StringBuffer();

  final normal = descriptionController.text.trim();
  if (normal.isNotEmpty) {
    buffer.writeln(normal);
    buffer.writeln();
  }

  buffer.writeln("دسته اصلی: $mainCategory");
  buffer.writeln("زیر دسته: $subCategory");
  buffer.writeln("ولایت: $province");
  buffer.writeln("ولسوالی: $district");

  final address = addressController.text.trim();
  if (address.isNotEmpty) {
    buffer.writeln("آدرس دقیق: $address");
  }

  if (latitude != null && longitude != null) {
    buffer.writeln("مختصات: $latitude,$longitude");
  }

  writeIfNotEmpty(buffer, "برند/نوع", brandController);
  writeIfNotEmpty(buffer, "مدل", modelController);
  writeIfNotEmpty(buffer, "سال ساخت", yearController);
  writeIfNotEmpty(buffer, "رنگ", colorController);
  writeIfNotEmpty(buffer, "وضعیت", conditionController);
  writeIfNotEmpty(buffer, "متراژ", meterController);
  writeIfNotEmpty(buffer, "تعداد اتاق", roomsController);
  writeIfNotEmpty(buffer, "تعداد تشناب", bathroomController);
  writeIfNotEmpty(buffer, "کیلومتر", kmController);
  writeIfNotEmpty(buffer, "تیل", fuelController);
  writeIfNotEmpty(buffer, "گیربکس", gearController);
  writeIfNotEmpty(buffer, "نوع سند", documentController);
  writeIfNotEmpty(buffer, "امکانات", facilityController);
  writeIfNotEmpty(buffer, "کرایه", rentController);
  writeIfNotEmpty(buffer, "گروی", depositController);
  writeIfNotEmpty(buffer, "معاش/قیمت", salaryController);
  writeIfNotEmpty(buffer, "وقت کاری", workTimeController);
  writeIfNotEmpty(buffer, "تجربه لازم", experienceController);

  return buffer.toString();
}

//===================== SUBMIT =====================//

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

  if (addressController.text.trim().isEmpty) {
    showMessage("آدرس دقیق را وارد کنید");
    return;
  }


  setState(() {
    loading = true;
  });

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
      "address": addressController.text.trim(),
      "category_id": categoryId,
      "image_url": imageUrls.isEmpty ? null : imageUrls.first,
      "images": imageUrls,
      "owner_token": ownerToken,
      "user_id": Session.userId,
      "latitude": latitude,
      "longitude": longitude,
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

  if (mounted) {
    setState(() {
      loading = false;
    });
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

Widget sectionCard({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

Widget textField(
  TextEditingController controller,
  String label, {
  TextInputType type = TextInputType.text,
  int maxLines = 1,
  String? hint,
  bool required = false,
}) {
  final isNumber = type == TextInputType.number;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : type,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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

Widget accountCard() {
  final isLogged = Session.isLoggedIn;
  final userName =
      Session.userFullName.isEmpty ? "کاربر عزیز" : Session.userFullName;

  return sectionCard(
    title: "حساب کاربری",
    icon: Icons.person,
    children: [
      Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            backgroundColor: isLogged ? Colors.green : Colors.orange,
            child: Icon(
              isLogged ? Icons.verified_user : Icons.login,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLogged ? userName : "برای ثبت آگهی وارد حساب شوید",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () async {
                    if (isLogged) {
                      await openAuthForChangeAccount();
                    } else {
                      await ensureLoggedIn();
                    }
                  },
            child: Text(isLogged ? "تغییر حساب" : "ورود"),
          ),
        ],
      ),
    ],
  );
}
Widget buildFormPage() {
  return Scaffold(
    backgroundColor: const Color(0xffF5F7FA),
    appBar: AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        isEditMode ? "ویرایش آگهی" : "ثبت آگهی جدید",
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: loading ? null : backToCategories,
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            if (!isEditMode) accountCard(),

            categoryHeader(),

            sectionCard(
              title: "اطلاعات اصلی",
              icon: Icons.description,
              children: [

                textField(
                  titleController,
                  "عنوان آگهی",
                  required: true,
                ),

                textField(
                  descriptionController,
                  "توضیحات",
                  maxLines: 5,
                ),

                textField(
                  priceController,
                  "قیمت",
                  type: TextInputType.number,
                ),

                /// شماره تماس دیگر خودکار نیست
                textField(
                  phoneController,
                  "شماره تماس",
                  type: TextInputType.phone,
                  required: true,
                ),
              ],
            ),

            sectionCard(
              title: "مشخصات دسته بندی",
              icon: Icons.category,
              children: [

                categorySpecificFields(),

              ],
            ),

            sectionCard(
              title: "موقعیت",
              icon: Icons.location_on,
              children: [

                locationFields(),

              ],
            ),

            sectionCard(
              title: "تصاویر",
              icon: Icons.photo_library,
              children: [

                imagePickerSection(),

              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),

                label: Text(
                  loading
                      ? "در حال ثبت..."
                      : isEditMode
                          ? "ذخیره تغییرات"
                          : "ثبت آگهی",
                ),

                onPressed: loading
                    ? null
                    : submitAd,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
Widget categoryHeader() {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: primaryColor.withOpacity(0.15)),
    ),
    child: InkWell(
      onTap: loading ? null : backToCategories,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.category, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$mainCategory / $subCategory",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.edit, size: 20),
        ],
      ),
    ),
  );
}

Widget locationFields() {
  final districtList = districts[province] ?? ["مرکز هرات"];
  final hasGps = latitude != null && longitude != null;

  return Column(
    children: [
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
        label: "ولسوالی / ناحیه",
        items: districtList,
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            district = v;
          });
        },
      ),
      textField(
        addressController,
        "آدرس دقیق",
        maxLines: 2,
        required: true,
        hint: "مثلاً: ناحیه دوازده، نزدیک مسجد، سرک عمومی",
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasGps
              ? Colors.green.withOpacity(0.08)
              : Colors.deepPurple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasGps
                ? Colors.green.withOpacity(0.35)
                : Colors.deepPurple.withOpacity(0.22),
          ),
        ),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  hasGps ? Icons.check_circle : Icons.my_location,
                  color: hasGps ? Colors.green : primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasGps
                        ? "موقعیت GPS ثبت شده است"
                        : "برای فیلتر کیلومتری، موقعیت GPS را ثبت کنید",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: hasGps ? Colors.green.shade700 : primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (hasGps) ...[
              const SizedBox(height: 8),
              Text(
                "Lat: ${latitude!.toStringAsFixed(6)}   Lng: ${longitude!.toStringAsFixed(6)}",
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: locationLoading ? null : detectCurrentLocation,
                icon: locationLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(hasGps ? Icons.refresh : Icons.gps_fixed),
                label: Text(
                  locationLoading
                      ? "در حال دریافت موقعیت..."
                      : hasGps
                          ? "گرفتن دوباره موقعیت"
                          : "ثبت موقعیت فعلی",
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget imagePickerSection() {
  final total = existingImageUrls.length + selectedImages.length;

  return Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: loading ? null : pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(total == 0 ? "انتخاب عکس" : "افزودن عکس ($total/20)"),
        ),
      ),
      const SizedBox(height: 12),
      if (total == 0)
        Text(
          "اضافه کردن عکس باعث اعتماد بیشتر خریدار می‌شود.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      if (existingImageUrls.isNotEmpty || selectedImageBytes.isNotEmpty)
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            children: [
              ...existingImageUrls.asMap().entries.map((entry) {
                return imagePreview(
                  child: Image.network(
                    entry.value,
                    fit: BoxFit.cover,
                    width: 82,
                    height: 82,
                  ),
                  onRemove: () => removeExistingImage(entry.key),
                );
              }),
              ...selectedImageBytes.asMap().entries.map((entry) {
                return imagePreview(
                  child: Image.memory(
                    entry.value,
                    fit: BoxFit.cover,
                    width: 82,
                    height: 82,
                  ),
                  onRemove: () => removeNewImage(entry.key),
                );
              }),
            ],
          ),
        ),
    ],
  );
}

Widget imagePreview({
  required Widget child,
  required VoidCallback onRemove,
}) {
  return Container(
    margin: const EdgeInsets.only(left: 8),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
        Positioned(
          top: 2,
          left: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget propertyFields() {
  if (isLandProperty) {
    return Column(
      children: [
        textField(meterController, "متراژ زمین", type: TextInputType.number),
        textField(landUseController, "نوع استفاده زمین"),
        textField(documentController, "نوع سند"),
        textField(directionController, "جهت زمین"),
        textField(frontageController, "بر جاده / سرک"),
        textField(waterPowerController, "آب و برق"),
      ],
    );
  }

  return Column(
    children: [
      textField(meterController, "متراژ", type: TextInputType.number),
      textField(roomsController, "تعداد اتاق", type: TextInputType.number),
      textField(bathroomController, "تعداد تشناب", type: TextInputType.number),
      textField(kitchenController, "آشپزخانه"),
      textField(floorController, "طبقه / منزل"),
      textField(parkingController, "پارکینگ"),
      textField(documentController, "نوع سند"),
      textField(facilityController, "امکانات", maxLines: 2),
      if (isPropertyForRent) ...[
        textField(rentController, "کرایه ماهانه", type: TextInputType.number),
        textField(depositController, "گروی / پیش‌پرداخت", type: TextInputType.number),
      ],
    ],
  );
}

Widget vehicleFields() {
  return Column(
    children: [
      textField(brandController, "برند یا نوع وسیله"),
      textField(modelController, "مدل"),
      textField(yearController, "سال ساخت", type: TextInputType.number),
      textField(kmController, "کیلومتر کارکرد", type: TextInputType.number),
      textField(colorController, "رنگ"),
      textField(fuelController, "نوع تیل"),
      textField(gearController, "گیربکس"),
      textField(documentController, "اسناد / نمبر پلیت"),
    ],
  );
}

Widget categorySpecificFields() {
  if (mainCategory == "املاک") return propertyFields();
  if (mainCategory == "وسایل نقلیه") return vehicleFields();

  if (mainCategory == "لوازم الکترونیکی") {
    return Column(
      children: [
        textField(brandController, "برند"),
        textField(modelController, "مدل"),
        textField(yearController, "سال / نسخه"),
        textField(colorController, "رنگ"),
        textField(sizeController, "اندازه / ظرفیت"),
        textField(storageController, "حافظه داخلی"),
        textField(ramController, "رم"),
        textField(processorController, "پردازنده"),
        textField(batteryController, "وضعیت باتری"),
        textField(screenSizeController, "اندازه صفحه"),
        textField(warrantyController, "گارانتی"),
        textField(originalBoxController, "جعبه اصلی"),
        textField(serialController, "سریال / IMEI"),
        textField(accessoriesController, "لوازم همراه", maxLines: 2),
        textField(repairController, "سابقه تعمیر", maxLines: 2),
        textField(conditionController, "وضعیت"),
      ],
    );
  }

  if (mainCategory == "خدمات" || mainCategory == "استخدام و کاریابی") {
    return Column(
      children: [
        textField(brandController, "عنوان کار یا خدمات"),
        textField(salaryController, "معاش / قیمت خدمات"),
        textField(workTimeController, "وقت کاری"),
        textField(experienceController, "تجربه لازم"),
      ],
    );
  }

  return Column(
    children: [
      textField(brandController, "برند / نوع"),
      textField(modelController, "مدل / اندازه"),
      textField(colorController, "رنگ"),
      textField(conditionController, "وضعیت"),
    ],
  );
}

Widget buildCategoryList() {
  return Scaffold(
    backgroundColor: bgColor,
    appBar: AppBar(
      title: Text(isEditMode ? "تغییر دسته‌بندی" : "انتخاب دسته‌بندی"),
      centerTitle: true,
    ),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mainCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = mainCategories[index];
        final color = item["color"] as Color;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(item["icon"] as IconData, color: color),
            ),
            title: Text(
              item["name"].toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: subs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      main,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final sub = subs[index - 1];

                return Card(
                  child: ListTile(
                    title: Text(sub, textAlign: TextAlign.right),
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
        ),
      );
    },
  );
}

@override
void dispose() {
  titleController.dispose();
  descriptionController.dispose();
  priceController.dispose();
  phoneController.dispose();
  addressController.dispose();

  brandController.dispose();
  modelController.dispose();
  yearController.dispose();
  colorController.dispose();
  conditionController.dispose();
  sizeController.dispose();

  warrantyController.dispose();
  originalBoxController.dispose();
  storageController.dispose();
  ramController.dispose();
  processorController.dispose();
  batteryController.dispose();
  screenSizeController.dispose();
  serialController.dispose();
  accessoriesController.dispose();
  repairController.dispose();

  meterController.dispose();
  roomsController.dispose();
  floorController.dispose();
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