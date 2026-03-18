import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import 'group_sort_sheet.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isDark;
  final GroupSortOrder sortOrder;
  final ValueChanged<GroupSortOrder> onSortOrderChanged;
  final VoidCallback onSearchChanged;

  const HomeSearchBar({
    super.key,
    required this.searchController,
    required this.isDark,
    required this.sortOrder,
    required this.onSortOrderChanged,
    required this.onSearchChanged,
  });

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => GroupSortSheet(
        currentOrder: sortOrder,
        isDark: isDark,
        onOrderSelected: onSortOrderChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radius12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.padding16,
                  vertical: AppDimensions.padding12,
                ),
              ),
              onChanged: (_) => onSearchChanged(),
            ),
          ),
          const SizedBox(width: AppDimensions.margin8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              onPressed: () => _showFilterSheet(context),
              tooltip: 'Sort & filter',
            ),
          ),
        ],
      ),
    );
  }
}
