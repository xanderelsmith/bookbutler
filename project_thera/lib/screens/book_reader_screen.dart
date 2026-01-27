import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:project_thera/screens/notes_list_screen.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../models/book.dart';
import '../models/reading_snippet.dart';
import '../providers/book_providers.dart';
import '../providers/snippet_providers.dart';
import '../providers/reading_activity_providers.dart';
import '../providers/streak_provider.dart';
import '../providers/home_widget_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/user_provider.dart';
import '../providers/serverpod_provider.dart';
import '../services/notification_service.dart';
import '../services/secure_cache_service.dart';
import '../services/storage_access_service.dart';
import '../theme/app_theme.dart';
import '../screens/ai_chat_screen.dart';
import '../widgets/error_dialog.dart';
import '../widgets/reader/reader_footer.dart';
import '../widgets/reader/reader_header.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  // PDF specific
  late PdfViewerController _pdfController;
  bool hasSentHalwaynotification = false;

  // Track if we've sent the "reading started" notification for this book
  bool hasSentReadingStartedNotification = false;

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
  final double _brightness = 1.0;
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPageNumber = 1;
  int _lastTrackedPage = 0; // Track last page that triggered progress update

  // File type detection
  bool get _isPdf =>
      widget.book.pdfUrl?.toLowerCase().endsWith('.pdf') ?? false;
  bool get _isDocx =>
      widget.book.pdfUrl?.toLowerCase().endsWith('.docx') ?? false;
  bool get _isTextBased => !_isPdf && !_isDocx; // Text only

  @override
  void initState() {
    // Initialize pdfrx controller
    _pdfController = PdfViewerController()
      ..addListener(() {
        _currentPageNumber = _pdfController.pageNumber ?? 0;
      });
    super.initState();

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

    if (_scrollController.hasClients) {
      final double maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final double progress = _scrollController.position.pixels / maxScroll;
      // Map 0.0-1.0 to 1-totalPages
      final int newPage = (progress * (_totalPages - 1)).round() + 1;
      final int clampedPage = newPage.clamp(1, _totalPages);

      if (clampedPage != _currentPageNumber) {
        setState(() {
          _currentPageNumber = clampedPage;
        });
        // Consider throttling this update
        _updateBookProgress(clampedPage);
      }
    }
  }

  Future<void> _initializeBook() async {
    try {
      String filePath = widget.book.pdfUrl ?? "";
      if (filePath.isEmpty) {
        _showErrorDialog(
          'No File Path',
          'No file path was specified for this book.',
        );
        return;
      }

      // Handle content URIs (SAF)
      if (filePath.startsWith('content://')) {
        log('Content URI detected, copying to local storage...');
        try {
          final safService = StorageAccessService();
          final result = await safService.copyContentUriToFile(
            contentUri: filePath,
            bookId: widget.book.id,
            originalFileName: widget.book.title,
          );

          if (result != null && result['path'] != null) {
            filePath = result['path']!;
            log('Content URI resolved to: $filePath');
          } else {
            log('Failed to resolve content URI');
          }
        } catch (e) {
          log('Error resolving content URI: $e');
          _showErrorDialog(
            'File Access Error',
            'Could not access the file from external storage. Please try importing it again.',
            icon: Icons.lock_outline,
          );
          return;
        }
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
      }
      // else if (_isDocx) {
      //   await _initializeDocx(filePath);
      // } else {
      //   await _initializeText(filePath);
      // }
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
    _commonInitialization();

    setState(() {
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        // ... (existing poll logic)
        int attempts = 0;
        while (attempts < 10 && mounted) {
          final pageCount = _pdfController.pageCount;
          if (pageCount > 0) {
            _handleTotalPagesUpdated(pageCount);

            // Jump to page
            if (_currentPageNumber > 1 && _currentPageNumber <= _totalPages) {
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                try {
                  await _pdfController.goToPage(
                    pageNumber: _currentPageNumber - 1,
                  );
                } catch (e) {
                  log('Error restoring PDF page: $e');
                }
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

      // Send "reading started" notification to all users (once per book)
      await _sendReadingStartedNotification();

      // Ensure status is updated to reading if it was wantToRead
      if (widget.book.status == BookStatus.wantToRead) {
        await _updateBookProgress(_currentPageNumber);
      }
    });
  }

  /// Send reading started notification to all users (once per book)
  Future<void> _sendReadingStartedNotification() async {
    try {
      // Check if we've already sent notification for this book
      final cacheKey = 'reading_started_${widget.book.id}';
      final cacheService = SecureCacheService();
      final alreadySent = await cacheService.getCachedBookMetadata(cacheKey);

      if (alreadySent != null || hasSentReadingStartedNotification) {
        return; // Already sent, don't spam
      }

      // Get serverpod client and call endpoint
      final client = ref.read(serverpodServiceProvider).client;
      try {
        await client.notification.sendReadingStartedNotification(
          widget.book.title,
        );

        // Mark as sent
        hasSentReadingStartedNotification = true;
        await cacheService.cacheBookMetadata(cacheKey, {
          'sent': true,
          'sentAt': DateTime.now().toIso8601String(),
        });

        log('📚 Reading started notification sent for: ${widget.book.title}');
      } catch (e) {
        log('Error sending reading started notification: $e');
        // Fail silently, non-critical feature
      }
    } catch (e) {
      log('Error in _sendReadingStartedNotification: $e');
    }
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

    // Auto-update status
    BookStatus newStatus = widget.book.status;
    String? dateStarted = widget.book.dateStarted;
    String? dateCompleted = widget.book.dateCompleted;

    if (progress >= 100) {
      newStatus = BookStatus.completed;
      dateCompleted ??= DateTime.now().toIso8601String();
    } else if (widget.book.status == BookStatus.wantToRead) {
      newStatus = BookStatus.reading;
      dateStarted ??= DateTime.now().toIso8601String();
    }

    final updatedBook = widget.book.copyWith(
      currentPage: page,
      progress: progress,
      totalPages: totalPages,
      status: newStatus,
      dateStarted: dateStarted,
      dateCompleted: dateCompleted,
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
      log('streak updated');
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
      if (hasSentHalwaynotification == false) {
        await _notificationService.sendHalfwayMilestoneNotification(
          widget.book.title,
        );
      }
      hasSentHalwaynotification = true;
    }
  }

  // ... _updateLeaderboard kept same ...
  Future<void> _updateLeaderboard(WidgetRef ref) async {
    try {
      final user = ref.read(userProvider);
      if (user == null || user.email.isEmpty) {
        log(
          '📊 [Leaderboard] _updateLeaderboard aborting: user is null or email is empty',
        );
        return;
      }

      final activities = ref.read(readingActivitiesProvider).valueOrNull;
      if (activities == null || activities.isEmpty) {
        log(
          '📊 [Leaderboard] _updateLeaderboard aborting: activities are null or empty',
        );
        return;
      }

      int totalPages = 0;
      final Set<String> uniqueBookIds = {};
      for (var activity in activities) {
        totalPages += activity.pagesRead;
        final ids = activity.bookIds;
        for (var id in ids) {
          uniqueBookIds.add(id);
        }
      }
      final points = ((totalPages / 5) * 2).round();

      log(
        '📊 [Leaderboard] Calculated points: $points for $totalPages total pages and ${uniqueBookIds.length} books',
      );

      final name = (user.nickname != null && user.nickname!.isNotEmpty)
          ? user.nickname!
          : (user.email.isNotEmpty ? user.email : 'Reader');

      log(
        '📊 [Leaderboard] Calling updateFromReadingActivities for ${user.email}',
      );
      await ref
          .read(leaderboardServiceProvider)
          .updateFromReadingActivities(
            activities: activities,
            name: name,
            email: user.email,
          );
      log('📊 [Leaderboard] Successfully called updateFromReadingActivities');
    } catch (e) {
      log('Error updating leaderboard: $e');
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

  Future<void> _handlePrevPage(int val) async {
    if (_isLoading) return;
    if (_isPdf) {
      await _pdfController.goToPage(pageNumber: val);
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

  Future<void> _handleNextPage(int val) async {
    log(_isPdf.toString());
    if (_isLoading) return;
    if (_isPdf) {
      // ... existing PDF next page
      // if (_currentPageNumber < _totalPages) {
      // try {
      _pdfController.goToPage(pageNumber: val);
      // } catch (e) {
      //   log('Error going to next PDF page: $e');
      // }
      // }
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

  @override
  void dispose() {
    // _pdfController.;
    _docxSearchController.removeListener(_onSearchChanged);
    _docxSearchController.dispose();
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  int get _progress =>
      _totalPages > 0 ? ((_currentPageNumber / _totalPages) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: Color.lerp(
          Colors.white,
          const Color.fromRGBO(0, 0, 0, 1),
          1.0 - _brightness,
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showControls)
                ReaderHeader(
                  book: widget.book,
                  currentPage: _currentPageNumber,
                  totalPages: _totalPages,
                  progress: _progress,
                  isDocx: _isDocx,
                  isSearchActive: _isSearchActive,
                  searchTextController: _searchTextController,
                  docxSearchController: _docxSearchController,
                  onClose: () => Navigator.pop(context),
                  onSaveSnippet: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesListScreen(
                          bookId: widget.book.id,
                          bookTitle: widget.book.title,
                        ),
                      ),
                    );
                  },
                  onToggleSearch: () {
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      if (!_isSearchActive) {
                        _docxSearchController.clear();
                        _searchTextController.clear();
                      }
                    });
                  },
                  onAskAi: _showAiDialog,
                  onSettings: () {},
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    log('Tapped');
                    _toggleControls();
                  },
                  behavior: HitTestBehavior
                      .translucent, // ensure taps are caught even on empty space
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: _isPdf
                        ? Colors.grey[50]
                        : Colors.white, // White background for text
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Builder(
                            builder: (context) {
                              if (_isPdf) {
                                return PdfViewer.file(
                                  widget.book.pdfUrl ?? '',
                                  controller: _pdfController,
                                  params: PdfViewerParams(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    onPageChanged: (page) {
                                      if (page != null &&
                                          page != _currentPageNumber) {
                                        if (mounted) {
                                          setState(() {
                                            _currentPageNumber = page;
                                          });
                                          _updateBookProgress(page);
                                        }
                                      }
                                    },
                                    customizeContextMenuItems: (params, items) {
                                      items.addAll([
                                        ContextMenuButtonItem(
                                          label: 'Save Snippet',
                                          onPressed: () {
                                            params.dismissContextMenu();
                                            params.textSelectionDelegate
                                                .getSelectedText()
                                                .then((text) {
                                                  if (text.isNotEmpty) {
                                                    _saveSnippet(text, null);
                                                  }
                                                });
                                          },
                                        ),
                                        ContextMenuButtonItem(
                                          label: 'Summarize',
                                          onPressed: () {
                                            params.dismissContextMenu();
                                            _onSelectionAiAction(
                                              params
                                                      .textSelectionDelegate
                                                      .hasSelectedText
                                                  ? params.textSelectionDelegate
                                                        .getSelectedText()
                                                        .then((value) => value)
                                                  : Future.value(''),
                                              'Summarize this',
                                            );
                                          },
                                        ),
                                        ContextMenuButtonItem(
                                          label: 'Explain',
                                          onPressed: () {
                                            params.dismissContextMenu();
                                            _onSelectionAiAction(
                                              params.textSelectionDelegate
                                                  .getSelectedText()
                                                  .then((value) => value),
                                              'Explain this',
                                            );
                                          },
                                        ),
                                        ContextMenuButtonItem(
                                          label: 'Ask AI',
                                          onPressed: () {
                                            params.dismissContextMenu();
                                            _onSelectionAiAction(
                                              params.textSelectionDelegate
                                                  .getSelectedText()
                                                  .then((value) => value),
                                              null,
                                            );
                                          },
                                        ),
                                      ]);
                                    },
                                  ),
                                );
                              } else if (_isDocx) {
                                return NotificationListener<ScrollNotification>(
                                  onNotification: (scrollNotification) {
                                    if (scrollNotification
                                            .metrics
                                            .maxScrollExtent >
                                        0) {
                                      // Estimate pages for Docx
                                      // DocxViewer doesn't give us pages, so we estimate based on scroll similar to Text
                                      if (_totalPages == 0) {
                                        // Initial estimation if not set
                                        // 1000px per page approx?
                                        final estimated =
                                            (scrollNotification
                                                        .metrics
                                                        .maxScrollExtent /
                                                    800)
                                                .ceil();
                                        _handleTotalPagesUpdated(
                                          estimated > 0 ? estimated : 1,
                                        );
                                      }

                                      final double progress =
                                          scrollNotification.metrics.pixels /
                                          scrollNotification
                                              .metrics
                                              .maxScrollExtent;
                                      final int newPage =
                                          (progress * _totalPages).ceil().clamp(
                                            1,
                                            _totalPages,
                                          );

                                      if (newPage != _currentPageNumber) {
                                        // Avoid too many setState calls
                                        if (mounted) {
                                          setState(() {
                                            _currentPageNumber = newPage;
                                          });
                                          // Debounce progress update?
                                          _updateBookProgress(newPage);
                                        }
                                      }
                                    }
                                    return false;
                                  },
                                  child: DocxView(
                                    path: widget.book.pdfUrl ?? '',
                                    config: DocxViewConfig(
                                      enableSearch: true,
                                      enableZoom: true,
                                    ),
                                    searchController: _docxSearchController,
                                  ),
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
                                  child: SelectableText(
                                    _textContent!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                    contextMenuBuilder:
                                        (context, editableTextState) {
                                          final List<ContextMenuButtonItem>
                                          buttonItems = editableTextState
                                              .contextMenuButtonItems;
                                          buttonItems.addAll([
                                            ContextMenuButtonItem(
                                              label: 'Summarize',
                                              onPressed: () {
                                                editableTextState.hideToolbar();
                                                final String selectedText =
                                                    _textContent!.substring(
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .start,
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .end,
                                                    );
                                                _onSelectionAiAction(
                                                  selectedText,
                                                  'Summarize this',
                                                );
                                              },
                                            ),
                                            ContextMenuButtonItem(
                                              label: 'Explain',
                                              onPressed: () {
                                                editableTextState.hideToolbar();
                                                final String selectedText =
                                                    _textContent!.substring(
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .start,
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .end,
                                                    );
                                                _onSelectionAiAction(
                                                  selectedText,
                                                  'Explain this',
                                                );
                                              },
                                            ),
                                            ContextMenuButtonItem(
                                              label: 'Ask AI',
                                              onPressed: () {
                                                editableTextState.hideToolbar();
                                                final String selectedText =
                                                    _textContent!.substring(
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .start,
                                                      editableTextState
                                                          .textEditingValue
                                                          .selection
                                                          .end,
                                                    );
                                                _onSelectionAiAction(
                                                  selectedText,
                                                  null,
                                                );
                                              },
                                            ),
                                          ]);
                                          return AdaptiveTextSelectionToolbar.buttonItems(
                                            anchors: editableTextState
                                                .contextMenuAnchors,
                                            buttonItems: buttonItems,
                                          );
                                        },
                                  ),
                                );
                              } else {
                                return const Text('Failed to load content');
                              }
                            },
                          ),
                  ),
                ),
              ),

              if (_showControls)
                ReaderFooter(
                  currentPage: _currentPageNumber,
                  totalPages: _totalPages,
                  isLoading: _isLoading,
                  onPrevPage: _handlePrevPage,
                  onNextPage: _handleNextPage,
                  onPageChanged: (val) {
                    log('_currentPageNumber: $val');
                    setState(() {
                      _currentPageNumber = val;
                    });
                  },
                  onSeekPage: (page) {
                    if (_isPdf) {
                      try {
                        _pdfController.goToPage(pageNumber: page - 1);
                      } catch (e) {
                        log('Error seeking PDF page: $e');
                      }
                    } else if (_isTextBased) {
                      if (_scrollController.hasClients) {
                        final double max =
                            _scrollController.position.maxScrollExtent;
                        final double target =
                            ((page - 1) / (_totalPages - 1)) * max;
                        _scrollController.jumpTo(target);
                      }
                    } else if (_isDocx) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Seeking not fully supported for this format',
                          ),
                        ),
                      );
                    }
                    _updateBookProgress(page);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectionAiAction(
    dynamic selectedTextSource,
    String? initialQuestion,
  ) async {
    String selectedText = '';
    if (selectedTextSource is Future<String>) {
      selectedText = await selectedTextSource;
    } else if (selectedTextSource is String) {
      selectedText = selectedTextSource;
    }

    if (!mounted || selectedText.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          extractedText: selectedText,
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          pageInfo: 'Selected Text',
          initialQuestion: initialQuestion,
          isHighlightedText: true,
        ),
      ),
    );
  }

  Future<void> _showAiDialog() async {
    String extractedText = '';
    if (_isPdf) {
      if (_currentPageNumber > 0) {
        // Use new optimized method
        extractedText = await ReadPdfText.getPDFtextForPage(
          widget.book.pdfUrl ?? '',
          _currentPageNumber,
        );
      }
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          extractedText: extractedText,
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          pageInfo:
              'Page $_currentPageNumber${_totalPages != null ? ' of $_totalPages' : ''}',
          // Enable range slider for PDFs
          bookFilePath: _isPdf ? widget.book.pdfUrl : null,
          currentPage: _currentPageNumber,
          totalPages: _totalPages,
        ),
      ),
    );
  }
}
