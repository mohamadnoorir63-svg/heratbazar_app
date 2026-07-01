import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/lang.dart';
import 'auth_page.dart';

class CreateAdPage extends StatefulWidget {
  final Map? ad;

  const CreateAdPage({super.key, this.ad});

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

  String mainCategoryKey = '';
  String subCategoryKey = '';
  int categoryId = 3;

  String province = 'هرات';
  String district = 'مرکز هرات';

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final Map<String, TextEditingController> fieldControllers = {};

  final List<XFile> selectedImages = [];
  final List<Uint8List> selectedImageBytes = [];
  final List<String> existingImageUrls = [];

  bool get isEditMode => widget.ad != null;

  static const Color primaryColor = Color(0xFF5B3FD6);
  static const Color bgColor = Color(0xFFF7F8FA);

  String tr(String key) => T.tr(key);

  TextEditingController c(String key) {
    return fieldControllers.putIfAbsent(key, () => TextEditingController());
  }

  final List<Map<String, dynamic>> mainCategories = const [
    {
      'key': 'cat_real_estate',
      'icon': Icons.apartment,
      'color': Colors.deepPurple,
      'subs': [
        'sub_house_sale','sub_house_rent','sub_apartment_sale','sub_apartment_rent','sub_land','sub_shop_sale','sub_shop_rent','sub_office_sale','sub_office_rent','sub_warehouse','sub_farm','sub_garden','sub_room_rent'
      ],
    },
    {
      'key': 'cat_vehicles',
      'icon': Icons.directions_car,
      'color': Colors.blue,
      'subs': [
        'sub_car','sub_motorcycle','sub_bicycle','sub_truck','sub_bus','sub_van','sub_rickshaw','sub_car_parts','sub_tires_parts','sub_vehicle_accessories'
      ],
    },
    {
      'key': 'cat_electronics',
      'icon': Icons.devices,
      'color': Colors.teal,
      'subs': [
        'sub_mobile','sub_laptop','sub_computer','sub_tablet','sub_tv','sub_fridge','sub_washing_machine','sub_camera','sub_generator','sub_printer','sub_speaker','sub_console','sub_smart_watch','sub_router','sub_solar_panel','sub_electronic_parts'
      ],
    },
    {
      'key': 'cat_home',
      'icon': Icons.chair,
      'color': Colors.orange,
      'subs': [
        'sub_furniture','sub_carpet','sub_dishes','sub_kitchen_items','sub_bedding','sub_home_decor','sub_tools','sub_garden_tools','sub_cleaning_items'
      ],
    },
    {
      'key': 'cat_services',
      'icon': Icons.handyman,
      'color': Colors.green,
      'subs': [
        'sub_construction_services','sub_technical_services','sub_health_services','sub_education_services','sub_transport_services','sub_home_services','sub_repair_services','sub_legal_services','sub_event_services','sub_design_services'
      ],
    },
    {
      'key': 'cat_personal',
      'icon': Icons.watch,
      'color': Colors.pink,
      'subs': [
        'sub_clothes','sub_shoes','sub_watch','sub_perfume','sub_jewelry','sub_bag','sub_cosmetics','sub_glasses'
      ],
    },
    {
      'key': 'cat_entertainment',
      'icon': Icons.sports_esports,
      'color': Colors.indigo,
      'subs': [
        'sub_book','sub_toy','sub_sport','sub_music','sub_games','sub_bicycle_sport','sub_pet_supplies'
      ],
    },
    {
      'key': 'cat_kids',
      'icon': Icons.child_care,
      'color': Colors.cyan,
      'subs': [
        'sub_kids_clothes','sub_stroller','sub_kids_toy','sub_kids_bed','sub_school_items','sub_baby_items','sub_kids_bicycle'
      ],
    },
    {
      'key': 'cat_business',
      'icon': Icons.store,
      'color': Colors.brown,
      'subs': [
        'sub_shop_equipment','sub_restaurant_equipment','sub_office_equipment','sub_machinery','sub_raw_materials','sub_agriculture_equipment','sub_medical_equipment','sub_factory_equipment'
      ],
    },
    {
      'key': 'cat_jobs',
      'icon': Icons.work,
      'color': Colors.redAccent,
      'subs': [
        'sub_full_time','sub_part_time','sub_daily_work','sub_online_work','sub_hiring','sub_internship','sub_driver_job','sub_teacher_job','sub_security_job','sub_worker_job'
      ],
    },
  ];

