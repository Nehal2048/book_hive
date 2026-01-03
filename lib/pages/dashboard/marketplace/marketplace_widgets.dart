import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/listing.dart';
import 'package:book_hive/pages/misc/IndividualBook.dart';
import 'package:book_hive/pages/misc/add_listing.dart';
import 'package:book_hive/services/auth_service.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:flutter/material.dart';

class MarketplaceCard extends StatefulWidget {
  final Listing listing;
  final bool extendedView;

  const MarketplaceCard({
    super.key,
    required this.listing,
    this.extendedView = false,
  });

  @override
  State<MarketplaceCard> createState() => _MarketplaceCardState();
}

class _MarketplaceCardState extends State<MarketplaceCard> {
  @override
  Widget build(BuildContext context) {
    Book? book = findBookByIsbn([], widget.listing.isbn ?? "", context)!;
    Book? requestedBook = findBookByIsbn(
      [],
      widget.listing.desired_book ?? "",
      context,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📕 Book Cover
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                color: Colors.deepPurple.shade100,
                child: book.coverUrl.isNotEmpty
                    ? Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.book, size: 48),
                      )
                    : const Icon(Icons.book, size: 48),
              ),
            ),
          ),

          // 📄 Book Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + Author
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author.isNotEmpty ? book.author : 'Unknown author',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  (widget.extendedView)
                      ? Text(
                          "Listing Type: ${widget.listing.listingType}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        )
                      : Text(
                          "Seller: ${widget.listing.sellerId}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    "Listing ID: ${widget.listing.id}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  (widget.listing.desired_book != null)
                      ? Text(
                          "Desired Book: ${requestedBook!.title} - ${requestedBook.author}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : Text(
                          "Tk. ${widget.listing.price}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    "Condition: ${widget.listing.condition}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.listing.status == 'available'
                          ? Colors.green.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.listing.status!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: widget.listing.status == 'available'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.extendedView &&
                          widget.listing.status == 'available') ...[
                        TextButton(
                          onPressed: () {
                            _deleteListing(
                              widget.listing.id,
                              widget.listing.status,
                            );
                          },
                          child: Text(
                            "Delete Listing",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddListingPage(
                                  books: [],
                                  existingListing: widget.listing,
                                ),
                              ),
                            );
                          },
                          child: Text("Edit Listing"),
                        ),
                      ],

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IndividualBook(book: book),
                            ),
                          );
                        },
                        child: Text("View Book"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

    await showDialog<bool>(
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
                await DatabaseService().deleteListing(
                  listingId,
                  AuthService().getUserEmail() ?? "",
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Listing deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
