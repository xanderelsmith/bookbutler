import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

class BookCardCompact extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCardCompact({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.cover,
                width: 64,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 96,
                    color: AppTheme.muted,
                    child: const Icon(Icons.book, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Book Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress for reading books
                  if (book.status == BookStatus.reading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: book.progress / 100,
                        minHeight: 6,
                        backgroundColor: AppTheme.muted,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6), // blue-500
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.currentPage} / ${book.totalPages} pages',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  
                  // Completed badge
                  if (book.status == BookStatus.completed)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Finished',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


