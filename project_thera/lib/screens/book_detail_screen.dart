import 'package:flutter/material.dart';
import 'dart:io';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/error_dialog.dart';
import 'book_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  Future<void> _openDocument() async {
    if (_book.pdfUrl == null || _book.pdfUrl!.isEmpty) {
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: 'No File Path',
          message:
              'No file path is available for this book. Please add a file to this book first.',
          icon: Icons.file_download_outlined,
          actions: [
            DialogAction(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              style: DialogActionStyle.primary,
            ),
          ],
        );
      }
      return;
    }

    // Try to check if file exists (may fail on Android 11+ due to scoped storage)
    bool fileExists = false;
    try {
      final file = File(_book.pdfUrl!);
      fileExists = file.existsSync();
    } catch (e) {
      // On Android 11+, existsSync may fail even if file exists
      fileExists = false;
    }

    if (!fileExists && !Platform.isAndroid) {
      // For non-Android, show error if file doesn't exist
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: 'File Not Found',
          message:
              'The file may have been moved, deleted, or renamed. Please update the file path for this book.',
          fileName: _book.pdfUrl!.split('/').last,
          icon: Icons.file_download_outlined,
          actions: [
            DialogAction(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              style: DialogActionStyle.primary,
            ),
          ],
        );
      }
      return;
    }

    // Navigate to PDF reader - it will handle Android 11+ file access issues
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookReaderScreen(book: _book)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share book
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover and Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _book.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.book, size: 60);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _book.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _book.author,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      if (_book.genre != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(_book.genre!),
                          backgroundColor: AppTheme.inputBackground,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_book.progress}%',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _book.progress / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Page ${_book.currentPage} of ${_book.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openDocument,
                icon: const Icon(Icons.book_outlined),
                label: const Text('Open Document'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Start reading session
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Reading Session'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Status', _getStatusLabel(_book.status)),
                    if (_book.dateAdded != null)
                      _buildDetailRow(
                        'Date Added',
                        _formatDate(_book.dateAdded!),
                      ),
                    if (_book.dateStarted != null)
                      _buildDetailRow(
                        'Date Started',
                        _formatDate(_book.dateStarted!),
                      ),
                    if (_book.dateCompleted != null)
                      _buildDetailRow(
                        'Date Completed',
                        _formatDate(_book.dateCompleted!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return 'Reading';
      case BookStatus.completed:
        return 'Completed';
      case BookStatus.wantToRead:
        return 'Want to Read';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
