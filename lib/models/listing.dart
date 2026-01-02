class Listing {
  final int id;
  final double price;
  final String? status;
  final DateTime? createdAt;
  final String? listingType;
  final String? condition;
  final String? isbn;
  final String? sellerId;
  final bool requestFlag;
  final int? requestId;
  final String? requestType;

  Listing({
    required this.id,
    required this.price,
    this.status,
    this.createdAt,
    this.listingType,
    this.condition,
    this.isbn,
    this.sellerId,
    required this.requestFlag,
    this.requestId,
    this.requestType,
  });

  /// Creates a Listing instance from a JSON map
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as int,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      listingType: json['listing_type'] as String?,
      condition: json['condition'] as String?,
      isbn: json['isbn'] as String?,
      sellerId: json['seller_id'] as String?,
      requestFlag: json['request_flag'] as bool? ?? false,
      requestId: json['request_id'] as int?,
      requestType: json['request_type'] as String?,
    );
  }

  /// Converts the Listing instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'listing_type': listingType,
      'condition': condition,
      'isbn': isbn,
      'seller_id': sellerId,
      'request_flag': requestFlag,
      'request_id': requestId,
      'request_type': requestType,
    };
  }

  @override
  String toString() {
    return 'Listing(id: $id, price: $price, status: $status, createdAt: $createdAt, '
        'listingType: $listingType, condition: $condition, isbn: $isbn, sellerId: $sellerId, '
        'requestFlag: $requestFlag, requestId: $requestId, requestType: $requestType)';
  }
}
