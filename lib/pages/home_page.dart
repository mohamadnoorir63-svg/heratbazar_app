import 'package:flutter/material.dart';

import '../core/api.dart';
import 'ad_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedMainCategory = 'همه';

  late Future<List<dynamic>> adsFuture;

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

  String textOf(dynamic ad, String key) {
    if (ad is! Map) return '';
    final value = ad[key];
    if (value == null) return '';
    return value.toString().trim();
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

  String getLocation(dynamic ad) {
    final province = textOf(ad, 'province');
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

  String cleanDescriptionPreview(dynamic ad) {
    final description = textOf(ad, 'description');

    if (description.isEmpty) return '';

    return description
        .split('\n')
        .where((line) {
          final text = line.trim();

          if (text.isEmpty) return false;
          if (text.startsWith('دسته اصلی:')) return false;
          if (text.startsWith('زیر دسته:')) return false;
          if (text.startsWith('ولایت:')) return false;
          if (text.startsWith('ولسوالی:')) return false;
          if (text.startsWith('مشخصات')) return false;
          if (text.contains(':')) return false;

          return true;
        })
        .take(2)
        .join(' ');
  }

  List<dynamic> filterAds(List<dynamic> ads) {
    return ads.where((ad) {
      final q = searchText.trim().toLowerCase();

      final title = textOf(ad, 'title').toLowerCase();
      final description = textOf(ad, 'description').toLowerCase();
      final subCategory = getSubCategory(ad).toLowerCase();
      final location = getLocation(ad).toLowerCase();
      final mainCategory = getMainCategory(ad);

      final matchSearch = q.isEmpty ||
          title.contains(q) ||
          description.contains(q) ||
          subCategory.contains(q) ||
          location.contains(q);

      final matchCategory =
          selectedMainCategory == 'همه' || mainCategory == selectedMainCategory;

      return matchSearch && matchCategory;
    }).toList();
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
        return Colors.deepPurple;
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
        return Icons.apps;
    }
  }

  String priceText(String price) {
    if (price.isEmpty || price == '0') return 'قیمت توافقی';
    return 'AFN $price';
  }

  Widget buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Text(
        'HeratBazar',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget buildSearchBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'جستجو در همه آگهی‌ها',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade700,
            size: 30,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
      ),
    );
  }

  Widget buildCategoryChips() {
    return SizedBox(
      height: 60,
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                setState(() {
                  selectedMainCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? color : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? color.withOpacity(0.25)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: selected ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      category == 'همه'
                          ? Icons.grid_view
                          : categoryIcon(category),
                      size: 20,
                      color: selected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
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
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.image, size: 46, color: Colors.grey),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.network(
            images.first,
            width: 118,
            height: 118,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 118,
                height: 118,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    '${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildAdCard(dynamic ad) {
    final title = textOf(ad, 'title');
    final price = textOf(ad, 'price');
    final location = getLocation(ad);
    final mainCategory = getMainCategory(ad);
    final subCategory = getSubCategory(ad);
    final preview = cleanDescriptionPreview(ad);
    final color = categoryColor(mainCategory);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
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
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.065),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAdImage(ad),
                const SizedBox(width: 13),
                Expanded(
                  child: SizedBox(
                    height: 122,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title.isEmpty ? 'بدون عنوان' : title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priceText(price),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (preview.isNotEmpty)
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14.5,
                              height: 1.4,
                            ),
                          ),
                        const Spacer(),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIcon(mainCategory),
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    subCategory,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 78, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'آگهی پیدا نشد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'کلمه جستجو یا دسته‌بندی را تغییر بدهید.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
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
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 22),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f1fb),
      body: SafeArea(
        child: Column(
          children: [
            buildTopHeader(),
            buildSearchBox(),
            buildCategoryChips(),
            const SizedBox(height: 4),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: adsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'خطا در دریافت آگهی‌ها\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
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
    );
  }
}