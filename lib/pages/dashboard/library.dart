import 'package:book_hive/services/database.dart';
import 'package:flutter/material.dart';

import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/trash/testData.dart';
import 'package:book_hive/pages/misc/pdf_reader_screen.dart';
import 'package:book_hive/pages/misc/audiobook_screen.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';
import 'package:book_hive/pages/misc/AddPage.dart';
import 'package:book_hive/main_navigation.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // filter / search state
  String _searchQuery = '';
  String _selectedGenre = 'All';
  String _selectedLanguage = 'All';
  String _selectedSort = 'Title A-Z';

  @override
  Widget build(BuildContext context) {
    final booksProvider = BooksProvider.of(context);
    final sourceBooks = booksProvider.books;
    final loading = booksProvider.loading;
    final error = booksProvider.error;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddPage()));
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book created (local only)')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Center(child: Text('Error loading books: $error'))
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

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => IndividualBook(book: book)));
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
                      width: 200 * 0.7,
                      height: 300 * 0.7,
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
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              icon: Icons.category_rounded,
                              label: 'Genre: ${book.genre}',
                            ),
                            _InfoChip(
                              icon: Icons.language,
                              label: 'Language: ${book.language}',
                            ),
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: 'Published: ${book.publishedYear}',
                            ),
                            _InfoChip(
                              icon: Icons.badge,
                              label: 'ISBN: ${book.isbn}',
                            ),
                            _InfoChip(
                              icon: Icons.account_balance,
                              label: 'Publisher: ${book.publisher}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      List<BookDetails> details;
                      try {
                        details = await DatabaseService().getBookDetails(
                          book.isbn,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Book editions not found: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        details = [];
                      }

                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddPage(bookToEdit: book, oldEditions: details),
                        ),
                      );
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
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
