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

  /// Create Book from Open Library JSON
  factory Book.fromOpenLibraryJson(String isbnKey, Map<String, dynamic> json) {
    final data = json[isbnKey] ?? {};

    // Extract authors as comma-separated string
    String author = "";
    if (data['authors'] != null && data['authors'] is List) {
      author = (data['authors'] as List).map((a) => a['name']).join(', ');
    }

    // Extract publishers as comma-separated string
    String publisher = "";
    if (data['publishers'] != null && data['publishers'] is List) {
      publisher = (data['publishers'] as List).map((p) => p['name']).join(', ');
    }

    // Extract first subject as genre (optional)
    String genre = "";
    if (data['subjects'] != null &&
        data['subjects'] is List &&
        data['subjects'].isNotEmpty) {
      genre = data['subjects'][0]['name'] ?? "";
    }

    // Extract published year from publish_date
    int publishedYear = 0;
    if (data['publish_date'] != null) {
      final yearMatch = RegExp(r'\d{4}').firstMatch(data['publish_date']);
      if (yearMatch != null) publishedYear = int.parse(yearMatch.group(0)!);
    }

    // Cover image (large)
    String coverUrl = "";
    if (data['cover'] != null && data['cover']['large'] != null) {
      coverUrl = data['cover']['large'];
    }

    return Book(
      isbn: isbnKey.replaceAll('ISBN:', ''),
      title: data['title'] ?? "",
      summary: data['notes'] ?? "", // you can use notes as a short summary
      genre: genre,
      language: "English", // Open Library doesn't always provide language
      author: author,
      publisher: publisher,
      coverUrl: coverUrl,
      publishedYear: publishedYear,
    );
  }
}
