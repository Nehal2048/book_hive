import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/review.dart';
import 'package:book_hive/models/user.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';

class ReviewTile extends StatefulWidget {
  final Review r;
  final bool viewBook;

  const ReviewTile({super.key, required this.r, this.viewBook = false});

  @override
  State<ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<ReviewTile> {
  final String currentEmail = AuthService().getUserEmail() ?? '';
  final DatabaseService _db = DatabaseService();
  late User? user;

  @override
  Widget build(BuildContext context) {
    List<Book> books = [];
    if (widget.viewBook) {
      final booksProvider = BooksProvider.of(context);
      books = booksProvider.books;
    }

    String getBookTitle(String isbn) {
      try {
        return books.firstWhere((b) => b.isbn == isbn).title;
      } catch (_) {
        return isbn; // fallback to ISBN if book not found
      }
    }

    DatabaseService().getUserByEmail(currentEmail).then((value) {
      setState(() {
        user = value;
      });
    });

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
                    widget.r.email.isNotEmpty
                        ? widget.r.email
                              .split('@')
                              .first
                              .split('.')
                              .map(
                                (s) => s.isNotEmpty ? s[0].toUpperCase() : '',
                              )
                              .join()
                        : 'U',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.r.email,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatDate(widget.r.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (widget.r.email == currentEmail)
                  ElevatedButton(
                    onPressed: () => _showEditReviewDialog(widget.r),
                    child: Text("Edit"),
                  ),
                SizedBox(width: 8),
                if (user != null &&
                    (user!.userType == "admin" || user!.email == currentEmail))
                  ElevatedButton(
                    onPressed: () {
                      _db
                          .deleteReviewByUserAndBook(
                            widget.r.email,
                            widget.r.isbn,
                          )
                          .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Review deleted')),
                            );
                          })
                          .catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $e')),
                            );
                          });
                    },
                    child: Text("Delete"),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < (widget.r.rating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            if (widget.viewBook) SizedBox(height: 8),
            if (widget.viewBook)
              Text(
                'Book: ${getBookTitle(widget.r.isbn)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 8),
            if (widget.r.reviewText != null)
              Text(
                widget.r.reviewText!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            const SizedBox(height: 8),
            if (widget.viewBook)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    try {
                      final book = await _db.getBook(widget.r.isbn);
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
}
