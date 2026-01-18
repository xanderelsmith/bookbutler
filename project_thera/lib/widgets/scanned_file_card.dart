import 'package:flutter/material.dart';
import '../services/file_scanner_service.dart';
import '../theme/app_theme.dart';

class ScannedFileCard extends StatelessWidget {
  final BookFile file;
  final bool isSelected;
  final VoidCallback onTap;

  const ScannedFileCard({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'epub':
        return Colors.blue;
      case 'mobi':
        return Colors.green;
      case 'fb2':
        return const Color(0xFF8B7355); // Brown
      case 'txt':
        return Colors.grey;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'rtf':
        return Colors.purple;
      case 'html':
        return Colors.orange;
      case 'djvu':
        return Colors.purpleAccent;
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
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'html':
        return Icons.language;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileColor = _getFileTypeColor(file.extension);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? fileColor : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail/Icon
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: fileColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getFileIcon(file.extension),
                color: fileColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // File Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: fileColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file.extension,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        file.formattedSize,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: fileColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}


