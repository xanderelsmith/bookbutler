class ReadingActivity {
  final DateTime date;
  final int pagesRead;
  final int minutesSpent;
  final List<String> bookIds;

  ReadingActivity({
    required this.date,
    required this.pagesRead,
    required this.minutesSpent,
    required this.bookIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'pagesRead': pagesRead,
      'minutesSpent': minutesSpent,
      'bookIds': bookIds,
    };
  }

  factory ReadingActivity.fromJson(Map<String, dynamic> json) {
    return ReadingActivity(
      date: DateTime.parse(json['date'] as String),
      pagesRead: json['pagesRead'] as int,
      minutesSpent: json['minutesSpent'] as int,
      bookIds: List<String>.from(json['bookIds'] as List),
    );
  }

  ReadingActivity copyWith({
    DateTime? date,
    int? pagesRead,
    int? minutesSpent,
    List<String>? bookIds,
  }) {
    return ReadingActivity(
      date: date ?? this.date,
      pagesRead: pagesRead ?? this.pagesRead,
      minutesSpent: minutesSpent ?? this.minutesSpent,
      bookIds: bookIds ?? this.bookIds,
    );
  }
}

// TODO Implement this library.