  final List<String> provinces = const [
    'هرات','کابل','قندهار','بلخ','ننگرهار','بدخشان','فراه','غزنی','بامیان','هلمند','بادغیس','بغلان','دایکندی','فاریاب','غور','جوزجان','کاپیسا','خوست','کنر','کندز','لغمان','لوگر','میدان وردک','نورستان','نیمروز','پکتیا','پکتیکا','پنجشیر','پروان','سمنگان','سرپل','تخار','ارزگان','زابل'
  ];

  final Map<String, List<String>> districts = const {
    'هرات': ['مرکز هرات','انجیل','گذره','کرخ','رباط سنگی','زنده جان','پشتون زرغون','شیندند','ادرسکن','اوبه','چشت شریف','گلران','کوهسان','کشک','کشک کهنه','غوریان'],
    'کابل': ['مرکز کابل','پغمان','بگرامی','ده سبز','شکردره','استالف','قره باغ','چهار آسیاب','موسهی','خاک جبار','سروبی','کلکان','گلدره','فرزه','میر بچه کوت'],
    'قندهار': ['مرکز قندهار'], 'بلخ': ['مرکز مزار شریف'], 'ننگرهار': ['مرکز جلال‌آباد'], 'بدخشان': ['مرکز فیض‌آباد'], 'فراه': ['مرکز فراه'], 'غزنی': ['مرکز غزنی'], 'بامیان': ['مرکز بامیان'], 'هلمند': ['مرکز لشکرگاه'], 'بادغیس': ['مرکز قلعه نو'], 'بغلان': ['مرکز پلخمری'], 'دایکندی': ['مرکز نیلی'], 'فاریاب': ['مرکز میمنه'], 'غور': ['مرکز فیروزکوه'], 'جوزجان': ['مرکز شبرغان'], 'کاپیسا': ['مرکز محمود راقی'], 'خوست': ['مرکز خوست'], 'کنر': ['مرکز اسعدآباد'], 'کندز': ['مرکز کندز'], 'لغمان': ['مرکز مهترلام'], 'لوگر': ['مرکز پل علم'], 'میدان وردک': ['مرکز میدان شهر'], 'نورستان': ['مرکز پارون'], 'نیمروز': ['مرکز زرنج'], 'پکتیا': ['مرکز گردیز'], 'پکتیکا': ['مرکز شرنه'], 'پنجشیر': ['مرکز بازارک'], 'پروان': ['مرکز چاریکار'], 'سمنگان': ['مرکز ایبک'], 'سرپل': ['مرکز سرپل'], 'تخار': ['مرکز تالقان'], 'ارزگان': ['مرکز ترینکوت'], 'زابل': ['مرکز قلات'],
  };

  static const Map<String, int> categoryIds = {
    'cat_vehicles': 1,
    'cat_real_estate': 2,
    'cat_electronics': 3,
    'cat_personal': 5,
    'cat_services': 6,
    'cat_jobs': 6,
  };

