import 'dart:convert';

import 'package:book_hive/main.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/user.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/models/review.dart';
import 'package:book_hive/shared/const.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String base = apiCallLinkProduction;

  Future<Map<String, String>> headers0() async {
    final token = await storage.read(key: 'token');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void ensureSuccess(http.Response res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    String message = res.body;
    try {
      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (decoded is Map && decoded['message'] != null)
        message = decoded['message'].toString();
    } catch (_) {}
    throw Exception('Request failed (${res.statusCode}): $message');
  }

  Future<List<Book>> getBooks() async {
    final uri = Uri.parse('$base/books');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Book>((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (payload is Map) return [Book.fromJson(payload.cast<String, dynamic>())];
    return <Book>[];
  }

  Future<Book> addBook(Map<String, dynamic> book, {String? email}) async {
    email ??= await storage.read(key: 'email') ?? '';
    final uri = Uri.parse(
      '$base/books',
    ).replace(queryParameters: {'email': email});
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode(book),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['book'] != null)
        ? decoded['book']
        : (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Book.fromJson(payload.cast<String, dynamic>());
    throw Exception('Unexpected response when adding book');
  }

  Future<Book> getBook(String isbn) async {
    final uri = Uri.parse('$base/books/$isbn');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Book.fromJson(payload.cast<String, dynamic>());
    throw Exception('Book not found');
  }

  Future<Book> updateBook(String isbn, Map<String, dynamic> data) async {
    final uri = Uri.parse('$base/books/$isbn');
    final res = await http.put(
      uri,
      headers: await headers0(),
      body: jsonEncode(data),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Book.fromJson(payload.cast<String, dynamic>());
    throw Exception('Failed to update book');
  }

  Future<bool> deleteBook(String isbn) async {
    final uri = Uri.parse('$base/books/$isbn');
    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<List<Book>> searchBooks(String query) async {
    final uri = Uri.parse('$base/books/search/${Uri.encodeComponent(query)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Book>((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Book>[];
  }

  Future<List<BookDetails>> getBookDetails(String isbn) async {
    final uri = Uri.parse('$base/books/$isbn/details');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<BookDetails>(
            (e) => BookDetails.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    if (payload is Map)
      return [BookDetails.fromJson(payload.cast<String, dynamic>())];
    return <BookDetails>[];
  }

  Future<List<Book>> getBooksByAuthor(String author) async {
    final uri = Uri.parse('$base/books/author/${Uri.encodeComponent(author)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Book>((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Book>[];
  }

  Future<List<Book>> getBooksByGenre(String genre) async {
    final uri = Uri.parse('$base/books/genre/${Uri.encodeComponent(genre)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Book>((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Book>[];
  }

  Future<BookDetails> addBookLink(
    String isbn,
    Map<String, dynamic> link, {
    String? email,
  }) async {
    email ??= await storage.read(key: 'email') ?? '';

    final edition = link['edition'] ?? link['Edition'];
    final pdfLink = link['pdfLink'] ?? link['pdf_link'];
    final audioUrl = link['audioUrl'] ?? link['audio_url'];

    if (edition == null || edition.toString().isEmpty) {
      throw Exception('Edition is required');
    }

    final params = <String, String>{
      'email': email,
      'edition': edition.toString(),
    };

    if (pdfLink != null && pdfLink.toString().isNotEmpty) {
      params['pdf_link'] = pdfLink.toString();
    }
    if (audioUrl != null && audioUrl.toString().isNotEmpty) {
      params['audio_url'] = audioUrl.toString();
    }

    final uri = Uri.parse(
      '$base/books/$isbn/add-link',
    ).replace(queryParameters: params);

    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);

    final decoded = jsonDecode(res.body);
    return BookDetails.fromJson(decoded['detail']);
  }

  Future<List<BookDetails>> getAllBookDetails() async {
    final uri = Uri.parse('$base/books/details');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<BookDetails>(
            (e) => BookDetails.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return <BookDetails>[];
  }

  Future<BookDetails> getSingleBookDetail(String isbn, String edition) async {
    final uri = Uri.parse(
      '$base/books/$isbn/details/${Uri.encodeComponent(edition)}',
    );
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map)
      return BookDetails.fromJson(payload.cast<String, dynamic>());
    throw Exception('Book detail not found');
  }

  Future<BookDetails> updateBookDetail(
    String isbn,
    String edition,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(
      '$base/books/$isbn/details/${Uri.encodeComponent(edition)}',
    );
    final res = await http.put(
      uri,
      headers: await headers0(),
      body: jsonEncode(data),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map)
      return BookDetails.fromJson(payload.cast<String, dynamic>());
    throw Exception('Failed to update book detail');
  }

  Future<bool> deleteBookDetail(String isbn, String edition) async {
    final uri = Uri.parse(
      '$base/books/$isbn/details/${Uri.encodeComponent(edition)}',
    );
    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    final uri = Uri.parse('$base/users');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode(userData),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return User.fromJson(payload.cast<String, dynamic>());
    throw Exception('Failed to create user');
  }

  Future<User> getUserByEmail(String email) async {
    final uri = Uri.parse('$base/users/${Uri.encodeComponent(email)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return User.fromJson(payload.cast<String, dynamic>());
    throw Exception('User not found');
  }

  // Reviews

  Future<Review> createReview(
    String email,
    Map<String, dynamic> reviewData,
  ) async {
    final uri = Uri.parse('$base/reviews/?email=${Uri.encodeComponent(email)}');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode(reviewData),
    );

    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Review.fromJson(payload.cast<String, dynamic>());
    throw Exception('Failed to create review');
  }

  Future<List<Review>> getAllReviews() async {
    final uri = Uri.parse('$base/reviews/');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Review>((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Review>[];
  }

  Future<Review> getReview(String reviewId) async {
    final uri = Uri.parse('$base/reviews/${Uri.encodeComponent(reviewId)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Review.fromJson(payload.cast<String, dynamic>());
    throw Exception('Review not found');
  }

  Future<bool> deleteReview(String reviewId) async {
    final uri = Uri.parse('$base/reviews/${Uri.encodeComponent(reviewId)}');
    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<List<Review>> getReviewsByBook(String isbn) async {
    final uri = Uri.parse('$base/reviews/book/${Uri.encodeComponent(isbn)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Review>((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Review>[];
  }

  Future<List<Review>> getReviewsByUser(String userId) async {
    final uri = Uri.parse('$base/reviews/user/${Uri.encodeComponent(userId)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Review>((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Review>[];
  }

  // Helpers for user+book keyed review endpoints (email + isbn)
  Future<Review> getReviewByUserAndBook(String userEmail, String isbn) async {
    final uri = Uri.parse(
      '$base/reviews/${Uri.encodeComponent(userEmail)}/${Uri.encodeComponent(isbn)}',
    );
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Review.fromJson(payload.cast<String, dynamic>());
    throw Exception('Review not found');
  }

  Future<Review> updateReviewByUserAndBook(
    String userEmail,
    String isbn,
    Map<String, dynamic> updates,
  ) async {
    final uri = Uri.parse(
      '$base/reviews/${Uri.encodeComponent(userEmail)}/${Uri.encodeComponent(isbn)}?email=${Uri.encodeComponent(userEmail)}',
    );

    final res = await http.put(
      uri,
      headers: await headers0(),
      body: jsonEncode(updates),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) return Review.fromJson(payload.cast<String, dynamic>());
    throw Exception('Failed to update review');
  }

  Future<bool> deleteReviewByUserAndBook(String userEmail, String isbn) async {
    final uri = Uri.parse(
      '$base/reviews/${Uri.encodeComponent(userEmail)}/${Uri.encodeComponent(isbn)}',
    );
    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }
}
