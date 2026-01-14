/// Minimal LivePerson Structured Content models for RichContentEvent.
///
/// These mirror the standard "vertical" template with:
/// - text
/// - image
/// - button (with publishText / link / navigate)
/// And a generic quick replies template.
///
/// You can build these and send them via RichContentEvent.
///
/// This file also includes higher-level message payload helpers
/// (attachments, quick replies, cards) used by LpMessagePayload.

/// Attachment type (file/image, etc.)
enum LpAttachmentType {
  image,
  file,
  video,
  audio,
  other,
}

class LpAttachment {
  final String id;
  final LpAttachmentType type;
  final Uri url;
  final String? fileName;
  final int? sizeBytes;
  final Map<String, dynamic> metadata;

  const LpAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.fileName,
    this.sizeBytes,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'url': url.toString(),
        if (fileName != null) 'fileName': fileName,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  static LpAttachment fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String? ?? 'other';
    final type = LpAttachmentType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => LpAttachmentType.other,
    );
    return LpAttachment(
      id: json['id'] as String? ?? '',
      type: type,
      url: Uri.parse(json['url'] as String? ?? ''),
      fileName: json['fileName'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }
}

/// Quick reply option (e.g., buttons the user can tap)
class LpQuickReply {
  final String id;
  final String title;
  final String? payload; // custom payload for bots/backends
  final Map<String, dynamic> metadata;

  const LpQuickReply({
    required this.id,
    required this.title,
    this.payload,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (payload != null) 'payload': payload,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  static LpQuickReply fromJson(Map<String, dynamic> json) => LpQuickReply(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        payload: json['payload'] as String?,
        metadata:
            (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      );
}

/// Basic rich card (image + title + description + actions)
class LpCardAction {
  final String id;
  final String title;
  final Uri? url;
  final String? payload;

  const LpCardAction({
    required this.id,
    required this.title,
    this.url,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (url != null) 'url': url.toString(),
        if (payload != null) 'payload': payload,
      };

  static LpCardAction fromJson(Map<String, dynamic> json) => LpCardAction(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        url: json['url'] != null ? Uri.parse(json['url'] as String) : null,
        payload: json['payload'] as String?,
      );
}

class LpCard {
  final String id;
  final String? title;
  final String? subtitle;
  final String? description;
  final Uri? imageUrl;
  final List<LpCardAction> actions;

  const LpCard({
    required this.id,
    this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.actions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl.toString(),
        if (actions.isNotEmpty)
          'actions': actions.map((a) => a.toJson()).toList(growable: false),
      };

  static LpCard fromJson(Map<String, dynamic> json) => LpCard(
        id: json['id'] as String? ?? '',
        title: json['title'] as String?,
        subtitle: json['subtitle'] as String?,
        description: json['description'] as String?,
        imageUrl:
            json['imageUrl'] != null ? Uri.parse(json['imageUrl'] as String) : null,
        actions: (json['actions'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(LpCardAction.fromJson)
            .toList(growable: false),
      );
}
class LpStructuredContent {
  final String type; // usually "vertical" or "quickReplies"
  final List<LpStructuredElement> elements;

  LpStructuredContent({
    required this.type,
    required this.elements,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}

abstract class LpStructuredElement {
  Map<String, dynamic> toJson();
}

/// Simple text block.
class LpTextElement extends LpStructuredElement {
  final String text;
  final String? tooltip;
  final bool bold;
  final String? size; // "small" | "medium" | "large"

  LpTextElement({
    required this.text,
    this.tooltip,
    this.bold = false,
    this.size,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'text',
      'text': text,
      if (tooltip != null) 'tooltip': tooltip,
      if (bold || size != null)
        'style': {
          'bold': bold,
          if (size != null) 'size': size,
        },
    };
  }
}

/// Simple image with optional click actions.
class LpImageElement extends LpStructuredElement {
  final String url;
  final String? tooltip;
  final List<LpClickAction> actions;

  LpImageElement({
    required this.url,
    this.tooltip,
    this.actions = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'url': url,
      if (tooltip != null) 'tooltip': tooltip,
      if (actions.isNotEmpty)
        'click': {
          'actions': actions.map((a) => a.toJson()).toList(),
        },
    };
  }
}

/// Button element.
class LpButtonElement extends LpStructuredElement {
  final String title;
  final String? tooltip;
  final List<LpClickAction> actions;

  LpButtonElement({
    required this.title,
    this.tooltip,
    this.actions = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'button',
      'title': title,
      if (tooltip != null) 'tooltip': tooltip,
      if (actions.isNotEmpty)
        'click': {
          'actions': actions.map((a) => a.toJson()).toList(),
        },
    };
  }
}

/// Generic click action:
/// - "publishText" (send a text payload back)
/// - "link" (deep link / http(s))
/// - "navigate" (map navigation)
class LpClickAction {
  final String type; // publishText | link | navigate | ...
  final String name;
  final String? text;
  final String? uri;
  final double? lo;
  final double? la;

  LpClickAction.publishText({
    required this.name,
    required this.text,
  })  : type = 'publishText',
        uri = null,
        lo = null,
        la = null;

  LpClickAction.link({
    required this.name,
    required this.uri,
  })  : type = 'link',
        text = null,
        lo = null,
        la = null;

  LpClickAction.navigate({
    required this.name,
    required this.lo,
    required this.la,
  })  : type = 'navigate',
        text = null,
        uri = null;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (text != null) 'text': text,
      if (uri != null) 'uri': uri,
      if (lo != null) 'lo': lo,
      if (la != null) 'la': la,
    };
  }
}

/// Quick replies structured content.
/// This is basically type "quickReplies" with reply buttons.
class LpQuickRepliesContent {
  final String text;
  final List<LpQuickReplyItem> replies;

  LpQuickRepliesContent({
    required this.text,
    required this.replies,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'quickReplies',
      'itemsPerRow': 8, // ignored for most channels but required
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

class LpQuickReplyItem {
  final String title;
  final String publishText;

  LpQuickReplyItem({
    required this.title,
    required this.publishText,
  });

  Map<String, dynamic> toJson() {
    return {
      'button': {
        'title': title,
        'click': {
          'actions': [
            {
              'type': 'publishText',
              'text': publishText,
            }
          ],
        },
      },
    };
  }
}
