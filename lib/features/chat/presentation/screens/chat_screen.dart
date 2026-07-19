import 'package:chat_app/core/theme/app_theme.dart';
import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:chat_app/features/chat/data/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  final String receiverId;
  final String receiverName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final messageController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await ChatService().sendMessage(widget.receiverId, text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d, yyyy').format(date);
  }

  bool _shouldShowDaySeparator(List docs, int index) {
    final Timestamp? currentTs =
        (docs[index].data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
    if (currentTs == null) return false;
    if (index == 0) return true;

    final Timestamp? prevTs =
        (docs[index - 1].data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
    if (prevTs == null) return true;

    final current = currentTs.toDate();
    final prev = prevTs.toDate();
    return current.year != prev.year ||
        current.month != prev.month ||
        current.day != prev.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final messages = ref.watch(messagesProvider(widget.receiverId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            final String name = widget.receiverName;
            bool isOnline = false;
            String profileUrl = '';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                isOnline = data['isOnline'] ?? false;
                profileUrl = data['profileUrl'] ?? '';
              }
            }

            return Row(
              children: [
                UserAvatar(
                  name: name,
                  profileUrl: profileUrl,
                  isOnline: isOnline,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isOnline
                              ? AppTheme.onlineGreen
                              : AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.divider.withValues(alpha: 0.8),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor,
                    AppTheme.cardColor.withValues(alpha: 0.35),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: messages.when(
                data: (snapshot) {
                  final docs = snapshot.docs;
                  _scrollToBottom();

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 28,
                                color: AppTheme.secondaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Say hi to ${widget.receiverName}',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This is the start of your conversation',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == currentUid;
                      final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                      final String timeText = timestamp != null
                          ? DateFormat('h:mm a').format(timestamp.toDate())
                          : '';

                      final showDay = _shouldShowDaySeparator(docs, index);

                      // Group consecutive same-sender bubbles
                      bool isFirstInGroup = true;
                      bool isLastInGroup = true;
                      if (index > 0) {
                        final prev =
                            docs[index - 1].data() as Map<String, dynamic>;
                        isFirstInGroup = prev['senderId'] != data['senderId'] ||
                            showDay;
                      }
                      if (index < docs.length - 1) {
                        final next =
                            docs[index + 1].data() as Map<String, dynamic>;
                        final nextTs = next['timestamp'] as Timestamp?;
                        final currentDay = timestamp?.toDate();
                        final nextDay = nextTs?.toDate();
                        final dayBreak = currentDay != null &&
                            nextDay != null &&
                            (currentDay.year != nextDay.year ||
                                currentDay.month != nextDay.month ||
                                currentDay.day != nextDay.day);
                        isLastInGroup =
                            next['senderId'] != data['senderId'] || dayBreak;
                      }

                      return Column(
                        children: [
                          if (showDay && timestamp != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatDayLabel(timestamp.toDate()),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: isFirstInGroup ? 6 : 2,
                                bottom: isLastInGroup ? 6 : 2,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.76,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    10,
                                    12,
                                    8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isMe
                                        ? const LinearGradient(
                                            colors: [
                                              AppTheme.bubbleSentStart,
                                              AppTheme.bubbleSentEnd,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isMe ? null : AppTheme.bubbleReceived,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        isMe
                                            ? 18
                                            : (isFirstInGroup ? 18 : 6),
                                      ),
                                      topRight: Radius.circular(
                                        isMe
                                            ? (isFirstInGroup ? 18 : 6)
                                            : 18,
                                      ),
                                      bottomLeft: Radius.circular(
                                        isMe
                                            ? 18
                                            : (isLastInGroup ? 4 : 6),
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe
                                            ? (isLastInGroup ? 4 : 6)
                                            : 18,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        data['message'],
                                        style: GoogleFonts.plusJakartaSans(
                                          color: isMe
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeText,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: isMe
                                              ? Colors.white.withValues(alpha: 0.7)
                                              : AppTheme.textSecondary
                                                  .withValues(alpha: 0.55),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (e, st) => Center(
                  child: Text(
                    e.toString(),
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.errorColor),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
          _MessageComposer(
            controller: messageController,
            hasText: _hasText,
            onSend: sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.hasText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.divider.withValues(alpha: 0.9)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasText
                      ? const LinearGradient(
                          colors: [
                            AppTheme.bubbleSentStart,
                            AppTheme.bubbleSentEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasText ? null : AppTheme.surfaceElevated,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasText ? onSend : null,
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: hasText
                          ? Colors.white
                          : AppTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
