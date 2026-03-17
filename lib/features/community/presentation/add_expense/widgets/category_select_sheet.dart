import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../expense_category.dart';

class CategorySelectSheet extends StatefulWidget {
  final bool isDark;
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory> onSelect;

  const CategorySelectSheet({
    Key? key,
    required this.isDark,
    this.selectedCategory,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<CategorySelectSheet> createState() => _CategorySelectSheetState();
}

class _CategorySelectSheetState extends State<CategorySelectSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _filtered {
    if (_query.isEmpty) return ExpenseCategories.all;
    return ExpenseCategories.all.where((c) {
      return c.name.toLowerCase().contains(_query) ||
          c.group.toLowerCase().contains(_query) ||
          c.id.contains(_query);
    }).toList();
  }

  static const _groupOrder = [
    'Entertainment', 'Food and drink', 'Home', 'Life', 'Transportation', 'Uncategorized', 'Utilities',
  ];

  Map<String, List<ExpenseCategory>> get _grouped {
    final map = <String, List<ExpenseCategory>>{};
    for (final cat in _filtered) {
      map.putIfAbsent(cat.group, () => []).add(cat);
    }
    final ordered = <String, List<ExpenseCategory>>{};
    for (final g in _groupOrder) {
      if (map.containsKey(g)) ordered[g] = map[g]!;
    }
    for (final g in map.keys) {
      if (!ordered.containsKey(g)) ordered[g] = map[g]!;
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App bar with search
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search or select a category...',
                        hintStyle: TextStyle(color: AppColors.textGrey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: AppFonts.fontSize16,
                        color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Category list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppDimensions.padding16),
                itemCount: _grouped.length,
                itemBuilder: (context, index) {
                  final group = _grouped.keys.elementAt(index);
                  final categories = _grouped[group]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                      ),
                      ...categories.map((cat) => _CategoryTile(
                            category: cat,
                            isSelected: widget.selectedCategory?.id == cat.id,
                            isDark: widget.isDark,
                            onTap: () {
                              widget.onSelect(cat);
                              Navigator.pop(context);
                            },
                          )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category.iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          category.icon,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
          size: 22,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontSize: AppFonts.fontSize16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
      onTap: onTap,
    );
  }
}
