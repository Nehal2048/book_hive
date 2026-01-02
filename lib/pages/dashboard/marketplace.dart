import 'package:flutter/material.dart';
import 'package:book_hive/pages/misc/add_listing.dart';
import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/pages/dashboard/marketplace/buy_tab.dart';
import 'package:book_hive/pages/dashboard/marketplace/my_listing.dart';
import 'package:book_hive/pages/dashboard/marketplace/exchange_tab.dart';
import 'package:book_hive/pages/dashboard/marketplace/borrow_tab.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.deepPurple.shade50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart), text: 'Buy'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Exchange'),
              Tab(icon: Icon(Icons.handshake), text: 'Borrow'),
              Tab(
                icon: Icon(Icons.my_library_books_rounded),
                text: 'My Listing',
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [BuyTab(), ExchangeTab(), BorrowTab(), MyListing()],
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () async {
                    final booksProvider = BooksProvider.of(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddListingPage(books: booksProvider.books),
                      ),
                    );
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Listing added successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
