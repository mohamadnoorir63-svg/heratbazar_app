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

  String get myContact => Session.userContact.trim();

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<dynamic>> load() async {
    if (!Session.isLoggedIn || myContact.isEmpty) {
      return [];
    }

    return Api.getConversations(myPhone: myContact);
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      future = load();
    });
  }

  String textOf(dynamic item, String key) {
    if (item is! Map) return '';
    return item[key]?.toString().trim() ?? '';
  }

  int intOf(dynamic item, String key) {
    return int.tryParse(textOf(item, key)) ?? 0;
  }

  Map<String, dynamic> adFromConversation(dynamic item) {
    final otherContact = textOf(item, 'other_phone');

    return {
      'id': textOf(item, 'ad_id'),
      'title': textOf(item, 'ad_title'),
      'image_url': textOf(item, 'image_url'),
      'phone': otherContact,
      'owner_phone': otherContact,
    };
  }

  Future<void> openChat(dynamic item) async {
    final otherContact = textOf(item, 'other_phone');

    if (otherContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اطلاعات طرف مقابل این گفتگو ناقص است')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          ad: adFromConversation(item),
          myPhone: myContact,
        ),
      ),
    );

    if (mounted) refresh();
  }

  String cleanError(Object error) {
    return error.toString().replaceAll('Exception:', '').trim();
  }

  Widget emptyState() {
    return const Center(
      child: Text(
        'هنوز گفتگویی ندارید',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget loginState() {
    return const Center(
      child: Text(
        'برای دیدن پیام‌ها وارد شوید',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildConversationTile(dynamic item) {
    final title = textOf(item, 'ad_title').isEmpty
        ? 'آگهی'
        : textOf(item, 'ad_title');

    final otherPhone = textOf(item, 'other_phone');
    final lastMessage = textOf(item, 'last_message');
    final unread = intOf(item, 'unread_count');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: unread > 0 ? Colors.deepPurple : Colors.grey.shade300,
        child: Icon(
          unread > 0 ? Icons.mark_chat_unread : Icons.chat,
          color: unread > 0 ? Colors.white : Colors.black54,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        [
          if (otherPhone.isNotEmpty) otherPhone,
          if (lastMessage.isNotEmpty) lastMessage,
        ].join('\n'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_left),
      onTap: () => openChat(item),
    );
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
              return loginState();
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  cleanError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return emptyState();
            }

            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return buildConversationTile(conversations[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}