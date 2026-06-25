import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/api.dart';
import '../core/session.dart';

class OfficialGroupPage extends StatefulWidget {
  const OfficialGroupPage({super.key});

  @override
  State<OfficialGroupPage> createState() => _OfficialGroupPageState();
}

class _OfficialGroupPageState extends State<OfficialGroupPage>
    with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF1F6FEB);
  static const Color telegramBlue = Color(0xFF229ED9);
  static const Color bgColor = Color(0xFFE7EEF5);
  static const Color bubbleMine = Color(0xFFDFF7E8);
  static const Color bubbleOther = Colors.white;
  static const Color dangerColor = Color(0xFFE53935);

  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController announcementTitleController =
      TextEditingController();
  final TextEditingController announcementBodyController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();
  final ImagePicker picker = ImagePicker();

  Timer? refreshTimer;
  Timer? typingTimer;

  bool loading = true;
  bool sending = false;
  bool searching = false;
  bool uploadingMedia = false;
  bool loadingMembers = false;
  bool typingSent = false;
  bool showScrollToBottomButton = false;
  bool darkMode = false;

  String searchText = '';

  String officialGroupTitle = 'گروه رسمی HeratBazar';
  String officialGroupAvatar = '';
  String officialGroupDescription = '';

  String groupProfileName = '';
  String groupProfileAvatar = '';
  String myGuestId = '';

  List messages = [];
  List announcements = [];
  List members = [];

  Map<String, dynamic>? stats;
  Map<String, dynamic>? replyMessage;
  Map<String, dynamic>? editingMessage;

  late AnimationController sendButtonController;

  bool get isLoggedIn => Session.isLoggedIn;

  int get myUserId {
    return int.tryParse(Session.userId.toString()) ?? 0;
  }

  String get myPhone => Session.userPhone.trim();

  bool get isOwnerUser {
    final phone = Session.userPhone.trim();

    return Session.isOwner ||
        phone == '015906771961' ||
        phone == '+4915906771961';
  }

  bool get hasGroupProfile {
    return groupProfileName.trim().isNotEmpty;
  }

  String get groupDisplayName {
    final name = groupProfileName.trim();
    if (name.isNotEmpty) return name;

    final fullName = Session.userFullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final phone = myPhone;
    if (phone.isNotEmpty) return phone;

    return 'کاربر';
  }

  String get groupDisplayAvatar {
    return groupProfileAvatar.trim();
  }

  Color get pageBg => darkMode ? const Color(0xFF0E1621) : bgColor;
  Color get panelColor => darkMode ? const Color(0xFF17212B) : Colors.white;
  Color get textColor => darkMode ? Colors.white : Colors.black87;
  Color get mutedTextColor =>
      darkMode ? Colors.white70 : Colors.grey.shade600;

  int get onlineCount {
    final now = DateTime.now();
    int count = 0;

    for (final item in members) {
      final raw = textOf(item, 'last_seen');
      if (raw.isEmpty) continue;

      try {
        final date = DateTime.parse(raw).toLocal();
        if (now.difference(date).inSeconds < 70) count++;
      } catch (_) {}
    }

    final statOnline = int.tryParse(stats?['online']?.toString() ?? '');
    if (statOnline != null && statOnline > count) return statOnline;

    return count;
  }

  @override
  void initState() {
    super.initState();

    sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      lowerBound: .88,
      upperBound: 1,
    )..value = 1;

    messageController.addListener(handleTyping);
    scrollController.addListener(handleScroll);

    initGroupPage();

    refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      updateLastSeen();
      loadMessages(silent: true);
      loadStats();
      loadAnnouncements();

      if (members.isEmpty) {
        loadMembers(silent: true);
      }
    });
  }

  Future<void> initGroupPage() async {
    myGuestId = await Session.getGroupGuestId();

    await loadGroupProfile();
    await loadAll();
    await updateLastSeen();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    typingTimer?.cancel();

    messageController.removeListener(handleTyping);
    scrollController.removeListener(handleScroll);

    messageController.dispose();
    searchController.dispose();
    announcementTitleController.dispose();
    announcementBodyController.dispose();
    scrollController.dispose();
    sendButtonController.dispose();

    super.dispose();
  }

  void handleScroll() {
    if (!scrollController.hasClients) return;

    final max = scrollController.position.maxScrollExtent;
    final current = scrollController.offset;

    final shouldShow = max - current > 500;

    if (shouldShow != showScrollToBottomButton && mounted) {
      setState(() {
        showScrollToBottomButton = shouldShow;
      });
    }
  }

  // ==================== BASIC HELPERS ====================

  String textOf(dynamic item, String key) {
    if (item is! Map) return '';
    return item[key]?.toString() ?? '';
  }

  int intOf(dynamic item, String key) {
    if (item is! Map) return 0;
    return int.tryParse(item[key]?.toString() ?? '') ?? 0;
  }

  bool boolOf(dynamic item, String key) {
    if (item is! Map) return false;

    final value = item[key];

    if (value is bool) return value;

    final text = value?.toString() ?? '';

    return text == 'true' || text == '1';
  }

  String cleanError(Object e) {
    return e.toString().replaceAll('Exception:', '').trim();
  }

  bool isMine(dynamic item) {
    if (isLoggedIn && myUserId > 0) {
      return intOf(item, 'sender_user_id') == myUserId;
    }

    final guestId = textOf(item, 'guest_id').trim();
    return guestId.isNotEmpty && guestId == myGuestId;
  }

  bool isOwner(dynamic item) {
    return textOf(item, 'role') == 'owner' ||
        boolOf(item, 'is_owner') ||
        textOf(item, 'sender_phone') == '015906771961' ||
        textOf(item, 'sender_phone') == '+4915906771961' ||
        textOf(item, 'phone') == '015906771961' ||
        textOf(item, 'phone') == '+4915906771961';
  }

  bool isVerified(dynamic item) {
    return boolOf(item, 'is_verified') ||
        boolOf(item, 'member_is_verified') ||
        isOwner(item);
  }

  bool isImageMessage(dynamic item) {
    final type = textOf(item, 'message_type');
    final mime = textOf(item, 'media_mime');

    return type == 'image' || mime.startsWith('image/');
  }

  bool hasReply(dynamic item) {
    return textOf(item, 'reply_message').trim().isNotEmpty ||
        textOf(item, 'reply_media_url').trim().isNotEmpty;
  }

  bool isOnlineMember(dynamic item) {
    final raw = textOf(item, 'last_seen');

    if (raw.isEmpty) return false;

    try {
      final date = DateTime.parse(raw).toLocal();
      return DateTime.now().difference(date).inSeconds < 70;
    } catch (_) {
      return false;
    }
  }

  bool isMemberTyping(dynamic item) {
    if (isMine(item)) return false;
    return boolOf(item, 'is_typing');
  }

  List typingMembers() {
    return members.where((m) => isMemberTyping(m)).toList();
  }

  String typingText() {
    final list = typingMembers();

    if (list.isEmpty) return '';

    if (list.length == 1) {
      return '${memberName(list.first)} در حال نوشتن...';
    }

    return '${list.length} نفر در حال نوشتن...';
  }

  String firstLetter(String text) {
    final value = text.trim();

    if (value.isEmpty) return '؟';

    return value.characters.first;
  }
  // ==================== NAME / AVATAR HELPERS ====================

  String senderName(dynamic item) {
    final guest = textOf(item, 'guest_name').trim();
    if (guest.isNotEmpty) return guest;

    final first = textOf(item, 'first_name');
    final last = textOf(item, 'last_name');

    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;

    final phone = textOf(item, 'sender_phone');
    return phone.isEmpty ? 'کاربر' : phone;
  }

  String senderAvatar(dynamic item) {
    final guestAvatar = textOf(item, 'guest_avatar_url').trim();
    if (guestAvatar.isNotEmpty) return guestAvatar;

    return textOf(item, 'avatar_url').trim();
  }

  String memberName(dynamic item) {
    final guest = textOf(item, 'guest_name').trim();
    if (guest.isNotEmpty) return guest;

    final first = textOf(item, 'first_name');
    final last = textOf(item, 'last_name');

    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;

    final phone = textOf(item, 'phone');
    return phone.isEmpty ? 'کاربر' : phone;
  }

  String memberAvatar(dynamic item) {
    final guestAvatar = textOf(item, 'guest_avatar_url').trim();
    if (guestAvatar.isNotEmpty) return guestAvatar;

    return textOf(item, 'avatar_url').trim();
  }

  String shortReplyName(dynamic item) {
    final first = textOf(item, 'reply_first_name');
    final last = textOf(item, 'reply_last_name');

    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;

    final guest = textOf(item, 'reply_guest_name').trim();
    if (guest.isNotEmpty) return guest;

    return 'پیام قبلی';
  }

  String replyTextOf(dynamic item) {
    final text = textOf(item, 'reply_message');

    if (text.trim().isNotEmpty) return text;

    final media = textOf(item, 'reply_media_url');
    if (media.trim().isNotEmpty) return 'عکس یا فایل';

    return 'پیام قبلی';
  }

  // ==================== TIME HELPERS ====================

  String formatTime(dynamic item) {
    final raw = textOf(item, 'created_at');

    if (raw.isEmpty) return '';

    try {
      final date = DateTime.parse(raw).toLocal();
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');

      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  String formatDateTitle(String raw) {
    if (raw.isEmpty) return '';

    try {
      final date = DateTime.parse(raw).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);

      final diff = today.difference(target).inDays;

      if (diff == 0) return 'امروز';
      if (diff == 1) return 'دیروز';

      return '${date.year}/${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }

  bool shouldShowDateHeader(int index) {
    if (index <= 0) return true;

    final current = textOf(messages[index], 'created_at');
    final previous = textOf(messages[index - 1], 'created_at');

    if (current.isEmpty || previous.isEmpty) return false;

    try {
      final c = DateTime.parse(current).toLocal();
      final p = DateTime.parse(previous).toLocal();

      return c.year != p.year || c.month != p.month || c.day != p.day;
    } catch (_) {
      return false;
    }
  }

  String formatLastSeen(dynamic item) {
    final raw = textOf(item, 'last_seen');

    if (raw.isEmpty) return 'نامشخص';

    try {
      final date = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 70) return 'آنلاین';
      if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه قبل';
      if (diff.inHours < 24) return '${diff.inHours} ساعت قبل';

      return '${date.year}/${date.month}/${date.day}';
    } catch (_) {
      return 'نامشخص';
    }
  }

  // ==================== REACTIONS HELPERS ====================

  List<Map<String, dynamic>> reactionsOf(dynamic item) {
    if (item is! Map) return [];

    final raw = item['reactions'];
    if (raw is! List) return [];

    final result = <Map<String, dynamic>>[];

    for (final r in raw) {
      if (r is! Map) continue;

      final reaction = r['reaction']?.toString() ?? '';
      final count = int.tryParse(r['count']?.toString() ?? '0') ?? 0;

      if (reaction.trim().isEmpty || count <= 0) continue;

      result.add({
        'reaction': reaction,
        'count': count,
      });
    }

    return result;
  }

  bool hasReactions(dynamic item) {
    return reactionsOf(item).isNotEmpty;
  }

  String reactionSummary(dynamic item) {
    final reactions = reactionsOf(item);

    if (reactions.isEmpty) return '';

    return reactions.map((e) {
      return '${e['reaction']} ${e['count']}';
    }).join(' ');
  }

  // ==================== SCROLL / SNACK / CONFIRM ====================

  void scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!scrollController.hasClients) return;

      if (!force && showScrollToBottomButton) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> confirm({
    required String title,
    required String message,
    bool danger = false,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: panelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              title,
              style: TextStyle(color: textColor),
            ),
            content: Text(
              message,
              style: TextStyle(color: mutedTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger ? dangerColor : telegramBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأیید'),
              ),
            ],
          ),
        );
      },
    );

    return result == true;
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkMode ? const Color(0xFF263442) : null,
        content: Text(
          text,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  // ==================== PROFILE ====================

  Future<void> loadGroupProfile() async {
    groupProfileName = await Session.getGroupName();
    groupProfileAvatar = await Session.getGroupAvatar();

    if (mounted) setState(() {});

    if (groupProfileName.trim().isEmpty) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) askGroupProfile(force: true);
      });
    }
  }

  Future<void> ensureGroupProfile() async {
    groupProfileName = await Session.getGroupName();
    groupProfileAvatar = await Session.getGroupAvatar();

    if (groupProfileName.trim().isEmpty) {
      await askGroupProfile(force: true);
    }

    groupProfileName = await Session.getGroupName();
    groupProfileAvatar = await Session.getGroupAvatar();

    if (mounted) setState(() {});
  }

  Future<void> editGroupProfile() async {
    await askGroupProfile(force: false);
  }

  Future<void> askGroupProfile({bool force = false}) async {
    final nameController = TextEditingController(text: groupProfileName);
    String tempAvatar = groupProfileAvatar;
    bool pickingAvatar = false;

    await showDialog(
      context: context,
      barrierDismissible: !force && groupProfileName.trim().isNotEmpty,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickAvatar() async {
              try {
                setDialogState(() => pickingAvatar = true);

                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );

                if (image == null) {
                  setDialogState(() => pickingAvatar = false);
                  return;
                }

                final bytes = await image.readAsBytes();

                final url = await Api.uploadImageBytes(
                  bytes: bytes,
                  filename: image.name,
                );

                if (url != null && url.isNotEmpty) {
                  tempAvatar = url;
                }
              } catch (_) {
                showMessage('انتخاب عکس انجام نشد');
              }

              setDialogState(() => pickingAvatar = false);
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: panelColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'پروفایل من در گروه',
                  style: TextStyle(color: textColor),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(90),
                        onTap: pickingAvatar ? null : pickAvatar,
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: telegramBlue.withOpacity(.12),
                              backgroundImage: tempAvatar.trim().isNotEmpty
                                  ? NetworkImage(Api.fullImageUrl(tempAvatar))
                                  : null,
                              child: tempAvatar.trim().isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: telegramBlue,
                                    )
                                  : null,
                            ),
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: telegramBlue,
                              child: pickingAvatar
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: nameController,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'نام نمایشی در گروه',
                          hintText: 'مثلاً احمد',
                          filled: true,
                          fillColor: darkMode
                              ? const Color(0xFF0E1621)
                              : const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'برای پیام دادن باید نام گروهی بسازی. این نام و عکس فقط داخل گروه نمایش داده می‌شود.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!force || groupProfileName.trim().isNotEmpty)
                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('بعداً'),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        showMessage('نام خود را وارد کنید');
                        return;
                      }

                      await Session.saveGroupProfile(
                        name: name,
                        avatarUrl: tempAvatar,
                      );

                      groupProfileName = name;
                      groupProfileAvatar = tempAvatar;

                      await saveGroupProfileToServer();
                      await updateLastSeen();

                      if (mounted) setState(() {});

                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('ذخیره'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // ==================== LOAD ====================

  Future<void> loadAll() async {
    if (mounted) {
      setState(() => loading = true);
    }

    await Future.wait([
      loadGroupInfo(),
      loadStats(),
      loadAnnouncements(),
      loadMembers(silent: true),
      loadMessages(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadGroupInfo(),
      updateLastSeen(),
      loadStats(),
      loadAnnouncements(),
      loadMembers(silent: true),
      loadMessages(),
    ]);
  }

  Map<String, String> adminHeaders() {
    return {
      ...Api.ownerHeaders(),
      'x-owner-phone': '015906771961',
    };
  }

  // ==================== API: GROUP INFO ====================

  Future<void> loadGroupInfo() async {
    try {
      final response = await http.get(
        Api.url('/group/info'),
        headers: Api.headers,
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        final info = data['info'];

        if (info is Map && mounted) {
          setState(() {
            officialGroupTitle =
                info['title']?.toString() ?? 'گروه رسمی HeratBazar';
            officialGroupAvatar = info['avatar_url']?.toString() ?? '';
            officialGroupDescription = info['description']?.toString() ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> adminChangeGroupAvatar() async {
    if (!isOwnerUser) {
      showMessage('فقط مدیر می‌تواند عکس گروه را تغییر دهد');
      return;
    }

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      final url = await Api.uploadImageBytes(
        bytes: bytes,
        filename: image.name,
      );

      if (url == null || url.isEmpty) {
        throw Exception('آپلود عکس گروه انجام نشد');
      }

      final response = await http.patch(
        Api.url('/group/info'),
        headers: adminHeaders(),
        body: jsonEncode({
          'avatar_url': url,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200) {
        await loadGroupInfo();
        showMessage('عکس گروه تغییر کرد');
      } else {
        throw Exception(Api.errorMessage(data, 'تغییر عکس گروه انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  // ==================== API: PROFILE / SEEN / TYPING ====================

  Future<Map<String, dynamic>> senderPayload() async {
    final phone = myPhone.trim();
    final guestId = await Session.getGroupGuestId();

    if (myGuestId.isEmpty) {
      myGuestId = guestId;
    }

    return {
      'user_id': isLoggedIn && myUserId > 0 ? myUserId : 0,
      'phone': phone.isNotEmpty ? phone : guestId,
      'sender_phone': phone.isNotEmpty ? phone : guestId,
      'guest_id': guestId,
      'guest_name': groupDisplayName.trim(),
      'guest_avatar_url': groupDisplayAvatar.trim(),
    };
  }

  Future<void> saveGroupProfileToServer() async {
    try {
      final payload = await senderPayload();

      await http.post(
        Api.url('/group/profile'),
        headers: Api.headers,
        body: jsonEncode({
          ...payload,
          'guest_name': groupProfileName,
          'guest_avatar_url': groupProfileAvatar,
        }),
      );
    } catch (_) {}
  }

  Future<void> updateLastSeen() async {
    try {
      final payload = await senderPayload();

      await http.post(
        Api.url('/group/seen'),
        headers: Api.headers,
        body: jsonEncode(payload),
      );
    } catch (_) {}
  }

  void handleTyping() {
    if (!mounted) return;

    if (editingMessage != null) return;

    final text = messageController.text.trim();

    if (text.isEmpty) {
      if (typingSent) {
        typingSent = false;
        sendTypingStatus(false);
      }
      return;
    }

    if (!typingSent) {
      typingSent = true;
      sendTypingStatus(true);
    }

    typingTimer?.cancel();
    typingTimer = Timer(const Duration(seconds: 2), () {
      typingSent = false;
      sendTypingStatus(false);
    });
  }

  Future<void> sendTypingStatus(bool isTyping) async {
    try {
      final payload = await senderPayload();

      await http.post(
        Api.url('/group/typing'),
        headers: Api.headers,
        body: jsonEncode({
          ...payload,
          'is_typing': isTyping,
        }),
      );
    } catch (_) {}
  }

  // ==================== API: STATS / ANNOUNCEMENTS ====================

  Future<void> loadStats() async {
    try {
      final response = await http.get(
        Api.url('/group/stats'),
        headers: Api.headers,
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        final rawStats = data['stats'];

        if (rawStats is Map && mounted) {
          setState(() {
            stats = Map<String, dynamic>.from(rawStats);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> loadAnnouncements() async {
    try {
      final response = await http.get(
        Api.url('/group/announcements'),
        headers: Api.headers,
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        final list = data['announcements'];

        if (list is List && mounted) {
          setState(() {
            announcements = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> createAnnouncement() async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final title = announcementTitleController.text.trim();
    final body = announcementBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      showMessage('عنوان و متن اطلاعیه را وارد کنید');
      return;
    }

    try {
      final response = await http.post(
        Api.url('/group/announcements'),
        headers: adminHeaders(),
        body: jsonEncode({
          'title': title,
          'body': body,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        announcementTitleController.clear();
        announcementBodyController.clear();

        if (mounted) Navigator.pop(context);

        await loadAnnouncements();
        showMessage('اطلاعیه ثبت شد');
      } else {
        throw Exception(Api.errorMessage(data, 'ثبت اطلاعیه انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> deleteAnnouncement(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final id = textOf(item, 'id');
    if (id.isEmpty) return;

    final ok = await confirm(
      title: 'برداشتن اطلاعیه',
      message: 'این اطلاعیه حذف شود؟',
      danger: true,
    );

    if (!ok) return;

    try {
      final response = await http.delete(
        Api.url('/group/announcements/$id'),
        headers: adminHeaders(),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200) {
        await loadAnnouncements();
        showMessage('اطلاعیه برداشته شد');
      } else {
        throw Exception(Api.errorMessage(data, 'حذف اطلاعیه انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }
  // ==================== API: MESSAGES ====================

  Future<void> loadMessages({bool silent = false}) async {
    try {
      final uri = Api.url('/group/messages').replace(
        queryParameters: {
          if (searchText.trim().isNotEmpty) 'q': searchText.trim(),
          'limit': '300',
        },
      );

      final response = await http.get(uri, headers: Api.headers);
      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        final list = data['messages'];

        if (list is List) {
          if (mounted) {
            setState(() {
              messages = list;
            });
          }

          if (!searching && !showScrollToBottomButton) {
            scrollToBottom();
          }
        }
      } else {
        if (!silent) {
          throw Exception(Api.errorMessage(data, 'خطا در دریافت پیام‌ها'));
        }
      }
    } catch (e) {
      if (!silent) {
        showMessage(cleanError(e));
      }
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (sending || uploadingMedia) return;
    if (text.isEmpty) return;

    await ensureGroupProfile();

    if (!hasGroupProfile) {
      showMessage('برای فعالیت در گروه، نام گروهی خود را وارد کنید');
      return;
    }

    sendButtonController.reverse().then((_) {
      if (mounted) sendButtonController.forward();
    });

    if (mounted) setState(() => sending = true);

    try {
      final payload = await senderPayload();

      if (editingMessage != null) {
        final response = await http.patch(
          Api.url('/group/messages/${textOf(editingMessage, 'id')}/edit'),
          headers: Api.headers,
          body: jsonEncode({
            ...payload,
            'user_id': myUserId,
            'guest_id': myGuestId,
            'message': text,
          }),
        );

        final data = Api.decode(response);

        if (response.statusCode == 200 && data is Map) {
          messageController.clear();

          setState(() {
            editingMessage = null;
            replyMessage = null;
          });

          await sendTypingStatus(false);
          await loadMessages(silent: true);
          return;
        }

        throw Exception(Api.errorMessage(data, 'ویرایش انجام نشد'));
      }

      final response = await http.post(
        Api.url('/group/messages'),
        headers: Api.headers,
        body: jsonEncode({
          ...payload,
          'message': text,
          'message_type': 'text',
          if (replyMessage != null)
            'reply_to_message_id': intOf(replyMessage, 'id'),
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        messageController.clear();

        setState(() {
          replyMessage = null;
          editingMessage = null;
        });

        await sendTypingStatus(false);
        await loadMessages(silent: true);
        await updateLastSeen();
        scrollToBottom(force: true);
      } else {
        throw Exception(Api.errorMessage(data, 'ارسال پیام انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }

    if (mounted) {
      setState(() => sending = false);
    }
  }

  Future<void> sendMediaMessage({
    required String mediaUrl,
    required String mediaName,
    required String mediaMime,
    required String messageType,
    String caption = '',
  }) async {
    if (sending) return;

    await ensureGroupProfile();

    if (!hasGroupProfile) {
      showMessage('ابتدا نام گروهی خود را وارد کنید');
      return;
    }

    if (mounted) setState(() => sending = true);

    try {
      final payload = await senderPayload();

      final response = await http.post(
        Api.url('/group/messages'),
        headers: Api.headers,
        body: jsonEncode({
          ...payload,
          'message': caption,
          'message_type': messageType,
          'media_url': mediaUrl,
          'media_name': mediaName,
          'media_mime': mediaMime,
          if (replyMessage != null)
            'reply_to_message_id': intOf(replyMessage, 'id'),
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          replyMessage = null;
          editingMessage = null;
        });

        await loadMessages(silent: true);
        await updateLastSeen();
        scrollToBottom(force: true);
      } else {
        throw Exception(Api.errorMessage(data, 'ارسال فایل انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }

    if (mounted) {
      setState(() => sending = false);
    }
  }

  Future<void> pickAndSendImage() async {
    if (uploadingMedia) return;

    await ensureGroupProfile();

    if (!hasGroupProfile) {
      showMessage('ابتدا نام گروهی خود را وارد کنید');
      return;
    }

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null) return;

      if (mounted) {
        setState(() {
          uploadingMedia = true;
        });
      }

      final bytes = await image.readAsBytes();

      final imageUrl = await Api.uploadImageBytes(
        bytes: bytes,
        filename: image.name,
      );

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('آپلود تصویر انجام نشد');
      }

      await sendMediaMessage(
        mediaUrl: imageUrl,
        mediaName: image.name,
        mediaMime: 'image/jpeg',
        messageType: 'image',
      );
    } catch (e) {
      showMessage(cleanError(e));
    }

    if (mounted) {
      setState(() {
        uploadingMedia = false;
      });
    }
  }

  Future<void> pickAndSendFilePlaceholder() async {
    showMessage('ویدیو و فایل فعلاً غیرفعال است تا سرور سنگین نشود');
  }

  Future<void> sendVoicePlaceholder() async {
    showMessage('ویس در مرحله بعد فعال می‌شود و بعد از ۲۴ ساعت پاک خواهد شد');
  }

  // ==================== API: REACTIONS ====================

  Future<void> reactToMessage(
    dynamic item, {
    String reaction = '❤️',
  }) async {
    await ensureGroupProfile();

    if (!hasGroupProfile) {
      showMessage('ابتدا نام گروهی خود را وارد کنید');
      return;
    }

    try {
      final payload = await senderPayload();

      final response = await http.post(
        Api.url('/group/messages/${textOf(item, 'id')}/react'),
        headers: Api.headers,
        body: jsonEncode({
          ...payload,
          'reaction': reaction,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200) {
        await loadMessages(silent: true);
      } else {
        throw Exception(Api.errorMessage(data, 'ثبت واکنش انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> likeMessage(
    dynamic item, {
    String reaction = '❤️',
  }) async {
    await reactToMessage(item, reaction: reaction);
  }

  // ==================== EDIT / DELETE OWN ====================

  Future<void> editMessage(dynamic item) async {
    if (item is! Map) return;

    if (!isMine(item) && !isOwnerUser) {
      showMessage('این پیام مربوط به شما نیست');
      return;
    }

    final current = textOf(item, 'message');

    if (current.trim().isEmpty) {
      showMessage('فقط پیام متنی قابل ویرایش است');
      return;
    }

    setState(() {
      editingMessage = Map<String, dynamic>.from(item);
      replyMessage = null;
      messageController.text = current;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    });
  }

  void cancelEdit() {
    setState(() {
      editingMessage = null;
      messageController.clear();
    });
  }

  Future<void> deleteOwnMessage(dynamic item) async {
    final mine = isMine(item);

    if (!mine && !isOwnerUser) {
      showMessage('این پیام مربوط به شما نیست');
      return;
    }

    final ok = await confirm(
      title: 'حذف پیام',
      message: isOwnerUser
          ? 'این پیام برای همه حذف شود؟'
          : 'این پیام برای شما حذف شود؟',
      danger: true,
    );

    if (!ok) return;

    try {
      if (isOwnerUser) {
        final response = await http.delete(
          Api.url('/group/messages/${textOf(item, 'id')}'),
          headers: adminHeaders(),
        );

        final data = Api.decode(response);

        if (response.statusCode == 200 && data is Map) {
          await loadMessages(silent: true);
          showMessage('پیام حذف شد');
          return;
        }

        throw Exception(Api.errorMessage(data, 'حذف انجام نشد'));
      }

      final response = await http.delete(
        Api.url('/group/messages/${textOf(item, 'id')}/own'),
        headers: Api.headers,
        body: jsonEncode({
          'user_id': myUserId,
          'guest_id': myGuestId,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMessages(silent: true);
        showMessage('پیام حذف شد');
      } else {
        throw Exception(Api.errorMessage(data, 'حذف انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }
  // ==================== OWNER ACTIONS ====================

  Future<void> adminDeleteMessage(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final ok = await confirm(
      title: 'حذف برای همه',
      message: 'این پیام برای همه حذف شود؟',
      danger: true,
    );

    if (!ok) return;

    try {
      final response = await http.delete(
        Api.url('/group/messages/${textOf(item, 'id')}'),
        headers: adminHeaders(),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMessages(silent: true);
        showMessage('پیام حذف شد');
      } else {
        throw Exception(Api.errorMessage(data, 'حذف انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminPinMessage(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    try {
      final response = await http.patch(
        Api.url('/group/messages/${textOf(item, 'id')}/pin'),
        headers: adminHeaders(),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMessages(silent: true);
        showMessage('پیام سنجاق شد');
      } else {
        throw Exception(Api.errorMessage(data, 'سنجاق پیام انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminUnpinMessage(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    try {
      final response = await http.patch(
        Api.url('/group/messages/${textOf(item, 'id')}/unpin'),
        headers: adminHeaders(),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMessages(silent: true);
        showMessage('سنجاق برداشته شد');
      } else {
        throw Exception(Api.errorMessage(data, 'برداشتن سنجاق انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminBanUser(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final ok = await confirm(
      title: 'مسدود کردن کاربر',
      message: 'این کاربر از گروه رسمی مسدود شود؟',
      danger: true,
    );

    if (!ok) return;

    try {
      final response = await http.post(
        Api.url('/group/ban'),
        headers: adminHeaders(),
        body: jsonEncode({
          if (intOf(item, 'sender_user_id') > 0)
            'user_id': intOf(item, 'sender_user_id'),
          if (intOf(item, 'user_id') > 0) 'user_id': intOf(item, 'user_id'),
          if (textOf(item, 'sender_phone').trim().isNotEmpty)
            'phone': textOf(item, 'sender_phone'),
          if (textOf(item, 'phone').trim().isNotEmpty)
            'phone': textOf(item, 'phone'),
          if (textOf(item, 'guest_id').trim().isNotEmpty)
            'guest_id': textOf(item, 'guest_id'),
          if (textOf(item, 'guest_name').trim().isNotEmpty)
            'guest_name': textOf(item, 'guest_name'),
          'reason': 'مسدود شده توسط مدیریت گروه',
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMembers(silent: true);
        await loadMessages(silent: true);
        showMessage('کاربر مسدود شد');
      } else {
        throw Exception(Api.errorMessage(data, 'مسدود کردن انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminUnbanUser(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    try {
      final response = await http.post(
        Api.url('/group/unban'),
        headers: adminHeaders(),
        body: jsonEncode({
          if (intOf(item, 'sender_user_id') > 0)
            'user_id': intOf(item, 'sender_user_id'),
          if (intOf(item, 'user_id') > 0) 'user_id': intOf(item, 'user_id'),
          if (textOf(item, 'sender_phone').trim().isNotEmpty)
            'phone': textOf(item, 'sender_phone'),
          if (textOf(item, 'phone').trim().isNotEmpty)
            'phone': textOf(item, 'phone'),
          if (textOf(item, 'guest_id').trim().isNotEmpty)
            'guest_id': textOf(item, 'guest_id'),
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMembers(silent: true);
        showMessage('کاربر آن‌بن شد');
      } else {
        throw Exception(Api.errorMessage(data, 'آن‌بن انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminMuteUser(dynamic item, int minutes) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final targetUserId = intOf(item, 'sender_user_id') > 0
        ? intOf(item, 'sender_user_id')
        : intOf(item, 'user_id');

    if (targetUserId <= 0) {
      showMessage('بی‌صدا کردن مهمان فعلاً فقط برای کاربران ثبت‌نامی فعال است');
      return;
    }

    try {
      final response = await http.post(
        Api.url('/group/mute'),
        headers: adminHeaders(),
        body: jsonEncode({
          'user_id': targetUserId,
          'minutes': minutes,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMembers(silent: true);
        showMessage('کاربر بی‌صدا شد');
      } else {
        throw Exception(Api.errorMessage(data, 'بی‌صدا کردن انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> adminUnmuteUser(dynamic item) async {
    if (!isOwnerUser) {
      showMessage('این بخش فقط برای مدیر است');
      return;
    }

    final targetUserId = intOf(item, 'sender_user_id') > 0
        ? intOf(item, 'sender_user_id')
        : intOf(item, 'user_id');

    if (targetUserId <= 0) {
      showMessage('رفع بی‌صدایی مهمان فعلاً فقط برای کاربران ثبت‌نامی فعال است');
      return;
    }

    try {
      final response = await http.post(
        Api.url('/group/unmute'),
        headers: adminHeaders(),
        body: jsonEncode({
          'user_id': targetUserId,
        }),
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        await loadMembers(silent: true);
        showMessage('بی‌صدایی برداشته شد');
      } else {
        throw Exception(Api.errorMessage(data, 'رفع بی‌صدایی انجام نشد'));
      }
    } catch (e) {
      showMessage(cleanError(e));
    }
  }

  Future<void> reportMessage(dynamic item) async {
    showMessage('گزارش پیام ثبت شد');
  }

  Future<void> copyMessage(dynamic item) async {
    final text = textOf(item, 'message');

    if (text.trim().isEmpty) {
      showMessage('متنی برای کپی وجود ندارد');
      return;
    }

    showMessage('متن پیام آماده کپی است');
  }

  Future<void> forwardMessage(dynamic item) async {
    showMessage('فوروارد در مرحله بعد فعال می‌شود');
  }

  // ==================== MEMBERS ====================

  Future<void> loadMembers({bool silent = false}) async {
    if (loadingMembers) return;

    if (mounted) {
      setState(() => loadingMembers = true);
    }

    try {
      final response = await http.get(
        Api.url('/group/members'),
        headers: Api.headers,
      );

      final data = Api.decode(response);

      if (response.statusCode == 200 && data is Map) {
        final list = data['members'];

        if (list is List && mounted) {
          setState(() {
            members = list;
          });
        }
      } else {
        if (!silent) {
          throw Exception(Api.errorMessage(data, 'خطا در دریافت اعضا'));
        }
      }
    } catch (e) {
      if (!silent) showMessage(cleanError(e));
    }

    if (mounted) {
      setState(() => loadingMembers = false);
    }
  }

  void toggleMembersPanel() async {
    await loadMembers(silent: true);
    openMembersSheet();
  }

  // ==================== SEARCH / REPLY ====================

  void runSearch() async {
    final text = searchController.text.trim();

    setState(() {
      searching = text.isNotEmpty;
      searchText = text;
    });

    await loadMessages();
  }

  void clearSearch() async {
    searchController.clear();

    setState(() {
      searching = false;
      searchText = '';
    });

    await loadMessages();
  }

  void startReply(dynamic item) {
    if (item is! Map) return;

    setState(() {
      replyMessage = Map<String, dynamic>.from(item);
      editingMessage = null;
    });
  }

  void cancelReply() {
    setState(() {
      replyMessage = null;
    });
  }
  // ==================== BADGES ====================

  Widget verifiedBadge({double size = 16}) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        Icons.verified,
        color: const Color(0xff1d9bf0),
        size: size,
      ),
    );
  }

  Widget founderBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.deepPurple.withOpacity(.20)),
      ),
      child: const Text(
        'Founder',
        style: TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget bannedBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withOpacity(.20)),
      ),
      child: const Text(
        'Banned',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget onlineDot({double size = 11}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.greenAccent.shade400,
        shape: BoxShape.circle,
        border: Border.all(color: panelColor, width: 2),
      ),
    );
  }

  // ==================== AVATAR ====================

  Widget telegramAvatar({
    required String imageUrl,
    required String name,
    double radius = 18,
    bool owner = false,
    bool online = false,
    VoidCallback? onTap,
  }) {
    final avatar = Api.fullImageUrl(imageUrl);

    final child = Stack(
      clipBehavior: Clip.none,
      children: [
        if (avatar.trim().isNotEmpty)
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: NetworkImage(avatar),
          )
        else
          CircleAvatar(
            radius: radius,
            backgroundColor: owner ? Colors.deepPurple : telegramBlue,
            child: Text(
              firstLetter(name),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * .85,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: onlineDot(size: radius * .62),
          ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(radius * 2),
      onTap: onTap,
      child: child,
    );
  }

  Widget buildAvatar(dynamic item, {double radius = 18}) {
    final owner = isOwner(item);

    return telegramAvatar(
      imageUrl: senderAvatar(item),
      name: senderName(item),
      radius: radius,
      owner: owner,
      online: isOnlineMember(item),
      onTap: () => openMiniProfile(item),
    );
  }

  Widget buildMyGroupAvatar({double radius = 18}) {
    return telegramAvatar(
      imageUrl: groupDisplayAvatar,
      name: groupDisplayName,
      radius: radius,
      owner: isOwnerUser,
      online: true,
      onTap: editGroupProfile,
    );
  }

  Widget buildMemberAvatar(dynamic item, {double radius = 18}) {
    return telegramAvatar(
      imageUrl: memberAvatar(item),
      name: memberName(item),
      radius: radius,
      owner: isOwner(item),
      online: isOnlineMember(item),
      onTap: () => openMiniProfile(item),
    );
  }

  void openAvatarViewer({
    required String imageUrl,
    required String name,
  }) {
    if (imageUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 48,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Positioned(
                right: 16,
                left: 16,
                bottom: 18,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== MINI PROFILE ====================

  void openMiniProfile(dynamic item) {
    final isMessage = item is Map && item.containsKey('message');

    final name = isMessage ? senderName(item) : memberName(item);
    final avatar = isMessage ? senderAvatar(item) : memberAvatar(item);
    final owner = isOwner(item);
    final verified = isVerified(item);

    final phone = textOf(item, 'sender_phone').isNotEmpty
        ? textOf(item, 'sender_phone')
        : textOf(item, 'phone');

    final lastSeen = formatLastSeen(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  telegramAvatar(
                    imageUrl: avatar,
                    name: name,
                    radius: 46,
                    owner: owner,
                    online: isOnlineMember(item),
                    onTap: () {
                      final full = Api.fullImageUrl(avatar);
                      if (full.isNotEmpty) {
                        Navigator.pop(context);
                        openAvatarViewer(imageUrl: full, name: name);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (owner) founderBadge(),
                      if (verified) verifiedBadge(size: 18),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isOnlineMember(item) ? 'آنلاین' : 'آخرین بازدید: $lastSeen',
                    style: TextStyle(
                      color: isOnlineMember(item)
                          ? Colors.greenAccent.shade400
                          : mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                  if (phone.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      phone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showMessage('پیام خصوصی در مرحله بعد فعال می‌شود');
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('پیام خصوصی'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isOwnerUser && !owner)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dangerColor,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              adminBanUser(item);
                            },
                            icon: const Icon(Icons.block),
                            label: const Text('بن'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget buildAppBar() {
    final membersCount =
        stats?['members']?.toString() ?? members.length.toString();
    final typing = typingText();

    return AppBar(
      backgroundColor: darkMode ? const Color(0xFF17212B) : telegramBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 8,
      title: Row(
        textDirection: TextDirection.rtl,
        children: [
          telegramAvatar(
            imageUrl: officialGroupAvatar,
            name: officialGroupTitle,
            radius: 21,
            owner: true,
            online: false,
            onTap: openGroupInfoSheet,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: openGroupInfoSheet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      Flexible(
                        child: Text(
                          officialGroupTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      verifiedBadge(),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      typing.isNotEmpty
                          ? typing
                          : '$membersCount عضو • $onlineCount آنلاین',
                      key: ValueKey(typing.isNotEmpty ? typing : onlineCount),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'جستجو',
          onPressed: () {
            setState(() {
              searching = !searching;
            });
          },
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'پروفایل من',
          onPressed: editGroupProfile,
          icon: const Icon(Icons.account_circle),
        ),
        IconButton(
          tooltip: 'اعضا',
          onPressed: toggleMembersPanel,
          icon: const Icon(Icons.group),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') refreshAll();
            if (value == 'dark') setState(() => darkMode = !darkMode);
            if (value == 'admin') openOwnerPanel();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Text('بروزرسانی'),
            ),
            PopupMenuItem(
              value: 'dark',
              child: Text(darkMode ? 'حالت روشن' : 'حالت شب'),
            ),
            if (isOwnerUser)
              const PopupMenuItem(
                value: 'admin',
                child: Text('پنل مدیریت'),
              ),
          ],
        ),
      ],
    );
  }
  // ==================== GROUP INFO SHEET ====================

  void openGroupInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  telegramAvatar(
                    imageUrl: officialGroupAvatar,
                    name: officialGroupTitle,
                    radius: 48,
                    owner: true,
                    onTap: () {
                      final img = Api.fullImageUrl(officialGroupAvatar);
                      if (img.isNotEmpty) {
                        Navigator.pop(context);
                        openAvatarViewer(
                          imageUrl: img,
                          name: officialGroupTitle,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Flexible(
                        child: Text(
                          officialGroupTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      verifiedBadge(size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${members.length} عضو • $onlineCount آنلاین',
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                  if (officialGroupDescription.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      officialGroupDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            toggleMembersPanel();
                          },
                          icon: const Icon(Icons.group),
                          label: const Text('اعضا'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isOwnerUser)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              adminChangeGroupAvatar();
                            },
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('عکس گروه'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== SEARCH / TOP SECTIONS ====================

  Widget buildSearchBar() {
    if (!searching) return const SizedBox();

    return Container(
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'جستجو در پیام‌ها...',
                hintStyle: TextStyle(color: mutedTextColor),
                filled: true,
                fillColor: darkMode
                    ? const Color(0xFF0E1621)
                    : const Color(0xffF3F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => runSearch(),
            ),
          ),
          IconButton(
            onPressed: runSearch,
            icon: Icon(Icons.search, color: textColor),
          ),
          IconButton(
            onPressed: clearSearch,
            icon: Icon(Icons.close, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget buildAnnouncementBox() {
    if (announcements.isEmpty) return const SizedBox();

    final item = announcements.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: darkMode
              ? [
                  const Color(0xFF3A2F10),
                  const Color(0xFF1D1A10),
                ]
              : [
                  const Color(0xfffff4c7),
                  const Color(0xfffffdf3),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.campaign, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        textOf(item, 'title'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: darkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isOwnerUser)
                      IconButton(
                        tooltip: 'برداشتن اطلاعیه',
                        onPressed: () => deleteAnnouncement(item),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  textOf(item, 'body'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: darkMode ? Colors.white70 : Colors.black87,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPinnedMessage() {
    final pinned = messages.where((e) => boolOf(e, 'is_pinned')).toList();

    if (pinned.isEmpty) return const SizedBox();

    final item = pinned.last;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF2E2A18) : const Color(0xfffffae6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final index = messages.indexOf(item);

          if (index >= 0 && scrollController.hasClients) {
            scrollController.animateTo(
              math.max(0, index * 92),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        },
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.push_pin, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                textOf(item, 'message').isEmpty
                    ? 'عکس یا فایل سنجاق شده'
                    : textOf(item, 'message'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOwnerUser)
              IconButton(
                onPressed: () => adminUnpinMessage(item),
                icon: Icon(
                  Icons.close,
                  color: mutedTextColor,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTopSections() {
    return Column(
      children: [
        buildSearchBar(),
        buildAnnouncementBox(),
        buildPinnedMessage(),
      ],
    );
  }

  // ==================== MESSAGE REPLY / MEDIA ====================

  Widget buildReplyPreview(dynamic item) {
    final replyText = textOf(item, 'reply_message');
    final replyMedia = textOf(item, 'reply_media_url');

    if (replyText.trim().isEmpty && replyMedia.trim().isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(darkMode ? .18 : .035),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          right: BorderSide(
            color: telegramBlue.withOpacity(.85),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            shortReplyName(item),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: telegramBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            replyTextOf(item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: mutedTextColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMediaView(dynamic item) {
    final mediaUrl = Api.fullImageUrl(textOf(item, 'media_url'));
    final mediaName = textOf(item, 'media_name');

    if (mediaUrl.isEmpty) return const SizedBox();

    if (isImageMessage(item)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => openImageViewer(mediaUrl),
          borderRadius: BorderRadius.circular(14),
          child: Hero(
            tag: 'media_$mediaUrl',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                mediaUrl,
                width: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 250,
                    height: 155,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(darkMode ? .16 : .04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.insert_drive_file, color: telegramBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              mediaName.isEmpty ? 'فایل پیوست' : mediaName,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void openImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Center(
                    child: Hero(
                      tag: 'media_$imageUrl',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 48,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== REACTIONS UI ====================

  Widget buildReactions(dynamic item) {
    final reactions = reactionsOf(item);

    if (reactions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: reactions.map((r) {
          final reaction = r['reaction']?.toString() ?? '';
          final count = r['count']?.toString() ?? '0';

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => openReactionPicker(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: telegramBlue.withOpacity(darkMode ? .18 : .08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: telegramBlue.withOpacity(.16),
                ),
              ),
              child: Text(
                '$reaction $count',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget messageStatusIcon(dynamic item, bool mine) {
    if (!mine) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        Icons.done_all,
        size: 15,
        color: telegramBlue.withOpacity(.85),
      ),
    );
  }

  // ==================== MESSAGE BUBBLE ====================

  Widget buildMessageBubble(dynamic item) {
    final mine = isMine(item);
    final owner = isOwner(item);
    final verified = isVerified(item);
    final pinned = boolOf(item, 'is_pinned');
    final editedAt = textOf(item, 'edited_at');
    final messageText = textOf(item, 'message');
    final time = formatTime(item);

    final bubbleColor = mine
        ? (darkMode ? const Color(0xFF2B5278) : bubbleMine)
        : (darkMode ? const Color(0xFF182533) : bubbleOther);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;

        if (velocity.abs() > 250) {
          startReply(item);
        }
      },
      onLongPress: () => openMessageActions(item),
      onDoubleTap: () => reactToMessage(item, reaction: '❤️'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment:
              mine ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) buildAvatar(item, radius: 18),
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                constraints: BoxConstraints(
                  minWidth: 70,
                  maxWidth: math.min(
                    MediaQuery.of(context).size.width * .62,
                    520,
                  ),
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(19),
                    topRight: const Radius.circular(19),
                    bottomLeft: Radius.circular(mine ? 19 : 5),
                    bottomRight: Radius.circular(mine ? 5 : 19),
                  ),
                  border: pinned
                      ? Border.all(
                          color: Colors.amber.shade600,
                          width: 1.1,
                        )
                      : null,
                  boxShadow: [
                    if (!darkMode)
                      BoxShadow(
                        color: Colors.black.withOpacity(.055),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        Flexible(
                          child: Text(
                            senderName(item),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: owner
                                  ? Colors.deepPurpleAccent
                                  : (mine && darkMode
                                      ? Colors.white
                                      : textColor),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (verified) verifiedBadge(size: 15),
                        if (owner) founderBadge(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    buildReplyPreview(item),
                    buildMediaView(item),
                    if (messageText.isNotEmpty)
                      SelectableText(
                        messageText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          color: mine && darkMode ? Colors.white : textColor,
                        ),
                      ),
                    buildReactions(item),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        if (pinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        if (editedAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'ویرایش شده',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                            ),
                          ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: mutedTextColor,
                            ),
                          ),
                        messageStatusIcon(item, mine),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (mine) buildMyGroupAvatar(radius: 18),
          ],
        ),
      ),
    );
  }

  // ==================== MESSAGE LIST ====================

  Widget buildDateHeader(String title) {
    if (title.trim().isEmpty) return const SizedBox();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withOpacity(.10)
              : Colors.black.withOpacity(.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: darkMode ? Colors.white70 : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 150),
        Icon(
          Icons.forum_outlined,
          size: 66,
          color: mutedTextColor,
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            'هنوز پیامی ارسال نشده است',
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: editGroupProfile,
            icon: const Icon(Icons.account_circle),
            label: const Text('ساخت پروفایل گروهی'),
          ),
        ),
      ],
    );
  }

  Widget buildMessageList() {
    if (messages.isEmpty) return buildEmptyState();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final item = messages[index];

        return Column(
          children: [
            if (shouldShowDateHeader(index))
              buildDateHeader(formatDateTitle(textOf(item, 'created_at'))),
            buildMessageBubble(item),
          ],
        );
      },
    );
  }
  // ==================== EDIT / REPLY COMPOSER ====================

  Widget buildEditComposer() {
    if (editingMessage == null) return const SizedBox();

    return Container(
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ویرایش پیام',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  textOf(editingMessage, 'message'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: mutedTextColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: cancelEdit,
            icon: Icon(Icons.close, color: mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget buildReplyComposer() {
    if (replyMessage == null) return const SizedBox();

    return Container(
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: telegramBlue,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  senderName(replyMessage),
                  style: const TextStyle(
                    color: telegramBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  textOf(replyMessage, 'message').isEmpty
                      ? 'عکس یا فایل'
                      : textOf(replyMessage, 'message'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: mutedTextColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: cancelReply,
            icon: Icon(Icons.close, color: mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget buildTypingTinyBar() {
    final text = typingText();
    if (text.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: telegramBlue.withOpacity(.75),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: telegramBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INPUT BOX ====================

  Widget buildInputBox() {
    final isEditing = editingMessage != null;

    return Container(
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isEditing)
              IconButton(
                tooltip: 'عکس',
                onPressed: uploadingMedia ? null : pickAndSendImage,
                icon: uploadingMedia
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.image, color: mutedTextColor),
              ),
            if (!isEditing)
              PopupMenuButton<String>(
                icon: Icon(Icons.attach_file, color: mutedTextColor),
                onSelected: (value) {
                  if (value == 'photo') pickAndSendImage();
                  if (value == 'voice') sendVoicePlaceholder();
                  if (value == 'file') pickAndSendFilePlaceholder();
                  if (value == 'video') pickAndSendFilePlaceholder();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'photo', child: Text('ارسال عکس')),
                  PopupMenuItem(value: 'voice', child: Text('ارسال ویس')),
                  PopupMenuItem(value: 'video', child: Text('ویدیو فعلاً غیرفعال')),
                  PopupMenuItem(value: 'file', child: Text('فایل فعلاً غیرفعال')),
                ],
              ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: darkMode
                      ? const Color(0xFF0E1621)
                      : const Color(0xffF3F5F8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: messageController,
                  minLines: 1,
                  maxLines: 5,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: isEditing ? 'ویرایش پیام...' : 'پیام بنویسید...',
                    hintStyle: TextStyle(color: mutedTextColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: sendButtonController,
              child: CircleAvatar(
                backgroundColor: isEditing ? Colors.orange : telegramBlue,
                radius: 22,
                child: IconButton(
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isEditing ? Icons.check : Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MEMBERS SHEET ====================

  void openMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        final onlineMembers = members.where((m) => isOnlineMember(m)).length;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .72,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'اعضای گروه',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${members.length} عضو • $onlineMembers آنلاین',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: mutedTextColor),
                    ),
                    trailing: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: mutedTextColor),
                    ),
                  ),
                  Divider(color: mutedTextColor.withOpacity(.2), height: 1),
                  Expanded(
                    child: loadingMembers
                        ? const Center(child: CircularProgressIndicator())
                        : members.isEmpty
                            ? Center(
                                child: Text(
                                  'عضوی برای نمایش وجود ندارد',
                                  style: TextStyle(color: mutedTextColor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (_, index) {
                                  return buildMemberTile(members[index]);
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

  Widget buildMemberTile(dynamic item) {
    final verified = isVerified(item);
    final owner = isOwner(item);
    final banned = boolOf(item, 'is_banned');
    final online = isOnlineMember(item);

    return ListTile(
      onTap: () => openMiniProfile(item),
      leading: buildMemberAvatar(item, radius: 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (banned) bannedBadge(),
          if (owner) founderBadge(),
          if (verified) verifiedBadge(size: 15),
          Flexible(
            child: Text(
              memberName(item),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: online ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        online
            ? 'آنلاین'
            : boolOf(item, 'is_typing')
                ? 'در حال نوشتن...'
                : formatLastSeen(item),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: online ? Colors.greenAccent.shade400 : mutedTextColor,
          fontSize: 12,
        ),
      ),
      trailing: isOwnerUser && !owner
          ? PopupMenuButton<String>(
              color: panelColor,
              onSelected: (value) {
                if (value == 'mute1') adminMuteUser(item, 60);
                if (value == 'mute24') adminMuteUser(item, 1440);
                if (value == 'unmute') adminUnmuteUser(item);
                if (value == 'ban') adminBanUser(item);
                if (value == 'unban') adminUnbanUser(item);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'mute1',
                  child: Text(
                    'بی‌صدا ۱ ساعت',
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem(
                  value: 'mute24',
                  child: Text(
                    'بی‌صدا ۲۴ ساعت',
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem(
                  value: 'unmute',
                  child: Text(
                    'رفع بی‌صدایی',
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem(
                  value: 'ban',
                  child: Text(
                    'بن کردن',
                    style: TextStyle(color: dangerColor),
                  ),
                ),
                PopupMenuItem(
                  value: 'unban',
                  child: Text(
                    'آن‌بن کردن',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            )
          : null,
    );
  }
  // ==================== MESSAGE ACTIONS ====================

  void openMessageActions(dynamic item) {
    final mine = isMine(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: math.min(
                MediaQuery.of(context).size.height * .78,
                620,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  buildActionTile(
                    icon: Icons.reply,
                    title: 'پاسخ دادن',
                    onTap: () {
                      Navigator.pop(context);
                      startReply(item);
                    },
                  ),
                  buildActionTile(
                    icon: Icons.favorite,
                    title: 'لایک',
                    onTap: () {
                      Navigator.pop(context);
                      reactToMessage(item, reaction: '❤️');
                    },
                  ),
                  buildActionTile(
                    icon: Icons.emoji_emotions,
                    title: 'واکنش‌ها',
                    onTap: () {
                      Navigator.pop(context);
                      openReactionPicker(item);
                    },
                  ),
                  buildActionTile(
                    icon: Icons.copy,
                    title: 'کپی متن',
                    onTap: () {
                      Navigator.pop(context);
                      copyMessage(item);
                    },
                  ),
                  buildActionTile(
                    icon: Icons.forward,
                    title: 'فوروارد',
                    onTap: () {
                      Navigator.pop(context);
                      forwardMessage(item);
                    },
                  ),
                  buildActionTile(
                    icon: Icons.report_gmailerrorred,
                    title: 'گزارش پیام',
                    onTap: () {
                      Navigator.pop(context);
                      reportMessage(item);
                    },
                  ),
                  if (mine || isOwnerUser)
                    buildActionTile(
                      icon: Icons.edit,
                      title: 'ویرایش پیام',
                      onTap: () {
                        Navigator.pop(context);
                        editMessage(item);
                      },
                    ),
                  if (mine || isOwnerUser)
                    buildActionTile(
                      icon: Icons.delete,
                      iconColor: dangerColor,
                      title: 'حذف پیام',
                      onTap: () {
                        Navigator.pop(context);
                        deleteOwnMessage(item);
                      },
                    ),
                  if (isOwnerUser) ...[
                    Divider(color: mutedTextColor.withOpacity(.2)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ابزارهای مدیر',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    buildActionTile(
                      icon: Icons.push_pin,
                      title: 'سنجاق کردن',
                      onTap: () {
                        Navigator.pop(context);
                        adminPinMessage(item);
                      },
                    ),
                    buildActionTile(
                      icon: Icons.push_pin_outlined,
                      title: 'برداشتن سنجاق',
                      onTap: () {
                        Navigator.pop(context);
                        adminUnpinMessage(item);
                      },
                    ),
                    buildActionTile(
                      icon: Icons.volume_off,
                      title: 'بی‌صدا کردن ۱ ساعت',
                      onTap: () {
                        Navigator.pop(context);
                        adminMuteUser(item, 60);
                      },
                    ),
                    buildActionTile(
                      icon: Icons.timer_off,
                      title: 'بی‌صدا کردن ۲۴ ساعت',
                      onTap: () {
                        Navigator.pop(context);
                        adminMuteUser(item, 1440);
                      },
                    ),
                    buildActionTile(
                      icon: Icons.block,
                      iconColor: dangerColor,
                      title: 'مسدود کردن',
                      onTap: () {
                        Navigator.pop(context);
                        adminBanUser(item);
                      },
                    ),
                    buildActionTile(
                      icon: Icons.delete_forever,
                      iconColor: dangerColor,
                      title: 'حذف برای همه',
                      onTap: () {
                        Navigator.pop(context);
                        adminDeleteMessage(item);
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor ?? mutedTextColor),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }

  // ==================== REACTION PICKER ====================

  void openReactionPicker(dynamic item) {
    final reactions = [
      '❤️',
      '👍',
      '😂',
      '😮',
      '😢',
      '🔥',
      '👏',
      '😍',
      '😡',
      '🎉',
      '🙏',
      '💯',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'انتخاب واکنش',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: reactions.map((emoji) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          Navigator.pop(context);
                          reactToMessage(item, reaction: emoji);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: darkMode
                                ? const Color(0xFF0E1621)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: telegramBlue.withOpacity(.10),
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 27),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (hasReactions(item)) ...[
                    const SizedBox(height: 14),
                    Text(
                      reactionSummary(item),
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== OWNER PANEL ====================

  Widget buildOwnerButton() {
    if (!isOwnerUser) return const SizedBox();

    return Positioned(
      left: 14,
      bottom: 92,
      child: FloatingActionButton.small(
        heroTag: 'owner_group_button',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: openOwnerPanel,
        child: const Icon(Icons.admin_panel_settings),
      ),
    );
  }

  void openOwnerPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: math.min(
                MediaQuery.of(context).size.height * .72,
                560,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: Colors.deepPurple,
                    ),
                    title: Text(
                      'پنل مدیریت گروه رسمی',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'ابزارهای مخصوص مدیر / Founder',
                      style: TextStyle(color: mutedTextColor),
                    ),
                  ),
                  Divider(color: mutedTextColor.withOpacity(.2)),
                  buildActionTile(
                    icon: Icons.photo_camera,
                    title: 'تغییر عکس گروه',
                    onTap: () {
                      Navigator.pop(context);
                      adminChangeGroupAvatar();
                    },
                  ),
                  buildActionTile(
                    icon: Icons.campaign,
                    title: 'ساخت اطلاعیه رسمی',
                    onTap: () {
                      Navigator.pop(context);
                      openAnnouncementDialog();
                    },
                  ),
                  buildActionTile(
                    icon: Icons.account_circle,
                    title: 'تنظیم نام و عکس من',
                    onTap: () {
                      Navigator.pop(context);
                      editGroupProfile();
                    },
                  ),
                  buildActionTile(
                    icon: Icons.group,
                    title: 'نمایش اعضا',
                    onTap: () {
                      Navigator.pop(context);
                      toggleMembersPanel();
                    },
                  ),
                  buildActionTile(
                    icon: Icons.push_pin,
                    title: 'پیام‌های سنجاق‌شده',
                    onTap: () {
                      Navigator.pop(context);
                      showPinnedMessagesSheet();
                    },
                  ),
                  buildActionTile(
                    icon: Icons.refresh,
                    title: 'بروزرسانی گروه',
                    onTap: () {
                      Navigator.pop(context);
                      refreshAll();
                    },
                  ),
                  buildActionTile(
                    icon: darkMode ? Icons.light_mode : Icons.dark_mode,
                    title: darkMode ? 'حالت روشن' : 'حالت شب',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => darkMode = !darkMode);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ==================== ANNOUNCEMENT DIALOG ====================

  void openAnnouncementDialog() {
    if (!isOwnerUser) {
      showMessage('فقط مدیر');
      return;
    }

    announcementTitleController.clear();
    announcementBodyController.clear();

    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: panelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'اطلاعیه جدید',
              style: TextStyle(color: textColor),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: announcementTitleController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'عنوان',
                      filled: true,
                      fillColor: darkMode
                          ? const Color(0xFF0E1621)
                          : const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: announcementBodyController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: textColor),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'متن اطلاعیه',
                      filled: true,
                      fillColor: darkMode
                          ? const Color(0xFF0E1621)
                          : const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton.icon(
                onPressed: createAnnouncement,
                icon: const Icon(Icons.check),
                label: const Text('ثبت'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== PINNED MESSAGES SHEET ====================

  void showPinnedMessagesSheet() {
    final pinned = messages.where((e) => boolOf(e, 'is_pinned')).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: math.min(
                MediaQuery.of(context).size.height * .72,
                520,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'پیام‌های سنجاق‌شده',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${pinned.length} پیام',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: mutedTextColor),
                    ),
                    trailing: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: mutedTextColor),
                    ),
                  ),
                  Divider(color: mutedTextColor.withOpacity(.2), height: 1),
                  Expanded(
                    child: pinned.isEmpty
                        ? Center(
                            child: Text(
                              'پیام سنجاق‌شده‌ای وجود ندارد',
                              style: TextStyle(color: mutedTextColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pinned.length,
                            itemBuilder: (_, index) {
                              final item = pinned[index];

                              return ListTile(
                                leading: const Icon(
                                  Icons.push_pin,
                                  color: Colors.amber,
                                ),
                                title: Text(
                                  textOf(item, 'message').isEmpty
                                      ? 'عکس یا فایل'
                                      : textOf(item, 'message'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: textColor),
                                ),
                                subtitle: Text(
                                  senderName(item),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: mutedTextColor),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  final realIndex = messages.indexOf(item);
                                  if (realIndex >= 0 &&
                                      scrollController.hasClients) {
                                    scrollController.animateTo(
                                      math.max(0, realIndex * 92),
                                      duration:
                                          const Duration(milliseconds: 350),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                trailing: isOwnerUser
                                    ? IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          adminUnpinMessage(item);
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: mutedTextColor,
                                        ),
                                      )
                                    : null,
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

  // ==================== FLOATING UI ====================

  Widget buildScrollToBottomButton() {
    if (!showScrollToBottomButton) return const SizedBox();

    return Positioned(
      right: 14,
      bottom: 94,
      child: FloatingActionButton.small(
        heroTag: 'scroll_down_group',
        backgroundColor: panelColor,
        foregroundColor: telegramBlue,
        onPressed: () => scrollToBottom(force: true),
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }

  Widget buildUploadingBanner() {
    if (!uploadingMedia) return const SizedBox();

    return Positioned(
      top: 8,
      right: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: telegramBlue.withOpacity(.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'در حال آپلود عکس...',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BODY ====================

  Widget buildBody() {
    if (loading) {
      return Container(
        color: pageBg,
        child: const Center(
          child: CircularProgressIndicator(color: telegramBlue),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: pageBg,
          child: Column(
            children: [
              buildTopSections(),
              Expanded(
                child: RefreshIndicator(
                  color: telegramBlue,
                  onRefresh: refreshAll,
                  child: buildMessageList(),
                ),
              ),
              buildTypingTinyBar(),
              buildEditComposer(),
              buildReplyComposer(),
              buildInputBox(),
            ],
          ),
        ),
        buildScrollToBottomButton(),
        buildOwnerButton(),
        buildUploadingBanner(),
      ],
    );
  }
  // ==================== MAIN BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: buildAppBar(),
        body: buildBody(),
      ),
    );
  }
}
