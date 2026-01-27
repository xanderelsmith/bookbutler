import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera/services/serverpod_service.dart';
import '../providers/rive_provider.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'add_book_screen.dart';

import '../providers/user_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    LeaderboardScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the bootstrap provider to ensure user session is restored
    ref.watch(userBootstrapProvider);
    final riveAsync = ref.watch(riveProvider);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? riveAsync.when(
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
              data: (mascot) {
                return GestureDetector(
                  onTap: () async {
                    mascot.wave();
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBookScreen(),
                      ),
                    );
                    if (result == true) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: SizedBox(
                    height: 120,
                    width: 100,
                    child: Stack(
                      children: [
                        SizedBox(height: 100, width: 100, child: mascot.view),
                        const Align(
                          alignment: Alignment(0, 0.8),
                          child: Text(
                            'Tap Me !!!!',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
