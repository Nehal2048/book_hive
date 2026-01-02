import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/listing.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:book_hive/pages/misc/add_listing.dart';

class MyListing extends StatefulWidget {
  const MyListing({super.key});

  @override
  State<MyListing> createState() => _MyListingState();
}

class _MyListingState extends State<MyListing> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _listingsFuture;
  late Future<List<dynamic>> _borrowRequestsFuture;
  late Future<List<dynamic>> _exchangeRequestsFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    final userEmail = _authService.getUserEmail() ?? "";
    _listingsFuture = _databaseService.getListingsByUser(userEmail);
    _borrowRequestsFuture = _databaseService.getReceivedBorrowRequests(
      userEmail,
    );
    _exchangeRequestsFuture = _databaseService.getReceivedExchangeRequests(
      userEmail,
    );
  }

  Future<void> _deleteListing(int listingId, String? status) async {
    if (status == 'sold') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete sold listings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Listing', style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updated = await _databaseService.deleteListing(
                  listingId,
                  AuthService().getUserEmail() ?? "",
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Listing updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, updated);
                }
              } catch (e) {
                rethrow;
              }
              Navigator.pop(context, true);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.updateListing(listingId, {'status': 'deleted'});
        if (mounted) {
          setState(() => _loadListings());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Listing deleted'),
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
  }

  Future<void> _acceptBorrowRequest(int listingId, String borrowerId) async {
    try {
      await _databaseService.acceptBorrowRequest(listingId, borrowerId);
      if (mounted) {
        setState(() => _loadListings());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Borrow request accepted!'),
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

  Future<void> _acceptExchangeRequest(int listingId, String userId) async {
    try {
      await _databaseService.acceptExchangeRequest(listingId, userId);
      if (mounted) {
        setState(() => _loadListings());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exchange request accepted!'),
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
      child: FutureBuilder<List<Listing>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final listings = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Listings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Manage your books and view requests',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              // =============== MY LISTINGS SECTION ===============
              Text(
                'Active for Selling',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              buildListingList(
                listings
                    .where(
                      (l) => l.status == 'available' && l.listingType == 'sale',
                    )
                    .toList(),
              ),
              SizedBox(height: 32),
              Text(
                'Active for Borrowing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              buildListingList(
                listings
                    .where(
                      (l) =>
                          l.status == 'available' && l.listingType == 'borrow',
                    )
                    .toList(),
              ),
              SizedBox(height: 32),
              Text(
                'Active for Exchanging',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              buildListingList(
                listings
                    .where(
                      (l) =>
                          l.status == 'available' &&
                          l.listingType == 'exchange',
                    )
                    .toList(),
              ),
              SizedBox(height: 32),
              Text(
                'Completed Listings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              buildListingList(
                listings.where((l) => l.status == 'sold').toList(),
              ),
              SizedBox(height: 32),
              // =============== BORROW REQUESTS SECTION ===============
              Text(
                'Borrow Requests Received',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: _borrowRequestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      child: Text(
                        'No borrow requests',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isbn = request['isbn'] ?? '';
                      final book = findBookByIsbn([], isbn, context);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        color: Colors.blue.shade50,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 70,
                            color: Colors.blue.shade100,
                            child: Icon(Icons.people),
                          ),
                          title: Text(
                            'Borrow Request - ${book?.title ?? 'Unknown Book'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'From: ${request['borrower_id'] ?? 'Unknown'}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _acceptBorrowRequest(
                              request['listing_id'] ?? 0,
                              request['borrower_id'] ?? '',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text('Accept'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 32),
              // =============== EXCHANGE REQUESTS SECTION ===============
              Text(
                'Exchange Requests Received',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: _exchangeRequestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      child: Text(
                        'No exchange requests',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isbn = request['isbn'] ?? '';
                      final book = findBookByIsbn([], isbn, context);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 70,
                            color: Colors.orange.shade100,
                            child: Icon(Icons.swap_horiz),
                          ),
                          title: Text(
                            'Exchange Request - ${book?.title ?? 'Unknown Book'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From: ${request['sender_id'] ?? 'Unknown'}',
                              ),
                              Text(
                                'Requesting: ${request['requested_book'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _acceptExchangeRequest(
                              request['your_listing_id'] ?? 0,
                              request['sender_id'] ?? '',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: Text('Accept'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  buildListingList(List<Listing> listingsFuture) {
    // return FutureBuilder<List<Listing>>(
    //   future: listingsFuture,
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return Center(child: CircularProgressIndicator());
    //     }
    //     if (snapshot.hasError) {
    //       return Center(child: Text('Error: ${snapshot.error}'));
    //     }
    //   }
    // final listings = snapshot.data ?? [];
    // final activeListing = listings
    //     .where((l) => l.status != 'sold')
    //     .toList();

    if (listingsFuture.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No active listings',
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
      itemCount: listingsFuture.length,
      itemBuilder: (context, index) {
        final listing = listingsFuture[index];
        final book = findBookByIsbn([], listing.isbn ?? "", context);

        if (book == null) {
          return SizedBox();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 70,
              color: Colors.deepPurple.shade100,
              child: book.coverUrl.isNotEmpty
                  ? Image.network(book.coverUrl, fit: BoxFit.cover)
                  : Icon(Icons.book),
            ),
            title: Text(book.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${listing.listingType?.toUpperCase() ?? 'SALE'}'),
                Text('Condition: ${listing.condition?.toUpperCase() ?? 'N/A'}'),
                Text(
                  'Tk. ${listing.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (listing.status == 'available')
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddListingPage(
                            books: [],
                            existingListing: listing,
                          ),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() => _loadListings());
                      }
                    },
                  ),
                if (listing.status == 'available')
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteListing(listing.id, listing.status),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
