import 'package:flutter/material.dart';

import '../models/category.dart';

IconData categoryIconData(String code) => switch (code) {
  'food' => Icons.restaurant_rounded,
  'transport' => Icons.directions_bus_rounded,
  'shopping' => Icons.shopping_bag_rounded,
  'bills' => Icons.receipt_long_rounded,
  'salary' => Icons.payments_rounded,
  'home' => Icons.home_rounded,
  'health' => Icons.favorite_rounded,
  'other' => Icons.category_rounded,
  _ => Icons.category_rounded,
};

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 42});
  final FinanceCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(category?.colorValue ?? 0xFF9AA8A5);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        categoryIconData(category?.iconCode ?? 'other'),
        color: color,
        size: size * 0.52,
      ),
    );
  }
}
