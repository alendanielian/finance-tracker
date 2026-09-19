import 'entry_type.dart';

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String iconCode;
  final int colorValue;
  final EntryType type;
  final bool isArchived;

  String displayName(String locale) {
    if (locale != 'en') return name;
    return switch (id) {
      'food' => 'Food',
      'transport' => 'Transport',
      'shopping' => 'Shopping',
      'bills' => 'Bills',
      'salary' => 'Salary',
      _ => name,
    };
  }

  FinanceCategory copyWith({bool? isArchived}) => FinanceCategory(
    id: id,
    name: name,
    iconCode: iconCode,
    colorValue: colorValue,
    type: type,
    isArchived: isArchived ?? this.isArchived,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'colorValue': colorValue,
    'type': type.name,
    'isArchived': isArchived,
  };

  factory FinanceCategory.fromMap(Map<dynamic, dynamic> map) => FinanceCategory(
    id: map['id'] as String,
    name: map['name'] as String,
    iconCode: map['iconCode'] as String,
    colorValue: map['colorValue'] as int,
    type: entryTypeFromString(map['type'] as String),
    isArchived: map['isArchived'] as bool? ?? false,
  );
}
