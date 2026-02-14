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
  return expenseCategories.firstWhere(
    (e) => e.name.toLowerCase() == name.toLowerCase(),
    orElse: () => expenseCategories.last, // Fallback to "Other"
  );
}
