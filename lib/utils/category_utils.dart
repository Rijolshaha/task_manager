// lib/utils/category_utils.dart
import 'package:flutter/material.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Personal':
      return Colors.blue;
    case 'Health':
      return Colors.red;
    case 'Work':
      return Colors.purple;
    case 'Shopping':
      return Colors.orange;
    case 'Learning':
      return Colors.indigo;
    case 'Home':
      return Colors.teal;
    default:
      return Colors.grey.shade700;
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Personal':
      return Icons.person;
    case 'Health':
      return Icons.favorite;
    case 'Work':
      return Icons.work;
    case 'Shopping':
      return Icons.shopping_cart;
    case 'Learning':
      return Icons.school;
    case 'Home':
      return Icons.home;
    default:
      return Icons.category;
  }
}