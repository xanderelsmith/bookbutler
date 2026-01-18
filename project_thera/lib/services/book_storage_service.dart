import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import 'secure_cache_service.dart';

class BookStorageService {
  static const String _booksKey = 'books';
  final SecureCacheService _cacheService = SecureCacheService();
  
  // Load all books from storage
  Future<List<Book>> loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_booksKey);
      
      if (booksJson == null || booksJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> booksList = json.decode(booksJson);
      return booksList.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Save all books to storage
  Future<bool> saveBooks(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = json.encode(
        books.map((book) => book.toJson()).toList(),
      );
      return await prefs.setString(_booksKey, booksJson);
    } catch (e) {
      return false;
    }
  }
  
  // Add a single book
  Future<bool> addBook(Book book) async {
    final books = await loadBooks();
    books.add(book);
    final success = await saveBooks(books);
    
    // Cache file location securely if available
    if (success && book.pdfUrl != null) {
      await _cacheService.cacheBookFileLocation(book.id, book.pdfUrl!);
    }
    
    // Cache book metadata
    if (success) {
      await _cacheService.cacheBookMetadata(book.id, {
        'title': book.title,
        'author': book.author,
        'cover': book.cover,
        'genre': book.genre,
        'totalPages': book.totalPages,
        'status': book.status.name,
      });
    }
    
    return success;
  }
  
  // Update a book
  Future<bool> updateBook(Book updatedBook) async {
    final books = await loadBooks();
    final index = books.indexWhere((b) => b.id == updatedBook.id);
    if (index != -1) {
      books[index] = updatedBook;
      final success = await saveBooks(books);
      
      // Update cached file location if changed
      if (success && updatedBook.pdfUrl != null) {
        await _cacheService.cacheBookFileLocation(updatedBook.id, updatedBook.pdfUrl!);
      }
      
      // Update cached metadata
      if (success) {
        await _cacheService.cacheBookMetadata(updatedBook.id, {
          'title': updatedBook.title,
          'author': updatedBook.author,
          'cover': updatedBook.cover,
          'genre': updatedBook.genre,
          'totalPages': updatedBook.totalPages,
          'status': updatedBook.status.name,
        });
      }
      
      return success;
    }
    return false;
  }
  
  // Delete a book
  Future<bool> deleteBook(String bookId) async {
    final books = await loadBooks();
    books.removeWhere((b) => b.id == bookId);
    final success = await saveBooks(books);
    
    // Remove cached data
    if (success) {
      await _cacheService.removeCachedBookData(bookId);
    }
    
    return success;
  }
  
  // Get a single book by ID
  Future<Book?> getBook(String bookId) async {
    final books = await loadBooks();
    try {
      final book = books.firstWhere((b) => b.id == bookId);
      
      // Try to restore file path from cache if missing
      if (book.pdfUrl == null) {
        final cachedPath = await _cacheService.getCachedBookFileLocation(bookId);
        if (cachedPath != null) {
          return book.copyWith(pdfUrl: cachedPath);
        }
      }
      
      return book;
    } catch (e) {
      return null;
    }
  }

  // Get cached file location for a book
  Future<String?> getCachedFileLocation(String bookId) async {
    return await _cacheService.getCachedBookFileLocation(bookId);
  }
}

