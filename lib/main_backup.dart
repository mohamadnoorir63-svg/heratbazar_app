import 'dart:convert';
import 'pages/ad_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBase = 'https://api.kooktalayi.com/heratbazar-api/api';

void main() {
  runApp(const HeratBazarApp());
}

class HeratBazarApp extends StatefulWidget {
  const HeratBazarApp({super.key});

  @override
  State<HeratBazarApp> createState() => _HeratBazarAppState();
}

class _HeratBazarAppState extends State<HeratBazarApp> {
  Future<List<dynamic>> fetchAds() async {
    final res = await http.get(Uri.parse('$apiBase/ads'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('خطا در دریافت آگهی‌ها');
  }

  Future<bool> createAd(
    String title,
    String desc,
    String price,
    String phone,
    int categoryId,
  ) async {
    final res = await http.post(
      Uri.parse('$apiBase/ads'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': desc,
        'price': int.tryParse(price) ?? 0,
        'phone': phone,
        'city': 'Herat',
        'category_id': categoryId,
      }),
    );

    print('POST STATUS: ${res.statusCode}');
    print('POST BODY: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      setState(() {});
      return true;
    }

    return false;
  }

  void openCreateAdForm(BuildContext context) {
    final title = TextEditingController();
    final desc = TextEditingController();
    final price = TextEditingController();
    final phone = TextEditingController();

    int selectedCategoryId = 3;

    final categories = [
      {'id': 1, 'name': 'خانه'},
      {'id': 2, 'name': 'موتر'},
      {'id': 3, 'name': 'موبایل'},
      {'id': 4, 'name': 'لپتاپ'},
      {'id': 5, 'name': 'لباس'},
      {'id': 6, 'name': 'خدمات'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ثبت آگهی جدید'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'عنوان'),
                    ),
                    TextField(
                      controller: desc,
                      decoration: const InputDecoration(labelText: 'توضیحات'),
                    ),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'قیمت'),
                    ),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'شماره تماس'),
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                      items: categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'] as int,
                          child: Text(cat['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryId = value ?? 3;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('لغو'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await createAd(
                      title.text,
                      desc.text,
                      price.text,
                      phone.text,
                      selectedCategoryId,
                    );

                    if (ok && mounted) {
                      Navigator.pop(dialogContext);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ثبت آگهی انجام نشد')),
                      );
                    }
                  },
                  child: const Text('ثبت'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeratBazar',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (pageContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('HeratBazar'),
              centerTitle: true,
              actions: [
                TextButton.icon(
                  onPressed: () => openCreateAdForm(pageContext),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'ثبت آگهی',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            body: FutureBuilder<List<dynamic>>(
              future: fetchAds(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('خطا: ${snapshot.error}'));
                }

                final ads = snapshot.data ?? [];

                if (ads.isEmpty) {
                  return const Center(child: Text('هنوز آگهی وجود ندارد'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.shopping_bag),
                        ),
                        title: Text(ad['title'] ?? ''),
                        subtitle: Text(
                          '${ad['description'] ?? ''}\n${ad['category_name'] ?? ''} - ${ad['city'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Text('${ad['price'] ?? ''} AFN'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdDetailPage(ad: ad),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}