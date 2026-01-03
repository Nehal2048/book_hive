class Borrow {
  final String id; // uuid
  final String lender; // email
  final String borrower; // email
  final int listingId; // bigint
  final DateTime startDate; // default: now()
  final DateTime dueDate; // default: now + 7 days
  final DateTime? returnDate; // nullable
  final bool returnedFlag; // default: false

  Borrow({
    this.id = "",
    required this.lender,
    required this.borrower,
    required this.listingId,
    DateTime? startDate,
    DateTime? dueDate,
    this.returnDate,
    this.returnedFlag = false,
  }) : startDate = startDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7));

  /// Create Borrow from JSON
  factory Borrow.fromJson(Map<String, dynamic> json) {
    return Borrow(
      id: json['id'] ?? "",
      lender: json['lender'] ?? "",
      borrower: json['borrower'] ?? "",
      listingId: json['listing_id'] is int
          ? json['listing_id']
          : int.tryParse(json['listing_id'].toString()) ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'])
          : null,
      returnedFlag: json['returned_flag'] ?? false,
    );
  }

  /// Convert Borrow to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : null,
      'lender': lender,
      'borrower': borrower,
      'listing_id': listingId,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'returned_flag': returnedFlag,
    };
  }

  @override
  String toString() {
    return 'Borrow('
        'id: $id, '
        'lender: $lender, '
        'borrower: $borrower, '
        'listingId: $listingId, '
        'startDate: $startDate, '
        'dueDate: $dueDate, '
        'returnDate: $returnDate, '
        'returnedFlag: $returnedFlag'
        ')';
  }
}
