class Book {
  final String id;
  final String title;
  final String author;
  final String cover;
  final int progress;
  final int totalPages;
  final int currentPage;
  final BookStatus status;
  final String? pdfUrl;
  final String? genre;
  final double? pagesPerMinute;
  final int? totalTimeSpent; // in minutes
  final String? dateAdded;
  final String? dateUpdated;
  final String? dateStarted;
  final String? dateCompleted;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.progress,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    this.pdfUrl,
    this.genre,
    this.pagesPerMinute,
    this.totalTimeSpent,
    this.dateAdded,
    this.dateUpdated,
    this.dateStarted,
    this.dateCompleted,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? cover,
    int? progress,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
    String? pdfUrl,
    String? genre,
    double? pagesPerMinute,
    int? totalTimeSpent,
    String? dateAdded,
    String? dateStarted,
    String? dateCompleted,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      cover: cover ?? this.cover,
      progress: progress ?? this.progress,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      genre: genre ?? this.genre,
      pagesPerMinute: pagesPerMinute ?? this.pagesPerMinute,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted: dateStarted ?? this.dateStarted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover': cover,
      'progress': progress,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status.name,
      'pdfUrl': pdfUrl,
      'genre': genre,
      'pagesPerMinute': pagesPerMinute,
      'totalTimeSpent': totalTimeSpent,
      'dateAdded': dateAdded,
      'dateStarted': dateStarted,
      'dateCompleted': dateCompleted,
    };
  }

  // JSON deserialization
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      cover: json['cover'] as String,
      progress: json['progress'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      status: BookStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookStatus.wantToRead,
      ),
      pdfUrl: json['pdfUrl'] as String?,
      genre: json['genre'] as String?,
      pagesPerMinute: (json['pagesPerMinute'] as num?)?.toDouble(),
      totalTimeSpent: json['totalTimeSpent'] as int?,
      dateAdded: json['dateAdded'] as String?,
      dateStarted: json['dateStarted'] as String?,
      dateCompleted: json['dateCompleted'] as String?,
    );
  }
}

enum BookStatus { reading, completed, wantToRead }
