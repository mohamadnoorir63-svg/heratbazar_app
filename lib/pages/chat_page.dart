import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';

class ChatPage extends StatefulWidget {
  final Map ad;
  final String? myPhone;

  const ChatPage({
    super.key,
    required this.ad,
    this.myPhone,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<dynamic> messages = [];

  bool loading = true;
  bool sending = false;

  int get adId =>
      int.tryParse(widget.ad['id']?.toString() ?? '0') ?? 0;

  String get sellerPhone =>
      widget.ad['phone']?.toString().trim() ??
      widget.ad['contact_phone']?.toString().trim() ??
      widget.ad['seller_phone']?.toString().trim() ??
      widget.ad['owner_phone']?.toString().trim() ??
      '';

  String get myPhone {
    final phone = widget.myPhone?.trim() ?? '';
    if (phone.isNotEmpty) return phone;
    return Session.userPhone.trim();
  }

  String get otherPhone => sellerPhone.trim();

  bool get isOwnAd =>
      myPhone.isNotEmpty &&
      otherPhone.isNotEmpty &&
      myPhone == otherPhone;

  bool get canChat =>
      Session.isLoggedIn &&
      adId > 0 &&
      myPhone.isNotEmpty &&
      otherPhone.isNotEmpty &&
      !isOwnAd;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    if (!canChat) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    try {
      final result = await Api.getMessages(
        adId: adId,
        myPhone: myPhone,
        otherPhone: otherPhone,
      );

      if (!mounted) return;

      setState(() {
        messages = result;
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending || !canChat) return;

    setState(() {
      sending = true;
    });

    try {
      await Api.sendMessage(
        adId: adId,
        senderPhone: myPhone,
        receiverPhone: otherPhone,
        message: text,
      );

      messageController.clear();

      await loadMessages();

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String messageText(dynamic msg) {
    if (msg is! Map) return '';
    return msg['message']?.toString() ?? '';
  }

  String sender(dynamic msg) {
    if (msg is! Map) return '';
    return msg['sender_phone']?.toString() ?? '';
  }

  Widget buildMessage(dynamic msg) {
    final isMe = sender(msg).trim() == myPhone;
    final text = messageText(msg);

    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .75,
        ),
        decoration: BoxDecoration(
          color:
              isMe ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    String text = 'اطلاعات چت کامل نیست';

    if (!Session.isLoggedIn) {
      text = 'ابتدا وارد حساب خود شوید';
    } else if (isOwnAd) {
      text = 'این آگهی متعلق به شماست';
    } else if (otherPhone.isEmpty) {
      text = 'شماره فروشنده موجود نیست';
    }

    return Expanded(
      child: Center(
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget buildMessages() {
    if (loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (messages.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'هنوز پیامی وجود ندارد',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: loadMessages,
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return buildMessage(messages[index]);
          },
        ),
      ),
    );
  }

  Widget buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              onPressed:
                  sending || !canChat ? null : sendMessage,
              icon: sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                enabled: canChat && !sending,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'پیام بنویس...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.ad['title']?.toString() ?? 'چت';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              onPressed: loadMessages,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            if (!canChat)
              buildEmptyState()
            else
              buildMessages(),
            buildInputBar(),
          ],
        ),
      ),
    );
  }
}