  static const Map<String, List<String>> formBySub = {
    // Real estate
    'sub_house_sale': ['property_type','area','land_area','rooms','bathrooms','kitchen','floor','parking','document_type','facilities','water_power','condition'],
    'sub_house_rent': ['property_type','area','rooms','bathrooms','kitchen','floor','parking','monthly_rent','deposit','facilities','condition'],
    'sub_apartment_sale': ['area','rooms','bathrooms','kitchen','floor','parking','document_type','facilities','condition'],
    'sub_apartment_rent': ['area','rooms','bathrooms','kitchen','floor','parking','monthly_rent','deposit','facilities','condition'],
    'sub_land': ['land_area','land_use','document_type','land_direction','frontage','water_power'],
    'sub_shop_sale': ['area','floor','document_type','frontage','facilities','water_power','condition'],
    'sub_shop_rent': ['area','floor','frontage','monthly_rent','deposit','facilities','water_power','condition'],
    'sub_office_sale': ['area','rooms','floor','parking','document_type','facilities','condition'],
    'sub_office_rent': ['area','rooms','floor','parking','monthly_rent','deposit','facilities','condition'],
    'sub_warehouse': ['area','height','document_type','frontage','water_power','facilities','monthly_rent','deposit','condition'],
    'sub_farm': ['land_area','land_use','water_power','document_type','facilities'],
    'sub_garden': ['land_area','rooms','water_power','document_type','facilities'],
    'sub_room_rent': ['rooms','monthly_rent','deposit','facilities'],

    // Vehicles
    'sub_car': ['brand_type_vehicle','model','year_made','km_used','color','fuel_type','gearbox','plate_docs','condition'],
    'sub_motorcycle': ['brand','model','year_made','km_used','color','fuel_type','plate_docs','condition'],
    'sub_bicycle': ['brand','model','size','color','condition'],
    'sub_truck': ['brand_type_vehicle','model','year_made','km_used','fuel_type','gearbox','capacity','plate_docs','condition'],
    'sub_bus': ['brand_type_vehicle','model','year_made','km_used','fuel_type','gearbox','capacity','plate_docs','condition'],
    'sub_van': ['brand_type_vehicle','model','year_made','km_used','fuel_type','gearbox','plate_docs','condition'],
    'sub_rickshaw': ['brand','model','year_made','fuel_type','plate_docs','condition'],
    'sub_car_parts': ['brand_type','model','part_name','part_for','condition'],
    'sub_tires_parts': ['brand','size','year_made','condition'],
    'sub_vehicle_accessories': ['brand_type','model','condition'],

    // Electronics
    'sub_mobile': ['brand','model','internal_storage','ram','battery_status','color','warranty','original_box','serial_imei','accessories','repair_history','condition'],
    'sub_laptop': ['brand','model','processor','ram','internal_storage','screen_size','battery_status','warranty','accessories','repair_history','condition'],
    'sub_computer': ['brand','model','processor','ram','internal_storage','screen_size','accessories','condition'],
    'sub_tablet': ['brand','model','internal_storage','ram','screen_size','battery_status','warranty','condition'],
    'sub_tv': ['brand','model','screen_size','year_version','warranty','condition'],
    'sub_fridge': ['brand','model','capacity','year_version','warranty','condition'],
    'sub_washing_machine': ['brand','model','capacity','year_version','warranty','condition'],
    'sub_camera': ['brand','model','type','accessories','warranty','condition'],
    'sub_generator': ['brand','model','capacity','fuel_type','year_version','condition'],
    'sub_printer': ['brand','model','type','warranty','condition'],
    'sub_speaker': ['brand','model','capacity','condition'],
    'sub_console': ['brand','model','internal_storage','accessories','condition'],
    'sub_smart_watch': ['brand','model','color','warranty','condition'],
    'sub_router': ['brand','model','type','condition'],
    'sub_solar_panel': ['brand','capacity','warranty','condition'],
    'sub_electronic_parts': ['brand_type','model','part_name','condition'],

    // Home and personal simple goods
    'sub_furniture': ['brand_type','model_size','color','condition'],
    'sub_carpet': ['size','color','condition'],
    'sub_dishes': ['brand_type','quantity','condition'],
    'sub_kitchen_items': ['brand_type','model_size','condition'],
    'sub_bedding': ['size','color','condition'],
    'sub_home_decor': ['brand_type','model_size','color','condition'],
    'sub_tools': ['brand_type','model','condition'],
    'sub_garden_tools': ['brand_type','model','condition'],
    'sub_cleaning_items': ['brand_type','quantity','condition'],

    'sub_clothes': ['type','size','color','condition'],
    'sub_shoes': ['brand','size','color','condition'],
    'sub_watch': ['brand','model','color','condition'],
    'sub_perfume': ['brand','size','condition'],
    'sub_jewelry': ['type','weight','condition'],
    'sub_bag': ['brand','model_size','color','condition'],
    'sub_cosmetics': ['brand','type','condition'],
    'sub_glasses': ['brand','type','condition'],

    // Kids/entertainment/business
    'sub_book': ['book_title','author','condition'],
    'sub_toy': ['brand_type','age_range','condition'],
    'sub_sport': ['brand_type','size','condition'],
    'sub_music': ['brand_type','model','condition'],
    'sub_games': ['brand_type','model','condition'],
    'sub_bicycle_sport': ['brand','model','size','condition'],
    'sub_pet_supplies': ['type','condition'],
    'sub_kids_clothes': ['type','size','color','condition'],
    'sub_stroller': ['brand','model','condition'],
    'sub_kids_toy': ['brand_type','age_range','condition'],
    'sub_kids_bed': ['size','condition'],
    'sub_school_items': ['brand_type','condition'],
    'sub_baby_items': ['brand_type','condition'],
    'sub_kids_bicycle': ['brand','model','size','condition'],

    'sub_shop_equipment': ['brand_type','model','condition'],
    'sub_restaurant_equipment': ['brand_type','model','capacity','condition'],
    'sub_office_equipment': ['brand_type','model','condition'],
    'sub_machinery': ['brand_type','model','year_made','capacity','condition'],
    'sub_raw_materials': ['type','quantity','condition'],
    'sub_agriculture_equipment': ['brand_type','model','condition'],
    'sub_medical_equipment': ['brand_type','model','condition'],
    'sub_factory_equipment': ['brand_type','model','capacity','condition'],

    // Services/jobs
    'sub_construction_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_technical_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_health_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_education_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_transport_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_home_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_repair_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_legal_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_event_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_design_services': ['job_service_title','salary_service_price','work_time','experience_required'],
    'sub_full_time': ['job_title','salary','work_time','experience_required'],
    'sub_part_time': ['job_title','salary','work_time','experience_required'],
    'sub_daily_work': ['job_title','salary','work_time','experience_required'],
    'sub_online_work': ['job_title','salary','work_time','experience_required'],
    'sub_hiring': ['job_title','salary','work_time','experience_required'],
    'sub_internship': ['job_title','salary','work_time','experience_required'],
    'sub_driver_job': ['job_title','salary','work_time','experience_required'],
    'sub_teacher_job': ['job_title','salary','work_time','experience_required'],
    'sub_security_job': ['job_title','salary','work_time','experience_required'],
    'sub_worker_job': ['job_title','salary','work_time','experience_required'],
  };

