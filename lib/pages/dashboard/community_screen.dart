import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/review.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';
import 'package:book_hive/main_navigation.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final DatabaseService _db = DatabaseService();
  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;
  bool _showMyReviewsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await _db.getAllReviews();
      setState(() {
        _reviews = reviews.reversed.toList(); // show newest first
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showWriteReviewDialog(List<Book> books) async {
    final email = AuthService().getUserEmail();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to write a review')),
      );
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (ctx) => _WriteReviewDialog(
        books: books,
        email: email,
        db: _db,
        onReviewPublished: _loadReviews,
      ),
    );
  }

  Future<void> _showEditReviewDialog(Review review) async {
    final email = AuthService().getUserEmail();
    if (email == null || email.isEmpty || email != review.email) {
      return;
    }

    int rating = review.rating ?? 5;
    final reviewController = TextEditingController(
      text: review.reviewText ?? '',
    );
    bool saving = false;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Edit Review',
          style: TextStyle(fontSize: 18, color: Colors.deepPurple),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        idx <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = idx),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Update your review',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _db.deleteReviewByUserAndBook(email, review.isbn);
                Navigator.of(ctx).pop(false);
                await _loadReviews();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Review deleted')));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reviewData = {
                'rating': rating,
                if (reviewController.text.trim().isNotEmpty)
                  'review_text': reviewController.text.trim(),
              };

              try {
                await _db.updateReviewByUserAndBook(
                  email,
                  review.isbn,
                  reviewData,
                );
                Navigator.of(ctx).pop(true);
                await _loadReviews();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Review updated')));
              } catch (e) {
                Navigator.of(ctx).pop(false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    reviewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksProvider = BooksProvider.of(context);
    final books = booksProvider.books;
    final currentEmail = AuthService().getUserEmail();

    String getBookTitle(String isbn) {
      try {
        return books.firstWhere((b) => b.isbn == isbn).title;
      } catch (_) {
        return isbn; // fallback to ISBN if book not found
      }
    }

    final displayedReviews = _showMyReviewsOnly && currentEmail != null
        ? _reviews.where((r) => r.email == currentEmail).toList()
        : _reviews;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showMyReviewsOnly ? 'My Reviews' : 'Book Reviews',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _showMyReviewsOnly
                        ? 'Your reviews'
                        : 'Share your thoughts with the community',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  if (currentEmail != null && currentEmail.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _showMyReviewsOnly = !_showMyReviewsOnly,
                      ),
                      icon: Icon(
                        _showMyReviewsOnly ? Icons.person : Icons.people,
                      ),
                      label: Text(
                        _showMyReviewsOnly ? 'All Reviews' : 'My Reviews',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.deepPurple),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showWriteReviewDialog(books),
                    icon: Icon(Icons.add),
                    label: Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Failed to load reviews: $_error'))
          else if (displayedReviews.isEmpty)
            Center(
              child: Text(
                _showMyReviewsOnly
                    ? 'No reviews written yet'
                    : 'No reviews yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: displayedReviews.length,
              itemBuilder: (context, index) {
                final r = displayedReviews[index];
                final initials = r.email.isNotEmpty
                    ? r.email
                          .split('@')
                          .first
                          .split('.')
                          .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
                          .join()
                    : 'U';
                final dateLabel = formatDate(r.createdAt);
                final isMyReview =
                    currentEmail != null && r.email == currentEmail;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(
                                initials,
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.email,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dateLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMyReview)
                              ElevatedButton(
                                onPressed: () => _showEditReviewDialog(r),
                                child: Text("Edit"),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < (r.rating ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Book: ${getBookTitle(r.isbn)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        if (r.reviewText != null)
                          Text(
                            r.reviewText!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              try {
                                final book = await _db.getBook(r.isbn);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IndividualBook(book: book),
                                  ),
                                );
                              } catch (_) {}
                            },
                            child: const Text('View Book'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WriteReviewDialog extends StatefulWidget {
  final List<Book> books;
  final String email;
  final DatabaseService db;
  final VoidCallback onReviewPublished;

  const _WriteReviewDialog({
    required this.books,
    required this.email,
    required this.db,
    required this.onReviewPublished,
  });

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  Book? selectedBook;
  int rating = 5;
  late TextEditingController reviewController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController();
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Write a Review',
        style: TextStyle(fontSize: 18, color: Colors.deepPurple),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book selection dropdown
          DropdownButtonFormField<Book>(
            value: selectedBook,
            hint: const Text('Select a book'),
            items: widget.books
                .map(
                  (b) => DropdownMenuItem<Book>(value: b, child: Text(b.title)),
                )
                .toList(),
            onChanged: (book) => setState(() => selectedBook = book),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Rating selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  idx <= rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => rating = idx),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Review text
          TextField(
            controller: reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving || selectedBook == null
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    final reviewData = {
                      'isbn': selectedBook!.isbn,
                      'rating': rating,
                      if (reviewController.text.trim().isNotEmpty)
                        'review_text': reviewController.text.trim(),
                    };

                    await widget.db.createReview(widget.email, reviewData);
                    if (mounted) {
                      Navigator.of(context).pop(true);
                    }
                    widget.onReviewPublished();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review published')),
                    );
                  } catch (e) {
                    if (mounted) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to publish: $e')),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publish'),
        ),
      ],
    );
  }
}
