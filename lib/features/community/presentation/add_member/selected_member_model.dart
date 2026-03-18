/// Represents a member selected for adding (from contacts or manual entry).
class SelectedMember {
  final String name;
  final String phone;
  final String? email;

  const SelectedMember({
    required this.name,
    required this.phone,
    this.email,
  });

  String get displayPhone => phone;
}
