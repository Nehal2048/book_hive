import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';

class BorrowLendTab extends StatefulWidget {
  const BorrowLendTab({super.key});

  @override
  State<BorrowLendTab> createState() => _BorrowLendTabState();
}

class _BorrowLendTabState extends State<BorrowLendTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<Map<String, dynamic>> _activeBorrowsFuture;
  late Future<List<dynamic>> _borrowListingsFuture;
  late Future<List<dynamic>> _receivedBorrowRequests;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userEmail = _authService.getUserEmail();
    _activeBorrowsFuture = _databaseService.getActiveBorrows(userEmail ?? "");
    _borrowListingsFuture = _databaseService.getListingsByType('borrow');
    _receivedBorrowRequests = _databaseService.getReceivedBorrowRequests(
      userEmail ?? "",
    );
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
        setState(() => _loadData());
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

  Future<void> _acceptBorrowRequest(int listingId, String borrowerId) async {
    try {
      await _databaseService.acceptBorrowRequest(listingId, borrowerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _loadData());
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
            'Borrow & Lend',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Borrow books from your community or lend yours',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          // Stats Row
          FutureBuilder<Map<String, dynamic>>(
            future: _activeBorrowsFuture,
            builder: (context, snapshot) {
              final borrowed = snapshot.data?['borrowed'] ?? 0;
              final lent = snapshot.data?['lent'] ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Borrowed',
                      value: borrowed.toString(),
                      icon: Icons.book,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Lent Out',
                      value: lent.toString(),
                      icon: Icons.volunteer_activism,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Trust Score',
                      value: '4.8',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 32),
          // Borrow Requests Received
          Text(
            'Borrow Requests Received',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: _receivedBorrowRequests,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey[600]),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('Borrow Request #${request['id']}'),
                      subtitle: Text(request['borrower_id'] ?? 'Unknown'),
                      trailing: ElevatedButton(
                        onPressed: () => _acceptBorrowRequest(
                          request['listing_id'],
                          request['borrower_id'],
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
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return Text(
                  'No books available',
                  style: TextStyle(color: Colors.grey[600]),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 70,
                        color: Colors.blue.shade100,
                        child: Icon(Icons.menu_book),
                      ),
                      title: Text(
                        listing is Map
                            ? (listing['isbn'] ?? 'Book ${index + 1}')
                            : 'Book ${index + 1}',
                      ),
                      subtitle: Text(
                        listing is Map
                            ? (listing['condition'] ?? 'Good condition')
                            : 'Available',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _sendBorrowRequest(
                          listing is Map ? listing['id'] : index,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: Text('Borrow'),
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
