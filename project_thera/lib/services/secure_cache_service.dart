import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCacheService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Cache book file paths and metadata
  static const String _bookFilesCacheKey = 'book_files_cache';
  static const String _bookMetadataCacheKey = 'book_metadata_cache';
  static const String _lastScanTimeKey = 'last_scan_time';
  static const String _lastScanDirectoryKey = 'last_scan_directory';
  static const String _safDirectoryUriKey =
      'saf_directory_uri'; // For Android SAF directory URI
  static const String _firstLaunchKey =
      'first_launch'; // Track first app launch

  // Cache book file location
  Future<void> cacheBookFileLocation(String bookId, String filePath) async {
    try {
      final cache = await getCachedBookFiles();
      cache[bookId] = {
        'path': filePath,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await _saveCachedBookFiles(cache);
    } catch (e) {
      // Handle error silently
    }
  }

  // Get cached file location for a book
  Future<String?> getCachedBookFileLocation(String bookId) async {
    try {
      final cache = await getCachedBookFiles();
      final bookData = cache[bookId];
      if (bookData != null) {
        return bookData['path'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all cached book files
  Future<Map<String, Map<String, dynamic>>> getCachedBookFiles() async {
    try {
      final cached = await _storage.read(key: _bookFilesCacheKey);
      if (cached == null || cached.isEmpty) {
        return {};
      }
      final Map<String, dynamic> decoded = json.decode(cached);
      return decoded.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (e) {
      return {};
    }
  }

  // Save cached book files
  Future<void> _saveCachedBookFiles(
    Map<String, Map<String, dynamic>> cache,
  ) async {
    try {
      final encoded = json.encode(cache);
      await _storage.write(key: _bookFilesCacheKey, value: encoded);
    } catch (e) {
      // Handle error silently
    }
  }

  // Cache book metadata
  Future<void> cacheBookMetadata(
    String bookId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final cache = await getAllCachedBookMetadata();
      cache[bookId] = {
        ...metadata,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await _saveCachedBookMetadata(cache);
    } catch (e) {
      // Handle error silently
    }
  }

  // Get cached book metadata for a specific book
  Future<Map<String, dynamic>?> getCachedBookMetadata(String bookId) async {
    try {
      final cache = await getAllCachedBookMetadata();
      return cache[bookId];
    } catch (e) {
      return null;
    }
  }

  // Get all cached book metadata
  Future<Map<String, Map<String, dynamic>>> getAllCachedBookMetadata() async {
    try {
      final cached = await _storage.read(key: _bookMetadataCacheKey);
      if (cached == null || cached.isEmpty) {
        return {};
      }
      final Map<String, dynamic> decoded = json.decode(cached);
      return decoded.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (e) {
      return {};
    }
  }

  // Save cached book metadata
  Future<void> _saveCachedBookMetadata(
    Map<String, Map<String, dynamic>> cache,
  ) async {
    try {
      final encoded = json.encode(cache);
      await _storage.write(key: _bookMetadataCacheKey, value: encoded);
    } catch (e) {
      // Handle error silently
    }
  }

  // Cache last scan time and directory
  Future<void> cacheLastScanInfo(
    DateTime scanTime,
    String? lastDirectory,
  ) async {
    try {
      await _storage.write(
        key: _lastScanTimeKey,
        value: scanTime.toIso8601String(),
      );
      if (lastDirectory != null) {
        await _storage.write(key: _lastScanDirectoryKey, value: lastDirectory);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Get last scan time
  Future<DateTime?> getLastScanTime() async {
    try {
      final timeString = await _storage.read(key: _lastScanTimeKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get last scan directory
  Future<String?> getLastScanDirectory() async {
    try {
      return await _storage.read(key: _lastScanDirectoryKey);
    } catch (e) {
      return null;
    }
  }

  // Save SAF directory URI (for Android Storage Access Framework)
  Future<void> saveSafDirectoryUri(String uri) async {
    try {
      await _storage.write(key: _safDirectoryUriKey, value: uri);
    } catch (e) {
      // Handle error silently
    }
  }

  // Get saved SAF directory URI
  Future<String?> getSafDirectoryUri() async {
    try {
      return await _storage.read(key: _safDirectoryUriKey);
    } catch (e) {
      return null;
    }
  }

  // Clear SAF directory URI
  Future<void> clearSafDirectoryUri() async {
    try {
      await _storage.delete(key: _safDirectoryUriKey);
    } catch (e) {
      // Handle error silently
    }
  }

  // Remove cached data for a book
  Future<void> removeCachedBookData(String bookId) async {
    try {
      final filesCache = await getCachedBookFiles();
      filesCache.remove(bookId);
      await _saveCachedBookFiles(filesCache);

      final metadataCache = await getAllCachedBookMetadata();
      metadataCache.remove(bookId);
      await _saveCachedBookMetadata(metadataCache);
    } catch (e) {
      // Handle error silently
    }
  }

  // Clear all cached data
  Future<void> clearAllCache() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    try {
      final firstLaunch = await _storage.read(key: _firstLaunchKey);
      return firstLaunch == null || firstLaunch.isEmpty;
    } catch (e) {
      return true;
      // Default to true if error (safer to show notification)
    }
  }

  // Mark first launch as completed
  Future<void> markFirstLaunchComplete() async {
    try {
      await _storage.write(key: _firstLaunchKey, value: 'false');
    } catch (e) {}
  }

  // Offline reminder settings storage
  static const String _offlineReminderKey = 'offline_reminder_settings';

  /// Save offline reminder settings
  Future<void> saveReminderSettings(Map<String, dynamic> settings) async {
    try {
      final encoded = json.encode(settings);
      await _storage.write(key: _offlineReminderKey, value: encoded);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get offline reminder settings
  Future<Map<String, dynamic>?> getReminderSettings() async {
    try {
      final cached = await _storage.read(key: _offlineReminderKey);
      if (cached == null || cached.isEmpty) {
        return null;
      }
      return json.decode(cached) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
