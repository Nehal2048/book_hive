import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/user.dart';
import 'package:book_hive/pages/dashboard/library.dart';
import 'package:book_hive/pages/dashboard/marketplace/marketplace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/listing.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:book_hive/pages/misc/add_listing.dart';

class MyListing extends StatefulWidget {
  final User userAccount;
  const MyListing({super.key, required this.userAccount});

  @override
  State<MyListing> createState() => _MyListingState();
}

class _MyListingState extends State<MyListing> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _listingsFuture;
  late Future<List<Book>> _userBooksFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    final userEmail = _authService.getUserEmail() ?? "";
    _listingsFuture = _databaseService.getListingsByUser(userEmail);
    _userBooksFuture = _databaseService.getOwnedBook(userEmail);
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
              SizedBox(height: 8),

              ElevatedButton.icon(
                icon: const Icon(Icons.auto_stories),
                label: const Text('Create listing'),
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
              ),
              SizedBox(height: 24),
              Text(
                'Books I own',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              FutureBuilder(
                future: _userBooksFuture,
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (asyncSnapshot.hasError) {
                    return Center(child: Text('Error: ${asyncSnapshot.error}'));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 260,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: asyncSnapshot.data!.length,
                    itemBuilder: (context, index) {
                      Book book = asyncSnapshot.data![index];
                      return BookCard(book: book, user: widget.userAccount);
                    },
                  );
                },
              ),
              SizedBox(height: 32),
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
            ],
          );
        },
      ),
    );
  }

  buildListingList(List<Listing> listingsFuture) {
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

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
      ),
      itemCount: listingsFuture.length,
      itemBuilder: (context, index) {
        final listing = listingsFuture[index];
        final book = findBookByIsbn([], listing.isbn ?? "", context);

        if (book == null) {
          return SizedBox();
        }

        return MarketplaceCard(listing: listing, extendedView: true);
      },
    );
  }
}
