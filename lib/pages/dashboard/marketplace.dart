import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/user.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/marketplace/buy_tab.dart';
import 'package:book_hive/pages/dashboard/marketplace/my_listing.dart';
import 'package:book_hive/pages/dashboard/marketplace/exchange_tab.dart';
import 'package:book_hive/pages/dashboard/marketplace/borrow_tab.dart';

class MarketplaceScreen extends StatefulWidget {
  final User userAccount;
  final List<Book> books;

  const MarketplaceScreen({
    super.key,
    required this.userAccount,
    required this.books,
  });

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
          child: TabBarView(
            controller: _tabController,
            children: [
              BuyTab(books: widget.books, currentUser: widget.userAccount),
              ExchangeTab(),
              BorrowTab(),
              MyListing(userAccount: widget.userAccount),
            ],
          ),
        ),
      ],
    );
  }
}
