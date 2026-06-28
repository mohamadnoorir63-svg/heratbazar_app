import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/session.dart';
import '../core/api.dart';
import 'ad_detail_page.dart';
import 'admin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final TextEditingController minAreaController = TextEditingController();
  final TextEditingController maxAreaController = TextEditingController();

  String searchText = '';
String selectedMainCategory = 'همه';
String selectedCondition = 'همه';
String selectedDistance = 'همه';
double selectedRadiusKm = 0; // <-- اینجا
String selectedProvince = 'همه';

Position? myPosition;
bool locationLoading = false;

  late Future<List<dynamic>> adsFuture;

  static const Color primaryColor = Color(0xff4F32D9);
  static const Color secondColor = Color(0xffFF8A3D);
  static const Color bgColor = Color(0xffEFEAFF);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xff19172B);
  static const Color greenColor = Color(0xff0FA958);

  final List<String> mainCategories = const [
    'همه',
    'املاک',
    'وسایل نقلیه',
    'لوازم الکترونیکی',
    'مربوط به خانه',
    'خدمات',
    'وسایل شخصی',
    'سرگرمی و فراغت',
    'لوازم کودک',
    'برای کسب و کار',
    'استخدام و کاریابی',
  ];

  final List<String> provinces = const [
    'همه',
    'بدخشان',
    'بادغیس',
    'بغلان',
    'بلخ',
    'بامیان',
    'دایکندی',
    'فراه',
    'فاریاب',
    'غزنی',
    'غور',
    'هلمند',
    'هرات',
    'جوزجان',
    'کابل',
    'قندهار',
    'کاپیسا',
    'خوست',
    'کنر',
    'کندز',
    'لغمان',
    'لوگر',
    'ننگرهار',
    'نیمروز',
    'نورستان',
    'پکتیا',
    'پکتیکا',
    'پنجشیر',
    'پروان',
    'سمنگان',
    'سرپل',
    'تخار',
    'ارزگان',
    'میدان وردک',
    'زابل',
  ];
  @override
  void initState() {
    super.initState();
    adsFuture = fetchAds();
  }

  Future<List<dynamic>> fetchAds() async {
    return Api.getAds();
  }

  Future<void> refreshAds() async {
    setState(() {
      adsFuture = fetchAds();
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<bool> loadMyLocation({bool showErrors = true}) async {
    if (locationLoading) return myPosition != null;

    setState(() => locationLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (showErrors) {
          showMessage('لوکیشن گوشی خاموش است. لطفاً GPS را روشن کنید.');
        }

        await Geolocator.openLocationSettings();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (showErrors) {
          showMessage('اجازه دسترسی به لوکیشن داده نشد.');
        }
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        if (showErrors) {
          showMessage('دسترسی لوکیشن برای برنامه بسته شده است. از تنظیمات فعالش کنید.');
        }

        await Geolocator.openAppSettings();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return false;

      setState(() {
        myPosition = position;
      });

      return true;
    } catch (_) {
      if (showErrors) {
        showMessage('لوکیشن دریافت نشد. دوباره تلاش کنید.');
      }
      return false;
    } finally {
      if (mounted) setState(() => locationLoading = false);
    }
  }

  String textOf(dynamic ad, String key) {
    if (ad is! Map) return '';
    final value = ad[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  bool boolOf(dynamic ad, String key) {
    if (ad is! Map) return false;

    final value = ad[key];

    if (value == true) return true;
    if (value == 1) return true;

    final text = value?.toString().toLowerCase().trim() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }
  String normalizeNumberText(String text) {
    return text
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  int numberOnlySafe(String text) {
    final normalized = normalizeNumberText(text);
    final clean = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  String formatPrice(String price) {
    final raw = normalizeNumberText(price.trim());

    if (raw.isEmpty || raw == '0') {
      return 'قیمت توافقی';
    }

    final number = int.tryParse(raw.replaceAll(',', ''));
    if (number == null || number == 0) {
      return 'قیمت توافقی';
    }

    final formatted = number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return '$formatted افغانی';
  }

  String priceText(String price) {
    return formatPrice(price);
  }

  double? doubleOf(dynamic ad, String key) {
    if (ad is! Map) return null;
    return double.tryParse(ad[key]?.toString() ?? '');
  }

  double? distanceKm(dynamic ad) {
    if (myPosition == null) return null;

    final lat = doubleOf(ad, 'latitude');
    final lng = doubleOf(ad, 'longitude');

    if (lat == null || lng == null) return null;

    final meters = Geolocator.distanceBetween(
      myPosition!.latitude,
      myPosition!.longitude,
      lat,
      lng,
    );

    return meters / 1000;
  }

  String distanceText(dynamic ad) {
    final km = distanceKm(ad);

    if (km == null) return '';

    if (km < 1) {
      return '${(km * 1000).round()} متر دورتر';
    }

    return '${km.toStringAsFixed(1)} کیلومتر دورتر';
  }

  int selectedDistanceKm() {
  return selectedRadiusKm.round();
}
  String getCondition(dynamic ad) {
    final direct = textOf(ad, 'condition');
    if (direct.isNotEmpty) return direct;

    final description = textOf(ad, 'description');

    for (final line in description.split('\n')) {
      final text = line.trim();

      if (text.startsWith('وضعیت:')) {
        return text.replaceFirst('وضعیت:', '').trim();
      }

      if (text.startsWith('حالت:')) {
        return text.replaceFirst('حالت:', '').trim();
      }
    }

    if (description.contains('کارکرده')) return 'کارکرده';
    if (description.contains('نو')) return 'نو';

    return '';
  }

  int getArea(dynamic ad) {
    final directArea = textOf(ad, 'area');
    if (directArea.isNotEmpty) return numberOnlySafe(directArea);

    final landArea = textOf(ad, 'land_area');
    if (landArea.isNotEmpty) return numberOnlySafe(landArea);

    final description = textOf(ad, 'description');

    for (final line in description.split('\n')) {
      final text = line.trim();

      if (text.startsWith('متراژ:')) {
        return numberOnlySafe(text.replaceFirst('متراژ:', ''));
      }

      if (text.startsWith('مساحت:')) {
        return numberOnlySafe(text.replaceFirst('مساحت:', ''));
      }

      if (text.startsWith('متراژ زمین:')) {
        return numberOnlySafe(text.replaceFirst('متراژ زمین:', ''));
      }
    }

    return 0;
  }

  List<String> getImages(dynamic ad) {
    final result = <String>[];

    if (ad is! Map) return result;

    final images = ad['images'];

    if (images is List) {
      for (final image in images) {
        final url = Api.fullImageUrl(image.toString());
        if (url.isNotEmpty && !result.contains(url)) {
          result.add(url);
        }
      }
    }

    final imageUrl = Api.fullImageUrl(ad['image_url']?.toString());

    if (imageUrl.isNotEmpty && !result.contains(imageUrl)) {
      result.insert(0, imageUrl);
    }

    return result;
  }

  String getProvince(dynamic ad) {
    final province = textOf(ad, 'province');
    if (province.isNotEmpty) return province;

    final description = textOf(ad, 'description');

    for (final line in description.split('\n')) {
      final text = line.trim();

      if (text.startsWith('ولایت:')) {
        return text.replaceFirst('ولایت:', '').trim();
      }
    }

    final city = textOf(ad, 'city');
    if (city.contains('-')) {
      return city.split('-').first.trim();
    }

    return '';
  }

  String getLocation(dynamic ad) {
    final province = getProvince(ad);
    final district = textOf(ad, 'district');
    final city = textOf(ad, 'city');

    if (province.isNotEmpty && district.isNotEmpty) {
      return '$province - $district';
    }

    if (province.isNotEmpty) return province;
    if (city.isNotEmpty) return city;

    return 'موقعیت نامشخص';
  }

  String getMainCategory(dynamic ad) {
    final description = textOf(ad, 'description');

    for (final line in description.split('\n')) {
      final text = line.trim();
      if (text.startsWith('دسته اصلی:')) {
        return text.replaceFirst('دسته اصلی:', '').trim();
      }
    }

    return textOf(ad, 'main_category');
  }

  String getSubCategory(dynamic ad) {
    final description = textOf(ad, 'description');

    for (final line in description.split('\n')) {
      final text = line.trim();
      if (text.startsWith('زیر دسته:')) {
        return text.replaceFirst('زیر دسته:', '').trim();
      }
    }

    final categoryName = textOf(ad, 'category_name');
    if (categoryName.isNotEmpty) return categoryName;

    return 'دسته‌بندی';
  }
  List<dynamic> filterAds(List<dynamic> ads) {
    return ads.where((ad) {
      final q = searchText.trim().toLowerCase();

      final title = textOf(ad, 'title').toLowerCase();
      final description = textOf(ad, 'description').toLowerCase();
      final subCategory = getSubCategory(ad).toLowerCase();
      final location = getLocation(ad).toLowerCase();
      final mainCategory = getMainCategory(ad);
      final province = getProvince(ad);

      final price = numberOnlySafe(textOf(ad, 'price'));
      final area = getArea(ad);
      final condition = getCondition(ad);

      final minPrice = numberOnlySafe(minPriceController.text);
      final maxPrice = numberOnlySafe(maxPriceController.text);
      final minArea = numberOnlySafe(minAreaController.text);
      final maxArea = numberOnlySafe(maxAreaController.text);

      final selectedKm = selectedDistanceKm();
      final adKm = distanceKm(ad);

      final matchSearch = q.isEmpty ||
          title.contains(q) ||
          description.contains(q) ||
          subCategory.contains(q) ||
          location.contains(q) ||
          province.toLowerCase().contains(q);

      final matchCategory =
          selectedMainCategory == 'همه' || mainCategory == selectedMainCategory;

      final matchProvince =
          selectedProvince == 'همه' || province == selectedProvince;

      final matchCondition = selectedCondition == 'همه' ||
          condition.contains(selectedCondition) ||
          description.contains(selectedCondition);

      final matchMinPrice = minPrice == 0 || price >= minPrice;
      final matchMaxPrice = maxPrice == 0 || price <= maxPrice;
      final matchMinArea = minArea == 0 || area >= minArea;
      final matchMaxArea = maxArea == 0 || area <= maxArea;

      final matchDistance =
          selectedKm == 0 || (adKm != null && adKm <= selectedKm);

      return matchSearch &&
          matchCategory &&
          matchProvince &&
          matchCondition &&
          matchMinPrice &&
          matchMaxPrice &&
          matchMinArea &&
          matchMaxArea &&
          matchDistance;
    }).toList();
  }

  bool get hasFilter {
  return selectedCondition != 'همه' ||
      selectedRadiusKm > 0 ||
      selectedProvince != 'همه' ||
      minPriceController.text.isNotEmpty ||
      maxPriceController.text.isNotEmpty ||
      minAreaController.text.isNotEmpty ||
      maxAreaController.text.isNotEmpty;
}

 void clearFilters() {
  setState(() {
    selectedCondition = 'همه';
    selectedDistance = 'همه';
    selectedRadiusKm = 0;
    selectedProvince = 'همه';

    minPriceController.clear();
    maxPriceController.clear();
    minAreaController.clear();
    maxAreaController.clear();
  });
}

  InputDecoration filterInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xffF7F3FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE0D7FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  BoxDecoration softCardDecoration({
    Color color = Colors.white,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xffE2DAFF)),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  void showProvinceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'انتخاب ولایت',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '۳۴ ولایت افغانستان',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: provinces.length,
                    itemBuilder: (context, index) {
                      final item = provinces[index];
                      final selected = selectedProvince == item;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryColor.withOpacity(0.10)
                              : const Color(0xffFAF9FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? primaryColor
                                : const Color(0xffEAE5FF),
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              selectedProvince = item;
                            });

                            Navigator.pop(context);
                          },
                          title: Text(
                            item == 'همه' ? 'همه ولایت‌ها' : item,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.bold,
                              color: selected ? primaryColor : textColor,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 void showDistanceSheet() {
  double tempRadius = selectedRadiusKm;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final isAll = tempRadius == 0;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'فیلتر فاصله',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAll ? 'همه فاصله‌ها' : 'تا ${tempRadius.round()} کیلومتر',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: tempRadius,
                    min: 0,
                    max: 300,
                    divisions: 300,
                    label: isAll ? 'همه' : '${tempRadius.round()} کیلومتر',
                    onChanged: (value) {
                      setSheetState(() => tempRadius = value);
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('اعمال فاصله'),
                      onPressed: () async {
                        if (tempRadius > 0) {
                          final ok = await loadMyLocation(showErrors: true);
                          if (!ok) return;
                        }

                        setState(() {
                          selectedRadiusKm = tempRadius;
                          selectedDistance = tempRadius == 0
                              ? 'همه'
                              : '${tempRadius.round()} کیلومتر';
                        });

                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.70,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 18,
                      right: 18,
                      top: 14,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryColor, secondColor],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.tune, color: primaryColor),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'فیلتر پیشرفته آگهی‌ها',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        const Text(
                          'ولایت',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(context);
                            showProvinceSheet();
                          },
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: softCardDecoration(
                              color: const Color(0xffFAF8FF),
                              radius: 18,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_city,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedProvince == 'همه'
                                        ? 'همه ولایت‌ها'
                                        : selectedProvince,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'وضعیت کالا',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: ['همه', 'نو', 'کارکرده'].map((item) {
                            final selected = selectedCondition == item;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedCondition = item;
                                    });

                                    setState(() {
                                      selectedCondition = item;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? primaryColor
                                          : const Color(0xffF7F3FF),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? primaryColor
                                            : const Color(0xffE2DAFF),
                                      ),
                                    ),
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : textColor,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: filterInputDecoration(
                                  'حداقل قیمت',
                                  Icons.south,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: filterInputDecoration(
                                  'حداکثر قیمت',
                                  Icons.north,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minAreaController,
                                keyboardType: TextInputType.number,
                                decoration: filterInputDecoration(
                                  'حداقل متراژ',
                                  Icons.square_foot,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: maxAreaController,
                                keyboardType: TextInputType.number,
                                decoration: filterInputDecoration(
                                  'حداکثر متراژ',
                                  Icons.fullscreen,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  clearFilters();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('پاک کردن'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('اعمال فیلتر'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
        return primaryColor;
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
        return Icons.grid_view_rounded;
    }
  }

  Widget buildTopHeader() {
    final isAdmin = Session.isAdmin;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xff4F32D9),
            Color(0xff7C63F4),
            Color(0xffFF8A3D),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isAdmin)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'مدیر',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const Spacer(),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'افغان بازار',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'خرید و فروش آسان در افغانستان',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: showDistanceSheet,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selectedDistance == 'همه' ? Colors.white : primaryColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffDDD4FF)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (locationLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: selectedDistance == 'همه'
                            ? primaryColor
                            : Colors.white,
                      ),
                    )
                  else
                    Icon(
                      Icons.my_location,
                      color: selectedDistance == 'همه'
                          ? primaryColor
                          : Colors.white,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    selectedDistance == 'همه' ? 'کیلومتر' : selectedDistance,
                    style: TextStyle(
                      color:
                          selectedDistance == 'همه' ? textColor : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: showProvinceSheet,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selectedProvince == 'همه' ? Colors.white : primaryColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffDDD4FF)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: selectedProvince == 'همه'
                        ? primaryColor
                        : Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    selectedProvince == 'همه' ? 'ولایت' : selectedProvince,
                    style: TextStyle(
                      color:
                          selectedProvince == 'همه' ? textColor : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffDDD4FF)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: 'جستجو؛ مثلاً هرات، موتر، خانه',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: showFilterSheet,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: hasFilter ? primaryColor : const Color(0xffFFF7F0),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasFilter ? primaryColor : const Color(0xffFFD7B5),
            ),
            boxShadow: [
              BoxShadow(
                color: hasFilter
                    ? primaryColor.withOpacity(0.18)
                    : secondColor.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.tune, color: hasFilter ? Colors.white : secondColor),
              const SizedBox(width: 8),
              Text(
                hasFilter ? 'فیلتر فعال است' : 'فیلتر پیشرفته آگهی‌ها',
                style: TextStyle(
                  color: hasFilter ? Colors.white : textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_down,
                color: hasFilter ? Colors.white : Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryChips() {
    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final category = mainCategories[index];
          final selected = selectedMainCategory == category;
          final color = categoryColor(category);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  selectedMainCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 104,
                decoration: BoxDecoration(
                  color: selected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? primaryColor : const Color(0xffE2DAFF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? primaryColor.withOpacity(0.18)
                          : primaryColor.withOpacity(0.07),
                      blurRadius: 13,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcon(category),
                      color: selected ? Colors.white : color,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : textColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildAdImage(dynamic ad) {
    final images = getImages(ad);

    if (images.isEmpty) {
      return Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xffF1EEFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffE2DAFF)),
        ),
        child: Icon(Icons.image, size: 40, color: Colors.grey.shade500),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        images.first,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 112,
            height: 112,
            color: const Color(0xffF1EEFF),
            child: Icon(Icons.broken_image, color: Colors.grey.shade500),
          );
        },
      ),
    );
  }

  Widget buildAdCard(dynamic ad) {
    final title = textOf(ad, 'title');
    final price = textOf(ad, 'price');
    final location = getLocation(ad);
    final mainCategory = getMainCategory(ad);
    final subCategory = getSubCategory(ad);
    final color = categoryColor(mainCategory);
    final distance = distanceText(ad);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffE2DAFF)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AdDetailPage(ad: ad),
                ),
              ),
            );

            if (result == true && mounted) {
              await refreshAds();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAdImage(ad),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title.isEmpty ? 'بدون عنوان' : title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (boolOf(ad, 'owner_blue_verified')) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          priceText(price),
                          style: const TextStyle(
                            color: greenColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withOpacity(0.20),
                                ),
                              ),
                              child: Text(
                                subCategory,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                distance.isNotEmpty
                                    ? '$location • $distance'
                                    : location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        margin: const EdgeInsets.all(24),
        decoration: softCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'آگهی پیدا نشد',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdsList(List<dynamic> ads) {
    final filtered = filterAds(ads);

    if (filtered.isEmpty) return buildEmptyState();

    return RefreshIndicator(
      onRefresh: refreshAds,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 26, top: 2),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return buildAdCard(filtered[index]);
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    minAreaController.dispose();
    maxAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              buildTopHeader(),
              buildSearchBox(),
              buildFilterButton(),
              buildCategoryChips(),
              const SizedBox(height: 3),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: adsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'خطا در دریافت آگهی‌ها\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      );
                    }

                    final ads = snapshot.data ?? [];
                    return buildAdsList(ads);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}