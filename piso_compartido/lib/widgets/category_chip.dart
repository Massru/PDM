import 'package:flutter/material.dart';
import '../models/expense.dart';

class CategoryChip extends StatelessWidget {
  final ExpenseCategory category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(category.label),
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(
        category.isFixed ? Icons.receipt : Icons.shopping_cart,
        size: 16,
      ),
    );
  }
}