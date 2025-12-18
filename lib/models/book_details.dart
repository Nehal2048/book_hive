class BookDetails {
  final String edition; // ""
  final String pdfLink; // ""
  final String audioUrl; // ""
  final String isbn; // FK -> Book
  final String adminId; // FK -> User.email

  BookDetails({
    this.edition = "",
    this.pdfLink = "",
    this.audioUrl = "",
    this.isbn = "",
    this.adminId = "",
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    return BookDetails(
      edition: json['edition'] ?? "",
      pdfLink: json['pdf_link'] ?? "",
      audioUrl: json['audio_url'] ?? "",
      isbn: json['isbn'] ?? "",
      adminId: json['admin_id'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edition': edition,
      'pdf_link': pdfLink,
      'audio_url': audioUrl,
      'isbn': isbn,
      'admin_id': adminId,
    };
  }

  @override
  String toString() {
    return 'BookDetails(isbn: $isbn, edition: $edition, '
        'pdfLink: $pdfLink, audioUrl: $audioUrl, adminId: $adminId)';
  }
}
