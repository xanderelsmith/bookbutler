import 'dart:io';
import 'package:path/path.dart' as path;

// BookFile representation for isolate communication (must be serializable)
class BookFileData {
  final String path;
  final String name;
  final int size;
  final String extension;

  BookFileData({
    required this.path,
    required this.name,
    required this.size,
    required this.extension,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'size': size,
        'extension': extension,
      };

  factory BookFileData.fromJson(Map<String, dynamic> json) => BookFileData(
        path: json['path'] as String,
        name: json['name'] as String,
        size: json['size'] as int,
        extension: json['extension'] as String,
      );
}

// Top-level function for isolate - must be outside any class
Future<List<BookFileData>> scanDirectoriesIsolate(List<String> directoryPaths) async {
  const List<String> bookExtensions = [
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

  List<BookFileData> foundFiles = [];

  for (var dirPath in directoryPaths) {
    if (dirPath.isEmpty) continue;
    
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        foundFiles.addAll(await _scanDirectory(dir, bookExtensions));
      }
    } catch (e) {
      // Skip directories that can't be accessed
      continue;
    }
  }

  // Sort by name
  foundFiles.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  return foundFiles;
}

// Recursive directory scanning function for isolate
Future<List<BookFileData>> _scanDirectory(
  Directory dir,
  List<String> bookExtensions,
) async {
  List<BookFileData> files = [];

  try {
    if (!dir.existsSync()) return files;

    // Use list() instead of listSync() to allow yielding to event loop
    // This prevents blocking and allows I/O operations to be interleaved
    final entities = await dir.list(followLinks: false).toList();

    // Yield periodically to prevent blocking and allow other operations (like PDF loading)
    // to access I/O resources
    int processedCount = 0;
    const int yieldInterval = 50; // Yield every 50 items

    for (var entity in entities) {
      if (entity is File) {
        final ext = path
            .extension(entity.path)
            .toLowerCase()
            .replaceAll('.', '');
        if (bookExtensions.contains(ext)) {
          try {
            final stat = await entity.stat();
            files.add(
              BookFileData(
                path: entity.path,
                name: path.basename(entity.path),
                size: stat.size,
                extension: ext.toUpperCase(),
              ),
            );
          } catch (e) {
            // Skip files that can't be accessed
            continue;
          }
        }
      } else if (entity is Directory) {
        // Recursively scan subdirectories (limit depth to prevent stack overflow)
        try {
          files.addAll(await _scanDirectory(entity, bookExtensions));
        } catch (e) {
          // Skip directories that can't be accessed
          continue;
        }
      }
      
      // Yield periodically to prevent I/O contention with other operations like PDF loading
      processedCount++;
      if (processedCount % yieldInterval == 0) {
        // await Future.microtask(() {});
      }
    }
  } catch (e) {
    // Permission denied or other errors
  }

  return files;
}


