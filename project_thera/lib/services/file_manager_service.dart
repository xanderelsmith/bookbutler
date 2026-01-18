import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'storage_access_service.dart';

class FileManagerService {
  static const String _booksFolderName = 'books';
  final StorageAccessService _safService = StorageAccessService();

  /// Get the internal storage books directory
  Future<Directory> getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(path.join(appDir.path, _booksFolderName));

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    return booksDir;
  }

  /// Get the full path for a book file in internal storage
  Future<String> getBookFilePath(String bookId, String originalFileName) async {
    final booksDir = await getBooksDirectory();
    return path.join(
      booksDir.path,
      '$bookId${path.extension(originalFileName)}',
    );
  }

  /// Copy a file to internal storage
  /// Handles both regular file paths and content URIs (from SAF)
  /// Uses cached file if available for faster copying
  Future<String?> copyFileToInternalStorage({
    required String sourcePath,
    required String bookId,
    String? originalFileName,
    String? cachedPath, // Optional cached path for faster copying
  }) async {
    try {
      // Check if it's a content URI (from SAF on Android)
      if (Platform.isAndroid && _safService.isContentUri(sourcePath)) {
        // Use SAF service to copy content URI (with cached path if available)
        final result = await _safService.copyContentUriToFile(
          contentUri: sourcePath,
          bookId: bookId,
          originalFileName: originalFileName,
          cachedPath: cachedPath,
        );

        if (result != null) {
          return result['path'];
        } else {
          throw Exception('Failed to copy content URI to internal storage');
        }
      } else {
        // Regular file path - use standard file operations
        final sourceFile = File(sourcePath);

        // Get original filename if not provided
        final fileName = originalFileName ?? path.basename(sourcePath);

        // Get destination path
        final destinationPath = await getBookFilePath(bookId, fileName);

        // Check if source file exists
        if (!await sourceFile.exists()) {
          throw Exception('Source file does not exist: $sourcePath');
        }

        // Copy file to internal storage
        await sourceFile.copy(destinationPath);

        return destinationPath;
      }
    } catch (e) {
      throw Exception('Failed to copy file to internal storage: $e');
    }
  }

  /// Move a file from external storage to internal storage
  Future<String?> moveFileToInternalStorage({
    required String sourcePath,
    required String bookId,
    String? originalFileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);

      // Get original filename if not provided
      final fileName = originalFileName ?? path.basename(sourcePath);

      // Get destination path
      final destinationPath = await getBookFilePath(bookId, fileName);
      final destinationFile = File(destinationPath);

      // Check if source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // If destination already exists, delete it first
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      // Move file to internal storage
      await sourceFile.rename(destinationPath);

      return destinationPath;
    } catch (e) {
      // If move fails, try copy and then delete source
      try {
        final copiedPath = await copyFileToInternalStorage(
          sourcePath: sourcePath,
          bookId: bookId,
          originalFileName: originalFileName,
        );

        // Try to delete source file (may fail on Android 11+ due to permissions)
        try {
          await File(sourcePath).delete();
        } catch (_) {
          // Ignore deletion errors - file is already copied
        }

        return copiedPath;
      } catch (copyError) {
        throw Exception('Failed to move file to internal storage: $copyError');
      }
    }
  }

  /// Check if a file exists in internal storage
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete a book file from internal storage
  Future<bool> deleteBookFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get all files in the books directory
  Future<List<FileSystemEntity>> listBookFiles() async {
    try {
      final booksDir = await getBooksDirectory();
      return booksDir.listSync();
    } catch (e) {
      return [];
    }
  }

  /// Get the size of the books directory
  Future<int> getBooksDirectorySize() async {
    try {
      final booksDir = await getBooksDirectory();
      int totalSize = 0;

      await for (final entity in booksDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
