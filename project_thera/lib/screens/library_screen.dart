import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../widgets/book_card_compact.dart';
import '../widgets/search_bar.dart' show CustomSearchBar;
import '../theme/app_theme.dart';
import '../providers/book_providers.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Refresh books when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(booksProvider.notifier).loadBooks();
    });
  }

  Future<void> _handleAddBook() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddBookScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    return books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = ref.watch(allBooksProvider);
    final readingBooks = ref.watch(readingBooksProvider);
    final completedBooks = ref.watch(completedBooksProvider);
    final wantToReadBooks = ref.watch(wantToReadBooksProvider);
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.purpleStart, AppTheme.indigoEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text('Library'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _handleAddBook),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Reading'),
            Tab(text: 'Done'),
            Tab(text: 'Wishlist'),
          ],
        ),
      ),
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
        data: (_) => Column(
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
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookList(_filterBooks(allBooks)),
                  _buildBookList(_filterBooks(readingBooks)),
                  _buildBookList(_filterBooks(completedBooks)),
                  _buildBookList(_filterBooks(wantToReadBooks)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No books found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookCardCompact(
            book: books[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: books[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
