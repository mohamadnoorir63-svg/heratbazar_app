import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final Map ad;

  const ChatPage({
    super.key,
    required this.ad,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();

  List messages = [];
  bool loading = true;
  bool sending = false;

  final String myPhone = '0700000000';

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  int get adId => int.tryParse(widget.ad['id'].toString()) ?? 0;

  Future<void> loadMessages() async {
    try {
      final result = await ChatService.getMessages(adId);

      if (!mounted) return;

      setState(() {
        messages = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دریافت پیام‌ها: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
    });

    try {
      await ChatService.sendMessage(
        adId: adId,
        senderPhone: myPhone,
        message: text,
      );

      messageController.clear();
      await loadMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ارسال پیام: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;

    return Scaffold(
      appBar: AppBar(
        title: Text(ad['title']?.toString() ?? 'چت'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Text(
              ad['title']?.toString() ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_phone'] == myPhone;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blue.shade100
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['message']?.toString() ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'پیام بنویس...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
