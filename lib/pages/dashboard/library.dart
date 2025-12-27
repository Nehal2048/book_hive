import 'package:flutter/material.dart';

import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/trash/testData.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/pages/dashboard/pdf_reader_screen.dart';
import 'package:book_hive/pages/dashboard/audiobook_screen.dart';
import 'package:book_hive/services/ai_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  // filter / search state
  String _searchQuery = '';
  String _selectedGenre = 'All';
  String _selectedLanguage = 'All';
  String _selectedSort = 'Title A-Z';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _db.getBooks();
      setState(() {
        _books = books;
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

  @override
  Widget build(BuildContext context) {
    final sourceBooks = _books;
    final genres = [
      'All',
      ...{for (final b in sourceBooks) b.genre},
    ];
    final languages = [
      'All',
      ...{for (final b in sourceBooks) b.language},
      'Spanish',
      'French',
      'German',
    ];

    List<Book> applyFilters() {
      final q = _searchQuery.toLowerCase();

      List<Book> filtered = sourceBooks.where((book) {
        final matchesQuery =
            q.isEmpty ||
            book.title.toLowerCase().contains(q) ||
            book.isbn.toLowerCase().contains(q) ||
            book.author.toLowerCase().contains(q) ||
            book.genre.toLowerCase().contains(q) ||
            book.language.toLowerCase().contains(q) ||
            book.publisher.toLowerCase().contains(q) ||
            book.publishedYear.toString().contains(q);

        final matchesGenre =
            _selectedGenre == 'All' ||
            book.genre.toLowerCase() == _selectedGenre.toLowerCase();
        final matchesLanguage =
            _selectedLanguage == 'All' ||
            book.language.toLowerCase() == _selectedLanguage.toLowerCase();

        return matchesQuery && matchesGenre && matchesLanguage;
      }).toList();

      switch (_selectedSort) {
        case 'Title Z-A':
          filtered.sort((a, b) => b.title.compareTo(a.title));
          break;
        case 'Newest First':
          filtered.sort((a, b) => b.publishedYear.compareTo(a.publishedYear));
          break;
        case 'Oldest First':
          filtered.sort((a, b) => a.publishedYear.compareTo(b.publishedYear));
          break;
        default:
          filtered.sort((a, b) => a.title.compareTo(b.title));
      }
      return filtered;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error loading books: $_error'))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Search by title, ISBN, author, genre, language, publisher, year',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterDropdown(
                    label: 'Genre',
                    value: _selectedGenre,
                    items: genres,
                    width: 200,
                    onChanged: (val) {
                      setState(() {
                        _selectedGenre = val;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _FilterDropdown(
                    label: 'Language',
                    value: _selectedLanguage,
                    items: languages,
                    onChanged: (val) {
                      setState(() {
                        _selectedLanguage = val;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _FilterDropdown(
                    label: 'Sort',
                    value: _selectedSort,
                    items: const [
                      'Title A-Z',
                      'Title Z-A',
                      'Newest First',
                      'Oldest First',
                    ],
                    width: 200,
                    onChanged: (val) {
                      setState(() {
                        _selectedSort = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final books = applyFilters();
                    return books.isEmpty
                        ? const Center(
                            child: Text('No books found with current filters'),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 260,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return _BookCard(book: book);
                            },
                          );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final double width;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: items
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}

class _SummarySheet extends StatefulWidget {
  final Book book;

  const _SummarySheet({required this.book});

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  late Future<String> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = AiService.generateSummary(widget.book);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Summary',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Summary Content
              Expanded(
                child: FutureBuilder<String>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Generating AI summary...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error generating summary',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No summary available',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.6, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.bookmark_add),
                          label: const Text('Save to Reading List'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${widget.book.title} added to reading list',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    BookDetails? details;
    try {
      details = fakeBookDetails.firstWhere((d) => d.isbn == book.isbn);
    } catch (_) {
      details = null;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _SummarySheet(book: book),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
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
                      width: 70,
                      height: 100,
                      child: book.coverUrl.isNotEmpty
                          ? Image.network(
                              book.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _CoverPlaceholder(title: book.title),
                            )
                          : _CoverPlaceholder(title: book.title),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(book.genre),
                          backgroundColor: Colors.deepPurple.shade50,
                          labelStyle: const TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Top-right: PDF/Audio links if available
                  if (details != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (details.pdfLink.isNotEmpty)
                          _LinkChip(
                            icon: Icons.picture_as_pdf,
                            label: 'PDF',
                            url: details.pdfLink,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PdfReaderScreen(
                                    bookDetails: details!,
                                    book: book,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (details.audioUrl.isNotEmpty)
                          _LinkChip(
                            icon: Icons.headphones,
                            label: 'Audio',
                            url: details.audioUrl,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AudiobookScreen(
                                    book: book,
                                    bookDetails: details!,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                book.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              if (details != null && details.edition.isNotEmpty) ...[
                _InfoChip(
                  icon: Icons.layers,
                  label: 'Edition: ${details.edition}',
                ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.language,
                    label: 'Language: ${book.language}',
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Published: ${book.publishedYear}',
                  ),
                  _InfoChip(icon: Icons.badge, label: 'ISBN: ${book.isbn}'),
                  _InfoChip(
                    icon: Icons.account_balance,
                    label: 'Publisher: ${book.publisher}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.deepPurple),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final VoidCallback? onPressed;

  const _LinkChip({
    required this.icon,
    required this.label,
    required this.url,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.deepPurple),
      label: Text(label),
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          // Placeholder: in a real app, use url_launcher to open the link.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Open link: $url')));
        }
      },
      backgroundColor: Colors.deepPurple.shade50,
      labelStyle: const TextStyle(color: Colors.deepPurple),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;

  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    final initials = title.isNotEmpty
        ? title.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'BK';
    return Container(
      color: Colors.deepPurple.shade50,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }
}
