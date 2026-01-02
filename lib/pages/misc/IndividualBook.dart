import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/pages/misc/review_tile.dart';
import 'package:book_hive/shared/const.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/services/ai_service.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/review.dart';
import 'package:book_hive/pages/misc/pdf_reader_screen.dart';
import 'package:book_hive/pages/misc/audiobook_screen.dart';

class IndividualBook extends StatefulWidget {
  final Book book;

  const IndividualBook({required this.book, super.key});

  @override
  State<IndividualBook> createState() => _IndividualBookState();
}

class _IndividualBookState extends State<IndividualBook> {
  final DatabaseService _db = DatabaseService();
  List<BookDetails> _details = [];
  bool _loadingDetails = true;
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  String? _reviewsError;
  String? _aiReport;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
      _reviewsError = null;
    });
    try {
      final reviews = await _db.getReviewsByBook(widget.book.isbn);
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      setState(() {
        _reviewsError = e.toString();
      });
    } finally {
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  Future<void> _showReviewDialog({Review? existing}) async {
    final email = AuthService().getUserEmail();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add a review')),
      );
      return;
    }

    int rating = existing?.rating ?? 5;
    final controller = TextEditingController(text: existing?.reviewText ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Add Review' : 'Edit Review',
          style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
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
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a short review (optional)',
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop(false);
                try {
                  await _db.deleteReviewByUserAndBook(email, widget.book.isbn);
                  await _loadReviews();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reviewData = {
                'isbn': widget.book.isbn,
                'rating': rating,
                if (controller.text.trim().isNotEmpty)
                  'review_text': controller.text.trim(),
              };

              try {
                if (existing == null) {
                  await _db.createReview(email, reviewData);
                } else {
                  await _db.updateReviewByUserAndBook(
                    email,
                    widget.book.isbn,
                    reviewData,
                  );
                }
                Navigator.of(ctx).pop(true);
                await _loadReviews();
              } catch (e) {
                Navigator.of(ctx).pop(false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // refreshed already
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loadingDetails = true;
      _error = null;
    });
    try {
      final details = await _db.getBookDetails(widget.book.isbn);
      setState(() {
        _details = details;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingDetails = false;
      });
    }
  }

  Future<void> _generateAiReport() async {
    setState(() {
      _generating = true;
    });

    final aiService = AIBookService(apiKey: apiKeyAI);

    try {
      final summary = await aiService.generateReport(widget.book);
      print(summary);
      setState(() {
        _aiReport = summary;
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _generating = false;
      });
    }
  }

  Widget _buildFormattedAIReport(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Section
          _buildReportSection(
            title: 'Summary',
            icon: Icons.description,
            content: data['summary'] ?? 'N/A',
            isText: true,
          ),
          const SizedBox(height: 16),

          // Key Takeaways Section
          _buildReportSection(
            title: 'Key Takeaways',
            icon: Icons.lightbulb,
            content: data['key_takeaways'] ?? [],
            isList: true,
          ),
          const SizedBox(height: 16),

          // Similar Books Section
          _buildReportSection(
            title: 'Similar Books',
            icon: Icons.auto_stories,
            content: data['similar_books'] ?? [],
            isList: true,
          ),
          const SizedBox(height: 16),

          // AI Review Section
          _buildReportSection(
            title: 'AI Review',
            icon: Icons.star,
            content: data['ai_review'] ?? 'N/A',
            isText: true,
          ),
          const SizedBox(height: 16),

          // Actionable Advice Section
          _buildReportSection(
            title: 'Actionable Advice',
            icon: Icons.check_circle,
            content: data['actionable_advice'] ?? [],
            isList: true,
          ),
        ],
      );
    } catch (e) {
      return Text(
        'Could not parse AI report: $e',
        style: TextStyle(color: Colors.red[600]),
      );
    }
  }

  Widget _buildReportSection({
    required String title,
    required IconData icon,
    required dynamic content,
    bool isText = false,
    bool isList = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isText)
              Text(
                content ?? 'N/A',
                style: TextStyle(color: Colors.grey[800], height: 1.6),
              )
            else if (isList && content is List)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (content).asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Text('N/A', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = AuthService().getUserEmail();
    final List<Review> displayReviews = List<Review>.from(_reviews);

    if (currentEmail != null && currentEmail.isNotEmpty) {
      final idx = displayReviews.indexWhere((r) => r.email == currentEmail);
      if (idx > 0) {
        final my = displayReviews.removeAt(idx);
        displayReviews.insert(0, my);
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2 * 1.5,
                    child: widget.book.coverUrl.isNotEmpty
                        ? Image.network(widget.book.coverUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.deepPurple.shade50,
                            child: Center(
                              child: Text(
                                widget.book.title.isNotEmpty
                                    ? widget.book.title
                                          .trim()
                                          .split(' ')
                                          .take(2)
                                          .map((w) => w[0].toUpperCase())
                                          .join()
                                    : 'BK',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.book.author,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text("Genre: ${widget.book.genre}"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.badge,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('ISBN: ${widget.book.isbn}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Published: ${widget.book.publishedYear}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Publisher: ${widget.book.publisher}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.summary,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Resources',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_loadingDetails)
                        const Center(child: CircularProgressIndicator())
                      else if (_details.isEmpty)
                        Text('No additional resources available')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _details.length,
                          itemBuilder: (context, index) {
                            final detail = _details[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.edition.isNotEmpty
                                          ? 'Edition: ${detail.edition}'
                                          : 'Edition ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (detail.pdfLink.isNotEmpty)
                                          ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                            ),
                                            label: const Text('Open PDF'),
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PdfReaderScreen(
                                                          bookDetails: detail,
                                                          book: widget.book,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        if (detail.audioUrl.isNotEmpty)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.headphones),
                                            label: const Text('Play Audio'),
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AudiobookScreen(
                                                          book: widget.book,
                                                          bookDetails: detail,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        if (detail.pdfLink.isEmpty &&
                                            detail.audioUrl.isEmpty)
                                          Text(
                                            'No resources available',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      Divider(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Generate AI Report'),
                  onPressed: _generating ? null : _generateAiReport,
                ),
                const SizedBox(width: 12),
                if (_generating) const CircularProgressIndicator(),
              ],
            ),
            if (_aiReport != null) ...[
              const SizedBox(height: 16),
              Text('AI Report', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildFormattedAIReport(_aiReport!),
            ],
            const SizedBox(height: 8),
            Divider(),

            // Average Rating Sectionconst SizedBox(height: 20),
            Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (!_loadingReviews && _reviews.isNotEmpty)
              Builder(
                builder: (ctx) {
                  final ratingsWithValue = _reviews
                      .where((r) => r.rating != null)
                      .map((r) => r.rating!)
                      .toList();
                  if (ratingsWithValue.isEmpty) {
                    return SizedBox.shrink();
                  }
                  final avgRating =
                      ratingsWithValue.fold<double>(
                        0,
                        (sum, rating) => sum + rating,
                      ) /
                      ratingsWithValue.length;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Community Rating',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < avgRating.floor()
                                                ? Icons.star
                                                : i < avgRating
                                                ? Icons.star_half
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 18,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${ratingsWithValue.length} ${ratingsWithValue.length == 1 ? 'rating' : 'ratings'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            // Add / Edit button for current user
            Builder(
              builder: (ctx) {
                final email = currentEmail;
                final myIndex = email == null
                    ? -1
                    : displayReviews.indexWhere((r) => r.email == email);
                if (email == null || email.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign in to add a review'),
                            ),
                          ),
                      icon: const Icon(Icons.add),
                      label: const Text('Sign in to review'),
                    ),
                  );
                }
                if (myIndex == -1) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Review'),
                      onPressed: () => _showReviewDialog(),
                    ),
                  );
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit My Review'),
                    onPressed: () =>
                        _showReviewDialog(existing: displayReviews[myIndex]),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (_loadingReviews)
              const Center(child: CircularProgressIndicator())
            else if (_reviewsError != null)
              Text('Failed to load reviews: $_reviewsError')
            else if (displayReviews.isEmpty)
              Text('No reviews yet', style: TextStyle(color: Colors.grey[600]))
            else
              Column(
                children: displayReviews.map((r) {
                  final initials = r.email.isNotEmpty
                      ? r.email
                            .split('@')
                            .first
                            .split('.')
                            .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
                            .join()
                      : 'U';
                  final dateLabel = r.createdAt
                      .toIso8601String()
                      .split('T')
                      .first;
                  return ReviewTile(r: r, viewBook: false);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
