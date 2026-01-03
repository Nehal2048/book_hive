class User {
  final String email; // PK, mandatory
  final String name; // mandatory
  final DateTime joinDate;
  final String userType; // 'admin' | 'regular'
  final bool buyerFlag; // default true
  final bool sellerFlag; // default true
  final double balance;

  static const Set<String> allowedUserTypes = {'admin', 'regular'};

  User({
    required this.email,
    required this.name,
    DateTime? joinDate,
    String userType = 'regular',
    this.buyerFlag = true,
    this.sellerFlag = true,
    this.balance = 0.0,
  }) : joinDate = joinDate ?? DateTime.now(),
       userType = userType;

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic jt = json['join_date'];
    DateTime parsedJoinDate;
    if (jt is String) {
      parsedJoinDate = DateTime.tryParse(jt) ?? DateTime.now();
    } else if (jt is int) {
      // Treat as epoch milliseconds
      parsedJoinDate = DateTime.fromMillisecondsSinceEpoch(jt);
    } else if (jt is DateTime) {
      parsedJoinDate = jt;
    } else {
      parsedJoinDate = DateTime.now();
    }

    return User(
      email: json['email'] as String,
      name: json['name'] as String,
      joinDate: parsedJoinDate,
      userType: (json['user_type'] as String?) ?? 'regular',
      buyerFlag: (json['buyer_flag'] as bool?) ?? true,
      sellerFlag: (json['seller_flag'] as bool?) ?? true,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'join_date': joinDate.toIso8601String().split('T')[0],
    'user_type': userType,
    'buyer_flag': buyerFlag,
    'seller_flag': sellerFlag,
    'balance': balance,
  };

  @override
  String toString() {
    return 'User(email: '
        '$email, name: $name, join_date: ${joinDate.toIso8601String()}, '
        'user_type: $userType, buyer_flag: $buyerFlag, seller_flag: $sellerFlag, balance: $balance)';
  }
}
