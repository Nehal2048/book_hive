import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/models/listing.dart';

class SellTab extends StatefulWidget {
  const SellTab({super.key});

  @override
  State<SellTab> createState() => _SellTabState();
}

class _SellTabState extends State<SellTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    _listingsFuture = _databaseService.getListingsByUser(
      _authService.getUserEmail() ?? "",
    );
  }

  Future<void> _deleteListing(int listingId, String status) async {
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
        title: Text('Delete Listing'),
        content: Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sell Your Books',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'List your books and manage your inventory',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Your Listings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Listing>>(
            future: _listingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final listings = snapshot.data ?? [];
              final activeListing = listings
                  .where((l) => l.status != 'sold')
                  .toList();

              if (activeListing.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
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
                itemCount: activeListing.length,
                itemBuilder: (context, index) {
                  final listing = activeListing[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 70,
                        color: Colors.deepPurple.shade100,
                        child: Icon(Icons.book),
                      ),
                      title: Text(listing.isbn ?? ""),
                      subtitle: Row(
                        children: [
                          Text('\$${listing.price.toStringAsFixed(2)}'),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: listing.status == 'available'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing.status ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                color: listing.status == 'available'
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (listing.status != 'sold')
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // TODO: Implement edit listing
                              },
                            ),
                          if (listing.status != 'sold')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteListing(
                                listing.id,
                                listing.status ?? "",
                              ),
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
