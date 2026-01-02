import 'dart:convert';

import 'package:book_hive/main.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/user.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/models/review.dart';
import 'package:book_hive/models/listing.dart';
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
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
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

  Future<Book> updateBook(
    String isbn,
    Map<String, dynamic> data,
    String email,
  ) async {
    final params = <String, String>{'email': email, 'isbn': isbn};

    final uri = Uri.parse('$base/books/$isbn').replace(queryParameters: params);
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
    if (payload is Map) {
      return [BookDetails.fromJson(payload.cast<String, dynamic>())];
    }
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
    if (payload is Map) {
      return BookDetails.fromJson(payload.cast<String, dynamic>());
    }
    throw Exception('Book detail not found');
  }

  Future<BookDetails> updateBookDetail({
    required String isbn,
    required String email,
    required BookDetails detail,
  }) async {
    final params = <String, String>{'email': email};

    if (detail.pdfLink.isNotEmpty) {
      params['pdf_link'] = detail.pdfLink;
    }
    if (detail.audioUrl.isNotEmpty) {
      params['audio_url'] = detail.audioUrl;
    }

    final uri = Uri.parse(
      '$base/books/$isbn/details/${Uri.encodeComponent(detail.edition)}',
    ).replace(queryParameters: params);

    print(uri.toString());

    final res = await http.put(uri, headers: await headers0());

    ensureSuccess(res);

    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['detail'] != null)
        ? decoded['detail']
        : decoded;

    if (payload is Map) {
      return BookDetails.fromJson(payload.cast<String, dynamic>());
    }

    throw Exception('Failed to update book detail');
  }

  Future<bool> deleteBookDetail(
    String isbn,
    String edition,
    String email,
  ) async {
    final params = <String, String>{
      'email': email,
      'isbn': isbn,
      'edition': edition,
    };

    final uri = Uri.parse(
      '$base/books/$isbn/details/${Uri.encodeComponent(edition)}',
    ).replace(queryParameters: params);

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
    ).replace(queryParameters: {'email': userEmail});

    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  // Listings

  Future<Listing> createListing(
    Map<String, dynamic> listingData, {
    String? sellerId,
  }) async {
    sellerId ??= await storage.read(key: 'email') ?? '';
    final uri = Uri.parse(
      '$base/listings',
    ).replace(queryParameters: {'seller_id': sellerId});
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode(listingData),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) {
      return Listing.fromJson(payload.cast<String, dynamic>());
    }
    throw Exception('Failed to create listing');
  }

  Future<List<Listing>> getAllListings() async {
    final uri = Uri.parse('$base/listings');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  Future<List<Listing>> getAvailableListings({
    String? listingType,
    String? condition,
  }) async {
    final params = <String, String>{'status': 'available'};
    if (listingType != null) params['listing_type'] = listingType;
    if (condition != null) params['condition'] = condition;

    final uri = Uri.parse(
      '$base/listings/available',
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  Future<Listing> getListing(int listingId) async {
    final uri = Uri.parse('$base/listings/$listingId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is Map) {
      return Listing.fromJson(payload.cast<String, dynamic>());
    }
    throw Exception('Listing not found');
  }

  Future<Listing> updateListing(
    int listingId,
    Map<String, dynamic> updates, {
    String? userId,
  }) async {
    final uri = Uri.parse(
      '$base/listings/$listingId',
    ).replace(queryParameters: {'user_id': userId});
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
    if (payload is Map) {
      return Listing.fromJson(payload.cast<String, dynamic>());
    }
    throw Exception('Failed to update listing');
  }

  Future<bool> deleteListing(int listingId, String? userId) async {
    final uri = Uri.parse(
      '$base/listings/$listingId',
    ).replace(queryParameters: {'user_id': userId});
    final res = await http.delete(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<List<Listing>> getListingsByUser(String userId) async {
    final uri = Uri.parse('$base/listings/user/${Uri.encodeComponent(userId)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  Future<List<Listing>> getListingsByBook(String isbn) async {
    final uri = Uri.parse('$base/listings/book/${Uri.encodeComponent(isbn)}');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  Future<List<Listing>> getListingsByType(String listingType) async {
    final uri = Uri.parse(
      '$base/listings/type/${Uri.encodeComponent(listingType)}',
    );
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  Future<List<Listing>> searchListings(String query) async {
    final uri = Uri.parse(
      '$base/listings/search/${Uri.encodeComponent(query)}',
    );
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    final payload = (decoded is Map && decoded['data'] != null)
        ? decoded['data']
        : decoded;
    if (payload is List) {
      return payload
          .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Listing>[];
  }

  // ============== BORROW APIS ==============
  Future<bool> sendBorrowRequest(int targetId, String borrowerId) async {
    final uri = Uri.parse('$base/borrow/request');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode({'target_id': targetId, 'borrower_id': borrowerId}),
    );
    ensureSuccess(res);
    return true;
  }

  Future<List<dynamic>> getReceivedBorrowRequests(String userId) async {
    final uri = Uri.parse('$base/borrow/received/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> getSentBorrowRequests(String userId) async {
    final uri = Uri.parse('$base/borrow/sent/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<bool> acceptBorrowRequest(int listingId, String lenderId) async {
    final uri = Uri.parse(
      '$base/borrow/accept/$listingId',
    ).replace(queryParameters: {'lender_id': lenderId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<bool> rejectBorrowRequest(int listingId, String lenderId) async {
    final uri = Uri.parse(
      '$base/borrow/reject/$listingId',
    ).replace(queryParameters: {'lender_id': lenderId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<bool> cancelBorrowRequest(int listingId, String borrowerId) async {
    final uri = Uri.parse(
      '$base/borrow/cancel/$listingId',
    ).replace(queryParameters: {'borrower_id': borrowerId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<bool> returnBorrowedBook(int borrowId, String userId) async {
    final uri = Uri.parse(
      '$base/borrow/return/$borrowId',
    ).replace(queryParameters: {'user_id': userId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<Map<String, dynamic>> getActiveBorrows(String userId) async {
    final uri = Uri.parse('$base/borrow/active/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Future<List<dynamic>> getBorrowHistory(String userId) async {
    final uri = Uri.parse('$base/borrow/history/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  // ============== EXCHANGE APIS ==============
  Future<bool> sendExchangeRequest(int targetId, int yourId) async {
    final uri = Uri.parse('$base/exchange/request');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode({'target_id': targetId, 'your_id': yourId}),
    );
    ensureSuccess(res);
    return true;
  }

  Future<List<dynamic>> getReceivedExchangeRequests(String userId) async {
    final uri = Uri.parse('$base/exchange/received/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> getSentExchangeRequests(String userId) async {
    final uri = Uri.parse('$base/exchange/sent/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<bool> acceptExchangeRequest(int listingId, String userId) async {
    final uri = Uri.parse(
      '$base/exchange/accept/$listingId',
    ).replace(queryParameters: {'user_id': userId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<bool> rejectExchangeRequest(int listingId, String userId) async {
    final uri = Uri.parse(
      '$base/exchange/reject/$listingId',
    ).replace(queryParameters: {'user_id': userId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<bool> cancelExchangeRequest(int yourListingId, String userId) async {
    final uri = Uri.parse(
      '$base/exchange/cancel/$yourListingId',
    ).replace(queryParameters: {'user_id': userId});
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  Future<List<dynamic>> getUserExchanges(String userId) async {
    final uri = Uri.parse('$base/exchange/user/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  // ============== ORDERS APIS ==============
  Future<Map<String, dynamic>> getOrder(int orderId) async {
    final uri = Uri.parse('$base/orders/$orderId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Future<List<dynamic>> getOrdersByUser(String userId) async {
    final uri = Uri.parse('$base/orders/user/$userId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> createOrder(
    int listingId,
    String buyerId,
  ) async {
    final uri = Uri.parse('$base/orders/');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode({'listing_id': listingId, 'buyer_id': buyerId}),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Future<bool> makePayment(int orderId) async {
    final uri = Uri.parse('$base/orders/$orderId/pay');
    final res = await http.post(uri, headers: await headers0());
    ensureSuccess(res);
    return true;
  }

  // ============== TRANSACTIONS APIS ==============
  Future<Map<String, dynamic>> createTransaction(int orderId) async {
    final uri = Uri.parse('$base/transactions/');
    final res = await http.post(
      uri,
      headers: await headers0(),
      body: jsonEncode({'order_id': orderId}),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Future<List<dynamic>> getAllTransactions() async {
    final uri = Uri.parse('$base/transactions/');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> getTransaction(int txId) async {
    final uri = Uri.parse('$base/transactions/$txId');
    final res = await http.get(uri, headers: await headers0());
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Future<Map<String, dynamic>> updateTransaction(
    int txId,
    String status,
  ) async {
    final uri = Uri.parse('$base/transactions/$txId');
    final res = await http.put(
      uri,
      headers: await headers0(),
      body: jsonEncode({'status': status}),
    );
    ensureSuccess(res);
    final decoded = jsonDecode(res.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }
}
