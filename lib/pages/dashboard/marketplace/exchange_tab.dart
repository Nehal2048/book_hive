import 'package:book_hive/models/book.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/listing.dart';

class ExchangeTab extends StatefulWidget {
  const ExchangeTab({super.key});

  @override
  State<ExchangeTab> createState() => _ExchangeTabState();
}

class _ExchangeTabState extends State<ExchangeTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _exchangeListingsFuture;
  late Future<List<dynamic>> _userExchangesFuture;

  @override
  void initState() {
    super.initState();
    _exchangeListingsFuture = _databaseService.getListingsByType('exchange');
    _userExchangesFuture = _databaseService.getUserExchanges(
      _authService.getUserEmail() ?? "",
    );
  }

  Future<void> _sendExchangeRequest(int listingId) async {
    try {
      final userEmail = _authService.getUserEmail();
      await _databaseService.sendExchangeRequest(listingId, userEmail.hashCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exchange request sent!'),
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
            'Exchange Books',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Swap books with other readers',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Available for Exchange',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Listing>>(
            future: _exchangeListingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No books available for exchange',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];

                  Book? book = findBookByIsbn([], listing.isbn ?? "", context)!;
                  // Book? requesting = findBookByIsbn([], listing.requestId , context)!;

                  return GestureDetector(
                    onTap: () => _sendExchangeRequest(listing.id),
                    child: MarketplaceCard(
                      condition: listing.condition ?? "",
                      price: 'For Trade',
                      status: 'Requesting: ${listing.requestId ?? 'Any'}',
                      statusColor: Colors.orange,
                      book: book,
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
