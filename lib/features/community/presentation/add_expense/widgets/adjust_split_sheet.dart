import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/group_model.dart';
import '../split_type.dart';
import 'equally_tab.dart';
import 'unequally_tab.dart';
import 'by_percentage_tab.dart';
import 'by_shares_tab.dart';
import 'by_adjustment_tab.dart';

class AdjustSplitSheet extends StatefulWidget {
  final double amount;
  final String currencySymbol;
  final GroupModel group;
  final Set<String> participants;
  final SplitType splitType;
  final Map<String, double> customAmounts;
  final bool isDark;
  final void Function(SplitType, Set<String>, Map<String, double>) onSave;

  const AdjustSplitSheet({
    Key? key,
    required this.amount,
    required this.currencySymbol,
    required this.group,
    required this.participants,
    required this.splitType,
    required this.customAmounts,
    required this.isDark,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AdjustSplitSheet> createState() => _AdjustSplitSheetState();
}

class _AdjustSplitSheetState extends State<AdjustSplitSheet> {
  late SplitType _tab;
  late Set<String> _selectedParticipants;
  late Map<String, double> _amounts;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tab = widget.splitType;
    _selectedParticipants = Set.from(widget.participants);
    if (_selectedParticipants.isEmpty) {
      _selectedParticipants.addAll(widget.group.members.keys);
    }
    _amounts = Map.from(widget.customAmounts);
    for (final uid in widget.group.members.keys) {
      _controllers[uid] = TextEditingController(
        text: _amounts[uid]?.toStringAsFixed(2) ?? '0.00',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<MapEntry<String, GroupMember>> get _members =>
      widget.group.members.entries.toList();

  double get _perPerson {
    if (_selectedParticipants.isEmpty) return 0;
    return widget.amount / _selectedParticipants.length;
  }

  Map<String, double> _computeFinalAmounts() {
    final result = <String, double>{};
    if (_tab == SplitType.equally) {
      final share = _selectedParticipants.isEmpty
          ? 0.0
          : widget.amount / _selectedParticipants.length;
      for (final uid in _selectedParticipants) {
        result[uid] = share;
      }
      return result;
    }
    if (_tab == SplitType.unequally) {
      for (final uid in _selectedParticipants) {
        result[uid] = _amounts[uid] ?? 0;
      }
      return result;
    }
    if (_tab == SplitType.byPercentage) {
      for (final uid in _selectedParticipants) {
        final pct = _amounts[uid] ?? 0;
        result[uid] = (pct / 100) * widget.amount;
      }
      return result;
    }
    if (_tab == SplitType.byShares) {
      double totalShares = 0;
      for (final uid in _selectedParticipants) {
        totalShares += _amounts[uid] ?? 0;
      }
      if (totalShares <= 0) return result;
      for (final uid in _selectedParticipants) {
        final share = _amounts[uid] ?? 0;
        result[uid] = (share / totalShares) * widget.amount;
      }
      return result;
    }
    if (_tab == SplitType.byAdjustment) {
      double totalAdj = 0;
      for (final uid in _selectedParticipants) {
        totalAdj += _amounts[uid] ?? 0;
      }
      final remainder = widget.amount - totalAdj;
      final equalShare = _selectedParticipants.isEmpty
          ? 0.0
          : remainder / _selectedParticipants.length;
      for (final uid in _selectedParticipants) {
        result[uid] = (_amounts[uid] ?? 0) + equalShare;
      }
      return result;
    }
    return result;
  }

  void _save() {
    final amounts = _computeFinalAmounts();
    widget.onSave(_tab, _selectedParticipants, amounts);
  }

  void _toggleParticipant(String uid) {
    setState(() {
      if (_selectedParticipants.contains(uid)) {
        _selectedParticipants.remove(uid);
      } else {
        _selectedParticipants.add(uid);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selectedParticipants.length == _members.length) {
        _selectedParticipants.clear();
      } else {
        _selectedParticipants.addAll(_members.map((e) => e.key));
      }
    });
  }

  void _onAmountChanged(String uid) {
    setState(() {
      _amounts[uid] = double.tryParse(_controllers[uid]?.text ?? '') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = SplitType.values;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          _buildAppBar(),
          _buildTabs(tabs),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabContent(),
            ),
          ),
          _buildBottomBar(),
        ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
          Text(
            'Adjust split',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<SplitType> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((t) {
          final selected = _tab == t;
          return GestureDetector(
            onTap: () => setState(() => _tab = t),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primaryGreen : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                t.tabTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? (widget.isDark ? AppColors.textWhite : AppColors.textBlack)
                      : AppColors.textGrey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case SplitType.equally:
        return EquallyTab(
          members: _members,
          selectedParticipants: _selectedParticipants,
          isDark: widget.isDark,
          onToggleParticipant: _toggleParticipant,
        );
      case SplitType.unequally:
        return UnequallyTab(
          members: _members,
          selectedParticipants: _selectedParticipants,
          amounts: _amounts,
          controllers: _controllers,
          currencySymbol: widget.currencySymbol,
          isDark: widget.isDark,
          onAmountChanged: _onAmountChanged,
        );
      case SplitType.byPercentage:
        return ByPercentageTab(
          members: _members,
          selectedParticipants: _selectedParticipants,
          amounts: _amounts,
          controllers: _controllers,
          currencySymbol: widget.currencySymbol,
          isDark: widget.isDark,
          onAmountChanged: _onAmountChanged,
        );
      case SplitType.byShares:
        return BySharesTab(
          members: _members,
          selectedParticipants: _selectedParticipants,
          amounts: _amounts,
          controllers: _controllers,
          currencySymbol: widget.currencySymbol,
          isDark: widget.isDark,
          onAmountChanged: _onAmountChanged,
        );
      case SplitType.byAdjustment:
        return ByAdjustmentTab(
          members: _members,
          selectedParticipants: _selectedParticipants,
          amounts: _amounts,
          controllers: _controllers,
          currencySymbol: widget.currencySymbol,
          isDark: widget.isDark,
          onAmountChanged: _onAmountChanged,
        );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.backgroundGrey,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.currencySymbol}${_perPerson.toStringAsFixed(2)}/person',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              Text(
                '(${_selectedParticipants.length} people)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          if (_tab == SplitType.equally)
            GestureDetector(
              onTap: _toggleAll,
              child: Row(
                children: [
                  Text(
                    _selectedParticipants.length == _members.length ? 'None' : 'All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _selectedParticipants.length == _members.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
