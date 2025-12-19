class Txn {
  final String id;
  final DateTime date;

  /// Income: positive. Expense: negative.
  final int amountCents;

  final String category;
  final String note;

  const Txn({
    required this.id,
    required this.date,
    required this.amountCents,
    required this.category,
    this.note = '',
  });

  bool get isIncome => amountCents >= 0;
}
