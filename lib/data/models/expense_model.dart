import 'package:cloud_firestore/cloud_firestore.dart';

/// Trip expense - only participants (jisme naam add hai) split karenge.
class ExpenseModel {
  final String id;
  final String groupId;
  final double amount;
  final String currency;
  final String description;
  final String paidBy; // userId who paid
  final List<String> participants; // userIds - sirf inko paisa dena hai
  final String createdBy; // userId who added - sirf ye edit/delete kar sakta hai
  final DateTime createdAt;
  /// Custom per-person amounts (userId -> amount). If null/empty, split equally.
  final Map<String, double>? customAmounts;
  /// Receipt/image URL from ImgBB
  final String? imageUrl;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.amount,
    this.currency = 'PKR',
    required this.description,
    required this.paidBy,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.customAmounts,
    this.imageUrl,
  });

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    double? amount,
    String? currency,
    String? description,
    String? paidBy,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    Map<String, double>? customAmounts,
    String? imageUrl,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      customAmounts: customAmounts ?? this.customAmounts,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Per-person share (sirf participants ke liye). Uses customAmounts if set.
  double shareForUser(String userId) {
    if (!participants.contains(userId)) return 0;
    if (customAmounts != null && customAmounts!.containsKey(userId)) {
      return customAmounts![userId]!;
    }
    return participants.isEmpty ? 0 : amount / participants.length;
  }

  /// Equal share per person (for backward compatibility)
  double get sharePerPerson =>
      participants.isEmpty ? 0 : amount / participants.length;

  /// Check if user is in this expense (usko paisa dena hai ya nahi)
  bool isParticipant(String userId) => participants.contains(userId);

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = data['participants'] as List<dynamic>? ?? [];
    final custom = data['customAmounts'] as Map<String, dynamic>?;
    final customAmounts = custom != null
        ? custom.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
        : null;
    final imageUrl = data['imageUrl'] as String?;
    return ExpenseModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'PKR',
      description: data['description'] ?? '',
      paidBy: data['paidBy'] ?? '',
      participants: participants.map((e) => e.toString()).toList(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customAmounts: customAmounts,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'paidBy': paidBy,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (customAmounts != null && customAmounts!.isNotEmpty) 'customAmounts': customAmounts,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }
}
