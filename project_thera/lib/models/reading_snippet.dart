class ReadingSnippet {
  final String id;
  final String bookId;
  final String bookTitle;
  final String text;
  final int pageNumber;
  final String dateSaved;
  final String? note;

  ReadingSnippet({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.text,
    required this.pageNumber,
    required this.dateSaved,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'text': text,
      'pageNumber': pageNumber,
      'dateSaved': dateSaved,
      'note': note,
    };
  }

  factory ReadingSnippet.fromJson(Map<String, dynamic> json) {
    return ReadingSnippet(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      text: json['text'] as String,
      pageNumber: json['pageNumber'] as int,
      dateSaved: json['dateSaved'] as String,
      note: json['note'] as String?,
    );
  }

  ReadingSnippet copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? text,
    int? pageNumber,
    String? dateSaved,
    String? note,
  }) {
    return ReadingSnippet(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      text: text ?? this.text,
      pageNumber: pageNumber ?? this.pageNumber,
      dateSaved: dateSaved ?? this.dateSaved,
      note: note ?? this.note,
    );
  }
}
