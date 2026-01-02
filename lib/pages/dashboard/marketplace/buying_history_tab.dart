import 'package:flutter/material.dart';
import 'package:book_hive/services/database.dart';
import 'package:book_hive/services/auth_service.dart';

class BuyingHistoryTab extends StatefulWidget {
  const BuyingHistoryTab({super.key});

  @override
  State<BuyingHistoryTab> createState() => _BuyingHistoryTabState();
}

class _BuyingHistoryTabState extends State<BuyingHistoryTab> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = _databaseService.getOrdersByUser(
      _authService.getUserEmail() ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buying History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'View all books you\'ve purchased',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          FutureBuilder<List<dynamic>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
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
                          'No purchases yet',
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
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order['id'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    order['status'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['status']?.toString() ?? 'pending',
                                  style: TextStyle(
                                    color: _getStatusColor(order['status']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Listing ID: ${order['listing_id'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Date: ${order['created_at'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (order['total_price'] != null) ...[
                            SizedBox(height: 8),
                            Text(
                              'Price: \$${order['total_price'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
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

  Color _getStatusColor(dynamic status) {
    final statusStr = status?.toString() ?? '';
    if (statusStr == 'completed' || statusStr == 'delivered') {
      return Colors.green;
    } else if (statusStr == 'pending' || statusStr == 'processing') {
      return Colors.orange;
    } else if (statusStr == 'cancelled') {
      return Colors.red;
    }
    return Colors.grey;
  }
}
