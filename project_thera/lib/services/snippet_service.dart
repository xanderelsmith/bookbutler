import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_snippet.dart';

class SnippetService {
  static const String _snippetsKey = 'reading_snippets';

  Future<List<ReadingSnippet>> getAllSnippets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snippetsJson = prefs.getString(_snippetsKey);

      if (snippetsJson == null || snippetsJson.isEmpty) {
        return [];
      }

      final List<dynamic> snippetsList = json.decode(snippetsJson);
      return snippetsList
          .map((json) => ReadingSnippet.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addSnippet(ReadingSnippet snippet) async {
    final snippets = await getAllSnippets();
    snippets.add(snippet);
    return await _saveSnippets(snippets);
  }

  Future<bool> updateSnippet(ReadingSnippet updatedSnippet) async {
    final snippets = await getAllSnippets();
    final index = snippets.indexWhere((s) => s.id == updatedSnippet.id);
    if (index != -1) {
      snippets[index] = updatedSnippet;
      return await _saveSnippets(snippets);
    }
    return false;
  }

  Future<bool> deleteSnippet(String snippetId) async {
    final snippets = await getAllSnippets();
    snippets.removeWhere((s) => s.id == snippetId);
    return await _saveSnippets(snippets);
  }

  Future<bool> _saveSnippets(List<ReadingSnippet> snippets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snippetsJson = json.encode(
        snippets.map((snippet) => snippet.toJson()).toList(),
      );
      return await prefs.setString(_snippetsKey, snippetsJson);
    } catch (e) {
      return false;
    }
  }
}
