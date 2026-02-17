// lib/utils/helpers.dart

import 'package:flutter/material.dart';

/// Sana formatlash (masalan: Friday, 30 January 2025)
String getFormattedDate({DateTime? date}) {
  final now = date ?? DateTime.now();
  final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final weekday = weekdays[now.weekday - 1];
  final day = now.day;
  final month = months[now.month - 1];
  final year = now.year;

  return '$weekday, $day $month $year';
}

/// O‘zbekcha sana formati
String getFormattedDateUZ({DateTime? date}) {
  final now = date ?? DateTime.now();
  final weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
  final months = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr'
  ];

  final weekday = weekdays[now.weekday - 1];
  final day = now.day;
  final month = months[now.month - 1];
  final year = now.year;

  return '$weekday, $day $month $year';
}

/// Kategoriya rangini qaytaradi
Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'personal':
      return Colors.blue;
    case 'health':
      return Colors.red;
    case 'work':
      return Colors.purple;
    case 'shopping':
      return Colors.orange;
    case 'learning':
      return Colors.indigo;
    case 'home':
      return Colors.teal;
    default:
      return Colors.grey.shade700;
  }
}

/// Kategoriya ikonasi
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

/// Boshqa yordamchi funksiyalar shu yerga qo‘shiladi