  static const Set<String> numberFields = {
    'price','area','land_area','rooms','bathrooms','monthly_rent','deposit','year_made','km_used','capacity','quantity','weight','salary','salary_service_price','height'
  };

  @override
  void initState() {
    super.initState();
    if (isEditMode) loadAdForEdit();
  }

  String adText(String key) => widget.ad?[key]?.toString() ?? '';

  String mainKeyFromText(String text) {
    for (final m in mainCategories) {
      if (tr(m['key'].toString()) == text || m['key'] == text) return m['key'].toString();
    }
    return text;
  }

  String subKeyFromText(String text) {
    for (final m in mainCategories) {
      for (final s in (m['subs'] as List)) {
        if (tr(s.toString()) == text || s == text) return s.toString();
      }
    }
    return text;
  }

  void loadAdForEdit() {
    titleController.text = adText('title');
    priceController.text = adText('price');
    phoneController.text = adText('phone');
    addressController.text = adText('address');
    latitude = double.tryParse(adText('latitude'));
    longitude = double.tryParse(adText('longitude'));
    province = adText('province').isEmpty ? 'هرات' : adText('province');
    district = adText('district').isEmpty ? 'مرکز هرات' : adText('district');
    categoryId = int.tryParse(adText('category_id')) ?? 3;
    readDescription(adText('description'));

    final images = widget.ad?['images'];
    if (images is List) {
      for (final img in images) {
        final url = Api.fullImageUrl(img.toString());
        if (url.isNotEmpty && !existingImageUrls.contains(url)) existingImageUrls.add(url);
      }
    }
    final imageUrl = Api.fullImageUrl(adText('image_url'));
    if (imageUrl.isNotEmpty && !existingImageUrls.contains(imageUrl)) existingImageUrls.insert(0, imageUrl);

    if (mainCategoryKey.isEmpty) mainCategoryKey = categoryKeyFromOldId(categoryId);
    if (subCategoryKey.isEmpty) subCategoryKey = subKeyFromText(adText('category_name'));
    if (subCategoryKey.isEmpty) subCategoryKey = (mainCategories.firstWhere((m) => m['key'] == mainCategoryKey, orElse: () => mainCategories[2])['subs'] as List).first.toString();

    if (!provinces.contains(province)) province = 'هرات';
    final districtList = districts[province] ?? ['مرکز هرات'];
    if (!districtList.contains(district)) district = districtList.first;
    categorySelected = true;
  }

