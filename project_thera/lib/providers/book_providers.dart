import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/book_storage_service.dart';
import '../services/file_manager_service.dart';
import '../services/home_widget_service.dart';
import '../services/streak_service.dart';

// Provider for BookStorageService (singleton)
final bookStorageServiceProvider = Provider<BookStorageService>((ref) {
  return BookStorageService();
});

// Provider for FileManagerService (singleton)
final fileManagerServiceProvider = Provider<FileManagerService>((ref) {
  return FileManagerService();
});

// StateNotifier for managing books list
class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  BooksNotifier(this._storageService, this._fileManager) : super(const AsyncValue.loading()) {
    loadBooks();
  }

  final BookStorageService _storageService;
  final FileManagerService _fileManager;
  final HomeWidgetService _homeWidgetService = HomeWidgetService();
  final StreakService _streakService = StreakService();

  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await _storageService.loadBooks();
      state = AsyncValue.data(books);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addBook(Book book) async {
    try {
      final success = await _storageService.addBook(book);
      if (success) {
        await loadBooks();
        // Update home widget when new book is added
        await _updateHomeWidget();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBook(Book updatedBook) async {
    try {
      final success = await _storageService.updateBook(updatedBook);
      if (success) {
        await loadBooks();
        // Update home widget when book progress changes
        await _updateHomeWidget();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateHomeWidget() async {
    try {
      await _homeWidgetService.initialize();
      final enabled = await _homeWidgetService.isEnabled();
      if (!enabled) return;

      final books = await _storageService.loadBooks();
      final currentlyReading = books.where((b) => b.status == BookStatus.reading).firstOrNull;

      final streak = await _streakService.getCurrentStreak();
      await _homeWidgetService.updateWidgetData(
        currentlyReading: currentlyReading,
        dailyStreak: streak,
      );
    } catch (e) {
      // Silently handle errors - widget update is not critical
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      // Get book before deleting to access file path
      final book = await _storageService.getBook(bookId);
      
      final success = await _storageService.deleteBook(bookId);
      if (success) {
        // Delete associated file from internal storage
        if (book?.pdfUrl != null) {
          try {
            await _fileManager.deleteBookFile(book!.pdfUrl!);
          } catch (e) {
            // Log error but don't fail the deletion
            // File might already be deleted or not exist
          }
        }
        await loadBooks();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<Book?> getBook(String bookId) async {
    try {
      return await _storageService.getBook(bookId);
    } catch (e) {
      return null;
    }
  }
}

// Provider for books notifier
final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  final storageService = ref.watch(bookStorageServiceProvider);
  final fileManager = ref.watch(fileManagerServiceProvider);
  return BooksNotifier(storageService, fileManager);
});

// Provider for filtered books by status
final booksByStatusProvider = Provider.family<List<Book>, BookStatus>((ref, status) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.when(
    data: (books) => books.where((b) => b.status == status).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for all books (non-async for easier access)
final allBooksProvider = Provider<List<Book>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.when(
    data: (books) => books,
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for reading books
final readingBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksByStatusProvider(BookStatus.reading));
});

// Provider for completed books
final completedBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksByStatusProvider(BookStatus.completed));
});

// Provider for want to read books
final wantToReadBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksByStatusProvider(BookStatus.wantToRead));
});

