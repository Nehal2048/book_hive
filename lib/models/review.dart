class Review {
  final String email; // references users.email
  final String isbn; // references books.isbn
  final int? rating; // 1..5, nullable
  final String? reviewText;
  final DateTime createdAt;

  Review({
    required this.email,
    required this.isbn,
    this.rating,
    this.reviewText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    print('Parsing Review from JSON: $json');
    final dynamic ct = json['created_at'];
    DateTime parsedCreatedAt;
    if (ct is String) {
      parsedCreatedAt = DateTime.tryParse(ct) ?? DateTime.now();
    } else if (ct is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(ct);
    } else if (ct is DateTime) {
      parsedCreatedAt = ct;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Review(
      email: json['email'] as String,
      isbn: json['isbn'] as String,
      rating: json['rating'] as int?,
      reviewText: json['review_text'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'isbn': isbn,
    'rating': rating,
    'review_text': reviewText,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  String toString() {
    return 'Review(email: $email, isbn: $isbn, rating: $rating, review_text: $reviewText, created_at: ${createdAt.toIso8601String()})';
  }
}
