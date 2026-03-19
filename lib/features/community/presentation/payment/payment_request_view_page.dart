import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import 'widgets/payment_widgets.dart';

/// Page shown when user taps a payment reminder notification.
/// Displays the QR code so the recipient can scan and pay.
class PaymentRequestViewPage extends StatelessWidget {
  final String upiUri;
  final double amount;
  final String currency;
  final String senderName;
  final String? groupName;

  const PaymentRequestViewPage({
    super.key,
    required this.upiUri,
    required this.amount,
    required this.currency,
    required this.senderName,
    this.groupName,
  });

  String _currencySymbol() {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs.';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Pay via QR'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                '$senderName is requesting',
                style: TextStyle(
                  fontSize: AppFonts.fontSize16,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currencySymbol()} ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppFonts.fontSize28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              if (groupName != null) ...[
                const SizedBox(height: 4),
                Text(
                  groupName!,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              QrCard(data: upiUri),
              const SizedBox(height: 24),
              Text(
                'Scan to pay',
                style: TextStyle(
                  fontSize: AppFonts.fontSize18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open GPay, PhonePe, or any UPI app and scan this QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFonts.fontSize14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
