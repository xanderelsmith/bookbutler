import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_snippet.dart';
import '../services/snippet_service.dart';

// Provider for SnippetService (singleton)
final snippetServiceProvider = Provider<SnippetService>((ref) {
  return SnippetService();
});

// StateNotifier for managing snippets
class SnippetsNotifier extends StateNotifier<AsyncValue<List<ReadingSnippet>>> {
  SnippetsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSnippets();
  }

  final SnippetService _service;

  Future<void> loadSnippets() async {
    state = const AsyncValue.loading();
    try {
      final snippets = await _service.getAllSnippets();
      state = AsyncValue.data(snippets);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addSnippet(ReadingSnippet snippet) async {
    try {
      final success = await _service.addSnippet(snippet);
      if (success) {
        await loadSnippets();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSnippet(String snippetId) async {
    try {
      final success = await _service.deleteSnippet(snippetId);
      if (success) {
        await loadSnippets();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSnippet(ReadingSnippet snippet) async {
    try {
      final success = await _service.updateSnippet(snippet);
      if (success) {
        await loadSnippets();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

// Provider for snippets notifier
final snippetsProvider = StateNotifierProvider<SnippetsNotifier, AsyncValue<List<ReadingSnippet>>>((ref) {
  final service = ref.watch(snippetServiceProvider);
  return SnippetsNotifier(service);
});

// Provider for all snippets (non-async for easier access)
final allSnippetsProvider = Provider<List<ReadingSnippet>>((ref) {
  final snippetsAsync = ref.watch(snippetsProvider);
  return snippetsAsync.when(
    data: (snippets) => snippets,
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for snippets by book
final snippetsByBookProvider = Provider.family<List<ReadingSnippet>, String>((ref, bookId) {
  final snippets = ref.watch(allSnippetsProvider);
  return snippets.where((s) => s.bookId == bookId).toList();
});
