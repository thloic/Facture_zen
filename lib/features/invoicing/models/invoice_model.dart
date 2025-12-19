class InvoiceModel {
  final String id;
  final String clientName;
  final DateTime date;
  final String amount;
  final String status;

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.date,
    required this.amount,
    required this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      clientName: json['clientName'] ?? '',
      date: DateTime.parse(json['date']),
      amount: json['amount'] ?? '',
      status: json['status'] ?? '',
    );
  }

  /// Formate la date au format "28 Oct 2025 | 17h8"
  String get formattedDate {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} | ${date.hour}h${date.minute}';
  }
}