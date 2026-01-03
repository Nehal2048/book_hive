import 'dart:convert';

import 'package:book_hive/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/services/database.dart';

class AddPage extends StatefulWidget {
  final Book? bookToEdit;
  final List<BookDetails>? oldEditions;

  const AddPage({super.key, this.bookToEdit, this.oldEditions});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();
  final _genreCtrl = TextEditingController();
  final _languageCtrl = TextEditingController();
  final _publisherCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  final List<BookDetailsEntry> _details = [];
  bool _lookingUp = false;
  bool _submitting = false;
  late bool _isEditMode;
  // local editable copies of old editions
  final List<BookDetails> _oldEditions = [];
  final List<_OldEditionEntry> _oldEditionEntries = [];
  final Set<int> _savingOld = {};

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.bookToEdit != null;
    if (_isEditMode && widget.bookToEdit != null) {
      final book = widget.bookToEdit!;
      _titleCtrl.text = book.title;
      _authorCtrl.text = book.author;
      _isbnCtrl.text = book.isbn;
      _summaryCtrl.text = book.summary;
      _coverUrlCtrl.text = book.coverUrl;
      _genreCtrl.text = book.genre;
      _languageCtrl.text = book.language;
      _publisherCtrl.text = book.publisher;
      _yearCtrl.text = book.publishedYear.toString();
      // initialize old editions entries if provided
      if (widget.oldEditions != null) {
        _oldEditions.addAll(widget.oldEditions!);
        for (var d in _oldEditions) {
          _oldEditionEntries.add(
            _OldEditionEntry(
              edition: d.edition,
              pdfCtrl: TextEditingController(text: d.pdfLink),
              audioCtrl: TextEditingController(text: d.audioUrl),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _isbnCtrl.dispose();
    _summaryCtrl.dispose();
    _coverUrlCtrl.dispose();
    _genreCtrl.dispose();
    _languageCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    for (var d in _details) {
      d.dispose();
    }
    for (var e in _oldEditionEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addDetail() {
    setState(() {
      _details.add(BookDetailsEntry());
    });
  }

  Future<void> _saveOldEdition(int i) async {
    if (i < 0 || i >= _oldEditions.length) return;
    setState(() => _savingOld.add(i));
    try {
      final isbn = _isbnCtrl.text.trim();
      final entry = _oldEditionEntries[i];
      final db = DatabaseService();
      final updated = await db.updateBookDetail(
        isbn: isbn,
        email: AuthService().getUserEmail() ?? "",
        detail: BookDetails(
          isbn: isbn,
          edition: _oldEditions[i].edition,
          pdfLink: entry.pdfCtrl.text.trim(),
          audioUrl: entry.audioCtrl.text.trim(),
        ),
      );
      // update local copy
      _oldEditions[i] = updated;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edition updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _savingOld.remove(i));
    }
  }

  Future<void> _deleteOldEdition(int i) async {
    if (i < 0 || i >= _oldEditions.length) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Edition',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text('Are you sure you want to delete this edition?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final isbn = _isbnCtrl.text.trim();
      final edition = _oldEditionEntries[i].edition;
      final db = DatabaseService();
      await db.deleteBookDetail(
        isbn,
        edition,
        AuthService().getUserEmail() ?? "",
      );
      setState(() {
        _oldEditions.removeAt(i);
        _oldEditionEntries.removeAt(i);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edition deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _uploadEditions() async {
    if (_details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No new editions to upload')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final isbn = _isbnCtrl.text.trim();
      final db = DatabaseService();
      for (var e in _details) {
        final detail = BookDetails(
          isbn: isbn,
          edition: e.editionCtrl.text.trim(),
          pdfLink: e.pdfCtrl.text.trim(),
          audioUrl: e.audioCtrl.text.trim(),
        );
        await db.addBookLink(
          isbn,
          detail.toJson(),
          email: AuthService().getUserEmail(),
        );
        widget.oldEditions!.add(detail);
      }
      setState(() => _details.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Editions uploaded')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading editions: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _removeDetail(int i) {
    setState(() {
      _details.removeAt(i);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final title = _titleCtrl.text.trim();
      final author = _authorCtrl.text.trim();
      final isbn = _isbnCtrl.text.trim();
      final summary = _summaryCtrl.text.trim();
      final coverUrl = _coverUrlCtrl.text.trim();
      final genre = _genreCtrl.text.trim();
      final language = _languageCtrl.text.trim();
      final publisher = _publisherCtrl.text.trim();
      final year = int.tryParse(_yearCtrl.text.trim()) ?? 0;

      final book = Book(
        title: title,
        author: author,
        isbn: isbn,
        summary: summary,
        coverUrl: coverUrl,
        genre: genre,
        language: language,
        publisher: publisher,
        publishedYear: year,
      );

      // Upload or update book only (editions are handled separately)
      final db = DatabaseService();
      if (_isEditMode) {
        await db.updateBook(
          book.isbn,
          book.toJson(),
          AuthService().getUserEmail() ?? "",
        );
      } else {
        await db.addBook(book.toJson(), email: AuthService().getUserEmail());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book uploaded successfully')),
        );
        Navigator.of(context).pop({'book': book});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _lookupISBN() async {
    final isbn = _isbnCtrl.text.trim();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter ISBN first')));
      return;
    }

    setState(() => _lookingUp = true);
    try {
      final url =
          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        throw Exception('Lookup failed: ${resp.statusCode}');
      }
      final Map<String, dynamic> data = json.decode(resp.body);
      final key = 'ISBN:$isbn';
      if (!data.containsKey(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found for this ISBN')),
        );
        return;
      }
      final info = data[key] as Map<String, dynamic>;

      // Title
      final title = info['title'] as String? ?? '';
      _titleCtrl.text = title;

      // Authors
      final authors = info['authors'] as List<dynamic>?;
      if (authors != null && authors.isNotEmpty) {
        final names = authors
            .map((a) => (a as Map<String, dynamic>)['name'] as String?)
            .whereType<String>()
            .toList();
        if (names.isNotEmpty) _authorCtrl.text = names.join(', ');
      }

      // Summary / notes or excerpts
      String summary = '';
      if (info.containsKey('notes')) {
        final n = info['notes'];
        if (n is String) {
          summary = n;
        } else if (n is Map && n.containsKey('value'))
          summary = n['value'] as String;
      }
      if (summary.isEmpty && info.containsKey('excerpts')) {
        final ex = info['excerpts'] as List<dynamic>?;
        if (ex != null && ex.isNotEmpty) {
          final first = ex.first as Map<String, dynamic>?;
          if (first != null && first.containsKey('text')) {
            summary = first['text'] as String;
          }
        }
      }
      if (summary.isNotEmpty) _summaryCtrl.text = summary;

      // Cover
      final cover = info['cover'] as Map<String, dynamic>?;
      if (cover != null) {
        _coverUrlCtrl.text =
            (cover['large'] ?? cover['medium'] ?? cover['small']) as String? ??
            '';
      }

      // Publishers
      final pubs = info['publishers'] as List<dynamic>?;
      if (pubs != null && pubs.isNotEmpty) {
        final p0 = (pubs.first as Map<String, dynamic>)['name'] as String?;
        if (p0 != null) _publisherCtrl.text = p0;
      }

      // Publish year (try to extract four-digit year from publish_date)
      final pd = info['publish_date'] as String?;
      if (pd != null) {
        final match = RegExp(r'\d{4}').firstMatch(pd);
        if (match != null) _yearCtrl.text = match.group(0)!;
      }

      // Subjects as genre
      final subjects = info['subjects'] as List<dynamic>?;
      if (subjects != null && subjects.isNotEmpty) {
        final s0 = (subjects.first as Map<String, dynamic>)['name'] as String?;
        if (s0 != null) _genreCtrl.text = s0;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lookup error: $e')));
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Book' : 'Add Book')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _isbnCtrl,
                  decoration: const InputDecoration(labelText: 'ISBN'),
                  enabled: !_isEditMode,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _lookingUp ? null : _lookupISBN,
                      icon: _lookingUp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Lookup ISBN'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Container()),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _summaryCtrl,
                  decoration: const InputDecoration(labelText: 'Summary'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _coverUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Cover URL'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _genreCtrl,
                        decoration: const InputDecoration(labelText: 'Genre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _languageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _publisherCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Publisher',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Saving...'),
                          ],
                        )
                      : Text(_isEditMode ? 'Update Book' : 'Save Book'),
                ),
                const SizedBox(height: 16),
                if (_oldEditionEntries.isNotEmpty) ...[
                  const Text(
                    'Previous Editions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._oldEditionEntries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final old = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Edition ${old.edition}'),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _savingOld.contains(i)
                                          ? null
                                          : () => _saveOldEdition(i),
                                      child: _savingOld.contains(i)
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => _deleteOldEdition(i),
                                      child: const Text('  Delete  '),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: old.edition,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Edition',
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: old.pdfCtrl,
                              decoration: const InputDecoration(
                                labelText: 'PDF Link',
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: old.audioCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Audio URL',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                Text(
                  _isEditMode
                      ? 'Edit or Add New Editions'
                      : 'Book Details / Editions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._details.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Edition ${i + 1}'),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeDetail(i),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: item.editionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Edition',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: item.pdfCtrl,
                            decoration: const InputDecoration(
                              labelText: 'PDF Link',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: item.audioCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Audio URL',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addDetail,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Edition'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _uploadEditions,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Editions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookDetailsEntry {
  final TextEditingController editionCtrl = TextEditingController();
  final TextEditingController pdfCtrl = TextEditingController();
  final TextEditingController audioCtrl = TextEditingController();

  void dispose() {
    editionCtrl.dispose();
    pdfCtrl.dispose();
    audioCtrl.dispose();
  }
}

class _OldEditionEntry {
  final String edition;
  final TextEditingController pdfCtrl;
  final TextEditingController audioCtrl;

  _OldEditionEntry({
    required this.edition,
    required this.pdfCtrl,
    required this.audioCtrl,
  });

  void dispose() {
    pdfCtrl.dispose();
    audioCtrl.dispose();
  }
}
