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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('Browse available books to exchange!')),
              ],
            ),
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
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return GestureDetector(
                    onTap: () => _sendExchangeRequest(listing.id),
                    child: MarketplaceCard(
                      title: listing.isbn ?? "",
                      subtitle: listing.condition ?? "",
                      price: 'For Trade',
                      status: 'Requesting: ${listing.requestId ?? 'Any'}',
                      statusColor: Colors.orange,
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(height: 32),
          Text(
            'Your Exchange Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: _userExchangesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final exchanges = snapshot.data ?? [];
              if (exchanges.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No active exchange requests',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: exchanges.length,
                itemBuilder: (context, index) {
                  final exchange = exchanges[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exchange #${exchange['id'] ?? 'N/A'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Status: ${exchange['status'] ?? 'pending'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
