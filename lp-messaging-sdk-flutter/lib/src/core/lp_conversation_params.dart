/// Parameters for launching / showing a conversation.
///
/// This is purposely generic (campaignInfo, visitorId, customVariables)
/// so you can map it to whichever LivePerson SDK inputs you need.
class LpConversationParams {
  /// Often a campaign / engagement / routing key.
  final String campaignInfo;

  /// Optional visitor/user identifier if you want to resume a session.
  final String? visitorId;

  /// Optional custom variables to pass into the conversation.
  final Map<String, String> customVariables;

  const LpConversationParams({
    required this.campaignInfo,
    this.visitorId,
    this.customVariables = const {},
  });

  Map<String, Object?> toJson() => {
    'campaignInfo': campaignInfo,
    'visitorId': visitorId,
    'customVariables': customVariables,
  };

  static LpConversationParams fromJson(Map<Object?, Object?> json) {
    final campaignInfo = json['campaignInfo']?.toString() ?? '';
    final visitorId = json['visitorId']?.toString();

    final vars = <String, String>{};
    final raw = json['customVariables'];
    if (raw is Map) {
      for (final e in raw.entries) {
        vars[e.key.toString()] = e.value.toString();
      }
    }

    return LpConversationParams(
      campaignInfo: campaignInfo,
      visitorId: visitorId,
      customVariables: vars,
    );
  }
}
