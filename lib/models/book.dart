class Book {
  final String isbn; // default: ""
  final String title; // default: ""
  final String summary; // default: ""
  final String genre; // default: ""
  final String language; // default: "English"
  final String author; // default: ""
  final String publisher; // default: ""
  final String coverUrl; // default: ""
  final int publishedYear; // default: 0

  Book({
    this.isbn = "",
    this.title = "",
    this.summary = "",
    this.genre = "",
    this.language = "English",
    this.author = "",
    this.publisher = "",
    this.coverUrl = "",
    this.publishedYear = 0,
  });

  /// Create Book from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'] ?? "",
      title: json['title'] ?? "",
      summary: json['summary'] ?? "",
      genre: json['genre'] ?? "",
      language: json['language'] ?? "English",
      author: json['author'] ?? "",
      publisher: json['publisher'] ?? "",
      coverUrl: json['cover_url'] ?? "",
      publishedYear: json['published_year'] ?? 0,
    );
  }

  /// Convert Book to JSON
  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'title': title,
      'summary': summary,
      'genre': genre,
      'language': language,
      'author': author,
      'publisher': publisher,
      'cover_url': coverUrl,
      'published_year': publishedYear,
    };
  }

  @override
  String toString() {
    return 'Book(isbn: $isbn, title: $title, author: $author, '
        'publishedYear: $publishedYear, genre: $genre, language: $language)';
  }
}
