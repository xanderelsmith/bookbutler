import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'storage_access_service.dart';
import 'file_scanner_isolate.dart';
import 'secure_cache_service.dart';
import 'dart:isolate';

class BookFile {
  final String path;
  final String name;
  final int size;
  final String extension;
  final bool isContentUri; // Track if this is a content URI from SAF
  final String? cachedPath; // Path to cached file (if available)
  final DateTime? lastModified;

  BookFile({
    required this.path,
    required this.name,
    required this.size,
    required this.extension,
    this.isContentUri = false,
    this.cachedPath,
    this.lastModified,
  });

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get the best available path - prefer cached path if available, otherwise use original path
  String get effectivePath => cachedPath ?? path;
}

class FileScannerService {
  final StorageAccessService _safService = StorageAccessService();
  final SecureCacheService _cacheService = SecureCacheService();

  static const List<String> bookExtensions = [
    'pdf',
    'epub',
    'mobi',
    'fb2',
    'txt',
    'doc',
    'docx',
    'rtf',
    'html',
    'djvu',
  ];

  String? _selectedDirectoryUri; // Store the selected directory URI

  /// Initialize and load saved directory URI from cache
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      _selectedDirectoryUri = await _cacheService.getSafDirectoryUri();
    }
  }

  /// Open directory picker and store the selected URI
  /// Returns true if directory was selected, false if cancelled
  Future<bool> requestDirectoryAccess() async {
    if (!Platform.isAndroid) {
      // On non-Android platforms, we can still use the old method
      return true;
    }

    try {
      final uri = await _safService.openDirectoryPicker();
      if (uri != null) {
        _selectedDirectoryUri = uri;
        // Take persistable permission for long-term access
        await _safService.takePersistableUriPermission(uri);
        // Save URI to persistent storage
        await _cacheService.saveSafDirectoryUri(uri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get the currently selected directory URI
  String? getSelectedDirectoryUri() => _selectedDirectoryUri;

  /// Scan the selected directory using SAF (on Android) or traditional method (other platforms)
  /// If no directory access is granted on Android, uses MediaStore search instead
  Future<List<BookFile>> scanDevice() async {
    if (Platform.isAndroid) {
      if (_selectedDirectoryUri != null) {
        // Use SAF to scan directory
        return await _scanDirectoryWithSAF(_selectedDirectoryUri!);
      } else {
        // No directory access - use MediaStore search (no permission needed)
        return await _searchWithMediaStore();
      }
    } else {
      // Use traditional method for iOS and desktop
      return await _scanDeviceTraditional();
    }
  }

  /// Scan directory using Storage Access Framework
  /// Files are automatically cached during scanning for faster access
  Future<List<BookFile>> _scanDirectoryWithSAF(String directoryUri) async {
    try {
      // Capture the RootIsolateToken to allow platform channels in background isolate
      final token = RootIsolateToken.instance;
      if (token == null) {
        // Fallback or error if token is null (shouldn't happen in normal Flutter app)
        return [];
      }

      // Run the entire operation (fetch + process) in a background isolate
      return await Isolate.run(() async {
        // Register the background isolate with the root isolate
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);

        // We need a fresh instance or access to the channel inside the isolate
        // Since StorageAccessService uses a const MethodChannel, we can create a new instance
        final safService = StorageAccessService();
        final filesData = await safService.scanDirectory(directoryUri);

        return filesData.map((fileData) {
          return BookFile(
            path: fileData['path'] as String,
            name: fileData['name'] as String,
            size: (fileData['size'] ?? fileData['cachedSize'] ?? 0) as int,
            extension: fileData['extension'] as String,
            isContentUri: true,
            cachedPath: fileData['cachedPath'] as String?,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error scanning directory with SAF: $e');
      return [];
    }
  }

  /// Search for book files using MediaStore API (no directory access required)
  /// This searches common locations like Downloads, Documents, etc.
  /// Files are automatically cached during search for faster access
  Future<List<BookFile>> _searchWithMediaStore() async {
    try {
      // Capture the RootIsolateToken
      final token = RootIsolateToken.instance;
      if (token == null) {
        return [];
      }

      // Run the entire operation in a background isolate
      return await Isolate.run(() async {
        // Register the background isolate
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);

        final safService = StorageAccessService();
        final filesData = await safService.searchBooksWithMediaStore();

        return filesData.map((fileData) {
          return BookFile(
            path: fileData['path'] as String,
            name: fileData['name'] as String,
            size: (fileData['size'] ?? fileData['cachedSize'] ?? 0) as int,
            extension: fileData['extension'] as String,
            isContentUri: true,
            cachedPath: fileData['cachedPath'] as String?,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error searching with MediaStore: $e');
      return [];
    }
  }

  /// Traditional scanning method for non-Android platforms
  Future<List<BookFile>> _scanDeviceTraditional() async {
    try {
      List<String> directoryPaths = [];

      if (Platform.isIOS) {
        // iOS directories
        final documentsDir = await getApplicationDocumentsDirectory();
        final externalStorage = await getExternalStorageDirectory();

        directoryPaths = [
          documentsDir.path,
          if (externalStorage != null) externalStorage.path,
        ].where((path) => path.isNotEmpty).toList();
      } else {
        // Desktop platforms
        final homeDir =
            Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (homeDir != null) {
          directoryPaths = [
            path.join(homeDir, 'Downloads'),
            path.join(homeDir, 'Documents'),
            path.join(homeDir, 'Desktop'),
          ];
        }
      }

      // Filter out non-existent directories before passing to isolate
      directoryPaths = directoryPaths.where((dirPath) {
        try {
          return Directory(dirPath).existsSync();
        } catch (e) {
          return false;
        }
      }).toList();

      if (directoryPaths.isEmpty) {
        return [];
      }

      // Run scanning in isolate to avoid blocking UI
      final fileDataList = await Isolate.run(() {
        return scanDirectoriesIsolate(directoryPaths);
      });

      // Convert BookFileData to BookFile
      return fileDataList
          .map(
            (data) => BookFile(
              path: data.path,
              name: data.name,
              size: data.size,
              extension: data.extension,
              isContentUri: false,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if directory access has been granted
  bool hasDirectoryAccess() {
    return _selectedDirectoryUri != null;
  }

  /// Clear saved directory URI (for example, if user wants to select a different directory)
  Future<void> clearDirectoryAccess() async {
    _selectedDirectoryUri = null;
    if (Platform.isAndroid) {
      await _cacheService.clearSafDirectoryUri();
    }
  }
}
