import 'package:flutter/material.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:project_thera/models/book.dart';
import 'package:project_thera/theme/app_theme.dart';

class ReaderHeader extends StatelessWidget {
  final Book book;
  final int currentPage;
  final int totalPages;
  final int progress;
  final bool isDocx;
  final bool isSearchActive;
  final bool isFullscreen;
  final TextEditingController searchTextController;
  final DocxSearchController docxSearchController;
  final VoidCallback onClose;
  final VoidCallback onSaveSnippet;
  final VoidCallback onToggleSearch;
  final VoidCallback onAskAi;
  final VoidCallback onSettings;

  const ReaderHeader({
    super.key,
    required this.book,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.isDocx,
    required this.isSearchActive,
    required this.isFullscreen,
    required this.searchTextController,
    required this.docxSearchController,
    required this.onClose,
    required this.onSaveSnippet,
    required this.onToggleSearch,
    required this.onAskAi,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: onSaveSnippet,
                      ),
                      if (isDocx)
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: onToggleSearch,
                        ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: onAskAi,
                        tooltip: 'Ask AI',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: onSettings,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Book Title (or Search Bar)
              if (isSearchActive && isDocx)
                _buildSearchBar()
              else ...[
                Text(
                  book.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(book.author, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 2,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Page $currentPage of $totalPages'),
                  Text('$progress%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchTextController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search text...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onSubmitted: (value) => docxSearchController.search(value),
            onChanged: (value) => docxSearchController.search(value),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (docxSearchController.matchCount > 0)
          Text(
            '${docxSearchController.currentMatchIndex + 1}/${docxSearchController.matchCount}',
            style: const TextStyle(fontSize: 14),
          ),
        IconButton(
          icon: const Icon(Icons.expand_less),
          onPressed: docxSearchController.previousMatch,
          tooltip: 'Previous',
        ),
        IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: docxSearchController.nextMatch,
          tooltip: 'Next',
        ),
      ],
    );
  }
}
