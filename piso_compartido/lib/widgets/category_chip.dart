import 'package:flutter/material.dart';
import '../models/expense.dart';

/// Widget reutilizable para mostrar una categoría de gasto como chip.
/// Usado en filtros y selección de categorías.
///
/// La diferencia con un FilterChip genérico es que incluye un icono
/// que varía según si la categoría es fija (factura) o variable (compra).
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
      // El icono distingue visualmente entre gastos fijos y variables:
      // receipt = factura (fijo), shopping_cart = compra (variable)
      avatar: Icon(
        category.isFixed ? Icons.receipt : Icons.shopping_cart,
        size: 16,
      ),
    );
  }
}