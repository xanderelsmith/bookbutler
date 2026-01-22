import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../models/book.dart';
import '../widgets/book_card_compact.dart';
import '../widgets/search_bar.dart' show CustomSearchBar;
import '../widgets/butler_app_bar.dart';
import '../widgets/section_header.dart';
import '../providers/book_providers.dart';
import '../providers/streak_provider.dart';
import '../providers/reading_goal_provider.dart';
import '../services/home_widget_service.dart';
import '../services/streak_service.dart';
import '../theme/app_theme.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';
import '../providers/rive_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();

    // Trigger wave animation on load using the shared mascot
    ref.read(riveProvider.future).then((mascot) {
      mascot.wave();
    });

    // Refresh books when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(booksProvider.notifier).loadBooks();
      _updateHomeWidget();
      _startAnimationTimer();
    });
  }

  void _startAnimationTimer() {
    _animationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      final mascotAsync = ref.read(riveProvider);
      if (mascotAsync.hasValue) {
        final mascot = mascotAsync.value!;
        final random = Random();
        // 0: wave, 1: dance, 2: idle
        final action = random.nextInt(3);
        switch (action) {
          case 0:
            mascot.wave();
            break;
          case 1:
            mascot.dance();
            break;
          case 2:
            mascot.idle();
            break;
        }
      }
    });
  }

  Future<void> _updateHomeWidget() async {
    if (!mounted) return;

    try {
      final widgetService = HomeWidgetService();
      await widgetService.initialize();

      final enabled = await widgetService.isEnabled();
      if (!enabled) return;

      // Get currently reading book (similar to how want to read is retrieved)
      final booksReading = ref.read(readingBooksProvider);
      final currentlyReading = booksReading.isNotEmpty
          ? booksReading.first
          : null;

      // Get current streak
      final streakService = StreakService();
      final streak = await streakService.getCurrentStreak();

      // Update home widget with currently reading data and streak
      await widgetService.updateWidgetData(
        currentlyReading: currentlyReading,
        dailyStreak: streak,
      );
    } catch (e) {
      // Silently handle errors - widget update is not critical
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filteredBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return [];
    return books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final booksReading = ref.watch(readingBooksProvider);
    final booksCompleted = ref.watch(completedBooksProvider);
    final booksWantToRead = ref.watch(wantToReadBooksProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    // Update home widget when data changes (books or streak)
    ref.listen(booksProvider, (previous, next) {
      next.whenData((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateHomeWidget();
        });
      });
    });

    ref.listen(currentStreakProvider, (previous, next) {
      next.whenData((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateHomeWidget();
        });
      });
    });
    return Scaffold(
      appBar: ButlerAppBar(title: 'The Butler'),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading books: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(booksProvider.notifier).loadBooks(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (books) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Search Results
              if (_searchQuery.isNotEmpty && _filteredBooks(books).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Results',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      ..._filteredBooks(books).map(
                        (book) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookCardCompact(
                            book: book,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookDetailScreen(book: book),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

              // Main Content (when not searching)
              if (_searchQuery.isEmpty) ...[
                // Stats Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStatsSection(
                    booksCompleted.length,
                    booksReading,
                    booksWantToRead.length,
                    streakAsync,
                  ),
                ),

                // Continue Reading
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Continue Reading'),
                      const SizedBox(height: 12),
                      booksReading.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No books in progress',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : Column(
                              children: booksReading
                                  .map(
                                    (book) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: BookCardCompact(
                                        book: book,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookDetailScreen(book: book),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ],
                  ),
                ),

                // Recently Completed
                if (booksCompleted.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recently Completed'),
                        const SizedBox(height: 12),
                        ...booksCompleted
                            .take(2)
                            .map(
                              (book) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BookCardCompact(
                                  book: book,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookDetailScreen(book: book),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                // Want to Read
                if (booksWantToRead.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Want to Read'),
                        const SizedBox(height: 12),
                        ...booksWantToRead
                            .take(2)
                            .map(
                              (book) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BookCardCompact(
                                  book: book,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookDetailScreen(book: book),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    int booksCompleted,
    List<Book> booksReading,
    int booksWantToRead,
    AsyncValue<int> streakAsync,
  ) {
    final goalAsync = ref.watch(readingGoalProvider);
    final yearlyGoal = goalAsync.when(
      data: (goal) => goal,
      loading: () => 24,
      error: (_, __) => 24,
    );

    final double goalProgress = yearlyGoal > 0
        ? (booksCompleted / yearlyGoal).clamp(0.0, 1.0)
        : 0.0;

    // Get current book progress
    final currentBook = booksReading.isNotEmpty ? booksReading.first : null;
    double currentBookProgress = 0.0;
    String currentBookTitle = '';
    if (currentBook != null) {
      currentBookTitle = currentBook.title;
      if (currentBook.totalPages > 0 && currentBook.currentPage >= 0) {
        currentBookProgress = (currentBook.currentPage / currentBook.totalPages)
            .clamp(0.0, 1.0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reading Goal Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.purpleStart, AppTheme.indigoEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '2026 Reading Goal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$booksCompleted of $yearlyGoal books',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '${(goalProgress * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goalProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${yearlyGoal - booksCompleted} books to go!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              // Current Book Progress
              if (currentBook != null && currentBookProgress > 0) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white38, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.book, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentBookTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(currentBookProgress * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentBookProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              icon: Icons.book_outlined,
              iconColor: Colors.blue,
              iconBg: Colors.blue.withOpacity(0.1),
              label: 'Currently Reading',
              value: '${booksReading.length}',
            ),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              iconBg: Colors.green.withOpacity(0.1),
              label: 'Completed',
              value: '$booksCompleted',
            ),
            _buildStatCard(
              icon: Icons.bookmark_outline,
              iconColor: Colors.orange,
              iconBg: Colors.orange.withOpacity(0.1),
              label: 'Want to Read',
              value: '$booksWantToRead',
            ),
            _buildStatCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.red,
              iconBg: Colors.red.withOpacity(0.1),
              label: 'Current Streak',
              value: streakAsync.when(
                data: (streak) => '$streak ${streak == 1 ? 'day' : 'days'}',
                loading: () => '...',
                error: (_, __) => '0 days',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
