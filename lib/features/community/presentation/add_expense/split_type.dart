/// Split methods for expense division
enum SplitType {
  equally,
  unequally,
  byPercentage,
  byShares,
  byAdjustment,
}

extension SplitTypeExtension on SplitType {
  String get label {
    switch (this) {
      case SplitType.equally:
        return 'equally';
      case SplitType.unequally:
        return 'unequally';
      case SplitType.byPercentage:
        return 'by %';
      case SplitType.byShares:
        return 'by shares';
      case SplitType.byAdjustment:
        return 'by adjustment';
    }
  }

  String get tabTitle {
    switch (this) {
      case SplitType.equally:
        return 'Equally';
      case SplitType.unequally:
        return 'Unequally';
      case SplitType.byPercentage:
        return 'By %';
      case SplitType.byShares:
        return 'By shares';
      case SplitType.byAdjustment:
        return 'By adjustment';
    }
  }

  String get title {
    switch (this) {
      case SplitType.equally:
        return 'Split equally';
      case SplitType.unequally:
        return 'Split unequally';
      case SplitType.byPercentage:
        return 'Split by percentage';
      case SplitType.byShares:
        return 'Split by shares';
      case SplitType.byAdjustment:
        return 'Split by adjustment';
    }
  }

  String get description {
    switch (this) {
      case SplitType.equally:
        return 'Select which people owe an equal share.';
      case SplitType.unequally:
        return 'Enter the amount each person owes.';
      case SplitType.byPercentage:
        return 'Enter the percentage each person owes (must total 100%).';
      case SplitType.byShares:
        return 'Enter shares (e.g. 2:1:1). Amount is divided by total shares.';
      case SplitType.byAdjustment:
        return 'Enter adjustments to reflect who owes extra; the remainder is split equally.';
    }
  }
}
