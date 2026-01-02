import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';
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

  late Future<List<dynamic>> _borrowListingsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _borrowListingsFuture = _databaseService.getListingsByType('borrow');
  }

  Future<void> _sendBorrowRequest(int listingId) async {
    try {
      final userEmail = _authService.getUserEmail();
      await _databaseService.sendBorrowRequest(listingId, userEmail ?? "");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Borrow request sent!'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
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
          // Available Books to Borrow
          Text(
            'Available to Borrow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: _borrowListingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final listings = snapshot.data ?? [];
              final currentUserEmail = _authService.getUserEmail();

              // Filter: not created by current user
              final availableListings = listings
                  .where(
                    (listing) =>
                        listing is Map &&
                        listing['seller_email'] != currentUserEmail,
                  )
                  .toList();

              if (availableListings.isEmpty) {
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

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: availableListings.length,
                itemBuilder: (context, index) {
                  final listing = availableListings[index];
                  final isbn = listing['isbn'] ?? '';
                  final condition = listing['condition'] ?? 'Good';

                  final book = findBookByIsbn([], isbn, context);

                  if (book == null) {
                    return SizedBox();
                  }

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 70,
                        color: Colors.blue.shade100,
                        child: book.coverUrl.isNotEmpty
                            ? Image.network(book.coverUrl, fit: BoxFit.cover)
                            : Icon(Icons.menu_book),
                      ),
                      title: Text(book.title),
                      subtitle: Text('Condition: $condition'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _sendBorrowRequest(listing['id'] ?? 0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: Text('Borrow'),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.open_in_new),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      IndividualBook(book: book),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
