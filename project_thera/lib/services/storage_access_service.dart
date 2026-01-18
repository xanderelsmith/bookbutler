import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service to handle Storage Access Framework (SAF) operations via native Android code
class StorageAccessService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.project_thera/storage_access',
  );

  /// Open directory picker using ACTION_OPEN_DOCUMENT_TREE
  /// Returns the URI string if successful, null otherwise
  Future<String?> openDirectoryPicker() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final String? uri = await _channel.invokeMethod<String>(
        'openDirectoryPicker',
      );
      return uri;
    } on PlatformException catch (e) {
      log("Failed to open directory picker: '${e.message}'.");
      return null;
    }
  }

  /// Scan a directory tree URI for book files
  /// Returns list of file information maps
  Future<List<Map<String, dynamic>>> scanDirectory(String uri) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final List<dynamic>? files = await _channel.invokeMethod<List<dynamic>>(
        'scanDirectory',
        {'uri': uri},
      );

      if (files == null) {
        return [];
      }

      return files.cast<Map<dynamic, dynamic>>().map((file) {
        final result = <String, dynamic>{
          'path': file['path'] as String,
          'name': file['name'] as String,
          'size': file['size'] as int,
          'extension': file['extension'] as String,
        };
        
        // Include cached path if available (automatically cached during scan)
        if (file['cachedPath'] != null) {
          result['cachedPath'] = file['cachedPath'] as String;
        }
        if (file['cachedSize'] != null) {
          result['cachedSize'] = file['cachedSize'] as int;
        }
        
        return result;
      }).toList();
    } on PlatformException catch (e) {
      log("Failed to scan directory: '${e.message}'.");
      return [];
    }
  }

  /// Copy a content URI to internal storage
  /// Returns a map with 'path' and 'fileName' keys
  /// Uses cached file if available for faster copying
  Future<Map<String, String>?> copyContentUriToFile({
    required String contentUri,
    required String bookId,
    String? originalFileName,
    String? cachedPath, // Optional cached path for faster copying
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final Map<dynamic, dynamic>? result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('copyContentUriToFile', {
            'contentUri': contentUri,
            'bookId': bookId,
            'originalFileName': originalFileName,
            if (cachedPath != null) 'cachedPath': cachedPath,
          });

      if (result == null) {
        return null;
      }

      return {
        'path': result['path'] as String,
        'fileName': result['fileName'] as String,
      };
    } on PlatformException catch (e) {
      print("Failed to copy content URI: '${e.message}'.");
      return null;
    }
  }

  /// Take persistable URI permission for long-term access
  Future<bool> takePersistableUriPermission(String uri) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'takePersistableUriPermission',
        {'uri': uri},
      );
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to take persistable URI permission: '${e.message}'.");
      return false;
    }
  }

  /// Check if a file path is a content URI
  bool isContentUri(String? filePath) {
    if (filePath == null) return false;
    return filePath.startsWith('content://');
  }

  /// Clear the temporary cache directory (similar to file_picker's clearCache)
  /// This removes all cached files from the temporary cache directory
  Future<bool> clearCache() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('clearCache');
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to clear cache: '${e.message}'.");
      return false;
    }
  }

  /// Search for book files using MediaStore API (no directory access required)
  /// This searches common locations like Downloads, Documents, etc.
  Future<List<Map<String, dynamic>>> searchBooksWithMediaStore() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final List<dynamic>? files = await _channel.invokeMethod<List<dynamic>>(
        'searchBooksWithMediaStore',
      );

      if (files == null) {
        return [];
      }

      return files.cast<Map<dynamic, dynamic>>().map((file) {
        final result = <String, dynamic>{
          'path': file['path'] as String,
          'name': file['name'] as String,
          'size': file['size'] as int,
          'extension': file['extension'] as String,
        };
        
        // Include cached path if available (automatically cached during search)
        if (file['cachedPath'] != null) {
          result['cachedPath'] = file['cachedPath'] as String;
        }
        if (file['cachedSize'] != null) {
          result['cachedSize'] = file['cachedSize'] as int;
        }
        
        return result;
      }).toList();
    } on PlatformException catch (e) {
      print("Failed to search books with MediaStore: '${e.message}'.");
      return [];
    }
  }
}
