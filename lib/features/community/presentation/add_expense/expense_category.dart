import 'package:flutter/material.dart';

/// Expense category with icon - used for category selection and auto-fill from description.
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color iconBgColor;
  final String group;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconBgColor,
    required this.group,
  });

  /// Keywords for auto-matching when user types in description (e.g. "home" -> Home)
  List<String> get keywords => [name.toLowerCase(), group.toLowerCase(), id];
}

/// All expense categories grouped by section (matches Splitwise-style UI).
class ExpenseCategories {
  static const List<ExpenseCategory> all = [
    // Entertainment
    ExpenseCategory(id: 'games', name: 'Games', icon: Icons.sports_esports_outlined, iconBgColor: Color(0xFFE1BEE7), group: 'Entertainment'),
    ExpenseCategory(id: 'movies', name: 'Movies', icon: Icons.movie_outlined, iconBgColor: Color(0xFFE1BEE7), group: 'Entertainment'),
    ExpenseCategory(id: 'music', name: 'Music', icon: Icons.music_note_outlined, iconBgColor: Color(0xFFE1BEE7), group: 'Entertainment'),
    ExpenseCategory(id: 'entertainment_other', name: 'Other', icon: Icons.receipt_long_outlined, iconBgColor: Color(0xFFE1BEE7), group: 'Entertainment'),
    ExpenseCategory(id: 'sports', name: 'Sports', icon: Icons.sports_soccer_outlined, iconBgColor: Color(0xFFE1BEE7), group: 'Entertainment'),
    // Food and drink
    ExpenseCategory(id: 'dining_out', name: 'Dining out', icon: Icons.restaurant_outlined, iconBgColor: Color(0xFFC8E6C9), group: 'Food and drink'),
    ExpenseCategory(id: 'groceries', name: 'Groceries', icon: Icons.shopping_cart_outlined, iconBgColor: Color(0xFFC8E6C9), group: 'Food and drink'),
    ExpenseCategory(id: 'liquor', name: 'Liquor', icon: Icons.local_bar_outlined, iconBgColor: Color(0xFFC8E6C9), group: 'Food and drink'),
    ExpenseCategory(id: 'food_other', name: 'Other', icon: Icons.restaurant_outlined, iconBgColor: Color(0xFFC8E6C9), group: 'Food and drink'),
    // Home
    ExpenseCategory(id: 'electronics', name: 'Electronics', icon: Icons.bolt_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'furniture', name: 'Furniture', icon: Icons.weekend_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'household_supplies', name: 'Household supplies', icon: Icons.cleaning_services_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'maintenance', name: 'Maintenance', icon: Icons.build_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'mortgage', name: 'Mortgage', icon: Icons.home_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'home_other', name: 'Other', icon: Icons.home_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'pets', name: 'Pets', icon: Icons.pets_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'rent', name: 'Rent', icon: Icons.home_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    ExpenseCategory(id: 'services', name: 'Services', icon: Icons.miscellaneous_services_outlined, iconBgColor: Color(0xFFFFF9C4), group: 'Home'),
    // Life
    ExpenseCategory(id: 'childcare', name: 'Childcare', icon: Icons.child_care_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'clothing', name: 'Clothing', icon: Icons.checkroom_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'education', name: 'Education', icon: Icons.school_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'gifts', name: 'Gifts', icon: Icons.card_giftcard_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'insurance', name: 'Insurance', icon: Icons.description_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'medical', name: 'Medical expenses', icon: Icons.medical_services_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'life_other', name: 'Other', icon: Icons.receipt_long_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    ExpenseCategory(id: 'taxes', name: 'Taxes', icon: Icons.calculate_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Life'),
    // Transportation
    ExpenseCategory(id: 'bicycle', name: 'Bicycle', icon: Icons.directions_bike_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'bus_train', name: 'Bus/train', icon: Icons.directions_bus_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'car', name: 'Car', icon: Icons.directions_car_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'gas_fuel', name: 'Gas/fuel', icon: Icons.local_gas_station_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'hotel', name: 'Hotel', icon: Icons.hotel_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'transportation_other', name: 'Other', icon: Icons.receipt_long_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'parking', name: 'Parking', icon: Icons.local_parking_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'plane', name: 'Plane', icon: Icons.flight_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    ExpenseCategory(id: 'taxi', name: 'Taxi', icon: Icons.local_taxi_outlined, iconBgColor: Color(0xFFF8BBD9), group: 'Transportation'),
    // Uncategorized
    ExpenseCategory(id: 'general', name: 'General', icon: Icons.receipt_long_outlined, iconBgColor: Color(0xFFE0E0E0), group: 'Uncategorized'),
    // Utilities
    ExpenseCategory(id: 'cleaning', name: 'Cleaning', icon: Icons.cleaning_services_outlined, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'electricity', name: 'Electricity', icon: Icons.bolt_outlined, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'heat_gas', name: 'Heat/gas', icon: Icons.local_fire_department_outlined, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'utilities_other', name: 'Other', icon: Icons.lightbulb_outline, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'trash', name: 'Trash', icon: Icons.delete_outline, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'tv_phone_internet', name: 'TV/Phone/Internet', icon: Icons.wifi_outlined, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
    ExpenseCategory(id: 'water', name: 'Water', icon: Icons.water_drop_outlined, iconBgColor: Color(0xFFB3E5FC), group: 'Utilities'),
  ];

  static List<String> get groups => [...all.map((c) => c.group).toSet()]..sort();

  static List<ExpenseCategory> byGroup(String group) =>
      all.where((c) => c.group == group).toList();

  /// Find category by description text - e.g. "home" -> home icon, "rent" -> Rent
  /// Prefers exact matches (name/id) over group matches, so "home" gives house icon not electronics.
  static ExpenseCategory? findFromDescription(String text) {
    if (text.trim().isEmpty) return null;
    final lower = text.toLowerCase().trim();
    final words = lower.split(RegExp(r'\s+'));
    ExpenseCategory? groupMatch;
    for (final word in words) {
      if (word.length < 2) continue;
      for (final cat in all) {
        final nameMatch = cat.name.toLowerCase().contains(word);
        final idMatch = cat.id.replaceAll('_', ' ').contains(word) || cat.id.contains(word);
        final groupMatchOnly = cat.group.toLowerCase().contains(word) && !nameMatch && !idMatch;
        if (nameMatch || idMatch) {
          return cat; // exact match - return immediately
        }
        if (groupMatchOnly && groupMatch == null) {
          groupMatch = cat;
        }
      }
      if (groupMatch != null) return groupMatch;
    }
    return groupMatch;
  }

  static ExpenseCategory get general => all.firstWhere((c) => c.id == 'general');
}
