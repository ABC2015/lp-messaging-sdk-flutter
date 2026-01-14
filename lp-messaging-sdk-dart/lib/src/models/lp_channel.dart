/// Source channel for a conversation (web, whatsapp, etc).
enum LpSourceChannelType {
  web,
  mobile,
  whatsapp,
  tiktok,
  instagram,
  appleMessages,
  sms,
  facebookMessenger,
  other,
}

class LpChannel {
  const LpChannel({
    required this.id,
    required this.type,
    this.metadata = const {},
  });

  final String id;
  final LpSourceChannelType type;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory LpChannel.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String? ?? 'other';
    final type = LpSourceChannelType.values.firstWhere(
      (t) => t.name == typeRaw,
      orElse: () => LpSourceChannelType.other,
    );
    return LpChannel(
      id: json['id'] as String? ?? '',
      type: type,
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }
}
