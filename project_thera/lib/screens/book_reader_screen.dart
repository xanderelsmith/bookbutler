import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/book.dart';
import '../models/reading_snippet.dart';
import '../providers/book_providers.dart';
import '../providers/snippet_providers.dart';
import '../providers/reading_activity_providers.dart';
import '../providers/streak_provider.dart';
import '../providers/home_widget_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_dialog.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  // PDF specific
  PdfViewerController? _pdfController;

  // Docx specific
  late DocxSearchController _docxSearchController;

  // Text/Docx specific
  String? _textContent;
  final ScrollController _scrollController = ScrollController();
  static const int _charsPerPage = 3000; // Approximation for text files

  final NotificationService _notificationService = NotificationService();

  bool _isSearchActive = false;
  final TextEditingController _searchTextController = TextEditingController();

  bool _showControls = true;
  bool _isFullscreen = false;
  double _brightness = 1.0;
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPageNumber = 1;
  int _lastTrackedPage = 0; // Track last page that triggered progress update
  bool _controllerInitialized = false;

  // File type detection
  bool get _isPdf =>
      widget.book.pdfUrl?.toLowerCase().endsWith('.pdf') ?? false;
  bool get _isDocx =>
      widget.book.pdfUrl?.toLowerCase().endsWith('.docx') ?? false;
  bool get _isTextBased => !_isPdf && !_isDocx; // Text only

  @override
  void initState() {
    super.initState();
    // Defer heavy operations until after first frame to prevent jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBook();
    });

    _docxSearchController = DocxSearchController();
    _docxSearchController.addListener(_onSearchChanged);

    // Add scroll listener for text based books
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_isTextBased || _textContent == null || _totalPages == 0) return;

    // Calculate page based on scroll percentage
    // This is rough approximation logic
    if (_scrollController.hasClients) {
      final double progress =
          _scrollController.position.pixels /
          _scrollController.position.maxScrollExtent;
      final int newPage = (progress * _totalPages).ceil().clamp(1, _totalPages);

      if (newPage != _currentPageNumber) {
        setState(() {
          _currentPageNumber = newPage;
        });
        _updateBookProgress(newPage);
      }
    }
  }

  Future<void> _initializeBook() async {
    try {
      final filePath = widget.book.pdfUrl ?? "";
      if (filePath.isEmpty) {
        _showErrorDialog(
          'No File Path',
          'No file path was specified for this book.',
        );
        return;
      }

      // Check existence
      bool fileExists = false;
      try {
        await Future.microtask(() async {
          final file = File(filePath);
          fileExists = await file.exists();
        });
      } catch (e) {
        log('Error checking file existence: $e');
      }

      log('File path: $filePath');
      log('File exists: $fileExists');

      if (!fileExists) {
        _showErrorDialog(
          'File Not Found',
          'The book file could not be found. It may have been deleted or moved.',
          icon: Icons.file_download_outlined,
        );
        return;
      }

      log('Opening book document...');

      // Yield to UI thread
      await Future.microtask(() {});

      // Initialize based on type
      if (_isPdf) {
        await _initializePdf(filePath);
      } else if (_isDocx) {
        await _initializeDocx(filePath);
      } else {
        await _initializeText(filePath);
      }
    } catch (e, stackTrace) {
      log('Error loading Book: $e');
      _handleLoadError(e);
    }
  }

  Future<void> _initializeDocx(String filePath) async {
    _commonInitialization();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializePdf(String filePath) async {
    // Initialize pdfrx controller
    _pdfController = PdfViewerController();
    _controllerInitialized = true;

    _commonInitialization();

    // Wait for PDF to load, then get page count and jump to saved page
    // ... (Rest of PDF loading logic kept almost same, simplified for brevity)
    // We'll rely on pdfrx onViewerReady or similar if possible, but keeping existing delay logic for minimal regression

    setState(() {
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted || _pdfController == null) return;
      try {
        // ... (existing poll logic)
        int attempts = 0;
        while (attempts < 10 && mounted) {
          final pageCount = _pdfController?.pageCount;
          if (pageCount != null && pageCount > 0) {
            _handleTotalPagesUpdated(pageCount);

            // Jump to page
            if (_currentPageNumber > 1 && _currentPageNumber <= _totalPages) {
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted && _pdfController != null) {
                await _pdfController!.goToPage(
                  pageNumber: _currentPageNumber - 1,
                );
              }
            }
            break;
          }
          attempts++;
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        log('Error getting page count: $e');
      }
    });
  }

  Future<void> _initializeText(String filePath) async {
    try {
      final file = File(filePath);
      String text = await file.readAsString();

      _textContent = text;

      // Calculate total pages
      final calculatedPages = (text.length / _charsPerPage).ceil();
      _handleTotalPagesUpdated(calculatedPages > 0 ? calculatedPages : 1);

      _commonInitialization();

      setState(() {
        _isLoading = false;
      });

      // Restore position (scroll)
      if (_currentPageNumber > 1 && _totalPages > 0) {
        // Wait for frame to allow text to render so maxScrollExtent is available
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Give a bit more time for layout
          await Future.delayed(const Duration(milliseconds: 100));
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            final targetScroll =
                (maxScroll / _totalPages) * (_currentPageNumber - 1);
            _scrollController.jumpTo(targetScroll);
          }
        });
      }
    } catch (e) {
      log('Error reading text file: $e');
      _handleLoadError(e);
    }
  }

  void _commonInitialization() {
    // Use book's totalPages if available first
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 0;

    // Set initial page number
    _currentPageNumber = widget.book.currentPage > 0
        ? widget.book.currentPage
        : 1;

    // Initialize last tracked page
    _lastTrackedPage = _currentPageNumber;

    // Send notification
    Future.microtask(() async {
      await _notificationService.sendFirstDocumentOpenedNotification(
        widget.book.title,
      );
    });
  }

  void _handleTotalPagesUpdated(int pageCount) {
    if (_totalPages != pageCount) {
      setState(() {
        _totalPages = pageCount;
      });

      // Update book with total pages if it was missing
      if (widget.book.totalPages == 0) {
        final updatedBook = widget.book.copyWith(totalPages: pageCount);
        ref.read(booksProvider.notifier).updateBook(updatedBook);
      }
    }
  }

  Future<void> _showErrorDialog(
    String title,
    String message, {
    IconData icon = Icons.error_outline,
  }) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      icon: icon,
      actions: [
        DialogAction(
          label: 'Close',
          onPressed: () => navigator.pop(),
          style: DialogActionStyle.primary,
        ),
      ],
    );
    if (mounted) {
      navigator.pop();
    }
  }

  void _handleLoadError(dynamic e) {
    // ... Reuse existing error mapping logic
    String title = 'Unable to Load Book';
    String message = 'There was an error loading the document.';
    IconData icon = Icons.error_outline;

    if (e.toString().contains('FileNotFoundException') ||
        e.toString().contains('No such file') ||
        e.toString().contains('File not found')) {
      title = 'File Not Found';
      message =
          'The book file could not be found. It may have been deleted or moved.';
      icon = Icons.file_download_outlined;
    } else if (e.toString().contains('Permission denied')) {
      title = 'Access Error';
      message = 'Unable to access the book file.';
      icon = Icons.lock_outline;
    }

    _showErrorDialog(title, message, icon: icon);
  }

  Future<void> _updateBookProgress(int page) async {
    // ... Existing update logic
    final totalPages = _totalPages > 0
        ? _totalPages
        : (widget.book.totalPages > 0 ? widget.book.totalPages : 1);

    if (page <= 0 || totalPages <= 0) return;

    final progress = ((page / totalPages) * 100).round();
    final previousProgress = widget.book.progress;

    final updatedBook = widget.book.copyWith(
      currentPage: page,
      progress: progress,
      totalPages: totalPages,
    );

    await ref.read(booksProvider.notifier).updateBook(updatedBook);

    final now = DateTime.now();
    final pagesRead = page > _lastTrackedPage ? (page - _lastTrackedPage) : 0;

    if (pagesRead > 0) {
      _lastTrackedPage = page;

      await ref
          .read(readingActivitiesProvider.notifier)
          .updateDailyActivity(now, pagesRead, 0, widget.book.id);

      final streakService = ref.read(streakServiceProvider);
      await streakService.updateStreak(now);

      _updateLeaderboard(ref);

      final homeWidgetService = ref.read(homeWidgetServiceProvider);
      await homeWidgetService.initialize();
      final enabled = await homeWidgetService.isEnabled();
      if (enabled) {
        final streak = await streakService.getCurrentStreak();
        final booksReading = ref.read(readingBooksProvider);
        final currentlyReading = booksReading.isNotEmpty
            ? booksReading.first
            : null;
        await homeWidgetService.updateWidgetData(
          currentlyReading: currentlyReading,
          dailyStreak: streak,
        );
      }
    }

    if (progress >= 100 && previousProgress < 100) {
      await _notificationService.sendBookCompletedNotification(
        widget.book.title,
      );
    } else if (progress >= 50 && previousProgress < 50) {
      await _notificationService.sendHalfwayMilestoneNotification(
        widget.book.title,
      );
    }
  }

  // ... _updateLeaderboard kept same ...
  Future<void> _updateLeaderboard(WidgetRef ref) async {
    try {
      final user = ref.read(userProvider);
      if (user == null || user.email.isEmpty) return;

      final activities = ref.read(readingActivitiesProvider).valueOrNull;
      if (activities == null || activities.isEmpty) return;

      int totalPages = 0;
      final Set<String> uniqueBookIds = {};
      for (var activity in activities) {
        totalPages += activity.pagesRead;
        final ids = activity.bookIds;
        for (var id in ids) uniqueBookIds.add(id);
      }
      final points = ((totalPages / 5) * 2).round();

      final name = (user.nickname != null && user.nickname!.isNotEmpty)
          ? user.nickname!
          : (user.email.isNotEmpty ? user.email : 'Reader');

      await ref
          .read(leaderboardServiceProvider)
          .updateFromReadingActivities(
            activities: activities,
            name: name,
            email: user.email,
          );
    } catch (e) {
      log('Error updating leaderboard: $e');
    }
  }

  Future<void> _showSaveSnippetDialog() async {
    // ... Keeping same ...
    final textController = TextEditingController();
    final noteController = TextEditingController();

    // Using simple dialog logic
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Text to save'),
                maxLines: 4,
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && textController.text.isNotEmpty) {
      await _saveSnippet(textController.text, noteController.text);
    }
  }

  Future<void> _saveSnippet(String text, String? note) async {
    // ... Saving snippet logic is Book agnostic, so keep same
    try {
      final snippetId = DateTime.now().millisecondsSinceEpoch.toString();
      final snippet = ReadingSnippet(
        id: snippetId,
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        text: text,
        pageNumber: _currentPageNumber,
        dateSaved: DateTime.now().toIso8601String(),
        note: note,
      );
      final success = await ref
          .read(snippetsProvider.notifier)
          .addSnippet(snippet);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Snippet saved' : 'Failed')),
        );
      }
    } catch (e) {
      log('Error saving snippet: $e');
    }
  }

  Future<void> _handlePrevPage() async {
    if (_isLoading) return;
    if (_isPdf) {
      // ... existing PDF prev page
      if (_pdfController != null && _currentPageNumber > 1) {
        await _pdfController!.goToPage(pageNumber: _currentPageNumber - 2);
      }
    } else {
      // Text/Docx prev page approx (scroll up one 'page')
      if (_scrollController.hasClients) {
        final double pageHeight =
            _scrollController.position.maxScrollExtent / _totalPages;
        final double target = (_currentPageNumber - 2) * pageHeight;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _handleNextPage() async {
    if (_isLoading) return;
    if (_isPdf) {
      // ... existing PDF next page
      if (_pdfController != null && _currentPageNumber < _totalPages) {
        await _pdfController!.goToPage(pageNumber: _currentPageNumber);
      }
    } else {
      // Text/Docx next page approx
      if (_scrollController.hasClients && _currentPageNumber < _totalPages) {
        final double pageHeight =
            _scrollController.position.maxScrollExtent / _totalPages;
        final double target = (_currentPageNumber) * pageHeight;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showControls = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // Restore system UI on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _pdfController = null;
    _docxSearchController.removeListener(_onSearchChanged);
    _docxSearchController.dispose();
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  int get _currentPage => _currentPageNumber;
  int get _progress =>
      _totalPages > 0 ? ((_currentPageNumber / _totalPages) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: Color.lerp(Colors.white, Colors.black, 1.0 - _brightness),
        child: Stack(
          children: [
            // Viewer Area
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: _isPdf
                    ? Colors.grey[50]
                    : Colors.white, // White background for text
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContentView(),
              ),
            ),

            // Top Controls (Header)
            if (_showControls)
              Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            // Bottom Controls
            if (_showControls)
              Positioned(bottom: 0, left: 0, right: 0, child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    if (_isPdf && _pdfController != null) {
      return PdfViewer.file(
        widget.book.pdfUrl ?? '',
        controller: _pdfController!,
      );
    } else if (_isDocx) {
      return DocxView(
        path: widget.book.pdfUrl ?? '',
        config: DocxViewConfig(enableSearch: true, enableZoom: true),
        searchController: _docxSearchController,
      );
    } else if (_isTextBased && _textContent != null) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          20,
          _showControls ? 120 : 60,
          20,
          _showControls ? 100 : 60,
        ),
        child: Text(
          _textContent!,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      );
    }
    return const Text('Failed to load content');
  }

  Widget _buildHeader() {
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: _showSaveSnippetDialog,
                      ),
                      if (_isDocx)
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              _isSearchActive = !_isSearchActive;
                              if (!_isSearchActive) {
                                _docxSearchController.clear();
                                _searchTextController.clear();
                              }
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Book Title (or Search Bar)
              if (_isSearchActive && _isDocx)
                _buildSearchBar()
              else ...[
                Text(
                  widget.book.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.book.author,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress / 100,
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
                  Text('Page $_currentPage of $_totalPages'),
                  Text('$_progress%'),
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
            controller: _searchTextController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search text...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onSubmitted: (value) => _docxSearchController.search(value),
            onChanged: (value) => _docxSearchController.search(value),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (_docxSearchController.matchCount > 0)
          Text(
            '${_docxSearchController.currentMatchIndex + 1}/${_docxSearchController.matchCount}',
            style: const TextStyle(fontSize: 14),
          ),
        IconButton(
          icon: const Icon(Icons.expand_less),
          onPressed: _docxSearchController.previousMatch,
          tooltip: 'Previous',
        ),
        IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: _docxSearchController.nextMatch,
          tooltip: 'Next',
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: (!_isLoading && _currentPage > 1)
                    ? _handlePrevPage
                    : null,
              ),
              Expanded(
                child: _totalPages > 0
                    ? Slider(
                        value: _currentPageNumber
                            .clamp(1, _totalPages)
                            .toDouble(),
                        min: 1,
                        max: _totalPages.toDouble(),
                        divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                        onChanged: (val) {
                          final page = val.round();
                          if (_isPdf) {
                            _pdfController?.goToPage(pageNumber: page - 1);
                          } else {
                            // Text seeking
                            if (_scrollController.hasClients) {
                              final double max =
                                  _scrollController.position.maxScrollExtent;
                              final double target = (page / _totalPages) * max;
                              _scrollController.jumpTo(target);
                            }
                            setState(() {
                              _currentPageNumber = page;
                            });
                          }
                        },
                      )
                    : const SizedBox(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (!_isLoading && _currentPage < _totalPages)
                    ? _handleNextPage
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
