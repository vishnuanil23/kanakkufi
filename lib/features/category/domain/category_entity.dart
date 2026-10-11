import 'package:flutter/material.dart';

class CategoryEntity {
  final String id;
  final String name;
  final IconData icon;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
  });
}

const List<CategoryEntity> expenseCategories = [
  CategoryEntity(
    id: 'income',
    name: 'Income',
    icon: Icons.account_balance_wallet_rounded,
  ),
  CategoryEntity(
    id: 'self_transfer',
    name: 'Self Transfer',
    icon: Icons.swap_horiz_rounded,
  ),
  CategoryEntity(
    id: 'upi',
    name: 'UPI',
    icon: Icons.flash_on_rounded,
  ),
  CategoryEntity(
    id: 'card',
    name: 'Card',
    icon: Icons.credit_card_rounded,
  ),
  CategoryEntity(
    id: 'bank',
    name: 'Bank Transfer',
    icon: Icons.account_balance_rounded,
  ),
  CategoryEntity(
    id: 'food',
    name: 'Food & Dining',
    icon: Icons.restaurant_rounded,
  ),
  CategoryEntity(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
  ),
  CategoryEntity(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_car_rounded,
  ),
  CategoryEntity(
    id: 'utilities',
    name: 'Utilities',
    icon: Icons.bolt_rounded,
  ),
  CategoryEntity(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_rounded,
  ),
  CategoryEntity(
    id: 'fuel',
    name: 'Fuel',
    icon: Icons.local_gas_station_rounded,
  ),
  CategoryEntity(
    id: 'health',
    name: 'Health',
    icon: Icons.medical_services_rounded,
  ),
  CategoryEntity(
    id: 'education',
    name: 'Education',
    icon: Icons.school_rounded,
  ),
  CategoryEntity(
    id: 'recharge',
    name: 'Mobile Recharge',
    icon: Icons.phone_android_rounded,
  ),
  CategoryEntity(
    id: 'travel',
    name: 'Travel & Stay',
    icon: Icons.hotel_rounded,
  ),
  CategoryEntity(
    id: 'fitness',
    name: 'Fitness',
    icon: Icons.fitness_center_rounded,
  ),
  CategoryEntity(
    id: 'insurance',
    name: 'Insurance',
    icon: Icons.shield_rounded,
  ),
  CategoryEntity(
    id: 'loan',
    name: 'Loan/EMI',
    icon: Icons.receipt_long_rounded,
  ),
  CategoryEntity(
    id: 'doctor',
    name: 'Doctor',
    icon: Icons.local_hospital_rounded,
  ),
  CategoryEntity(
    id: 'pharmacy',
    name: 'Pharmacy',
    icon: Icons.medication_rounded,
  ),
  CategoryEntity(id: 'scan', name: 'Scan', icon: Icons.biotech_rounded),
  CategoryEntity(
    id: 'baby_care',
    name: 'Baby Care',
    icon: Icons.child_care_rounded,
  ),
  CategoryEntity(
    id: 'hospital',
    name: 'Hospital',
    icon: Icons.apartment_rounded,
  ),
  CategoryEntity(
    id: 'nutrition',
    name: 'Nutrition',
    icon: Icons.restaurant_rounded,
  ),
  CategoryEntity(
    id: 'laboratory',
    name: 'Laboratory',
    icon: Icons.science_rounded,
  ),
  CategoryEntity(id: 'other', name: 'Other', icon: Icons.more_horiz_rounded),
];

CategoryEntity getCategoryByName(String name) {
  // Strip emojis and punctuation symbols to compare clean text
  final cleanName = name
      .replaceAll(RegExp(r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '')
      .replaceAll(RegExp(r'^[^\w]+'), '')
      .trim()
      .toLowerCase();

  for (final cat in expenseCategories) {
    final catLower = cat.name.toLowerCase();
    if (cleanName == catLower ||
        cleanName.contains(catLower) ||
        catLower.contains(cleanName)) {
      return cat;
    }
  }
  return expenseCategories.last; // Fallback to "Other"
}