  void readDescription(String description) {
    final normalLines = <String>[];
    for (final line in description.split('\n')) {
      final text = line.trim();
      if (text.isEmpty) continue;
      if (text.startsWith('دسته اصلی:') || text.startsWith('main_category:')) { mainCategoryKey = mainKeyFromText(text.split(':').sublist(1).join(':').trim()); continue; }
      if (text.startsWith('زیر دسته:') || text.startsWith('sub_category:')) { subCategoryKey = subKeyFromText(text.split(':').sublist(1).join(':').trim()); continue; }
      if (text.startsWith('ولایت:')) { province = text.replaceFirst('ولایت:', '').trim(); continue; }
      if (text.startsWith('ولسوالی:')) { district = text.replaceFirst('ولسوالی:', '').trim(); continue; }
      if (text.startsWith('آدرس دقیق:')) { if (addressController.text.trim().isEmpty) addressController.text = text.replaceFirst('آدرس دقیق:', '').trim(); continue; }
      if (text.contains(':')) {
        final parts = text.split(':');
        final key = parts.first.trim();
        final value = parts.sublist(1).join(':').trim();
        setFieldFromDescription(key, value);
        continue;
      }
      normalLines.add(text);
    }
    descriptionController.text = normalLines.join('\n');
  }

  void setFieldFromDescription(String label, String value) {
    for (final entry in T.words.entries) {
      final fa = entry.value['fa'];
      final ps = entry.value['ps'];
      if (entry.key == label || fa == label || ps == label) {
        c(entry.key).text = value;
        return;
      }
    }
  }

  String categoryKeyFromOldId(int id) {
    if (id == 1) return 'cat_vehicles';
    if (id == 2) return 'cat_real_estate';
    if (id == 3 || id == 4) return 'cat_electronics';
    if (id == 5) return 'cat_personal';
    if (id == 6) return 'cat_services';
    return 'cat_electronics';
  }

  int getCategoryId(String mainKey, String subKey) {
    if (subKey == 'sub_mobile') return 3;
    if (subKey == 'sub_laptop' || subKey == 'sub_computer') return 4;
    return categoryIds[mainKey] ?? 3;
  }

  void clearCategoryFields() {
    for (final controller in fieldControllers.values) controller.clear();
  }

  void selectCategory(String mainKey, String subKey) {
    setState(() {
      mainCategoryKey = mainKey;
      subCategoryKey = subKey;
      categoryId = getCategoryId(mainKey, subKey);
      categorySelected = true;
      if (!isEditMode) clearCategoryFields();
    });
  }

  void backToCategories() => setState(() => categorySelected = false);

  Future<bool> ensureLoggedIn() async {
    if (Session.isLoggedIn) return true;
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    if (result == true && Session.isLoggedIn) { setState(() {}); return true; }
    showMessage(tr('login_required'));
    return false;
  }

