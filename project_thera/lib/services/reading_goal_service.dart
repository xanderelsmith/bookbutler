import 'package:shared_preferences/shared_preferences.dart';

class ReadingGoalService {
  static const String _goalKey = 'reading_goal_books';
  static const int _defaultGoal = 24;

  /// Get the current reading goal (number of books)
  Future<int> getGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_goalKey) ?? _defaultGoal;
    } catch (e) {
      return _defaultGoal;
    }
  }

  /// Set the reading goal (number of books)
  Future<bool> setGoal(int books) async {
    try {
      if (books < 1) {
        return false; // Goal must be at least 1
      }
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_goalKey, books);
    } catch (e) {
      return false;
    }
  }

  /// Reset goal to default
  Future<bool> resetGoal() async {
    return await setGoal(_defaultGoal);
  }
}
