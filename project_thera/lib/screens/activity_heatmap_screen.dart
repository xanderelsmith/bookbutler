import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reading_activity_providers.dart';
import '../providers/snippet_providers.dart';
import '../models/reading_snippet.dart';

class ActivityHeatmapScreen extends ConsumerStatefulWidget {
  const ActivityHeatmapScreen({super.key});

  @override
  ConsumerState<ActivityHeatmapScreen> createState() =>
      _ActivityHeatmapScreenState();
}

class _ActivityHeatmapScreenState extends ConsumerState<ActivityHeatmapScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  late TabController _tabController;
  final PageController _monthPageController = PageController(
    initialPage: 12,
  ); // Start at current month

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Activity'),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _showMonthPicker(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Activity'),
            Tab(icon: Icon(Icons.bookmark), text: 'Snippets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActivityHeatmapView(), _buildSnippetsView()],
      ),
    );
  }

  Widget _buildActivityHeatmapView() {
    return PageView.builder(
      controller: _monthPageController,
      onPageChanged: (index) {
        // Calculate month based on page index (0 = 12 months ago, 12 = current month)
        final now = DateTime.now();
        final monthsFromNow = 12 - index;
        setState(() {
          _selectedMonth = DateTime(now.year, now.month - monthsFromNow, 1);
        });
      },
      itemBuilder: (context, index) {
        // Calculate month for this page
        final now = DateTime.now();
        final monthsFromNow = 12 - index;
        final month = DateTime(now.year, now.month - monthsFromNow, 1);
        final monthActivities = ref.watch(monthlyActivitiesProvider(month));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      _monthPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  Text(
                    '${_getMonthName(month.month)} ${month.year}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: index < 12
                        ? () {
                            _monthPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Heatmap
              _buildActivityHeatmap(monthActivities),
              const SizedBox(height: 24),

              // Stats
              _buildMonthlyStats(monthActivities),
            ],
          ),
        );
      },
      itemCount: 13, // Last 12 months + current month
    );
  }

  Widget _buildActivityHeatmap(List<Map<DateTime, int>> activities) {
    final Map<DateTime, int> activityMap = {};
    for (var activity in activities) {
      activityMap.addAll(activity);
    }

    // Get first and last day of month
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Get first day of week for the month (0 = Sunday)
    final firstWeekday = firstDay.weekday % 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Weekday labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (day) => SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Heatmap grid
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Empty cells for days before month starts
                ...List.generate(
                  firstWeekday,
                  (index) => const SizedBox(width: 32, height: 32),
                ),
                // Days of the month
                ...List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final date = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month,
                    day,
                  );
                  final normalizedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final pages = activityMap[normalizedDate] ?? 0;
                  final intensity = _calculateIntensity(
                    pages,
                    activityMap.values,
                  );

                  return Tooltip(
                    message:
                        '${date.day}/${date.month}/${date.year}\n$pages pages',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getColorForIntensity(intensity),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10,
                            color: intensity > 0.5
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: pages > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Less', Colors.grey.shade100),
                _buildLegendItem('', Colors.green.shade200),
                _buildLegendItem('', Colors.green.shade400),
                _buildLegendItem('More', Colors.green.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  double _calculateIntensity(int pages, Iterable<int> allPages) {
    if (allPages.isEmpty || pages == 0) return 0.0;
    final maxPages = allPages.reduce((a, b) => a > b ? a : b);
    if (maxPages == 0) return 0.0;
    return (pages / maxPages).clamp(0.0, 1.0);
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == 0) return Colors.grey.shade100;
    if (intensity < 0.25) return Colors.green.shade200;
    if (intensity < 0.5) return Colors.green.shade400;
    if (intensity < 0.75) return Colors.green.shade600;
    return Colors.green.shade800;
  }

  Widget _buildMonthlyStats(List<Map<DateTime, int>> activities) {
    final Map<DateTime, int> activityMap = {};
    for (var activity in activities) {
      activityMap.addAll(activity);
    }

    final totalPages = activityMap.values.fold<int>(
      0,
      (sum, pages) => sum + pages,
    );
    final activeDays = activityMap.values.where((pages) => pages > 0).length;
    final avgPagesPerDay = activeDays > 0
        ? (totalPages / activeDays).round()
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Pages',
                    '$totalPages',
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Active Days',
                    '$activeDays',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg/Day',
                    '$avgPagesPerDay',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetsView() {
    final snippets = ref.watch(allSnippetsProvider);

    if (snippets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No saved snippets yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Highlight text while reading to save snippets',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group snippets by book
    final Map<String, List<ReadingSnippet>> snippetsByBook = {};
    for (var snippet in snippets) {
      if (!snippetsByBook.containsKey(snippet.bookId)) {
        snippetsByBook[snippet.bookId] = [];
      }
      snippetsByBook[snippet.bookId]!.add(snippet);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: snippetsByBook.length,
      itemBuilder: (context, index) {
        final bookId = snippetsByBook.keys.elementAt(index);
        final bookSnippets = snippetsByBook[bookId]!;
        final firstSnippet = bookSnippets.first;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.book),
            title: Text(
              firstSnippet.bookTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${bookSnippets.length} snippet${bookSnippets.length != 1 ? 's' : ''}',
            ),
            children: bookSnippets.map((snippet) {
              return ListTile(
                title: Text(snippet.text, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  'Page ${snippet.pageNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Snippet'),
                        content: const Text(
                          'Are you sure you want to delete this snippet?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      await ref
                          .read(snippetsProvider.notifier)
                          .deleteSnippet(snippet.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Snippet deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _showMonthPicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedMonth = date;
        });
      }
    });
  }
}
