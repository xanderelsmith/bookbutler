import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart' as Shareplus;
import 'package:share_plus/share_plus.dart';
import '../providers/serverpod_provider.dart';
import 'dart:developer';

class AiQueryContent extends ConsumerStatefulWidget {
  final Future<String> Function() getContent;

  const AiQueryContent({super.key, required this.getContent});

  @override
  ConsumerState<AiQueryContent> createState() => _AiQueryContentState();
}

class _AiQueryContentState extends ConsumerState<AiQueryContent> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _aiResponse;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(String question) async {
    setState(() {
      _aiResponse = null;
      _isLoading = true;
    });

    try {
      final content = await widget.getContent();
      log(content);
      final client = ref.read(serverpodServiceProvider).client;
      final response = await client.ai.askAboutPage(content, question);

      if (mounted) {
        setState(() {
          _aiResponse = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponse = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text('Ask AI', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_aiResponse == null && !_isLoading) ...[
                    Text(
                      'Ask a question about this page or generate a summary.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Generate Tweet'),
                          avatar: const Icon(Icons.summarize, size: 18),
                          onPressed: () {
                            _textController.text = 'Generate Tweet from this';
                            _sendRequest(
                              'Generate a short Tweet from this as me (in first person)',
                            );
                          },
                        ),
                        ActionChip(
                          label: const Text('Summarize Page'),
                          avatar: const Icon(Icons.summarize, size: 18),
                          onPressed: () {
                            _textController.text = 'Summarize this page';
                            _sendRequest('Summarize this page');
                          },
                        ),
                        ActionChip(
                          label: const Text('Key Points'),
                          avatar: const Icon(Icons.list, size: 18),
                          onPressed: () {
                            _textController.text = 'List key points';
                            _sendRequest('List key points from this page');
                          },
                        ),
                      ],
                    ),
                  ] else if (_isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_aiResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AI Response',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () {
                                  if (_aiResponse != null) {
                                    SharePlus.instance.share(
                                      ShareParams(text: _aiResponse!),
                                    );
                                  }
                                },
                                tooltip: 'Share Response',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiResponse!,
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Input Area
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask about this page...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _sendRequest(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_textController.text.isNotEmpty) {
                          _sendRequest(_textController.text);
                        }
                      },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
