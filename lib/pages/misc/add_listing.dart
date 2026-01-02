import 'package:book_hive/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';

class AddListingPage extends StatefulWidget {
  final List<Book> books;

  const AddListingPage({super.key, required this.books});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  late TextEditingController _searchController;
  late TextEditingController _priceController;
  late TextEditingController _exchangeSearchController;

  String? _selectedIsbn;
  Book? _selectedBook;
  String? _selectedExchangeIsbn;
  Book? _selectedExchangeBook;
  String? _selectedListingType;
  String? _selectedCondition;
  bool _isLoading = false;
  List<Book> _searchResults = [];
  List<Book> _exchangeSearchResults = [];

  final List<String> _listingTypes = ['sale', 'borrow', 'exchange'];
  final List<String> _conditions = ['new', 'good', 'fair'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _priceController = TextEditingController();
    _exchangeSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceController.dispose();
    _exchangeSearchController.dispose();
    super.dispose();
  }

  void _searchBooks(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final queryLower = query.toLowerCase();
    final results = widget.books
        .where(
          (book) =>
              book.title.toLowerCase().contains(queryLower) ||
              book.author.toLowerCase().contains(queryLower),
        )
        .toList();

    setState(() => _searchResults = results);
  }

  void _selectBook(Book book) {
    setState(() {
      _selectedBook = book;
      _selectedIsbn = book.isbn;
      _searchResults = [];
      _searchController.text = '${book.title} - ${book.author}';
    });
  }

  void _searchExchangeBooks(String query) {
    if (query.isEmpty) {
      setState(() => _exchangeSearchResults = []);
      return;
    }

    final queryLower = query.toLowerCase();
    final results = widget.books
        .where(
          (book) =>
              book.title.toLowerCase().contains(queryLower) ||
              book.author.toLowerCase().contains(queryLower),
        )
        .toList();

    setState(() => _exchangeSearchResults = results);
  }

  void _selectExchangeBook(Book book) {
    setState(() {
      _selectedExchangeBook = book;
      _selectedExchangeIsbn = book.isbn;
      _exchangeSearchResults = [];
      _exchangeSearchController.text = '${book.title} - ${book.author}';
    });
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIsbn == null || _selectedIsbn!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a book')));
      return;
    }

    if (_selectedListingType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a listing type')));
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a condition')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final listingData = {
        'isbn': _selectedIsbn,
        'price': double.parse(_priceController.text),
        'listing_type': _selectedListingType,
        'condition': _selectedCondition,
      };

      // For exchange listings, add the requested book's ISBN to request_id
      if (_selectedListingType == 'exchange') {
        if (_selectedExchangeIsbn == null || _selectedExchangeIsbn!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select a book to exchange for'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        listingData['request_id'] = _selectedExchangeIsbn;
      }

      final listing = await _databaseService.createListing(
        listingData,
        sellerId: AuthService().getUserEmail() ?? "",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, listing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Listing'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 16),
              // Book Search Field
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Book',
                  hintText: 'Enter book title or author',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _selectedBook != null
                      ? IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedBook = null;
                              _selectedIsbn = null;
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: _searchBooks,
                validator: (value) {
                  if (_selectedIsbn == null || _selectedIsbn!.isEmpty) {
                    return 'Please select a book';
                  }
                  return null;
                },
              ),
              // Search Results
              if (_searchResults.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final book = _searchResults[index];
                      return ListTile(
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        trailing: Text(
                          book.isbn,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () => _selectBook(book),
                        tileColor: index.isEven
                            ? Colors.grey.shade50
                            : Colors.white,
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  hintText: 'Enter price (0 for borrow/exchange)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  try {
                    double.parse(value);
                  } catch (_) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                'Listing Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 16),
              // Selected Book Info
              if (_selectedBook != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IndividualBook(book: _selectedBook!),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Book',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _selectedBook!.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'by ${_selectedBook!.author}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),
              // Listing Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedListingType,
                decoration: InputDecoration(
                  labelText: 'Listing Type',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                hint: Text('Select listing type'),
                items: _listingTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type[0].toUpperCase() + type.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedListingType = value;
                    // Reset exchange fields when changing listing type
                    if (value != 'exchange') {
                      _selectedExchangeBook = null;
                      _selectedExchangeIsbn = null;
                      _exchangeSearchController.clear();
                      _exchangeSearchResults = [];
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a listing type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Exchange Book Selection (only shown when listing type is 'exchange')
              if (_selectedListingType == 'exchange') ...[
                TextFormField(
                  controller: _exchangeSearchController,
                  decoration: InputDecoration(
                    labelText: 'Book You Want to Exchange For',
                    hintText: 'Search for the book you want',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _selectedExchangeBook != null
                        ? IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedExchangeBook = null;
                                _selectedExchangeIsbn = null;
                                _exchangeSearchController.clear();
                                _exchangeSearchResults = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: _searchExchangeBooks,
                ),
                // Exchange Search Results
                if (_exchangeSearchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _exchangeSearchResults.length,
                      itemBuilder: (context, index) {
                        final book = _exchangeSearchResults[index];
                        return ListTile(
                          title: Text(book.title),
                          subtitle: Text(book.author),
                          trailing: Text(
                            book.isbn,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _selectExchangeBook(book),
                          tileColor: index.isEven
                              ? Colors.grey.shade50
                              : Colors.white,
                        );
                      },
                    ),
                  ),
                // Selected Exchange Book Info
                if (_selectedExchangeBook != null)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requesting',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _selectedExchangeBook!.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
              ]
              // Condition Dropdown
              else
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: InputDecoration(
                    labelText: 'Book Condition',
                    prefixIcon: Icon(Icons.check_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: Text('Select condition'),
                  items: _conditions.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(
                        condition[0].toUpperCase() + condition.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCondition = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a condition';
                    }
                    return null;
                  },
                ),
              SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitListing,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.upload),
                  label: Text(
                    _isLoading ? 'Creating Listing...' : 'Create Listing',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
