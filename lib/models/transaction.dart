import 'entry_type.dart';

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.amountMinor,
    required this.title,
    required this.type,
    required this.occurredAt,
    required this.categoryId,
    required this.currencyCode,
    this.note = '',
    this.isDemo = false,
  });

  final String id;
  final int amountMinor;
  final String title;
  final EntryType type;
  final DateTime occurredAt;
  final String categoryId;
  final String currencyCode;
  final String note;
  final bool isDemo;

  Map<String, dynamic> toMap() => {
    'id': id,
    'amountMinor': amountMinor,
    'title': title,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    'categoryId': categoryId,
    'currencyCode': currencyCode,
    'note': note,
    'isDemo': isDemo,
  };

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) =>
      FinanceTransaction(
        id: map['id'] as String,
        amountMinor: map['amountMinor'] as int,
        title: map['title'] as String,
        type: entryTypeFromString(map['type'] as String),
        occurredAt: DateTime.parse(map['occurredAt'] as String),
        categoryId: map['categoryId'] as String,
        currencyCode: map['currencyCode'] as String? ?? 'RUB',
        note: map['note'] as String? ?? '',
        isDemo: map['isDemo'] as bool? ?? false,
      );
}
