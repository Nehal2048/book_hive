import 'package:book_hive/models/book.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/listing.dart';

class BuyTab extends StatefulWidget {
  const BuyTab({super.key});

  @override
  State<BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends State<BuyTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _listingsFuture;
  final Map<int, int> _cartItems = {}; // listing id -> quantity
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _databaseService.getListingsByType('sale');
  }

  Future<void> _confirmOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please add items to cart')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userEmail = _authService.getUserEmail();

      for (final listingId in _cartItems.keys) {
        await _databaseService.createOrder(listingId, userEmail ?? "");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order confirmed! ${_cartItems.length} book(s) purchased.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _cartItems.clear();
          _listingsFuture = _databaseService.getListingsByType('sale');
        });
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy Books',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Purchase new or used books from our community',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                FutureBuilder<List<Listing>>(
                  future: _listingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allListings = snapshot.data ?? [];
                    final currentUserEmail = _authService.getUserEmail();

                    // Filter: only available and not created by current user
                    final listings = allListings
                        .where(
                          (l) =>
                              l.status == 'available' &&
                              l.sellerId != currentUserEmail,
                        )
                        .toList();

                    if (listings.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No books available for purchase',
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
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        final isInCart = _cartItems.containsKey(listing.id);

                        Book? book = findBookByIsbn(
                          [],
                          listing.isbn ?? "",
                          context,
                        );

                        if (book == null) {
                          return SizedBox();
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isInCart) {
                                _cartItems.remove(listing.id);
                              } else {
                                _cartItems[listing.id] = 1;
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              MarketplaceCard(
                                condition: listing.condition ?? "Good",
                                price:
                                    'Tk. ${listing.price.toStringAsFixed(2)}',
                                status: listing.status ?? "",
                                statusColor: listing.status == 'available'
                                    ? Colors.green
                                    : Colors.orange,
                                book: book,
                              ),
                              if (isInCart)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Cart Summary Footer
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cart: ${_cartItems.length} item(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isLoading ? 'Processing...' : 'Confirm Order'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
