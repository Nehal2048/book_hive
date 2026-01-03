import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/borrow.dart';
import 'package:book_hive/models/listing.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/shared/shared_functions.dart';

class BorrowTab extends StatefulWidget {
  const BorrowTab({super.key});

  @override
  State<BorrowTab> createState() => _BorrowTabState();
}

class _BorrowTabState extends State<BorrowTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _borrowListingsFuture;
  late Future<List<Borrow>> _activeBorrowsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _borrowListingsFuture = _databaseService.getListingsByType('borrow');
    _activeBorrowsFuture = _databaseService.getActiveBorrowing(
      _authService.getUserEmail() ?? "",
    );
  }

  void _returnBorrow(String borrowId) async {
    final userEmail = _authService.getUserEmail() ?? "";
    try {
      await _databaseService.returnBorrow(borrowId, userEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book returned successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _loadData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendBorrowRequest(Listing listing, Book mainBook) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Borrow?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to borrow:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${mainBook.title} by ${mainBook.author}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  DatabaseService().sendBorrowRequest(
                    _authService.getUserEmail() ?? "",
                    listing,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Borrow Successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Borrow Books',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Borrow books from your community',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          // Active Borrows (books user has borrowed)
          Text(
            'Your Borrowed Books',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Borrow>>(
            future: _activeBorrowsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final borrowing = snap.data ?? [];

              if (borrowing.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmarks_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have no active borrowed books',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: borrowing.length,
                itemBuilder: (context, i) {
                  final b = borrowing[i];
                  final listingId = b.listingId;

                  return FutureBuilder<Listing>(
                    future: _databaseService.getListing(listingId),
                    builder: (context, lsnap) {
                      if (lsnap.connectionState == ConnectionState.waiting) {
                        return ListTile(title: Text('Loading...'));
                      }
                      if (lsnap.hasError || !lsnap.hasData) {
                        return ListTile(title: Text('Listing not found'));
                      }

                      final listing = lsnap.data!;
                      final book = findBookByIsbn(
                        [],
                        listing.isbn ?? "",
                        context,
                      );

                      return ListTile(
                        leading: book != null
                            ? Image.network(
                                book.coverUrl ?? '',
                                width: 48,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.menu_book_outlined),
                        title: Text(book?.title ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lender: ${b.lender}'),
                            Text('Start: ${formatDate(b.startDate)}'),
                            Text('Due: ${formatDate(b.dueDate)}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _returnBorrow(b.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text('Return'),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Available Books to Borrow
          Text(
            'Available to Borrow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Listing>>(
            future: _borrowListingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<Listing> listings =
                  snapshot.data
                      ?.where(
                        (element) =>
                            element.status == 'available' &&
                            element.sellerId != _authService.getUserEmail(),
                      )
                      .toList() ??
                  [];

              if (listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No books available for borrowing',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];

                  final book = findBookByIsbn([], listing.isbn ?? "", context);

                  if (book == null) {
                    return SizedBox();
                  }

                  if (true) {
                    return GestureDetector(
                      onTap: () => _sendBorrowRequest(listing, book),
                      child: MarketplaceCard(listing: listing),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
