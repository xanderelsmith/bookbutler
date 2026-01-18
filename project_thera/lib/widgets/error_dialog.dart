import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? fileName;
  final List<DialogAction>? actions;
  final IconData icon;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.fileName,
    this.actions,
    this.icon = Icons.error_outline,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? fileName,
    List<DialogAction>? actions,
    IconData icon = Icons.error_outline,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        fileName: fileName,
        actions: actions,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.destructive,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedForeground,
                    height: 1.5,
                  ),
            ),
            
            // File name if provided
            if (fileName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((action) {
                  final isPrimary = action.style == DialogActionStyle.primary;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: isPrimary
                        ? ElevatedButton(
                            onPressed: action.onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(action.label),
                          )
                        : OutlinedButton(
                            onPressed: action.onPressed,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: const BorderSide(
                                color: AppTheme.border,
                                width: 1,
                              ),
                            ),
                            child: Text(action.label),
                          ),
                  );
                }).toList(),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(
                        color: AppTheme.border,
                        width: 1,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final DialogActionStyle style;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.style = DialogActionStyle.secondary,
  });
}

enum DialogActionStyle {
  primary,
  secondary,
}

