import 'lp_enums.dart';

class LpParticipant {
  const LpParticipant({
    required this.id,
    required this.role,
    this.displayName,
  });

  /// LivePerson participant ID (could be consumer ID, agent ID, or bot ID).
  final String id;

  final LpChannelType role;

  final String? displayName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role.name,
      'displayName': displayName,
    };
  }

  factory LpParticipant.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? 'consumer';
    final role = LpChannelType.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => LpChannelType.consumer,
    );

    return LpParticipant(
      id: json['id'] as String? ?? '',
      role: role,
      displayName: json['displayName'] as String?,
    );
  }
}
