import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'chat_message.dart';
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  static const route = '/chats';
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _messagesFuture;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageListener();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 100) {
        setState(() => _showScrollToBottom = true);
      } else {
        setState(() => _showScrollToBottom = false);
      }
    });
  }

  /* ─────────────── message helpers ─────────────── */

  void _loadMessages() {
    _messagesFuture = ChatService.getMessages();
  }

  void _setupMessageListener() {
    ChatService.messageListenable.addListener(() {
      if (mounted) setState(() => _loadMessages());
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    await msg.delete(); // your model’s delete()
    setState(() => _loadMessages());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete message?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  /* ─────────────── UI helpers ─────────────── */

  void _scrollToBottom() => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );

  void _showMessageMenu(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(msg.body);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.trash),
              title: const Text('Delete'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                Navigator.pop(ctx);
                if (await _confirmDelete()) _deleteMessage(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  /* ─────────────── build ─────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadMessages)
        ],
      ),
      body: Container(
        color: Colors.white,
        child: FutureBuilder<List<ChatMessage>>(
          future: _messagesFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }
            if (snap.hasError) {
              return _buildError();
            }

            final messages = snap.data ?? [];
            if (messages.isEmpty) return _buildEmptyState();

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => _loadMessages(),
                  color: Theme.of(context).primaryColor,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _buildMessageItem(messages[i]),
                  ),
                ),
                if (_showScrollToBottom)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Theme.of(context).primaryColor,
                      child:
                          const Icon(Iconsax.arrow_down_1, color: Colors.white),
                      onPressed: _scrollToBottom,
                    ),
                  ).animate().fadeIn().scale(),
              ],
            );
          },
        ),
      ),
    );
  }

  /* ─────────────── item widgets ─────────────── */

  Widget _buildMessageItem(ChatMessage msg) {
    return Dismissible(
      key: ValueKey(msg.id ?? msg.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red.shade400,
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _deleteMessage(msg),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onLongPress: () => _showMessageMenu(msg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              // color: Colors.white,
              color: Color(0xFFE3E3E3),
          
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SelectableText(
              msg.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ).animate().fadeIn(duration: 200.ms).slideX(
                begin: -0.2,
                curve: Curves.easeOut,
              ),
        ),
      ),
    );
  }


  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load messages',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.message,
                size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text('No messages yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).disabledColor)),
            const SizedBox(height: 8),
            Text('Your notifications will appear here',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );

  Widget _buildShimmerLoading() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: 10,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                3,
                (j) => Padding(
                  padding: EdgeInsets.only(bottom: j == 2 ? 0 : 12),
                  child: Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width *
                        (j == 0 ? 1.0 : j == 1 ? .7 : .4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 1500.ms, delay: (i * 100 + j * 50).ms),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
