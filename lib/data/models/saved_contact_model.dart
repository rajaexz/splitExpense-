/// A contact saved by the user (from Add Someone New).
class SavedContactModel {
  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  const SavedContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  factory SavedContactModel.fromFirestore(Map<String, dynamic> data, String id) {
    final createdAt = data['createdAt'];
    return SavedContactModel(
      id: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      createdAt: createdAt is DateTime
          ? createdAt
          : (createdAt as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}
