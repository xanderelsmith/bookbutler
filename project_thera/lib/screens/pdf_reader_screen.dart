import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class PdfReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  PdfViewerController? _pdfController;
  final NotificationService _notificationService = NotificationService();

  bool _showControls = true;
  double _brightness = 1.0;
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPageNumber = 1;
  int _lastTrackedPage = 0; // Track last page that triggered progress update
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer heavy operations until after first frame to prevent jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePdf();
    });
  }

  Future<void> _initializePdf() async {
    try {
      final filePath = widget.book.pdfUrl ?? "";
      if (filePath.isEmpty) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await ErrorDialog.show(
          context: context,
          title: 'No File Path',
          message: 'No file path was specified for this book.',
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
        return;
      }

      // Check if file exists asynchronously to avoid blocking
      // Files in internal storage don't require permissions
      bool fileExists = false;
      try {
        // Use Future.microtask to yield to UI thread before file check
        await Future.microtask(() async {
          final file = File(filePath);
          fileExists = await file.exists();
        });
      } catch (e) {
        log('Error checking file existence: $e');
        fileExists = false;
      }

      log('File path: $filePath');
      log('File exists: $fileExists');

      if (!fileExists) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await ErrorDialog.show(
          context: context,
          title: 'File Not Found',
          message:
              'The book file could not be found. It may have been deleted or moved. Please try adding the book again.',
          fileName: filePath.split('/').last,
          icon: Icons.file_download_outlined,
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
        return;
      }

      log('Opening PDF document from internal storage...');
      log('📄 File path: $filePath');

      // Yield to UI thread before heavy PDF loading operation
      await Future.microtask(() {});

      // Initialize pdfrx controller
      _pdfController = PdfViewerController();
      _controllerInitialized = true;

      // Use book's totalPages if available, otherwise will be updated when PDF loads
      _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 0;

      // Set initial page number before loading
      _currentPageNumber = widget.book.currentPage > 0
          ? widget.book.currentPage
          : 1;

      // Initialize last tracked page to current page
      _lastTrackedPage = _currentPageNumber;

      log(
        '📑 Initial page number: $_currentPageNumber (book.currentPage: ${widget.book.currentPage})',
      );
      log(
        '📊 Initial total pages: $_totalPages (book.totalPages: ${widget.book.totalPages})',
      );

      // Defer notification to avoid blocking UI update
      Future.microtask(() async {
        await _notificationService.sendFirstDocumentOpenedNotification(
          widget.book.title,
        );
      });

      log('✅ PDF controller initialized');

      // Set loading to false after initialization
      setState(() {
        _isLoading = false;
      });

      // Wait for PDF to load, then get page count and jump to saved page
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted || _pdfController == null) return;

        try {
          // Try to get page count - may need multiple attempts
          int attempts = 0;
          while (attempts < 10 && mounted) {
            try {
              final pageCount = _pdfController?.pageCount;
              if (pageCount != null && pageCount > 0) {
                if (_totalPages != pageCount) {
                  setState(() {
                    _totalPages = pageCount;
                  });

                  // Update book with total pages if it was missing
                  if (widget.book.totalPages == 0) {
                    final updatedBook = widget.book.copyWith(
                      totalPages: pageCount,
                    );
                    await ref
                        .read(booksProvider.notifier)
                        .updateBook(updatedBook);
                  }

                  log('✅ PDF document loaded - Total pages: $_totalPages');

                  // Jump to saved page if needed
                  if (_currentPageNumber > 1 &&
                      _currentPageNumber <= _totalPages) {
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted && _pdfController != null) {
                      try {
                        await _pdfController!.goToPage(
                          pageNumber: _currentPageNumber - 1,
                        );
                        log(
                          '✅ Successfully jumped to page $_currentPageNumber',
                        );
                      } catch (e) {
                        log('❌ Error jumping to page: $e');
                      }
                    }
                  }
                }
                break; // Success, exit loop
              }
            } catch (e) {
              // pageCount not ready yet, continue trying
            }

            attempts++;
            if (attempts < 10) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        } catch (e) {
          log('Error getting page count: $e');
        }
      });
    } catch (e, stackTrace) {
      log('Error loading PDF: $e');
      log('Stack trace: $stackTrace');
      if (mounted) {
        final filePath = widget.book.pdfUrl ?? '';
        final fileName = filePath.split('/').last;

        String title = 'Unable to Load PDF';
        String message = 'There was an error loading the PDF document.';
        IconData icon = Icons.error_outline;
        List<DialogAction> actions = [];

        // Determine error type and customize message
        if (e.toString().contains('FileNotFoundException') ||
            e.toString().contains('No such file') ||
            e.toString().contains('File not found')) {
          title = 'File Not Found';
          message =
              'The book file could not be found. It may have been deleted or moved. Please try adding the book again from the Add Book screen.';
          icon = Icons.file_download_outlined;
        } else if (e.toString().contains('Permission denied') ||
            e.toString().contains('EACCES') ||
            e.toString().contains('Access denied')) {
          title = 'Access Error';
          message =
              'Unable to access the book file. This is unusual for files in internal storage. Please try adding the book again.';
          icon = Icons.lock_outline;
        } else {
          message =
              'An unexpected error occurred while loading the PDF.\n\n${e.toString()}';
        }

        // Default actions if not set
        if (actions.isEmpty) {
          actions = [
            DialogAction(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              style: DialogActionStyle.primary,
            ),
          ];
        }

        // Show error dialog
        await ErrorDialog.show(
          context: context,
          title: title,
          message: message,
          fileName: fileName.isNotEmpty && fileName != filePath
              ? fileName
              : null,
          actions: actions,
          icon: icon,
        );

        // Pop the PDF reader screen
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _updateBookProgress(int page) async {
    // Use totalPages from _totalPages or fall back to book's totalPages
    final totalPages = _totalPages > 0
        ? _totalPages
        : (widget.book.totalPages > 0 ? widget.book.totalPages : 1);

    if (page <= 0 || totalPages <= 0) return;

    final progress = ((page / totalPages) * 100).round();
    final previousProgress = widget.book.progress;

    // Update book progress using Riverpod
    final updatedBook = widget.book.copyWith(
      currentPage: page,
      progress: progress,
      totalPages: _totalPages > 0 ? _totalPages : widget.book.totalPages,
    );

    await ref.read(booksProvider.notifier).updateBook(updatedBook);

    // Track reading activity and update streak (only track incremental pages)
    final now = DateTime.now();
    final pagesRead = page > _lastTrackedPage ? (page - _lastTrackedPage) : 0;

    if (pagesRead > 0) {
      _lastTrackedPage = page; // Update last tracked page

      await ref
          .read(readingActivitiesProvider.notifier)
          .updateDailyActivity(
            now,
            pagesRead,
            0, // TODO: Calculate actual minutes spent
            widget.book.id,
          );

      // Update streak when reading activity is recorded
      final streakService = ref.read(streakServiceProvider);
      await streakService.updateStreak(now);

      // Update leaderboard entry
      _updateLeaderboard(ref);

      // Update home widget with latest data
      final homeWidgetService = ref.read(homeWidgetServiceProvider);
      await homeWidgetService.initialize();
      final enabled = await homeWidgetService.isEnabled();
      if (enabled) {
        final streak = await streakService.getCurrentStreak();
        // Get currently reading book (similar to how want to read is saved)
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

    // Send milestone notifications (check against previous progress)
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

  /// Updates the leaderboard entry based on current reading activities
  Future<void> _updateLeaderboard(WidgetRef ref) async {
    log('📊 [Leaderboard] Starting leaderboard update flow');
    try {
      // Check if user is signed in
      log('📊 [Leaderboard] Step 1: Checking if user is signed in...');
      final user = ref.read(userProvider);

      if (user == null) {
        log('📊 [Leaderboard] User not signed in, aborting leaderboard update');
        return;
      }

      if (user.email.isEmpty) {
        log(
          '📊 [Leaderboard] User email is empty, aborting leaderboard update',
        );
        return;
      }
      // Get reading activities
      log('📊 [Leaderboard] Step 2: Getting reading activities...');
      final activitiesAsync = ref.read(readingActivitiesProvider);
      final activities = activitiesAsync.valueOrNull;
      log(
        '📊 [Leaderboard] Step 2 result: activities state = ${activitiesAsync.runtimeType}, activities count = ${activities?.length ?? 0}',
      );
      if (activities == null || activities.isEmpty) {
        log(
          '📊 [Leaderboard] No activities found, aborting leaderboard update',
        );
        return;
      }

      // Calculate stats from activities
      int totalPages = 0;
      final Set<String> uniqueBookIds = {};
      for (var activity in activities) {
        totalPages += activity.pagesRead;
        for (var bookId in activity.bookIds) {
          uniqueBookIds.add(bookId);
        }
      }
      final points = ((totalPages / 5) * 2).round();
      final booksCount = uniqueBookIds.length;
      log(
        '📊 [Leaderboard] Step 2.5: Calculated stats - pages: $totalPages, books: $booksCount, points: $points',
      );

      // Get user profile info
      log('📊 [Leaderboard] Step 3: Getting user profile info...');

      // Determine name to use (nickname, or email, or "Reader" as fallback)
      // user is guaranteed to be non-null at this point due to earlier check
      final name = (user.nickname != null && user.nickname!.isNotEmpty)
          ? user.nickname!
          : (user.email.isNotEmpty ? user.email : 'Reader');
      final email = user.email;

      log('📊 [Leaderboard] Step 4: Determined name="$name", email="$email"');

      // Update leaderboard
      log(
        '📊 [Leaderboard] Step 5: Calling updateFromReadingActivities with name="$name", email="$email", pages=$totalPages, books=$booksCount, points=$points',
      );
      final leaderboardService = ref.read(leaderboardServiceProvider);
      final result = await leaderboardService.updateFromReadingActivities(
        activities: activities,
        name: name,
        email: email,
      );
      log(
        '📊 [Leaderboard] Step 5 result: Leaderboard update ${result != null ? "successful" : "failed"}',
      );
      if (result != null) {
        log(
          '📊 [Leaderboard] ✅ Leaderboard update completed successfully - Entry ID: ${result.id}, Points: ${result.points}, Pages: ${result.pages}, Books: ${result.books}',
        );
      } else {
        log('📊 [Leaderboard] ❌ Leaderboard update returned null');
      }
    } catch (e, stackTrace) {
      log('📊 [Leaderboard] ❌ Error updating leaderboard: $e');
      log('📊 [Leaderboard] Stack trace: $stackTrace');
    }
  }

  Future<void> _showSaveSnippetDialog() async {
    final textController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text to save',
                  hintText: 'Enter or paste text from the book...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                minLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a personal note...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Page: $_currentPageNumber',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && textController.text.trim().isNotEmpty && mounted) {
      await _saveSnippet(
        textController.text.trim(),
        noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
    }
  }

  Future<void> _saveSnippet(String text, String? note) async {
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
          SnackBar(
            content: Text(
              success
                  ? 'Snippet saved successfully!'
                  : 'Failed to save snippet',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('Error saving snippet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving snippet: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handlePrevPage() async {
    if (!_controllerInitialized ||
        _isLoading ||
        _currentPageNumber <= 1 ||
        _pdfController == null) {
      return;
    }

    final newPage = _currentPageNumber - 1;
    try {
      await _pdfController!.goToPage(
        pageNumber: newPage - 1,
      ); // pdfrx uses 0-based indexing
      if (mounted) {
        setState(() {
          _currentPageNumber = newPage;
        });
        await _updateBookProgress(newPage);
      }
    } catch (e) {
      log('Error going to previous page: $e');
    }
  }

  Future<void> _handleNextPage() async {
    if (!_controllerInitialized || _isLoading || _pdfController == null) {
      return;
    }

    // Check against totalPages or book's totalPages
    final totalPages = _totalPages > 0 ? _totalPages : widget.book.totalPages;
    if (totalPages > 0 && _currentPageNumber >= totalPages) {
      return;
    }

    final newPage = _currentPageNumber + 1;
    try {
      await _pdfController!.goToPage(
        pageNumber: newPage - 1,
      ); // pdfrx uses 0-based indexing
      if (mounted) {
        setState(() {
          _currentPageNumber = newPage;
        });
        await _updateBookProgress(newPage);
      }
    } catch (e) {
      log('Error going to next page: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  void dispose() {
    // pdfrx controller doesn't require explicit disposal
    _pdfController = null;
    super.dispose();
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
            // PDF Viewer
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.grey[50],
                child: Center(
                  child:
                      _isLoading ||
                          !_controllerInitialized ||
                          _pdfController == null
                      ? const CircularProgressIndicator()
                      : PdfViewer.file(
                          widget.book.pdfUrl ?? '',
                          controller: _pdfController!,
                        ),
                ),
              ),
            ),

            // Top Controls (Header)
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
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
                                    onPressed: () => _showSaveSnippetDialog(),
                                    tooltip: 'Save Snippet',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings_outlined),
                                    onPressed: () {
                                      // TODO: Settings menu
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Book Title and Author
                          Column(
                            children: [
                              Text(
                                widget.book.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.book.author,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Progress Bar
                          LinearProgressIndicator(
                            value: _progress / 100,
                            minHeight: 2,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Page Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Page $_currentPage of $_totalPages',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              Text(
                                '$_progress%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Page Navigation
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed:
                                    (!_isLoading && _currentPageNumber > 1)
                                    ? _handlePrevPage
                                    : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                              Expanded(
                                child: _totalPages > 0
                                    ? Slider(
                                        value: _currentPageNumber
                                            .clamp(1, _totalPages)
                                            .toDouble(),
                                        min: 1,
                                        max: _totalPages.toDouble(),
                                        divisions: _totalPages > 1
                                            ? _totalPages - 1
                                            : 1,
                                        onChanged: (value) async {
                                          if (!_controllerInitialized ||
                                              _isLoading ||
                                              _pdfController == null) {
                                            return;
                                          }

                                          final page = value.round().clamp(
                                            1,
                                            _totalPages,
                                          );
                                          if (page != _currentPageNumber) {
                                            try {
                                              await _pdfController!.goToPage(
                                                pageNumber:
                                                    page -
                                                    1, // pdfrx uses 0-based indexing
                                              );
                                              setState(() {
                                                _currentPageNumber = page;
                                              });
                                              await _updateBookProgress(page);
                                            } catch (e) {
                                              log('Error going to page: $e');
                                            }
                                          }
                                        },
                                      )
                                    : const SizedBox(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed:
                                    (!_isLoading &&
                                        _currentPageNumber < _totalPages &&
                                        _totalPages > 0)
                                    ? _handleNextPage
                                    : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Font Size Control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.text_decrease,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 150,
                                child: Slider(
                                  value: _brightness,
                                  min: 0.5,
                                  max: 1.0,
                                  divisions: 10,
                                  label: '${(_brightness * 100).round()}%',
                                  onChanged: (value) {
                                    setState(() {
                                      _brightness = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.text_increase,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
