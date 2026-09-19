class MonthlyBudget {
  const MonthlyBudget({
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.limitMinor,
  });

  final int year;
  final int month;
  final String currencyCode;
  final int limitMinor;

  String get id => '$year-$month-$currencyCode';

  Map<String, dynamic> toMap() => {
    'year': year,
    'month': month,
    'currencyCode': currencyCode,
    'limitMinor': limitMinor,
  };

  factory MonthlyBudget.fromMap(Map<dynamic, dynamic> map) => MonthlyBudget(
    year: map['year'] as int,
    month: map['month'] as int,
    currencyCode: map['currencyCode'] as String,
    limitMinor: map['limitMinor'] as int,
  );
}
