import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<dynamic>> load() {
    return Api.getConversations(myPhone: Session.userPhone);
  }

  Future<void> refresh() async {
    setState(() {
      future = load();
    });
  }

  String textOf(dynamic item, String key) {
    if (item is! Map) return '';
    return item[key]?.toString() ?? '';
  }

  Map<String, dynamic> adFromConversation(dynamic item) {
    return {
      'id': textOf(item, 'ad_id'),
      'title': textOf(item, 'ad_title'),
      'image_url': textOf(item, 'image_url'),
      'phone': textOf(item, 'other_phone'),
    };
  }

  void openChat(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          ad: adFromConversation(item),
          myPhone: Session.userPhone,
        ),
      ),
    ).then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پیام‌ها'),
          centerTitle: true,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (!Session.isLoggedIn) {
              return const Center(child: Text('برای دیدن پیام‌ها وارد شوید'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString().replaceAll('Exception:', '').trim(),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return const Center(child: Text('هنوز گفتگویی ندارید'));
            }

            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = conversations[index];

                  final title = textOf(item, 'ad_title').isEmpty
                      ? 'آگهی'
                      : textOf(item, 'ad_title');

                  final otherPhone = textOf(item, 'other_phone');
                  final lastMessage = textOf(item, 'last_message');

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.chat),
                    ),
                    title: Text(title),
                    subtitle: Text(
                      '$otherPhone\n$lastMessage',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => openChat(item),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}