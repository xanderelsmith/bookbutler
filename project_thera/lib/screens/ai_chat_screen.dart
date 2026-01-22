import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/serverpod_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends ConsumerStatefulWidget {
  final String bookTitle;
  final String pageInfo;
  final String extractedText;
  final String? bookFilePath; // Optional: for PDF range extraction
  final int? currentPage;
  final int? totalPages;

  final String? initialQuestion;
  final bool isHighlightedText;

  const AiChatScreen({
    super.key,
    required this.extractedText,
    required this.bookTitle,
    required this.pageInfo,
    this.bookFilePath,
    this.currentPage,
    this.totalPages,
    this.initialQuestion,
    this.isHighlightedText = false,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late ScrollController scrollController;

  String _rangeText = '';
  bool _isLoadingRange = false;

  // PageView controller for range selector and preview
  late PageController _pageViewController;
  int _currentPageViewIndex = 0;

  @override
  void initState() {
    scrollController = ScrollController();
    _pageViewController = PageController();
    // Initialize page range
    if (widget.currentPage != null && widget.totalPages != null) {}
    _rangeText = widget.extractedText;
    super.initState();

    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendRequest(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    scrollController.dispose();
    _pageViewController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendRequest(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    try {
      // Use range text if available, otherwise fallback to extracted text
      final content = _rangeText.isNotEmpty ? _rangeText : widget.extractedText;
      log(content);
      final client = ref.read(serverpodServiceProvider).client;
      // Note: You might want to pass history here if the API supports it in the future
      final response = await client.ai.askAboutPage(content, question);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error: $e',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _saveSnippet(String text) {
    // For now, we just show the snackbar as requested.
    // This could later be expanded to save to a database or file.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text('Ask AI'),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
              },
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Ask a question about this page',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Text.rich(
                TextSpan(
                  text: '${widget.bookTitle}\n ',
                  children: [
                    TextSpan(
                      text: '--${widget.pageInfo}--',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              // Page range selector (if PDF)
              if (widget.bookFilePath != null &&
                  widget.totalPages != null &&
                  widget.totalPages! > 1)
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        _rangeText.isNotEmpty
                            ? _rangeText
                            : widget.extractedText,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    label: const Text('Generate Tweet'),
                    avatar: const Icon(Icons.post_add, size: 18),
                    onPressed: () => _sendRequest(
                      'Generate a short Tweet from this as me (in first person)',
                    ),
                  ),
                  ActionChip(
                    label: const Text('Summarize Page'),
                    avatar: const Icon(Icons.summarize, size: 18),
                    onPressed: () => _sendRequest('Summarize this page'),
                  ),
                  ActionChip(
                    label: const Text('Key Points'),
                    avatar: const Icon(Icons.list, size: 18),
                    onPressed: () =>
                        _sendRequest('List key points from this page'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : null,
            bottomLeft: !message.isUser ? const Radius.circular(0) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isUser)
              Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.5),
              )
            else
              MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  strong: TextStyle(color: Colors.blue, fontSize: 14),
                  a: TextStyle(color: Colors.black),
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                    height: 1.5,
                  ),
                  listBullet: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            const SizedBox(height: 8),
            if (!message.isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Share.share(message.text);
                    },
                    child: Icon(
                      Icons.share,
                      size: 16,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _saveSnippet(message.text),
                    child: Icon(
                      Icons.download,
                      size: 16,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask about this page...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: _sendRequest,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _sendRequest(_textController.text);
              }
            },
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPageRangeText(int startPage, int endPage) async {
    if (widget.bookFilePath == null) return;

    setState(() {
      _isLoadingRange = true;
    });

    try {
      // Get text for the page range
      final rangeText = await ReadPdfText.getPDFtextForRange(
        widget.bookFilePath!,
        startPage,
        endPage,
      );

      if (mounted) {
        setState(() {
          _rangeText = rangeText;
          _isLoadingRange = false;
        });
      }
    } catch (e) {
      log('Error loading page range: $e');
      if (mounted) {
        setState(() {
          _isLoadingRange = false;
        });
      }
    }
  }
}
