import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:project_thera/theme/app_theme.dart';

class ReaderFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final ValueChanged<int>? onPrevPage;
  final ValueChanged<int> onNextPage;
  final ValueChanged<int> onPageChanged; // For preview update
  final ValueChanged<int> onSeekPage; // For actual seek action

  const ReaderFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onPageChanged,
    required this.onSeekPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  onPrevPage?.call(currentPage - 1);
                },
              ),

              // Pagination Slider
              Expanded(
                child: totalPages > 1
                    ? SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14.0,
                          ),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: AppTheme.primary,
                        ),
                        child: Slider(
                          value: currentPage.clamp(1, totalPages).toDouble(),
                          min: 1,
                          max: totalPages.toDouble(),
                          divisions: totalPages > 1 ? totalPages - 1 : 1,
                          label: currentPage.toString(),
                          onChanged: (val) {
                            log('val: $val');
                            onPageChanged(val.round());
                          },
                          onChangeEnd: (val) {
                            log('val: $val');
                            onSeekPage(val.round());
                          },
                        ),
                      )
                    : const SizedBox(),
              ),

              // Next Page Button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  onNextPage.call(currentPage + 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