  Future<void> openAuthForChangeAccount() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    if (result == true && Session.isLoggedIn) setState(() {});
  }

  Future<void> pickImages() async {
    if (loading) return;
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final remain = 20 - (selectedImages.length + existingImageUrls.length);
    if (remain <= 0) { showMessage(tr('max_20_images')); return; }
    for (final f in files.take(remain)) {
      selectedImages.add(f);
      selectedImageBytes.add(await f.readAsBytes());
    }
    setState(() {});
  }

  void removeNewImage(int index) => setState(() { selectedImages.removeAt(index); selectedImageBytes.removeAt(index); });
  void removeExistingImage(int index) => setState(() => existingImageUrls.removeAt(index));

  Future<String?> uploadOneImage(XFile image) async {
    try { return await Api.uploadImageBytes(bytes: await image.readAsBytes(), filename: image.name); } catch (_) { return null; }
  }

  Future<List<String>> uploadAllImages() async {
    final result = <String>[...existingImageUrls];
    for (final img in selectedImages) {
      final url = await uploadOneImage(img);
      if (url != null && url.isNotEmpty) result.add(url);
    }
    return result;
  }

  Future<void> detectCurrentLocation() async {
    if (locationLoading) return;
    setState(() => locationLoading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { showMessage(tr('gps_off_optional')); return; }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { showMessage(tr('gps_permission_denied_optional')); return; }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String foundAddress = '';
      try {
        final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final p = places.first;
          foundAddress = [p.street, p.subLocality, p.locality, p.administrativeArea, p.country].where((e) => e != null && e.trim().isNotEmpty).join('، ');
        }
      } catch (_) {}
      setState(() { latitude = pos.latitude; longitude = pos.longitude; if (foundAddress.isNotEmpty) addressController.text = foundAddress; });
      showMessage(tr('gps_saved_optional'));
    } catch (_) { showMessage(tr('gps_failed_optional')); }
    finally { if (mounted) setState(() => locationLoading = false); }
  }

  void writeIfNotEmpty(StringBuffer buffer, String key, TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isNotEmpty) buffer.writeln('${tr(key)}: $value');
  }

  String buildFullDescription() {
    final buffer = StringBuffer();
    final normal = descriptionController.text.trim();
    if (normal.isNotEmpty) { buffer.writeln(normal); buffer.writeln(); }
    buffer.writeln('main_category: $mainCategoryKey');
    buffer.writeln('sub_category: $subCategoryKey');
    buffer.writeln('دسته اصلی: ${tr(mainCategoryKey)}');
    buffer.writeln('زیر دسته: ${tr(subCategoryKey)}');
    buffer.writeln('ولایت: $province');
    buffer.writeln('ولسوالی: $district');
    final address = addressController.text.trim();
    if (address.isNotEmpty) buffer.writeln('آدرس دقیق: $address');
    if (latitude != null && longitude != null) buffer.writeln('مختصات: $latitude,$longitude');
    for (final key in formBySub[subCategoryKey] ?? const ['brand_type','model_size','color','condition']) {
      writeIfNotEmpty(buffer, key, c(key));
    }
    return buffer.toString();
  }

  Future<void> submitAd() async {
    if (loading) return;
    final logged = await ensureLoggedIn();
    if (!logged) return;
    if (titleController.text.trim().isEmpty) { showMessage(tr('enter_title')); return; }
    if (phoneController.text.trim().isEmpty) { showMessage(tr('enter_phone')); return; }
    if (mainCategoryKey.isEmpty || subCategoryKey.isEmpty) { showMessage(tr('select_category')); return; }
    if (addressController.text.trim().isEmpty) { showMessage(tr('enter_address')); return; }
    setState(() => loading = true);
    try {
      final ownerToken = await Session.getOwnerToken();
      final imageUrls = await uploadAllImages();
      final body = {
        'title': titleController.text.trim(),
        'description': buildFullDescription(),
        'price': int.tryParse(priceController.text.trim()) ?? 0,
        'phone': phoneController.text.trim(),
        'province': province,
        'district': district,
        'city': '$province - $district',
        'address': addressController.text.trim(),
        'category_id': categoryId,
        'category_name': tr(subCategoryKey),
        'category_key': subCategoryKey,
        'main_category_key': mainCategoryKey,
        'image_url': imageUrls.isEmpty ? null : imageUrls.first,
        'images': imageUrls,
        'owner_token': ownerToken,
        'user_id': Session.userId,
        'latitude': latitude,
        'longitude': longitude,
      };
      await Api.saveAd(isEdit: isEditMode, adId: isEditMode ? int.tryParse(widget.ad!['id'].toString()) : null, body: body);
      if (!mounted) return;
      showMessage(isEditMode ? tr('ad_updated') : tr('ad_created'));
      Navigator.pop(context, true);
    } catch (e) { showMessage(e.toString().replaceAll('Exception:', '').trim()); }
    if (mounted) setState(() => loading = false);
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.right), behavior: SnackBarBehavior.floating));
  }

  Widget sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(textDirection: TextDirection.rtl, children: [Icon(icon, color: primaryColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget textField(TextEditingController controller, String label, {TextInputType type = TextInputType.text, int maxLines = 1, String? hint, bool required = false}) {
    final isNumber = type == TextInputType.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : type,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(labelText: required ? '$label *' : label, hintText: hint, filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget adField(String key) {
    final maxLines = {'facilities','accessories','repair_history'}.contains(key) ? 2 : 1;
    final type = numberFields.contains(key) ? TextInputType.number : TextInputType.text;
    return textField(c(key), tr(key), type: type, maxLines: maxLines);
  }

  Widget dropdown<T>({required T value, required String label, required List<T> items, required Function(T?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString(), textAlign: TextAlign.right))).toList(),
        onChanged: loading ? null : onChanged,
      ),
    );
  }

  Widget accountCard() {
    final isLogged = Session.isLoggedIn;
    final userName = Session.userFullName.isEmpty ? tr('dear_user') : Session.userFullName;
    return sectionCard(title: tr('user_account'), icon: Icons.person, children: [
      Row(textDirection: TextDirection.rtl, children: [
        CircleAvatar(backgroundColor: isLogged ? Colors.green : Colors.orange, child: Icon(isLogged ? Icons.verified_user : Icons.login, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: Text(isLogged ? userName : tr('login_to_post_ad'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        TextButton(onPressed: loading ? null : () async { if (isLogged) { await openAuthForChangeAccount(); } else { await ensureLoggedIn(); } }, child: Text(isLogged ? tr('change_account') : tr('login'))),
      ]),
    ]);
  }

  Widget buildFormPage() {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(elevation: 0, centerTitle: true, title: Text(isEditMode ? tr('edit_ad') : tr('create_new_ad')), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: loading ? null : backToCategories)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        if (!isEditMode) accountCard(),
        categoryHeader(),
        sectionCard(title: tr('basic_info'), icon: Icons.description, children: [
          textField(titleController, tr('ad_title'), required: true),
          textField(descriptionController, tr('description'), maxLines: 5),
          textField(priceController, tr('price'), type: TextInputType.number),
          textField(phoneController, tr('phone_number'), type: TextInputType.phone, required: true),
        ]),
        sectionCard(title: tr('category_specs'), icon: Icons.category, children: [categorySpecificFields()]),
        sectionCard(title: tr('location'), icon: Icons.location_on, children: [locationFields()]),
        sectionCard(title: tr('images'), icon: Icons.photo_library, children: [imagePickerSection()]),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, height: 55, child: FilledButton.icon(icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check), label: Text(loading ? tr('saving') : isEditMode ? tr('save_changes') : tr('post_ad')), onPressed: loading ? null : submitAd)),
        const SizedBox(height: 40),
      ]))),
    );
  }

  Widget categoryHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: primaryColor.withOpacity(0.15))),
      child: InkWell(onTap: loading ? null : backToCategories, child: Row(textDirection: TextDirection.rtl, children: [
        const Icon(Icons.category, color: primaryColor), const SizedBox(width: 10),
        Expanded(child: Text('${tr(mainCategoryKey)} / ${tr(subCategoryKey)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        const Icon(Icons.edit, size: 20),
      ])),
    );
  }

  Widget locationFields() {
    final districtList = districts[province] ?? ['مرکز هرات'];
    final hasGps = latitude != null && longitude != null;
    return Column(children: [
      dropdown<String>(value: province, label: tr('province'), items: provinces, onChanged: (v) { if (v == null) return; setState(() { province = v; district = districts[v]?.first ?? 'مرکز هرات'; }); }),
      dropdown<String>(value: district, label: tr('district'), items: districtList, onChanged: (v) { if (v == null) return; setState(() => district = v); }),
      textField(addressController, tr('exact_address'), maxLines: 2, required: true, hint: tr('address_hint')),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: hasGps ? Colors.green.withOpacity(0.08) : Colors.deepPurple.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: hasGps ? Colors.green.withOpacity(0.35) : Colors.deepPurple.withOpacity(0.22))), child: Column(children: [
        Row(textDirection: TextDirection.rtl, children: [Icon(hasGps ? Icons.check_circle : Icons.my_location, color: hasGps ? Colors.green : primaryColor), const SizedBox(width: 8), Expanded(child: Text(hasGps ? tr('gps_saved') : tr('gps_for_filter'), textAlign: TextAlign.right, style: TextStyle(color: hasGps ? Colors.green.shade700 : primaryColor, fontWeight: FontWeight.bold)))]),
        if (hasGps) ...[const SizedBox(height: 8), Text('Lat: ${latitude!.toStringAsFixed(6)}   Lng: ${longitude!.toStringAsFixed(6)}', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: locationLoading ? null : detectCurrentLocation, icon: locationLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(hasGps ? Icons.refresh : Icons.gps_fixed), label: Text(locationLoading ? tr('getting_location') : hasGps ? tr('refresh_location') : tr('save_current_location')))),
      ])),
    ]);
  }

  Widget imagePickerSection() {
    final total = existingImageUrls.length + selectedImages.length;
    return Column(children: [
      SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: loading ? null : pickImages, icon: const Icon(Icons.add_photo_alternate), label: Text(total == 0 ? tr('select_image') : '${tr('add_image')} ($total/20)'))),
      const SizedBox(height: 12),
      if (total == 0) Text(tr('image_trust_note'), style: TextStyle(color: Colors.grey.shade600)),
      if (existingImageUrls.isNotEmpty || selectedImageBytes.isNotEmpty) SizedBox(height: 96, child: ListView(scrollDirection: Axis.horizontal, reverse: true, children: [
        ...existingImageUrls.asMap().entries.map((entry) => imagePreview(child: Image.network(entry.value, fit: BoxFit.cover, width: 82, height: 82), onRemove: () => removeExistingImage(entry.key))),
        ...selectedImageBytes.asMap().entries.map((entry) => imagePreview(child: Image.memory(entry.value, fit: BoxFit.cover, width: 82, height: 82), onRemove: () => removeNewImage(entry.key))),
      ])),
    ]);
  }

  Widget imagePreview({required Widget child, required VoidCallback onRemove}) {
    return Container(margin: const EdgeInsets.only(left: 8), child: Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
      Positioned(top: 2, left: 2, child: InkWell(onTap: onRemove, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
    ]));
  }

  Widget categorySpecificFields() {
    final keys = formBySub[subCategoryKey] ?? const ['brand_type','model_size','color','condition'];
    return Column(children: keys.map(adField).toList());
  }

  Widget buildCategoryList() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(isEditMode ? tr('change_category') : tr('select_category')), centerTitle: true),
      body: ListView.separated(padding: const EdgeInsets.all(12), itemCount: mainCategories.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
        final item = mainCategories[index];
        final color = item['color'] as Color;
        return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: ListTile(
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.14), child: Icon(item['icon'] as IconData, color: color)),
          title: Text(tr(item['key'].toString()), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => showSubCategories(item['key'].toString(), List<String>.from(item['subs'] as List)),
        ));
      }),
    );
  }

  void showSubCategories(String mainKey, List<String> subs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SizedBox(height: MediaQuery.of(context).size.height * 0.75, child: ListView.builder(padding: const EdgeInsets.all(14), itemCount: subs.length + 1, itemBuilder: (context, index) {
        if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(mainKey), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)));
        final subKey = subs[index - 1];
        return Card(child: ListTile(title: Text(tr(subKey), textAlign: TextAlign.right), trailing: const Icon(Icons.chevron_left), onTap: () { Navigator.pop(context); selectCategory(mainKey, subKey); }));
      })))),
    );
  }

  @override
  void dispose() {
    titleController.dispose(); descriptionController.dispose(); priceController.dispose(); phoneController.dispose(); addressController.dispose();
    for (final controller in fieldControllers.values) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: categorySelected ? buildFormPage() : buildCategoryList());
  }
}
