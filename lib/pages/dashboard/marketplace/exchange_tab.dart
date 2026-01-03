import 'package:book_hive/models/book.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/models/listing.dart';

class ExchangeTab extends StatefulWidget {
  const ExchangeTab({super.key});

  @override
  State<ExchangeTab> createState() => _ExchangeTabState();
}

class _ExchangeTabState extends State<ExchangeTab> {
  final _databaseService = DatabaseService();

  late Future<List<Listing>> _exchangeListingsFuture;

  @override
  void initState() {
    super.initState();
    _exchangeListingsFuture = _databaseService.getListingsByType('exchange');
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

              List<Listing> listings =
                  snapshot.data
                      ?.where((element) => element.status == 'available')
                      .toList() ??
                  [];

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
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];

                  Book? desiredBook = findBookByIsbn(
                    [],
                    listing.desired_book!,
                    context,
                  )!;

                  Book? mainBook = findBookByIsbn([], listing.isbn!, context)!;

                  return GestureDetector(
                    onTap: () =>
                        _sendExchangeRequest(listing, mainBook, desiredBook),
                    child: MarketplaceCard(listing: listing),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendExchangeRequest(Listing listing, Book mainBook, Book desiredBook) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Exchange'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You Give:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${desiredBook.title} by ${desiredBook.author}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Divider(height: 24),
                Text(
                  'You Gain:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${mainBook.title} by ${mainBook.author}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  DatabaseService().sendExchangeRequest(
                    AuthService().getUserEmail() ?? "",
                    listing,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exchange Successful!'),
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
              child: Text('Confirm Exchange'),
            ),
          ],
        );
      },
    );
  }
}
