import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/book.dart';
import '../services/file_scanner_service.dart';
import '../services/file_manager_service.dart';
import '../services/secure_cache_service.dart';
import '../providers/book_providers.dart';
import '../widgets/scanned_file_card.dart';
import '../theme/app_theme.dart';
import 'book_reader_screen.dart';
import 'dart:developer';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _coverController = TextEditingController();
  final _genreController = TextEditingController();

  final _scannerService = FileScannerService();
  final _fileManager = FileManagerService();
  final _cacheService = SecureCacheService();
  bool _isLoading = false;
  bool _isScanning = false;
  final BookStatus _selectedStatus = BookStatus.wantToRead;
  String? _selectedFilePath;
  List<BookFile> _scannedFiles = [];
  BookFile? _selectedFile;

  bool _hasDirectoryAccess = false;

  @override
  void initState() {
    super.initState();
    _checkDirectoryAccess();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _coverController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _checkDirectoryAccess() async {
    if (Platform.isAndroid) {
      _hasDirectoryAccess = _scannerService.hasDirectoryAccess();
      // On Android, we can search without directory access using MediaStore
      // So we don't need to wait for directory access - user can search immediately
    }
    // For non-Android platforms, scan immediately
    // For Android, user can search without directory access
  }

  Future<void> _scanDevice() async {
    setState(() {
      _isScanning = true;
      _scannedFiles = [];
    });

    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        log('✅ Storage permission granted');
      } else if (await Permission.manageExternalStorage.request().isGranted) {
        log('✅ Manage External Storage permission granted');
      } else {
        log('❌ Storage permissions denied');
      }
    }

    try {
      final files = await _scannerService.scanDevice();

      // Cache scan time and directory info
      await _cacheService.cacheLastScanInfo(
        DateTime.now(),
        files.isNotEmpty
            ? (files.first.isContentUri
                  ? 'SAF Directory'
                  : path.dirname(files.first.path))
            : null,
      );

      setState(() {
        _scannedFiles = files;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'fb2', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final file = BookFile(
          name: platformFile.name,
          path: platformFile.path!,
          size: platformFile.size,
          lastModified: DateTime.now(),
          extension: platformFile.extension ?? '',
          isContentUri:
              false, // File picker returns real paths or cached copies
        );
        _selectFile(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectFile(BookFile file) {
    if (file.extension.toLowerCase() == 'docx' ||
        file.extension.toLowerCase() == 'doc') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DOCX files are not supported at the moment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _selectedFile = file;
      _selectedFilePath = file.path;
    });

    // Extract metadata from filename
    _extractMetadataFromFilename(file.name);
  }

  Future<void> _saveBook() async {
    log('=== Starting book save process ===');

    if (!_formKey.currentState!.validate()) {
      log('❌ Form validation failed');
      return;
    }
    log('✅ Form validation passed');

    // Validate file is selected
    if (_selectedFilePath == null || _selectedFile == null) {
      log(
        '❌ No file selected - path: $_selectedFilePath, file: $_selectedFile',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a book file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    log(
      '✅ File selected - path: $_selectedFilePath, name: ${_selectedFile!.name}, isContentUri: ${_selectedFile!.isContentUri}',
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now().toIso8601String();
      log('📝 Parsing book data - pages text: "${_pagesController.text}"');

      int totalPages;
      try {
        totalPages = 0;
        log('✅ Pages parsed successfully: $totalPages');
      } catch (e, stackTrace) {
        log('❌ Error parsing pages: $e');
        log('Stack trace: $stackTrace');
        throw Exception(
          'Invalid page number: ${_pagesController.text}. Please enter a valid number.',
        );
      }

      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      log('📚 Book ID generated: $bookId');

      // For content URIs, we don't check existsSync (it won't work)
      // For regular files, verify file still exists
      if (!_selectedFile!.isContentUri) {
        log('🔍 Checking if regular file exists: $_selectedFilePath');
        final sourceFile = File(_selectedFilePath!);
        if (!sourceFile.existsSync()) {
          log('❌ File does not exist: $_selectedFilePath');
          throw Exception(
            'Selected file no longer exists. Please select another file.',
          );
        }
        log('✅ Regular file exists');
      } else {
        log('ℹ️ Content URI detected, skipping existsSync check');
      }

      // Copy file to internal storage (handles both regular paths and content URIs)
      log('📋 Copying file to internal storage...');
      String? internalFilePath;
      try {
        log('  - Source path: $_selectedFilePath');
        log('  - Book ID: $bookId');
        log('  - Original filename: ${_selectedFile!.name}');
        log('  - Is content URI: ${_selectedFile!.isContentUri}');

        internalFilePath = await _fileManager.copyFileToInternalStorage(
          sourcePath: _selectedFilePath!,
          bookId: bookId,
          originalFileName: _selectedFile!.name,
          cachedPath: _selectedFile!
              .cachedPath, // Use cached file if available for faster copying
        );

        if (internalFilePath != null) {
          log('✅ File copied successfully to: $internalFilePath');
        } else {
          log('❌ File copy returned null');
        }
      } catch (e, stackTrace) {
        log('❌ Error copying file to internal storage: $e');
        log('Stack trace: $stackTrace');
        throw Exception('Failed to copy file to internal storage: $e');
      }

      if (internalFilePath == null) {
        log('❌ Internal file path is null after copy operation');
        throw Exception('Failed to copy file to internal storage');
      }

      // At this point, internalFilePath is guaranteed to be non-null
      final finalFilePath = internalFilePath;
      log('✅ Final file path determined: $finalFilePath');

      // Check for duplicate books before creating the book object
      log('🔍 Checking for duplicate books...');
      final existingBooks = ref.read(allBooksProvider);
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();

      Book? duplicate;
      for (final existingBook in existingBooks) {
        final existingTitle = existingBook.title.toLowerCase().trim();
        final existingAuthor = existingBook.author.toLowerCase().trim();
        final newTitle = title.toLowerCase().trim();
        final newAuthor = author.toLowerCase().trim();

        // Check if title and author match (case-insensitive)
        final titleAuthorMatch =
            existingTitle == newTitle && existingAuthor == newAuthor;

        // Also check if the file path is the same (if available)
        final filePathMatch =
            existingBook.pdfUrl != null && existingBook.pdfUrl == finalFilePath;

        if (titleAuthorMatch || filePathMatch) {
          duplicate = existingBook;
          break;
        }
      }

      if (duplicate != null) {
        log(
          '❌ Duplicate book found: "${duplicate.title}" by ${duplicate.author}',
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Clean up the copied file since we're not adding the book
          try {
            await _fileManager.deleteBookFile(finalFilePath);
            log('  ✅ Cleaned up copied file due to duplicate');
          } catch (e) {
            log('  ⚠️ Error cleaning up file: $e');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'A book with the same title and author already exists: "${duplicate.title}"',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () {
                  if (duplicate != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            BookReaderScreen(book: duplicate!),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
        return;
      }
      log('✅ No duplicate found, proceeding with book creation');

      log('📖 Creating Book object...');
      log('  - Title: "$title"');
      log('  - Author: "$author"');
      log('  - Pages: $totalPages');
      log('  - Status: ${_selectedStatus.name}');

      final book = Book(
        id: bookId,
        title: title,
        author: author,
        cover: _coverController.text.trim().isNotEmpty
            ? _coverController.text.trim()
            : 'https://images.unsplash.com/photo-1636262454420-364d3a97e3e7',
        progress: _selectedStatus == BookStatus.reading
            ? 0
            : _selectedStatus == BookStatus.completed
            ? 100
            : 0,
        totalPages: totalPages,
        currentPage: 0,
        status: _selectedStatus,
        pdfUrl: finalFilePath, // Store internal storage path
        genre: _genreController.text.trim().isNotEmpty
            ? _genreController.text.trim()
            : null,
        dateAdded: now,
        dateUpdated: now,
        dateStarted: _selectedStatus == BookStatus.reading ? now : null,
        dateCompleted: _selectedStatus == BookStatus.completed ? now : null,
      );
      log('✅ Book object created: ${book.id}');

      // Save book using Riverpod provider
      log('💾 Saving book using Riverpod provider...');
      final success = await ref.read(booksProvider.notifier).addBook(book);
      log('📊 Book save result: $success');

      if (success) {
        log('✅ Book saved successfully, caching metadata...');
        try {
          await _cacheService.cacheBookFileLocation(bookId, finalFilePath);
          log('  ✅ File location cached');

          await _cacheService.cacheBookMetadata(bookId, {
            'fileSize': _selectedFile!.size,
            'fileExtension': _selectedFile!.extension,
            'fileName': _selectedFile!.name,
            'filePath': finalFilePath,
            'originalPath':
                _selectedFilePath, // Keep original path for reference
            'selectedAt': DateTime.now().toIso8601String(),
          });
          log('  ✅ Book metadata cached');
        } catch (e, stackTrace) {
          log('⚠️ Error caching metadata (non-critical): $e');
          log('Stack trace: $stackTrace');
          // Continue even if caching fails
        }
        log('🎉 Book save process completed successfully!');
      } else {
        log('❌ Book save returned false, cleaning up copied file...');
        // If book save failed, clean up the copied file
        try {
          final deleted = await _fileManager.deleteBookFile(finalFilePath);
          log('  ${deleted ? "✅" : "⚠️"} File cleanup result: $deleted');
        } catch (e, stackTrace) {
          log('  ❌ Error deleting file during cleanup: $e');
          log('Stack trace: $stackTrace');
        }
      }

      if (mounted) {
        if (success) {
          log('✅ Book saved successfully, navigating to PDF reader...');

          // Use the book object we just created for navigation
          // Since it was successfully saved, it should have all the correct data
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BookReaderScreen(book: book),
            ),
          );
        } else {
          log('❌ Showing error snackbar - save returned false');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add book. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        log('⚠️ Widget not mounted, cannot navigate or show snackbar');
      }
    } catch (e, stackTrace) {
      log('❌❌❌ ERROR SAVING BOOK ❌❌❌');
      log('Error type: ${e.runtimeType}');
      log('Error message: $e');
      log('Full stack trace:');
      log(stackTrace.toString());
      log('Current state:');
      log('  - Selected file path: $_selectedFilePath');
      log('  - Selected file: ${_selectedFile?.name ?? "null"}');
      log('  - Title: "${_titleController.text}"');
      log('  - Author: "${_authorController.text}"');
      log('  - Pages: "${_pagesController.text}"');
      log('  - Status: $_selectedStatus');
      log('  - Is loading: $_isLoading');
      log('  - Has directory access: $_hasDirectoryAccess');
      log('❌❌❌ END ERROR LOG ❌❌❌');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        log('⚠️ Widget not mounted, cannot show error snackbar');
      }
    } finally {
      log('🧹 Cleaning up - setting loading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      log('=== Book save process ended ===\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan Device Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan device',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.more_vert),
                  //   onPressed: () {
                  //     // TODO: Show options menu
                  //   },
                  // ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Button (works without directory access on Android)
              if (_scannedFiles.isEmpty && !_isScanning)
                Card(
                  color: AppTheme.inputBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Book File',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Search your device or pick a specific file.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isScanning ? null : _scanDevice,
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                label: Text(
                                  _isScanning ? 'Scanning...' : 'Scan Device',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isScanning ? null : _pickFile,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Pick File'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Optional: Directory Access Button (Android only) - for deeper scanning
              if (Platform.isAndroid &&
                  !_hasDirectoryAccess &&
                  _scannedFiles.isEmpty)
                const SizedBox(height: 16),
              if (Platform.isAndroid && !_hasDirectoryAccess)
                const SizedBox(height: 16),

              // Selected File (if any)
              if (_selectedFile != null)
                Card(
                  color: AppTheme.inputBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getFileTypeColor(
                              _selectedFile!.extension,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getFileIcon(_selectedFile!.extension),
                            color: _getFileTypeColor(_selectedFile!.extension),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _selectedFile!.formattedSize,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _selectedFilePath = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              if (_selectedFile != null) const SizedBox(height: 16),

              // Scanned Files List
              if (_isScanning)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.purpleStart,
                          strokeWidth: 12,
                          backgroundColor: AppTheme.indigoEnd,
                        ),
                        const SizedBox(height: 16),
                        const Text('Scanning device for book files...'),
                      ],
                    ),
                  ),
                )
              else if (_scannedFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No book files found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try scanning again or select a file manually',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate available height: screen height - app bar - padding - other widgets
                    final screenHeight = MediaQuery.of(context).size.height;
                    final appBarHeight = AppBar().preferredSize.height;
                    final statusBarHeight = MediaQuery.of(context).padding.top;
                    final bottomPadding = MediaQuery.of(context).padding.bottom;

                    // Estimate height for header, spacing, and save button area
                    final headerHeight = 80.0;
                    final saveButtonAreaHeight = 100.0;

                    // When no file is selected, use available space (unbounded)
                    // When file is selected, use fixed height of 300
                    final listViewHeight = _selectedFile == null
                        ? screenHeight -
                              appBarHeight -
                              statusBarHeight -
                              headerHeight -
                              saveButtonAreaHeight -
                              bottomPadding -
                              100 // Extra padding
                        : 300.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found ${_scannedFiles.length} book file${_scannedFiles.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: listViewHeight,
                          child: ListView.builder(
                            itemCount: _scannedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _scannedFiles[index];
                              final isSelected =
                                  _selectedFile?.path == file.path;
                              return ScannedFileCard(
                                file: file,
                                isSelected: isSelected,
                                onTap: () => _selectFile(file),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Title
              const SizedBox(height: 24),

              // Save Button
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveBook,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add Book', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'epub':
        return Colors.blue;
      case 'mobi':
        return Colors.green;
      case 'fb2':
        return const Color(0xFF8B7355);
      case 'txt':
        return Colors.grey;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
      case 'mobi':
      case 'fb2':
        return Icons.book;
      case 'txt':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _extractMetadataFromFilename(String filename) {
    // Remove file extension
    String nameWithoutExt = path.basenameWithoutExtension(filename);

    // Common patterns:
    // "Title - Author.pdf"
    // "Title by Author.pdf"
    // "Title, Author.pdf"
    // "Author - Title.pdf"

    // Try "Title - Author" or "Title by Author"
    if (nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      if (parts.length >= 2) {
        setState(() {
          _titleController.text = parts[0].trim();
          _authorController.text = parts[1].trim();
        });
        return;
      }
    }

    // Try "Title by Author"
    if (nameWithoutExt.contains(' by ')) {
      final parts = nameWithoutExt.split(' by ');
      if (parts.length >= 2) {
        setState(() {
          _titleController.text = parts[0].trim();
          _authorController.text = parts[1].trim();
        });
        return;
      }
    }

    // Try "Author, Title"
    if (nameWithoutExt.contains(', ')) {
      final parts = nameWithoutExt.split(', ');
      if (parts.length >= 2) {
        setState(() {
          _authorController.text = parts[0].trim();
          _titleController.text = parts[1].trim();
        });
        return;
      }
    }

    // If no pattern matches, use the filename as title
    setState(() {
      _titleController.text = nameWithoutExt.trim();
    });

    // Try to estimate pages based on file size (rough estimate)
    if (_selectedFilePath != null) {
      try {
        final file = File(_selectedFilePath!);
        if (file.existsSync()) {
          final fileSize = file.lengthSync();
          // Rough estimate: ~2KB per page for PDF, adjust as needed
          final estimatedPages = (fileSize / 2048).round();
          if (estimatedPages > 0 && estimatedPages < 10000) {
            _pagesController.text = estimatedPages.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Estimated pages: $estimatedPages (please verify)',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        // Ignore errors in page estimation
      }
    }
  }
}
